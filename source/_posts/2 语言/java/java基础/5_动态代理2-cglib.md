---
title: 5_动态代理2-cglib
date: 2018-09-12 03:30:10
tags: [动态代理,java,todo]
categories: [语言,java,java基础]
---

[TOC]

上篇讲了 jdk 动态代理 必须依赖接口才能进行代理的。因此，对于没有实现接口的类，只能使用 CGLIB 动态代理来实现了。



<!--more-->


## 简单使用

使用CGLIB需要在MAVEN中添加依赖

```xml
<dependency>
    <groupId>cglib</groupId>
    <artifactId>cglib</artifactId>
    <version>3.2.8</version>
</dependency>
```

实际代码

```java
public class Target{
    public void f(){
        System.out.println("Target f()");
    }
    public void g(){
        System.out.println("Target g()");
    }
}

public class Interceptor implements MethodInterceptor {
    @Override
    public Object intercept(Object obj, Method method, Object[] args,    MethodProxy proxy) throws Throwable {
        System.out.println("I am intercept begin");
        proxy.invokeSuper(obj, args);
        System.out.println("I am intercept end");
        return null;
    }
}

public class Test {
    public static void main(String[] args) {
        //指定输出目录，这样cglib会将动态生成的每个class都输出到文件中
        System.setProperty(DebuggingClassWriter.DEBUG_LOCATION_PROPERTY, "F:\\code");
         //实例化一个增强器，也就是cglib中的一个class generator
        Enhancer eh = new Enhancer();
         //设置目标类
        eh.setSuperclass(Target.class);
        // 设置拦截对象
        eh.setCallback(new Interceptor());
        // 生成代理类并返回一个实例
        Target t = (Target) eh.create();
        t.f();
        t.g();
    }
}
```

## 原理

## 来源

https://blog.csdn.net/mantantan/article/details/51873755
https://blog.csdn.net/zhanlanmg/article/details/48161003
https://www.cnblogs.com/cruze/p/3865180.html
https://www.cnblogs.com/monkey0307/p/8328821.html