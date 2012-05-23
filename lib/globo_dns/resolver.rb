module GloboDns
class Resolver
    include GloboDns::Config
    include GloboDns::Util

    def initialize(host, port)
        @host = host
        @port = port
    end

    MASTER = GloboDns::Resolver.new(BIND_MASTER_HOST, BIND_MASTER_PORT.to_i)
    SLAVE  = GloboDns::Resolver.new(BIND_SLAVE_HOST,  BIND_SLAVE_PORT.to_i)

    def resolve(record)
        name   = Record::fqdn(record.name, record.domain.name)
        source = record.domain.try(:view).try(:query_ip_address)

        args  = [Binaries::DIG, '@'+@host, '-p', @port.to_s, '-t', record.type]
        args += ['-b', source] if source
        args += [name, '+norecurse', '+time=1'] # , '+short']

        exec('dig', *args)
    end
end
end
