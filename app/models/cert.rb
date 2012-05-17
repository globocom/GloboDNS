# = Certificate Record (CERT)
#
# Stores PKIX, SPKI, PGP, etc.

class CERT < Record
    validates_presence_of :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::CERT
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
