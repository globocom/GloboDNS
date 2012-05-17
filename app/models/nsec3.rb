# = NSEC3 Record version 3 (NSEC3)
#
# An extension to DNSSEC that allows proof of nonexistence for a name without
# permitting zonewalking

class NSEC3 < Record
    validates_presence_of :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::NSEC3
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
