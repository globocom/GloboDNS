# See #MX

# = Mail Exchange Record (MX)
# Defined in RFC 1035. Specifies the name and relative preference of mail
# servers (mail exchangers in the DNS jargon) for the zone.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/mx.html
#
class MX < Record
    validates_numericality_of :prio, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 65535, :only_integer => true
    validates_with HostnameValidator, :attributes => :content
    validation_scope :warnings do |scope|
        scope.validate :validate_same_name_and_type   # validation_scopes doesn't support inheritance; we have to redefine this validation
        scope.validate :validate_indirect_local_cname
    end

    def supports_prio?
        true
    end

    def resolv_resource_class
        Resolv::DNS::Resource::IN::MX
    end

    def match_resolv_resource(resource)
        resource.preference == self.prio &&
        (resource.exchange.to_s == self.content.chomp('.') ||
         resource.exchange.to_s == (self.content + '.' + self.domain.name))
    end

    def validate_indirect_local_cname
        return if self.fqdn_content?

        cname = CNAME.where('domain_id' => self.domain_id, 'name' => self.content).first
        unless cname.nil? || cname.fqdn_content?
            self.warnings.add(:base, I18n.t('indirect_local_cname_mx', :scope => 'activerecord.errors.messages', :name => self.content, :replacement => cname.content))
        end
    end
end
