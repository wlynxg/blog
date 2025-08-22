```bash
# 连接带宽限制
iptables -A OUTPUT -o eth0 -m hashlimit --hashlimit-above 3000kb/s --hashlimit-mode dstip,dstport --hashlimit-name out -j DROP

iptables -A INPUT -i eth0 -m hashlimit --hashlimit-above 3000kb/s --hashlimit-mode srcip,srcport --hashlimit-name in -j DROP
```