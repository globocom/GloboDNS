# = Next-secure Record (NSEC)
#
# The NSEC RR is part of the DNSSEC (DNSSEC.bis) standard. The NSEC RR points to
# the next valid name in the zone file and is used to provide proof of
# non-existense of any name within a zone. The last NSEC in a zone will point
# back to the zone root or apex. NSEC RRs are created using the dnssec-signzone
# utility supplied with BIND.
#
# Obtained from http://www.zytrax.com/books/dns/ch8/nsec.html

class NSEC < Record
    validates_presence_of :content

    def resolv_resource_class
        Resolv::DNS::Resource::IN::NSEC
    end

    def match_resolv_resource(resource)
        resource.strings.join(' ') == self.content.chomp('.')
    end
end
