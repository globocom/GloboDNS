# = NSEC3 parameters Record (NSEC3PARAM)
# 
# Parameter record for use with NSEC3

class NSEC3PARAM < Record
    def resolv_resource_class
        Resolv::DNS::Resource::IN::NSEC3PARAM
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
