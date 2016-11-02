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

require File.expand_path('../importer/util', __FILE__)

module GloboDns

class Importer
    include GloboDns::Config
    include GloboDns::Util
    include SyslogHelper

    attr_reader :logger

    def import(options = {})
        import_timestamp        = Time.now
        master_chroot_dir       = options.delete(:master_chroot_dir)      || Bind::Master::CHROOT_DIR
        master_named_conf_path  = options.delete(:master_named_conf_file) || Bind::Master::NAMED_CONF_FILE
        slaves_chroot_dirs      = options.delete(:slave_chroot_dir)       || Bind::Slaves.map { |slave| slave::CHROOT_DIR }
        slaves_named_conf_paths = options.delete(:slave_named_conf_file)  || Bind::Slaves.map { |slave| slave::NAMED_CONF_FILE }
        @logger                 = GloboDns::StringIOLogger.new(options.delete(:logger) || Rails.logger)
        slaves_canonical_named_conf = []

        if options[:remote]
            master_tmp_dir = Dir.mktmpdir
            logger.debug "syncing master chroot dir to \"#{master_tmp_dir}\""
            puts "#{Bind::Master::USER}@#{Bind::Master::HOST}:#{File.join(master_chroot_dir, '')}"
            exec('rsync remote master',
                 Binaries::RSYNC,
                 '--archive',
                 '--no-owner',
                 '--no-group',
                 '--no-perms',
                 '--verbose',
                 '--exclude=session.key',
                 "#{Bind::Master::USER}@#{Bind::Master::HOST}:#{File.join(master_chroot_dir, '')}",
                 master_tmp_dir)
            master_chroot_dir = master_tmp_dir

            if SLAVE_ENABLED?
                Bind::Slaves.each_with_index do |slave, index|
                  slave_tmp_dir = Dir.mktmpdir
                  logger.debug "syncing slave chroot dir to \"#{slave_tmp_dir}\""
                  exec('rsync remote slave',
                       Binaries::RSYNC,
                       '--archive',
                       '--no-owner',
                       '--no-group',
                       '--no-perms',
                       '--verbose',
                       '--exclude=session.key',
                       "#{slave::USER}@#{slave::HOST}:#{File.join(slaves_chroot_dirs[index], '')}",
                       slave_tmp_dir)
                  slaves_chroot_dirs[index] = slave_tmp_dir
                end
            end
        end

        named_conf_path = File.join(master_chroot_dir, master_named_conf_path)
        File.exists?(named_conf_path) or raise "master BIND configuration file not found (\"#{named_conf_path}\")"
        # test zone files
        exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', master_chroot_dir, master_named_conf_path)
        # generate canonical representation of the configuration file
        master_canonical_named_conf = exec_as_root('named-checkconf', Binaries::CHECKCONF, '-p', '-t', master_chroot_dir, master_named_conf_path)

        if SLAVE_ENABLED?
          Bind::Slaves.each_with_index do |slave, index|
            named_conf_path = File.join(slaves_chroot_dirs[index], slaves_named_conf_paths[index])
            File.exists?(named_conf_path) or raise "slave #{index+1} BIND configuration file not found (\"#{named_conf_path}\")"
            # test zone files
            exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', slaves_chroot_dirs[index],  slaves_named_conf_paths[index]) if slave::HOST
            # generate canonical representation of the configuration file
            slaves_canonical_named_conf << exec_as_root('named-checkconf', Binaries::CHECKCONF, '-p', '-t', slaves_chroot_dirs[index],  slaves_named_conf_paths[index]) if slave::HOST
          end #each
        end #if


        if options[:debug]
            # write canonical representation to a tmp file, for debugging purposes
            File.open('/tmp/globodns.canonical.master.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
                file.write(master_canonical_named_conf)
                logger.debug "canonical master BIND configuration written to \"#{file.path}\""
            end

            if SLAVE_ENABLED?
                Bind::Slaves.each_with_index do |slave, index|
                    File.open("/tmp/globodns.canonical.slave-#{index+1}.named.conf." + ('%x' % (rand * 999999)), 'w') do |file|
                        file.write(slaves_canonical_named_conf[index])
                        logger.debug "canonical slave BIND configuration for slave #{index+1} written to \"#{file.path}\""
                    end
                end
            end
        end

        # load grammar
        Citrus.load(File.expand_path('../importer/named_conf.citrus', __FILE__))

        # process slave first, cache the filtered config and free the parsed
        # tree to free some memory
        if SLAVE_ENABLED?
            slaves_configs   = []
            slaves_rndc_keys = []
            Bind::Slaves.each_with_index do |slave, index|
                slave_root = nil
                begin
                    slave_root = NamedConf.parse(slaves_canonical_named_conf[index])
                rescue Citrus::ParseError => e
                    raise RuntimeError.new("[ERROR] unable to parse canonical slave BIND configuration for slave #{index+1} (line #{e.line_number}, column #{e.line_offset}: #{e.line})")
                end

                slaves_configs << slave_root.config
                slaves_rndc_keys << slave_root.rndc_key
                slave_root     = nil
                if options[:debug]
                    File.open("/tmp/globodns.filtered.slave-#{index+1}.named.conf." + ('%x' % (rand * 999999)), 'w') do |file|
                        file.write(slave_root.config)
                        logger.debug "filtered slave BIND configuration for slave #{index+1} written to \"#{file.path}\""
                    end
                end
            end
        end

        # now, process the master file
        master_root = nil
        begin
            master_root = NamedConf.parse(master_canonical_named_conf)
        rescue Citrus::ParseError => e
            raise RuntimeError.new("[ERROR] unable to parse canonical master BIND configuration #{master_canonical_named_conf} (line #{e.line_number}, column #{e.line_offset}: #{e.line})")
        end

        master_config   = master_root.config
        master_rndc_key = master_root.rndc_key
        if options[:debug]
            # write filtered/parsed representation to a tmp file, for debugging purposes
            File.open('/tmp/globodns.filtered.master.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
                file.write(master_config)
                logger.debug "filtered master BIND configuration written to \"#{file.path}\""
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
            views.size == master_root.views.size
        }

        # save each view and its respective domains
        master_root.views.each do |view|
            logger.info "saving view: #{view.model.inspect}"
            unless view.model.save
                logger.error("unable to save view #{view.name}: #{view.model.errors.full_messages}")
                next
            end

            while domain = view.domains.shift
                domain.chroot_dir = master_chroot_dir
                domain.bind_dir   = master_root.bind_dir
                domain.logger     = logger
                domain_views      = common_domains[domain.import_key]

                unless domain.model && domain.model.soa_record
                    logger.error "unable to build DB model from zone statement: #{domain.to_str}"
                    next
                end

                if domain_views == false
                    next
                elsif domain_views.is_a?(Array)
                    common_domains[domain.import_key] = false
                else
                    domain.model.view_id = view.model.id
                end


                # Look for a sibling, and merge replicated records.
                domain.model.set_sibling()

                logger.info "  saving domain: #{domain.model.inspect} (soa: #{domain.model.soa_record.inspect})"

                domain.model.save or logger.error("unable to save domain #{domain.model.name}: #{domain.model.errors.full_messages} (soa: #{domain.model.soa_record.errors.full_messages})")
                domain.reset_model
            end
        end

        # save domains outside any views
        logger.info "viewless domains:"
        while domain = master_root.domains.shift
            domain.chroot_dir = master_chroot_dir
            domain.bind_dir   = master_root.bind_dir
            domain.logger     = logger

            unless domain.model && domain.model.soa_record
                logger.error "unable to build DB model from zone statement: #{domain.to_str}"
                next
            end

            logger.info "  saving domain: #{domain.model.inspect} (soa: #{domain.model.soa_record.inspect})"
            domain.model.save or logger.error("unable to save domain #{domain.model.name}: #{domain.model.errors.full_messages} (soa: #{domain.model.soa_record.errors.full_messages})")
            domain.reset_model
        end

        # generate rdnc.conf files
        if master_rndc_key
            write_rndc_conf(Bind::Master::EXPORT_CHROOT_DIR, master_rndc_key, Bind::Master::IPADDR, Bind::Master::RNDC_PORT)
        else
            logger.warn "no rndc key found in master's named.conf"
            FileUtils.rm(File.join(Bind::Master::EXPORT_CHROOT_DIR, RNDC_CONFIG_FILE))
        end

        if SLAVE_ENABLED?
            Bind::Slaves.each_with_index do |slave, index|
                if slaves_rndc_keys[index]
                    write_rndc_conf(slave::EXPORT_CHROOT_DIR, slaves_rndc_keys[index], slave::IPADDR, slave::RNDC_PORT)
                else
                    logger.warn "no rndc key found in slave's named.conf for slave #{index+1}"
                    FileUtils.rm(File.join(slave::EXPORT_CHROOT_DIR, RNDC_CONFIG_FILE))
                end
            end
        end

        # finally, regenerate/export the updated database
        if options[:export]
            GloboDns::Exporter.new.export_all(master_config, slaves_configs,
                                              :all                   => true,
                                              :keep_tmp_dir          => true,
                                              :abort_on_rndc_failure => false,
                                              :logger                => logger)
        else
            #save_config(master_config, Bind::Master::EXPORT_CHROOT_DIR, Bind::Master::ZONES_DIR, Bind::Master::NAMED_CONF_FILE, import_timestamp)
            save_config(master_config, Bind::Master::EXPORT_CHROOT_DIR, File.dirname(Bind::Master::NAMED_CONF_FILE) , Bind::Master::NAMED_CONF_FILE, import_timestamp)
            Bind::Slaves.each_with_index do |slave, index|
                #save_config(slaves_configs[index],  slave::EXPORT_CHROOT_DIR,  slave::ZONES_DIR,  slave::NAMED_CONF_FILE,  import_timestamp) if SLAVE_ENABLED?
                save_config(slaves_configs[index],  slave::EXPORT_CHROOT_DIR,  File.dirname(slave::NAMED_CONF_FILE),  slave::NAMED_CONF_FILE,  import_timestamp) if SLAVE_ENABLED?
            end
        end

        syslog_info('import successful')
        Notifier.import_successful(logger).deliver_now
    rescue Exception => e
        syslog_error 'import failed'
        Notifier.import_failed("#{e}\n\n#{logger}\n\nBacktrace:\n#{e.backtrace.join("\n")}").deliver_now
        raise e
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
    def save_config(content, chroot_dir, target_dir, named_conf_file, timestamp)
        Dir.chdir(File.join(chroot_dir, target_dir)) do
            File.open(File.basename(named_conf_file), 'w') do |file|
                file.write(content)
                file.puts GloboDns::Exporter::CONFIG_START_TAG
                file.puts "# imported on #{timestamp}"
                file.puts GloboDns::Exporter::CONFIG_END_TAG
            end

            exec('git add', Binaries::GIT, 'add', '.')
            commit_output = exec('git commit', Binaries::GIT, 'commit', "--author=#{GIT_AUTHOR}", "--date=#{timestamp}", '-am', '"[GloboDns::importer]"')
            logger.info "import changes committed:\n#{commit_output}"
        end
    end
end # class Importer

end # module GloboDns
