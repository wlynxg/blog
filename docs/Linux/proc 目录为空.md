当我们使用**ls**命令查看 **/proc** 目录时，会发现该目录的大小为0，这是为什么呢？
原来 **/proc** 目录本身是一个虚拟文件系统（virtual filesystem）。该目录下的所有数据都是存在与内存之中，例如系统内核、进程、外部设备状态及网络状态等。因为这个文件的目录在内存中，因此本身不占用任何硬盘空间。