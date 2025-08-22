# Wireshark 远程抓包 

Wireshark 支持使用远程接口抓包，想要使用这个能力需要使用 `libpcap` 提供远程抓包服务。

## 自行编译运行 libpcap

`libpcap` 源码可以从  [tcpdump 官网](https://www.tcpdump.org/index.html)  下载：

```bash
# 下载 libpcap
wget https://www.tcpdump.org/release/libpcap-1.10.4.tar.xz

# 安装依赖程序
apt install gcc flex bison make 

# 配置 libpcap, 启用远程抓包能力
./configure --enable-remote

# 编译程序
make

# 运行 rpcapd, 监听 ipv4 地址, 无密码认证
./rpcapd/rpcapd -4 -n     
```

# Wireshark 添加远程接口

![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-141548.png)

![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-141558.png)

![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-141610.png)

![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-141623.png)
输入远程主机地址，即可拿到所有网卡：

![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-141635.png)
