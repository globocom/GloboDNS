# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.expand_path('../../../config/environment', __FILE__)

module GloboDns

class RevertableError < ::Exception; end

class StashLogs 
    def new()
        @stashed = Array.new
    end
    
    def add(tag, type, msg)
        strLog = "[#{tag}][#{type}] #{msg}"
        @stashed.push(strLog)
        # save log
    end
end


class Exporter
    include GloboDns::Config
    include GloboDns::Util
    include SyslogHelper

    attr_reader :logger

    CONFIG_START_TAG = '### BEGIN GloboDns ###'
    CONFIG_END_TAG   = '### END GloboDns ###'
    GIT_AUTHOR       = 'DNS API <dnsapi@example.com>'
    CHECKCONF_STANDARD_MESSAGES = [
        /^zone .*?: loaded serial\s+\d+\n/
    ]

    def initialize
        # @logger = ActiveSupport::TaggedLogging.new(Rails.logger)
        @logger = GloboDns::StringIOLogger.new("teste")
        @logger.loggers
        # @logger = GloboDns::StringIOLogger.new
        # @logger = Logger.new(STDOUT)
        @something_exported = false
    end

    def export_all(master_named_conf_content, slaves_named_conf_contents, options = {})
        # @logger                     = ActiveSupport::TaggedLogging.new(options.delete(:logger) || Rails.logger)
        # @logger                     = GloboDns::StringIOLogger.new(options.delete(:logger) || Rails.logger)
        # @logger                     ||= Rails.logger
        # @logger                     = GloboDns::StringIOLogger.initialize
        @logger = GloboDns::StringIOLogger.new
        @logger.loggers
        lock_tables                 = options.delete(:lock_tables)
      if (options[:use_master_named_conf_for_slave])
        slaves_named_conf_contents = [master_named_conf_content] * slaves_named_conf_contents.size
      end

      @views=View.all.collect(&:name)

        Domain.connection.execute("LOCK TABLE #{View.table_name} READ, #{Domain.table_name} READ, #{Record.table_name} READ, #{Audited::Adapters::ActiveRecord::Audit.table_name} READ") unless (lock_tables == false)
        export_master(master_named_conf_content, options)
        if SLAVE_ENABLED?
            Bind::Slaves.each_with_index do |slave, index|
                # only exports if the slave hosts is defined.
                export_slave(slaves_named_conf_contents[index], options.merge!(index: index)) if slave_enabled?(slave)
            end
        end

        syslog_info('export successful')
        Notifier.export_successful(@logger).deliver if @something_exported
    rescue Exception => e
        @logger.error(e.to_s + e.backtrace.join("\n"))

        syslog_error('export failed')
        Notifier.export_failed("#{e}\n\n#{@logger}\n\nBacktrace:\n#{e.backtrace.join("\n")}").deliver

        raise e
    ensure
        Domain.connection.execute('UNLOCK TABLES') unless (lock_tables == false)
    end

    def export_master(named_conf_content, options = {})
        bind_server_data = {
            :user            => Bind::Master::USER,
            :host            => Bind::Master::HOST,
            :chroot_dir      => Bind::Master::CHROOT_DIR,
            :zones_dir       => Bind::Master::ZONES_DIR,
            :named_conf_file => Bind::Master::NAMED_CONF_FILE
        }
        export(named_conf_content, Bind::Master::EXPORT_CHROOT_DIR, bind_server_data, slave = false, options.merge(:label => 'master'))
    end

    def export_slave(named_conf_content, options = {})
        index = options[:index] || 0
        bind_server_data = {
            :user            => Bind::Slaves[index]::USER,
            :host            => Bind::Slaves[index]::HOST,
            :chroot_dir      => Bind::Slaves[index]::CHROOT_DIR,
            :zones_dir       => Bind::Slaves[index]::ZONES_DIR,
            :named_conf_file => Bind::Slaves[index]::NAMED_CONF_FILE
        }
        export(named_conf_content, Bind::Slaves[index]::EXPORT_CHROOT_DIR, bind_server_data, slave = true, options.merge(:label => "slave#{index+1}"))
    end

    def export(named_conf_content, chroot_dir, bind_server_data, slave, options = {})
        @options        = options
        @logger       ||= @options[:logger] || Rails.logger
        @slave          = slave
        zones_root_dir  = bind_server_data[:zones_dir]       or raise ArgumentError.new('missing "bind_server_data.zones_dir" attr')
        named_conf_file = bind_server_data[:named_conf_file] or raise ArgumentError.new('missing "bind_server_data.named_conf_file" attr')

        # get last commit timestamp and the export/current timestamp
        Dir.chdir(File.join(chroot_dir, zones_root_dir))
        if @options[:all] == true
            # ignore the current git content and export all records
            @last_commit_date = Time.at(0)
        else
          if slave
            @last_commit_date = Dir.chdir(File.join(chroot_dir, zones_root_dir)) do
                Time.at(exec('git last commit date', GloboDns::Config::Binaries::GIT, 'log', '-1', '--format=%at').to_i)
            end
          else
            @last_commit_date = last_export_timestamp
          end
        end
        @export_timestamp = Time.now.round
        #@touch_timestamp  = @export_timestamp + 1 # we add 1 second to avoid minor subsecond discrepancies
                                                  # when comparing each file's mtime with the @export_times

        #Remove destroyed domains
        removed_zones = remove_destroyed_domains(File.join(chroot_dir, zones_root_dir), slave)

        tmp_dir = Dir.mktmpdir
        @logger.info "[GloboDns::Exporter] tmp dir: #{tmp_dir}" if @options[:keep_tmp_dir] == true
        File.chmod(02770, tmp_dir)
        FileUtils.chown(nil, BIND_GROUP, tmp_dir, :verbose => true)
        File.umask(0007)

        # recursivelly copy the current configuration to the tmp dir
        exec('rsync chroot', 'rsync', '-v', '-a', '--exclude', 'session.key', '--exclude', '.git/', File.join(chroot_dir, '.'), tmp_dir)

        # export main configuration file
        named_conf_content = self.class.load_named_conf(chroot_dir, named_conf_file) if named_conf_content.blank?
        export_named_conf(named_conf_content, tmp_dir, zones_root_dir, named_conf_file)

        # export all views
        export_views(tmp_dir, zones_root_dir)

        new_zones = []

        # export each view-less domain group to a separate file
        if @slave == true
            export_domain_group(tmp_dir, zones_root_dir, ZONES_FILE,    ZONES_DIR,    [], true)
            export_domain_group(tmp_dir, zones_root_dir, REVERSE_FILE,  REVERSE_DIR,  [], true)
            export_domain_group(tmp_dir, zones_root_dir, SLAVES_FILE,   SLAVES_DIR,   Domain.noview.master_or_reverse)
            export_domain_group(tmp_dir, zones_root_dir, FORWARDS_FILE, FORWARDS_DIR, Domain.noview.forward)
        else
            new_zones_noreverse = export_domain_group(tmp_dir, zones_root_dir, ZONES_FILE,    ZONES_DIR,    Domain.noview.master)
            new_zones_reverse   = export_domain_group(tmp_dir, zones_root_dir, REVERSE_FILE,  REVERSE_DIR,  Domain.noview._reverse)
            if not new_zones_noreverse.empty? and not new_zones_reverse.empty?
                # If there is a new zone in non-reverse or reverse, I need update everything.
                # If both have only changes, may I reload only changed zones
                new_zones += new_zones_noreverse + new_zones_reverse
            end
            export_domain_group(tmp_dir, zones_root_dir, SLAVES_FILE,   SLAVES_DIR,   Domain.noview.slave)
            export_domain_group(tmp_dir, zones_root_dir, FORWARDS_FILE, FORWARDS_DIR, Domain.noview.forward)
        end

        # remove files that older than the export timestamp; these are the
        # zonefiles from domains that have been removed from the database
        # (otherwise they'd have been regenerated or 'touched')
        remove_untouched_zonefiles(File.join(tmp_dir, zones_root_dir, ZONES_DIR),   @export_timestamp)
        remove_untouched_zonefiles(File.join(tmp_dir, zones_root_dir, REVERSE_DIR), @export_timestamp)
        remove_untouched_zonefiles(File.join(tmp_dir, zones_root_dir, SLAVES_DIR),  @export_timestamp, true)

        # validate configuration with 'named-checkconf'
        run_checkconf(tmp_dir, named_conf_file)

        # sync generated files on the tmp dir to the local chroot repository
        sync_repository_and_commit(tmp_dir, chroot_dir, zones_root_dir, named_conf_file, bind_server_data)

        updated_zones = removed_zones.empty? ? new_zones : []
        # sync files in chroot repository to remote dir on the actual BIND server
        sync_remote_bind_and_reload(chroot_dir, zones_root_dir, named_conf_file, bind_server_data, updated_zones)
        @something_exported = true
    rescue ExitStatusError => err
      if err.message == "Nothing to be exported!"
        @logger.info("[GloboDns::Exporter][INFO] #{err.message}")
      else
        raise err
      end
    rescue Exception => e
        if @revert_operation_data && @options[:reset_repository_on_failure] != false
            @logger.error(e.to_s + e.backtrace.join("\n"))
            revert_operation()
        end
        raise e
    ensure
        FileUtils.remove_entry_secure tmp_dir unless !defined?(tmp_dir) && tmp_dir.nil? || @options[:keep_tmp_dir] == true
        Domain.connection.execute('UNLOCK TABLES') unless (@options[:lock_tables] == false)
    end

    def self.load_named_conf(chroot_dir, named_conf_file)
        File.read(File.join(chroot_dir, named_conf_file)).sub(/\n*#{GloboDns::Exporter::CONFIG_START_TAG}.*#{GloboDns::Exporter::CONFIG_END_TAG}\n*/m, "\n")
    end

    private

    def export_named_conf(content, chroot_dir, zones_root_dir, named_conf_file)
        content.gsub!("\r\n", "\n")
        content.sub!(/\A[\s\n]+/, '')
        content.sub!(/[\s\n]*\Z/, "\n")
        content.sub!(/\n*#{GloboDns::Exporter::CONFIG_START_TAG}.*#{GloboDns::Exporter::CONFIG_END_TAG}\n*/m, "\n")

        abs_zones_root_dir  = File.join(chroot_dir, zones_root_dir)
        abs_named_conf_file = File.join(abs_zones_root_dir, File.basename(named_conf_file))
        File.open(abs_named_conf_file, 'w') do |file|
            file.puts content
            file.puts
            file.puts CONFIG_START_TAG
            file.puts '# this block is auto generated; do not edit'
            if View.count > 0
                file.puts "include \"#{File.join(zones_root_dir, VIEWS_FILE)}\";"
            else
                file.puts "include \"#{File.join(zones_root_dir, GloboDns::Config::ZONES_FILE)}\";\n"
                file.puts "include \"#{File.join(zones_root_dir, GloboDns::Config::SLAVES_FILE)}\";\n"
                file.puts "include \"#{File.join(zones_root_dir, GloboDns::Config::FORWARDS_FILE)}\";\n"
                file.puts "include \"#{File.join(zones_root_dir, GloboDns::Config::REVERSE_FILE)}\";\n"
            end
            file.puts CONFIG_END_TAG
        end
        #File.utime(@touch_timestamp, @touch_timestamp, abs_named_conf_file)
    end

    def export_views(chroot_dir, zones_root_dir)
        abs_zones_root_dir = File.join(chroot_dir, zones_root_dir)
        abs_views_file     = File.join(abs_zones_root_dir, VIEWS_FILE)

        File.open(abs_views_file, 'w') do |file|
            View.all.each do |view|
                file.puts view.to_bind9_conf(zones_root_dir)
                if @slave == true
                    #                   chroot_dir , zones_root_dir , file_name          , dir_name          , domains                        , export_all_domains
                    export_domain_group(chroot_dir , zones_root_dir , view.zones_file    , view.zones_dir    , []                             , true)
                    export_domain_group(chroot_dir , zones_root_dir , view.reverse_file  , view.reverse_dir  , []                             , true)
                    export_domain_group(chroot_dir , zones_root_dir , view.slaves_file   , view.slaves_dir   , view.domains.master_or_reverse , view.updated_since?(@last_commit_date))
                    export_domain_group(chroot_dir , zones_root_dir , view.forwards_file , view.forwards_dir , view.domains.forward           , true)
                    else
                    #                   chroot_dir , zones_root_dir , file_name          , dir_name          , domains                        , export_all_domains
                    export_domain_group(chroot_dir , zones_root_dir , view.zones_file    , view.zones_dir    , view.domains.master            , view.updated_since?(@last_commit_date))
                    export_domain_group(chroot_dir , zones_root_dir , view.reverse_file  , view.reverse_dir  , view.domains._reverse          , view.updated_since?(@last_commit_date))
                    export_domain_group(chroot_dir , zones_root_dir , view.slaves_file   , view.slaves_dir   , view.domains.slave             , view.updated_since?(@last_commit_date))
                    export_domain_group(chroot_dir , zones_root_dir , view.forwards_file , view.forwards_dir , view.domains.forward           , view.updated_since?(@last_commit_date))
                end
            end
        end

        #File.utime(@touch_timestamp, @touch_timestamp, abs_views_file)
    end

    def export_domain_group(chroot_dir, zones_root_dir, file_name, dir_name, domains, export_all_domains = false)
        # abs stands for absolute
        abs_zones_root_dir = File.join(chroot_dir, zones_root_dir)
        abs_file_name      = File.join(abs_zones_root_dir, file_name)
        abs_dir_name       = File.join(abs_zones_root_dir, dir_name)
        array_new_zones = []
        n_zones = []

        # @logger.debug "Export domain group chroot_dir=#{chroot_dir} zones_root_dir=#{zones_root_dir} file_name=#{file_name} dir_name=#{dir_name} export_all_domains=#{export_all_domains}"
        File.exists?(abs_dir_name) or FileUtils.mkdir(abs_dir_name)

        File.open(abs_file_name, 'w') do |file|
            # dump zonefile of updated domains
            updated_domains = export_all_domains ? domains : domains.updated_since(@last_commit_date)
            updated_domains.each do |domain|
                if not export_all_domains and not @slave
                    n_zones << domain
                end
                unless @slave #Slaves don't replicate the zone-files.
                    @logger.debug "[DEBUG] writing zonefile for domain #{domain.name} (last updated: #{domain.updated_at}; repo: #{@last_commit_date}; created_at: #{domain.created_at}) (domain.updated?: #{domain.updated_since?(@last_commit_date)}; domain.records.updated_since-count: #{domain.records.updated_since(@last_commit_date).count})"
                    #create subdir for this domain, if it doesn't exist yet.
                    abs_zonefile_dir = File::join(abs_zones_root_dir, domain.zonefile_dir)
                    File.exists?(abs_zonefile_dir) or FileUtils.mkdir_p(abs_zonefile_dir)
                    #Create/Update the zonefile itself
                    abs_zonefile_path = File.join(abs_zones_root_dir, domain.zonefile_path)
                    domain.to_zonefile(abs_zonefile_path) unless domain.slave?
                    #File.utime(@touch_timestamp, @touch_timestamp, File.join(abs_zonefile_path)) unless domain.slave? || domain.forward?
                end
            end

            #If one zone is new, we need a full reload to bind.
            n_zones.each do |z|
                if z.created_at > @last_commit_date
                    array_new_zones = []
                    break
                else
                    array_new_zones << "#{z.name}"
                end
            end

            # write entries to index file (<domain_type>.conf).
            domains.each do |domain|
                if @slave and not domain.forward?
                    domain = domain.clone
                    domain.slave!
                    abs_zonefile_dir = File::join(abs_zones_root_dir, domain.zonefile_dir)
                    File.exists?(abs_zonefile_dir) or FileUtils.mkdir_p(abs_zonefile_dir)
                    abs_zonefile_path = File.join(abs_zones_root_dir, domain.zonefile_path)
                    File.exists?(abs_zonefile_path) or File.open(abs_zonefile_path,'w')
                    domain.master  = "#{Bind::Master::IPADDR}"
                    domain.master += " port #{Bind::Master::PORT}"     if defined?(Bind::Master::PORT)
                    domain.master += " key #{domain.query_key_name}" if domain.query_key_name
                end
                file.puts domain.to_bind9_conf(zones_root_dir)
            end
        end

        #File.utime(@touch_timestamp, @touch_timestamp, abs_dir_name)
        #File.utime(@touch_timestamp, @touch_timestamp, abs_file_name)
        return array_new_zones
    end

    def remove_untouched_zonefiles(dir, export_timestamp, slave = false)
      if slave
        patern = File.join(dir, 'dbs.*')
      else
        patern = File.join(dir, 'db.*')
      end
        Dir.glob(patern).each do |file|
            if File.mtime(file) < export_timestamp
                @logger.debug "[DEBUG] removing untouched zonefile \"#{file}\" (mtime (#{File.mtime(file)}) < export ts (#{export_timestamp}))"
                FileUtils.rm(file)
            end
        end
    end

    def run_checkconf(chroot_dir, named_conf_file)
        output = exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', chroot_dir, named_conf_file)
        clean_checkconf_output(output)
    rescue ExitStatusError => e
        raise ExitStatusError.new(clean_checkconf_output(e.message))
    end

    def sync_repository_and_commit(tmp_dir, chroot_dir, zones_root_dir, named_conf_file, bind_server_data)
        abs_tmp_zones_root_dir   = File.join(tmp_dir, zones_root_dir, '')
        abs_repository_zones_dir = File.join(chroot_dir, zones_root_dir, '')

        # set 'bind' as group of the tmp_dir, add rwx permission to group
        FileUtils.chown_R(nil, BIND_GROUP, abs_tmp_zones_root_dir)
        exec('chmod_R', 'chmod', '-R', 'g+u', abs_tmp_zones_root_dir) # ruby doesn't accept symbolic mode on chmod

        #--- change to the directory with the local copy of the zone files
        Dir.chdir(abs_repository_zones_dir)

        #--- save data required to revert the respository to the current version
        orig_head = (exec('git rev-parse', Binaries::GIT, 'rev-parse', 'HEAD')).chomp
        @logger.info "[GloboDns::Exporter][INFO] git repository ORIG_HEAD: #{orig_head}"
        label = @options[:label]
        @revert_operation_data ||= {}
        @revert_operation_data[label] = {
            :bind_server_data => bind_server_data,
            :chroot_dir       => chroot_dir,
            :revert_server    => false, #Only true after sync_remote
            :revision         => orig_head,
            :zones_root_dir   => zones_root_dir
        }

        #--- sync to Bind9's data dir
        if @slave
            rsync_output = exec('local rsync',
                                Binaries::RSYNC,
                                '--checksum',
                                '--archive',
                                '--delete',
                                '--verbose',
                                # '--omit-dir-times',
                                '--group',
                                '--perms',
                                # "--include=#{NAMED_CONF_FILE}",
                                "--include=#{File.basename(named_conf_file)}",
                                "--include=#{VIEWS_FILE}",
                                "--include=*#{ZONES_FILE}",
                                "--include=*#{SLAVES_FILE}",
                                "--include=*#{FORWARDS_FILE}",
                                "--include=*#{REVERSE_FILE}",
                                "--include=*#{ZONES_DIR}/***",
                                "--include=*#{SLAVES_DIR}/***",
                                "--include=*#{FORWARDS_DIR}/***",
                                "--include=*#{REVERSE_DIR}/***",
                                '--exclude=*',
                                abs_tmp_zones_root_dir,
                                abs_repository_zones_dir)
        else
            rsync_output = exec('local rsync',
                                Binaries::RSYNC,
                                '--checksum',
                                '--archive',
                                '--delete',
                                '--verbose',
                                # '--omit-dir-times',
                                '--group',
                                '--perms',
                                # "--include=#{NAMED_CONF_FILE}",
                                "--include=#{File.basename(named_conf_file)}",
                                "--include=#{VIEWS_FILE}",
                                "--include=*#{ZONES_FILE}",
                                "--include=*#{SLAVES_FILE}",
                                "--include=*#{FORWARDS_FILE}",
                                "--include=*#{REVERSE_FILE}",
                                "--include=*#{ZONES_DIR}/***",
                                "--include=*#{SLAVES_DIR}/***",
                                "--include=*#{FORWARDS_DIR}/***",
                                "--include=*#{REVERSE_DIR}/***",
                                '--exclude=*',
                                abs_tmp_zones_root_dir,
                                abs_repository_zones_dir)
        end
        @logger.debug "[GloboDns::Exporter][DEBUG] rsync:\n#{rsync_output}"

        #--- add all changed files to git's index
        # exec_as_bind('git add', Binaries::GIT, 'add', '-A')
        exec('git add', Binaries::GIT, 'add', '-A')

        #--- check status output; if there are no changes, just return
        git_status_output = exec('git status', Binaries::GIT, 'status')
        if git_status_output =~ /nothing to commit \(working directory clean\)/
          raise ExitStatusError, "Nothing to be exported!"
        end

        #--- commit the changes
        # commit_output = exec_as_bind('git commit', Binaries::GIT, 'commit', "--author=#{GIT_AUTHOR}", "--date=#{@export_timestamp}", '-m', '"[GloboDns::exporter]"')
        commit_output = exec('git commit', Binaries::GIT, 'commit', "--author=#{GIT_AUTHOR}", "--date=#{@export_timestamp}", '-m', '"[GloboDns::exporter]"')
        @logger.info "[GloboDns::Exporter][INFO] changes committed:\n#{commit_output}"

        #--- get the new HEAD and dump it to the log
        new_head = (exec('git rev-parse', Binaries::GIT, 'rev-parse', 'HEAD')).chomp
        @logger.info "[GloboDns::Exporter][INFO] git repository new HEAD: #{new_head}"
    end

    def sync_remote_bind_and_reload(chroot_dir, zones_root_dir, named_conf_file, bind_server_data, updated_zones)
        abs_repository_zones_dir = File.join(chroot_dir, zones_root_dir, '')
        sync_remote(abs_repository_zones_dir , named_conf_file, bind_server_data)

        @to_reload = updated_zones
        #Better do a full reload if to many zones were changed
        if @to_reload.size < 10 and not @to_reload.empty?
            @to_reload.each do |zone|
                reload_output = reload_bind_conf(chroot_dir, zone)
                @logger.info "[GloboDns::Exporter][INFO] bind configuration reloaded:\n#{reload_output}"
            end
        else
            zone = []
            reload_output = reload_bind_conf(chroot_dir, zone)
            @logger.info "[GloboDns::Exporter][INFO] bind configuration reloaded:\n#{reload_output}"
        end
    end

    def sync_remote(abs_repository_zones_dir, named_conf_file, bind_server_data)
        label = @options[:label]
        # If anything fails from now on, the server data has to be reverted as well
        @revert_operation_data[label][:revert_server] = true if @revert_operation_data[label]

        if @slave
            rsync_output = exec('remote rsync',
                                Binaries::RSYNC,
                                '--checksum',
                                '--archive',
                                '--delete',
                                '--verbose',
                                '--ignore-existing',
                                '--min-size=1',
                                "--include=#{File.basename(named_conf_file)}",
                                "--include=*#{ZONES_DIR}/***",
                                "--include=*#{SLAVES_DIR}/***",
                                "--include=*#{FORWARDS_DIR}/***",
                                "--include=*#{REVERSE_DIR}/***",
                                '--exclude=*',
                                abs_repository_zones_dir,
                                "#{bind_server_data[:user]}@#{bind_server_data[:host]}:#{File.join(bind_server_data[:chroot_dir], bind_server_data[:zones_dir])}")

            rsync_output = exec('remote rsync',
                                Binaries::RSYNC,
                                '--checksum',
                                '--archive',
                                '--delete',
                                '--verbose',
                                "--include=#{File.basename(named_conf_file)}",
                                "--include=#{VIEWS_FILE}",
                                "--include=*#{ZONES_FILE}",
                                "--include=*#{SLAVES_FILE}",
                                "--include=*#{FORWARDS_FILE}",
                                "--include=*#{REVERSE_FILE}",
                                '--exclude=*',
                                abs_repository_zones_dir,
                                "#{bind_server_data[:user]}@#{bind_server_data[:host]}:#{File.join(bind_server_data[:chroot_dir], bind_server_data[:zones_dir])}")

            rsync_output = exec('remote rsync',
                                Binaries::RSYNC,
                                '--inplace',
                                '--owner',
                                '--group',
                                '--perms',
                                '--verbose',
                                File.join(abs_repository_zones_dir, File.basename(named_conf_file)),
                                "#{bind_server_data[:user]}@#{bind_server_data[:host]}:#{File.join(bind_server_data[:chroot_dir], bind_server_data[:named_conf_file])}")
        else
            rsync_output = exec('remote rsync',
                                Binaries::RSYNC,
                                '--checksum',
                                '--archive',
                                '--delete',
                                '--verbose',
                                # '--omit-dir-times',
                                '--owner',
                                '--group',
                                '--perms',
                                "--include=#{File.basename(named_conf_file)}",
                                "--include=#{VIEWS_FILE}",
                                "--include=*#{ZONES_FILE}",
                                "--include=*#{SLAVES_FILE}",
                                "--include=*#{FORWARDS_FILE}",
                                "--include=*#{REVERSE_FILE}",
                                "--include=*#{ZONES_DIR}/***",
                                "--include=*#{SLAVES_DIR}/***",
                                "--include=*#{FORWARDS_DIR}/***",
                                "--include=*#{REVERSE_DIR}/***",
                                '--exclude=*',
                                abs_repository_zones_dir,
                                "#{bind_server_data[:user]}@#{bind_server_data[:host]}:#{File.join(bind_server_data[:chroot_dir], bind_server_data[:zones_dir])}")

            rsync_output = exec('remote rsync',
                                Binaries::RSYNC,
                                '--inplace',
                                '--owner',
                                '--group',
                                '--perms',
                                '--verbose',
                                File.join(abs_repository_zones_dir, File.basename(named_conf_file)),
                                "#{bind_server_data[:user]}@#{bind_server_data[:host]}:#{File.join(bind_server_data[:chroot_dir], bind_server_data[:named_conf_file])}")
        end

        rsync_output
    end

    def reload_bind_conf(chroot_dir, zone = [])
        if zone.empty? or not @views.empty?
            cmd_args = ['rndc reload', Binaries::RNDC, '-c', File.join(chroot_dir, RNDC_CONFIG_FILE), '-y', RNDC_KEY_NAME, 'reload']
        else
            cmd_args = ['rndc reload', Binaries::RNDC, '-c', File.join(chroot_dir, RNDC_CONFIG_FILE), '-y', RNDC_KEY_NAME, 'reload'] << zone
        end
        begin
          exec(*cmd_args)
        rescue ExitStatusError => e
          if e.message.include?('no matching zone') || e.message.include?('not found')
            @logger.warn("[GloboDns::Exporter]#{e.message}")
          else
            raise e
          end
        end
    end

    def revert_operation
        @revert_operation_data.each do |label, data|
            abs_repository_zones_dir = File.join(data[:chroot_dir], data[:zones_root_dir], '')
            Dir.chdir(abs_repository_zones_dir) do
                @logger.info("[GloboDns::Exporter] reseting #{label} git repository")
                # Go back to last successful revision
                exec('git reset', Binaries::GIT,  'reset', '--hard', data[:revision]) # try to rollback changes
                if data[:revert_server]
                    # Something failed after sending data to server. We have to sync the old data again
                    bind_server_data = data[:bind_server_data]
                    named_conf_file = bind_server_data[:named_conf_file]
                    # Sync it to server
                    @logger.info("[GloboDns::Exporter] Sending the reverted config to remote")
                    sync_remote(abs_repository_zones_dir, named_conf_file, bind_server_data)

                    # Reload again
                    reload_output = reload_bind_conf(data[:chroot_dir]) rescue nil
                    @logger.info "[GloboDns::Exporter][INFO] bind configuration reloaded:\n#{reload_output}"
                end
            end
        end
    end

    def clean_checkconf_output(output)
        CHECKCONF_STANDARD_MESSAGES.inject(output) do |output, pattern|
            output.gsub(pattern, '')
        end
    end

    def remove_destroyed_domains(zonefile_dir,slave = false)
      destroyed = Audited::Adapters::ActiveRecord::Audit.where(auditable_type:"Domain",action:"destroy" ).where("created_at > ?", @last_commit_date)
      domains = destroyed.collect{|a| a.audited_changes['name']}
      @logger.info "[GloboDns::Exporter] Removing destroyed domains: #{domains}" unless domains.empty?
      domains.each do |domain|
        tmpdomain = Domain.new(name:domain)
        tmpdomain.slave! if slave
        zonefile_path = tmpdomain.zonefile_path
        abs_zonefile_path = File.join(zonefile_dir,zonefile_path)
        @logger.debug "[GloboDns::Exporter] removing destroyed zonefile \"#{abs_zonefile_path}\""
        begin
          FileUtils.rm(abs_zonefile_path)
        rescue Errno::ENOENT => e
          @logger.info "[GloboDns::Exporter] #{e.message}"
        end
      end
      domains
    end

end # Exporter
end # GloboDns
