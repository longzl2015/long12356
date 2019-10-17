---

title: spring-0-重要接口定义

date: 2019-10-17 00:00:00

categories: [spring,springframe]

tags: [spring,springframe,ioc]

---

Spring 几个重要的接口类

<!--more-->

## IOC容器

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

## bean对象

###BeanDefinition

BeanDefinition定义了spring中bean对象的基本行为和属性。

### BeanDefinitionReader

BeanDefinitionReader 定义了加载bean信息的 load() 方法。

```java
public interface BeanDefinitionReader {
	BeanDefinitionRegistry getRegistry();
	ResourceLoader getResourceLoader();
	ClassLoader getBeanClassLoader();
	BeanNameGenerator getBeanNameGenerator();
  // 从指定路径或资源对象加载 bean 定义
	int loadBeanDefinitions(Resource resource) throws BeanDefinitionStoreException;
  int loadBeanDefinitions(String location) throws BeanDefinitionStoreException;
  // 忽略
}
```

BeanDefinitionReader的子类如下所示:

![image-20191017141723423](/images/spring-0/image-20191017141723423.png)



## 优质文章

[Spring：源码解读Spring IOC原理](https://www.cnblogs.com/ITtangtang/p/3978349.html)

