---
title: classpath详解
date: 2015-08-24 13:45:09
tags: [spring,classpath]
categories: [spring,其他]

---
classpath:和`classpath*`:的区别
<!--more-->

## `classpath:`

在spring配置文件里，可以用 **classpath:** 来从classpath中加载资源

比如在 src/main/resources 下有一个jdbc.properties的文件，可以用如下方法加载：

```xml
<property name="locations">  
    <list>  
        <value>classpath:jdbc.properties</value>  
    </list>  
</property>  
```

## `classpath*:`


```xml
<property name="mappingLocations">  
   <list>  
        <value>classpath*:/hibernate/*.hbm.xml</value>  
   </list>  
</property>  
```


**classpath:** 与 **`classpath*:`** 的区别在于，前者只会从当前classpath中加载，而后者会从所有的classpath中加载

`classpath*`:优点

在多个classpath中存在同名资源，都需要加载，那么就不能使用**classpath:**，而是使用**`classpath*:`**

`classpath*`:缺点

可想而知，用`classpath*`:需要遍历所有的classpath，所以加载速度是很慢的，因此，在规划的时候，应该尽可能规划好资源文件所在的路径，尽量避免使用`classpath*`

---
详细讲解：
[Spring中使用classpath加载配置文件浅析](http://my.oschina.net/yjx/blog/6253)
