---

title: K8S域名问题

date: 2019-09-30 16:00:48

categories: [k8s]

tags: [k8s]

---

K8S域名问题

<!--more-->



## 访问规则

### pod

`{pod-ip}.{namespace}.pod.cluster.local`

### service

1. 正常服务，通过如下域名返回 **该服务的集群IP**

   `{service-name}.{namespace}.svc.cluster.local`

2. headLess 服务，通过如下域名返回 **Pod的一组IP**

   `{service-name}.{namespace}.svc.cluster.local`

### statefulSet

 ` {pod-name}.{service-name}.{namespace}.svc.cluster.local`



