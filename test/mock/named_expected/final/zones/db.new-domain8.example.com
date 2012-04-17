$ORIGIN new-domain8.example.com.
$TTL    86408

@                           IN SOA      ns8.example.com. root8.example.com. 2012030100 10808 3608 604808 7208
@                           IN NS       new-ns
@                           IN MX    18 new-mail
new-host1                   IN A        10.0.8.3
new-host2                   IN A        10.0.8.4
new-host2-anothername       IN A        10.0.8.4
new-mail                    IN A        10.0.8.2
new-ns                      IN A        10.0.8.1
new_host2alias              IN CNAME    new-host2.new-domain8.example.com.
new-host1alias              IN CNAME    new-host1
new-txt               86418 IN TXT      sample content for txt record
