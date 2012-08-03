# = DNS Trust Authorities Record (TA)
#
# Part of a deployment proposal for DNSSEC without a signed DNS root. See
# the IANA database and Weiler Spec for details. Uses the same format as the DS
# record.

class TA < Record
    def resolv_resource_class
        Resolv::DNS::Resource::IN::TA
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
