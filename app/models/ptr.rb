# = Name Server Record (PTR)
#
# Pointer records are the opposite of A and AAAA RRs and are used in Reverse Map
# zone files to map an IP address (IPv4 or IPv6) to a host name.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/ptr.html

class PTR < Record
    include RecordPatterns

    validates_with HostnameValidator, :attributes => :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::PTR
    end

    def match_resolv_resource(resource)
        resource.name.to_s == self.content.chomp('.') ||
        resource.name.to_s == (self.content + '.' + self.domain.name)
    end

    def validate_name_format
        unless self.name.blank? || self.name == '@' || reverse_ipv4_fragment?(self.name) || reverse_ipv6_fragment?(self.name)
            self.errors.add(:name, I18n.t('invalid', :scope => 'activerecord.errors.messages'))
        end
    end
end
