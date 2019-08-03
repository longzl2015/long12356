---
title: docker 运维常见问题
date: 2019-06-02 22:46:48
tags: 
  - docker
categories: [docker]
---

[TOC]

## 删除无用镜像和容器

方法一

> docker system prune -f

方法二

>docker ps -a | grep 'Exited' | awk '{print $1}' | xargs docker stop | xargs docker rm
>
>docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi

## 修改docker存储位置

https://stackoverflow.com/questions/24309526/how-to-change-the-docker-image-installation-directory/34731550#34731550

1. 编辑daemon.json

在 `/etc/docker/daemon.json`中添加

```json
{
  "data-root": "/home/k8s/docker"
}
```

2. 复制原数据

将 `/var/lib/docker`内容拷贝到新文件路径.

3. 重启

```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 远程

https://success.docker.com/article/how-do-i-enable-the-remote-api-for-dockerd
https://docs.docker.com/engine/security/https/

### 服务端设置

在作为docker远程服务的centos7机器中配置如下：

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

### 客户端

在环境 bash_profile 中添加 DOCKER_HOST 即可

> export DOCKER_HOST="tcp://10.100.1.130:2376"

