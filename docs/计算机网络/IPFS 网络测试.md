# IPFS 网络测试

## 说明

本测试是为了测试 IPFS DHT 网络在国内使用时的网络情况。

由于测试环境限制，本测试中手机端网络所处地理位置均在成都。

## 测试流程

设备端：

1. 通过 libp2p 提供的默认 IPFS DHT bootstrap 节点连接到 IPFS 网络；
2. 在网络中通过 DHT 的查询临近节点的功能搜索网络中节点，并从中筛选出可用作 Relay 的节点，与其建立连接；
3. 将自身节点信息广播到 IPFS DHT 网络。

手机端：

1. 设备端通过 libp2p 提供的默认 IPFS DHT bootstrap 节点连接到 IPFS 网络；
2. 通过 IPFS DHT 网络查询设备端节点信息；
3. 尝试与设备端建立连接；
4. 尝试利用 Relay 进行打洞；

## 测试结果

**设备端:**

| **网络环境 \ 操作** | **连接到** **bootstrap** **节点耗时** | 中继节点筛选耗时 | **中继****延迟** |
| :------------------ | :------------------------------------ | :--------------- | :--------------- |
| **移动宽带**        | 1s                                    | 10s              | 150ms~300ms      |
| **电信宽带**        | 1s                                    | 8s               | 150ms~300ms      |
| **阿里云**          | 1s                                    | 11s              | 150ms~300ms      |

**手机端:**

| **运营商 \ 操作** | **连接到** **bootstrap** **节点耗时** | **查询到服务端节点信息耗时** | **连接到对端节点耗时** |
| :---------------- | :------------------------------------ | :--------------------------- | :--------------------- |
| **联通**          | 1s                                    | 31s                          | 3s                     |
| **电信**          | 1s                                    | 29s                          | 2s                     |
| **移动**          | 1s                                    | 30s                          | 3s                     |

## 分析

### DHT 节点和 Relay 节点来源？

查看日志发现，连接的 DHT 节点和找到的中继节点大部分（实测 90% 以上）都是国外的 IP 地址。

下图是随机选择的几个节点地址进行地理位置查询：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-144333.png)
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-145149.png)
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-145200.png)
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-145208.png)


### 中继节点筛选和查询到服务端节点信息耗时为什么较长？

主要有两个原因造成：

1. 当 libp2p 连接到 IPFS 网络时，DHT 模块在启动后，会先执行查询临近节点 DHT 节点池的操作。默认 DHT 节点池子大小为 200 （每个桶 20 个节点，10个桶）个节点，该过程会消耗较长时间；
2. 当执行查询操作时，会向临近节点发送查询请求。但是由于整个 DHT 网络较为庞大，很难通过一次查询就正好查找到包含设备端节点信息的节点。因此需要多次查询才能查询到对端信息。

由于设备端只需要执行操作 1，而手机端需要执行操作 1 和 2。因此设备端耗时相比于手机端会短一些。

### 中继节点查询为什么这么快？

在默认情况下，libp2p 会根据自身检测到的网络可见性情况而选择是否提供中继服务和 DHT 查询服务。

默认情况下，当 libp2p 发现节点处于公网可见状态时，会同时开启 DHT 查询服务和 Relay 服务。因此查询到的大部分 DHT 节点（实测在 80% 以上）都可以作为中继服务。

不过在默认情况下，libp2p 启动 Relay 服务时，会存在资源限制。因此 Relay 节点只能用于传输少量数据。