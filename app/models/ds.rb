# = DS Record (DS)
#
# The Delegated Signer RR is part of the DNSSEC (DNSSEC.bis) standard. It
# appears at the point of delegation in the parent zone and contains a digest of
# the DNSKEY RR used as either a Zone Signing Key (ZSK) or a Key Signing Key
# (KSK). It is used to authenticate the chain of trust from the parent to the
# child zone. The DS RR is optionally created using the dnssec-signzone utility
# supplied with BIND.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/ds.html

class DS < Record
    validates_presence_of :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::DS
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
