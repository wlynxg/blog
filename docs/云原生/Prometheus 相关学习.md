# Prometheus 相关学习

```
sum by(resource_name) (rate(otelcol_receiver_accepted_spans_bytes[$__rate_interval]))
```