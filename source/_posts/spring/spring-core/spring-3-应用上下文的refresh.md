---

title: spring-3-应用上下文的refresh方法(转)

date: 2019-10-17 00:00:03

categories: [spring,springframe]

tags: [spring,springframe,ioc]

---

本文介绍spring应用上下文的refresh方法。

我们以AnnotationConfigApplicationContext为例。

<!--more-->

## 前言

在介绍 refresh() 方法之前，简单看下 AnnotationConfigApplicationContext 的构造函数: 

```java
public class AnnotationConfigApplicationContext extends GenericApplicationContext implements AnnotationConfigRegistry {
  public AnnotationConfigApplicationContext(String... basePackages) {
		this();
		scan(basePackages);
		refresh();
	}
}
```

##refresh方法总览

refresh方法的左右: 在创建IoC容器前，如果已经有容器存在，则需要把已有的容器销毁和关闭，以保证在refresh之后使用的是新建立起来的IoC容器。因此refresh类似于对IoC容器的重启。

```java
public class AbstractApplicationContext extends DefaultResourceLoader
		implements ConfigurableApplicationContext {
  public void refresh() throws BeansException, IllegalStateException {  
       synchronized (this.startupShutdownMonitor) {
           //设置容器的启动时间，标记状态为active，验证所有的必要参数已配置正确
           //等等
           prepareRefresh();
           //获取一个 BeanFactory
           ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();  
           //为BeanFactory配置容器特性，例如类加载器、事件处理器等  
           prepareBeanFactory(beanFactory);  
           try {  
               //为容器的某些子类指定特殊的BeanPost事件处理器  
               postProcessBeanFactory(beanFactory);  
               //调用所有注册的BeanFactoryPostProcessor的Bean  
               invokeBeanFactoryPostProcessors(beanFactory);  
               //为BeanFactory注册BeanPost事件处理器.  
               //BeanPostProcessor是Bean后置处理器，用于监听容器触发的事件  
               registerBeanPostProcessors(beanFactory);  
               //初始化信息源，和国际化相关.  
               initMessageSource();  
               //初始化容器事件传播器.  
               initApplicationEventMulticaster();  
               //调用子类的某些特殊Bean初始化方法  
               onRefresh();  
               //为事件传播器注册事件监听器.  
               registerListeners();  
               //初始化所有剩余的单态Bean.  
               finishBeanFactoryInitialization(beanFactory);  
               //初始化容器的生命周期事件处理器，并发布容器的生命周期事件  
               finishRefresh();  
           }  
           catch (BeansException ex) {  
               //销毁以创建的单态Bean  
               destroyBeans();  
               //取消refresh操作，重置容器的同步标识.  
               cancelRefresh(ex);  
               throw ex;  
           }  
       }  
   }
  //其他忽略
}
```

## 初始化 refresh 的上下文环境

```java
protected void prepareRefresh() {
  // 设置spring容器启动时间
  this.startupDate = System.currentTimeMillis();
  this.closed.set(false);
  this.active.set(true);
  // 初始化属性源，默认什么都不做。具体可由子类覆盖实现
  initPropertySources();
  // 验证 必要参数 是否完整。
  getEnvironment().validateRequiredProperties();

  // 添加某些监听器到 applicationListeners 变量中
  if (this.earlyApplicationListeners == null) {
    this.earlyApplicationListeners = new LinkedHashSet<>(this.applicationListeners);
  }
  else {
    this.applicationListeners.clear();
    this.applicationListeners.addAll(this.earlyApplicationListeners);
  }

  // Allow for the collection of early ApplicationEvents,
  // to be published once the multicaster is available...
  this.earlyApplicationEvents = new LinkedHashSet<>();
}
```

添加的监听器样例如下:

```
0 = {ConditionEvaluationReportLoggingListener$ConditionEvaluationReportListener@3109} 
1 = {ServerPortInfoApplicationContextInitializer@3110} 
2 = {BootstrapApplicationListener@3111} 
3 = {LoggingSystemShutdownListener@3112} 
4 = {ConfigFileApplicationListener@3113} 
5 = {AnsiOutputApplicationListener@3114} 
6 = {LoggingApplicationListener@3115} 
7 = {BackgroundPreinitializer@3116} 
8 = {ClasspathLoggingApplicationListener@3117} 
9 = {RestartListener@3118} 
10 = {DelegatingApplicationListener@3119} 
11 = {ParentContextCloserApplicationListener@3120} 
12 = {ClearCachesApplicationListener@3121} 
13 = {FileEncodingApplicationListener@3122} 
14 = {LiquibaseServiceLocatorApplicationListener@3123} 
15 = {EnableEncryptablePropertiesBeanFactoryPostProcessor@3124} 
```

## 初始化 BeanFactory

```java
protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
  refreshBeanFactory();
  // 直接返回 this.beanFactory
  return getBeanFactory();
}
```

```java
@Override
protected final void refreshBeanFactory() throws IllegalStateException {
  if (!this.refreshed.compareAndSet(false, true)) {
    throw new IllegalStateException(
      "GenericApplicationContext does not support multiple refresh attempts: just call 'refresh' once");
  }
  this.beanFactory.setSerializationId(getId());
}
```

## 对 BeanFactory 进行功能增强

```java
protected void prepareBeanFactory(ConfigurableListableBeanFactory beanFactory) {
		//设置用于加载bean的BeanClassLoader
		beanFactory.setBeanClassLoader(getClassLoader());
    //设置表达式解析器(解析bean定义中的一些EL表达式)
		beanFactory.setBeanExpressionResolver(new StandardBeanExpressionResolver(beanFactory.getBeanClassLoader()));
    //添加属性编辑注册器
		beanFactory.addPropertyEditorRegistrar(new ResourceEditorRegistrar(this, getEnvironment()));
		//添加添加后置处理器 ApplicationContextAwareProcessor(该类与XXAware接口配合)
    //由于ApplicationContextAwareProcessor实现了下面几个接口的字段属性的自动注入，
    //因此需要忽略下面这些接口的自动注入
		beanFactory.addBeanPostProcessor(new ApplicationContextAwareProcessor(this));
		beanFactory.ignoreDependencyInterface(EnvironmentAware.class);
		beanFactory.ignoreDependencyInterface(EmbeddedValueResolverAware.class);
		beanFactory.ignoreDependencyInterface(ResourceLoaderAware.class);
		beanFactory.ignoreDependencyInterface(ApplicationEventPublisherAware.class);
		beanFactory.ignoreDependencyInterface(MessageSourceAware.class);
		beanFactory.ignoreDependencyInterface(ApplicationContextAware.class);

		//注册几个自动装配的规则
		beanFactory.registerResolvableDependency(BeanFactory.class, beanFactory);
		beanFactory.registerResolvableDependency(ResourceLoader.class, this);
		beanFactory.registerResolvableDependency(ApplicationEventPublisher.class, this);
		beanFactory.registerResolvableDependency(ApplicationContext.class, this);

		//注册后置处理器 ApplicationListenerDetector，用于探测 ApplicationListener 类型接口
		beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(this));

		// 增加对 AspectJ 的支持
		if (beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
			beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
			beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
		}

		// 注册默认系统环境相关的bean(environment、systemProperties、systemEnvironment)
		if (!beanFactory.containsLocalBean(ENVIRONMENT_BEAN_NAME)) {
			beanFactory.registerSingleton(ENVIRONMENT_BEAN_NAME, getEnvironment());
		}
		if (!beanFactory.containsLocalBean(SYSTEM_PROPERTIES_BEAN_NAME)) {
			beanFactory.registerSingleton(SYSTEM_PROPERTIES_BEAN_NAME, getEnvironment().getSystemProperties());
		}
		if (!beanFactory.containsLocalBean(SYSTEM_ENVIRONMENT_BEAN_NAME)) {
			beanFactory.registerSingleton(SYSTEM_ENVIRONMENT_BEAN_NAME, getEnvironment().getSystemEnvironment());
		}
	}
```

在配置 bean 的时候，如果我们希望对某一类型的属性执行一些处理，可以通过自定义属性编辑器来实现，典型的应用场景就是对时间类型属性的转换，假设我们的 bean 存在 LocalDate 类型的属性，这个时候我们直接以字符串配置进行注入是会出现异常的，这个时候我们可以自定义属性编辑器来实现类型的转换：

```java
public class MyDatePropertyEditor extends PropertyEditorSupport implements InitializingBean {
    private String format = "yyyy-MM-dd";
    private DateTimeFormatter dtf;
    @Override
    public void afterPropertiesSet() throws Exception {
        dtf = DateTimeFormatter.ofPattern(format);
    }
    @Override
    public void setAsText(String text) throws IllegalArgumentException {
        if (!StringUtils.hasText(text)) {
            this.setValue(null);
            return;
        }
        this.setValue(LocalDate.parse(text));
    }
    public MyDatePropertyEditor setFormat(String format) {
        this.format = format;
        return this;
    }
}
```

```xml
<!--注册自定义属性解析器-->
<bean class="org.springframework.beans.factory.config.CustomEditorConfigurer">
    <property name="customEditors">
        <map>
            <entry key="java.time.LocalDate">
                <bean class="org.zhenchao.editor.MyDatePropertyEditor">
                    <property name="format" value="yyyy-MM-dd"/>
                </bean>
            </entry>
        </map>
    </property>
</bean>
```

我们自定义的属性编辑器 MyDatePropertyEditor 通过时间格式化工具对指定模式的字符串格式日期执行转换和注入，而上述转换只能在我们以 ApplicationContext 的方式加载 bean 的前提下才生效，如果我们以 BeanFactory 的方式加载 bean，还是会抛出异常，毕竟这属于高级容器中增强的功能。



当我们定义的 bean 实现了 Aware 接口的时候，这些 bean 可以比一般的 bean 多拿到一些资源，而此处对于 beanFactory 的扩展也增加了对一些 Aware 类自动装配的支持。ApplicationContextAwareProcessor 实现了 BeanPostProcessor 接口，并主要实现了 postProcessBeforeInitialization 逻辑：

```java
public Object postProcessBeforeInitialization(final Object bean, String beanName) throws BeansException {
    AccessControlContext acc = null;
    if (System.getSecurityManager() != null &&
            (bean instanceof EnvironmentAware 
                || bean instanceof EmbeddedValueResolverAware 
                || bean instanceof ResourceLoaderAware 
                || bean instanceof ApplicationEventPublisherAware 
                || bean instanceof MessageSourceAware 
                || bean instanceof ApplicationContextAware)) {
        acc = this.applicationContext.getBeanFactory().getAccessControlContext();
    }
    if (acc != null) {
        AccessController.doPrivileged(new PrivilegedAction<Object>() {
            @Override
            public Object run() {
                invokeAwareInterfaces(bean);
                return null;
            }
        }, acc);
    } else {
        // 核心在于激活 Aware
        this.invokeAwareInterfaces(bean);
    }
    return bean;
}
```

上述方法的核心在于 invokeAwareInterfaces 方法：

```java
private void invokeAwareInterfaces(Object bean) {
  if (bean instanceof Aware) {
    if (bean instanceof EnvironmentAware) {
      ((EnvironmentAware) bean).setEnvironment(this.applicationContext.getEnvironment());
    }
    if (bean instanceof EmbeddedValueResolverAware) {
      ((EmbeddedValueResolverAware) bean).setEmbeddedValueResolver(this.embeddedValueResolver);
    }
    if (bean instanceof ResourceLoaderAware) {
      ((ResourceLoaderAware) bean).setResourceLoader(this.applicationContext);
    }
    if (bean instanceof ApplicationEventPublisherAware) {
      ((ApplicationEventPublisherAware) bean).setApplicationEventPublisher(this.applicationContext);
    }
    if (bean instanceof MessageSourceAware) {
      ((MessageSourceAware) bean).setMessageSource(this.applicationContext);
    }
    if (bean instanceof ApplicationContextAware) {
      ((ApplicationContextAware) bean).setApplicationContext(this.applicationContext);
    }
  }
}
```

整个方法的逻辑很直观，判断当前类所实现的 Aware 接口，然后将相应的资源给到该 bean



在 4.3.x 版本中增加了对实现了 ApplicationListener 接口的探测，ApplicationListenerDetector 实现了 MergedBeanDefinitionPostProcessor 和 DestructionAwareBeanPostProcessor 后置处理接口，并相应实现了这些后置处理器定义的模板方法，其中核心的方法 postProcessAfterInitialization 逻辑如下：

```java
public Object postProcessAfterInitialization(Object bean, String beanName) {
  if (this.applicationContext != null && bean instanceof ApplicationListener) {
    // 实现了 ApplicationListener 接口
    Boolean flag = this.singletonNames.get(beanName);
    if (Boolean.TRUE.equals(flag)) { // 单例
      this.applicationContext.addApplicationListener((ApplicationListener<?>) bean);
    } else if (Boolean.FALSE.equals(flag)) { // 非单例
      if (logger.isWarnEnabled() && !this.applicationContext.containsBean(beanName)) {
        // inner bean with other scope - can't reliably process events
        logger.warn("Inner bean '" + beanName + "' implements ApplicationListener interface but is not reachable for event multicasting by its containing ApplicationContext " +
                    "because it does not have singleton scope. Only top-level listener beans are allowed to be of non-singleton scope.");
      }
      this.singletonNames.remove(beanName);
    }
  }
  return bean;
}
```

该方法针对实现了 ApplicationListener 接口的单例对象，统一注册到监听器集合中监听事件，而方法中的 singletonNames 变量则是在 postProcessMergedBeanDefinition 方法中进行构建：

```java
public void postProcessMergedBeanDefinition(RootBeanDefinition beanDefinition, Class<?> beanType, String beanName) {
    if (this.applicationContext != null) {
        this.singletonNames.put(beanName, beanDefinition.isSingleton());
    }
}
```

由此我们可以知道 singletonNames 中存放了 beanName，以及对应的 bean 是否是单例的关联关系。

## 后置处理器 BeanFactory

该方法的实现逻辑交由子类，用于增强 Spring 框架的可扩展性。

##调用已注册的 BeanFactoryPostProcessor 后置处理器

BeanFactoryPostProcessor 用于对 BeanFactory 实例进行后置处理，而 BeanPostProcessor 用于对 bean 实例进行后置处理。

```java
protected void invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    // invoke BeanFactoryPostProcessor 后置处理器,处理前面已经准备好的 BeanFactory 对象
    PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, this.getBeanFactoryPostProcessors());
    // AOP支持：LoadTimeWeaver
    if (beanFactory.getTempClassLoader() == null 
          && beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }
}
```

以下代码为 PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors()

```java
/*
* beanFactoryPostProcessors 保存了所有通过编码注册的 BeanFactoryPostProcessor
*/
public static void invokeBeanFactoryPostProcessors(
            ConfigurableListableBeanFactory beanFactory, 
            List<BeanFactoryPostProcessor> beanFactoryPostProcessors) {
  
    Set<String> processedBeans = new HashSet<String>();
    // 如果是 BeanDefinitionRegistry 注册器
    if (beanFactory instanceof BeanDefinitionRegistry) {
        BeanDefinitionRegistry registry = (BeanDefinitionRegistry) beanFactory;
        // 记录注册的 BeanFactoryPostProcessor 类型处理器
        List<BeanFactoryPostProcessor> regularPostProcessors = new LinkedList<BeanFactoryPostProcessor>(); 
        // 记录注册的 BeanDefinitionRegistryPostProcessor 注册器后置处理器
        List<BeanDefinitionRegistryPostProcessor> registryPostProcessors =  new LinkedList<BeanDefinitionRegistryPostProcessor>(); 
        // 一、遍历处理编码注册的 BeanFactoryPostProcessor
        for (BeanFactoryPostProcessor postProcessor : beanFactoryPostProcessors) {
            if (postProcessor instanceof BeanDefinitionRegistryPostProcessor) {
                /*
                 * 如果是 BeanDefinitionRegistryPostProcessor 注册器后置处理器（继承自 BeanFactoryPostProcessor）
                 * 1. 执行 BeanDefinitionRegistryPostProcessor 中扩展的方法 postProcessBeanDefinitionRegistry
                 * 2. 记录到 registryPostProcessors 集合中，用于后面处理继承自 BeanFactoryPostProcessor 的方法
                 */
                BeanDefinitionRegistryPostProcessor registryPostProcessor = (BeanDefinitionRegistryPostProcessor) postProcessor;
                registryPostProcessor.postProcessBeanDefinitionRegistry(registry);
                registryPostProcessors.add(registryPostProcessor);
            } else {
                // 否则就是 BeanFactoryPostProcessor
                regularPostProcessors.add(postProcessor);
            }
        }

        // 二、获取配置的 BeanDefinitionRegistryPostProcessor 注册器后置处理器
        String[] postProcessorNames =
                beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
        /* 1.invoke 所有实现了 PriorityOrdered 接口的 BeanDefinitionRegistryPostProcessor */
        List<BeanDefinitionRegistryPostProcessor> priorityOrderedPostProcessors = new ArrayList<BeanDefinitionRegistryPostProcessor>();
        for (String ppName : postProcessorNames) {
            if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
                priorityOrderedPostProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                processedBeans.add(ppName);
            }
        }
        sortPostProcessors(beanFactory, priorityOrderedPostProcessors);
        registryPostProcessors.addAll(priorityOrderedPostProcessors);
        invokeBeanDefinitionRegistryPostProcessors(priorityOrderedPostProcessors, registry);

        // 为啥要重新获取一次？？
        postProcessorNames = 
                beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
        /* 2. invoke 所有实现了 Ordered 接口的 BeanDefinitionRegistryPostProcessor */
        List<BeanDefinitionRegistryPostProcessor> orderedPostProcessors = new ArrayList<BeanDefinitionRegistryPostProcessor>();
        for (String ppName : postProcessorNames) {
            if (!processedBeans.contains(ppName) && beanFactory.isTypeMatch(ppName, Ordered.class)) {
                orderedPostProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                processedBeans.add(ppName);
            }
        }
        sortPostProcessors(beanFactory, orderedPostProcessors);
        registryPostProcessors.addAll(orderedPostProcessors);
        invokeBeanDefinitionRegistryPostProcessors(orderedPostProcessors, registry);

        /* 3.激活剩余的 BeanDefinitionRegistryPostProcessor */
        boolean reiterate = true;  
        while (reiterate) {
            reiterate = false;
            postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
            for (String ppName : postProcessorNames) {
                if (!processedBeans.contains(ppName)) { // 没有处理过的
                    BeanDefinitionRegistryPostProcessor pp = beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class);
                    registryPostProcessors.add(pp);
                    processedBeans.add(ppName);
                    // 执行 BeanDefinitionRegistryPostProcessor 中扩展的方法
                    pp.postProcessBeanDefinitionRegistry(registry);
                    reiterate = true;
                }
            }
        }

        // 激活所有 BeanDefinitionRegistryPostProcessor 后置处理器中的 postProcessBeanFactory 方法
        invokeBeanFactoryPostProcessors(registryPostProcessors, beanFactory);
        // 激活所有 BeanFactoryPostProcessor 后置处理器中的 postProcessBeanFactory 方法
        invokeBeanFactoryPostProcessors(regularPostProcessors, beanFactory);
    } else {
        // 如果不是 BeanDefinitionRegistry 类型，直接激活所有编码注册的 BeanFactoryPostProcessor 后置处理器
        invokeBeanFactoryPostProcessors(beanFactoryPostProcessors, beanFactory);
    }

    // 获取配置的 BeanFactoryPostProcessor 类型后置处理器
    String[] postProcessorNames =
            beanFactory.getBeanNamesForType(BeanFactoryPostProcessor.class, true, false);

    List<BeanFactoryPostProcessor> priorityOrderedPostProcessors = new ArrayList<BeanFactoryPostProcessor>();
    List<String> orderedPostProcessorNames = new ArrayList<String>();
    List<String> nonOrderedPostProcessorNames = new ArrayList<String>();
    for (String ppName : postProcessorNames) {
        if (processedBeans.contains(ppName)) {
            // 跳过已经处理过的 bean
        } else if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
            // 实现了 PriorityOrdered 接口
            priorityOrderedPostProcessors.add(beanFactory.getBean(ppName, BeanFactoryPostProcessor.class));
        } else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
            // 实现了 Ordered 接口
            orderedPostProcessorNames.add(ppName);
        } else {
            // 其它
            nonOrderedPostProcessorNames.add(ppName);
        }
    }

    /* 1.激活所有实现了 PriorityOrdered 接口的 BeanFactoryPostProcessor */
    sortPostProcessors(beanFactory, priorityOrderedPostProcessors);
    invokeBeanFactoryPostProcessors(priorityOrderedPostProcessors, beanFactory);

    /* 2.激活所有实现了 Ordered 接口的 BeanFactoryPostProcessor */
    List<BeanFactoryPostProcessor> orderedPostProcessors = new ArrayList<BeanFactoryPostProcessor>();
    for (String postProcessorName : orderedPostProcessorNames) {
        orderedPostProcessors.add(beanFactory.getBean(postProcessorName, BeanFactoryPostProcessor.class));
    }
    sortPostProcessors(beanFactory, orderedPostProcessors);
    invokeBeanFactoryPostProcessors(orderedPostProcessors, beanFactory);

    /* 3.激活剩余的 BeanFactoryPostProcessor */
    List<BeanFactoryPostProcessor> nonOrderedPostProcessors = new ArrayList<BeanFactoryPostProcessor>();
    for (String postProcessorName : nonOrderedPostProcessorNames) {
        nonOrderedPostProcessors.add(beanFactory.getBean(postProcessorName, BeanFactoryPostProcessor.class));
    }
    invokeBeanFactoryPostProcessors(nonOrderedPostProcessors, beanFactory);

    // 清理工作
    beanFactory.clearMetadataCache();
}
```

我们可以看到针对编码注册和以配置方式注册的 BeanFactoryPostProcessor，Spring 的获取方式是不一样的，前者都是注册到之前提到的 beanFactoryPostProcessors 集合中，而后者都是通过 BeanFactory 的 getBeanNamesForType 方法获取到的。

上述方法先判断 BeanFactory 是不是 BeanDefinitionRegistry 类型，如果是的话则专门处理，这样设计是因为继承自 BeanFactoryPostProcessor 的 BeanDefinitionRegistryPostProcessor 需要专门处理这种类型：

```java
public interface BeanDefinitionRegistryPostProcessor extends BeanFactoryPostProcessor {

    void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException;

}
```

并且针对配置的 BeanFactoryPostProcessor 而言，因为获取顺序的不确定性，所以 Spring 支持对其配置优先级，上述方法的逻辑也可以看出 Spring 会依次处理 PriorityOrdered、Ordered，以及其他类型，并会针对各类型进行按照比较器进行排序处理。

##注册 BeanPostProcessor 后置处理器

不同于 BeanFactoryPostProcessor 的调用，这里仅仅是对 BeanPostProcessor 的注册，因为 BeanPostProcessor 作用于 bean 实例之上，而当前还没有开始创建 bean 实例。之前讲解 getBean 过程的文章中我们应该有所记忆，BeanPostProcessor 的调用是发生在 getBean 过程中，具体来说应该是围绕 bean 实例化过程的前后。如下为 BeanPostProcessor 接口源码

```java
public interface BeanPostProcessor {

    Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException;

    Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException;

}
```

注册过程本质上是将配置的 BeanPostProcessor 添加到 beanPostProcessors 集合的过程，我们在简单容器中需要通过调用 addBeanPostProcessor 编码注册我们实现的 BeanPostProcessor，实际上两者本质上是一样的，只是高级容器支持以配置的方式来完成简单容器中需要编码才能完成的操作：

```java
// PostProcessorRegistrationDelegate 
public static void registerBeanPostProcessors(
        ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {

    // 获取配置的 BeanPostProcessor 类型
    String[] postProcessorNames = beanFactory.getBeanNamesForType(BeanPostProcessor.class, true, false);

    // 注册一个 BeanPostProcessorChecker，用于`还没有注册后置处理器就开始实例化bean的情况`打印日志记录
    int beanProcessorTargetCount = beanFactory.getBeanPostProcessorCount() + 1 + postProcessorNames.length;
    beanFactory.addBeanPostProcessor(new BeanPostProcessorChecker(beanFactory, beanProcessorTargetCount));

    List<BeanPostProcessor> priorityOrderedPostProcessors = new ArrayList<BeanPostProcessor>(); // 存放实现了 PriorityOrdered 接口的 BeanPostProcessor
    List<BeanPostProcessor> internalPostProcessors = new ArrayList<BeanPostProcessor>(); // 存放 MergedBeanDefinitionPostProcessor
    List<String> orderedPostProcessorNames = new ArrayList<String>(); // 存放实现了 Ordered 接口的 BeanPostProcessor
    List<String> nonOrderedPostProcessorNames = new ArrayList<String>(); // 存放其它的 BeanPostProcessor

    // 遍历分类
    for (String ppName : postProcessorNames) {
        if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
            BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
            priorityOrderedPostProcessors.add(pp);
            if (pp instanceof MergedBeanDefinitionPostProcessor) {
                internalPostProcessors.add(pp);
            }
        } else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
            orderedPostProcessorNames.add(ppName);
        } else {
            nonOrderedPostProcessorNames.add(ppName);
        }
    }

    // 1.排序并注册实现了 PriorityOrdered 接口的 BeanPostProcessor，不包含 MergedBeanDefinitionPostProcessor
    sortPostProcessors(beanFactory, priorityOrderedPostProcessors);
    registerBeanPostProcessors(beanFactory, priorityOrderedPostProcessors);

    // 2.排序并注册实现了 Ordered 接口的 BeanPostProcessor
    List<BeanPostProcessor> orderedPostProcessors = new ArrayList<BeanPostProcessor>();
    for (String ppName : orderedPostProcessorNames) {
        BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
        orderedPostProcessors.add(pp);
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    sortPostProcessors(beanFactory, orderedPostProcessors);
    registerBeanPostProcessors(beanFactory, orderedPostProcessors);

    // 3.注册其余的除 MergedBeanDefinitionPostProcessor 类型的 BeanPostProcessor
    List<BeanPostProcessor> nonOrderedPostProcessors = new ArrayList<BeanPostProcessor>();
    for (String ppName : nonOrderedPostProcessorNames) {
        BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
        nonOrderedPostProcessors.add(pp);
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    registerBeanPostProcessors(beanFactory, nonOrderedPostProcessors);

    // 4.排序并注册所有的 MergedBeanDefinitionPostProcessor
    sortPostProcessors(beanFactory, internalPostProcessors);
    registerBeanPostProcessors(beanFactory, internalPostProcessors);

    // 重新注册 ApplicationListenerDetector，将其移到链尾
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(applicationContext));
}
```

BeanPostProcessor 与 BeanFactoryPostProcessor 一样，同样支持优先级的配置。

##初始化国际化资源

笔者目前所负责的几个项目都需要考虑国际化支持，有的直接基于 jdk 原生的 ResourceBundle，有的则基于 Spring 提供的 MessageSource，在具体分析 MessageSource 的初始化过程之前，我们先来了解一下 Spring 国际化支持的设计与简单使用。

### MessageSource 的设计与简单使用

Spring MessageSource 支持本质上也是对 ResourceBundle 的封装，MessageSource 接口的定义如下：

```java
public interface MessageSource {

    /**
     * 获取指定语言的文案信息
     * code 为属性名称，args 用于传递格式化参数，defaultMessage 表示在找不到指定属性时返回的默认信息，locale 表示本地化对象
     */
    String getMessage(String code, Object[] args, String defaultMessage, Locale locale);

    /**
     * 获取指定语言的文案信息
     * 相对于第一个方法的区别在于当找不到对应属性时直接抛出异常
     */
    String getMessage(String code, Object[] args, Locale locale) throws NoSuchMessageException;

    /**
     * 获取指定语言的文案信息
     * 只不过采用 MessageSourceResolvable 来封装第一个方法中的前三个参数
     */
    String getMessage(MessageSourceResolvable resolvable, Locale locale) throws NoSuchMessageException;

}
```

Spring MessageSource 相关类的继承关系如下：

![spring-message-source](/images/spring-3-应用上下文的refresh/11102521_5Jz2.png)

其中 HierarchicalMessageSource 的设计为 MessageSource 提供了层次支持，建立了父子层级结构。
ResourceBundleMessageSource 和 ReloadableResourceBundleMessageSource 是我们常用的两个类，均可以看做是对 jdk 原生国际化支持的封装，只不过后者相对于前者提供了定时更新资源文件的支持，从而不需要重启系统。
StaticMessageSource 为编码式资源注册提供了支持，
DelegatingMessageSource 则可以看做是 MessageSource 的一个代理，必要时对 MessageSource 进行封装。

下面我们演示一下 MessageSource 的简单使用，首先我们定义好国际化资源 resource.properties：

resource.properties

> spring=Spring framework is a good design, the latest version is {0}

resource_zh.properties

> spring=Spring 框架設計精良，當前最新版本是 {0}

resource_zh_CN.properties

> spring=Spring 框架设计精良，当前最新版本是 {0}

需要注意的是，如果资源文件包含了非 ASCII 字符，则需要将文本内容转换成 Unicode 编码，jdk 自带的 native2ascii 工具可以达到目的，操作如下：

> native2ascii -encoding utf-8 resource_zh.properties resource_zh_tmp.properties

然后我们在配置文件中进行如下配置：

```xml
<!--推荐以 messageResource 作为 id-->
<bean id="messageResource" class="org.springframework.context.support.ResourceBundleMessageSource">
    <property name="basenames">
        <list>
            <value>i18n/resource</value>
        </list>
    </property>
</bean>
```

调用方式如下：

```java
ApplicationContext context = new ClassPathXmlApplicationContext("spring-core.xml");
Object[] params = {"4.3.8.RELEASE"};
System.out.println(context.getMessage("spring", params, Locale.ENGLISH));
System.out.println(context.getMessage("spring", params, Locale.TRADITIONAL_CHINESE));
System.out.println(context.getMessage("spring", params, Locale.SIMPLIFIED_CHINESE));
```

因为 ApplicationContext 同样实现了 MessageSource 接口，所以可以直接调用，但是这样调用的前提是配置中的 id 必须设置为 messageResource。输出如下：

```
Spring framework is a good design, the latest version is 4.3.8.RELEASE
Spring 框架設計精良，當前最新版本是 4.3.8.RELEASE
Spring 框架设计精良，当前最新版本是 4.3.8.RELEASE
```

###MessageSource 的初始化过程

```java
protected void initMessageSource() {
    ConfigurableListableBeanFactory beanFactory = this.getBeanFactory();
    if (beanFactory.containsLocalBean(MESSAGE_SOURCE_BEAN_NAME)) {
        /*如果存在名称为 messageSource 的 bean*/
        // 初始化资源
        this.messageSource = beanFactory.getBean(MESSAGE_SOURCE_BEAN_NAME, MessageSource.class);
        // 构造层次关系
        if (this.parent != null && this.messageSource instanceof HierarchicalMessageSource) {
            HierarchicalMessageSource hms = (HierarchicalMessageSource) this.messageSource;
            if (hms.getParentMessageSource() == null) {
                hms.setParentMessageSource(this.getInternalParentMessageSource());
            }
        }
    } else {
        /*不存在名称为 messageSource 的 bean*/
        // 创建一个 DelegatingMessageSource 对象
        DelegatingMessageSource dms = new DelegatingMessageSource();
        dms.setParentMessageSource(this.getInternalParentMessageSource());
        this.messageSource = dms;
        // 以 messageSource 进行注册
        beanFactory.registerSingleton(MESSAGE_SOURCE_BEAN_NAME, this.messageSource);
    }
}
```

前面我们在配置时推荐将 id 配置为 messageSource 是有原因的，通过阅读源码一目了然，代码中硬编码要求我们的配置 messageSource 作为 bean 的名称，否则不执行初始化，而是创建一个默认的代理，如果我们利用 ApplicationContext 对象去获取对应的资源则会出现异常，否则我们就需要手动指定 getBean 时候的名称，但是这样做是不推荐的，既然框架以约定的方式提供了相应的实现，还是推荐以 messageSource 作为 id 进行配置。

##初始化事件广播器

事件广播和监听机制是典型的观察者模式的实现，而 ApplicationEventMulticaster 也是观察者模式中主题角色的典型实现。
在 Spring 中，如果我们希望监听事件广播器广播的事件，则需要定义一个实现了 ApplicationListener 接口的监听器，Spring 支持监听器的编码注册和自动扫描注册，这个我们在后面小节中细说，我们先来看一下这里广播器的初始化过程：

```java
protected void initApplicationEventMulticaster() {
    ConfigurableListableBeanFactory beanFactory = this.getBeanFactory();
    if (beanFactory.containsLocalBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME)) {
        this.applicationEventMulticaster = beanFactory.getBean(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, ApplicationEventMulticaster.class);
        }
    } else {
        // 创建并注册一个 SimpleApplicationEventMulticaster
        this.applicationEventMulticaster = new SimpleApplicationEventMulticaster(beanFactory);
        beanFactory.registerSingleton(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, this.applicationEventMulticaster);
    }
}
```

逻辑很清晰，如果我们以约定的方式配置了自己的事件广播器，则初始化该广播器实例，
否则容器会创建并注册一个默认的 SimpleApplicationEventMulticaster，进入该广播器的实现我们会发现如下逻辑：

```java
public void multicastEvent(final ApplicationEvent event, ResolvableType eventType) {
    ResolvableType type = (eventType != null ? eventType : resolveDefaultEventType(event));
    for (final ApplicationListener<?> listener : this.getApplicationListeners(event, type)) {
        Executor executor = this.getTaskExecutor();
        if (executor != null) {
            executor.execute(new Runnable() {
                @Override
                public void run() {
                    invokeListener(listener, event);
                }
            });
        } else {
            // 回调各个监听器
            this.invokeListener(listener, event);
        }
    }
}
protected void invokeListener(ApplicationListener listener, ApplicationEvent event) {
    ErrorHandler errorHandler = this.getErrorHandler();
    if (errorHandler != null) {
        try {
            // 回调监听的监听方法 onApplicationEvent
            listener.onApplicationEvent(event);
        } catch (Throwable err) {
            errorHandler.handleError(err);
        }
    } else {
        try {
            // 回调监听的监听方法 onApplicationEvent
            listener.onApplicationEvent(event);
        } catch (ClassCastException ex) {
            String msg = ex.getMessage();
            if (msg == null || msg.startsWith(event.getClass().getName())) {
                // Possibly a lambda-defined listener which we could not resolve the generic event type for
                Log logger = LogFactory.getLog(getClass());
                if (logger.isDebugEnabled()) {
                    logger.debug("Non-matching event type for listener: " + listener, ex);
                }
            } else {
                throw ex;
            }
        }
    }
}
```

典型的回调观察者监听方法的逻辑，如果对于观察者模式了解的话，这里的逻辑会比较好理解。

## 初始化其他特定的bean

提供一个模版方法 onRefresh()，子类可以实现该方法，用于初始化某些特定的bean。 

##注册事件监听器

既然有被观察者，就应该有观察者，事件监听器就是我们的观察者，我们需要将其注册来监听事件消息，针对事件监听器的注册，我们可以以编码的方式进行注册，如果我们将其配置到配置文件中，容器也会自动扫描进行注册：

```java
protected void registerListeners() {
    // 1.注册所有的编码添加的事件监听器
    for (ApplicationListener<?> listener : this.getApplicationListeners()) {
        this.getApplicationEventMulticaster().addApplicationListener(listener);
    }

    // 2. 扫描注册以配置方式添加的事件监听器（延迟加载）
    String[] listenerBeanNames = this.getBeanNamesForType(ApplicationListener.class, true, false);
    for (String listenerBeanName : listenerBeanNames) {
        this.getApplicationEventMulticaster().addApplicationListenerBean(listenerBeanName);
    }

    // 3. 发布需要提前广播的事件
    Set<ApplicationEvent> earlyEventsToProcess = this.earlyApplicationEvents;
    this.earlyApplicationEvents = null;
    if (earlyEventsToProcess != null) {
        for (ApplicationEvent earlyEvent : earlyEventsToProcess) {
            // 通知事件
            this.getApplicationEventMulticaster().multicastEvent(earlyEvent);
        }
    }
}
```

##实例化所有非延迟加载的单例

记得最开始学习 Spring 框架的时候，就看到说 BeanFactory 和 ApplicationContext 有一个很大的区别就是 BeanFactory 在初始化容器时不会实例化 bean，而 ApplicationContext 则会实例化所有非延迟加载的单例 bean，而这个加载过程就在这里发生。

```java
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
    // 如果存在类型转换器，则进行加载
    if (beanFactory.containsBean(CONVERSION_SERVICE_BEAN_NAME)
            && beanFactory.isTypeMatch(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class)) {
        beanFactory.setConversionService(beanFactory.getBean(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class));
    }

    // 如果不存在 embedded value resolver 则设置一个默认的
    if (!beanFactory.hasEmbeddedValueResolver()) {
        beanFactory.addEmbeddedValueResolver(new StringValueResolver() {
            @Override
            public String resolveStringValue(String strVal) {
                return getEnvironment().resolvePlaceholders(strVal);
            }
        });
    }

    // AOP支持，实例化 LoadTimeWeaverAware
    String[] weaverAwareNames = beanFactory.getBeanNamesForType(LoadTimeWeaverAware.class, false, false);
    for (String weaverAwareName : weaverAwareNames) {
        this.getBean(weaverAwareName);
    }

    beanFactory.setTempClassLoader(null);

    // 冻结所有 bean 的定义，不再允许更改
    beanFactory.freezeConfiguration();

    // 实例化所有的非延迟加载的bean（非abstract && 单例 && 非延迟加载）
    beanFactory.preInstantiateSingletons();
}
```

由上述逻辑可以看到在执行实例化操作之前，容器会先校验一些必要的工具实例，如果之前没有注册则会创建一个默认的代替，然后会冻结所有的 bean 定义，毕竟即将开始实例化，后续的更改也不会再生效。在一些准备工作完毕之后，容器即开始实例化所有满足条件（非abstract && 单例 && 非延迟加载）的 bean。

Spring 4.1 增加了 SmartInitializingSingleton，实现了该接口的单例可以感知所有单例实例化完成的事件，而接口中声明的方法 afterSingletonsInstantiated 也在这里被回调：

```java
public void preInstantiateSingletons() throws BeansException {
    // 遍历实例化满足条件的 bean
    List<String> beanNames = new ArrayList<String>(this.beanDefinitionNames);
    for (String beanName : beanNames) {
        RootBeanDefinition bd = this.getMergedLocalBeanDefinition(beanName);
        // 不是abstract && 单例 && 不是延迟加载的
        if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
            if (this.isFactoryBean(beanName)) {
                // 工厂bean
                final FactoryBean<?> factory = (FactoryBean<?>) getBean(FACTORY_BEAN_PREFIX + beanName);
                boolean isEagerInit;
                if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {
                    isEagerInit = AccessController.doPrivileged(new PrivilegedAction<Boolean>() {
                        @Override
                        public Boolean run() {
                            return ((SmartFactoryBean<?>) factory).isEagerInit();
                        }
                    }, getAccessControlContext());
                } else {
                    isEagerInit = (factory instanceof SmartFactoryBean && ((SmartFactoryBean<?>) factory).isEagerInit());
                }
                if (isEagerInit) {
                    this.getBean(beanName);
                }
            } else {
                // 普通单例
                this.getBean(beanName);
            }
        }
    }

    // 4.1版本新特性 SmartInitializingSingleton
    for (String beanName : beanNames) {
        Object singletonInstance = this.getSingleton(beanName);
        // SmartInitializingSingleton 类型
        if (singletonInstance instanceof SmartInitializingSingleton) {
            final SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;
            if (System.getSecurityManager() != null) {
                AccessController.doPrivileged(new PrivilegedAction<Object>() {
                    @Override
                    public Object run() {
                        smartSingleton.afterSingletonsInstantiated();
                        return null;
                    }
                }, getAccessControlContext());
            } else {
                smartSingleton.afterSingletonsInstantiated();
            }
        }
    }
}
```

##完成刷新过程，发布应用事件

Spring 很早就提供了 Lifecycle 接口，实现了该接口的 bean 可以感知到容器的启动和关闭状态，对应着接口的 start 和 stop 方法，而 start 方法的回调则位于这个时候发生：

```java
protected void finishRefresh() {
    // 初始化 LifecycleProcessor
    this.initLifecycleProcessor();

    // 调用所有实现了 Lifecycle 的 start 方法
    this.getLifecycleProcessor().onRefresh();

    // 发布上下文刷新完毕事件
    this.publishEvent(new ContextRefreshedEvent(this));

    // 注册到 LiveBeansView MBean
    LiveBeansView.registerApplicationContext(this);
}
```

Lifecycle 对应方法的执行需要依赖于 LifecycleProcessor，我们可以自定义 LifecycleProcessor，否则容器会创建一个默认的 DefaultLifecycleProcessor，然后基于定义的 LifecycleProcessor 来调用满足条件 bean 的 start 方法。在完成了这一操作之后，容器的初始化过程基本上完成，这个时候容器可以将容器刷新完毕事件通知到对应的监听器。



## 来源

https://my.oschina.net/wangzhenchao/blog/918627