require File.expand_path('../../../config/environment', __FILE__)

require 'globo_dns/config'
require 'globo_dns/util'

module GloboDns
class Exporter
    include GloboDns::Config
    include GloboDns::Util

    def export_all(options = {})
        @options = options
        @logger  = @options.delete(:logger) || Rails.log

        Dir.mktmpdir do |tmp_dir|
            #--- regular zone records
            File.open(File.join(tmp_dir, ZONES_FILE), 'w') do |file|
                Domain.standard.each do |domain|
                    file.puts domain.to_bind9_conf
                end
            end

            Dir.mkdir(File.join(tmp_dir, ZONES_DIR))
            Domain.standard.each do |domain|
                next if domain.slave?
                export_domain(domain, tmp_dir)
            end

            #--- then, reverse zone records
            File.open(File.join(tmp_dir, REVERSE_FILE), 'w') do |file|
                Domain.reverse.each do |domain|
                    file.puts domain.to_bind9_conf
                end
            end

            Dir.mkdir(File.join(tmp_dir, REVERSE_DIR))
            Domain.reverse.each do |domain|
                next if domain.slave?
                export_domain(domain, tmp_dir)
            end

            #--- and, finally, the slaves + stubs + forwards
            File.open(File.join(tmp_dir, SLAVES_FILE), 'w') do |file|
                Domain.slave.each do |domain|
                    file.puts domain.to_bind9_conf
                end
            end

            #--- sync generated files on the tmp dir to the one monitored by bind
            sync_and_commit(tmp_dir)

            #--- test the changes by parsing the git commit log
            test_changes if @options[:test_changes]
        end
    end
    
    private

    def export_domain(domain, tmp_dir)
        @logger.info "[GloboDns::exporter] generating file \"#{domain.zonefile_path}\""
        format = build_record_format(domain)
        File.open(File.join(tmp_dir, domain.zonefile_path), 'w') do |file|
            export_records(domain.records.order("FIELD(type, #{RECORD_ORDER.map{|x| "'#{x}'"}.join(', ')}), name ASC"), file, format)
        end
    end

    def export_records(records, file, format)
        return if records.nil?

        records = Array[records]                if records.is_a?(Record)
        records = records.includes(:domain).all if records.is_a?(ActiveRecord::Relation)

        records.collect do |record|
            file.print record.to_zonefile(format)
        end
    end

    def build_record_format(domain)
        sizes = domain.records.select('MAX(LENGTH(name)) AS name, LENGTH(MAX(ttl)) AS ttl, MAX(LENGTH(type)) AS mtype, LENGTH(MAX(prio)) AS prio').first
        "%-#{sizes.name}s %-#{sizes.ttl}d IN %-#{sizes.mtype}s %-#{sizes.prio}s %s\n"
    end

    def sync_and_commit(tmp_dir)
        #--- sync to Bind9's data dir
        rsync_output = exec('rsync', Binaries::RSYNC,
                                     '--checksum',
                                     '--archive',
                                     '--delete',
                                     '--verbose',
                                     '--omit-dir-times',
                                     '--no-group',
                                     '--no-perms',
                                     "--include=#{ZONES_FILE}",
                                     "--include=#{ZONES_DIR}/",
                                     "--include=#{ZONES_DIR}/*",
                                     "--include=#{REVERSE_DIR}/",
                                     "--include=#{REVERSE_DIR}/*",
                                     '--exclude=*',
                                     File.join(tmp_dir, ''),
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
                sleep 5

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
