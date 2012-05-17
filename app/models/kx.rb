# = Key eXchanger Record (KX)
#
# Used with some cryptographic systems (not including DNSSEC) to identify a key
# management agent for the associated domain-name. Note that this has nothing to
# do with DNS Security. It is Informational status, rather than being on the
# IETF standards-track. It has always had limited deployment, but is still in
# use.

class KX < Record
    validates_presence_of :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::KX
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
