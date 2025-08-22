# 监测 Windows 应用行为

> 当我们安装、运行 Windows程序时，程序可能会包含创建文件夹、修改注册表等一系列行为。但是大部分应用程序的这些行为对于使用者来说都是不可见的。

当我们需要监控一个应用程序干了哪些事情，就可以使用工具： `Wise Installation System`。该应用程序通过拍摄快照、对比快照的方式可以来展示程序的行为。

安装：

![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-172526.png)

选择`SetupCapture`：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-172539.png)

勾选设置：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-172550.png)


对当前主机内容拍摄快照：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-172605.png)

执行需要观测的程序：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-172618.png)

执行操作后再观测当前主机状态：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-172631.png)

完成后就可以在此处看到这个过程中主机更改的信息了：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-172643.png)
