---

title: spring-3-bean的创建和初始化(转)

date: 2019-10-17 00:00:02

categories: [spring,spring-core]

tags: [spring,springframe,bean]

---

bean的创建和初始化(非 bean 配置的解析和注册)

<!--more-->

## 概览

Spring 提供了多种重载和覆盖的 getBean 方法，当我们在执行 beanFactory.getBean("myBean") 时，我们实际上是在调用 AbstractBeanFactory 中的实现：

```java
public Object getBean(String name) throws BeansException {
    return this.doGetBean(name, null, null, false);
}
```

按照 Spring 中方法的命名规则，以 “do” 开头的方法一般都是真正干事的地方，doGetBean 方法也不例外，其中包含了整个创建和获取 bean 的过程，在前面的文章中我们已经简单的浏览过该方法，这里我们再看一遍，并针对其中的逻辑进行展开：

```java
protected <T> T doGetBean(
            final String name, final Class<T> requiredType, final Object[] args, boolean typeCheckOnly) throws BeansException {
    /*
     * 获取name对应的真正beanName
     *
     * 因为传入的参数可以是alias，也可能是FactoryBean的name，所以需要进行解析，包含以下内容：
     * 1. 如果是FactoryBean，则去掉修饰符“&”
     * 2. 沿着引用链获取alias对应的最终name
     */
    final String beanName = this.transformedBeanName(name);

    Object bean;

    /*
     * 检查缓存或者实例工厂中是否有对应的单例
     *
     * 在创建单例bean的时候会存在依赖注入的情况，而在创建依赖的时候为了避免循环依赖
     * Spring创建bean的原则是不等bean创建完成就会将创建bean的ObjectFactory提前曝光（将对应的ObjectFactory加入到缓存）
     * 一旦下一个bean创建需要依赖上一个bean，则直接使用ObjectFactory对象
     */
    Object sharedInstance = this.getSingleton(beanName); // 获取单例
    if (sharedInstance != null && args == null) {
        // 实例已经存在，返回对应的实例
        bean = this.getObjectForBeanInstance(sharedInstance, name, beanName, null);
    } else {
        // 单例实例不存在
        if (this.isPrototypeCurrentlyInCreation(beanName)) {
            /*
             * 只有在单例模式下才会尝试解决循环依赖问题
             * 对于原型模式，如果存在循环依赖，也就是满足this.isPrototypeCurrentlyInCreation(beanName)，抛出异常
             */
            throw new BeanCurrentlyInCreationException(beanName);
        }

        // 获取parentBeanFactory实例
        BeanFactory parentBeanFactory = this.getParentBeanFactory();
        // 如果在beanDefinitionMap中（即所有已经加载的类中）不包含目标bean，则尝试从parentBeanFactory中获取
        if (parentBeanFactory != null && !this.containsBeanDefinition(beanName)) {
            String nameToLookup = this.originalBeanName(name);  // 获取name对应的真正beanName，如果是factoryBean，则加上“&”前缀
            if (args != null) {
                // 递归到BeanFactory中寻找
                return (T) parentBeanFactory.getBean(nameToLookup, args);
            } else {
                return parentBeanFactory.getBean(nameToLookup, requiredType);
            }
        }

        // 如果不仅仅是做类型检查，标记bean的状态已经创建，即将beanName加入alreadyCreated集合中
        if (!typeCheckOnly) {
            this.markBeanAsCreated(beanName);
        }

        try {
            /*
             * 将存储XML配置的GenericBeanDefinition实例转换成RootBeanDefinition实例，方便后续处理
             * 如果存在父bean，则同时合并父bean的相关属性
             */
            final RootBeanDefinition mbd = this.getMergedLocalBeanDefinition(beanName);
            // 检查bean是否是抽象的，如果是则抛出异常
            this.checkMergedBeanDefinition(mbd, beanName, args);

            // 加载当前bean依赖的bean
            String[] dependsOn = mbd.getDependsOn();
            if (dependsOn != null) {
                // 存在依赖，递归实例化依赖的bean
                for (String dep : dependsOn) {
                    if (this.isDependent(beanName, dep)) {
                        // 检查dep是否依赖beanName，从而导致循环依赖
                        throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
                    }
                    // 缓存依赖调用
                    this.registerDependentBean(dep, beanName);
                    this.getBean(dep);
                }
            }

            // 完成加载依赖的bean后，实例化mbd自身
            if (mbd.isSingleton()) {
                // scope == singleton
                sharedInstance = this.getSingleton(beanName, new ObjectFactory<Object>() {
                    @Override
                    public Object getObject() throws BeansException {
                        try {
                            return createBean(beanName, mbd, args);
                        } catch (BeansException ex) {
                            // 清理工作，从单例缓存中移除
                            destroySingleton(beanName);
                            throw ex;
                        }
                    }
                });
                bean = this.getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
            } else if (mbd.isPrototype()) {
                // scope == prototype
                Object prototypeInstance;
                try {
                    // 设置正在创建的状态
                    this.beforePrototypeCreation(beanName);
                    // 创建bean
                    prototypeInstance = this.createBean(beanName, mbd, args);
                } finally {
                    this.afterPrototypeCreation(beanName);
                }
                // 返回对应的实例
                bean = this.getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
            } else {
                // 其它scope
                String scopeName = mbd.getScope();
                final Scope scope = this.scopes.get(scopeName);
                if (scope == null) {
                    throw new IllegalStateException("No Scope registered for scope name '" + scopeName + "'");
                }
                try {
                    Object scopedInstance = scope.get(beanName, new ObjectFactory<Object>() {
                        @Override
                        public Object getObject() throws BeansException {
                            beforePrototypeCreation(beanName);
                            try {
                                return createBean(beanName, mbd, args);
                            } finally {
                                afterPrototypeCreation(beanName);
                            }
                        }
                    });
                    // 返回对应的实例
                    bean = this.getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
                } catch (IllegalStateException ex) {
                    throw new BeanCreationException(beanName, "Scope '" + scopeName + "' is not active for the current thread; consider defining a scoped proxy for this bean if you intend to refer to it from a singleton", ex);
                }
            }
        } catch (BeansException ex) {
            cleanupAfterBeanCreationFailure(beanName);
            throw ex;
        }
    }

    // 检查需要的类型是否符合bean的实际类型，对应getBean时指定的requireType
    if (requiredType != null && bean != null && !requiredType.isAssignableFrom(bean.getClass())) {
        try {
            // 执行类型转换，转换成期望的类型
            return this.getTypeConverter().convertIfNecessary(bean, requiredType);
        } catch (TypeMismatchException ex) {
            if (logger.isDebugEnabled()) {
                logger.debug("Failed to convert bean '" + name + "' to required type '" + ClassUtils.getQualifiedName(requiredType) + "'", ex);
            }
            throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
        }
    }
    return (T) bean;
}
```

整个方法的过程可以概括为：

1. 获取参数 name 对应的真正的 beanName
2. 检查缓存或者实例工厂中是否有对应的单例，若存在则进行实例化并返回对象，否则继续往下执行
3. 执行 prototype 类型依赖检查，防止循环依赖
4. 如果当前 beanFactory 中不存在需要的 bean，则尝试从 parentBeanFactory 中获取
5. 将之前解析过程返得到的 GenericBeanDefinition 对象合并为 RootBeanDefinition 对象，便于后续处理
6. 如果存在依赖的 bean，则进行递归加载
7. 依据当前 bean 的作用域对 bean 进行实例化
8. 如果对返回 bean 类型有要求，则进行类型检查，并按需做类型转换
9. 返回 bean 实例

接下来我们针对各步骤中的详细过程按照需要进行逐一探究。

## 获取真正的 beanName

我们在调用 getBean 方法的时候传递的 name 可以是 bean 的别名，也可以是获取 factoryBean 实例的 name，所以当我们以 name 为 key 检索 bean 的时候，首先需要获取 name 对应的唯一标识 bean 的真正名称 beanName，这一过程位于 transformedBeanName(String name) 方法中：

```java
protected String transformedBeanName(String name) {
    return this.canonicalName(BeanFactoryUtils.transformedBeanName(name));
}
```

上述方法首先会通过 BeanFactoryUtils 工具类方法判断是不是获取 factoryBean，如果是的话就去掉 name 前面的 “&” 字符，然后执行 canonicalName(String name) 逻辑：

```java
public String canonicalName(String name) {  // canonical：权威的
    String canonicalName = name;
    String resolvedName;
    do {
        resolvedName = this.aliasMap.get(canonicalName);
        if (resolvedName != null) {
            canonicalName = resolvedName;
        }
        // 遍历寻找真正的name，因为可能存在引用链
    } while (resolvedName != null);
    return canonicalName;
}
```

为什么这里当 `resolvedName != null` 的时候需要继续循环呢，这是因为一个别名所引用的不一定是一个最终的 beanName，可以是另外一个别名，这个时候就是一个链式引用的场景，我们需要继续沿着引用链往下寻找最终的 beanName。

## 尝试从单例集合中获取目标 bean

容器首先尝试从单例对象集合中获取 bean 实例，我们都知道单例对象在容器中只会存在一份，所以首先检查单例集合也符合常理，获取单例对象的方法如下：

```java
public Object getSingleton(String beanName) {
    // true表示允许早期依赖
    return this.getSingleton(beanName, true);
}
```

上述方法第二个参数设置为 true，即 `allowEarlyReference=true`，表示允许对 bean 的早期依赖，Spring 中 bean 的依赖关系由开发者控制，具备极大的自由配置空间，如果配置不当，可能会导致循环依赖的场景，即 A 依赖于 B，而 B 又依赖于 A，当初始化 A 的时候，检测到引用的 B 还没有实例化，就会转去实例 B，实例化 B 的过程中又会发现 A 还没有实例化完成，从而又回来实例化 A，因此陷入死锁。而 allowEarlyReference 则会提前曝光 bean 的创建过程，具体如下：

```java
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
    // 检查 singletonObjects 缓存中是否存在 单例实例
    Object singletonObject = this.singletonObjects.get(beanName); // singletonObjects: key(beanName) value(bean实例)

    if (singletonObject == null // singletonObjects缓存中为空
            && this.isSingletonCurrentlyInCreation(beanName)) {  // bean正在创建中
        synchronized (this.singletonObjects) {
            singletonObject = this.earlySingletonObjects.get(beanName); // earlySingletonObjects:key(beanName) value(bean实例)（这里的实例还处于创建中）
            if (singletonObject == null && allowEarlyReference) {
                // 当某些方法需要提前初始化的时候，
                // 会调用addSingletonFactory将对应的objectFactory存储在singletonFactories中
                ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName); // singletonFactories key(beanName) value(ObjectFactory)
                if (singletonFactory != null) {
                    singletonObject = singletonFactory.getObject();
                    // earlySingletonObjects 和 singletonFactories互斥
                    this.earlySingletonObjects.put(beanName, singletonObject);
                    this.singletonFactories.remove(beanName);
                }
            }
        }
    }
    return (singletonObject != NULL_OBJECT ? singletonObject : null);
}
```

上述方法的逻辑是
首先从存放 bean 实例的集合 singletonObjects 中获取实例，
如果实例不存在且正在创建中，则尝试从 earlySingletonObjects 中获取正在创建中的 bean 实例，
如果仍然不存在并且允许早期依赖，则将 ObjectFactory 提前曝光。

> **singletonObjects 和 earlySingletonObjects 的区别**
>
> 两者都是以 beanName 为 key，bean 实例为 value 进行存储，区别在于
> singletonObjects 存储的是实例化完成的 bean 实例，
> earlySingletonObjects 存储的是正在实例化中的 bean，
> 所以两个集合的内容也是互斥的。

## 从 bean 实例中获取目标对象

如果上一步我们获取到了单例 bean 实例，那么我们需要接着调用 getObjectForBeanInstance 方法，该方法在 doGetBean 的过程中被多次调用，每次我们获取到 bean 实例之后，不管是从单例集合中获取、还是实时生成各个作用域对象，我们都需要调用一次该方法，该方法的主要目的是判断当前 bean 实例是否是 FactoryBean，如果是 FactoryBean 实例，同时用户希望获取的是真正的 bean 实例（即 name 不是以 “&” 开头），此时就需要由 FactoryBean 实例创建目标 bean 实例：

```java
protected Object getObjectForBeanInstance(Object beanInstance, String name, String beanName, RootBeanDefinition mbd) {

    if (BeanFactoryUtils.isFactoryDereference(name) && !(beanInstance instanceof FactoryBean)) {
        // 获取FactoryBean，但是对应的bean并不是FactoryBean类型
        throw new BeanIsNotAFactoryException(transformedBeanName(name), beanInstance.getClass());
    }

    /*
     * 一个bean实例，可以是普通的bean，也可能是FactoryBean
     * 该bean实例不是FactoryBean or 本来就是希望获取FactoryBean实例
     */
    if (!(beanInstance instanceof FactoryBean) // 不是FactoryBean，直接返回
            || BeanFactoryUtils.isFactoryDereference(name)) { // 希望仅仅获取FactoryBean实例，直接返回
        return beanInstance;
    }

    // 获取由FactoryBean创建的bean实例
    Object object = null;
    if (mbd == null) {
        // 尝试从factoryBeanObjectCache缓存中获取bean实例
        object = this.getCachedObjectForFactoryBean(beanName);
    }
    if (object == null) {
        // 处理FactoryBean
        FactoryBean<?> factory = (FactoryBean<?>) beanInstance;
        if (mbd == null && this.containsBeanDefinition(beanName)) {  // beanName已经注册
            // 指定merge操作
            mbd = this.getMergedLocalBeanDefinition(beanName);
        }
        // 是否是用户定义的，而不是应用程序自己定义的
        boolean synthetic = (mbd != null && mbd.isSynthetic());
        // 核心代码：getObjectFromFactoryBean
        object = this.getObjectFromFactoryBean(factory, beanName, !synthetic);
    }
    return object;
}
```

方法首先会进行一些基础校验，如果用户希望获取的是 FactoryBean 实例，但是当前的实例明确不是 FactoryBean 实例则抛出异常，否则除非当前实例是 FactoryBean 实例，同时用户又希望获取由 FactoryBean 实例创建的对象，其余情况直接返回 bean 实例。

接下来就是处理由 FactoryBean 实例创建目标 bean 对象的过程，首先容器会尝试从缓存中获取，因为对于一些单例的 bean 来说，可能之前已经完成了创建，如果缓存不命中则执行创建过程，这里继续调用 getObjectFromFactoryBean 方法：

```java
protected Object getObjectFromFactoryBean(FactoryBean<?> factory, String beanName, boolean shouldPostProcess) {

    if (factory.isSingleton() && this.containsSingleton(beanName)) {
        // 如果是单例，且factoryBean已经实例化
        synchronized (this.getSingletonMutex()) {
            // 尝试从缓存中获取， factoryBeanObjectCache以factoryBeanName为key存储由FactoryBean创建的实例
            Object object = this.factoryBeanObjectCache.get(beanName);
            if (object == null) {
                // 调用FactoryBean的getObject方法创建对象
                object = this.doGetObjectFromFactoryBean(factory, beanName);
                // 尝试获取已经缓存的实例
                Object alreadyThere = this.factoryBeanObjectCache.get(beanName);
                if (alreadyThere != null) {
                    object = alreadyThere;
                } else {
                    if (object != null && shouldPostProcess) {
                        try {
                            // 调用后置处理器
                            object = this.postProcessObjectFromFactoryBean(object, beanName);
                        } catch (Throwable ex) {
                            throw new BeanCreationException(beanName, "Post-processing of FactoryBean's singleton object failed", ex);
                        }
                    }
                    // 缓存，以 factoryBeanName 为key，由FactoryBean创建的对象为value
                    this.factoryBeanObjectCache.put(beanName, (object != null ? object : NULL_OBJECT));
                }
            }
            return (object != NULL_OBJECT ? object : null);
        }
    } else {
        // 调用FactoryBean的getObject方法创建对象
        Object object = this.doGetObjectFromFactoryBean(factory, beanName);
        if (object != null && shouldPostProcess) {
            try {
                // 调用后置处理器
                object = this.postProcessObjectFromFactoryBean(object, beanName);
            } catch (Throwable ex) {
                throw new BeanCreationException(beanName, "Post-processing of FactoryBean's object failed", ex);
            }
        }
        return object;
    }
}
```

该方法对于单例来说，保证单例在容器中的唯一性，同时触发后置处理器，而我们期望的创建 bean 实例的逻辑位于 doGetObjectFromFactoryBean 方法中，这里才是调用我们在使用 FactoryBean 构造对象所覆盖的 getObject 方法的地方，前面的文章已经介绍过 FactoryBean，并演示了 FactoryBean 的使用方法，再来回顾一下 FactoryBean 的构成：

```java
public interface FactoryBean<T> {
	/** 获取由 FactoryBean 创建的目标 bean 实例*/
	T getObject() throws Exception;
	/** 返回目标 bean 类型 */
	Class<?> getObjectType();
	/** 是否是单实例 */
	boolean isSingleton();
}
```

FactoryBean 接口仅仅包含 3 个方法，而 getObject 是用来真正创建对象的地方，当我们在调用 BeanFactory 的 getBean 方法不加 “&” 获取 bean 实例时，这个时候 getBean 可以看做是 getObject 方法的代理方法，而具体调用就在 doGetObjectFromFactoryBean 方法中：

```java
private Object doGetObjectFromFactoryBean(final FactoryBean<?> factory, final String beanName) throws BeanCreationException {
    Object object;
    try {
        // 需要权限验证
        if (System.getSecurityManager() != null) {
            AccessControlContext acc = this.getAccessControlContext();
            try {
                object = AccessController.doPrivileged(new PrivilegedExceptionAction<Object>() {
                    @Override
                    public Object run() throws Exception {
                        return factory.getObject();
                    }
                }, acc);
            } catch (PrivilegedActionException pae) {
                throw pae.getException();
            }
        } else {
            // 直接调用getObject方法，FactoryBean的getObject方法代理了getBean
            object = factory.getObject();
        }
    } catch (FactoryBeanNotInitializedException ex) {
        throw new BeanCurrentlyInCreationException(beanName, ex.toString());
    } catch (Throwable ex) {
        throw new BeanCreationException(beanName, "FactoryBean threw exception on object creation", ex);
    }
    // FactoryBean未成功创建对象，或factoryBean实例正在被创建
    if (object == null && this.isSingletonCurrentlyInCreation(beanName)) {
        throw new BeanCurrentlyInCreationException(beanName, "FactoryBean which is currently in creation returned null from getObject");
    }
    return object;
}
```

上述方法中的 factory.getObject() 是我们一层层剥离外表所触及到的核心，其具体实现则交给了开发者。

## 创建 bean 实例

如果单例缓存集合中不存在目标 bean 实例，那么说明当前 bean 可能是一个非单例对象，或者是一个单例但却是第一次加载，如果前面的操作是获取对象，那么这里就需要真正创建对象了，在具体创建对象之前，需要做如下几步操作：

> 1. 对 prototype 对象的循环依赖进行检查，如果存在循环依赖则直接抛出异常，而不尝试去解决循环依赖。
> 2. 检测目标 bean 是否属于当前 BeanFactory 的管辖范围，如果不属于，同时又存在父 BeanFactory，则委托给父 BeanFactory 进行处理。
> 3. 检测是不是仅仅做类型检查，如果不是则清空 merge 标记，并标记当前 bean 为已创建状态
> 4. 将存储XML配置的GenericBeanDefinition实例转换成RootBeanDefinition实例，方便后续处理
> 5. 检查依赖的 bean，如果存在且未实例化，则先递归实例化依赖的 bean

完成了上述流程之后，容器针对具体的作用域采取适当的方法创建对应的 bean 实例。

### 创建单例对象

之前尝试从单例缓存集合中获取单例对象，而能够走到这里说明之前缓存不命中，对应的单例对象还没有创建，需要现在开始实时创建，这个过程位于 getSingleton(String beanName, ObjectFactory<?> singletonFactory) 方法中，这是一个重载方法，与前面从缓存中获取单例对象的方法在参数上存在差别：

```java
public Object getSingleton(String beanName, ObjectFactory<?> singletonFactory) {
    Assert.notNull(beanName, "'beanName' must not be null");
    synchronized (this.singletonObjects) {  // singletonObjects用于缓存beanName与已创建的单例对象的映射关系
        Object singletonObject = this.singletonObjects.get(beanName);
        if (singletonObject == null) { // 对应的bean没有加载过
            // 开始singleton bean的初始化过程
            if (this.singletonsCurrentlyInDestruction) {
                // 对应的bean正在其它地方创建中
                throw new BeanCreationNotAllowedException(beanName,
                        "Singleton bean creation not allowed while singletons of this factory are in destruction (Do not request a bean from a BeanFactory in a destroy method implementation!)");
            }

            // 前置处理，对于需要依赖检测的bean，设置状态为“正在创建中”
            this.beforeSingletonCreation(beanName);

            boolean newSingleton = false;
            boolean recordSuppressedExceptions = (this.suppressedExceptions == null);
            if (recordSuppressedExceptions) {
                this.suppressedExceptions = new LinkedHashSet<Exception>();
            }

            try {
                // 实例化bean
                singletonObject = singletonFactory.getObject();
                newSingleton = true;
            } catch (IllegalStateException ex) {
                // 异常，再次尝试从缓存中获取
                singletonObject = this.singletonObjects.get(beanName);
                if (singletonObject == null) {
                    throw ex;
                }
            } catch (BeanCreationException ex) {
                if (recordSuppressedExceptions) {
                    for (Exception suppressedException : this.suppressedExceptions) {
                        ex.addRelatedCause(suppressedException);
                    }
                }
                throw ex;
            } finally {
                if (recordSuppressedExceptions) {
                    this.suppressedExceptions = null;
                }
                // 后置处理，对于需要依赖检测的bean，移除“正在创建中”的状态
                this.afterSingletonCreation(beanName);
            }
            if (newSingleton) { // 新实例
                // 加入缓存
                this.addSingleton(beanName, singletonObject);
            }
        }
        // 返回实例
        return (singletonObject != NULL_OBJECT ? singletonObject : null);
    }
}
```

整个方法的逻辑还是很直观的，流程概括如下：

> 1. 检测 bean 是否正在其它地方被创建，是的话抛异常并中断流程
> 2. 标记 bean 的状态为“正在创建中”
> 3. 实例化 bean，如果过程中出现异常，则尝试从缓存中获取实例
> 4. 移除 bean 的“正在创建中”的状态
> 5. 将 bean 实例加入缓存，并返回实例

步骤三中的实例化 bean 是整个流程的关键所在，这里调用了参数 singletonFactory 的 getObject 方法，由前面传入的参数我们可以知道 getObject 中的逻辑如下：

```java
this.getSingleton(beanName, new ObjectFactory<Object>() {
    @Override
    public Object getObject() throws BeansException {
        try {
            return createBean(beanName, mbd, args);
        } catch (BeansException ex) {
            // 清理工作，从单例缓存中移除
            destroySingleton(beanName);
            throw ex;
        }
    }
});
```

所以创建 bean 的真正逻辑位于 createBean 方法中，该方法的具体实现位于 AbstractAutowireCapableBeanFactory 中：

```java
protected Object createBean(String beanName, RootBeanDefinition mbd, Object[] args) throws BeanCreationException {
    RootBeanDefinition mbdToUse = mbd;

    // 1.根据设置的class属性或className来解析得到Class引用
    Class<?> resolvedClass = this.resolveBeanClass(mbd, beanName);
    if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
        mbdToUse = new RootBeanDefinition(mbd);
        mbdToUse.setBeanClass(resolvedClass);
    }

    // 2.对override属性进行标记和验证，本质上是处理lookup-method和replaced-method标签
    try {
        mbdToUse.prepareMethodOverrides();
    } catch (BeanDefinitionValidationException ex) {
        throw new BeanDefinitionStoreException(mbdToUse.getResourceDescription(), beanName, "Validation of method overrides failed", ex);
    }

    // 3. 处理 InstantiationAwareBeanPostProcessor
    try {
        Object bean = this.resolveBeforeInstantiation(beanName, mbdToUse);
        if (bean != null) {
            // 如果处理结果不为null，则直接返回，而不执行后续的createBean
            return bean;
        }
    } catch (Throwable ex) {
        throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName, "BeanPostProcessor before instantiation of bean failed", ex);
    }

    // 4. 创建bean实例
    Object beanInstance = this.doCreateBean(beanName, mbdToUse, args);
    if (logger.isDebugEnabled()) {
        logger.debug("Finished creating instance of bean '" + beanName + "'");
    }
    return beanInstance;
}
```

该方法虽然叫 createBean，但仍然不是真正创建 bean 实例的地方，该方法主要还是在做一些前期准备工作，具体的流程参见代码注释，下面针对各个过程来逐一探究。

#### 获取 class 引用

不知道你是否还记得，在对标签解析过程的探究中，对于 class 属性的解析，如果参数中传入了类加载器则会尝试获取其 class 引用，否则直接记录类的全称类名，对于前者这里的解析就是直接返回引用，而后者则需要在此对其进行解析得到对应的 class 引用：

```java
protected Class<?> resolveBeanClass(final RootBeanDefinition mbd, String beanName, final Class<?>... typesToMatch)
        throws CannotLoadBeanClassException {
    try {
        if (mbd.hasBeanClass()) {
            // 如果之前直接存储的class引用则直接返回
            return mbd.getBeanClass();
        }
        // 否则由beanClassName解析得到class引用
        if (System.getSecurityManager() != null) {
            return AccessController.doPrivileged(new PrivilegedExceptionAction<Class<?>>() {
                @Override
                public Class<?> run() throws Exception {
                    // 解析得到bean引用
                    return doResolveBeanClass(mbd, typesToMatch);
                }
            }, getAccessControlContext());
        } else {
            // 解析得到bean引用
            return this.doResolveBeanClass(mbd, typesToMatch);
        }
    } catch (PrivilegedActionException pae) {
        ClassNotFoundException ex = (ClassNotFoundException) pae.getException();
        throw new CannotLoadBeanClassException(mbd.getResourceDescription(), beanName, mbd.getBeanClassName(), ex);
    } catch (ClassNotFoundException ex) {
        throw new CannotLoadBeanClassException(mbd.getResourceDescription(), beanName, mbd.getBeanClassName(), ex);
    } catch (LinkageError ex) {
        throw new CannotLoadBeanClassException(mbd.getResourceDescription(), beanName, mbd.getBeanClassName(), ex);
    }
}
```

逻辑很清晰，如果 beanDefinition 实例中记录已经是 class 引用则直接返回，否则进行解析，即 doResolveBeanClass 方法，该方法会验证类全称类名，并利用类加载器解析获取 class 引用，具体不再展开。

#### 处理 override 属性

Spring 中并不存在 `override-method` 的标签，这里的 override 指的是 <lookup-method/> 和 <replaced-method/> 两个标签，之前解析这两个标签时是将这两个标签配置以 MethodOverride 对象的形式记录在 beanDefinition 实例的 methodOverrides 属性中，而这里的处理主要是逐一检查所覆盖的方法是否存在，如果不存在则覆盖无效，如果存在唯一的方法，则覆盖是明确的，标记后期无需依据参数类型以及个数进行推测：

```java
public void prepareMethodOverrides() throws BeanDefinitionValidationException {
    // 获取之前记录的<lookup-method/>和<replaced-method/>标签配置
    MethodOverrides methodOverrides = this.getMethodOverrides();
    if (!methodOverrides.isEmpty()) {
        Set<MethodOverride> overrides = methodOverrides.getOverrides();
        synchronized (overrides) {
            for (MethodOverride mo : overrides) {
                // 逐一处理
                this.prepareMethodOverride(mo);
            }
        }
    }
}
protected void prepareMethodOverride(MethodOverride mo) throws BeanDefinitionValidationException {
    // 获取指定类中指定方法名的个数
    int count = ClassUtils.getMethodCountForName(this.getBeanClass(), mo.getMethodName());
    if (count == 0) {
        // 无效
        throw new BeanDefinitionValidationException("Invalid method override: no method with name '" + mo.getMethodName() + "' on class [" + getBeanClassName() + "]");
    } else if (count == 1) {
        /*
         * 标记MethodOverride暂未被覆盖，避免参数类型检查的开销
         *
         * 如果一个方法存在多个重载，那么在调用及增强的时候还需要根据参数类型进行匹配来最终确认调用的函数
         * 如果方法只有一个，就在这里设置重载为false，后续可以直接定位方法
         */
        mo.setOverloaded(false);
    }
}
```

#### 处理 InstantiationAwareBeanPostProcessor

接下来主要处理 InstantiationAwareBeanPostProcessor 处理器，我们先来回忆一下该处理器的作用。该处理器的接口定义如下：

```java
public interface InstantiationAwareBeanPostProcessor extends BeanPostProcessor {

    /** bean实例化前调用，是对bean定义进行修改的最后机会 */
    Object postProcessBeforeInstantiation(Class<?> beanClass, String beanName) throws BeansException;

    /** bean实例化后立即调用，位于属性注入之前 */
    boolean postProcessAfterInstantiation(Object bean, String beanName) throws BeansException;

    /** 在将属性注入bean实例前的属性处理 */
    PropertyValues postProcessPropertyValues(PropertyValues pvs, PropertyDescriptor[] pds, Object bean, String beanName) throws BeansException;

}
```

由上述说明还是能够清晰的知道这个处理器的功能，接口中定义的方法紧挨着 bean 实例化的过程，如果我们希望在实例化前后对 bean 的定义实施一些修改，可以实现该接口并注册到 BeanFactory 中，不过需要注意一点的是处理器会对所有的 bean 生效，而筛选的逻辑需要我们自己实现。

回过头来我们继续探究这里的处理逻辑，如下首先会去解析 bean 的真正 class 引用，因为可能存在一些工厂 bean，而具体的 bean 类型还需要通过工厂方法去推测：

```java
protected Object resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd) {
    Object bean = null;
    if (!Boolean.FALSE.equals(mbd.beforeInstantiationResolved)) { // 表示尚未被解析
        // mbd是程序创建的且存在后置处理器
        if (!mbd.isSynthetic() && this.hasInstantiationAwareBeanPostProcessors()) {
            // 获取最终的class引用，如果是工厂方法则获取工厂所创建的实例类型
            Class<?> targetType = this.determineTargetType(beanName, mbd);
            if (targetType != null) {
                // 调用实例化前置处理器
                bean = this.applyBeanPostProcessorsBeforeInstantiation(targetType, beanName);
                if (bean != null) {
                    // 调用实例化后置处理器
                    bean = this.applyBeanPostProcessorsAfterInitialization(bean, beanName);
                }
            }
        }
        mbd.beforeInstantiationResolved = (bean != null);
    }
    return bean;
}
```

然后就是我们之前说到的 InstantiationAwareBeanPostProcessor 中的应用实例化前置和后置处理器，代码逻辑分别如下：

- **应用实例化前置处理**

```java
protected Object applyBeanPostProcessorsBeforeInstantiation(Class<?> beanClass, String beanName) {
    // 实例化前置处理器
    for (BeanPostProcessor bp : this.getBeanPostProcessors()) {
        if (bp instanceof InstantiationAwareBeanPostProcessor) {
            // 逐一调用处理器
            InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
            Object result = ibp.postProcessBeforeInstantiation(beanClass, beanName);
            if (result != null) {
                return result;
            }
        }
    }
    return null;
}
```

- **应用实例化后置处理**

```java
public Object applyBeanPostProcessorsAfterInitialization(Object existingBean, String beanName) throws BeansException {
    // 实例化后置处理器
    Object result = existingBean;
    // 依次采用后置处理器处理
    for (BeanPostProcessor beanProcessor : this.getBeanPostProcessors()) {
        result = beanProcessor.postProcessAfterInitialization(result, beanName);
        if (result == null) {
            return result;
        }
    }
    return result;
}
```

当然这里的后置处理不是必然调用，而是建立在前置处理实例化了 bean 的前提下，因为真正常规实例化 bean 的过程将在接下来一步进行发生，不过如果这一步已经完成了 bean 的实例化过程，那么也就没有继续执行下去的必要，直接返回即可：

```java
if (bean != null) {
    // 如果处理结果不为null，则直接返回，而不执行后续的createBean
    return bean;
}
```

#### 实例化 bean

终于挖到了实例化 bean 的地方，实例化 bean 的逻辑还是挺复杂的，我们先来看一下主体流程，如源码中的注释，我们可以将整个过程概括为 7 个步骤：

> 1. 如果是单例，尝试从缓存中获取 bean 的包装器 BeanWrapper
> 2. 如果不存在对应的 Wrapper，则说明 bean 未被实例化，创建 bean 实例
> 3. 应用 MergedBeanDefinitionPostProcessor
> 4. 检查是否需要提前曝光，避免循环依赖
> 5. 初始化 bean 实例
> 6. 再次基于依存关系验证是否存在循环依赖
> 7. 注册 DisposableBean

```java
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final Object[] args) throws BeanCreationException {

    BeanWrapper instanceWrapper = null;
    // 1. 如果是单例，尝试获取对应的BeanWrapper
    if (mbd.isSingleton()) {
        instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
    }

    // 2. bean未实例化，创建 bean 实例
    if (instanceWrapper == null) {
        /*
         * 说明对应的bean还没有创建，用对应的策略（工厂方法、构造函数）创建bean实例，以及简单初始化
         *
         * 将beanDefinition转成BeanWrapper，大致流程如下：
         * 1. 如果存在工厂方法，则使用工厂方法初始化
         * 2. 否则，如果存在多个构造函数，则根据参数确定构造函数，并利用构造函数初始化
         * 3. 否则，使用默认构造函数初始化
         */
        instanceWrapper = this.createBeanInstance(beanName, mbd, args);
    }
    // 从BeanWrapper中获取包装的bean实例
    final Object bean = (instanceWrapper != null ? instanceWrapper.getWrappedInstance() : null);
    // 从BeanWrapper获取包装bean的class引用
    Class<?> beanType = (instanceWrapper != null ? instanceWrapper.getWrappedClass() : null);
    mbd.resolvedTargetType = beanType;

    // 3. 应用 MergedBeanDefinitionPostProcessor
    synchronized (mbd.postProcessingLock) {
        if (!mbd.postProcessed) {
            try {
                // 处理 merged bean，Autowired通过此方法实现诸如类型的解析
                this.applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
            } catch (Throwable ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Post-processing of merged bean definition failed", ex);
            }
            mbd.postProcessed = true;
        }
    }

    // 4. 检查是否需要提前曝光，避免循环依赖，条件：单例 && 允许循环依赖 && 当前bean正在创建中
    boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences && this.isSingletonCurrentlyInCreation(beanName));
    if (earlySingletonExposure) {
        // 为避免循环依赖，在完成bean实例化之前，将对应的ObjectFactory加入bean的工厂
        this.addSingletonFactory(beanName, new ObjectFactory<Object>() {
            @Override
            public Object getObject() throws BeansException {
                // 对bean再一次依赖引用，应用SmartInstantiationAwareBeanPostProcessor
                return getEarlyBeanReference(beanName, mbd, bean);
            }
        });
    }

    // 5. 初始化bean实例
    Object exposedObject = bean;
    try {
        // 对bean进行填充，将各个属性值注入，如果存在依赖的bean则进行递归初始化
        this.populateBean(beanName, mbd, instanceWrapper);
        if (exposedObject != null) {
            // 初始化bean，调用初始化方法，比如init-method
            exposedObject = this.initializeBean(beanName, exposedObject, mbd);
        }
    } catch (Throwable ex) {
        if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
            throw (BeanCreationException) ex;
        } else {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
        }
    }

    // 6. 再次基于依存关系验证是否存在循环依赖
    if (earlySingletonExposure) { // 提前曝光
        Object earlySingletonReference = this.getSingleton(beanName, false);
        if (earlySingletonReference != null) { // 只有在检测到循环引用的情况下才会不为null
            if (exposedObject == bean) {  // exposedObject没有在初始化中被增强
                exposedObject = earlySingletonReference;
            } else if (!this.allowRawInjectionDespiteWrapping && this.hasDependentBean(beanName)) {
                // 获取依赖的bean的name
                String[] dependentBeans = this.getDependentBeans(beanName);
                Set<String> actualDependentBeans = new LinkedHashSet<String>(dependentBeans.length);
                for (String dependentBean : dependentBeans) {
                    // 检测依赖，记录未完成创建的bean
                    if (!this.removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                        actualDependentBeans.add(dependentBean);
                    }
                }
                /*
                 * 因为bean在创建完成之后，其依赖的bean一定是被创建了的
                 * 如果actualDependentBeans不为空，则说明bean依赖的bean没有完成创建，存在循环依赖
                 */
                if (!actualDependentBeans.isEmpty()) {
                    throw new BeanCurrentlyInCreationException(beanName,
                            "Bean with name '" + beanName + "' has been injected into other beans [" +
                                    StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
                                    "] in its raw version as part of a circular reference, but has eventually been " +
                                    "wrapped. This means that said other beans do not use the final version of the " +
                                    "bean. This is often the result of over-eager type matching - consider using " +
                                    "'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
                }
            }
        }
    }
    try {
        // 7. 注册DisposableBean
        this.registerDisposableBeanIfNecessary(beanName, bean, mbd);
    } catch (BeanDefinitionValidationException ex) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
    }

    return exposedObject;
}
```

针对上述过程，我们逐一进行探究。

**1. 对于单例，尝试从缓存中获取 BeanWrapper 对象**

单例对象是全局唯一的，一旦创建就常驻内存，如果对应的 bean 已经被实例化过，那么这里获取到的是 BeanWrapper 对象，BeanWrapper 可以看作是偏底层的 bean 包装器，提供了对标准 java bean 的分析和操作方法，包括获取和设置属性值、获取属性描述符，以及属性的读写特性等。

**2. bean 的实例化过程**

如果步骤 1 中没有获取到目标 bean 实例，则说明对应的 bean 还没有被实例化或是非单例的 bean，这个时候就需要创建对象（通过工厂方法或构造函数创建），Spring 创建对象的基本执行流程为：

> 1. 如果存在工厂方法，则使用工厂方法初始化
> 2. 否则，如果存在多个构造函数，则根据参数确定构造函数，并利用构造函数初始化
> 3. 否则，使用默认构造函数初始化

```java
protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, Object[] args) {
    Class<?> beanClass = this.resolveBeanClass(mbd, beanName); // 解析class引用
    if (beanClass != null && !Modifier.isPublic(beanClass.getModifiers()) && !mbd.isNonPublicAccessAllowed()) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Bean class isn't public, and non-public access not allowed: " + beanClass.getName());
    }

    /*1. 如果工厂方法不为空，则使用工厂方法进行实例化*/
    if (mbd.getFactoryMethodName() != null) {
        return this.instantiateUsingFactoryMethod(beanName, mbd, args);
    }

    /*2. 利用构造函数进行实例化，解析并确定目标构造函数*/
    boolean resolved = false;
    boolean autowireNecessary = false;
    if (args == null) {
        synchronized (mbd.constructorArgumentLock) {
            // 一个类可能有多个构造函数，需要根据参数来确定具体的构造函数
            if (mbd.resolvedConstructorOrFactoryMethod != null) {
                resolved = true;
                autowireNecessary = mbd.constructorArgumentsResolved;
            }
        }
    }
    // 如果已经解析过，则使用已经确定的构造方法
    if (resolved) {
        if (autowireNecessary) {
            // 依据构造函数注入
            return this.autowireConstructor(beanName, mbd, null, null);
        } else {
            // 使用默认构造函数构造
            return this.instantiateBean(beanName, mbd);
        }
    }

    // 需要根据参数决定使用哪个构造函数
    Constructor<?>[] ctors = this.determineConstructorsFromBeanPostProcessors(beanClass, beanName);
    if (ctors != null ||
            mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_CONSTRUCTOR || // 构造函数注入
            mbd.hasConstructorArgumentValues() || !ObjectUtils.isEmpty(args)) { // 存在构造函数配置
        // 构造函数自动注入
        return this.autowireConstructor(beanName, mbd, ctors, args);
    }

    /*3. 使用默认的构造函数*/
    return this.instantiateBean(beanName, mbd);
}
```

上述源码是属于框架式的源码，描述了整个实例化的执行流程（如前面所述），接下来我们需要继续往下深入，探究各种实例化过程，以及容器确定目标构造函数的算法。

如果存在 factory-method 则说明存在工厂方法执行实例化，Spring 通过 instantiateUsingFactoryMethod 方法执行实例化过程：

```java
protected BeanWrapper instantiateUsingFactoryMethod(String beanName, RootBeanDefinition mbd, Object[] explicitArgs) {
    return new ConstructorResolver(this).instantiateUsingFactoryMethod(beanName, mbd, explicitArgs);
}
public BeanWrapper instantiateUsingFactoryMethod(final String beanName, final RootBeanDefinition mbd, final Object[] explicitArgs) {
    // 创建并初始化 BeanWrapper
    BeanWrapperImpl bw = new BeanWrapperImpl();
    this.beanFactory.initBeanWrapper(bw);

    Object factoryBean; // 工厂
    Class<?> factoryClass; // 工厂所指代的类
    boolean isStatic;  // 是不是静态工厂
    String factoryBeanName = mbd.getFactoryBeanName(); // 获取factory-bean
    if (factoryBeanName != null) {
        /*
         * 存在factory-bean，说明是非静态工厂
         *
         * <bean id="my-bean-simple-factory" class="org.zhenchao.factory.MyBeanSimpleFactory"/>
         * <bean id="my-bean-1" factory-bean="my-bean-simple-factory" factory-method="create"/>
         */
        if (factoryBeanName.equals(beanName)) {
            throw new BeanDefinitionStoreException(mbd.getResourceDescription(), beanName, "factory-bean reference points back to the same bean definition");
        }
        // 获取工厂bean实例
        factoryBean = this.beanFactory.getBean(factoryBeanName);
        if (factoryBean == null) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName, "factory-bean '" + factoryBeanName + "' (or a BeanPostProcessor involved) returned null");
        }
        // 单例不需要由工厂主动创建
        if (mbd.isSingleton() && this.beanFactory.containsSingleton(beanName)) {
            throw new IllegalStateException("About-to-be-created singleton instance implicitly appeared through the creation of the factory bean that its bean definition points to");
        }
        factoryClass = factoryBean.getClass();
        isStatic = false;
    } else {
        /*
         * 不存在factory-bean，说明是静态工厂
         *
         * <bean id="my-bean-2" class="org.zhenchao.factory.MyBeanStaticFactory" factory-method="create"/>
         */
        if (!mbd.hasBeanClass()) {
            throw new BeanDefinitionStoreException(mbd.getResourceDescription(), beanName, "bean definition declares neither a bean class nor a factory-bean reference");
        }
        factoryBean = null;
        factoryClass = mbd.getBeanClass();
        isStatic = true;
    }

    Method factoryMethodToUse = null;
    ArgumentsHolder argsHolderToUse = null;
    Object[] argsToUse = null;
    if (explicitArgs != null) {
        // getBean时传递的构造参数
        argsToUse = explicitArgs;
    } else {
        // 如果没有则需要进行解析
        Object[] argsToResolve = null;
        // 尝试从缓存中获取
        synchronized (mbd.constructorArgumentLock) {
            factoryMethodToUse = (Method) mbd.resolvedConstructorOrFactoryMethod;
            if (factoryMethodToUse != null && mbd.constructorArgumentsResolved) {
                // 存在已经解析过的工厂方法
                argsToUse = mbd.resolvedConstructorArguments;
                if (argsToUse == null) {
                    // 获取待解析的构造参数
                    argsToResolve = mbd.preparedConstructorArguments;
                }
            }
        }
        // 缓存命中
        if (argsToResolve != null) {
            // 解析参数值，必要的话会进行类型转换
            argsToUse = this.resolvePreparedArguments(beanName, mbd, bw, factoryMethodToUse, argsToResolve);
        }
    }

    // 缓存未命中，则基于参数来解析决策确定的工厂方法
    if (factoryMethodToUse == null || argsToUse == null) {
        // 获取候选的工厂方法
        factoryClass = ClassUtils.getUserClass(factoryClass);
        Method[] rawCandidates = this.getCandidateMethods(factoryClass, mbd);
        List<Method> candidateSet = new ArrayList<Method>();
        for (Method candidate : rawCandidates) {
            if (Modifier.isStatic(candidate.getModifiers()) == isStatic && mbd.isFactoryMethod(candidate)) {
                candidateSet.add(candidate);
            }
        }
        Method[] candidates = candidateSet.toArray(new Method[candidateSet.size()]);
        // 对候选方法进行排序，public在前，参数多的在前
        AutowireUtils.sortFactoryMethods(candidates);

        ConstructorArgumentValues resolvedValues = null;
        boolean autowiring = (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_CONSTRUCTOR);
        int minTypeDiffWeight = Integer.MAX_VALUE;
        Set<Method> ambiguousFactoryMethods = null;

        int minNrOfArgs;
        if (explicitArgs != null) {
            // getBean时明确指定了参数
            minNrOfArgs = explicitArgs.length;
        } else {
            // 没有指定，则从beanDefinition实例中解析
            ConstructorArgumentValues cargs = mbd.getConstructorArgumentValues();
            resolvedValues = new ConstructorArgumentValues();
            // 获取解析到的参数个数
            minNrOfArgs = this.resolveConstructorArguments(beanName, mbd, bw, cargs, resolvedValues);
        }

        LinkedList<UnsatisfiedDependencyException> causes = null;
        // 遍历候选方法
        for (Method candidate : candidates) {
            Class<?>[] paramTypes = candidate.getParameterTypes();
            if (paramTypes.length >= minNrOfArgs) {
                ArgumentsHolder argsHolder;
                if (resolvedValues != null) {
                    // Resolved constructor arguments: type conversion and/or autowiring necessary.
                    try {
                        String[] paramNames = null;
                        // 获取参数名称探测去
                        ParameterNameDiscoverer pnd = this.beanFactory.getParameterNameDiscoverer();
                        if (pnd != null) {
                            // 获取候选方法的参数名称列表
                            paramNames = pnd.getParameterNames(candidate);
                        }
                        // 依据参数名称和类型创建参数持有对象
                        argsHolder = this.createArgumentArray(
                                beanName, mbd, resolvedValues, bw, paramTypes, paramNames, candidate, autowiring);
                    } catch (UnsatisfiedDependencyException ex) {
                        if (this.beanFactory.logger.isTraceEnabled()) {
                            this.beanFactory.logger.trace("Ignoring factory method [" + candidate + "] of bean '" + beanName + "': " + ex);
                        }
                        // 异常，尝试下一个候选工厂方法
                        if (causes == null) {
                            causes = new LinkedList<UnsatisfiedDependencyException>();
                        }
                        causes.add(ex);
                        continue;
                    }
                } else {
                    if (paramTypes.length != explicitArgs.length) {
                        // 参数个数不等于期望的参数个数
                        continue;
                    }
                    argsHolder = new ArgumentsHolder(explicitArgs);
                }

                // 检测是否有不确定的候选方法存在（比如不同方法的参数存在继承关系）
                int typeDiffWeight = (mbd.isLenientConstructorResolution() ?
                        argsHolder.getTypeDifferenceWeight(paramTypes) : argsHolder.getAssignabilityWeight(paramTypes));
                // 选择最近似的候选方法
                if (typeDiffWeight < minTypeDiffWeight) {
                    factoryMethodToUse = candidate;
                    argsHolderToUse = argsHolder;
                    argsToUse = argsHolder.arguments;
                    minTypeDiffWeight = typeDiffWeight;
                    ambiguousFactoryMethods = null;
                } else if (factoryMethodToUse != null && typeDiffWeight == minTypeDiffWeight &&
                        !mbd.isLenientConstructorResolution() &&
                        paramTypes.length == factoryMethodToUse.getParameterTypes().length &&
                        !Arrays.equals(paramTypes, factoryMethodToUse.getParameterTypes())) {
                    if (ambiguousFactoryMethods == null) {
                        ambiguousFactoryMethods = new LinkedHashSet<Method>();
                        ambiguousFactoryMethods.add(factoryMethodToUse);
                    }
                    ambiguousFactoryMethods.add(candidate);
                }
            }
        }

        if (factoryMethodToUse == null) {
            // 无法确定具体的工厂方法
            if (causes != null) {
                UnsatisfiedDependencyException ex = causes.removeLast();
                for (Exception cause : causes) {
                    this.beanFactory.onSuppressedException(cause);
                }
                throw ex;
            }
            List<String> argTypes = new ArrayList<String>(minNrOfArgs);
            if (explicitArgs != null) {
                for (Object arg : explicitArgs) {
                    argTypes.add(arg != null ? arg.getClass().getSimpleName() : "null");
                }
            } else {
                Set<ValueHolder> valueHolders = new LinkedHashSet<ValueHolder>(resolvedValues.getArgumentCount());
                valueHolders.addAll(resolvedValues.getIndexedArgumentValues().values());
                valueHolders.addAll(resolvedValues.getGenericArgumentValues());
                for (ValueHolder value : valueHolders) {
                    String argType = (value.getType() != null ? ClassUtils.getShortName(value.getType()) :
                            (value.getValue() != null ? value.getValue().getClass().getSimpleName() : "null"));
                    argTypes.add(argType);
                }
            }
            String argDesc = StringUtils.collectionToCommaDelimitedString(argTypes);
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "No matching factory method found: " +  (mbd.getFactoryBeanName() != null ?  "factory bean '" + mbd.getFactoryBeanName() + "'; " : "") +
                            "factory method '" + mbd.getFactoryMethodName() + "(" + argDesc + ")'. " + "Check that a method with the specified name " +
                            (minNrOfArgs > 0 ? "and arguments " : "") + "exists and that it is " +  (isStatic ? "static" : "non-static") + ".");
        } else if (void.class == factoryMethodToUse.getReturnType()) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Invalid factory method '" + mbd.getFactoryMethodName() + "': needs to have a non-void return type!");
        } else if (ambiguousFactoryMethods != null) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "Ambiguous factory method matches found in bean '" + beanName + "' " + "(hint: specify index/type/name arguments for simple parameters to avoid type ambiguities): " +  ambiguousFactoryMethods);
        }

        if (explicitArgs == null && argsHolderToUse != null) {
            // 缓存
            argsHolderToUse.storeCache(mbd, factoryMethodToUse);
        }
    }

    // 利用工厂方法创建bean实例
    try {
        Object beanInstance;
        if (System.getSecurityManager() != null) {
            final Object fb = factoryBean;
            final Method factoryMethod = factoryMethodToUse;
            final Object[] args = argsToUse;
            beanInstance = AccessController.doPrivileged(new PrivilegedAction<Object>() {
                @Override
                public Object run() {
                    return beanFactory.getInstantiationStrategy().instantiate(
                            mbd, beanName, beanFactory, fb, factoryMethod, args);
                }
            }, beanFactory.getAccessControlContext());
        } else {
            // 基于java反射调用工厂bean的指定方法依据给定的参数进行实例化
            beanInstance = this.beanFactory.getInstantiationStrategy().instantiate(
                    mbd, beanName, this.beanFactory, factoryBean, factoryMethodToUse, argsToUse);
        }

        if (beanInstance == null) {
            return null;
        }
        bw.setBeanInstance(beanInstance);
        return bw;
    } catch (Throwable ex) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Bean instantiation via factory method failed", ex);
    }
}
```

方法实现真的很长！不过整个方法主要做了三件事情：

> 1. 确定当前使用的是静态工厂配置还是一般工厂配置。
> 2. 确定用于实例化 bean 的工厂方法。
> 3. 调用工厂方法实例化 bean。

其中最复杂的是步骤 2，因为可能存在多个工厂方法的重载版本，所以需要依据给定或配置的参数个数和类型去解析确定的工厂方法，Spring 会对所有的候选工厂方法按照 public 优先，以及参数个数多的方法优先的原则，对候选方法进行排序，然后逐个比对是否满足当前指定的参数列表，依次确定具体使用哪个工厂方法来进行实例化，这个过程与我们后面介绍的通过构造方法进行实例化时确定具体构造方法的过程大同小异，后面你还会看到与此相似的解析过程。

跳出这个方法，我们继续之前的逻辑往下走，如果一个 bean 没有配置工厂方法则需要通过构造函数进行实例化，如前面所说，一个类也可能存在多个重载的构造方法，所以需要依据给定或配置的构造参数进行决策：

```java
protected BeanWrapper autowireConstructor(
        String beanName, RootBeanDefinition mbd, Constructor<?>[] ctors, Object[] explicitArgs) {
    return new ConstructorResolver(this).autowireConstructor(beanName, mbd, ctors, explicitArgs);
}
public BeanWrapper autowireConstructor(
        final String beanName, final RootBeanDefinition mbd, Constructor<?>[] chosenCtors, final Object[] explicitArgs) {
    // 创建并初始化BeanWrapper
    BeanWrapperImpl bw = new BeanWrapperImpl();
    this.beanFactory.initBeanWrapper(bw);

    Constructor<?> constructorToUse = null;
    ArgumentsHolder argsHolderToUse = null;
    Object[] argsToUse = null;
    if (explicitArgs != null) {
        // 调用getBean时明确指定了构造参数explicitArgs
        argsToUse = explicitArgs;
    } else {
        // 尝试从缓存中获取
        Object[] argsToResolve = null;
        synchronized (mbd.constructorArgumentLock) {
            constructorToUse = (Constructor<?>) mbd.resolvedConstructorOrFactoryMethod;
            if (constructorToUse != null && mbd.constructorArgumentsResolved) {
                // 找到了缓存的构造方法
                argsToUse = mbd.resolvedConstructorArguments;
                if (argsToUse == null) {
                    // 配置的构造函数参数
                    argsToResolve = mbd.preparedConstructorArguments;
                }
            }
        }
        // 如果缓存中存在
        if (argsToResolve != null) {
            // 解析参数类型，将字符串值转换为真实的值，缓存中的值可能是原始值也可能是解析后的值
            argsToUse = this.resolvePreparedArguments(beanName, mbd, bw, constructorToUse, argsToResolve);
        }
    }

    // 没有缓存则从配置文件中解析
    if (constructorToUse == null) {
        // 需要解析确定具体的构造方法
        boolean autowiring = (chosenCtors != null ||
                mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_CONSTRUCTOR);
        ConstructorArgumentValues resolvedValues = null;

        int minNrOfArgs; // 记录解析到的参数个数
        if (explicitArgs != null) {
            minNrOfArgs = explicitArgs.length;
        } else {
            // 提取配置的构造函数参数值
            ConstructorArgumentValues cargs = mbd.getConstructorArgumentValues();
            resolvedValues = new ConstructorArgumentValues(); // 用于承载解析后的构造函数参数的值
            // 解析构造参数
            minNrOfArgs = this.resolveConstructorArguments(beanName, mbd, bw, cargs, resolvedValues);
        }

        // 获取候选的构造方法集合
        Constructor<?>[] candidates = chosenCtors;
        if (candidates == null) {
            Class<?> beanClass = mbd.getBeanClass();
            try {
                candidates = (mbd.isNonPublicAccessAllowed() ? beanClass.getDeclaredConstructors() : beanClass.getConstructors());
            } catch (Throwable ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Resolution of declared constructors on bean Class [" + beanClass.getName() + "] from ClassLoader [" + beanClass.getClassLoader() + "] failed", ex);
            }
        }

        // 排序构造函数，public在前，参数多的在前
        AutowireUtils.sortConstructors(candidates);

        int minTypeDiffWeight = Integer.MAX_VALUE;
        Set<Constructor<?>> ambiguousConstructors = null;
        LinkedList<UnsatisfiedDependencyException> causes = null;

        for (Constructor<?> candidate : candidates) {
            Class<?>[] paramTypes = candidate.getParameterTypes();
            if (constructorToUse != null && argsToUse.length > paramTypes.length) {
                // 已经找到目标构造函数，或者已有的构造函数的参数个数已经小于期望的个数
                break;
            }
            if (paramTypes.length < minNrOfArgs) {
                // 参数个数不相等
                continue;
            }

            ArgumentsHolder argsHolder;
            if (resolvedValues != null) {
                // 有参数则根据对应的值构造对应参数类型的参数
                try {
                    // 从注解上获得参数名称
                    String[] paramNames = ConstructorPropertiesChecker.evaluate(candidate, paramTypes.length);
                    if (paramNames == null) {
                        // 获取参数名称探测器
                        ParameterNameDiscoverer pnd = this.beanFactory.getParameterNameDiscoverer();
                        if (pnd != null) {
                            // 获取构造方法的参数名称列表
                            paramNames = pnd.getParameterNames(candidate);
                        }
                    }
                    // 根据数值和类型创建参数持有者
                    argsHolder = this.createArgumentArray(
                            beanName, mbd, resolvedValues, bw, paramTypes, paramNames, this.getUserDeclaredConstructor(candidate), autowiring);
                } catch (UnsatisfiedDependencyException ex) {
                    if (this.beanFactory.logger.isTraceEnabled()) {
                        this.beanFactory.logger.trace("Ignoring constructor [" + candidate + "] of bean '" + beanName + "': " + ex);
                    }
                    // 尝试下一个构造函数
                    if (causes == null) {
                        causes = new LinkedList<UnsatisfiedDependencyException>();
                    }
                    causes.add(ex);
                    continue;
                }
            } else {
                // 参数个数不匹配
                if (paramTypes.length != explicitArgs.length) {
                    continue;
                }
                // 构造函数没有参数的情况
                argsHolder = new ArgumentsHolder(explicitArgs);
            }

            // 探测是否有不确定性的构造函数存在，不如不同构造函数的参数为继承关系
            int typeDiffWeight = (mbd.isLenientConstructorResolution() ?
                    argsHolder.getTypeDifferenceWeight(paramTypes) : argsHolder.getAssignabilityWeight(paramTypes));
            // 如果当前的不确定性构造函数最接近期望值，则选择作为构造函数
            if (typeDiffWeight < minTypeDiffWeight) {
                constructorToUse = candidate;
                argsHolderToUse = argsHolder;
                argsToUse = argsHolder.arguments;
                minTypeDiffWeight = typeDiffWeight;
                ambiguousConstructors = null;
            } else if (constructorToUse != null && typeDiffWeight == minTypeDiffWeight) {
                if (ambiguousConstructors == null) {
                    ambiguousConstructors = new LinkedHashSet<Constructor<?>>();
                    ambiguousConstructors.add(constructorToUse);
                }
                ambiguousConstructors.add(candidate);
            }
        }

        if (constructorToUse == null) {
            if (causes != null) {
                UnsatisfiedDependencyException ex = causes.removeLast();
                for (Exception cause : causes) {
                    this.beanFactory.onSuppressedException(cause);
                }
                throw ex;
            }
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "Could not resolve matching constructor (hint: specify index/type/name arguments for simple parameters to avoid type ambiguities)");
        } else if (ambiguousConstructors != null && !mbd.isLenientConstructorResolution()) {
            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                    "Ambiguous constructor matches found in bean '" + beanName + "' (hint: specify index/type/name arguments for simple parameters to avoid type ambiguities): " + ambiguousConstructors);
        }

        if (explicitArgs == null) {
            // 将解析的构造函数加入缓存
            argsHolderToUse.storeCache(mbd, constructorToUse);
        }
    }

    // 依据构造方法进行实例化
    try {
        Object beanInstance;
        if (System.getSecurityManager() != null) {
            final Constructor<?> ctorToUse = constructorToUse;
            final Object[] argumentsToUse = argsToUse;
            beanInstance = AccessController.doPrivileged(new PrivilegedAction<Object>() {
                @Override
                public Object run() {
                    return beanFactory.getInstantiationStrategy().instantiate(
                            mbd, beanName, beanFactory, ctorToUse, argumentsToUse);
                }
            }, beanFactory.getAccessControlContext());
        } else {
            // 基于反射创建对象
            beanInstance = this.beanFactory.getInstantiationStrategy().instantiate(
                    mbd, beanName, this.beanFactory, constructorToUse, argsToUse);
        }

        // 将构造的实例加入BeanWrapper
        bw.setBeanInstance(beanInstance);
        return bw;
    } catch (Throwable ex) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Bean instantiation via constructor failed", ex);
    }
}
```

整个方法的设计思想与前面通过工厂方法实例化对象相同，具体可参考注释，不再展开，而如果没有指定或配置构造参数，容器会采用默认的构造方法创建对象，该过程位于 instantiateBean 方法中：

```java
protected BeanWrapper instantiateBean(final String beanName, final RootBeanDefinition mbd) {
    try {
        Object beanInstance;
        final BeanFactory parent = this;
        if (System.getSecurityManager() != null) {
            beanInstance = AccessController.doPrivileged(new PrivilegedAction<Object>() {
                @Override
                public Object run() {
                    return getInstantiationStrategy().instantiate(mbd, beanName, parent);
                }
            }, getAccessControlContext());
        } else {
            // 利用反射进行实例化
            beanInstance = this.getInstantiationStrategy().instantiate(mbd, beanName, parent);
        }
        // 利用包装器包装bean实例
        BeanWrapper bw = new BeanWrapperImpl(beanInstance);
        this.initBeanWrapper(bw);
        return bw;
    } catch (Throwable ex) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Instantiation of bean failed", ex);
    }
}
```

需要知晓的一点是，经过上面的流程，不管是通过通过工厂方法还是构造方法来实例化对象，到这里得到的也仅仅是一个 bean 的最初实例，还不是我们最终期望的 bean，因为后面还需要对 bean 实例进行初始化处理，注入相应的属性值等。

**3. 应用 MergedBeanDefinitionPostProcessor**

如果我们实现并注册了 MergedBeanDefinitionPostProcessor 处理器，希望在对 bean 初始化之前对 beanDefinition 进行处理，那么这些处理器会在这里被逐一调用：

```java
protected void applyMergedBeanDefinitionPostProcessors(RootBeanDefinition mbd, Class<?> beanType, String beanName) {
    for (BeanPostProcessor bp : this.getBeanPostProcessors()) {
        // 遍历所有的后置处理器
        if (bp instanceof MergedBeanDefinitionPostProcessor) {
            // 如果是 MergedBeanDefinitionPostProcessor 则进行应用
            MergedBeanDefinitionPostProcessor bdp = (MergedBeanDefinitionPostProcessor) bp;
            bdp.postProcessMergedBeanDefinition(mbd, beanType, beanName);
        }
    }
}
```

**4. 检查是否需要提前曝光，避免循环依赖**

对于单例而言，Spring 会通过提前曝光的机制来尝试解决循环依赖导致的死锁问题，循环依赖导致的死锁除了发生在构造方法注入时，也可能发生在 setter 方法注入过程中，对于前者而言，容器是无法解决循环依赖问题的，只能抛出异常，而后者则可以通过提前曝光的机制来达到“先引用，后初始化”的目的，所以不会死锁，这个过程的关键代码如下：

```java
boolean earlySingletonExposure = (
            mbd.isSingleton() // 单例
                    && this.allowCircularReferences // 允许循环依赖，需要通过程序设置
                    && this.isSingletonCurrentlyInCreation(beanName)); // 当前 bean 正在创建中
    if (earlySingletonExposure) {
        // 为避免循环依赖，在完成bean实例化之前，将对应的ObjectFactory加入创建bean的工厂集合中
        this.addSingletonFactory(beanName, new ObjectFactory<Object>() {
            @Override
            public Object getObject() throws BeansException {
                // 对bean再一次依赖引用，应用SmartInstantiationAwareBeanPostProcessor
                return getEarlyBeanReference(beanName, mbd, bean);
            }
        });
    }
```

方法的逻辑是先判断是否允许提前曝光，如果当前为单例 bean，且程序制定允许循环引用，同时当前 bean 正处于创建中，则会将创建 bean 的 ObjectFactory 对象加入到用于保存 beanName 和创建 bean 的工厂之间的关系的集合中：

```java
protected void addSingletonFactory(String beanName, ObjectFactory<?> singletonFactory) {
    Assert.notNull(singletonFactory, "Singleton factory must not be null");
    synchronized (this.singletonObjects) {
        if (!this.singletonObjects.containsKey(beanName)) {
            this.singletonFactories.put(beanName, singletonFactory);
            this.earlySingletonObjects.remove(beanName);
            this.registeredSingletons.add(beanName);
        }
    }
}
```

> 说明一下方法中各个变量的意义
>
> - singletonObjects：用于保存 beanName 和 bean 实例之间的关系
> - singletonFactories：用于保存 beanName 和 创建 bean 的工厂之间的关系
> - earlySingletonObjects：也是保存 beanName 和 bean 实例之间的关系，不同于 singletonObjects，当一个bean的实例放置于其中后，当bean还在创建过程中就可以通过 getBean 方法获取到
> - registeredSingletons：用来保存当前所有已注册的 bean

上面这段逻辑位于初始化 bean 实例之前，其用意就是当初始化一个 bean 时，如果引用了另外一个 bean，这个时候就需要转而去创建并初始化另外一个 bean，如果恰好该 bean 引用了之前的 bean 就出现了循环依赖，假设我们令第一个 bean 为 A，第二个 bean 为 B，基于这段代码的逻辑，B 就可以先给自己类型为 A 的属性注入 A 的实例（这个时候 A 还没有被初始化），然后完成初始化，此时继续回到初始化 A 的逻辑，因为都是单例，所以当 A 完成了初始化之后，B 所引用的 A 对象也就是一个完成了初始化过程的对象，而不是之前的刚刚完成对象创建还没有注入属性的实例。

**5. 初始化 bean 实例**

整个初始化过程包括 **属性注入** 和 **执行初始化方法** 两个步骤。我们先来看属性注入的过程，该过程位于 populateBean 方法中：

```java
protected void populateBean(String beanName, RootBeanDefinition mbd, BeanWrapper bw) {
    // 获取bean实例的属性值集合
    PropertyValues pvs = mbd.getPropertyValues();
    if (bw == null) {
        if (!pvs.isEmpty()) {
            // null对象，但是存在填充的属性，不合理
            throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Cannot apply property values to null instance");
        } else {
            // null 对象，且没有属性可以填充，直接返回
            return;
        }
    }

    boolean continueWithPropertyPopulation = true;
    // 给InstantiationAwareBeanPostProcessors最后一次机会在注入属性前改变bean实例
    if (!mbd.isSynthetic() && this.hasInstantiationAwareBeanPostProcessors()) {
        for (BeanPostProcessor bp : this.getBeanPostProcessors()) {
            if (bp instanceof InstantiationAwareBeanPostProcessor) {
                InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
                // 是否继续填充bean
                if (!ibp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
                    continueWithPropertyPopulation = false;
                    break;
                }
            }
        }
    }
    // 如果处理器指明不需要再继续执行属性注入，则返回
    if (!continueWithPropertyPopulation) {
        return;
    }

    // autowire by name or autowire by type
    if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME
            || mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
        MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
        // 根据名称自动注入
        if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME) {
            this.autowireByName(beanName, mbd, bw, newPvs);
        }
        // 根据类型自动注入
        if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
            this.autowireByType(beanName, mbd, bw, newPvs);
        }
        pvs = newPvs;
    }

    boolean hasInstAwareBpps = this.hasInstantiationAwareBeanPostProcessors();
    boolean needsDepCheck = (mbd.getDependencyCheck() != RootBeanDefinition.DEPENDENCY_CHECK_NONE);
    if (hasInstAwareBpps || needsDepCheck) {
        PropertyDescriptor[] filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
        // 在属性注入前应用实例化后置处理器
        if (hasInstAwareBpps) {
            for (BeanPostProcessor bp : this.getBeanPostProcessors()) {
                if (bp instanceof InstantiationAwareBeanPostProcessor) {
                    InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
                    // 调用后置处理器的postProcessPropertyValues方法
                    pvs = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
                    if (pvs == null) {
                        // 处理器中把属性值处理没了，则继续执行属性注入已经没有意义
                        return;
                    }
                }
            }
        }
        // 依赖检查，对应depends-on属性，该属性已经弃用
        if (needsDepCheck) {
            this.checkDependencies(beanName, mbd, filteredPds, pvs);
        }
    }

    // 执行属性注入
    this.applyPropertyValues(beanName, mbd, bw, pvs);
}
```

该方法中会执行 InstantiationAwareBeanPostProcessor 后置处理器的 postProcessAfterInstantiation 方法逻辑，从而实现对完成实例化且还没有注入属性值的对象进行最后的更改，如果我们在 postProcessAfterInstantiation 指明不需要执行后续的属性注入过程，则方法到此结束。否则方法会检测当前的注入类型，是 byName 还是 byType，并调用相应的注入逻辑获取依赖的 bean，加入属性集合中。然后方法会调用 InstantiationAwareBeanPostProcessor 后置处理器的 postProcessPropertyValues 方法，实现在将属性值应用到 bean 实例之前的最后一次对属性值的更改，同时会依据配置执行依赖检查，以确保所有的属性都被赋值（这里的赋值是指 beanDefinition 中的属性都有对应的值，而不是指最终 bean 实例的属性是否注入了对应的值）。最后将输入值应用到 bean 实例对应的属性上。

- **autowireByName**

如果当前注入类型是 byName，则容器会基于 beanName 获取依赖的 bean，并将依赖关系保存在对应的集合中，如果依赖的 bean 未被实例化则需要执行实例化逻辑：

```java
protected void autowireByName(
        String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs) {
    // 寻找需要注入的属性
    String[] propertyNames = this.unsatisfiedNonSimpleProperties(mbd, bw);
    for (String propertyName : propertyNames) {
        if (this.containsBean(propertyName)) {
            // 如果依赖的bean没有初始化，则递归初始化相关的bean
            Object bean = this.getBean(propertyName);
            // 添加到属性集合中
            pvs.add(propertyName, bean);
            // 记录依赖关系到集合中
            this.registerDependentBean(propertyName, beanName);
        } else {
        }
    }
}
```

- **autowireByType**

如果当前注入类型是 byType，则容器会依据类型去确定对应的 bean，并将依赖关系保存到对应的集合中，如果依赖的 bean 未被实例化则需要执行实例化逻辑，因为类型注入需要一个推断的过程，所以实现逻辑要复杂很多：

```java
protected void autowireByType(
            String beanName, AbstractBeanDefinition mbd, BeanWrapper bw, MutablePropertyValues pvs) {

    TypeConverter converter = this.getCustomTypeConverter();
    if (converter == null) {
        converter = bw;
    }

    Set<String> autowiredBeanNames = new LinkedHashSet<String>(4);
    // 寻找需要注入的属性
    String[] propertyNames = this.unsatisfiedNonSimpleProperties(mbd, bw);
    for (String propertyName : propertyNames) {
        try {
            PropertyDescriptor pd = bw.getPropertyDescriptor(propertyName);
            if (Object.class != pd.getPropertyType()) {
                // 获取指定属性的set方法
                MethodParameter methodParam = BeanUtils.getWriteMethodParameter(pd);
                boolean eager = !PriorityOrdered.class.isAssignableFrom(bw.getWrappedClass());
                DependencyDescriptor desc = new AutowireByTypeDependencyDescriptor(methodParam, eager);
                /*
                 * 解析指定beanName的属性所匹配的值，并把解析到的属性存储在autowiredBeanNames中，当属性存在多个封装的bean时，比如：
                 *
                 * @Autowired
                 * private List<A> list
                 *
                 * 将会找到所有匹配A类型的bean，并将其注入
                 */
                Object autowiredArgument = this.resolveDependency(desc, beanName, autowiredBeanNames, converter);
                if (autowiredArgument != null) {
                    pvs.add(propertyName, autowiredArgument);
                }
                for (String autowiredBeanName : autowiredBeanNames) {
                    // 记录bean之间的依赖关系
                    this.registerDependentBean(autowiredBeanName, beanName);
                    if (logger.isDebugEnabled()) {
                        logger.debug("Autowiring by type from bean name '" + beanName + "' via property '" + propertyName + "' to bean named '" + autowiredBeanName + "'");
                    }
                }
                autowiredBeanNames.clear();
            }
        } catch (BeansException ex) {
            throw new UnsatisfiedDependencyException(mbd.getResourceDescription(), beanName, propertyName, ex);
        }
    }
}
```

上述方法的核心位于 resolveDependency 方法中：

```java
public Object resolveDependency(
        DependencyDescriptor descriptor, String requestingBeanName, Set<String> autowiredBeanNames, TypeConverter typeConverter)
        throws BeansException {

    // 获取并初始化参数名称探测器
    descriptor.initParameterNameDiscovery(this.getParameterNameDiscoverer());
    if (javaUtilOptionalClass == descriptor.getDependencyType()) {
        // 支持java8的java.util.Optional
        return new OptionalDependencyFactory().createOptionalDependency(descriptor, requestingBeanName);
    } else if (ObjectFactory.class == descriptor.getDependencyType() || ObjectProvider.class == descriptor.getDependencyType()) {
        // ObjectFactory类注入的特殊处理
        return new DependencyObjectProvider(descriptor, requestingBeanName);
    } else if (javaxInjectProviderClass == descriptor.getDependencyType()) {
        // 支持javax.inject.Provider
        return new Jsr330ProviderFactory().createDependencyProvider(descriptor, requestingBeanName);
    } else {
        Object result = this.getAutowireCandidateResolver().getLazyResolutionProxyIfNecessary(descriptor, requestingBeanName);
        if (result == null) {
            // 通用处理逻辑
            result = this.doResolveDependency(descriptor, requestingBeanName, autowiredBeanNames, typeConverter);
        }
        return result;
    }
}
public Object doResolveDependency(
        DependencyDescriptor descriptor, String beanName, Set<String> autowiredBeanNames, TypeConverter typeConverter)
        throws BeansException {

    InjectionPoint previousInjectionPoint = ConstructorResolver.setCurrentInjectionPoint(descriptor);
    try {
        // 快速处理
        Object shortcut = descriptor.resolveShortcut(this);
        if (shortcut != null) {
            return shortcut;
        }

        // 如果是@Value注解，获取并返回对应的值
        Class<?> type = descriptor.getDependencyType();
        Object value = this.getAutowireCandidateResolver().getSuggestedValue(descriptor);
        if (value != null) {
            if (value instanceof String) {
                String strVal = this.resolveEmbeddedValue((String) value);
                BeanDefinition bd = (beanName != null && this.containsBean(beanName) ? this.getMergedBeanDefinition(beanName) : null);
                // 如果value是一个表达式，则解析表达式所指代的值
                value = this.evaluateBeanDefinitionString(strVal, bd);
            }
            // 类型转换并返回
            TypeConverter converter = (typeConverter != null ? typeConverter : this.getTypeConverter());
            return (descriptor.getField() != null ?
                    converter.convertIfNecessary(value, type, descriptor.getField()) :
                    converter.convertIfNecessary(value, type, descriptor.getMethodParameter()));
        }

        // 尝试解析数组、集合类型
        Object multipleBeans = this.resolveMultipleBeans(descriptor, beanName, autowiredBeanNames, typeConverter);
        if (multipleBeans != null) {
            return multipleBeans;
        }

        // 获取匹配类型的bean实例
        Map<String, Object> matchingBeans = this.findAutowireCandidates(beanName, type, descriptor);
        if (matchingBeans.isEmpty()) {
            if (descriptor.isRequired()) {
                this.raiseNoMatchingBeanFound(type, descriptor.getResolvableType(), descriptor);
            }
            return null;
        }

        String autowiredBeanName;
        Object instanceCandidate;
        // 存在多个匹配项
        if (matchingBeans.size() > 1) {
            // 基于优先级配置来唯一确定注入的bean
            autowiredBeanName = this.determineAutowireCandidate(matchingBeans, descriptor);
            if (autowiredBeanName == null) {
                if (descriptor.isRequired() || !this.indicatesMultipleBeans(type)) {
                    return descriptor.resolveNotUnique(type, matchingBeans);
                } else {
                    return null;
                }
            }
            instanceCandidate = matchingBeans.get(autowiredBeanName);
        } else {
            // 存在唯一的匹配
            Map.Entry<String, Object> entry = matchingBeans.entrySet().iterator().next();
            autowiredBeanName = entry.getKey();
            instanceCandidate = entry.getValue();
        }

        if (autowiredBeanNames != null) {
            autowiredBeanNames.add(autowiredBeanName);
        }
        // 如果不是目标bean实例（比如工厂bean），需要进一步获取所指带的实例
        return (instanceCandidate instanceof Class ?
                descriptor.resolveCandidate(autowiredBeanName, type, this) : instanceCandidate);
    } finally {
        ConstructorResolver.setCurrentInjectionPoint(previousInjectionPoint);
    }
}
```

整个解析的过程还是比较清晰的，首先会依次以确定的 `@Value` 注解和集合类型进行解析，如果不是这些类型，则获取匹配类型的 bean 实例集合，如果存在多个匹配，则尝试以优先级配置（比如 Primary 或 Priority）来确定首选的 bean 实例，如果仅存在唯一的匹配，则无需做推断逻辑，最后会检测当前解析得到的 bean 是不是目标 bean 实例，如果是工厂一类的 bean，则还要继续获取工厂所指代的 bean 实例。

- **applyPropertyValues**

在这一步才真正将 bean 的所有属性全部注入到 bean 实例中，之前虽然已经创建了实例，但是属性仍然存在于 beanDefinition 实例中，applyPropertyValues 会将相应属性转换成 bean 中对应属性的真实类型注入到对应属性上：

```java
protected void applyPropertyValues(String beanName, BeanDefinition mbd, BeanWrapper bw, PropertyValues pvs) {
    if (pvs == null || pvs.isEmpty()) {
        return;
    }

    MutablePropertyValues mpvs = null;
    List<PropertyValue> original;

    if (System.getSecurityManager() != null) {
        if (bw instanceof BeanWrapperImpl) {
            ((BeanWrapperImpl) bw).setSecurityContext(this.getAccessControlContext());
        }
    }

    if (pvs instanceof MutablePropertyValues) {
        mpvs = (MutablePropertyValues) pvs;
        if (mpvs.isConverted()) {
            // 之前已经被转换为对应的类型，那么可以直接设置到beanWrapper
            try {
                bw.setPropertyValues(mpvs);
                return;
            } catch (BeansException ex) {
                throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Error setting property values", ex);
            }
        }
        // 未被转换，记录到original进行转换
        original = mpvs.getPropertyValueList();
    } else {
        // 否则，使用原始的属性获取方法
        original = Arrays.asList(pvs.getPropertyValues());
    }

    TypeConverter converter = this.getCustomTypeConverter();
    if (converter == null) {
        converter = bw;
    }

    // 获取对应的解析器
    BeanDefinitionValueResolver valueResolver = new BeanDefinitionValueResolver(this, beanName, mbd, converter);

    List<PropertyValue> deepCopy = new ArrayList<PropertyValue>(original.size());
    boolean resolveNecessary = false;
    // 遍历属性，将属性转换成对应类的属性类型
    for (PropertyValue pv : original) {
        if (pv.isConverted()) {
            deepCopy.add(pv);
        } else {
            // 执行类型转换
            String propertyName = pv.getName();
            Object originalValue = pv.getValue();
            Object resolvedValue = valueResolver.resolveValueIfNecessary(pv, originalValue);
            Object convertedValue = resolvedValue;
            boolean convertible = bw.isWritableProperty(propertyName) && !PropertyAccessorUtils.isNestedOrIndexedProperty(propertyName);
            if (convertible) {
                // 转换
                convertedValue = this.convertForProperty(resolvedValue, propertyName, bw, converter);
            }

            if (resolvedValue == originalValue) {
                // 转换后的value等于原始值
                if (convertible) {
                    pv.setConvertedValue(convertedValue);
                }
                deepCopy.add(pv);
            } else if (convertible && originalValue instanceof TypedStringValue &&
                    !((TypedStringValue) originalValue).isDynamic() &&
                    !(convertedValue instanceof Collection || ObjectUtils.isArray(convertedValue))) {
                // 转换后的类型是集合或数组
                pv.setConvertedValue(convertedValue);
                deepCopy.add(pv);
            } else {
                // 未解析完全，标记需要解析
                resolveNecessary = true;
                deepCopy.add(new PropertyValue(pv, convertedValue));
            }
        }
    }
    if (mpvs != null && !resolveNecessary) {
        mpvs.setConverted(); // 标记为已全部转换
    }

    try {
        // 深拷贝
        bw.setPropertyValues(new MutablePropertyValues(deepCopy));
    } catch (BeansException ex) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName, "Error setting property values", ex);
    }
}
```

完成了属性注入，接下来容器会执行我们所熟知的 init-method 方法，不过 Spring 并不是单纯的调用一下对应的初始化方法，在整一个初始化方法 initializeBean 中，容器主要做了 4 件事情：

> 1. 激活 bean 实现的 Aware 类：BeanNameAware, BeanClassLoaderAware, BeanFactoryAware
> 2. 应用 BeanPostProcessor 的 postProcessBeforeInitialization
> 3. 激活用户自定义的 init-method 方法，以及常用的 afterPropertiesSet 方法
> 4. 应用 BeanPostProcessor 的 postProcessAfterInitialization

```java
protected Object initializeBean(final String beanName, final Object bean, RootBeanDefinition mbd) {
    // 1. 激活bean实现的Aware类：BeanNameAware, BeanClassLoaderAware, BeanFactoryAware
    if (System.getSecurityManager() != null) {
        AccessController.doPrivileged(new PrivilegedAction<Object>() {
            @Override
            public Object run() {
                invokeAwareMethods(beanName, bean);
                return null;
            }
        }, getAccessControlContext());
    } else {
        this.invokeAwareMethods(beanName, bean);
    }

    // 2. 应用 BeanPostProcessor 的 postProcessBeforeInitialization
    Object wrappedBean = bean;
    if (mbd == null || !mbd.isSynthetic()) {
        wrappedBean = this.applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
    }

    // 3. 激活用户自定义的 init-method 方法，以及常用的 afterPropertiesSet 方法
    try {
        this.invokeInitMethods(beanName, wrappedBean, mbd);
    } catch (Throwable ex) {
        throw new BeanCreationException((mbd != null ? mbd.getResourceDescription() : null), beanName, "Invocation of init method failed", ex);
    }

    // 4. 应用 BeanPostProcessor 的 postProcessAfterInitialization
    if (mbd == null || !mbd.isSynthetic()) {
        wrappedBean = this.applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
    }
    return wrappedBean;
}
```

**6. 基于依存关系验证是否存在循环依赖**

存在循环依赖会导致容器中存在残缺的 bean，这对于使用 Spring 框架的系统来说是一个极大的隐患，所以在这里最后再检测一次，确保所有需要实例化的 bean 都完成了对象的创建和初始化过程，否则系统不应该正常启动。

**7. 注册 DisposableBean**

Spring 允许单例或自定义作用域的 bean 实现 DisposableBean 接口：

```java
public interface DisposableBean {

    /**
     * Invoked by a BeanFactory on destruction of a singleton.
     *
     * @throws Exception in case of shutdown errors.
     *                   Exceptions will get logged but not rethrown to allow
     *                   other beans to release their resources too.
     */
    void destroy() throws Exception;

}
```

从而在销毁对应的 bean 时能够回调实现的 destroy 方法，从而为销毁前的处理工作提供了入口，容器会利用一个 Map 集合来记录所有实现了 DisposableBean 接口的 bean：

```java
protected void registerDisposableBeanIfNecessary(String beanName, Object bean, RootBeanDefinition mbd) {
    AccessControlContext acc = (System.getSecurityManager() != null ? getAccessControlContext() : null);
    if (!mbd.isPrototype() && this.requiresDestruction(bean, mbd)) {
        // 非原型，且需要执行销毁前的处理工作
        if (mbd.isSingleton()) {
            // 单例，注册bean到disposableBeans集合
            this.registerDisposableBean(beanName, new DisposableBeanAdapter(bean, beanName, mbd, this.getBeanPostProcessors(), acc));
        } else {
            // 自定义的scope
            Scope scope = this.scopes.get(mbd.getScope());
            if (scope == null) {
                throw new IllegalStateException("No Scope registered for scope name '" + mbd.getScope() + "'");
            }
            scope.registerDestructionCallback(beanName, new DisposableBeanAdapter(bean, beanName, mbd, getBeanPostProcessors(), acc));
        }
    }
}
```

当我们在调用 destroySingleton 销毁 bean 的时候，容器就会尝试从 DisposableBean 集合中获取当前待销毁 bean 对应的 DisposableBean 实例，如果存在则调用 destroy 方法，执行其中的自定义逻辑。

### 创建原型对象

创建和初始化过程调用的 createBean 方法同单例对象，不再重复撰述。

### 创建其它作用域对象

创建和初始化过程调用的 createBean 方法同单例对象，不再重复撰述。

## 类型检查和转换

我们在 getBean 的时候可以指定我们期望的返回类型 `getBean(String name, Class requiredType)`，如果我们指定了那么容器在创建和初始化 bean 的最后一步需要执行类型校验，并尝试将不是期望类型的 bean 实例转换成期望类型：

```java
// 检查需要的类型是否符合bean的实际类型，对应getBean时指定的requireType
if (requiredType != null && bean != null && !requiredType.isAssignableFrom(bean.getClass())) {
    try {
        // 执行类型转换，转换成期望的类型
        return this.getTypeConverter().convertIfNecessary(bean, requiredType);
    } catch (TypeMismatchException ex) {
        if (logger.isDebugEnabled()) {
            logger.debug("Failed to convert bean '" + name + "' to required type '" + ClassUtils.getQualifiedName(requiredType) + "'", ex);
        }
        throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
    }
}
```

这个转换的过程还是比较复杂的，鉴于本篇已经写的够长了，就不再展开啦。

## 来源

https://my.oschina.net/wangzhenchao/blog/918237

