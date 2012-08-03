# = IPSEC key Record (IPSECKEY)
#
# Key record that can be used with IPSEC (http://en.wikipedia.org/wiki/IPSEC")

class IPSECKEY < Record
    def resolv_resource_class
        Resolv::DNS::Resource::IN::IPSECKEY
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
