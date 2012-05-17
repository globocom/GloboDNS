# = DNSSEC signature Record (RRSIG)
#
# The RRSIG RR is part of the DNSSEC (DNSSEC.bis) standard. Each RRset in a
# signed zone will have an RRSIG RR containing a digest of the RRset created
# using a DNSKEY RR Zone Signing Key (ZSK). RRSIG RRs are unique in that they do
# not form RRsets - were this not so recursive signing would occur! RRSIG RRs
# are automatically created using the dnssec-signzone utility supplied with
# BIND.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/rrsig.html

class RRSIG < Record
    validates_presence_of :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::RRSIG
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
