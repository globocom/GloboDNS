# = DNSSEC Lookaside Validation Record (DLV)
#
# For publishing DNSSEC trust anchors outside of the DNS delegation chain. Uses
# the same format as the DS record. RFC 5074 describes a way of using these
# records.

class DLV < Record
    validates_presence_of :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::DLV
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
