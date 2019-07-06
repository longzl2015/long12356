---
title: docker 远程访问
date: 2016-04-02 22:46:48
tags: 
  - docker
categories: [docker]
---



**在作为docker远程服务的centos7机器中配置如下：**

1、在 `/etc/systemd/system/docker.service.d/startup_options.conf `，配置远程访问。


```
# /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2376

```

2、docker重新读取配置文件，重新启动docker服务

```
# systemctl daemon-reload
# systemctl restart docker.service
```

3、查看docker是否已开启远程

```
curl http://localhost:2376/version
```

注意：生产环境最好将这个关掉，或者做好安全的配置





## 使用本地 docker 客户端连接远程docker daemon

很简单，只需在环境 bash_profile 中添加 DOCKER_HOST 即可

> export DOCKER_HOST="tcp://10.100.1.130:2376"



##参考文章：

https://success.docker.com/article/how-do-i-enable-the-remote-api-for-dockerd
https://docs.docker.com/engine/security/https/






