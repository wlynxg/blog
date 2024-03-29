# P2P 时遇到端口被改的坑

在尝试 Port Restricted Cone NAT  到 Port Restricted Cone NAT  的  P2P 时遇到一个很灵异的现象，UDP 套接字发往 STUN 的数据包能够正常回包，但是进行打洞时出现了端口被更改的现象。路由器上 tcpdump 抓包如下：

```
15:56:16.555958 IP 11.11.11.11.1065 > 22.22.22.22.23215: UDP, length 40
15:56:17.307864 IP 11.11.11.11.60094 > 33.33.33.33.3478: UDP, length 40
15:56:17.309272 IP 11.11.11.11.60094 > 44.44.44.44.3478: UDP, length 40
```

可以发现发往 33.33.33.33 和 44.44.44.44 两个 STUN 服务器的 src port 是正常的，但是发往 22.22.22.22 的 src port 却被改为了 1065.

经过排查后，发现如果 22.22.22.22:23215 在 11.11.11.11.60094 发送过数据包之前到达了路由器，路由器会将端口更改为另外一个随机端口（应该是一种防火墙规则，防止udp端口被外部碰撞攻击）。

解决方案：

**更改打洞流程，打洞时采用短 ttl 包打开本地防火墙，再使用正常 ttl 的包来建立连接。**