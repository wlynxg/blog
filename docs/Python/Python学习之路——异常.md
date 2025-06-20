# Python 学习之路——异常

# 一、简介

### 什么是异常？
在我们编写Python程序的过程中，常常会因为各种原因导致我们的程序出现错误，这就是程序出现异常。
由于在Python程序中，程序一旦出现异常，那么整个程序会立即终止，异常后面的代码都不会执行（异常前面的代码会执行，在这里也体现出Python是编译性语言的特征）。
### 什么是处理异常？
为了不让我们的程序一旦出现出现异常就卡死，我们就需要对程序中可能出现异常的部分进行处理。
当在函数中出现异常时，如果在函数中对异常进行了处理，则异常不会再传播，如果函数中没有对异常进行处理，则异常会继续向函数调用处传播。
如果函数在调用处处理了异常，则不再传播；
如果没有处理则继续像调用处传播，直到传递到全局作用域，如果依然没有处理，则程序终止，并且显示异常信息。

# 二、异常的分类
当程序运行过程中出现异常以后，所有的异常信息会被专门保存到一个异常对象当中
而异常传播时，实际上就是异常对象抛给了调用处。
**常见异常**：

| 异常名            | 出现原因                    |
| ----------------- | --------------------------- |
| BaseException     | 所有异常的基类              |
| Exception         | 常规异常的基类              |
| AttributeError    | 对象不存在此属性            |
| IndexError        | 输入/输出操作失败           |
| KeyboardInterrupt | 用户中断执行                |
| KeyError          | 映射中不存在此键            |
| NameError         | 找不到名字（变量）          |
| SyntaxError       | Python语法错误              |
| TypeError         | 对类型无效的操作            |
| ValueError        | 传入无效的参数              |
| ZeroDivisionError | 除或取模运算的第二个参数为0 |
| ConnectionError   | 与连接相关异常的基类        |

# 三、异常的处理
在Python中我们可以利用try-except语句来对异常进行处理。
**异常处理语法**：
```python
try:
	代码块(可能会出现错误的语句)
except 异常类型 as异常名：
	代码块(出现错误以后的处理方式)
except 异常类型 as异常名：
	代码块(出现错误以后的处理方式)
.....
else:
	代码块(没有错误时要执行的语句)
finally:
	代码块(是否有异常都会执行)
```
在try-eccept语句中，如果except后面不跟任何内容，则此时会捕获到所有的异常；如果except后面跟着一个异常类型，那么此时它只会捕获该类型的异常。
```python
try:
    print(1/0)
except ZeroDivisionError:
    print('出现错误！')
```
当直接运行"1/0"时，程序会抛出ZeroDivisionError异常。我们利用try-except语句接收异常，然后执行print('出现错误！')语句，然后就不会抛出异常了，后面的程序也不会中断了。
# 四、自定义异常对象
在实际开发过程中，我们可以自己自定义异常对象，在程序不能按照我们的要求执行时就抛出自定义异常。
**自定义异常语法**：
```python
raise [Exception [, args [, traceback]]]
```
语句中Exception是异常的类型（例如，NameError）。该参数是可选的，如果不提供，异常的参数是"None"。
```python
class MyError(Exception):
    pass

def add(a,b):
    if a < 0 or b < 0 :
        raise MyError('输入值不应为负！')
    r = a + b
    return r

print(add(-1,2))
```
MyError是我们定义的异常，当程序不符合我们的要求时就抛出MyError异常。