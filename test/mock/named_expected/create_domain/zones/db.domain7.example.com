$ORIGIN domain7.example.com.
$TTL    86407

@                IN SOA      ns7.example.com. root7.example.com. 2012030200 10807 3607 604807 7207
@                IN NS       ns
@                IN MX    17 mail
host1            IN A        10.0.7.3
host2            IN A        10.0.7.4
host2other       IN A        10.0.7.4
mail             IN A        10.0.7.2
ns               IN A        10.0.7.1
host1alias       IN CNAME    host1
host2alias       IN CNAME    host2.domain7.example.com.
txt        86417 IN TXT      sample content for txt record
