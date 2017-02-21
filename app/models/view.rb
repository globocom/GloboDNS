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

class View < ActiveRecord::Base
    include SyslogHelper

    RFC1912_NAME = '__rfc1912'
    ANY_NAME     = '__any'

    attr_accessible :name

    audited :protect => false

    has_many :domains

    validates_presence_of :name, :key
    validates_associated  :domains

    before_validation :generate_key, :on => :create

    attr_accessible :name, :clients, :destinations
    
    scope :default, -> {
                        default_view = View.where(name: 'default').first || View.new
                        default_view.name ||= 'default'
                        default_view.clients ||= 'any;'
                        default_view.save
                        default_view
                    }

    def updated_since?(timestamp)
        self.updated_at > timestamp
    end

    def after_audit
        syslog_audit(self.audits.last)
    end

    def zones_dir
        'views/' + self.name + '-' + GloboDns::Config::ZONES_DIR
    end
    
    def zones_file
        'views/' + self.name + '-' + GloboDns::Config::ZONES_FILE
    end

    def default_zones_file
        'views/' + self.name + '-' + GloboDns::Config::ZONES_DIR + '-default.conf'
    end

    def slaves_dir
        'views/' + self.name + '-' + GloboDns::Config::SLAVES_DIR
    end

    def slaves_file
        'views/' + self.name + '-' + GloboDns::Config::SLAVES_FILE
    end

    def default_slaves_file
        'views/' + self.name + '-' + GloboDns::Config::SLAVES_DIR + '-default.conf'
    end

    def forwards_dir
        'views/' + self.name + '-' + GloboDns::Config::FORWARDS_DIR
    end

    def forwards_file
        'views/' + self.name + '-' + GloboDns::Config::FORWARDS_FILE
    end

    def default_forwards_file
        'views/' + self.name + '-' + GloboDns::Config::FORWARDS_DIR + '-default.conf'
    end    

    def reverse_dir
        'views/' + self.name + '-' + GloboDns::Config::REVERSE_DIR
    end

    def reverse_file
        'views/' + self.name + '-' + GloboDns::Config::REVERSE_FILE
    end

    def default_reverse_file
        'views/' + self.name + '-' + GloboDns::Config::REVERSE_DIR + '-default.conf'
    end

    def self.key_name(view_name)
        view_name + '-key'
    end

    def key_name
        self.class.key_name(self.name)
    end

    def default?
        self == View.default
    end

    def all_domains_names
        domains_names = []
        self.domains.each do |domain|
            domains_names.push domain.name
        end
        domains_names
    end

    ### views masters zones methods
    def domains_master_names
        self.domains.pluck(:name)
    end

    def domains_master_default_only
        # zones that are only at default view
        Domain.where(id: View.default.domains.master.where.not(name: self.domains_master_names).pluck(:id))
    end

    def domains_master
        # domains_master_view + domains_master_default
        ids = self.domains.master.pluck(:id) + View.default.domains.master.where.not(name: self.domains_master_names).pluck(:id)
        Domain.where(id: ids.uniq)
        
    end

    ### views reverse zones methods
    def domains_reverse_named
        domains_names = []
        self.domains._reverse.each do |domain|
            domains_names.push domain.name
        end 
        domains_names
    end

    def domains_reverse
        ids = self.domains._reverse.pluck(:id) + View.default.domains._reverse.where.not(name: self.domains_reverse_names).pluck(:id)
        Domain.where(id: ids.uniq)
    end


    ### views slaves zones methods
    def domains_slave_names
        domains_names = []
        self.domains.slave.each do |domain|
            domains_names.push domain.name
        end 
        domains_names
    end

    def domains_slave
        ids = self.domains.slave.pluck(:id) + View.default.domains.slave.where.not(name: self.domains_slave_names).pluck(:id)
        Domain.where(id: ids.uniq)
    end

    ### views forwards zones methods
    def domains_forward_names
        domains_names = []
        self.domains.forward.each do |domain|
            domains_names.push domain.name
        end
        domains_names
    end

    def domains_forward  
        ids = self.domains.forward.pluck(:id) + View.default.domains.forward.where.not(name: self.domains_forward_names).pluck(:id)
        Domain.where(id: ids.uniq)
    end


    ### views masters, reverses or slaves zones methods
    def domains_master_or_reverse_or_slave_names
        domains_names = []
        self.domains.master_or_reverse_or_slave.each do |domain|
            domains_names.push domain.name
        end
        domains_names
    end

    def domains_master_or_reverse_or_slave
        ids = self.domains.master_or_reverse_or_slave.pluck(:id) + View.default.domains.master_or_reverse_or_slave.where.not(name: self.domains_master_or_reverse_or_slave_names).pluck(:id)
        Domain.where(id: ids.uniq)
    end

    def domains_master_or_reverse_or_slave_default_only
        # zones that are only at default view
        Domain.where(id: View.default.domains.master_or_reverse_or_slave.where.not(name: self.domains_master_or_reverse_or_slave_names).pluck(:id))
    end

    def to_bind9_conf(zones_dir, indent = '', slave=false)
        match_clients = self.clients.present? ? self.clients.split(/\s*;\s*/) : Array.new

        if self.key.present?
            # use some "magic" to figure out the local address used to connect
            # to the master server
            # local_ipaddr = %x(ip route get #{GloboDns::Config::BIND_MASTER_IPADDR})
            local_ipaddr = IO::popen([GloboDns::Config::Binaries::IP, 'route', 'get', GloboDns::Config::Bind::Master::IPADDR]) { |io| io.read }
            local_ipaddr = local_ipaddr[/src (#{RecordPatterns::IPV4}|#{RecordPatterns::IPV6})/, 1]

            # then, exclude this address from the list of "match-client"
            # addresses to force the view match using the "key" property
            match_clients.delete("!#{local_ipaddr}") unless self.default?
            match_clients.unshift("!#{local_ipaddr}") unless self.default?

            # additionally, exclude the slave's server address (to enable it to
            # transfer the zones from the view that doesn't match its IP address)
            # unless self.default?
                GloboDns::Config::Bind::Slaves.each do |slave|
                    match_clients.delete("!#{slave::IPADDR}")
                    match_clients.unshift("!#{slave::IPADDR}") 
                end

                key_str = "key \"#{self.key_name}\""
                match_clients.delete(key_str)
                match_clients.unshift(key_str)
            # end
        end

        str  = ""
        # unless self.default?
            str << "#{indent}key \"#{self.key_name}\" {\n"
            str << "#{indent}    algorithm hmac-md5;\n"
            str << "#{indent}    secret \"#{self.key}\";\n"
            str << "#{indent}};\n"
            str << "\n"
        # end
        str << "#{indent}view \"#{self.name}\" {\n"
        str << "#{indent}    match-clients      { #{match_clients.uniq.join('; ')}; };\n" if match_clients.present?
        str << "#{indent}    match-destinations { #{self.destinations}; };\n"             if self.destinations.present?
        str << "\n"

        
        str << "#{indent}    include \"#{File.join(zones_dir, self.zones_file)}\";\n"
        str << "#{indent}    include \"#{File.join(zones_dir, self.slaves_file)}\";\n"
        str << "#{indent}    include \"#{File.join(zones_dir, self.forwards_file)}\";\n"
        str << "#{indent}    include \"#{File.join(zones_dir, self.reverse_file)}\";\n"
        str << "\n"


        unless self == View.default
            str << "#{indent}    include \"#{File.join(zones_dir, self.default_zones_file)}\";\n" unless slave
            str << "#{indent}    include \"#{File.join(zones_dir, self.default_forwards_file)}\";\n"
            str << "#{indent}    include \"#{File.join(zones_dir, self.default_reverse_file)}\";\n" unless slave
            str << "\n"
        end

        str << "#{indent}};\n\n"
        str
    end

    def generate_key
        Tempfile.open('globodns-key') do |file|
            GloboDns::Util::exec('rndc-confgen', GloboDns::Config::Binaries::RNDC_CONFGEN, '-a', '-r', '/dev/urandom', '-c', file.path, '-k', self.key_name)
            self.key = file.read[/algorithm\s+hmac\-md5;\s*secret\s+"(.*?)";/s, 1];
        end
    end
end
