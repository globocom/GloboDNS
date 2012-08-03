# = Canonical Name Record (CNAME)
#
# A CNAME record maps an alias or nickname to the real or Canonical name which
# may lie outside the current zone. Canonical means expected or real name.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/cname.html

class CNAME < Record
    include RecordPatterns

    validates_with HostnameValidator, :attributes => :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::CNAME
    end

    def match_resolv_resource(resource)
        resource.name.to_s == self.content.chomp('.') ||
        resource.name.to_s == (self.content + '.' + self.domain.name)
    end

    def validate_name_format
        unless self.name.blank? || self.name == '@' || hostname?(self.name) || reverse_ipv4_fragment?(self.name) || reverse_ipv6_fragment?(self.name)
            self.errors.add(:name, I18n.t('invalid', :scope => 'activerecord.errors.messages'))
        end
    end
end
