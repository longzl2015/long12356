---

title: spring-ioc

date: 2019-10-17 00:00:00

categories: [spring,springframe]

tags: [spring,springframe,ioc]

---

Spring 几个重要的接口类

<!--more-->

## 相关接口

### BeanFactory

BeanFactory是spring最基本的IOC容器接口。它对IOC容器的基本行为进行了定义，但不关心具体的实现。

以下列举BeanFactory的几个方法

- getBean()
- containsBean()
- isSingleton()
- isPrototype()
- isTypeMatch()
- 等等

###ApplicationContext

ApplicationContext是spring提供的更高级的IOC容器接口。它除了能够提供IoC容器的基本功能外(ListableBeanFactory、HierarchicalBeanFactory)，还为用户提供了多个的附加服务()。

- 支持信息源，可以实现国际化。（实现MessageSource接口）
- 访问资源。(实现ResourcePatternResolver接口)
- 支持应用事件。(实现ApplicationEventPublisher接口)

### BeanDefinition

BeanDefinition定义了spring中bean对象的基本行为和属性。



## 优质文章

[Spring：源码解读Spring IOC原理](https://www.cnblogs.com/ITtangtang/p/3978349.html)

