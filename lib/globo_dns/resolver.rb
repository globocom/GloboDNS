module GloboDns
class Resolver
    include GloboDns::Config
    include GloboDns::Util

    DEFAULT_PORT = 53

    def initialize(host, port)
        @host = host
        @port = port
    end

    MASTER = GloboDns::Resolver.new(BIND_MASTER_IPADDR, (BIND_MASTER_PORT rescue DEFAULT_PORT).to_i)
    SLAVE  = GloboDns::Resolver.new(BIND_SLAVE_IPADDR,  (BIND_SLAVE_PORT  rescue DEFAULT_PORT).to_i)

    def resolve(record)
        name      = Record::fqdn(record.name, record.domain.name)
        key_name  = record.domain.try(:query_key_name)
        key_value = record.domain.try(:query_key)

        args  = [Binaries::DIG, '@'+@host, '-p', @port.to_s, '-t', record.type]
        args += ['-y', "#{key_name}:#{key_value}"] if key_name && key_value
        args += [name, '+norecurse', '+noauthority', '+time=1'] # , '+short']

        exec!('dig', *args)
    end
end
end
