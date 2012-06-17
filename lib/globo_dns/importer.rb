require 'polyglot'
require 'treetop'

treetop_file         = File.expand_path('../importer/named_conf.treetop',   __FILE__)
compiled_parser_file = File.expand_path('../importer/named_conf_parser.rb', __FILE__)
if File.mtime(treetop_file) > File.mtime(compiled_parser_file)
    Treetop.load treetop_file
else
    require compiled_parser_file
end

# Treetop::Runtime::SyntaxNode.class_eval do
#     alias :old_inspect :inspect
#     def inspect(indent = '')
#         self.terminal? ? '' : old_inspect(indent)
#     end
# end

module GloboDns
class Importer

    include GloboDns::Config
    include GloboDns::Util

    def import(options = {})
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

        # actually parse both configuration files; abort on error
        parser      = NamedConfParser.new
        master_root = parser.parse(master_canonical_named_conf) or raise RuntimeError.new("[ERROR] unable to parse canonical master BIND configuration: #{parser.failure_reason}")
        slave_root  = parser.parse(slave_canonical_named_conf)  or raise RuntimeError.new("[ERROR] unable to parse canonical slave BIND configuration: #{parser.failure_reason}")

        # set the chroot_dir; this is needed to find and parse the zone files
        master_root.chroot_dir = master_chroot_dir
        slave_root.chroot_dir  = slave_chroot_dir

        if options[:debug]
            # write filtered/parsed representation to a tmp file, for debugging purposes
            File.open('/tmp/globodns.filtered.master.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
                file.write(master_root.named_conf)
                puts "[DEBUG] filtered master BIND configuration written to \"#{file.path}\""
            end

            File.open('/tmp/globodns.filtered.slave.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
                file.write(slave_root.named_conf)
                puts "[DEBUG] filtered slave BIND configuration written to \"#{file.path}\""
            end
        end

        # disable auditing on all affected models
        View.disable_auditing
        Domain.disable_auditing
        Record.disable_auditing

        # save the 'View's and 'Domain's found by the parser to the DB
        View.transaction do
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
            common_domains = domain_views.select { |domain, views|
                puts "[select common domains] domain: #{domain}; views.size: #{views.size}; master_root.views.size: #{master_root.views.size}"
                views.size == master_root.views.size
            }
            puts "common domains:\n#{common_domains.awesome_inspect}"

            # save each view and its respective domains
            master_root.views.each do |view|
                domains = view.domains.clone
                view.domains.clear
                view.save or raise Exception.new("[ERROR] unable to save view #{view.name}: #{view.errors.full_messages}")

                domains.each do |domain|
                    domain_views = common_domains[domain.import_key]

                    if domain_views == false
                        next
                    elsif domain_views.is_a?(Array)
                        common_domains[domain.import_key] = false
                        domain.view = nil                    # shared/common domains are saved with a 'nil' View
                    else
                        domain.view = view
                    end

                    puts "[view] saving domain: #{domain.inspect} (soa: #{domain.soa_record.inspect}) (object_id: #{domain.object_id})"
                    domain.save or raise Exception.new("[ERROR] unable to save domain #{domain.name}: #{domain.errors.full_messages} (soa: #{domain.soa_record.errors.full_messages})")
                end
            end

            # save domains outside any views
            master_root.domains.each do |domain|
                puts "[standalone] saving domain: #{domain.inspect} (soa: #{domain.soa_record.inspect}) (object_id: #{domain.object_id})"
                domain.save or raise Exception.new("[ERROR] unable to save domain #{domain.name}: #{domain.errors.full_messages} (soa: #{domain.soa_record.errors.full_messages})")
            end
        end

        # finally, regenerate/export the updated database
        if options[:export]
            GloboDns::Exporter.new.export_all(master_root.named_conf, slave_root.named_conf,
                                              :all                   => true,
                                              :keep_tmp_dir          => true,
                                              :abort_on_rndc_failure => false,
                                              :logger                => Logger.new(STDOUT))
        else
            # save the new named.conf files to the local chroots
            File.open(File.join(EXPORT_MASTER_CHROOT_DIR, EXPORT_CONFIG_FILE), 'w')  do |file|
                file.write(master_root.named_conf)
            end

            File.open(File.join(EXPORT_SLAVE_CHROOT_DIR, EXPORT_CONFIG_FILE), 'w')  do |file|
                file.write(slave_root.named_conf)
            end
        end
    ensure
        # FileUtils.remove_entry_secure master_tmp_dir unless master_tmp_dir.nil? || @options[:keep_tmp_dir] == true
        # FileUtils.remove_entry_secure slave_tmp_dir  unless slave_tmp_dir.nil?  || @options[:keep_tmp_dir] == true
    end

end # class Importer
end # module GloboDns
