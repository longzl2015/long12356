---

title: k8s常用命令

date: 2019-07-07 16:00:38

categories: [k8s]

tags: [k8s]

---





### proxy 代理

```bash
kubectl proxy 
```

上述命令会 在本地 启动一个代理服务，将请求转发给 k8s的api服务。默认监控 8001端口。

> Starting to serve on 127.0.0.1:8001

通过curl就能够访问集群的资源信息

> curl http://localhost:8001/api/v1/namespaces/sl/pods/eureka-0/

**详细资源访问路径:** https://blog.csdn.net/huwh_/article/details/77922209

注: 由于我使用的是 rancher安装的k8s，需要使用以下 路径

> curl http://localhost:8001/k8s/clusters/clusterid/api

### 查看服务的srv

```bash
kubectl run -it srvlookup --image=tutum/dnsutils --rm  --restart=Never -- dig SRV eureka.sl.svc.cluster.local
```

> ; <<>> DiG 9.9.5-3ubuntu0.2-Ubuntu <<>> SRV eureka.sl.svc.cluster.local
> ;; global options: +cmd
> ;; Got answer:
> ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 20482
> ;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 2
>
> ;; QUESTION SECTION:
> ;eureka.sl.svc.cluster.local.	IN	SRV
>
> ;; ANSWER SECTION:
> eureka.sl.svc.cluster.local. 30	IN	SRV	10 50 0 eureka-1.eureka.sl.svc.cluster.local.
> eureka.sl.svc.cluster.local. 30	IN	SRV	10 50 0 eureka-0.eureka.sl.svc.cluster.local.
>
> ;; ADDITIONAL SECTION:
> eureka-1.eureka.sl.svc.cluster.local. 30 IN A	10.42.0.94
> eureka-0.eureka.sl.svc.cluster.local. 30 IN A	10.42.1.14
>
> ;; Query time: 1 msec
> ;; SERVER: 10.43.0.10#53(10.43.0.10)
> ;; WHEN: Fri Jun 28 03:50:32 UTC 2019
> ;; MSG SIZE  rcvd: 189
>
> pod "srvlookup" deleted

### port-forward

将本机端口转发到容器的端口

```
kubetl port-forward 容器名 主机端口: 容器端口
```

### cp 命令

```
kubectl cp ingress-nginx/nginx-ingress-controller-mp5zd:/etc/nginx/nginx.conf ~/Desktop/aa.conf
```

上述命令会出现以下警告，可以忽略

>  tar: Removing leading / from member names