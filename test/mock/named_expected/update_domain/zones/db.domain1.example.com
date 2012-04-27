$ORIGIN domain1.example.com.
$TTL    86401

@                IN SOA      ns1.example.com. root1.example.com. 2012030200 10801 3601 604801 7201
@                IN NS       new-ns
@                IN MX    21 new-mx
mail             IN A        10.0.1.2
new-host1  86421 IN A        10.0.1.3
new-host3  86411 IN A        10.0.1.5
new-ns           IN A        10.0.1.1
host2alias       IN CNAME    host2.domain1.example.com.
new-cname1       IN CNAME    new-host1
