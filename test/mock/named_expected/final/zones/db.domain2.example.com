$ORIGIN domain2.example.com.
$TTL    86402

@     IN SOA  ns2.example.com. root2.example.com. 2012030101 10802 3602 604802 7202
@     IN NS   ns
mail  IN A    10.0.2.2
ns    IN A    10.0.2.1
