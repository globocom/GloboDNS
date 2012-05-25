require 'polyglot'
require 'treetop'

treetop_file         = File.expand_path('../named_conf.treetop',   __FILE__)
compiled_parser_file = File.expand_path('../named_conf_parser.rb', __FILE__)
if File.mtime(treetop_file) > File.mtime(compiled_parser_file)
    puts "requiring 'treetop' grammar"
    Treetop.load File.expand_path('../named_conf.treetop', __FILE__)
else
    puts "requiring 'compiled' grammar"
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

    def import(chroot_dir)
        named_conf_path = File.join(chroot_dir, BIND_CONFIG_FILE)
        File.exists?(named_conf_path) or raise "[ERROR] BIND configuration file not found (\"#{named_conf_path}\")"

        # test zone files
        exec_as_root('named-checkconf', Binaries::CHECKCONF, '-z', '-t', chroot_dir, BIND_CONFIG_FILE)

        # generate canonical representation of the configuration file
        canonical_named_conf = exec_as_root('named-checkconf', Binaries::CHECKCONF, '-p', '-t', chroot_dir, BIND_CONFIG_FILE)

        # named_conf_file = Tempfile.new('named.conf')
        named_conf_file = File.new('/tmp/named.conf.' + ('%x' % (rand * 999999)), 'w')
        named_conf_file.write(canonical_named_conf)
        named_conf_file.close
        puts "[DEBUG] canonical bind configuration written to \"#{named_conf_file.path}\""

        parser = NamedConfParser.new
        root   = parser.parse(canonical_named_conf)
        if root.nil?
            STDERR.puts "[ERROR] unable to parse canonical bind configuration: #{parser.failure_reason}"
            # STDERR.puts p.instance_variable_get('@node_cache').inspect
        else
            root.chroot_dir = chroot_dir

            View.transaction do
                # ActiveRecord::Base.connection.execute "TRUNCATE `#{View.table_name}`"
                # ActiveRecord::Base.connection.execute "TRUNCATE `#{Domain.table_name}`"
                # ActiveRecord::Base.connection.execute "TRUNCATE `#{Record.table_name}`"
                Record.delete_all
                Domain.delete_all
                View.delete_all

                # find 'common/shared' domains
                domain_views = Hash.new
                root.views.each do |view|
                    view.domains.each do |domain|
                        domain_views[domain.name] ||= Array.new
                        domain_views[domain.name]  << view.name
                    end
                end
                common_domains = domain_views.select { |domain, views| views.size == root.views.size }

                # save each view and its respective domain
                root.views.each do |view|
                    domains = view.domains.clone
                    view.domains.clear
                    view.save or raise Exception.new("[ERROR] unable to save view #{view.name}: #{view.errors.full_messages}")

                    domains.each do |domain|
                        domain_views = common_domains[domain.name]

                        if domain_views == false
                            next
                        elsif domain_views.is_a?(Array)
                            common_domains[domain.name] = false
                            domain.view = nil
                        else
                            domain.view = view
                        end

                        puts "saving domain: #{domain.inspect} (soa: #{domain.soa_record.inspect})"
                        domain.save or raise Exception.new("[ERROR] unable to save domain #{domain.name}: #{domain.errors.full_messages} (soa: #{domain.soa_record.errors.full_messages})")
                    end
                end

            end

            GloboDns::Exporter.new.export_master(root.named_conf)
        end
    ensure
        if named_conf_file
            # named_conf_file.unlink
        end
    end

end # class Importer
end # module GloboDns
