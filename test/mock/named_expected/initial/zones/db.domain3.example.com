$ORIGIN domain3.example.com.
$TTL    86403

@  IN SOA  ns3.example.com. root3.example.com. 2012030100 10803 3603 604803 7203
@  IN NS   ns1.domain1.example.com.
