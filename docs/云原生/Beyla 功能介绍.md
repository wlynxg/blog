    Grafana Beyla 是一款基于 eBPF（Extended Berkeley Packet Filter）技术的应用程序自动检测工具，为应用程序可观测性提供了强大支持。它能够在不修改应用程序代码或配置的前提下，自动检测应用程序，获取指标和追踪信息。

## 一、核心检测功能

1. 多语言应用程序自动检测：Beyla 具备强大的兼容性，可自动检测使用多种编程语言编写的应用程序。涵盖 Go、C/C++、Rust、Python、Ruby、Java（包括 GraalVM Native）、NodeJS、.NET 等。

2. 高效低开销数据捕获：对于解释型语言应用，Beyla 通过使用原生编译代码，实现高效检测和低开销的数据捕获。在保障数据获取准确性的同时，最大程度减少对应用程序性能的影响，确保应用正常稳定运行。

3. 自动检测应用执行与网络层：利用 eBPF 技术，Beyla 自动检查应用程序可执行文件和操作系统网络层。它能捕获与 Web 事务以及 Linux HTTP/S 和 gRPC 服务的RED（Request rate、Error、Duration）指标相关的追踪跨度，为分析应用性能和网络状况提供关键数据。

## 二、数据导出与格式支持

1. OpenTelemetry 格式导出：Beyla 支持以 OpenTelemetry 格式导出数据。OpenTelemetry 是云原生可观测性领域的标准，这种导出方式便于与其他遵循该标准的工具和平台集成，实现数据的统一处理与分析。

2. 原生 Prometheus 指标导出：除 OpenTelemetry 格式外，Beyla 还能以原生 Prometheus 指标形式导出数据。Prometheus 是广泛使用的监控系统，Beyla 的这一功能使得在 Prometheus 生态系统中使用其数据变得轻松，用户可利用 Prometheus 的强大功能进行监控和告警。

## 三、分布式追踪

Beyla 的分布式追踪基于传播 W3C 的`traceparent`标头值来实现。在请求处理过程中，Beyla 会自动读取任何传入的追踪上下文标头值，以此跟踪程序的执行流程。当进行传出的 HTTP/gRPC 请求时，Beyla 会自动添加`traceparent`字段来传播追踪上下文。如果应用程序已经在传出请求中添加了`traceparent`字段，Beyla 会直接使用该值进行追踪，而不再另行生成；若未找到传入的`traceparent`上下文值，Beyla 则会依据 W3C 规范生成一个新的值。

1. ### 网络级别上下文传播

网络级别的上下文传播通过将追踪上下文信息写入传出的 HTTP 标头以及 TCP/IP 数据包级别来实现。HTTP 上下文传播与任何其他基于 OpenTelemetry 的追踪库完全兼容。

对于 TLS 加密流量 (HTTPS)，Beyla 无法将追踪信息注入到传出的 HTTP 标头中，而是将信息注入到 TCP/IP 数据包级别。由于此限制，Beyla 只能将追踪信息发送到其他 Beyla instrumentation 的服务。L7 代理和负载均衡器会破坏 TCP/IP 上下文传播，因为原始数据包被丢弃并在下游重放。从 OpenTelemetry SDK instrumentation 的服务解析传入的追踪上下文信息仍然有效。

 **目前不支持 gRPC 和 HTTP2，并且上下文传播传入标头解析需要内核 5.17 或更高版本。**

2. ### 库级别上下文传播（仅适用于 Go 应用程序）

**这种类型的上下文传播仅支持 Go 应用程序**，并使用 eBPF 用户内存写入支持 (`bpf_probe_write_user`)。这种方法的优点是它适用于 HTTP/HTTP2/HTTPS 和 gRPC，但有一些限制，但是使用 `bpf_probe_write_user` 需要授予 Beyla `CAP_SYS_ADMIN` 权限，或者将其配置为以 `privileged` 容器运行。

## 四、运行环境与适配能力

1. Linux 环境广泛支持：Beyla 可在任何 Linux 环境中运行，但要求 Linux 内核版本为 5.8 或更高，并启用 BPF 类型格式（BTF）。多数内核版本 5.14 及更高的 Linux 发行版默认启用 BTF，可通过检查`/sys/kernel/btf/vmlinux`是否存在来确认。对于基于 RedHat 的发行版，如 RHEL8、CentOS 8、Rocky8、AlmaLinux8 等，虽内核为 4.18，但已向后移植 eBPF 相关补丁，也能支持 Beyla 运行。

2. Kubernetes 集成：Beyla 能够监听 Kubernetes API，利用 Pod 和 Services 元数据装饰指标和追踪。在 Kubernetes 容器编排环境中，这一功能可使检测数据与容器资源信息紧密结合，方便用户从容器集群层面分析应用性能和资源使用情况。

## 五、权限管理与局限性

1. 细粒度权限控制：尽管多数 eBPF 程序需要提升权限，但 Beyla 允许用户指定更细粒度的权限，如`CAP_DAC_READ_SEARCH`、`CAP_SYS_PTRACE`等，以最小权限运行，增强安全性。部分功能虽需额外权限（如`CAP_NET_ADMIN`用于网络可观测性探针与 Linux 流量控制，`CAP_SYS_ADMIN`用于 Go 中跨节点上下文传播），但这些功能可选启用，权限不足时 Beyla 会降级运行，保证基本功能可用。

2. 功能局限性：Beyla 提供的是通用指标和事务级追踪跨度信息，在检测代码特定部分的粒度和聚焦关键操作方面，不如语言代理和手动检测。因此，在对应用程序检测精度要求极高的场景下，可结合使用 Beyla 与其他检测手段。