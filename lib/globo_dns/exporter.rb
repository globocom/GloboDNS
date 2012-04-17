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
        @last_commit_date = Time.at(exec('git last commit date', Binaries::GIT, 'log', '-1', '--format="%ct"').to_i)
        @export_timestamp = Time.now

        tmp_dir = Dir.mktmpdir
        @logger.debug "[GloboDns::exporter] tmp dir: #{tmp_dir}" if @options[:keep_tmp_dir] == true

        # FileUtils.cp_r does not preserve directory timestamps; use 'cp -a' instead
        # FileUtils.cp_r(File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR, '.'), tmp_dir, :preserve => true)
        exec('cp -a -p', 'cp', '-a', '-p', File.join(BIND_CHROOT_DIR, '.'), tmp_dir)
        tmp_named_dir = File.join(tmp_dir, BIND_CONFIG_DIR)
        puts "tmp named dir: #{tmp_named_dir}"

        # main configuration file
        export_named_conf(named_conf_content, tmp_named_dir) if named_conf_content.present?


        export_views(tmp_named_dir)
        export_domain_group(tmp_named_dir, ZONES_FILE,   ZONES_DIR,   Domain.master)
        export_domain_group(tmp_named_dir, REVERSE_FILE, REVERSE_DIR, Domain.reverse)
        export_domain_group(tmp_named_dir, SLAVES_FILE,  SLAVES_DIR,  Domain.slave)


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
        FileUtils.remove_entry_secure tmp_dir unless tmp_dir.nil? || @options[:keep_tmp_dir] == true
        Domain.connection.execute('UNLOCK TABLES') unless (@options[:lock_tables] == false)
    end
    
    private

    def export_named_conf(content, tmp_named_dir)
        File.open(named_conf_file = File.join(tmp_named_dir, NAMED_CONF_FILE), 'w') do |file|
            file.puts content
            file.puts
            file.puts CONFIG_START_TAG
            file.puts '# this block is auto generated; do not edit'
            file.puts
            file.puts "include \"#{File.join(BIND_CONFIG_DIR, VIEWS_FILE)}\";"
            file.puts "include \"#{File.join(BIND_CONFIG_DIR, ZONES_FILE)}\";"
            file.puts "include \"#{File.join(BIND_CONFIG_DIR, SLAVES_FILE)}\";"
            file.puts "include \"#{File.join(BIND_CONFIG_DIR, REVERSE_FILE)}\";"
            file.puts
            file.puts CONFIG_END_TAG
        end
        File.utime(@export_timestamp, @export_timestamp, named_conf_file)
    end

    def export_views(tmp_named_dir)
        abs_views_file = File.join(tmp_named_dir, VIEWS_FILE)

        File.open(abs_views_file, 'w') do |io|
        end

        File.utime(@export_timestamp, @export_timestamp, abs_views_file)
    end

    def export_domain_group(tmp_named_dir, file_name, dir_name, domains)
        abs_file_name = File.join(tmp_named_dir, file_name)
        abs_dir_name  = File.join(tmp_named_dir, dir_name)

        File.exists?(abs_dir_name) or FileUtils.mkdir(abs_dir_name)

        File.open(abs_file_name, 'w') do |io|
            domains.each do |domain|
                export_domain(domain, tmp_named_dir, io)
            end
        end

        File.utime(@export_timestamp, @export_timestamp, abs_dir_name)
        File.utime(@export_timestamp, @export_timestamp, abs_file_name)
    end

    def export_domain(domain, tmp_named_dir, zone_conf_file)
        zone_conf_file.puts domain.to_bind9_conf

        return if domain.slave?

        zone_file_name = File.join(tmp_named_dir, domain.zonefile_path)
        if domain.records.updated_since(@last_commit_date).exists?
            @logger.info "[GloboDns::exporter] generating file \"#{zone_file_name}\""
            domain.to_zonefile(zone_file_name)
        end
        File.utime(@export_timestamp, @export_timestamp, zone_file_name)
    end

    def remove_untouched_zonefiles(dir, timestamp)
        Dir.glob(File.join(dir, 'db.*')).each do |file|
            if File.mtime(file) < timestamp
                @logger.info "[INFO] removing untouched zonefile \"#{file}\""
                FileUtils.rm(file)
            end
        end
    end

    def run_checkconf(tmp_dir)
        exec('named-checkconf', Binaries::SUDO, Binaries::CHECKCONF, '-z', '-t', tmp_dir, BIND_CONFIG_FILE)
    end

    def sync_and_commit(tmp_named_dir)
        #--- sync to Bind9's data dir
        rsync_output = exec('rsync', Binaries::RSYNC,
                                     '--checksum',
                                     '--archive',
                                     '--delete',
                                     '--verbose',
                                     # '--omit-dir-times',
                                     '--no-group',
                                     '--no-perms',
                                     "--include=#{NAMED_CONF_FILE}",
                                     "--include=#{VIEWS_FILE}",
                                     "--include=#{ZONES_FILE}",
                                     "--include=#{SLAVES_FILE}",
                                     "--include=#{REVERSE_FILE}",
                                     "--include=#{SLAVES_DIR}/",
                                     "--include=#{ZONES_DIR}/",
                                     "--include=#{ZONES_DIR}/*",
                                     "--include=#{REVERSE_DIR}/",
                                     "--include=#{REVERSE_DIR}/*",
                                     '--exclude=*',
                                     File.join(tmp_named_dir, ''),
                                     File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR, ''))
        @logger.debug "[GloboDns::Exporter][DEBUG] rsync:\n#{rsync_output}"

        #--- commit changes to the git repository
        Dir.chdir(File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR))

        # save the current HEAD and dump it to the log
        orig_head = (exec('git rev-parse', Binaries::GIT, 'rev-parse', 'HEAD')).chomp
        @logger.info "[GloboDns::Exporter][INFO] git repository ORIG_HEAD: #{orig_head}"

        begin
            exec('git add', Binaries::GIT, 'add', '-A')

            git_status_output = exec('git commit', Binaries::GIT, 'status')
            unless git_status_output =~ /nothing to commit \(working directory clean\)/
                commit_output = exec('git commit', Binaries::GIT, 'commit', '-m', '"[GloboDns::exporter]"')
                @logger.info "[GloboDns::Exporter][INFO] changes committed:\n#{commit_output}"

                # setup file handle to read and report error messages from bind's 'error log'
                if err_log = File.open(BIND_ERROR_LOG, 'r') rescue nil
                    err_log.seek(err_log.size)
                else
                    @logger.warn "[GloboDns::Exporter][WARN] unable to open bind's error log file \"#{BIND_ERROR_LOG}\""
                end

                reload_output = reload_bind_conf
                @logger.info "[GloboDns::Exporter][INFO] bind configuration reloaded:\n#{reload_output}"
                # sleep 5 unless @options[:skip_sleep] == true

                # after reloading, read new entries from error log
                if err_log
                    entries = err_log.gets(nil)
                    err_log.close
                end

                test_changes if @options[:test_changes] && @options[:abort_on_test_failure]
            end
        rescue Exception => e
            @logger.error e.to_s + e.backtrace.join("\n")
            STDERR.puts   e, e.backtrace
            if @options[:reset_repository_on_failure]
                exec('git reset', Binaries::GIT,  'reset', '--hard', orig_head) # try to rollback changes
                reload_bind_conf
            end
            exit 1
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
