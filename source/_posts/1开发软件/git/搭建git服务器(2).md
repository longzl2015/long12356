---
title: 搭建git服务器-http访问
date: 2015-09-01 09:09:28
tags: [git,git服务器,gitolite,gitweb]
categories: [开发软件,git]

---

在本教程中，我们将学习如何通过 gitolite 和 gitweb 工具来安装一个git服务器，该服务器可通过 ssh 和 http 协议进行访问。
Gitolite 工具能够实现用户管理功能。
gitweb 工具提供一个仓库列表的 web 界面。
apache 工具提供智能 http 服务(smart http)，用于连接git服务器。
<!--more-->

> 注：该文章是从其他文字转过来的，具体出处记不住了。


## 准备

**Git 项目网站:** http://git-scm.com/

### 服务器配置

- Arch: i686 / x86_64
- Packages : Gitolite and Gitweb
- Git server ip address : 10.82.59.55

note:如果能进行域名解析，你也可以使用 git 服务器主机名。

### 摘要:

搭建一个私有 git 服务器。该服务器能通过ssh和http链接。这里，gitweb用于浏览仓库细节。Gitolite 用于git服务器的用户/组管理。

Note: 该文章中，# 表示 root用户。$ 表示 git 用户。

## 配置本机PC，非git服务器

搭建步骤如下:

首先从你的PC开始，**注意不是你的git服务器**。

创建 RSA key 。

### Step A:

登陆你的PC主机，该机用于远程管理git服务器。

如果你的主目录下不存在 .ssh 目录，说明你的 SSH 公钥/私钥对尚未创建。可以用这个命令创建：

```bash
ssh-keygen -t rsa -C "Git-Admin"
```

该命令会在用户主目录下创建 .ssh 目录，并在其中创建两个文件：

- id_rsa 私钥文件。

是基于 RSA 算法创建。该私钥文件要妥善保管，不要泄漏。

- id_rsa.pub 公钥文件。

和 id_rsa 文件是一对儿，该文件作为公钥文件，可以公开。

Note：Git-Admin 为你的pc客户端的git用户名。

### Step B:

使用 scp 将 id_rsa.pub 复制到 git服务器上。

```bash
$ scp ~/.ssh/id_rsa.pub root@ip-address-of-git-server:~
```

## 配置git服务器
以 root 登陆 git 服务器。

### Step 1:
安装 git http 和 perl 依赖。

```bash
yum -y install git httpd perl-Time-HiRes perl-Data-Dumper
```

### Step 2:
创建 git 用户，并更改它的 gid 和 uid

```bash
useradd git
usermod -u 600 git
groupmod -g 600 git
```

### Step3:

将得到的 id_rsa.pub 改为 Git-Admin.pub。同时将其 mv 到 /home/git 。将它的用户/组更改为git。

```bash
mv /root/id_rsa.pub /home/git/Git-Admin.pub ; chown git:git /home/git/Git-Admin.pub
```

### Step 4:
登陆git用户，从 github.com 克隆 gitolite。

```bash
su -l git

whoami
(The command will show you log in with which user)

echo $HOME
(The command will show what is your home directory)

git clone git://github.com/sitaramc/gitolite
```

### Step 5:
创建 bin 目录和设置 Git-Admin 账户

Note: 将 id_rsa.pub 改为 Git-Admin.pub 的原因是：
the Gitolite will provide same name of user in gitolite.conf file as the name of .pub file.
for eg. if I use only id_rsa.pub then "id_rsa” user will be created.

因此，当你需要通过 ssh 添加一个 git 服务器的用户时，你需要将该用户的 id_rsa.pub 重命名为 user-name.pub。比如，joe的 rsa file 应该被改为 joe.pub (id_rsa.pub –rename–joe.pub)

```bash
 mkdir -p /home/git/bin
 gitolite/install -ln
 gitolite setup -pk Git-Admin.pub
```

### Step 6:
退出 git 用户。登陆 root 。核对一下 suexec 的默认值。

```bash
exit
(logout from git user)
```

我的git服务器 suexec 细节.

```bash
[root@gitserver ~]# suexec -V
 -D AP_DOC_ROOT="/var/www"
 -D AP_GID_MIN=100
 -D AP_HTTPD_USER="apache"
 -D AP_LOG_EXEC="/var/log/httpd/suexec.log"
 -D AP_SAFE_PATH="/usr/local/bin:/usr/bin:/bin"
 -D AP_UID_MIN=500
 -D AP_USERDIR_SUFFIX="public_html"
```

### Step 7:
创建 bin 目录 （in /var/www ）
(Why /var/www ? because I got the detail from suexec -V,see parameter AP_DOC_ROOT)

下面的命令将创建一个 /var/www/bin 文件夹（with permission 0755 and owner &group is git）

```bash
install -d -m 0755 -o git -g git /var/www/bin
```

### Step 8:
在 /var/www/bin/ 创建一个 gitolite-suexec-wrapper.sh 。然后保存退出。

```bash
vi /var/www/bin/gitolite-suexec-wrapper.sh

    #!/bin/bash
    #
    # Suexec wrapper for gitolite-shell
    #

    export GIT_PROJECT_ROOT="/home/git/repositories"
    export GITOLITE_HTTP_HOME="/home/git"

    exec ${GITOLITE_HTTP_HOME}/gitolite/src/gitolite-shell
```

### Step 9:
修改 /var/www/bin 和 gitolite-suexec-wrapper.sh 的权限

```bash
chown -R git:git /var/www/bin
chmod 750 /var/www/bin/gitolite-suexec-wrapper.sh
chmod 755 /var/www/bin
```

### Step 10:
将 /home/git/.gitolite.rc 里的 UMASK 0077 修改为 UMASK =0027

```bash
vi /home/git/.gitolite.rc

    UMASK => 0027,
```

### Step 11:
安装 GitWeb

```bash
yum install gitweb
```

### Step 12:
默认情况下，gitweb 会安装在 /var/www/git 目录。（目录下包含 gitweb.cgi 文件）
修改 /var/www/git 目录。如下所示：

```bash
mv /var/www/git /var/www/html/gitweb
```

### Step 13:
修改 /var/www/html/gitweb 所有者

```bash
chown -R git:git /var/www/html/gitweb
```

下面是我服务器的细节：

```bash
[root@gitserver html]# chown -R git:git gitweb/
[root@gitserver html]# ls -ld gitweb/
drwxr-xr-x 2 git git 4096 Jun  1 12:36 gitweb/
[root@gitserver html]# ls -la gitweb/
total 252
drwxr-xr-x 2 git  git    4096 Jun  1 12:36 .
drwxr-xr-x 3 root root   4096 Jun  1 12:34 ..
-rw-r--r-- 1 git  git     115 Apr 24  2010 git-favicon.png
-rw-r--r-- 1 git  git     207 Apr 24  2010 git-logo.png
-rwxr-xr-x 1 git  git  204754 Jun  1 12:36 gitweb.cgi
-rw-r--r-- 1 git  git    8379 Apr 24  2010 gitweb.css
-rw-r--r-- 1 git  git   24142 Apr 24  2010 gitweb.js
[root@gitserver html]#
```

### Step 14:

编辑文件 /etc/gitweb.conf  修改其中的两个变量:
 `$projectroot` 和 `$projects_list`

```bash
vi /etc/gitweb.conf

    our $projectroot = "/home/git/repositories/";
    our $projects_list = "/home/git/projects.list";
```

### Step 15:
修改文件 /var/www/html/gitweb/gitweb.cgi 并修改其中的两个变量:
 `$projectroot` 和 `$projects_list`

```bash
vi /var/www/html/gitweb/gitweb.cgi

    our $projectroot = "/home/git/repositories";
    our $projects_list = "/home/git/projects.list";
```

### Step 16:
创建一个虚假文件夹（dummy folder git）。注意加上 permissions,owner and group限制。

```bash
install -d -m 0755 -o apache -g apache /var/www/git  (This is dummy one)
```

### Step 17:
打开 /etc/httpd/conf/httpd.conf 。
在最后一行加上 VirtualHost 配置。

Note: 如果你的 git 服务器有使用主机名和 FQDN，你就可以将 ServerName 和 ServerAlias 前的 # 去掉。然后，写上你的主机信息。ServerAdmin表示管理员的联系邮箱。

```text
     <VirtualHost *:80>
    
     # You can comment out the below 3 lines and put correct value as per your server information
     #  ServerName        gitserver.example.com
     #  ServerAlias       gitserver
    
     ServerAdmin       youremailid@example.com
    
     DocumentRoot /var/www/git
     <Directory /var/www/git>
         Options       None
         AllowOverride none
         Order         allow,deny
         Allow         from all
    
     </Directory>
    
     SuexecUserGroup git git
     ScriptAlias /git/ /var/www/bin/gitolite-suexec-wrapper.sh/
     ScriptAlias /gitmob/ /var/www/bin/gitolite-suexec-wrapper.sh/
    
     <Location /git>
         AuthType Basic
         AuthName "Git Access"
         Require valid-user
         AuthUserFile /etc/httpd/conf/git.passwd
     </Location>
     </VirtualHost>
```

### Step 18:

修改 /etc/httpd/conf.d/git.conf 。该文件在安装 gitweb 时自动创建。
下面我将对 Git Server 进行部分修改。重点！不能落下一步。

```bash
vi /etc/httpd/conf.d/git.conf

    Alias /gitweb /var/www/html/gitweb
    
    <Directory /var/www/html/gitweb>
      Options +ExecCGI
      AddHandler cgi-script .cgi
      DirectoryIndex gitweb.cgi
    </Directory>
    <Location /gitweb>
       AuthType Basic
       AuthName "Git Access"
       Require valid-user
       AuthUserFile /etc/httpd/conf/git.passwd
    </Location>
``` 

### Step 19:
下面我们将创建 apcahe 的管理员的用户密码。
当你第一次创建用户时，我们需要使用 -c 符号。-c 表示创建一个新的文件。详细参见htpasswd的man帮助。

```bash
htpasswd -c /etc/httpd/conf/git.passwd admin
```

对于添加一个用户或者修改存在的用户密码，不需要添加 -c

```bash
htpasswd /etc/httpd/conf/git.passwd  user1
htpasswd /etc/httpd/conf/git.passwd  testuser
```
当你设置一个 htpasswd user 或 passwd时，需要重启或重载 apache 。
chkconfig 命令使 apache 服务开机启动。设置为 runelevel 3 and 5

```bash
### On CentOS 6.x / RHEL 6.x
/etc/init.d/httpd restart;chkconfig httpd on

### On CentOS 7.x / RHEL 7.x
systemctl restart httpd ; systemctl enable httpd
```

所有配置已完成，可以使用 git 服务器了。

## 使用 git 服务器
### GitWeb webpage

使用以下格式访问（网页会要求你输入你设置的 htpasswd 的用户和密码）

    http://ip-address-of-git-server/gitweb/

### 以 http方式 克隆仓库

使用命令（网页会要求你输入你设置的 htpasswd 的用户和密码）

```bash
git clone http://ip-address-of-git-server-OR-FQDN/git/repo-name.git
```

上面两个命令的不同之处，
- 克隆 git 仓库时在url中使用 git
- 访问网页时，使用 gitweb

Note: 如果你想要学习为什么使用 git 或 gitweb，请打开 git.conf 和 httpd.conf 文件。
- git.conf中 "Alias /gitweb /var/www/html/gitweb”

- httpd.conf中 "ScriptAlias /git/ /var/www/bin/gitolite-suexec-wrapper.sh/”

然后将testing.git克隆到桌面上或其他目录

```bash
cd ~/Desktop
git clone http://ip-address-of-git-server-OR-FQDN/git/testing.git
```

### 管理 git 服务器的用户和用户组

为了管理 git 服务器的用户和用户组，你需要克隆 gitolite-admin 到你的pc上。**注意，该PC必须是你在 Step A 和 Step B中使用的PC。**

这里我将复制 gitolite-admin 到桌面。

```bash
cd ~/Desktop
git config --global user.name "Git-Admin"
git config --global user.email "youremailid@example.com"
git clone git@GitServerIP-or-FQDN:gitolite-admin.git
```

通过配置 gitolite.conf 文件来管理访问 git 服务器的用户和用户组。
当你对 gitolite.conf 文件进行了如何修改，你都需要进行** git push **操作

下面是我电脑的配置参考

```bash
sharad@mypc:~/Desktop/gitolite-admin/conf$ pwd
/home/sharad/Desktop/gitolite-admin/conf

sharad@sharad-sapplica:~/Desktop/gitolite-admin/conf$ cat gitolite.conf

    repo gitolite-admin
        RW+     =   Git-Admin
   
    repo testing
        RW+     =   @all
        R       =   git daemon

sharad@mypc:~/Desktop/gitolite-admin/conf$
```

这里 R 和 W 的意义：
- R = Read
- W = Write

现在将这些修改 push 到 git服务器上。

```bash
cd ~/Desktop/gitolite-admin/conf
ls -l gitolite.conf

git add gitolite.conf
git commit -m "first commit"
git push origin master
```

### 在 git 服务器中创建仓库
我们创建一个 "linux” 仓库

1. 以 root 方式登陆 git 服务器，然后切换到 git 用户

```bash
su -l git
cd repositories
mkdir linux.git
cd linux.git
git --bare init
git update-server-info
```

2. Update projects.list 文件

更新 projects.list 文件。在该文件中添加你刚刚新建的 git 仓库名。

```bash
vi /home/git/projects.list
	
	testing.git
	linux.git
```
	

完成 update 操作后，你就可以在 gitWeb 上看到新的 repository 了。

如下图所示

![git_server](http://i.imgur.com/Cf8jJVi.jpg)


## 小结
1. 当 gitweb 出现 404 – No projects found 时，需要关闭 SElinux 。

### 参考
[How to install own git server with ssh and http access by using gitolite and gitweb in CentOS](http://sharadchhetri.com/2013/06/01/how-to-install-own-git-server-with-ssh-and-http-access-by-using-gitolite-and-gitweb-in-centos/)
