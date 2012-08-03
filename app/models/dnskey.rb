# = DNSKEY Record (NSKEY)
#
# The DNSKEY RR is part of the DNSSEC (DNSSEC.bis) standard. DNSKEY RRs contain
# the public key (of an asymmetric encryption algorithm) used in zone signing
# operations. Public keys used for other functions are defined using a KEY RR.
# DNSKEY RRs may be either a Zone Signing Key (ZSK) or a Key Signing Key (KSK).
# The DNSKEY RR is created using the dnssec-keygen utility supplied with BIND.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/dskey.html

class DNSKEY < Record
    def resolv_resource_class
        Resolv::DNS::Resource::IN::DNSKEY
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
