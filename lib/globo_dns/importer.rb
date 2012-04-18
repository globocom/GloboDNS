require File.expand_path('../../../config/environment', __FILE__)

module GloboDns
class Importer
    include GloboDns::Config

    # import BIND9 configuration into the MySQL database (other DBs currently
    # not supported) using the zone2sql utility from PowerDNS
    #
    # options:
    #    :use_fqdn             => add ending '.' to record names when appropriate (default: true)
    #    :strip_domain_name    => remove the domain name of record names; requires :use_fqdn (default: true)
    #    :set_at_symbol        => replace the domain name with '@'; requires :use_fqdn (default: true)
    #    :remove_rfc1912_zones => remove 'localhost' and '1.0.0.127' zones from the DB (default: true)
    #
    def import(options = {})
        ActiveRecord::Base.connection.execute "TRUNCATE `#{Domain.table_name}`"
        ActiveRecord::Base.connection.execute "TRUNCATE `#{Record.table_name}`"

        IO::popen([Binaries::SUDO,
                   Binaries::CHROOT,
                   BIND_CHROOT_DIR,
                   Binaries::ZONE2SQL,
                   '--gmysql',
                   '--transactions',
                   "--named-conf=#{BIND_CONFIG_FILE}"]) do |io|
            while buffer = io.gets
                ActiveRecord::Base.connection.execute buffer
            end
        end

        set_timestamps

        unless options[:use_fqdn] == false
            set_fqdn
            strip_domain_name unless options[:strip_domain_name] == false
            set_at_symbol unless options[:set_at_symbol]     == false
        end

        unless options[:remove_rfc1912_zones] == false
            remove_rfc1912_zones
        end
    end

    private

    def set_timestamps
        now = Time.now
        Domain.update_all('created_at' => now, 'updated_at' => now)
        Record.update_all('created_at' => now, 'updated_at' => now)
    end

    def set_fqdn
        Record.joins(:domain).update_all(["#{Record.table_name}.name = CONCAT(#{Record.table_name}.name, '.')"], ["(SUBSTRING(#{Record.table_name}.name, - LENGTH(#{Domain.table_name}.name)) = #{Domain.table_name}.name) AND (SUBSTRING(#{Record.table_name}.name, -1) <> '.') AND (SUBSTRING(#{Domain.table_name}.name, -1) <> '.')"])
    end

    def strip_domain_name
        Record.joins(:domain).update_all(["#{Record.table_name}.name = SUBSTRING(#{Record.table_name}.name, 1, LENGTH(#{Record.table_name}.name) - LENGTH(#{Domain.table_name}.name) - 2)"], ["(SUBSTRING(#{Record.table_name}.name, - LENGTH(#{Domain.table_name}.name) - 1, LENGTH(#{Domain.table_name}.name)) = #{Domain.table_name}.name) AND (SUBSTRING(#{Record.table_name}.name, 1, LENGTH(#{Record.table_name}.name) - LENGTH(#{Domain.table_name}.name) - 2) <> '')"])
    end

    def set_at_symbol
        Record.joins(:domain).update_all(["#{Record.table_name}.name = '@'"], ["#{Record.table_name}.name = CONCAT(#{Domain.table_name}.name, '.')"])
    end

    def remove_rfc1912_zones
        Domain.destroy_all('name' => ['localhost.localdomain',
                                      'localhost',
                                      '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa',
                                      '1.0.0.127.in-addr.arpa',
                                      '0.in-addr.arpa'])
    end

end # Importer
end # GloboDns
