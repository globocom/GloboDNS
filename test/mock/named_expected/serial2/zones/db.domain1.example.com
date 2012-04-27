$ORIGIN domain1.example.com.
$TTL    86401

@           IN SOA      ns1.example.com. root1.example.com. 2012030201 10801 3601 604801 7201
@           IN NS       ns
@           IN MX    10 mail
host1       IN A        10.0.1.3
host2       IN A        10.0.1.4
mail        IN A        10.0.1.2
ns          IN A        10.0.1.1
host1cname  IN CNAME    host1
host2alias  IN CNAME    host2.domain1.example.com.
