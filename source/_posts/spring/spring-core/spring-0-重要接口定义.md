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

BeanFactory 是spring最基本的IOC容器接口。它对IOC容器的基本行为进行了定义，但不关心具体的实现。

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

### BeanDefinition

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

![image-20191017141723423](/images/spring-0-重要接口定义/image-20191017141723423.png)


## BeanFactory vs FactoryBean vs ObjectFactory

### BeanFactory

BeanFactory 接口是 spring 最基本的 IOC 容器。具体内容见本文的 [BeanFactory](#BeanFactory)小节。

### FactoryBean 

```java
public interface FactoryBean<T> {
    // 返回factoryBean创建的实例，
    // 如果isSingleton为true，则该实例会放到Spring容器中的单实例缓存池中
    T getObject() throws Exception;
    // 返回FactoryBean创建的bean的类型
    Class<?> getObjectType();
    // 返回FactoryBean创建的是作用域是singleton还是prototype。
    boolean isSingleton();
}
```

FactoryBean 本质上就是一个 Bean，但是它是一个能生产 Bean 对象的一个工厂 Bean 。
在 ApplicationContext.getBean(name) 过程中，spring会对 FactoryBean 类型进行特殊处理：

> 当 name 表示的 FactoryBean 类型类时, getBean() 会直接返回 `FactoryBean.getObject()的返回值` ，

FactoryBean 通常是用来创建比较复杂的bean。
很多开源项目在集成Spring时都使用 FactoryBean。例如 `org.mybatis.spring.SqlSessionFactoryBean`

### ObjectFactory

```java
public interface ObjectFactory<T> {
	T getObject() throws BeansException;
}
```

ObjectFactory 目的也是工厂，用于生产 Bean 对象。这个接口和FactoryBean有点像，但是 ObjectFactory 仅仅是一个普通的工厂。

在开源项目中，ObjectFactory 也被经常使用。如 `RequestObjectFactory`、`ResponseObjectFactory`、`SessionObjectFactory`

## 优质文章

[Spring中FactoryBean的作用和实现原理](https://www.guitu18.com/post/2019/04/28/33.html)
