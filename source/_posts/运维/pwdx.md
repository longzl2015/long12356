---

title: pwdx

date: 2018-08-14 下午5:54

categories: [pwdx]

tags: [pwdx,mac]

---

pwdx pid用来查看正在运行的线程所在的目录


<!--more-->


## mac 添加 pwdx 支持

mac系统没有内置 pwdx 命令，可以通过添加 bash function 实现

在bash_profile最后添加以下内容即可：

```bash
function pwdx()   { L=$(lsof -a  -d cwd -p $1 | tail -1); echo /${L#*/}; }
```


