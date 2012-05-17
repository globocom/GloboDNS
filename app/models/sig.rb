# = Signature Record (SIG)
#
# Signature record used in SIG(0) (RFC 2931) and TKEY (RFC 2930).[7] RFC 3755
# designated RRSIG as the replacement for SIG for use within DNSSEC.[7]

class SIG < Record
    validates_presence_of :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::SIG
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
