# defer 与 panic



```go
package main

import (
	"fmt"
)

func main() {
	defer_call()
}

func defer_call() {
	defer fmt.Println("defer 1")
	defer fmt.Println("defer 2")

	fmt.Println("hello world")
	panic("panic")
}

// hello world
// defer 2
// defer 1
// panic: panic
//
// goroutine 1 [running]:
// main.defer_call()
```

`defer` 会在 return 之前按照先入后出的顺序执行，但是当遇到 `panic` 时，会等所有 `defer` 执行完毕再执行 `panic` 。

结合 `recover` 就很清晰了，这种顺序差异主要是执行寻找带有 `recover` 的 `defer`：

```go
package main

import (
	"fmt"
)

func main() {
	defer_call()
}

func defer_call() {
	defer fmt.Println("defer 1")
	defer fmt.Println("defer 2")

	defer func() {
		r := recover()
		if r != nil {
			fmt.Println("recover:", r)
		}
	}()
	fmt.Println("hello world")
	panic("panic")
}

// hello world
// recover: panic
// defer 2
// defer 1
```

