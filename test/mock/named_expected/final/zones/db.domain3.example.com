$ORIGIN domain3.example.com.
$TTL    86403

@                    IN SOA    ns3.example.com. root3.example.com. 2012030101 10803 3603 604803 7203
@                    IN NS     ns1.domain1.example.com.
new-host1      10021 IN A      10.0.3.101
new-host1alias 86403 IN CNAME  new-host1
new-txt        86403 IN TXT    meaningless content
