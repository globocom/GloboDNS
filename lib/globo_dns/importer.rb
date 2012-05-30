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

String.class_eval do
    def strip_quotes
        self.sub(/^['"]?(.*?)['"]?$/, '\1')
    end
end

module GloboDns
class Importer

    include GloboDns::Config
    include GloboDns::Util

    def import(master_chroot_dir, slave_chroot_dir)
        named_conf_path = File.join(master_chroot_dir, BIND_CONFIG_FILE)
        File.exists?(named_conf_path) or raise "[ERROR] master BIND configuration file not found (\"#{named_conf_path}\")"

        named_conf_path = File.join(slave_chroot_dir, BIND_CONFIG_FILE)
        File.exists?(named_conf_path) or raise "[ERROR] slave BIND configuration file not found (\"#{named_conf_path}\")"

        # test zone files
        exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', master_chroot_dir, BIND_CONFIG_FILE)
        exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', slave_chroot_dir,  BIND_CONFIG_FILE)

        # generate canonical representation of the configuration file
        master_canonical_named_conf = exec_as_root('named-checkconf', Binaries::CHECKCONF, '-p', '-t', master_chroot_dir, BIND_CONFIG_FILE)
        slave_canonical_named_conf  = exec_as_root('named-checkconf', Binaries::CHECKCONF, '-p', '-t', slave_chroot_dir,  BIND_CONFIG_FILE)

        # write canonical representation to a tmp file, for debugging purposes
        File.open('/tmp/globodns.master.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
            file.write(master_canonical_named_conf)
            puts "[DEBUG] canonical master BIND configuration written to \"#{file.path}\""
        end

        File.open('/tmp/globodns.slave.named.conf.' + ('%x' % (rand * 999999)), 'w') do |file|
            file.write(slave_canonical_named_conf)
            puts "[DEBUG] canonical slave BIND configuration written to \"#{file.path}\""
        end

        # actually parse both configuration files; abort on error
        parser      = NamedConfParser.new
        master_root = parser.parse(master_canonical_named_conf) or raise RuntimeError.new("[ERROR] unable to parse canonical master BIND configuration: #{parser.failure_reason}")
        slave_root  = parser.parse(slave_canonical_named_conf)  or raise RuntimeError.new("[ERROR] unable to parse canonical slave BIND configuration: #{parser.failure_reason}")

        # set the chroot_dir; this is needed to find and parse the zone files
        master_root.chroot_dir = master_chroot_dir
        slave_root.chroot_dir  = slave_chroot_dir

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
                    domain_views[domain.name] ||= Array.new
                    domain_views[domain.name]  << view.name
                end
            end
            common_domains = domain_views.select { |domain, views| views.size == master_root.views.size }

            # save each view and its respective domains
            master_root.views.each do |view|
                domains = view.domains.clone
                view.domains.clear
                view.save or raise Exception.new("[ERROR] unable to save view #{view.name}: #{view.errors.full_messages}")

                domains.each do |domain|
                    domain_views = common_domains[domain.name]

                    if domain_views == false
                        next
                    elsif domain_views.is_a?(Array)
                        common_domains[domain.name] = false
                        domain.view = nil                    # shared/common domains are saved with a 'nil' View
                    else
                        domain.view = view
                    end

                    puts "saving domain: #{domain.inspect} (soa: #{domain.soa_record.inspect})"
                    domain.save or raise Exception.new("[ERROR] unable to save domain #{domain.name}: #{domain.errors.full_messages} (soa: #{domain.soa_record.errors.full_messages})")
                end
            end

        end

        # finally, regenerate/export the updated database
        GloboDns::Exporter.new.export_all(master_root.named_conf, slave_root.named_conf, :logger => Logger.new(STDOUT), :keep_tmp_dir => true)
    end

end # class Importer
end # module GloboDns
