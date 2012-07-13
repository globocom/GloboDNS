require File.expand_path('../importer/util', __FILE__)

module GloboDns
class Importer

    include GloboDns::Config
    include GloboDns::Util

    def import(options = {})
        import_timestamp       = Time.now
        master_chroot_dir      = options.delete(:master_chroot_dir)      || BIND_MASTER_CHROOT_DIR
        master_named_conf_path = options.delete(:master_named_conf_file) || BIND_MASTER_NAMED_CONF_FILE
        slave_chroot_dir       = options.delete(:slave_chroot_dir)       || BIND_SLAVE_CHROOT_DIR
        slave_named_conf_path  = options.delete(:slave_named_conf_file)  || BIND_SLAVE_NAMED_CONF_FILE

        if options[:remote]
            master_tmp_dir = Dir.mktmpdir
            puts "[DEBUG] syncing master chroot dir to \"#{master_tmp_dir}\""
            exec('rsync remote master',
                 Binaries::RSYNC,
                 '--archive',
                 '--no-owner',
                 '--no-group',
                 '--no-perms',
                 '--verbose',
                 "#{BIND_MASTER_USER}@#{BIND_MASTER_HOST}:#{File.join(master_chroot_dir, '')}",
                 master_tmp_dir)
            master_chroot_dir = master_tmp_dir

            slave_tmp_dir = Dir.mktmpdir
            puts "[DEBUG] syncing slave chroot dir to \"#{slave_tmp_dir}\""
            exec('rsync remote slave',
                 Binaries::RSYNC,
                 '--archive',
                 '--no-owner',
                 '--no-group',
                 '--no-perms',
                 '--verbose',
                 "#{BIND_SLAVE_USER}@#{BIND_SLAVE_HOST}:#{File.join(slave_chroot_dir, '')}",
                 slave_tmp_dir)
            slave_chroot_dir = slave_tmp_dir
        end

        named_conf_path = File.join(master_chroot_dir, master_named_conf_path)
        File.exists?(named_conf_path) or raise "[ERROR] master BIND configuration file not found (\"#{named_conf_path}\")"

        named_conf_path = File.join(slave_chroot_dir, slave_named_conf_path)
        File.exists?(named_conf_path) or raise "[ERROR] slave BIND configuration file not found (\"#{named_conf_path}\")"

        # test zone files
        exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', master_chroot_dir, master_named_conf_path)
        exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', slave_chroot_dir,  slave_named_conf_path)

        # generate canonical representation of the configuration file
        master_canonical_named_conf = exec_as_root('named-checkconf', Binaries::CHECKCONF, '-p', '-t', master_chroot_dir, master_named_conf_path)
        slave_canonical_named_conf  = exec_as_root('named-checkconf', Binaries::CHECKCONF, '-p', '-t', slave_chroot_dir,  slave_named_conf_path)

        if options[:debug]
            # write canonical representation to a tmp file, for debugging purposes
            File.open('/tmp/globodns.canonical.master.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
                file.write(master_canonical_named_conf)
                puts "[DEBUG] canonical master BIND configuration written to \"#{file.path}\""
            end

            File.open('/tmp/globodns.canonical.slave.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
                file.write(slave_canonical_named_conf)
                puts "[DEBUG] canonical slave BIND configuration written to \"#{file.path}\""
            end
        end

        # load grammar
        Citrus.load(File.expand_path('../importer/named_conf.citrus', __FILE__))

        # process slave first, cache the filtered config and free the parsed
        # tree to free some memory
        slave_root = nil
        begin
            slave_root = NamedConf.parse(slave_canonical_named_conf)
        rescue Citrus::ParseError => e
            raise RuntimeError.new("[ERROR] unable to parse canonical slave BIND configuration (line #{e.line_number}, column #{e.line_offset}: #{e.line})")
        end

        slave_config   = slave_root.config
        slave_rndc_key = slave_root.rndc_key
        slave_root     = nil
        if options[:debug]
            File.open('/tmp/globodns.filtered.slave.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
                file.write(slave_config)
                puts "[DEBUG] filtered slave BIND configuration written to \"#{file.path}\""
            end
        end

        # now, process the master file
        master_root = nil
        begin
            master_root = NamedConf.parse(master_canonical_named_conf)
        rescue Citrus::ParseError => e
            raise RuntimeError.new("[ERROR] unable to parse canonical master BIND configuration (line #{e.line_number}, column #{e.line_offset}: #{e.line})")
        end

        master_config   = master_root.config
        master_rndc_key = master_root.rndc_key
        if options[:debug]
            # write filtered/parsed representation to a tmp file, for debugging purposes
            File.open('/tmp/globodns.filtered.master.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
                file.write(master_config)
                puts "[DEBUG] filtered master BIND configuration written to \"#{file.path}\""
            end
        end

        # disable auditing on all affected models
        View.disable_auditing
        Domain.disable_auditing
        Record.disable_auditing

        # save the 'View's and 'Domain's found by the parser to the DB
        # ActiveRecord::Base.connection.execute "TRUNCATE `#{View.table_name}`"
        # ActiveRecord::Base.connection.execute "TRUNCATE `#{Domain.table_name}`"
        # ActiveRecord::Base.connection.execute "TRUNCATE `#{Record.table_name}`"
        Record.delete_all
        Domain.delete_all
        View.delete_all

        # find 'common/shared' domains
        domain_views = Hash.new
        master_root.views.each do |view|
            view.domains.each do |domain|
                domain_views[domain.import_key] ||= Array.new
                domain_views[domain.import_key]  << view.name
            end
        end
        common_domains = domain_views.select { |domain_key, views|
            puts "[select common domains] domain: #{domain_key}; views.size: #{views.size}; master_root.views.size: #{master_root.views.size}"
            views.size == master_root.views.size
        }
        puts "common domains:\n    #{common_domains.keys.join("    \n")}"

        # save each view and its respective domains
        master_root.views.each do |view|
            unless view.model.save
                STDERR.puts("[ERROR] unable to save view #{view.name}: #{view.model.errors.full_messages}")
                next
            end

            while domain = view.domains.shift
                domain.chroot_dir = master_chroot_dir
                domain.bind_dir   = master_root.bind_dir
                domain_views      = common_domains[domain.import_key]

                unless domain.model && domain.model.soa_record
                    STDERR.puts "[ERROR] unable to build DB model from zone statement: #{domain.to_str}"
                    next
                end

                if domain_views == false
                    next
                elsif domain_views.is_a?(Array)
                    common_domains[domain.import_key] = false
                else
                    domain.model.view_id = view.model.id
                end

                puts "[view] saving domain: #{domain.model.inspect} (soa: #{domain.model.soa_record.inspect})"
                domain.model.save or STDERR.puts("[ERROR] unable to save domain #{domain.model.name}: #{domain.model.errors.full_messages} (soa: #{domain.model.soa_record.errors.full_messages})")
                domain.reset_model
            end
        end

        # save domains outside any views
        while domain = master_root.domains.shift
            domain.chroot_dir = master_chroot_dir
            domain.bind_dir   = master_root.bind_dir
            unless domain.model && domain.model.soa_record
                STDERR.puts "[ERROR} unable to build DB model from zone statement: #{domain.to_str}"
                next
            end
            puts "[standalone] saving domain: #{domain.model.inspect} (soa: #{domain.model.soa_record.inspect})"
            domain.model.save or STDERR.puts("[ERROR] unable to save domain #{domain.model.name}: #{domain.model.errors.full_messages} (soa: #{domain.model.soa_record.errors.full_messages})")
            domain.reset_model
        end

        # generate rdnc.conf files
        if master_rndc_key
            write_rndc_conf(EXPORT_MASTER_CHROOT_DIR, master_rndc_key, BIND_MASTER_IPADDR, BIND_MASTER_RNDC_PORT)
        else
            STDERR.puts "[WARNING] no rndc key found in master's named.conf"
            FileUtils.rm(File.join(EXPORT_MASTER_CHROOT_DIR, RNDC_CONFIG_FILE))
        end

        if slave_rndc_key
            write_rndc_conf(EXPORT_SLAVE_CHROOT_DIR, slave_rndc_key, BIND_SLAVE_IPADDR, BIND_SLAVE_RNDC_PORT)
        else
            STDERR.puts "[WARNING] no rndc key found in slave's named.conf"
            FileUtils.rm(File.join(EXPORT_SLAVE_CHROOT_DIR, RNDC_CONFIG_FILE))
        end

        # finally, regenerate/export the updated database
        if options[:export]
            GloboDns::Exporter.new.export_all(master_config, slave_config,
                                              :all                   => true,
                                              :keep_tmp_dir          => true,
                                              :abort_on_rndc_failure => false,
                                              :logger                => Logger.new(STDOUT))
        else
            save_config(master_config, EXPORT_MASTER_CHROOT_DIR, BIND_MASTER_ZONES_DIR, BIND_MASTER_NAMED_CONF_FILE, import_timestamp)
            save_config(slave_config,  EXPORT_SLAVE_CHROOT_DIR,  BIND_SLAVE_ZONES_DIR,  BIND_SLAVE_NAMED_CONF_FILE,  import_timestamp)
        end
    # ensure
        # FileUtils.remove_entry_secure master_tmp_dir unless master_tmp_dir.nil? || @options[:keep_tmp_dir] == true
        # FileUtils.remove_entry_secure slave_tmp_dir  unless slave_tmp_dir.nil?  || @options[:keep_tmp_dir] == true
    end

    def write_rndc_conf(chroot_dir, key_str, bind_host, bind_port)
        File.open(File.join(chroot_dir, RNDC_CONFIG_FILE), 'w') do |file|
            file.puts key_str
            file.puts ""
            file.puts "options {"
            file.puts "    default-key    \"#{RNDC_KEY_NAME}\";"
            file.puts "    default-server #{bind_host};"
            file.puts "    default-port   #{bind_port};" if bind_port
            file.puts "};"
        end
    end

    # saves *and commits the changes to git*
    def save_config(content, chroot_dir, zones_dir, named_conf_file, timestamp)
        Dir.chdir(File.join(chroot_dir, zones_dir)) do
            File.open(File.basename(named_conf_file), 'w') do |file|
                file.write(content)
            end

            exec('git add', Binaries::GIT, 'add', File.basename(named_conf_file))

            commit_output = exec('git commit', Binaries::GIT, 'commit', "--author=#{GIT_AUTHOR}", "--date=#{timestamp}", '-m', '"[GloboDns::importer]"')
            puts "[GloboDns::Importer] changes committed:\n#{commit_output}"
        end
    end

end # class Importer
end # module GloboDns
