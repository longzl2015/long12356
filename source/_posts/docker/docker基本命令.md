---
title: docker 基本命令
date: 2016-04-02 22:46:48
tags: 
  - docker
categories:
  - docker
---

## 1. 镜像基本操作
- 搜索镜像:   docker search 关键字
- 下载一个镜像:   docker pull 镜像名
- 本地镜像列表:   docker images
- 删除镜像:   docker rmi 镜像名

## 2. 容器基本操作
### 2.1 创建并运行一个容器
> docker run - -name 容器名 -d 镜像名

	-d表示deamon，以后台启动这个container， 执行这个container是永远不会停止的，
	-i表示同步container的stdin
	-t表示同步container的输出
	--rm=true 表示容器运行完后，自动删除

### 2.2 容器列表
docker ps 查看所有正在运行的容器
docker ps -a 查看所有的容器，包括停止运行的

### 2.3 启动和停止容器
docker stop  container-id/container-name
docker start  container-id/container-name

### 2.4 登陆容器
登陆容器能够使我们在容器中像正常访问linux一样操作,访问正在运行的容器
docker exec -it  container-id/container-name bash

### 2.5 端口映射
由于本机和本机的局域网是无法访问docker容器的，所以需要将docker容器的端口映射到当前主机的端口上。
> docker run -d -p (宿主机器端口):(虚拟机端口) --name 容器名 镜像名

### 2.6 删除容器
docker rm  container-id
docker rm $(docker ps -a -q) 删除所有的容器

### 2.7 查看容器日志
docker logs  container-id/container-name

### 2.8 将容器保存为一个镜像
docker commit  container-id/container-name

## 3.自定义一个镜像（安装自己想要的环境）
### 3.1 commit方式
1. 进入bash交互环境
  docker run -t -i 镜像名 /bin/bash
2. 安装想要的软件( 如 wget )
  docker run -t -i b15 /bin/bash

3. 安装完毕后退出容器
  exit
4. 找到刚刚创建的容器
  docker ps -a
5. 将该容器提交为一个新的镜像
  docker commit 容器名  新的镜像名

### 3.2 dockfile方式
1. 预先编写一个Dockerfile
```
# This is a comment
FROM centos  //基于什么镜像
MAINTAINER doublespout <doublespout@gmail.com>   //作者是
RUN yum install -y wget    //依次执行什么命令
```
2. 安装如下命令创建镜像

```bash
mkdir wget
cd wget
vi Dockerfile #将上面内容复制进去
docker build -t="doublespout/wget" ./
# 也可以直接使用远程文件
docker build -t="dockerfile/nginx" github.com/dockerfile/nginx
#将看到安装脚本的执行输出，安装完成后，执行 docker images 就可以看到我们刚才创建的镜像了
```

## 4.容器和宿主机的资源拷贝
### 从container往host拷贝文件

```Sh
docker cp <container_id>:/root/hello.txt .
```

### 从host往container里拷贝文件
```Sh
docker stop <container_name_or_ID>
#执行命令找到程序pid
ContainerID=$(docker inspect --format {{.Id}} <container_name_or_ID>)
cp /tmp/tmp.txt /var/lib/docker/aufs/mnt/<ContainerID>/tmp/
#如果为centos则修改为：
#/var/lib/docker/devicemapper/mnt/<ContainerID>/rootfs/
```

## 5.将多个 container 连接起来
先下载一个redis数据库image，这也是以后做项目的常规用法，数据库单独用一个image，程序一个image，利用docker的link属性将他们连接起来。
> docker pull redis #下载官方的redis镜像，耐心等待一段时间


接着我们执行命令启动redis镜像到一个container，开启redis-server持久化服务
> docker run --name redis-server -d redis redis-server --appendonly yes


然后再启动一个redis镜像的container作为客户端连接它
```
docker run -it --link redis-server:redis --rm redis /bin/bash
 
redis@7441b8880e4e:/data$ env  #想要知道当前我们在主机还是container，注意$前面的host和name
REDIS_PORT_6379_TCP_PROTO=tcp
HOSTNAME=7441b8880e4e
TERM=xterm
REDIS_NAME=/boring_perlman/redis
REDIS_PORT_6379_TCP_ADDR=172.17.0.34    #redis服务器ip
REDIS_PORT_6379_TCP_PORT=6379                #redis服务器端口
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PWD=/data
REDIS_PORT_6379_TCP=tcp://172.17.0.34:6379
SHLVL=1
REDIS_PORT=tcp://172.17.0.34:6379
HOME=/
_=/usr/bin/env
 
$redis-cli -h "$REDIS_PORT_6379_TCP_ADDR" -p "$REDIS_PORT_6379_TCP_PORT"
 
172.17.0.34:6379> set a 1 #成功连入redis数据库服务器
OK
172.17.0.34:6379> get a
"1"
172.17.0.34:6379>
```
通过这样的方法，我们就可以将发布的应用程序和数据库分开，单独进行管理，以后对数据库进行升级或者对程序进行调整两者都没有冲突，系统环境变量我们可以通过程序的os模块来获得。


## 6.文件卷标加载
比如我们想要一个日志文件保存目录，如果直接写入container，那样image升级之后，日志文件处理就比较麻烦了，所以就需要将主机的文件卷标挂载到container中去，挂载方法如下：
```
$ docker run --rm=true -i -t --name=ls-volume -v /etc/:/opt/etc/ centos ls /opt/etc
boot2docker  hostname     ld.so.conf     passwd-      securetty  sysconfig
default      hosts        mke2fs.conf    pcmcia       services   sysctl.conf
fstab        hosts.allow  modprobe.conf  profile      shadow     udev
group        hosts.deny   motd           profile.d    shadow-    version
group-       init.d       mtab           protocols    shells
gshadow      inittab      netconfig      rc.d         skel
gshadow-     issue        nsswitch.conf  resolv.conf  ssl
host.conf    ld.so.cache  passwd         rpc          sudoers
```
如果想要挂载后的文件是只读，需要在这样挂载：
>-v /etc/:/opt/etc/:ro #read only


我们也可以挂载其他container中的文件系统，需要用到 -volumes-from 参数，我们先创建一个container，他共享/var/目录给其他container。
>$ docker run -d -i -t -p 1337:1337 --name nodedev -v /var/ fa node /var/nodejs/app.js


然后我们启动一个ls-var的container来挂载nodedev共享的目录：

> $ docker run --rm=true -i -t --volumes-from nodedev --name=aaa1 centos ls /var
> adm    db     games   kerberos  local  log   nis     opt       run    tmp  yp
> cache  empty  gopher  lib       lock   mail  nodejs  preserve  spool  var


我们打印var目录，会发现多了一个nodejs的目录，就是从nodedev中的container挂载过来的。其实我们挂载其他container的路径都是在根目录上的。

## 7.发布到docker hub上去

我们做完镜像，就需要将镜像发布到docker hub上，供服务器下载然后运行，这类似git仓库，将自己开发的东西丢到云服务器上，然后自己在其他机器或者其他开发者可以下载镜像，并且从这个镜像开始运行程序或者再进行2次制作镜像。

我们需要先登录docker帐号，执行：
 ```
$ docker login #输入你在docker官网注册的帐号和密码就可以登录了
$ docker push <用户名>/<镜像名> #将你制作的镜像提交到docker hub上
 ```
非官方不允许直接提交根目录镜像，所以必须以<用户名>/<镜像名>这样的方式提交，比如 doublespout/dev 这样


## 8.小窍门
### 如何像使用linux虚拟机那样运行一个container
比如我们想要直接登录container执行多个任务，又不想直接借助 docker run 命令，以后我们还想登录到这个container来查看运行情况，比如执行top，ps -aux命令等等。
docker run -d -i -t -p 1337:1337 fa /bin/bash
docker attach 58
bash-4.2#
这样我们就可以通过进入container来调试程序了。但是一旦执行ctrl+d或者exit，container就将退出，这个方法也只适用于开发调试的时候。
### 设置别名
alias dockerbash='docker run -i -t CONTAINER_ID /bin/bash'


http://snoopyxdy.blog.163.com/blog/static/601174402014720113318508/




