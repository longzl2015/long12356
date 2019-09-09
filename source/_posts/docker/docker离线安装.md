---
title: docker离线安装
date: 2019-08-10 22:46:48
tags: 
  - docker
categories: [docker]
---

在某些场景下，服务器是不允许连接外网的。因此本文简单记录离线安装 docker 的过程。

需确保两台 CentOs 环境一致。

##简单概述

- 先安装一个最小化安装的centos系统，并确保该系统能连接外网。
- 使用 `yumdownloader --resolve docker-ce`下载docker的相关安装包 
- 将上一步获取到的安装包，复制到无外网环境的主机上
- 执行 rpm -ivh --replacefiles --replacepkgs *.rpm 即可
- 最后 `systemctl enable docker.service` 和 `systemctl start docker.service`

##具体步骤

https://ahmermansoor.blogspot.com/2019/02/install-docker-ce-on-offline-centos-7-machine.html