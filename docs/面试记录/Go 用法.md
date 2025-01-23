## 1. 请求合并

singleflight 原始在 Go internal/singleflight，后演变为 golang.org/x/sync/singleflight

核心结构：call Group

原理：sync.Lock 、map、sync.WaitGroup{}

同一 key 构造 call 对象，存入 map，利用 sync.WaitGroup 进行 Wait

