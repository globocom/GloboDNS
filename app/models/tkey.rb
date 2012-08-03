# = TSIG key Record (TKEY)
#
# A method of providing keying material to be used with TSIG that is encrypted
# under the public key in an accompanying KEY RR.[9]

class TKEY < Record
    def resolv_resource_class
        Resolv::DNS::Resource::IN::TKEY
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
