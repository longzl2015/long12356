---
title: java.library.path 用途
tags: 
  - java
categories:
  - java
---



## 简介：

> The Java Virtual Machine (JVM) uses the `java.library.path` property in order to locate native libraries. This property is part of the system environment used by Java, in order to locate and load native libraries used by an application.

> When a Java application loads a native library using the `System.loadLibrary()` method, the `java.library.path` is scanned for the specified library. If the JVM is not able to detect the requested library, it throws an `UnsatisfiedLinkError`. Finally, the usage of native libraries makes a Java program more platform dependent, as it requires the existence of specific native libraries.

简而言之：jvm 使用 `java.library.path ` 来加载 本地库(native libraries)，如 加载 dll 等

## How to set the java.library.path property 

There are several ways to set the `java.library.path` property:

- *使用命令行方式* : Using the terminal (Linux or Mac) or the command prompt (Windows), we can execute the following command, in order to execute our Java application:

```
java -Djava.library.path=<path_to_dll> <main_class>
```

where the `path_to_dll` argument must be replaced with the path of the required library.

- *使用java源码配置* : Inside an application’s code we can set the`java.library.path`. using the following code snippet:

```
System.setProperty(“java.library.path”, “/path/to/library”);  	
```

- *通过 ide 配置*: The `java.library.path` can be configured using an IDE, such as `Eclipse` or `Netbeans`.
