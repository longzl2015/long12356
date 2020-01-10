---

title: springboot-热部署原理-转

date: 2019-10-14 09:00:06

categories: [spring,springboot]

tags: [springboot,热启动]

---

DevTools 为我们提供的支持 Spring Boot应用热部署的功能，无需手动重启Spring Boot应用，可以极大提高开发效率。

<!--more-->

## 如何使用
使用很方便，在应用的pom.xml中增加依赖即可。

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-devtools</artifactId>
        <optional>true</optional>
    </dependency>
</dependencies>
```

既然是 「Dev」Tool，开发的也比较机智，只在开发环境用，生产环境就自动停用了。判断生产环境的方便是是否通过 java -jar的方式启动，或者是「自定义的ClassLoader」。而且一般也推荐依赖的时候做为optional。
然后在项目中修改你的应用代码，你就会发现应用自动重新部署了。但是分明比你自己重新启动要快好多。

## 怎么做到的，为什么快?

带着这个疑问，我们一起看下 DevTools的工作原理。

在 SpringBoot 的主类 启动 SpringApplication 时，会产生一系列的事件，通过观察者模式，进行 multicastEvent ，这一系列事件会广播到各个Listener。
在增加 DevTools依赖后，这些 Listener 中，会有一个RestartApplicationListener。
它在事件通知时会干啥呢？

```java
private void onApplicationStartingEvent(ApplicationStartingEvent event) {
    String enabled = System.getProperty("spring.devtools.restart.enabled");
    if(enabled != null && !Boolean.parseBoolean(enabled)) {
        Restarter.disable();
    } else {
        String[] args = event.getArgs();
        DefaultRestartInitializer initializer = new DefaultRestartInitializer();
        boolean restartOnInitialize = !AgentReloader.isActive();
        Restarter.initialize(args, false, initializer, restartOnInitialize);
    }
}
```

我们看到，这里会初始化一个Restarter。初始化的时候，会使用到著名的「c双重锁检查」。

下面的代码，就是初始化时的 DCL。

```java
public static void initialize(String[] args, boolean forceReferenceCleanup, RestartInitializer initializer, boolean restartOnInitialize) {
    Restarter localInstance = null;
    Object var5 = INSTANCE_MONITOR;
    synchronized(INSTANCE_MONITOR) {
        if(instance == null) {
            localInstance = new Restarter(Thread.currentThread(), args, forceReferenceCleanup, initializer);
            instance = localInstance;
        }
    }
    if(localInstance != null) {
        localInstance.initialize(restartOnInitialize);
    }
}
```

初始化时，会生成 Restarter 的实例，我们看，此时会保存下来一些关键信息，像主类名称，参数等等，请留意，这些是后面重启的要素。
除参数外，还有一个名为LeakSafeThread的重要「人物」以及加载类URL的分类。

```java
protected Restarter(Thread thread, String[] args, boolean forceReferenceCleanup, RestartInitializer initializer) {
    SilentExitExceptionHandler.setup(thread);
    this.forceReferenceCleanup = forceReferenceCleanup;
    this.initialUrls = initializer.getInitialUrls(thread);
    this.mainClassName = this.getMainClassName(thread);
    this.applicationClassLoader = thread.getContextClassLoader();
    this.args = args;
    this.exceptionHandler = thread.getUncaughtExceptionHandler();
    this.leakSafeThreads.add(new Restarter.LeakSafeThread());
}
```

首先，类的加载我们都知道，是通过类加载完成的。类加载去哪里加载类呢？当然是在我们启动时指定的类路径上。为了完成应用的快速启动， DevTools的巧妙之外在于，这里将第三方类库的类和用户自定义的类做了区分。
这里的initialUrls，就是做这个的，他会根据路径判断，将用户自定义类的URL选出来。

```java
private ChangeableUrls(URL... urls) {
    DevToolsSettings settings = DevToolsSettings.get();
    List<URL> reloadableUrls = new ArrayList(urls.length);
    URL[] var4 = urls;
    int var5 = urls.length;

    for(int var6 = 0; var6 < var5; ++var6) {
        URL url = var4[var6];
        if((settings.isRestartInclude(url) || this.isFolderUrl(url.toString())) && !settings.isRestartExclude(url)) {
            reloadableUrls.add(url);
        }
    }

    if(logger.isDebugEnabled()) {
        logger.debug("Matching URLs for reloading : " + reloadableUrls);
    }

    this.urls = Collections.unmodifiableList(reloadableUrls);
}
```

这段代码是从整个项目的加载类路径中找到我们自己的类，也就是非第三方类库，因为这些第
三方的库是不会变的，我们所改的都是自己项目的内容。

然后这里呢，会添加这样一个Thread

> this.leakSafeThreads.add(new Restarter.LeakSafeThread());

这个leakSafeThread是做啥的呢？

这是 Restarter 的一个内部类

```java
private class LeakSafeThread extends Thread {
    private Callable<?> callable;
    private Object result;

    LeakSafeThread() {
        this.setDaemon(false);
    }

    public void call(Callable<?> callable) {
        this.callable = callable;
        this.start();
    }

    public <V> V callAndWait(Callable<V> callable) {
        this.callable = callable;
        this.start(); // 这里把线程自己给启动起来

        try {
            this.join();
            return this.result;
        } catch (InterruptedException var3) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(var3);
        }
    }

    public void run() {
        try {
            Restarter.this.leakSafeThreads.put(Restarter.this.new LeakSafeThread());
            this.result = this.callable.call();
        } catch (Exception var2) {
            var2.printStackTrace();
            System.exit(1);
        }

    }
}
```

那这个线程是什么时候被启动的呢？看一眼前面的初始化内容

```java
if(localInstance != null) {
        localInstance.initialize(restartOnInitialize);
}

protected void initialize(boolean restartOnInitialize) {
    this.preInitializeLeakyClasses();
    if(this.initialUrls != null) {
        this.urls.addAll(Arrays.asList(this.initialUrls));
        if(restartOnInitialize) {
            this.logger.debug("Immediately restarting application");
            this.immediateRestart();
        }
    }

}
```

看，这就和LeakSafeThread串起来了。

```java
private void immediateRestart() {
    try {
        this.getLeakSafeThread().callAndWait(() -> {
            this.start(FailureHandler.NONE);
            this.cleanupCaches();
            return null;
        });
    } catch (Exception var2) {      
    }
}
protected void start(FailureHandler failureHandler) throws Exception {
    Throwable error;
    do {
        error = this.doStart();
        if(error == null) {
            return;
        }
    } while(failureHandler.handle(error) != Outcome.ABORT);

}

private Throwable doStart() throws Exception {
    URL[] urls = (URL[])this.urls.toArray(new URL[0]);
    ClassLoaderFiles updatedFiles = new ClassLoaderFiles(this.classLoaderFiles);
    ClassLoader classLoader = new RestartClassLoader(this.applicationClassLoader, urls, updatedFiles, this.logger);

    return this.relaunch(classLoader);
}
```

重点来了，这里加入了一个新的人物：RestartClassLoader

```java
protected Throwable relaunch(ClassLoader classLoader) throws Exception {
    RestartLauncher launcher = new RestartLauncher(classLoader, this.mainClassName, this.args, this.exceptionHandler);
    launcher.start();
    launcher.join();
    return launcher.getError();
}

class RestartLauncher extends Thread {
    private final String mainClassName;
    private final String[] args;
    private Throwable error;
    RestartLauncher(ClassLoader classLoader, String mainClassName, String[] args, UncaughtExceptionHandler exceptionHandler) {
        this.mainClassName = mainClassName;
        this.args = args;
        this.setName("restartedMain");
        this.setUncaughtExceptionHandler(exceptionHandler);
        this.setDaemon(false);
        this.setContextClassLoader(classLoader);
    }   
}
```

这也是个新的线程，我们看到前面 Restarter 里记下来了MainClass的名字，参数

这里搞了一个新的ClassLoader，然后后面我想你也猜到了

> 反射。

看一眼具体的调用栈：

```text
"restartedMain@2014" prio=5 tid=0xe nid=NA runnable
  java.lang.Thread.State: RUNNABLE
      at org.springframework.boot.devtools.restart.classloader.RestartClassLoader.getResources(RestartClassLoader.java:93)
      at org.springframework.core.io.support.SpringFactoriesLoader.loadSpringFactories(SpringFactoriesLoader.java:130)
      at org.springframework.core.io.support.SpringFactoriesLoader.loadFactoryNames(SpringFactoriesLoader.java:119)
      at org.springframework.boot.SpringApplication.getSpringFactoriesInstances(SpringApplication.java:429)
      at org.springframework.boot.SpringApplication.getSpringFactoriesInstances(SpringApplication.java:421)
      at org.springframework.boot.SpringApplication.<init>(SpringApplication.java:268)
      at org.springframework.boot.SpringApplication.<init>(SpringApplication.java:249)
      at org.springframework.boot.SpringApplication.run(SpringApplication.java:1258)
      at org.springframework.boot.SpringApplication.run(SpringApplication.java:1246)
      at com.finecity.RabbitApplication.main(RabbitApplication.java:21)
      at sun.reflect.NativeMethodAccessorImpl.invoke0(NativeMethodAccessorImpl.java:-1)
      at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
      at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
      at java.lang.reflect.Method.invoke(Method.java:498)
      at org.springframework.boot.devtools.restart.RestartLauncher.run(RestartLauncher.java:49)

Class<?> mainClass = this.getContextClassLoader().loadClass(this.mainClassName);
Method mainMethod = mainClass.getDeclaredMethod("main", new Class[]{String[].class});
mainMethod.invoke((Object)null, new Object[]{this.args});
```


整体的启动不久就完成了，和我们加 DevTools之前的区别是，这里的线程是restartedMain，他已经接管了我们的启动。

## 重部署呢?
那我们对于代码的变更，又是怎样作用到Thread上的呢？修改一个自己的业务代码，你会发现，原来是本地启动了一个File Watcher，看看这个调用栈：

```text
"File Watcher@7244" daemon prio=5 tid=0x1a nid=NA runnable
  java.lang.Thread.State: RUNNABLE
      at org.springframework.boot.devtools.restart.Restarter$LeakSafeThread.call(Restarter.java:612)
      at org.springframework.boot.devtools.restart.Restarter.restart(Restarter.java:251)
      at org.springframework.boot.devtools.autoconfigure.LocalDevToolsAutoConfiguration$RestartConfiguration.onClassPathChanged(LocalDevToolsAutoConfiguration.java:108)
      at sun.reflect.NativeMethodAccessorImpl.invoke0(NativeMethodAccessorImpl.java:-1)
      at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
      at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
      at java.lang.reflect.Method.invoke(Method.java:498)
      at org.springframework.context.event.ApplicationListenerMethodAdapter.doInvoke(ApplicationListenerMethodAdapter.java:261)
      at org.springframework.context.event.ApplicationListenerMethodAdapter.processEvent(ApplicationListenerMethodAdapter.java:180)
      at org.springframework.context.event.ApplicationListenerMethodAdapter.onApplicationEvent(ApplicationListenerMethodAdapter.java:142)
      at org.springframework.context.event.SimpleApplicationEventMulticaster.doInvokeListener(SimpleApplicationEventMulticaster.java:172)
      at org.springframework.context.event.SimpleApplicationEventMulticaster.invokeListener(SimpleApplicationEventMulticaster.java:165)
      at org.springframework.context.event.SimpleApplicationEventMulticaster.multicastEvent(SimpleApplicationEventMulticaster.java:139)
      at org.springframework.context.support.AbstractApplicationContext.publishEvent(AbstractApplicationContext.java:400)
      at org.springframework.context.support.AbstractApplicationContext.publishEvent(AbstractApplicationContext.java:354)
      at org.springframework.boot.devtools.classpath.ClassPathFileChangeListener.publishEvent(ClassPathFileChangeListener.java:68)
      at org.springframework.boot.devtools.classpath.ClassPathFileChangeListener.onChange(ClassPathFileChangeListener.java:64)
      at org.springframework.boot.devtools.filewatch.FileSystemWatcher$Watcher.fireListeners(FileSystemWatcher.java:309)
      at org.springframework.boot.devtools.filewatch.FileSystemWatcher$Watcher.updateSnapshots(FileSystemWatcher.java:302)
      at org.springframework.boot.devtools.filewatch.FileSystemWatcher$Watcher.scan(FileSystemWatcher.java:262)
      at org.springframework.boot.devtools.filewatch.FileSystemWatcher$Watcher.run(FileSystemWatcher.java:242)
      at java.lang.Thread.run(Thread.java:748)
```

此时，会调用到Restarter的 restart方法上

```java
public void restart(FailureHandler failureHandler) {
    if(!this.enabled) {
        this.logger.debug("Application restart is disabled");
    } else {
        this.logger.debug("Restarting application");
        this.getLeakSafeThread().call(() -> {
            this.stop();  // 第一步
            this.start(failureHandler); // 第二步
            return null;
        });
    }
}
```

具体的restart，是先stop，再start，start的过程又和我们前面启动时一样。

```java
protected void stop() throws Exception {
    this.logger.debug("Stopping application");
    this.stopLock.lock();

    try {
        Iterator var1 = this.rootContexts.iterator();

        while(true) {
            if(!var1.hasNext()) {
                this.cleanupCaches();
                if(this.forceReferenceCleanup) {
                    this.forceReferenceCleanup();
                }
                break;
            }

            ConfigurableApplicationContext context = (ConfigurableApplicationContext)var1.next();
            context.close();
            this.rootContexts.remove(context);
        }
    } finally {
        this.stopLock.unlock();
    }

    System.gc();
    System.runFinalization();
}


private Throwable doStart() throws Exception {
    Assert.notNull(this.mainClassName, "Unable to find the main class to restart");
    URL[] urls = (URL[])this.urls.toArray(new URL[0]);
    ClassLoaderFiles updatedFiles = new ClassLoaderFiles(this.classLoaderFiles);
    ClassLoader classLoader = new RestartClassLoader(this.applicationClassLoader, urls, updatedFiles, this.logger);
    if(this.logger.isDebugEnabled()) {
        this.logger.debug("Starting application " + this.mainClassName + " with URLs " + Arrays.asList(urls));
    }

    return this.relaunch(classLoader);
}
```
  
## 总结
整体来说，DevTools能快速热部署，主要在于ClassLoader做了区分，一个加载第三方类，另一个称为RestartClassLoader的加载用户类,这样在有代码更改的时候，原来的ClassLoader 会被清除，进行gc，重新创建一个RestartClassLoader，由于需要加载的类相比较少，所以重启很快。



## 原文地址

https://www.javazhiyin.com/27485.html