---

title: git代理

date: 2018-08-05 03:30:09

tags: [git]

categories: [版本管理]

---

git 常用协议 以及 对应的 代理方法

<!--more-->

### Git常用的有两种协议:

常见的git clone 协议如下：

1. 使用http:// 协议

git clone https://github.com/EasyChris/baidu.git

2. 使用git:// 协议

git clone git@github.com:EasyChris/baidu.git

3. 使用ssh:// 协议

git clone ssh://user@server/project.git

### http/https协议

假设程序在无状态、无工作目录的情况下运行git指令，利用-c参数可以在运行时重载git配置，包括关键的http.proxy

git clone 使用 http.proxy 克隆项目

```
git clone -c http.proxy=http://127.0.0.1:1080 https://github.com/madrobby/zepto.git
```

git目录设置目录代理模式，不太建议全部设置为全局配置

假设shadowsocks的代理在本机地址是127.0.0.1 代理端口是1080

```
git config --local http.proxy 'socks5://127.0.0.1:1080' 
git config --local https.proxy 'socks5://127.0.0.1:1080'
```



### git协议(貌似不能用)

使用git协议的配置

```
git config core.gitProxy  'socks5://192.168.7.1:1080'
```

### ssh 协议

那么，你使用的是[SSH协议](http://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols#The-SSH-Protocol)连接的远程仓库。
因为git依赖ssh去连接，所以，我们需要配置ssh的socks5代理实现git的代理。在ssh的配置文件`~/.ssh/config`（没有则新建）使用`ProxyCommand`配置：

```
#Linux
Host bitbucket.org
  User git
  Port 22
  Hostname bitbucket.org
  ProxyCommand nc -x 127.0.0.1:1086 %h %p
Host github.com
  User git
  Port 22
  Hostname bitbucket.org
  ProxyCommand nc -x 127.0.0.1:1086 %h %p  
  
#windows
Host bitbucket.org
  User git
  Port 22
  Hostname bitbucket.org
  ProxyCommand connect -S 127.0.0.1:1080 %h %p
```