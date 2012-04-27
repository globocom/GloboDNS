$ORIGIN domain2.view1.example.com.
$TTL    86422

@      IN SOA  ns2.example.com. root2.example.com. 2012030201 10812 3612 604812 7212
@      IN NS   ns2.example.com.
host1  IN A    10.1.2.1
