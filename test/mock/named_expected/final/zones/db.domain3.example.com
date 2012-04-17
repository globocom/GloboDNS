$ORIGIN domain3.example.com.
$TTL    86403

@                    IN SOA    ns3.example.com. root3.example.com. 2012030101 10803 3603 604803 7203
@                    IN NS     ns3.example.com.
new-host1      86431 IN A      10.0.3.1
new-host1alias       IN CNAME  new-host1
new-txt              IN TXT    meaningless content
