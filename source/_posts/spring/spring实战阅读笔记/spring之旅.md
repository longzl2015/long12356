---

title: spring读书笔记-spring之旅

date: 2018-10-23 20:33:00

categories: [springboot,spring实战阅读笔记]

tags: [spring,读书笔记]

---



<!--more-->


## 简化java开发

### DI 依赖注入

使 相互协作的类 保持松散耦合。

### AOP

允许开发者将 遍布应用各处的功能 统一分离出来，整合成可重用的类。如 日志、事务管理和安全等服务

### 模板代码

通过封装 jdbc 等 样板代码，利用 JdbcTemplate 等 减少 样板代码的重复量。

## spring的bean

spring的bean是由spring的容器管理的。

spring的容器主要分为两大类:

- bean工厂: 最简单的容器提供基本的DI支持
- 应用上下文: 基于 beanFactory 构建。提供更高级别的服务。


最基本的 ApplicationContext 接口 

- getId()
- getApplicationName()
- getDisplayName()
- getStartupDate()
- getParent()
- getAutowireCapableBeanFactory()

最基本的 beanFactory 接口

- getBean()
- containsBean()
- isSingleton()
- isPrototype()
- isTypeMatch()
- 等等

下面主要介绍 应用上下文。

### spring应用上下文(Application Context)

该类用于 装载bean 的定义并将他们组装起来。

spring应用上下文有多种实现:

- AnnotationConfigApplicationContext 加载基于Java配置类
- AnnotationConfigWebApplicationContext 加载基于Java配置类
- FileSystemXmlApplicationContext 加载位于文件系统路径下的一个或者多个XML配置文件
- ClassPathXmlApplicationContext 加载位于应用程序类路径下的一个或者多个XML配置文件。
- XmlWebApplicationContext 加载web应用下的一个或者多个XML配置文件

WebApplicationContext 后缀的应用上下文，主要用于Web应用。会在之后详细讲解。

### bean 的生命周期

1. spring 对 bean 进行实例化
2. spring 将 值 和 bean 的引用注入到 bean 对应的属性中
3. 若 bean 实现了 BeanNameAware 接口，spring 将 bean 的 Id 传递给 setBeanName() 方法
4. 若 bean 实现了 BeanFactoryAware 接口，spring 将调用 setBeanFactory() 方法，将 BeanFactory 容器实例传入
5. 若 bean 实现了 ApplicationContextAware 接口，Spring 将调用 setApplicationContext()方法，将 bean 所在的应用上下文的引用传入进来；
6. 若 bean 实现了 BeanPostProcessor 接口，Spring将调用它们的 postProcessBeforeInitialization() 方法；
7. 若 bean 实现了 InitializingBean 接口，Spring将调用它们的 after-PropertiesSet()方法。类似地，如果 bean 使用init-method声明了初始化方法，该方法也会被调用；
8. 若 bean 实现了 BeanPostProcessor 接口，Spring将调用它们的 postProcessAfterInitialization() 方法；
9. 若 bean 已经准备就绪，可以被应用程序使用了，它们将一直驻留在应用上下文中，直到该应用上下文被销毁；
10. 若 bean 实现了 DisposableBean 接口，Spring 将调用它的 destroy() 接口方法。同样，如果bean 使用destroy-method声明了销毁方法，该方法也会被调用。


## spring 模块

![](/images/spring之旅/spring模块.png)

具体介绍 阅读 <<spring实战>>。