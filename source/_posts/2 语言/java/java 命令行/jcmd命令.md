---

title: jcmd命令

date: 2018-12-27 15:05:00

categories: [jvm]

tags: [jvm]

---

jcmd工具可以向正在运行的JVM发送诊断请求，通过这些请求，我们可以获得 jvm 的系统变量、jdk版本号、线程信息等等


<!--more-->

## jcmd 命令集合

```text
JFR.stop
JFR.start
JFR.dump
JFR.check
VM.native_memory
VM.check_commercial_features
VM.unlock_commercial_features
ManagementAgent.stop
ManagementAgent.start_local
ManagementAgent.start
Thread.print
GC.class_stats
GC.class_histogram
GC.heap_dump
GC.run_finalization
GC.run
VM.uptime
VM.flags
VM.system_properties
VM.command_line
VM.version
help
```

```text
> jcmd 2125 help Thread.print

2125:
Thread.print
Print all threads with stacktraces.
 
Impact: Medium: Depends on the number of threads.
 
Permission: java.lang.management.ManagementPermission(monitor)
 
Syntax : Thread.print [options]
 
Options: (options must be specified using the <key> or <key>=<value> syntax)
        -l : [optional] print java.util.concurrent locks (BOOLEAN, false)

```

## 常用命令
以pid 为 20877为例。

### 查看当前 pid 使用的 jdk 版本

> jcmd 20877 VM.version

### 查看当前 pid 所有的系统属性

> jcmd 20877 VM.system_properties

### 查看当前 pid 所有的flag

> jcmd 20877 VM.flags

其他命令可见文末的参考链接。

## 参考
[java问题跟踪工具](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/toc.html)
[jcmd工具](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/tooldescr006.html)