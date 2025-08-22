# iOS bind

Swift/ObjC和go的交互是通过cgo。

## 系统线程

Swift/ObjC有线程概念。从c调用go时，线程阻塞等待go返回；go执行完成后，线程继续执行c代码。

go没有线程概念。go调用c时，goroutine阻塞；如果c不能及时返回，即处理此Goroutine的系统线程被阻塞，go运行时将启动额外线程，维持GOMAXPROCS数量的可用系统线程处理其他goroutines。

在线程数量可控的情况下，使用同步方式阻塞线程并无大碍。但在阻塞线程不可控的情况下，会引发效率问题。

## 异步编程

各语言都提供了各自的异步编程方案，Swift的async/await，GCD，goroutines。关键之处在于：函数不能阻塞线程。

gomobile没有提供通用模版，生成的ObjC代码也无法被Swift自动转为async函数。所以只能使用callback方式，自行封装。

### Swift 调用 Go

主功能`LongAddCore`由go实现，swift里通过task并发调用。

```Go
package mygo

func LongAddCore(a int, b int) int {
    time.Sleep(2 * time.Second)
    return a + b
}

type LongAddCallback interface {
    Done(int)
}

type LongAdd interface {
    Run(a int, b int, cb LongAddCallback)
}

type longAdd struct {
}

func (l *longAdd) Run(a int, b int, cb LongAddCallback) {
    go func() {
       cb.Done(LongAddCore(a, b))
    }()
}

var LongAddInst LongAdd = &longAdd{}
```

```Swift
class LongAddCallbackImpl: NSObject, MygoLongAddCallbackProtocol {
    let continuation: CheckedContinuation<Int, Never>

    init(continuation: CheckedContinuation<Int, Never>) {
        self.continuation = continuation
    }

    func done(_ result: Int) {
        continuation.resume(returning: result)
    }
    
    static func doLongAdd(a:Int, b:Int) async -> Int {
        await withCheckedContinuation { continuation in
            Mygo.longAddInst()?.run(a, b: b, cb: LongAddCallbackImpl(continuation: continuation))
        }
    }
}

// 以下是演示代码
// .task {
    await withTaskGroup(of: Void.self) { group in
        for i in 1...1000 {
            group.addTask {
                let r = await LongAddCallbackImpl.doLongAdd(a: i, b: i)
                assert(r == i + i, "Incorrect result")
            }
        }
        await group.waitForAll()
        print("LongAdd - Done")
    }
```

忽略掉中间的桥接代码，最终的结果是：

- go定义了`func LongAddCore(a int, b int) int`
- 通过一大堆桥接代码
- 在swift里使用`func doLongAdd(a:Int, b:Int) async -> Int`

### Go 调用 Swift

主功能`LongSubCore`由Swift实现，go里通过goroutines并发调用。

```Go
package mygo

type LongSubCallback interface {
    Done(int)
}

type LongSub interface {
    Run(a int, b int, cb LongSubCallback)
}

type longSubCallbackImpl struct {
    c chan int
}

func (l *longSubCallbackImpl) Done(i int) {
    l.c <- i
}

var LongSubInst LongSub

func doLongSub(a int, b int) int {
    c := make(chan int)
    go LongSubInst.Run(a, b, &longSubCallbackImpl{c})
    return <-c
}

// 以下是演示代码，由Swift调用
func StartLongSub() {
    go func() {
       var wg sync.WaitGroup
       for i := 0; i < 1000; i++ {
          wg.Add(1)
          go func() {
             defer wg.Done()
             r := doLongSub(i, -i)
             if r != i+i {
                log.Println("Incorrect result")
             }
          }()
       }
       wg.Wait()
       log.Println("LongSub - Done")
    }()
}
```

```Swift
func LongSubCore(a: Int, b: Int) async -> Int {
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    return a-b
}

class LongSubInst: NSObject, MygoLongSubProtocol {
    func run(_ a: Int, b: Int, cb: (any MygoLongSubCallbackProtocol)?) {
        Task {
            let r = await LongSubCore(a: a, b: b)
            cb?.done(r)
        }
    }
}

// 设置LongSub的实现后，调用演示代码
// .task {
     Mygo.setLongSubInst(LongSubInst())
     MygoStartLongSub()
```

忽略掉中间的桥接代码，最终的结果是：
- swift定义了`func LongSubCore(a: Int, b: Int) async -> Int`
- 通过一大堆桥接代码
- go里使用`func doLongSub(a int, b int) int`

### 总结

- 封装成签名几乎一致的异步接口，桥接层代码繁多，不适合手写。
- 直接使用callback也可以完成，但在调用方无法使用自己语言特有的同步写法。
- 也可以把go封装成ObjC的Delegate模式，由go触发事件回调。
- 使用阻塞线程的方式，代码简单。
	- 从Swift调用Go，有线程概念，线程数量固定。
    - 从Go调用Swift，Swift一旦卡住Go会新启线程，导致线程数量不可控。    

因此，需要按实际的用法来决定如何封装和桥接。推荐把Go封装成ObjC接口给Swift用，设计模式可照ObjC来做。

## 避免内存复制

由于跨语言，不复制内存的方式传递数据，只能用传统的方式传递内存地址。使用时一定注意内存地址的有效性，建议仅在同步调用时使用。

### Swift提供内存空间，Go使用

```Swift
    var d = Data(count: 128)
    d.withUnsafeMutableBytes { p in
        while true {
            let n = l2conn!.read(Int64(UInt(bitPattern:p.baseAddress)), n: p.count)
            //...
```

```Go
func (c *l2conn) Read(p int64, n int) int {
    ptr := unsafe.Pointer(uintptr(p))
    bytes := (*[1 << 30]byte)(ptr)[:n:n]
    n, e := c.netConn.Read(bytes)
    // ...
```

## 大写开头的变量名

gomobile生成Obj-C代码时，对于大写字母开头的字段，产生的Obj-C属性名称与其Setter名称不一致。

比如原始字段：`IPAddr`
生成的Obj-C属性：`ipAddr`
Obj-C预期的Setter：`setIpAddr`
gomobile生成的Setter：`setIPAddr`

此问题于2020年已有Patch https://github.com/golang/mobile/pull/50，但gomobile社区非常不活跃，没有合并此Patch。

### 应对方案

如果修改并自行维护gomobile，一但开发人员误用原版gomobile，将会引发难以发现的问题。为了避免潜在的风险，我们迁就gomobile，字段定义时**不使用连续的大写字母开头**。

- 如果误用了连续大写字母开头，相应功能失效，一般在开发时就能发现。
- 基本不破坏可读性。
