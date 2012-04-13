$ORIGIN new-domain8.example.com.
$TTL    86408

@              86408 IN SOA      ns1.new-domain8.example.com. contact.new-domain8.example.com. 2012030100 10808 3608 604808 7208
@              86408 IN NS       new-ns
@              86408 IN MX    11 new-mx
new-host1      86408 IN A        10.0.8.3
new-host2      86408 IN A        10.0.8.4
new-mx         86408 IN A        10.0.8.2
new-ns         86408 IN A        10.0.8.1
new_host2alias 86408 IN CNAME    new-host2.new-domain8.example.com.
new-host1alias 86408 IN CNAME    new-host1
new-txt        86408 IN TXT      sample content for txt record
