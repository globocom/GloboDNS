require File.expand_path('../../../config/environment', __FILE__)

require 'globo_dns/config'
require 'globo_dns/util'

module GloboDns
class Tester < ActiveSupport::TestCase
    include GloboDns::Config
    include GloboDns::Util

    def initialize(*args)
        super(args)
    end

    def teardown
        # nothing to do
    end

    def setup
        # parse diff output and save records to be tested
        Dir.chdir(File.join(BIND_CHROOT_DIR, BIND_CONFIG_DIR))

        log_output = exec('git log', Binaries::GIT, '--no-pager', 'log', '--stat', '-p', '-1')
        # Rails.logger.debug "[GloboDns::Tester::git] git log -1:\n#{log_output}"

        @added_domains, @removed_domains, @modified_domains = Hash.new, Hash.new, Hash.new
        added_domain,  removed_domain = Array.new, Array.new

        log_output.each_line do |line|
            if line =~ /^\+\+\+ \/dev\/null$/
                added_domain = nil
            elsif line =~ /^\+\+\+ b\/(?:#{ZONES_DIR}|#{REVERSE_DIR})\/db\.(.*)$/
                added_domain = $1
            elsif line =~ /^\-\-\- \/dev\/null$/
                removed_domain = nil
            elsif line =~ /^\-\-\- a\/(?:#{ZONES_DIR}|#{REVERSE_DIR})\/db\.(.*)$/
                removed_domain = $1
            elsif line =~ /^([\+\-])([\S]+)\s*(\d+)?\s+IN\s+([A-Z]+)\s*(\d+)?\s+(.*)$/
                domain, domain_list = if added_domain == removed_domain
                                          [added_domain, @modified_domains]
                                      elsif added_domain.nil? && !removed_domain.nil?
                                          [removed_domain, @removed_domains]
                                      elsif !added_domain.nil? && removed_domain.nil?
                                          [added_domain, @added_domains]
                                      else
                                          raise "[ERROR] invalid domain operation"
                                      end
            domain_list[domain] ||= Array.new
            domain_list[domain] <<  {:domain => domain, :op => $1, :name => $2, :ttl => $3, :type => $4, :prio => $5, :content => $6}
            end
        end

        true
    end

    def run_all
        setup
        self.public_methods.grep(/test_/).each do |method_name|
            m = self.method(method_name)
            m.call if m.parameters.empty?
        end
    end

    def test_added_domains
        @added_domains.each do |domain, records|
            puts "[GloboDns::Tester::added] \"#{domain}\""
            test_added_domain(domain, records)
            puts "[GloboDns::Tester::added] \"#{domain}\": ok"
        end
        true
    end

    def test_removed_domains
        @removed_domains.each do |domain, records|
            puts "[GloboDns::Tester::removed] \"#{domain}\""
            test_removed_domain(domain, records)
            puts "[GloboDns::Tester::removed] \"#{domain}\": ok"
        end
        true
    end

    def test_modified_domains
        @modified_domains.each do |domain, records|
            puts "[GloboDns::Tester::modified] \"#{domain}\""
            test_modified_domain(domain, records)
            puts "[GloboDns::Tester::modified] \"#{domain}\": ok"
        end
        true
    end

    private

    def test_added_domain(domain, records)
        log_test 'added', 'domain' do
            db_domain = Domain.where('name' => domain).first
            refute_nil db_domain
        end

        records.each do |record|
            test_record(record, domain, 'added')
        end
    end

    def test_removed_domain(domain, records)
        log_test 'removed', 'domain' do
            db_domain = Domain.where('name' => domain).first
            assert_nil db_domain
        end

        records.each do |record|
            test_record(record, domain, 'removed')
        end
    end

    def test_modified_domain(domain, records)
        log_test 'modified', 'domain' do
            db_domain = Domain.where('name' => domain).first
            refute_nil db_domain
        end

        tested_records = Hash.new
        records.each do |record|
            next unless record[:op] == '+'
            test_record(record, domain, 'modified')
            tested_records[Record::fqdn(record[:name], domain) + ':' + record[:type]] = true
        end

        records.each do |record|
            next unless record[:op] == '-' && !tested_records.include?(Record::fqdn(record[:name], domain) + ':' + record[:type])
            test_record(record, domain, 'modified')
        end
    end

    def test_record(record, domain, category_label = '')
        log_test category_label, "record: #{record[:name]}/#{record[:type]}:" do
            db_records = Record.joins(:domain).
                                where("#{Domain.table_name}.name" => domain).
                                where("#{Record.table_name}.name" => possible_record_names(record[:name], domain)).
                                where("#{Record.table_name}.type" => record[:type]).
                                all
            resources = resolver.getresources(Record::fqdn(record[:name], domain), Record::resolv_resource_class(record[:type]))
            match_resolve_resources_against_db_records(resources, db_records)
        end
    end

    def test_added_record(record, domain, category_label = '')
        log_test category_label, "record: #{record[:name]}/#{record[:type]}:" do
            db_records = Record.joins(:domain).
                                where("#{Domain.table_name}.name" => domain).
                                where("#{Record.table_name}.name" => possible_record_names(record[:name], domain)).
                                where("#{Record.table_name}.type" => record[:type]).
                                all
            refute db_records.empty?

            resources = resolver.getresources(Record::fqdn(record[:name], domain), Record::resolv_resource_class(record[:type]))
            refute resources.empty?, "no resources found (domain: #{domain}, name: #{record[:name]}, type: #{record[:type]})"
            match_resolve_resources_against_db_records(resources, db_records)
        end
    end

    def test_removed_record(record, domain, category_label = '')
        log_test category_label, "record: #{record[:name]}/#{record[:type]}:" do
            db_records = Record.joins(:domain).
                                where("#{Domain.table_name}.name" => domain).
                                where("#{Record.table_name}.name" => possible_record_names(record[:name], domain)).
                                where("#{Record.table_name}.type" => record[:type]).
                                all

            assert db_records.empty?
            assert_raises Resolv::ResolvError do resolver.getresource(Record::fqdn(record[:name], domain), Record::resolv_resource_class(record[:type])) end
        end
    end

    def log_test(category, name)
        print "[GloboDns::Tester#{category ? '::' + category : ''}]     #{name}:"
        yield
        print " ok\n"
    end

    def possible_record_names(name, domain)
        fqdn_name   = Record::fqdn(name, domain)
        fqdn_domain = domain + '.' if domain[-1] != '.'

        names  = Array.new
        names << name
        names << fqdn_name   if name[-1]  != '.'
        names << fqdn_domain if name      == '@'
        names << '@'         if fqdn_name == fqdn_domain
        names
    end

    def match_resolve_resources_against_db_records(resources, db_records)
        # trivial first check: matching sizes
        assert resources.size == db_records.size, "resources and db_records sizes do not match (#{resources.size} = #{db_records.size})"

        resources.each do |resource|
            # the db_records array should only be empty after the last loop iteration
            refute db_records.empty?, "db_records.empty? prematurely (on resource #{resource.inspect})"

            # no db_record was found that matches the give resource
            refute_nil db_records.reject! { |db_record| db_record.match_resolv_resource(resource) }, "resource #{resource.inspect} found no match"
        end

        # after the loop is finished, the db_records array should be empty; if it's not,
        # it means that one or more resources were not found
        assert db_records.empty?, "db_records not empty? #{db_records.inspect}"
    end

end # Tester
end # GloboDns
