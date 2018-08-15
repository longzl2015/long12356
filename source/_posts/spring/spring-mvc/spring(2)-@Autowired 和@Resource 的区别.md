---
title: spring(2)-@Autowired 和@Resource 的区别
date: 2015-08-10 13:22:58
tag: [autowired,resource]
categories: spring

---

@Autowired 和@Resource 的区别

<!--more-->

一、

@Autowired和@Resource都可以用来装配bean，都可以写在字段上，或者方法上。

二、

@Autowired属于Spring的；@Resource为JSR-250标准的注释，属于J2EE的。

三、

@Autowired默认按类型装配，默认情况下必须要求依赖对象必须存在，如果要允许null值，可以设置它的required属性为false，例如：`@Autowired(required=false)` ，
如果我们想使用名称装配可以结合`@Qualifier`注解进行使用，如下：

```java
@Autowired()
@Qualifier("baseDao")
private BaseDao baseDao;
```

四、

@Resource，默认按照名称进行装配，名称可以通过name属性进行指定，如果没有指定name属性，当注解写在字段上时，默认取字段名进行安装名称查找，
如果注解写在setter方法上默认取属性名进行装配。当找不到与名称匹配的bean时才按照类型进行装配。但是需要注意的是，如果name属性一旦指定，就只会按照名称进行装配。

例如：

```java
@Resource(name="baseDao")
private BaseDao baseDao;
```

参考：
[Spring 注释 @Autowired 和@Resource 的区别](http://www.cnblogs.com/leiOOlei/p/3713779.html)
