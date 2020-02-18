---

title: jstat命令

date: 2020-01-27 15:05:00

categories: [语言,java,命令行]

tags: [jvm,jstat]

---

jcmd工具 可以统计 GC 相关信息


<!--more-->

## 常用命令

###显示gc的信息，查看gc的次数，及时间

> jstat -gc pid 1000 10 (每隔1秒更新出最新的一行jstat统计信息，一共执行10次jstat统计）

S0C：第一个幸存区的大小
S1C：第二个幸存区的大小
S0U：第一个幸存区的使用大小
S1U：第二个幸存区的使用大小
EC：伊甸园区的大小
EU：伊甸园区的使用大小
OC：老年代大小
OU：老年代使用大小
MC：方法区大小
MU：方法区使用大小
CCSC:压缩类空间大小
CCSU:压缩类空间使用大小
YGC：从应用程序启动到采样时young gc的次数
YGCT：从应用程序启动到采样时young gc的所用的时间（s）
FGC：从应用程序启动到采样时full gc的次数
FGCT：从应用程序启动到采样时full gc的所用的时间（s）
GCT： 从应用程序启动到采样时整个gc所用的时间

### 获取gc的统计数据

> jstat -gcutil pid 3s （每3s打印一次gcutil）

S0：幸存1区当前使用比例
S1：幸存2区当前使用比例
E：伊甸园区使用比例
O：老年代使用比例
M：元数据区使用比例
CCS：压缩使用比例
YGC：年轻代垃圾回收次数
FGC：老年代垃圾回收次数
FGCT：老年代垃圾回收消耗时间
GCT：垃圾回收消耗总时间

## 参考

[java问题跟踪工具](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/toc.html)
