# Go 数组初始化详解

```go
package main

import (
	"encoding/json"
	"fmt"
	"reflect"
)

func main() {
	var a []int
	b := []int{}

	fmt.Printf("%p \n", a)
	fmt.Printf("%p \n", b)

	dataA, _ := json.Marshal(a)
	fmt.Println(string(dataA))
	dataB, _ := json.Marshal(b)
	fmt.Println(string(dataB))

	fmt.Println(reflect.ValueOf(a).IsNil()) // true
	fmt.Println(reflect.ValueOf(b).IsNil()) // false
}
```


a 和 b 变量的两种声明方式不同，a 变量声明了一个 []int 类型的空指针，而 b 是声明了一个实际变量。
    
在 JSON 反序列化的过程中，由于 a 是空指针，会被序列化为 `null`，而 b 会被序列化为 `[]` 。
    
在实际生产环境中更推介 a 变量的声明方式，因为 a 变量在使用时才会初始化分配内存，而 b 变量在声明时就会分配内存。