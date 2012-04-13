$ORIGIN domain1.example.com.
$TTL    86401

@                IN SOA       ns1.example.com. root1.example.com. 2012030101 10801 3601 604801 7201
@          86401 IN NS        new-ns
new-mx     86401 IN MX    123 mail
host2            IN A         10.0.1.4
mail             IN A         10.0.1.2
new-host1  10001 IN A         10.0.1.3
new-host3  10001 IN A         10.0.1.103
new-ns     86401 IN A         10.0.1.1
host2alias       IN CNAME     host2.domain1.example.com.
new-cname1 86401 IN CNAME     anyname.example.com.
