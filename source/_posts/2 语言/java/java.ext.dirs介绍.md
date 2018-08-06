---
title: java.ext.dirs介绍
date: 2016-08-05 03:30:09
tags: 
  - java
categories:
  - java
---

java.ext.dirs 用于加载指定路径下的jar文件，默认是 $JAVA_HOME/jre/lib/ext 。

在添加 java.ext.dirs 参数时， 需要注意 java.ext.dirs会覆盖默认的 $JAVA_HOME/jre/lib/ext。正确的使用方法为：

```
 -Djava.ext.dirs=./plugin:$JAVA_HOME/jre/lib/ext
```

<!--more-->

### JDK software directory tree
![jdk_tree](../../图/jdk_tree.png)

### 详解

1. 当我们运行jar包时，一般可以通过如下的命令：

`java -cp ".\a.jar;.\b.jar" -jar myjar.jar MainClass`

但是 cp 参数不支持文件夹的方式

2. 如果需要指定其他依赖lib包的文件夹，可以采用：

`java -Djava.ext.dirs=".\lib" -jar myjar.jar MainClass` 

3. 但是上面的方式会会有一个问题，就是会覆盖默认的ext值。

ext的默认值是JRE/LIB/EXT. 

`-Djava.ext.dirs`会覆盖Java本身的ext设置，`java.ext.dirs`指定的目录由ExtClassLoader加载器加载。
如果您的程序没有指定该系统属性，那么该加载器默认加载`$JAVA_HOME/jre/lib/ext`目录下的所有jar文件。
但如果你手动指定系统属性且忘了把`$JAVA_HOME/jre/lib/ext`路径给加上，那么ExtClassLoader不会去加载`$JAVA_HOME/lib/ext`下面的jar文件，
这意味着你将失去一些功能，**例如java自带的加解密算法实现。**

**解决方案:**

只需在该路径后面补上ext的路径即可！比如(**linux环境**)：
​       -Djava.ext.dirs=./plugin:$JAVA_HOME/jre/lib/ext。**windows环境下**运行程序，应该用分号替代冒号来分隔。

## 参考来源
[java jar扩展包](https://docs.oracle.com/javase/tutorial/ext/basics/install.html)