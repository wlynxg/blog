# tun2socks 原理分析

## 简介

`tun` 是一种位于 **网络层** 的虚拟网卡，从 `tun` 读取和写入的数据都是 **网络层**的数据。而 Socks 是一种使用 Socket 代理的技术，代理的是会话层的流量。

因此想要将从 `tun` 出来的流量塞到 socks 代理，就需要**去除  网络层和 传输层的 Header**；而想要将 Socks 回来的数据塞到 Tun，则需要在流量前面**增加 网络层 和 传输层的 Header**。

下面介绍两种市面上使用较多的方案。

## 系统网络栈

在启用 `tun` 网卡时，同时监听一个对应传输层协议的 socket。当从 `tun` 网卡读取到网络包后，改变网络包的四元组（源IP改为 tun 网卡 IP，源端口更换为一个随机端口，目的 IP 和 目的端口改为监听的 Socket 的IP和端口），再将网络包写回 `tun` 网卡。

当网络包写回系统网络栈后，系统会自行转发包到监听的 socket，从监听的 socket 中读取的数据就是已经去除了 网络层和传输层 header 的数据。

要注意的是，在发送数据包的过程中需要记忆改变前后的四元组（NAT 映射）。当 socket 返回数据时，从 tun 网卡读取数据，再改变回原始的映射关系。

这样就利用系统网络栈实现了 tun2socks。

## gVisor 协议栈

`gVisor` 是谷歌开发实现的容器沙箱。在 `gVisor` 中实现了一套较为完整的网络协议栈。

`gVisor`中提供了不同层网络协议包的解析以及读取，因此我们可以利用 `gVisor` 对 网络包解析来实现 tun2socks。

