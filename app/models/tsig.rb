# = Transaction Signature Record (TSIG)
#
# Can be used to authenticate dynamic updates as coming from an approved client,
# or to authenticate responses as coming from an approved recursive name
# server[10] similar to DNSSEC.

class TSIG < Record
    def resolv_resource_class
        Resolv::DNS::Resource::IN::TSIG
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
