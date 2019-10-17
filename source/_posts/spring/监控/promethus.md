---
title: promethus
date: 2019-05-30 23:22:58
tags: 
  - promethus
categories: [spring,监控]
---


Prometheus 是一个开源系统监控和警报工具包。跟springboot 有很好的兼容性。

## 架构

![](/images/promethus/fb150642.png)

## 最佳实践

### 基本类型: Count

**只增不减的计数器**

常用的监控指标: 统计 请求总数、 jvm gc次数等。

结合 rate() 函数，可以获取监控指标过去一段时间的增长率

> rate(http_requests_total[5m])

结合 topk() 函数，可以获取topk的指标

> topk(10, http_requests_total)

### 基本类型: Gauge

**可增可减的变量，反映当前的状态**

常见指标: 当前活跃线程数、当前主机空闲内存等

直接通过指标名，即可获取指标的当前状态。

### 高级类型: 直方图和摘要

Histograms和Summaries 用来获取 监控指标 从初始化(重启)到某个时间点的采样点分布，监控指标一般要求服从正态分布。

Histograms或summaries 会同时维护观察对象(如 request )的两个指标:

- `*_count`指标: 表示观察对象的请求次数，如 request的次数
- `*_sum`指标: 表示 观察对象的值的总和，如 request的总耗时

通过这两个变量，我们可以计算出观察对象 一定时间的平均值。如:

```text
前五分钟，一个请求的平均耗时
-----------------------------
rate(http_request_duration_seconds_sum[5m])
/
rate(http_request_duration_seconds_count[5m])
```

## 常用函数

### increase

获取 区间向量中的第一个样本与最后一个样本之间的增长量。**increase 只能用于 Counter 类型的指标。**

计算方式为:

> (v5-v1) / (t5-t1) * 5

例子: 过去5分钟新增的请求数

```
increase(http_requests_total{job="api-server"}[5m])
```

### rate

区间向量的平均增长率。**rate 只能用于 Counter 类型的指标**
计算方式为:

> (v5-v1) / (t5-t1)

```text
rate(http_requests_total{job="api-server"}[2m])
等同于
increase(http_requests_total{job="api-server"}[2m]) / 120
```

### irate

基于 区间的`最后两个连续`的数据点，计算区间的平均增长率(秒)。**irate 只能用于 Counter 类型的指标**

```text
基于过去5分钟的最后两个数据点，计算每秒HTTP请求率

irate(http_requests_total{job="api-server"}[5m])
```

### histogram_quantile

用于获取某一数值，小于该数值的观察对象占 指定百分位

```text
过去10分钟内，请求响应时间的 90th 百分位数(暂且称为A)。即 90% 的请求响应时间小于 A

histogram_quantile(0.9, rate(http_request_duration_seconds_bucket[10m]))
```


## 参考资料

[直方图和摘要](https://prometheus.io/docs/practices/histograms/)

[Prometheus查询函数](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate)

[prometheus中文]( https://yunlzheng.gitbook.io/prometheus-book/)




