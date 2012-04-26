$ORIGIN domain1.view3.example.com.
$TTL    86413

@      IN SOA  ns3.example.com. root3.example.com. 2012030100 10813 3613 604813 7213
@      IN NS   ns3.example.com.
host1  IN A    10.1.3.1
host2  IN A    10.1.3.2
