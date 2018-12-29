---
title: spring Bean的加载过程.md

date: 2016-03-22 22:55:02

tags: [spring,ioc,bean]

---

[TOC]

<!--more-->

# 从web.xml配置的监视器中启动

```xml
<listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
</listener>
```

`ContextLoaderListener`实现了`ServletContextListener`接口,tomcat启动时就会调用`ContextLoaderListener`的`contextInitialized()`方法，完成以下事件：

1. 判断是否重复注册了WebApplicationContext。
2. 获取各种配置文件（如web.xml中的`contextConfigLocation`的属性值），将其注册到`XmlWebApplicationContext`
3. 最后调用`wac.refresh();`

`wac.refresh()`是IOC加载最核心的部分，完成了资源文件的加载、配置文件解析、Bean定义的注册、组件的初始化等核心工作。

## AbstractApplicationContext的refresh()源代码

```java
public void refresh() throws BeansException, IllegalStateException {
synchronized (this.startupShutdownMonitor) {
   // 准备上下文用于刷新:做一些准备工作，如记录开始时间，输出日志
   //initPropertySources()和getEnvironment().validateRequiredProperties()一般没干什么事。
   prepareRefresh();
   // 创建BeanFactory，Bean定义的解析与注册
   ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();
   // 为该上下文配置已经生成的BeanFactory
   prepareBeanFactory(beanFactory);
    try {
    //可以调用用户自定义的BeanFactory来对已经生成的BeanFactory进行修改
    postProcessBeanFactory(beanFactory);
    invokeBeanFactoryPostProcessors(beanFactory);
    //可以对以后再创建Bean实例对象添加一些自定义操作
    registerBeanPostProcessors(beanFactory);
    //初始化信息源
    initMessageSource();
    //初始化事件
    initApplicationEventMulticaster();
    //初始化在特定上下文中的其它特殊Bean
    onRefresh();
    registerListeners();
    //Bean的真正实例化，创建非懒惰性的单例Bean
    finishBeanFactoryInitialization(beanFactory);
    finishRefresh();
   }catch (BeansException ex) {
    destroyBeans()；
    cancelRefresh(ex);
    throw ex;
   }
}
```

----

[看看Spring的源码(一)——Bean加载过程](http://my.oschina.net/gongzili/blog/304101)