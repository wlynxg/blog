# 环境配置
	该部分配置所有节点都需要执行！

## 关闭防火墙

```shell
root@k8s:~# ufw status
Status: inactive

# 关闭防火墙
ufw disable 
```

## 关闭 swap

由于 `swap` 在涉及交换内存时，保证和核算 Pod 内存利用率存在固有的困难。因此 k8s 需要禁用 Linux 的 swap 功能（1.22 以后 k8s 在逐步支持，不过当前还不够完善）。

```bash
# 临时关闭
swapoff -a

# 永久关闭
vim /etc/fstab （注释fstab中swap配置）
# 或者直接使用 sed
sed -ri 's/.*swap.*/#&/' /etc/fstab
```

## 关闭 SELinux

```bash
# 查看是否开启 SELinux
# 某些ubuntu版本，没有安装selinux，则可以不用配置
getenforce

# 临时关闭 SELinux
setenforce 0 
# 永久关闭 SELinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
```

## 开启内核流量转发并让 iptables 看到桥接流量

```bash
# 载入内核模块
tee /etc/modules-load.d/k8s.conf <<EOF 
overlay 
br_netfilter 
EOF

modprobe overlay 
modprobe br_netfilter
```

```bash
# 开启 bridge 流量过滤和内核流量转发功能
tee /etc/sysctl.d/k8s.conf << EOF 
net.bridge.bridge-nf-call-ip6tables = 1 
net.bridge.bridge-nf-call-iptables = 1 
net.ipv4.ip_forward = 1 
net.ipv6.conf.all.forwarding = 1
EOF
```

```bash
# 应用配置而不重新启动
sysctl --system
```

```bash
# 查看相关内核模块是否载入
lsmod | grep br_netfilter
lsmod | grep overlay

# 查看内核参数是否修改
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward net.ipv6.conf.all.forwarding
```

## 安装容器运行时

k8s 官方推介 **[containerd](https://github.com/containerd/containerd)** 作为 k8s 的容器运行时。因此下面在集群中安装 `containerd`。
下面介绍使用 `apt-get` 的方式在环境中安装 `containerd`，其余平台和环境安装 `containerd` 可见: https://github.com/containerd/containerd/blob/main/docs/getting-started.md

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install containerd.io
sudo apt-get install containerd.io
```

```bash
# 查看 containerd 状态
systemctl status containerd
```

配置 `containerd`:

```bash
# 生成默认配置
containerd config default > /etc/containerd/config.toml

# 如果提示：/etc/containerd/config.toml: No such file or directory
# 则需要手动创建文件夹再执行上面的命令
mkdir /etc/containerd/

# k8s 官方推荐使用 systemd 作为 CgroupDriver
# 修改 CgroupDriver 为 systemd
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# 查看是否修改成功
root@k8s:~# cat /etc/containerd/config.toml | grep SystemdCgroup
            SystemdCgroup = true

# 由于网络原因，国内很难拉取 registry.k8s.io/pause:3.8 镜像
# 这个镜像是一切的pod的基础，要么自己手动导入进来，要么改成国内的镜像
# 下面将 containerd 的镜像仓库更换为阿里云的源
sed -i 's/sandbox_image = ".*"/sandbox_image = "registry.aliyuncs.com\/google_containers\/pause:3.10"/' /etc/containerd/config.toml

# 查看是否修改成功
root@k8s:~# cat /etc/containerd/config.toml | grep sandbox_image
    sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.10"

# 重启 containerd
systemctl restart containerd

# 查看 containerd 状态
systemctl status containerd
```

# 安装 kubeadm、kubelet 和 kubectl
## 添加 k8s 软件源
	 此部分所有节点都需要执行！

详细可见：https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
```shell
sudo apt-get update
# apt-transport-https 可能是一个虚拟包（dummy package）；如果是的话，你可以跳过安装这个包
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

```shell
# 对于国内机器，推介更换阿里源
curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.33/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list


# 如果是网络环境能够访问外网，则可以使用官方方式
# 下载签名秘钥及添加apt仓库
# 如果 `/etc/apt/keyrings` 目录不存在，则应在 curl 命令之前创建它，请阅读下面的注释。
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 此操作会覆盖 /etc/apt/sources.list.d/kubernetes.list 中现存的所有配置。
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

## 安装配置 k8s
### master 节点

更新 apt 包索引，安装 `kubelet`、`kubeadm` 和 `kubectl`，并锁定其版本：
```shell
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

用 kubeadm 初始化集群：
```bash
# 初始化集群控制台 Control plane
# 失败了可以用 kubeadm reset 重置
# 对于国内机器建议更换镜像源为阿里源
# 注意⚠️：此处指定 pod-network-cidr 为 10.244.0.0/16
# 这是为了与后面的 flannel 匹配，如无特殊需求直接使用这个即可
# apiserver-advertise-address 用于指定 k8s apiserver 监听地址，默认会使用默认网卡的 IP
# 由于我这里是多网卡，需要更换为实际网卡地址
kubeadm init --image-repository=registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="192.168.5.51"

# 记得把 kubeadm join xxx 保存起来 你需要此命令将节点加入集群。
# 忘记了重新获取：kubeadm token create --print-join-command

#要使非 root 用户可以运行 kubectl，请运行以下命令， 它们也是 kubeadm init 输出的一部分：
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

状态检查：
```bash
# 检查集群状态
root@k8s:~# kubectl get --raw='/readyz?verbose'
[+]ping ok
[+]log ok
[+]etcd ok
[+]etcd-readiness ok
[+]informer-sync ok
[+]poststarthook/start-apiserver-admission-initializer ok
[+]poststarthook/generic-apiserver-start-informers ok
[+]poststarthook/priority-and-fairness-config-consumer ok
[+]poststarthook/priority-and-fairness-filter ok
[+]poststarthook/storage-object-count-tracker-hook ok
[+]poststarthook/start-apiextensions-informers ok
[+]poststarthook/start-apiextensions-controllers ok
[+]poststarthook/crd-informer-synced ok
[+]poststarthook/start-system-namespaces-controller ok
[+]poststarthook/start-cluster-authentication-info-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
[+]poststarthook/start-legacy-token-tracking-controller ok
[+]poststarthook/start-service-ip-repair-controllers ok
[+]poststarthook/rbac/bootstrap-roles ok
[+]poststarthook/scheduling/bootstrap-system-priority-classes ok
[+]poststarthook/priority-and-fairness-config-producer ok
[+]poststarthook/bootstrap-controller ok
[+]poststarthook/start-kubernetes-service-cidr-controller ok
[+]poststarthook/aggregator-reload-proxy-client-cert ok
[+]poststarthook/start-kube-aggregator-informers ok
[+]poststarthook/apiservice-status-local-available-controller ok
[+]poststarthook/apiservice-status-remote-available-controller ok
[+]poststarthook/apiservice-registration-controller ok
[+]poststarthook/apiservice-discovery-controller ok
[+]poststarthook/kube-apiserver-autoregistration ok
[+]autoregister-completion ok
[+]poststarthook/apiservice-openapi-controller ok
[+]poststarthook/apiservice-openapiv3-controller ok
[+]shutdown ok
readyz check passed

# 查看 namespace
root@k8s:~# kubectl get ns
NAME              STATUS   AGE
default           Active   5m3s
kube-node-lease   Active   5m3s
kube-public       Active   5m3s
kube-system       Active   5m4s

# 查看 kube-system 空间 pod 状态
root@k8s:~# kubectl get pods -n kube-system 
NAME                          READY   STATUS    RESTARTS   AGE
coredns-757cc6c8f8-cpv64      0/1     Pending   0          4m56s
coredns-757cc6c8f8-h697j      0/1     Pending   0          4m56s
etcd-k8s                      1/1     Running   0          5m1s
kube-apiserver-k8s            1/1     Running   0          5m7s
kube-controller-manager-k8s   1/1     Running   0          5m1s
kube-proxy-hdf6r              1/1     Running   0          4m56s
kube-scheduler-k8s            1/1     Running   0          5m7s

# 查看节点状态
root@k8s:~# kubectl get nodes
NAME   STATUS     ROLES           AGE   VERSION
k8s    NotReady   control-plane   14m   v1.33.1
```

在 `master node`上执行 `kubectl get nodes` 发现状态是 `NotReady`，这是因为还没有部署 CNI 网络插件。在 k8s 系统上 Pod 网络的实现依赖于第三方插件进行，这类插件有近数十种之多，较为著名的有 flannel、calico 和 Cilium 等。

其中 flannel 相对来说较为简单，对于初学者来说可以应用 flannel 来部署 CNI 网络插件。

`flannel` 部署：

	注意⚠️：kube-flannel.yml 的 Network，要和 pod-network-cidr 保持一致
	如果在初始化时使用的是 --pod-network-cidr=10.244.0.0/16 则不用进行修改了，否则需要自行修改 kube-flannel.yaml

查看 k8s `pod-network-cidr`:
```bash
root@k8s:~# kubectl get node -o jsonpath='{.items[0].spec.podCIDR}'
10.244.0.0/24
```

`kube-flannel.yml`:
```yaml
  net-conf.json: |
    {
      "Network": "10.244.0.0/16", <- 修改此处
      "EnableNFTables": false,
      "Backend": {
        "Type": "vxlan"
      }
    }
```


```

 配置对应后即可部署 `flannel`：
```bash
# 部署 flannel 
root@k8s:~# kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
namespace/kube-flannel created
serviceaccount/flannel created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created

# 查看 flannel 节点状态
root@k8s:~# kubectl get pods -n kube-flannel
NAME                    READY   STATUS    RESTARTS   AGE
kube-flannel-ds-v92h4   1/1     Running   0          22s
```
### slave 节点
	注意⚠️：此部分需要在所有 slave 节点执行！

```bash
# slave 节点不需要安装 kubectl，只需要安装 kubelet 和 kubeadm 即可
sudo apt-get install -y kubelet kubeadm
sudo apt-mark hold kubelet kubeadm

# 执行 master 节点在 init 时输出的 kubeadm join xxx 命令
# 如果忘记命令，可在 master 节点输出 kubeadm token create --print-join-command 命令查看
# 如果 kubeadm 输出的命令的 IP 和实际联通 IP 符的，可自行修改
kubeadm join xxxx...
```

# 最后
回到 `master` 节点，查看集群状态：
```bash
# 查看节点状态
root@k8s:~# kubectl get nodes
NAME    STATUS   ROLES           AGE   VERSION
k8s     Ready    control-plane   96m   v1.33.1
node1   Ready    <none>          95m   v1.33.1
node2   Ready    <none>          94m   v1.33.1
```

所以节点都处于 `Ready` 状态，说明 k8s 集群已经安装配置好了。