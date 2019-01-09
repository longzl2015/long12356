---

title: spring-7-SpringBean的销毁过程(转)

date: 2018-08-22 15:20:00

categories: [spring]

tags: [spring,bean]

---


##缘起
项目中需要用到kafka，公司的message queue sdk中已经封装了kafka的使用，在xml文件中进行配置就可以方便使用。但由于sdk的强依赖的问题，假如kafka链接失败会导致应用无法启动。所以就只能放弃sdk转为操作底层api操作kafka的启动监听以及关闭。

在使用的过程遇到了启动空指针以及关闭时TransactionManager已经被关闭的问题，同时Spring的初始化启动以及关闭过程是日常spring使用中最为关心的阶段，在前几篇文章介绍了Spring的初始化实现，那么结合前几篇文章以及对Spring关闭过程的解读来分析一下对于上述的场景遇到的问题可以怎么解决。

首先对Spring的Bean销毁过程的分析。

## Spring的关闭过程
spring通过AbstractApplicateContext的close方法执行容器的关闭处理，代码如下：

```java

public void close() {
    synchronized (this.startupShutdownMonitor) {
	    doClose();
		// If we registered a JVM shutdown hook, we don't need it anymore now:
		// We've already explicitly closed the context.
		if (this.shutdownHook != null) {
			try {
				Runtime.getRuntime().removeShutdownHook(this.shutdownHook);
			}catch (IllegalStateException ex) {
				// ignore - VM is already shutting down
			}
                   }
	}
}

protected void doClose() {
		if (this.active.get() && this.closed.compareAndSet(false, true)) {
			if (logger.isInfoEnabled()) {
				logger.info("Closing " + this);
			}

			LiveBeansView.unregisterApplicationContext(this);

			try {
				// Publish shutdown event.
				publishEvent(new ContextClosedEvent(this));
			}
			catch (Throwable ex) {
				logger.warn("Exception thrown from ApplicationListener handling ContextClosedEvent", ex);
			}

			// Stop all Lifecycle beans, to avoid delays during individual destruction.
			try {
				getLifecycleProcessor().onClose();
			}
			catch (Throwable ex) {
				logger.warn("Exception thrown from LifecycleProcessor on context close", ex);
			}

			// Destroy all cached singletons in the context's BeanFactory.
			destroyBeans();

			// Close the state of this context itself.
			closeBeanFactory();

			// Let subclasses do some final clean-up if they wish...
			onClose();

			this.active.set(false);
		}
	}

```

可以看到最终的关闭处理是通过调用doClose方法执行，在onClose方法中处理了以下事情：

1. 发布容器关闭事件ContextCloseEvent
2. 调用lifeCycleProcessor的onClose方法（在AbstractBeanFactory的refresh的最后一步，调用的是LifeCycleProcessor接口的onRefresh方法，两者互相对应）
3. 调用destroyBean方法
4. 调用closeBeanFactory方法。是一个抽象方法，用于让子类关闭factory，比如将BeanFactory设置为null
5. 调用onClose方法。这是一个空方法，目的是为了让子类在最后能够对关闭事件进行扩展

上述方法中destroyBean方法最为关键，bean的释放就是在这个方法中处理。

## destoryBean
destoryBean最终是委托DefaultListableBeanFactory的destroySingletons方法进行bean的关闭处理，我们来看一下代码：

```java

public void destroySingletons() {
	if (logger.isDebugEnabled()) {
		logger.debug("Destroying singletons in " + this);
	}
	synchronized (this.singletonObjects) {
		this.singletonsCurrentlyInDestruction = true;
	}

	String[] disposableBeanNames;
	synchronized (this.disposableBeans) {
        // 获取到所有需要进行关闭释放的bean。
		disposableBeanNames = StringUtils.toStringArray(this.disposableBeans.keySet());
	}
	for (int i = disposableBeanNames.length - 1; i >= 0; i--) {
		destroySingleton(disposableBeanNames[i]);
	}

	this.containedBeanMap.clear();
	this.dependentBeanMap.clear();
	this.dependenciesForBeanMap.clear();

	synchronized (this.singletonObjects) {
		this.singletonObjects.clear();
		this.singletonFactories.clear();
		this.earlySingletonObjects.clear();
		this.registeredSingletons.clear();
		this.singletonsCurrentlyInDestruction = false;
	}
}
```

在Spring装载上下文，解析bean配置的时候，就会生成对应的disposableBeans数据。一个具体的bean在创建完成后，会在AbstractAutowireCapableBeanFactory的registerDisposableBeanIfNecessary中判断当前bean是否需要放入到disposableBeans中。

目前以下三种情况的bean会被注册到disposableBeans中：

1. 实现了DisposableBean接口
2. 在xml配置文件中自定义了destroy方法
3. 实现了AutoCloseable接口。Mybatis的SqlSessionTemplate类就是实现了该接口，导致在spring容器关闭的时候，被反射调用了这个close方法。而SqlSessionTemplate类的生命周期是受Mybatis
管理的，不能手动执行close。这也就是很经典的一个异常： Invocation of destroy method 'close' failed on bean with name 'sqlSessionTemplate'
第二和第三种方式，Spring都通过一个DisposableBeanAdapter将具体的bean包装成为一个实现了DisposableBean接口的实现类，使得在最终销毁Bean释放资源时，统一对DisposableBean操作。

## Bean销毁的顺序
上面的代码逻辑中，会对取到的disposableBeans循环一个个调用destroyBean方法进行销毁与进行资源释放。那么是不是bean的销毁是有序的呢？能不能执行bean的销毁顺序呢？比如B要比A先释放？

可能这是一个很多人都会遇到的一个问题。Spring是不支持执行bean销毁的顺序，这个可以从Spring的一些官方讨论中得到：

> 假如你所销毁的资源有顺序关系的话，可以使用bean之间的依赖关系来实现这个目的，Spring在bean的销毁顺序上做了很多努力，但目前并不支持destroy的顺序配置。默认是先加载的bean后销毁，是一个反向操作。

所以你可以在destroyBean中看到一个关键逻辑，会先执行当前bean所依赖的bean的销毁操作。代码如下：

```java
    //...
    Set<String> dependencies = this.dependentBeanMap.remove(beanName);
	if (dependencies != null) {
		if (logger.isDebugEnabled()) {
			logger.debug("Retrieved dependent beans for bean '" + beanName + "': " + dependencies);
		}
		for (String dependentBeanName : dependencies) {
			destroySingleton(dependentBeanName);
		}
	}
    //...
```

对于bean之间的依赖配置，可以使用下面方式：

1. 在xml配置文件中通过视同depensOn的方式指定一个bean对另外一个bean的依赖
2. 一个bean中的属性也是当前bean所依赖的实例

上文就是Spring 销毁bean的一个大概的逻辑，后续会编写一个实践案例来贯穿Spring的初始化与关闭

## 来源

[Spring中Bean的关闭与资源释放](Spring中Bean的关闭与资源释放)