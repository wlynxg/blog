# 使用 netplan 创建 bridge

```yaml
# 根据实际情况编辑 netplan 文件，系统默认会创建一个
# /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  ethernets:
    enp2s0:
      addresses:
      - "192.168.5.11/24"
      nameservers:
        addresses:
        - 192.168.5.1
        search: []
      routes:
      - to: "default"
        via: "192.168.5.80"
  bridges:
    br0:
      dhcp4: false
      addresses: [192.168.5.40/24]
      interfaces:
        - enp2s0
      gateway4: 192.168.5.80
      nameservers:
        addresses: [192.168.5.1,223.5.5.5,1.1.1.1 ]
      parameters:
        forward-delay: 0
        stp: false
      optional: true
```

应用 `netplan` 配置：
```bash
# 配置验证
netplan try

# 应用配置
netplan apply

# 查看创建的 br0 网卡
root@k8s:~# ip a
...
5: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 06:59:59:0e:14:4c brd ff:ff:ff:ff:ff:ff
    inet 192.168.5.40/24 brd 192.168.5.255 scope global br0
       valid_lft forever preferred_lft forever
    inet6 fe80::459:59ff:fe0e:144c/64 scope link 
       valid_lft forever preferred_lft forever
```

# 安装和配置 lxd
```bash
# snap 安装 lxd
snap install lxd

# lxd 初始化配置
root@k8s:~# lxd init
Would you like to use LXD clustering? (yes/no) [default=no]: 
Do you want to configure a new storage pool? (yes/no) [default=yes]: 
Name of the new storage pool [default=default]: 
Name of the storage backend to use (dir, lvm, powerflex, zfs, btrfs, ceph) [default=zfs]: 
Create a new ZFS pool? (yes/no) [default=yes]: 
Would you like to use an existing empty block device (e.g. a disk or partition)? (yes/no) [default=no]: 
Size in GiB of the new loop device (1GiB minimum) [default=19GiB]: 100GiB # 根据实际情况选择大容量，后续 multipass 创建的虚拟机会放在这里
Would you like to connect to a MAAS server? (yes/no) [default=no]: 
Would you like to create a new local network bridge? (yes/no) [default=yes]: no # 我们已经手动创建了 br0，因此不需要 lxd 再创建 bridge 网卡
Would you like to configure LXD to use an existing bridge or host interface? (yes/no) [default=no]: 
Would you like the LXD server to be available over the network? (yes/no) [default=no]: 
Would you like stale cached images to be updated automatically? (yes/no) [default=yes]: 
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]: 
```

# 安装和配置 multipass
```bash
# 安装 multipass
snap install multipass

# !!! 注意⚠️
# 当将多通道后端切换到 lxd 后，在现有后端（qemu）上运行的实例将被隐藏！
# 建议先停止当前所有实例
multipass stop --all

# 将 multipass 后端由 qemu 变更为 lxd
multipass set local.driver=lxd

# 检查后端驱动是否发生变更
root@k8s:~# multipass get local.driver
lxd

# 将 lxd 连接到 multipass
snap connect multipass:lxd lxd

# 确认已经连接到 lxd
root@k8s:~# snap connections multipass | grep lxd
lxd                     multipass:lxd                lxd:lxd                         -

# 检查 br0 是否被 multipass 识别
root@k8s:~# multipass networks
Name     Type       Description
br0      bridge     Network bridge with enp2s0
enp2s0   ethernet   Ethernet device
mpbr0    bridge     Network bridge for Multipass
```

# 使用 multipass 创建桥接模式虚拟机

```bash
# 创建虚拟机
multipass launch node --network br0

# 查看虚拟机
root@k8s:~# multipass list
Name                    State             IPv4             Image
node                   Running            10.110.224.184   Ubuntu 24.04 LTS
                                          192.168.5.49

# 查看宿主机网络可以看到虚拟机的两张网卡
root@k8s1:~# ip a
...
7: tap06d9eb7f: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq master mpbr0 state UP group default qlen 1000
    link/ether e6:af:7b:08:3a:f2 brd ff:ff:ff:ff:ff:ff
8: tap35adde70: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq master br0 state UP group default qlen 1000
    link/ether ea:77:45:5d:3d:af brd ff:ff:ff:ff:ff:ff


# 进入虚拟机 
multipass shell node
# 在虚拟机中查看网卡
ubuntu@node:~$ ip a
...
2: enp5s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 52:54:00:57:95:6e brd ff:ff:ff:ff:ff:ff
    inet 10.110.224.184/24 metric 100 brd 10.110.224.255 scope global dynamic enp5s0
       valid_lft 3386sec preferred_lft 3386sec
    inet6 fd42:ee96:be30:827a:5054:ff:fe57:956e/64 scope global mngtmpaddr noprefixroute 
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe57:956e/64 scope link 
       valid_lft forever preferred_lft forever
3: enp6s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 52:54:00:48:fb:1d brd ff:ff:ff:ff:ff:ff
    inet 192.168.5.49/24 metric 200 brd 192.168.5.255 scope global dynamic enp6s0
       valid_lft 86189sec preferred_lft 86189sec
    inet6 fe80::5054:ff:fe48:fb1d/64 scope link 
       valid_lft forever preferred_lft forever

# 网络连通性测试
ubuntu@node:~$ ping 192.168.5.1
PING 192.168.5.1 (192.168.5.1) 56(84) bytes of data.
64 bytes from 192.168.5.1: icmp_seq=1 ttl=64 time=0.763 ms
64 bytes from 192.168.5.1: icmp_seq=2 ttl=64 time=1.46 ms
64 bytes from 192.168.5.1: icmp_seq=3 ttl=64 time=0.860 ms
...

ubuntu@node2:~$ ping 223.5.5.5
PING 223.5.5.5 (223.5.5.5) 56(84) bytes of data.
64 bytes from 223.5.5.5: icmp_seq=1 ttl=115 time=7.11 ms
64 bytes from 223.5.5.5: icmp_seq=2 ttl=115 time=7.18 ms
...
```

至此，利用 multipas 创建桥接主机网络的虚拟机完成。