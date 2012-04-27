$ORIGIN new-domain4.example.com.
$TTL    86404

@  IN SOA  ns4.example.com. root4.example.com. 2012030200 10804 3604 604804 7204
@  IN NS   ns4.example.com.
