---
title: docker 容器和镜像位置
date: 2019-04-02 22:46:48
tags: 
  - docker
categories: [docker]
---

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

