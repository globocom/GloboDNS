$ORIGIN new-domain1.view1.example.com.
$TTL    86421

@           IN SOA      ns1.example.com. root1.example.com. 2012030100 10811 3611 604811 7211
@           IN NS       ns1.example.com.
@           IN MX    10 host4
host1       IN A        10.1.1.1
host4       IN A        10.1.1.4
new-host3   IN A        10.1.1.3
host1alias  IN CNAME    host1
