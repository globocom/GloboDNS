$ORIGIN domain1.view1.example.com.
$TTL    86411

@           IN SOA    ns1.example.com. root1.example.com. 2012030200 10811 3611 604811 7211
@           IN NS     ns1.example.com.
host1       IN A      10.1.1.1
host2       IN A      10.1.1.2
host3       IN A      10.1.1.3
host1alias  IN CNAME  host1
