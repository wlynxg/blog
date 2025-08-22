在 Linux 中有一些特殊字符，它们在命令中有着特殊的用法。掌握了这些字符能让你在 Linux 学习中更加如鱼得水。

# 一、 ~
波浪号 **~** 指的是主目录，即是用户的个人目录，无论你身在何方，只要输入 `cd ~` 就能立即回到主目录
```bash
[GNU@ec Pictures]$ cd ~
[GNU@ec ~]
```
# 二、.
英文句号 **.** 代表当前目录，使用 **.** 可以缩短我们的文件路径。
使用 **ls** 命令查看当前目录下所有文件，第一个就是 **.** 文件：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184256.png)


# 三、..
两个英文句号 **.** 代表上级目录，即父目录，使用 **..** 可以缩短我们的文件路径。
使用 **ls** 命令查看当前目录下所有文件，第二个就是 **..** 文件：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184309.png)

# 四、/
斜杠 **/** 既指的是路径目录分隔符，也指的是根目录。
在输入文件路径时使用 **/** 分隔不同目录，使用 `cd /` 命令时可以直接回到根目录。
# 五、#
以 **#** 开头的话是注释
```bash
# GNU's Not Unix!
```
注释虽然会被解释器忽略，但是它还是会添加到用户的命令历史记录中。
# 六、?
问号 **?**，是单字符通配符，它在Bash Shell中可以匹配任意一个字符：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184331.png)

如果想要匹配多个字符，就可以输入多个 **?** ：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184349.png)

# 七、*
星号 **\*** 代表的是任意字符序列，匹配任意字符，包括空字符：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184408.png)

# 八、[]
方括号 **[]** 指的是字符集通配符，匹配至少有一个和字符集字符匹配的字符：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184418.png)

# 九、;
分号 **;** 主要是用来分隔命令的，使用了 **;** 之后就可以在一行书写多条命令：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184428.png)

# 十、<
在 Linux 中的很多命令允许接受一个文件作为参数，并从该文件中获取数据。这些命令中的大多数还可以从流中获取输入。要创建一个流，可以使用左尖括号 "<" ，如下将文件重定向到命令中：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184441.png)

# 十一、>
输入和输出是相反的。右尖括号 **>** 将命令的输出进行重定向，一般是将输出结果重定向到文件中：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184456.png)

# 十二、!
感叹号 **!** 在Linux中可以代表着可以执行逻辑非运算，即将命令的返回值进行非运算。
感叹号 **!** 还可以从历史命令中取出一条命令来执行
```bash
[GNU@ec ~]$!1 # 执行第一条命令
[GNU@ec ~]$!?soft # 执行最近一次包含soft的命令
[GNU@ec ~]$!! # 执行上一条命令
```

# 十三、&
连接符 **&** 可以将程序放到后台执行。在执行命令后加上 **&** 即可将程序放到后台进行执行。若想要恢复至前台执行，使用 `fg [工作号]` 命令即可：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184507.png)

两个连接符 **&&** 代表的是做 **且** 运算，只有前面的命令执行成功时才能执行后面的命令：
```bash
[GNU@ec ~]$ [! -d hello] && mkdir hello # 如果当前目录下没有hello目录就创建一个hello目录
```
# 十四、|【连接命令】
**|** 的左右看成将命令链接在一起的管道，它将前一个命令的输出作为后一个命令的输入进行传递：
![image.png](https://raw.githubusercontent.com/wlynxg/pic/main/2025/06/01/20250601-184515.png)

**||** 代表着做或运算，前面的命令执行失败时执行后面的命令
```bash
[GNU@ec ~]$ cat hello && touch hello # 查看hello文件，没有的话创建一个
```
# 十五、$
在Linux中以 **$** 开头通常表示变量，例如一些系统变量
```bash
[GNU@ec ~]$ echo $PATH
/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/GNU/.local/bin:/home/GNU/bin
[GNU@ec ~]$ echo $USER
GNU
```
# 十六、`
反引号 **\`** 可以用来替换命令。
命令替换是指Shell可以先执行中的命令，将输出结果暂时保存，在适当的地方输出。**语法：\`command`**
```bash
[GNU@ecs ~]$ dAte=`date`
[GNU@ecs ~]$ echo "Date is $dAte"
Date is Fri Mar 13 20:31:58 CST 2020
```

# 十七、引用特殊字符

由于在 Linux 中这么多的特殊字符都有着自己的独特的作用，当我们想将这些特殊字符当作普通字符进行使用时就会有报错的风险。因此我们就需要想办法对这些特殊字符进行转义操作：
- 使用双引号 **" "** 括起来，不过这对 **$** 无效
```bash
[GNU@ec ~]$ echo "This is a &"
This is a 
[GNU@ec ~]$ echo "Today is $(date)"
Today is Tue Mar  3 21:14:06 CST 202
```

- 用单引号 **' '** 括起来，停止所有特殊字符的功
```bash
[GNU@ec ~]$ echo 'This is a |'
This is a |
```
- 反斜杠 **\\** 转义，在大多数场合通用
```bash
[GNU@ec ~]$ echo This is a \*
This is a *
```