require File.expand_path('../../../config/environment', __FILE__)

module GloboDns

class RevertableError < ::Exception; end

class Exporter
    include GloboDns::Config
    include GloboDns::Util

    CONFIG_START_TAG = '### BEGIN GloboDns ###'
    CONFIG_END_TAG   = '### END GloboDns ###'
    GIT_AUTHOR       = 'Globo DNS API <dnsapi@globoi.com>'
    CHECKCONF_STANDARD_MESSAGES = [
        /^zone .*?: loaded serial\s+\d+\n/
    ]

    def export_all(master_named_conf_content, slave_named_conf_content, options = {})
        @logger                     = options.delete(:logger) || Rails.logger
        lock_tables                 = options.delete(:lock_tables)
        reset_repository_on_failure = options.delete(:reset_repository_on_failure)
        options.merge!({ :lock_tables => false, :reset_repository_on_failure => false })

        slave_named_conf_content = master_named_conf_content if (options[:use_master_named_conf_for_slave] == true)

        Domain.connection.execute("LOCK TABLE #{View.table_name} READ, #{Domain.table_name} READ, #{Record.table_name} READ") unless (lock_tables == false)
        master_new_head, master_orig_head = export_master(master_named_conf_content, options.merge(:slave => false))
        slave_new_head,  slave_orig_head  = export_slave(slave_named_conf_content,   options.merge(:slave => true))
    rescue Exception => e
        @logger.error("[GloboDns::Exporter][ERROR] " + e.to_s + e.backtrace.join("\n"))
        unless reset_repository_on_failure == false
            reset_repository(master_orig_head, EXPORT_MASTER_CHROOT_DIR, 'master') if master_orig_head
            reset_repository(slave_orig_head,  EXPORT_SLAVE_CHROOT_DIR,  'slave')  if slave_orig_head
        end
        raise e
    ensure
        Domain.connection.execute('UNLOCK TABLES') unless (lock_tables == false)
    end

    def export_master(named_conf_content, options = {})
        export(named_conf_content, options.merge(:chroot_dir => EXPORT_MASTER_CHROOT_DIR,
                                                 :remote     => {:user => BIND_MASTER_USER, :host => BIND_MASTER_HOST, :chroot_dir => BIND_MASTER_CHROOT_DIR, :named_conf => BIND_MASTER_NAMED_CONF_FILE},
                                                 :slave      => false))
    end

    def export_slave(named_conf_content, options = {})
        export(named_conf_content, options.merge(:chroot_dir => EXPORT_SLAVE_CHROOT_DIR,
                                                 :remote     => {:user => BIND_SLAVE_USER, :host => BIND_SLAVE_HOST, :chroot_dir => BIND_SLAVE_CHROOT_DIR, :named_conf => BIND_SLAVE_NAMED_CONF_FILE},
                                                 :slave      => true))
    end

    def export(named_conf_content, options = {})
        @options     = options
        @logger    ||= @options[:logger] || Rails.logger
        chroot_dir   = @options[:chroot_dir] or raise RuntimeError.new('[GloboDns::Exporter][ERROR] no "chroot_dir" option supplied')
        remote       = @options[:remote]     or raise RuntimeError.new('[GloboDns::Exporter][ERROR] no "remote" option supplied')
        config_dir   = File.join(chroot_dir, EXPORT_CONFIG_DIR)

        # get last commit timestamp and the export/current timestamp
        Dir.chdir(config_dir)
        if @options[:all] == true
            # ignore the current git content and export all records
            @last_commit_date = Time.at(0)
        else
            @last_commit_date = Time.at(exec('git last commit date', Binaries::GIT, 'log', '-1', '--format=%at').to_i)
        end
        @export_timestamp = Time.now
        @touch_timestamp  = @export_timestamp + 1 # we add 1 second to avoid minor subsecond discrepancies
                                                  # when comparing each file's mtime with the @export_times

        tmp_dir = Dir.mktmpdir
        @logger.info "[GloboDns::Exporter] tmp dir: #{tmp_dir}" if @options[:keep_tmp_dir] == true
        File.chmod(02770, tmp_dir)
        FileUtils.chown(nil, BIND_GROUP, tmp_dir)
        File.umask(0007)

        tmp_named_dir = File.join(tmp_dir, EXPORT_CONFIG_DIR)

        # recursivelly copy the current configuration to the tmp dir
        exec('rsync chroot', 'rsync', '-v', '-a', '--exclude', 'session.key', '--exclude', '.git/', File.join(chroot_dir, '.'), tmp_dir)

        # export main configuration file
        export_named_conf(named_conf_content, tmp_named_dir) if named_conf_content.present?

        # export all views
        export_views(tmp_named_dir)

        # export each view-less domain group to a separate file
        if @options[:slave] == true
            export_domain_group(tmp_named_dir, ZONES_FILE,   ZONES_DIR,   [], true)
            export_domain_group(tmp_named_dir, REVERSE_FILE, REVERSE_DIR, [], true)
            export_domain_group(tmp_named_dir, SLAVES_FILE,  SLAVES_DIR,  Domain.noview.nonslave)
        else
            export_domain_group(tmp_named_dir, ZONES_FILE,   ZONES_DIR,   Domain.noview.master)
            export_domain_group(tmp_named_dir, REVERSE_FILE, REVERSE_DIR, Domain.noview._reverse)
            export_domain_group(tmp_named_dir, SLAVES_FILE,  SLAVES_DIR,  Domain.noview.slave)
        end

        # remove files that older than the export timestamp; these are the
        # zonefiles from domains that have been removed from the database
        # (otherwise they'd have been regenerated or 'touched')
        remove_untouched_zonefiles(File.join(tmp_named_dir, ZONES_DIR),   @export_timestamp)
        remove_untouched_zonefiles(File.join(tmp_named_dir, REVERSE_DIR), @export_timestamp)

        # validate configuration with 'named-checkconf'
        run_checkconf(tmp_dir)

        # sync generated files on the tmp dir to the local chroot repository
        sync_repository_and_commit(chroot_dir, config_dir, tmp_named_dir)

        # sync files in chroot repository to remote dir on the actual BIND server
        sync_remote_bind_and_reload(chroot_dir, remote)
    ensure
        # FileUtils.remove_entry_secure tmp_dir unless tmp_dir.nil? || @options[:keep_tmp_dir] == true
        Domain.connection.execute('UNLOCK TABLES') unless (@options[:lock_tables] == false)
    end
    
    private

    def export_named_conf(content, tmp_named_dir)
        content.gsub!("\r\n", "\n")
        content.sub!(/\A[\s\n]+/, '')
        content.sub!(/[\s\n]*\Z/, "\n")
        content.sub!(/\n*#{GloboDns::Exporter::CONFIG_START_TAG}.*#{GloboDns::Exporter::CONFIG_END_TAG}\n*/m, "\n")

        # File.open(named_conf_file = File.join(tmp_named_dir, NAMED_CONF_FILE), 'w') do |file|
        File.open(named_conf_file = File.join(tmp_named_dir, File.basename(EXPORT_CONFIG_FILE)), 'w') do |file|
            file.puts content
            file.puts
            file.puts CONFIG_START_TAG
            file.puts '# this block is auto generated; do not edit'
            if View.count > 0
                file.puts "include \"#{File.join(EXPORT_CONFIG_DIR, VIEWS_FILE)}\";"
            else
                file.puts "include \"#{File.join(GloboDns::Config::EXPORT_CONFIG_DIR, GloboDns::Config::ZONES_FILE)}\";\n"
                file.puts "include \"#{File.join(GloboDns::Config::EXPORT_CONFIG_DIR, GloboDns::Config::SLAVES_FILE)}\";\n"
                file.puts "include \"#{File.join(GloboDns::Config::EXPORT_CONFIG_DIR, GloboDns::Config::REVERSE_FILE)}\";\n"
            end
            file.puts CONFIG_END_TAG
        end
        File.utime(@touch_timestamp, @touch_timestamp, named_conf_file)
    end

    def export_views(tmp_named_dir)
        abs_views_file = File.join(tmp_named_dir, VIEWS_FILE)

        File.open(abs_views_file, 'w') do |file|
            View.all.each do |view|
                file.puts view.to_bind9_conf
                if @options[:slave] == true
                    export_domain_group(tmp_named_dir, view.zones_file,   view.zones_dir,   [],                    true)
                    export_domain_group(tmp_named_dir, view.reverse_file, view.reverse_dir, [],                    true)
                    export_domain_group(tmp_named_dir, view.slaves_file,  view.slaves_dir,  view.domains.nonslave, view.updated_since?(@last_commit_date))
                else
                    export_domain_group(tmp_named_dir, view.zones_file,   view.zones_dir,   view.domains.master,   view.updated_since?(@last_commit_date))
                    export_domain_group(tmp_named_dir, view.reverse_file, view.reverse_dir, view.domains._reverse, view.updated_since?(@last_commit_date))
                    export_domain_group(tmp_named_dir, view.slaves_file,  view.slaves_dir,  view.domains.slave,    view.updated_since?(@last_commit_date))
                end
            end
        end

        File.utime(@touch_timestamp, @touch_timestamp, abs_views_file)
    end

    def export_domain_group(tmp_named_dir, file_name, dir_name, domains, export_all_domains = false)
        abs_file_name = File.join(tmp_named_dir, file_name)
        abs_dir_name  = File.join(tmp_named_dir, dir_name)

        File.exists?(abs_dir_name) or FileUtils.mkdir(abs_dir_name)

        File.open(abs_file_name, 'w') do |file|
            # dump zonefile of updated domains
            updated_domains = export_all_domains ? domains : domains.updated_since(@last_commit_date)
            updated_domains.each do |domain|
                # @logger.debug "[DEBUG] writing zonefile for domain #{domain.name} (last updated: #{domain.updated_at}; repo: #{@last_commit_date}) (domain.updated?: #{domain.updated_since?(@last_commit_date)}; domain.records.updated?: #{domain.records.updated_since(@last_commit_date).first})"
                domain.to_zonefile(File.join(tmp_named_dir, domain.zonefile_path)) unless domain.slave? || (@options[:slave] == true)
            end

            # write entries to index file (<domain_type>.conf) and update 'mtime'
            # of *all* non-slave domains, so that we may use the mtime as a criteria
            # to identify the zonefiles that have been removed from BIND's config
            domains.each do |domain|
                if (@options[:slave] == true)
                    domain = domain.clone
                    domain.slave!
                    domain.master  = "#{BIND_MASTER_IPADDR}"
                    domain.master += " port #{BIND_MASTER_PORT}" if defined?(BIND_MASTER_PORT)
                end
                file.puts domain.to_bind9_conf
                File.utime(@touch_timestamp, @touch_timestamp, File.join(tmp_named_dir, domain.zonefile_path)) unless domain.slave?
            end
        end

        File.utime(@touch_timestamp, @touch_timestamp, abs_dir_name)
        File.utime(@touch_timestamp, @touch_timestamp, abs_file_name)
    end

    def remove_untouched_zonefiles(dir, export_timestamp)
        Dir.glob(File.join(dir, 'db.*')).each do |file|
            if File.mtime(file) < export_timestamp
                @logger.debug "[DEBUG] removing untouched zonefile \"#{file}\" (mtime (#{File.mtime(file)}) < export ts (#{export_timestamp}))"
                FileUtils.rm(file)
            end
        end
    end

    def run_checkconf(tmp_dir)
        output = exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', tmp_dir, EXPORT_CONFIG_FILE)
        clean_checkconf_output(output)
    rescue ExitStatusError => e
        raise ExitStatusError.new(clean_checkconf_output(e.message))
    end

    def sync_repository_and_commit(chroot_dir, config_dir, tmp_named_dir)
        # set 'bind' as group of the tmp_dir, add rwx permission to group
        FileUtils.chown_R(nil, BIND_GROUP, tmp_named_dir)
        # FileUtils.chmod_R('g+u', tmp_named_dir)
        exec('chmod_R', 'chmod', '-R', 'g+u', tmp_named_dir) # ruby doesn't accept symbolic mode on chmod

        #--- change to the bind config dir
        Dir.chdir(config_dir)

        #--- save the current HEAD and dump it to the log
        orig_head = (exec('git rev-parse', Binaries::GIT, 'rev-parse', 'HEAD')).chomp
        @logger.info "[GloboDns::Exporter][INFO] git repository ORIG_HEAD: #{orig_head}"

        #--- sync to Bind9's data dir
        # rsync_output = exec_as_bind('rsync',
        rsync_output = exec('local rsync',
                            Binaries::RSYNC,
                            '--checksum',
                            '--archive',
                            '--delete',
                            '--verbose',
                            # '--omit-dir-times',
                            '--no-group',
                            '--no-perms',
                            # "--include=#{NAMED_CONF_FILE}",
                            "--include=#{File.basename(EXPORT_CONFIG_FILE)}",
                            "--include=#{VIEWS_FILE}",
                            "--include=*#{ZONES_FILE}",
                            "--include=*#{SLAVES_FILE}",
                            "--include=*#{REVERSE_FILE}",
                            "--include=*#{ZONES_DIR}/***",
                            "--include=*#{SLAVES_DIR}/***",
                            "--include=*#{REVERSE_DIR}/***",
                            '--exclude=*',
                            File.join(tmp_named_dir, ''),
                            File.join(config_dir, ''))
        @logger.debug "[GloboDns::Exporter][DEBUG] rsync:\n#{rsync_output}"

        #--- add all changed files to git's index
        # exec_as_bind('git add', Binaries::GIT, 'add', '-A')
        exec('git add', Binaries::GIT, 'add', '-A')

        #--- check status output; if there are no changes, just return
        git_status_output = exec('git status', Binaries::GIT, 'status')
        return if git_status_output =~ /nothing to commit \(working directory clean\)/

        #--- commit the changes
        # commit_output = exec_as_bind('git commit', Binaries::GIT, 'commit', "--author=#{GIT_AUTHOR}", "--date=#{@export_timestamp}", '-m', '"[GloboDns::exporter]"')
        commit_output = exec('git commit', Binaries::GIT, 'commit', "--author=#{GIT_AUTHOR}", "--date=#{@export_timestamp}", '-m', '"[GloboDns::exporter]"')
        @logger.info "[GloboDns::Exporter][INFO] changes committed:\n#{commit_output}"

        #--- get the new HEAD and dump it to the log
        new_head = (exec('git rev-parse', Binaries::GIT, 'rev-parse', 'HEAD')).chomp
        @logger.info "[GloboDns::Exporter][INFO] git repository new HEAD: #{new_head}"

        # reload_output = reload_bind_conf(chroot_dir)
        # @logger.info "[GloboDns::Exporter][INFO] bind configuration reloaded:\n#{reload_output}"

        [new_head, orig_head]
    rescue Exception => e
        if orig_head && (@options[:reset_repository_on_failure] != false)
            @logger.error(e.to_s + e.backtrace.join("\n"))
            reset_repository(orig_head, chroot_dir, (@options[:slave] == true) ? 'slave' : 'master')
        end
        raise e
    end

    def sync_remote_bind_and_reload(chroot_dir, remote)
        rsync_output = exec('remote rsync',
                            Binaries::RSYNC,
                            '--checksum',
                            '--archive',
                            '--delete',
                            '--verbose',
                            # '--omit-dir-times',
                            '--no-owner',
                            '--no-group',
                            '--no-perms',
                            "--include=#{File.basename(EXPORT_CONFIG_FILE)}",
                            "--include=#{VIEWS_FILE}",
                            "--include=*#{ZONES_FILE}",
                            "--include=*#{SLAVES_FILE}",
                            "--include=*#{REVERSE_FILE}",
                            "--include=*#{ZONES_DIR}/***",
                            "--include=*#{SLAVES_DIR}/***",
                            "--include=*#{REVERSE_DIR}/***",
                            '--exclude=*',
                            File.join(chroot_dir, EXPORT_CONFIG_DIR, ''),
                            "#{remote[:user]}@#{remote[:host]}:#{File.join(remote[:chroot_dir], EXPORT_CONFIG_DIR, '')}")

        rsync_output = exec('remote rsync',
                            Binaries::RSYNC,
                            '--inplace',
                            '--no-owner',
                            '--no-group',
                            '--no-perms',
                            '--verbose',
                            File.join(chroot_dir, EXPORT_CONFIG_DIR, File.basename(EXPORT_CONFIG_FILE)),
                            "#{remote[:user]}@#{remote[:host]}:#{File.join(remote[:chroot_dir], remote[:named_conf])}")

        reload_output = reload_bind_conf(chroot_dir)
        @logger.info "[GloboDns::Exporter][INFO] bind configuration reloaded:\n#{reload_output}"
    rescue Exception => e
        @logger.error(e.to_s + e.backtrace.join("\n"))
        raise e
    end

    def reload_bind_conf(chroot_dir)
        cmd_args = ['rndc reload', Binaries::RNDC, '-c', File.join(chroot_dir, RNDC_CONFIG_FILE), '-y', RNDC_KEY, 'reload']
        if @options[:abort_on_rndc_failure] == false
            exec!(*cmd_args)
        else
            exec(*cmd_args)
        end
    end

    def reset_repository(orig_head, chroot_dir, label = '')
        Dir.chdir(File.join(chroot_dir, EXPORT_CONFIG_DIR)) do
            @logger.info("[GloboDns::Exporter] resetting #{label} git repository")
            exec_as_bind('git reset', Binaries::GIT,  'reset', '--hard', orig_head) # try to rollback changes
            reload_bind_conf(chroot_dir) rescue nil
        end
    end

    def clean_checkconf_output(output)
        CHECKCONF_STANDARD_MESSAGES.inject(output) do |output, pattern|
            output.gsub(pattern, '')
        end
    end

end # Exporter
end # GloboDns
