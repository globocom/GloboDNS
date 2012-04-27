require File.expand_path('../../../config/environment', __FILE__)

module GloboDns
class Exporter
    include GloboDns::Config
    include GloboDns::Util

    CONFIG_START_TAG = '### BEGIN GloboDns ###'
    CONFIG_END_TAG   = '### END GloboDns ###'

    def export_all(named_conf_content, options = {})
        @options     = options
        @logger      = @options.delete(:logger) || Rails.logger

        Domain.connection.execute("LOCK TABLE #{Domain.table_name} READ, #{Record.table_name} READ") unless (@options[:lock_tables] == false)

        # get last commit timestamp and the export/current timestamp
        Dir.chdir(File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR))
        @last_commit_date = Time.at(exec('git last commit date', Binaries::GIT, 'log', '-1', '--format=%at').to_i)
        @export_timestamp = Time.now
        @touch_timestamp  = @export_timestamp + 1 # we add 1 second to avoid minor subsecond discrepancies
                                                  # when comparing each file's mtime with the @export_times

        tmp_dir = Dir.mktmpdir
        @logger.debug "[GloboDns::exporter] tmp dir: #{tmp_dir}" if @options[:keep_tmp_dir] == true
        File.chmod(02770, tmp_dir)
        FileUtils.chown(nil, BIND_GROUP, tmp_dir)
        File.umask(0007)


        # FileUtils.cp_r does not preserve directory timestamps; use 'cp -a' instead
        # FileUtils.cp_r(File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR, '.'), tmp_dir, :preserve => true)
        # exec('rsync chroot', Binaries::SUDO, '-u', BIND_USER, 'rsync', '-a', '--exclude', '.git/', File.join(BIND_CHROOT_DIR, '.'), tmp_dir)
        # top_level_dir = BIND_CONFIG_DIR.sub(/(#{File::SEPARATOR}.*?)#{File::SEPARATOR}.*/, '\1/') 
        exec('rsync chroot', 'rsync', '-v', '-a', '--exclude', 'session.key', '--exclude', '.git/', File.join(BIND_CHROOT_DIR, '.'), tmp_dir)

        tmp_named_dir = File.join(tmp_dir, BIND_CONFIG_DIR)

        # main configuration file
        export_named_conf(named_conf_content, tmp_named_dir) if named_conf_content.present?


        export_views(tmp_named_dir)
        export_domain_group(tmp_named_dir, ZONES_FILE,   ZONES_DIR,   Domain.noview.master)
        export_domain_group(tmp_named_dir, REVERSE_FILE, REVERSE_DIR, Domain.noview._reverse)
        export_domain_group(tmp_named_dir, SLAVES_FILE,  SLAVES_DIR,  Domain.noview.slave)


        # remove files that older than the export timestamp; these are the
        # zonefiles from domains that have been removed from the database
        # (otherwise they'd have been regenerated or 'touched')
        # remove_untouched_zonefiles(zones_dir,   @export_timestamp)
        # remove_untouched_zonefiles(reverse_dir, @export_timestamp)
        remove_untouched_zonefiles(File.join(tmp_named_dir, ZONES_DIR), @export_timestamp)
        remove_untouched_zonefiles(File.join(tmp_named_dir, REVERSE_DIR), @export_timestamp)


        # validate configuration with 'named-checkconf'
        run_checkconf(tmp_dir)


        # sync generated files on the tmp dir to the one monitored by bind
        sync_and_commit(tmp_named_dir)

        # test the changes by parsing the git commit log
        test_changes if @options[:test_changes]
    ensure
        # FileUtils.remove_entry_secure tmp_dir unless tmp_dir.nil? || @options[:keep_tmp_dir] == true
        Domain.connection.execute('UNLOCK TABLES') unless (@options[:lock_tables] == false)
    end
    
    private

    def export_named_conf(content, tmp_named_dir)
        content.gsub!("\r\n", "\n")
        content.sub!(/\A[\s\n]+/, '')
        content.sub!(/[\s\n]*\Z/, "\n")

        File.open(named_conf_file = File.join(tmp_named_dir, NAMED_CONF_FILE), 'w') do |file|
            file.puts content
            file.puts
            file.puts CONFIG_START_TAG
            file.puts '# this block is auto generated; do not edit'
            file.puts
            file.puts "include \"#{File.join(BIND_CONFIG_DIR, VIEWS_FILE)}\";"
            file.puts
            file.puts "view \"__any\" {"
            file.puts "    include \"#{File.join(BIND_CONFIG_DIR, ZONES_FILE)}\";"
            file.puts "    include \"#{File.join(BIND_CONFIG_DIR, SLAVES_FILE)}\";"
            file.puts "    include \"#{File.join(BIND_CONFIG_DIR, REVERSE_FILE)}\";"
            file.puts "};"
            file.puts
            file.puts CONFIG_END_TAG
        end
        File.utime(@touch_timestamp, @touch_timestamp, named_conf_file)
    end

    def export_views(tmp_named_dir)
        abs_views_file = File.join(tmp_named_dir, VIEWS_FILE)

        File.open(abs_views_file, 'w') do |file|
            View.all.each do |view|
                file.puts view.to_bind9_conf
                export_domain_group(tmp_named_dir, view.zones_file,   view.zones_dir,   view.domains.master,   view.updated_since?(@last_commit_date))
                export_domain_group(tmp_named_dir, view.slaves_file,  view.slaves_dir,  view.domains.slave,    view.updated_since?(@last_commit_date))
                export_domain_group(tmp_named_dir, view.reverse_file, view.reverse_dir, view.domains._reverse, view.updated_since?(@last_commit_date))
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
                @logger.debug "[DEBUG] writing zonefile for domain #{domain.name} (last updated: #{domain.updated_at}; repo: #{@last_commit_date}) (domain.updated?: #{domain.updated_since?(@last_commit_date)}; domain.records.updated?: #{domain.records.updated_since(@last_commit_date).first})"
                domain.to_zonefile(File.join(tmp_named_dir, domain.zonefile_path)) unless domain.slave?
            end

            # write entries to index file (<domain_type>.conf) and update 'mtime'
            # of *all* non-slave domains, so that we may use the mtime as a criteria
            # to identify the zonefiles that have been removed from BIND's config
            domains.each do |domain|
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
        # exec('named-checkconf', Binaries::SUDO, Binaries::CHECKCONF, '-z', '-t', tmp_dir, BIND_CONFIG_FILE)
        exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', tmp_dir, BIND_CONFIG_FILE)
    end

    def sync_and_commit(tmp_named_dir)
        #--- change to the bind config dir
        Dir.chdir(File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR))

        #--- save the current HEAD and dump it to the log
        orig_head = (exec('git rev-parse', Binaries::GIT, 'rev-parse', 'HEAD')).chomp
        @logger.info "[GloboDns::Exporter][INFO] git repository ORIG_HEAD: #{orig_head}"

        begin
            #--- sync to Bind9's data dir
            rsync_output = exec_as_bind('rsync',
                                        Binaries::RSYNC,
                                        '--checksum',
                                        '--archive',
                                        '--delete',
                                        '--verbose',
                                        # '--omit-dir-times',
                                        '--no-group',
                                        '--no-perms',
                                        "--include=#{NAMED_CONF_FILE}",
                                        "--include=#{VIEWS_FILE}",
                                        "--include=*#{ZONES_FILE}",
                                        "--include=*#{SLAVES_FILE}",
                                        "--include=*#{REVERSE_FILE}",
                                        "--include=*#{ZONES_DIR}/***",
                                        "--include=*#{SLAVES_DIR}/***",
                                        "--include=*#{REVERSE_DIR}/***",
                                        '--exclude=*',
                                        File.join(tmp_named_dir, ''),
                                        File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR, ''))
            @logger.debug "[GloboDns::Exporter][DEBUG] rsync:\n#{rsync_output}"

            #--- add all changed files to git's index
            exec_as_bind('git add', Binaries::GIT, 'add', '-A')

            #--- check status output; if there are no changes, just return
            git_status_output = exec('git commit', Binaries::GIT, 'status')
            return if  git_status_output =~ /nothing to commit \(working directory clean\)/

            #--- commit the changes
            commit_output = exec_as_bind('git commit', Binaries::GIT, 'commit', "--date=#{@export_timestamp}", '-m', '"[GloboDns::exporter]"')
            @logger.info "[GloboDns::Exporter][INFO] changes committed:\n#{commit_output}"

            # setup file handle to read and report error messages from bind's 'error log'
            # if err_log = File.open(BIND_ERROR_LOG, 'r') rescue nil
            #     err_log.seek(err_log.size)
            # else
            #     @logger.warn "[GloboDns::Exporter][WARN] unable to open bind's error log file \"#{BIND_ERROR_LOG}\""
            # end

            reload_output = reload_bind_conf
            @logger.info "[GloboDns::Exporter][INFO] bind configuration reloaded:\n#{reload_output}"
            # sleep 5 unless @options[:skip_sleep] == true

            # after reloading, read new entries from error log
            # if err_log
            #     entries = err_log.gets(nil)
            #     err_log.close
            # end

            test_changes if @options[:test_changes] && @options[:abort_on_test_failure]
        rescue Exception => e
            @logger.error(e.to_s + e.backtrace.join("\n"))
            unless @options[:reset_repository_on_failure] == false
                @logger.info('[GloboDns::Exporter][INFO] resetting git repository')
                exec_as_bind('git reset', Binaries::GIT,  'reset', '--hard', orig_head) # try to rollback changes
                reload_bind_conf rescue nil
            end
            raise e
        end
    end

    def reload_bind_conf
        exec('rndc reload', Binaries::RNDC, '-c', RNDC_CONFIG_FILE, '-y', RNDC_KEY, 'reload')
    end

    def test_changes
        # TODO: move the tests inside the 'begin; rescue;' block above, to
        # ensure we revert the changes when any test fails; or make this
        # optional, using a key in the config file
        tester = GloboDns::Tester.new
        tester.setup
        tester.run
    end

end # Exporter
end # GloboDns
