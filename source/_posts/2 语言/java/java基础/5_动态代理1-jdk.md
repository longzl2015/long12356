---
title: 5_动态代理1-jdk
date: 2016-09-11 03:30:09
tags: [动态代理,java]
categories: [语言,java,java基础]
---


JDK动态代理可以在`运行期间`创建一个代理类，这个代理类实现了一组给定的`接口`方法。

当调用这个代理类的接口方法时，这个调用都会被定向到 InvocationHandler.invoke()方法。在这个invoke方法中，我们可以添加任何逻辑，如打印日志、安全检查等等。
之后，invoke方法会调用真实对象的方法。

动态代理是基于接口实现代理类的。因此当被代理对象没有继承接口时，JDK动态代理就无法使用，这时可以使用 CGLIB 代理，关于CGLIB 代理在下一章中介绍。

<!--more-->

## 主要构成

JDK动态代理主要有 `Proxy类的newProxyInstance(...)方法` 和 `实现InvocationHandler接口` 这两个要点。

### Proxy类的newProxyInstance()方法

```java
public static Object newProxyInstance(
  ClassLoader loader,
  Class<?>[] interfaces,
  InvocationHandler h){
  //...
}
```

newProxyInstance()方法用于根据传入的接口类型 interfaces 返回一个动态创建的代理类的实例，方法的参数解释

- 第一个参数loader表示代理类的类加载器，
- 第二个参数interfaces表示被代理类实现的接口列表，
- 第三个参数h表示所指派的调用处理程序类InvocationHandler。

### InvocationHandler接口的 invoke() 方法

实现InvocationHandler接口主要是重写 invoke 方法，在invoke 方法中，可以添加任何逻辑，如打印日志、安全检查等等。
如果不进行拦截的话，一定要 调用 `Object invoke = method.invoke(target, args);`来执行真正的方法

## 简单例子

![jdk动态代理](/images/5 动态代理1-jdk/jdk动态代理.png)

主题接口类：

```java
public interface IHello {
    public void sayHello();
}
```

被代理的真实类：

```java

public class Hello implements IHello{

    public void sayHello() {
        System.out.println("hello!");
    }
}
```

JDK动态代理类必须管理一个 InvocationHandler 类。

```java

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class MyInvocationHandler implements InvocationHandler {
    private Object target;//委托类
    public MyInvocationHandler(Object target){
        this.target=target;
    }

    @Override
    public Object invoke(Object target, Method method, Object[] args) throws Throwable {
        /**代理环绕**/
        //执行实际的方法
        Object invoke = method.invoke(target, args);
        return invoke;
    }
}
```

测试代码

```java
import java.lang.reflect.Proxy;

public class Test {

    public static void main(String[] args){
        //需要代理的对象
        IHello hello = new Hello();
        InvocationHandler handler = new MyInvocationHandler(hello);
        
        IHello  ihello = (IHello) Proxy.newProxyInstance(handler.getClass().getClassLoader(),  
                hello.getClass().getInterfaces(),     
                handler);
        ihello.sayHello();
    }
}
```

## Proxy 源码

```java
public class Proxy implements java.io.Serializable {
    // ...
     public static Object newProxyInstance(ClassLoader loader,
                                              Class<?>[] interfaces,
                                              InvocationHandler h)
        throws IllegalArgumentException {
         
        Objects.requireNonNull(h);
        
        final Class<?>[] intfs = interfaces.clone();
        // 安全管理器，默认是关闭状态
        final SecurityManager sm = System.getSecurityManager();
        if (sm != null) {
            checkProxyAccess(Reflection.getCallerClass(), loader, intfs);
        }

        // 查找或者生产特定的类，
        // todo 具体细节
        Class<?> cl = getProxyClass0(loader, intfs);

        /*
         * Invoke its constructor with the designated invocation handler.
         */
        try {
            if (sm != null) {
                checkNewProxyPermission(Reflection.getCallerClass(), cl);
            }

            // 获取 InvocationHandler 构造器
            final Constructor<?> cons = cl.getConstructor(constructorParams);
            final InvocationHandler ih = h;
            // 如果修饰符不为 public，则 跳过 权限检查。
            if (!Modifier.isPublic(cl.getModifiers())) {
                AccessController.doPrivileged(new PrivilegedAction<Void>() {
                    public Void run() {
                        cons.setAccessible(true);
                        return null;
                    }
                });
            }
            // 根据代理类的构造函数来创建代理对象
            return cons.newInstance(new Object[]{h});
        } catch (IllegalAccessException|InstantiationException e) {
            throw new InternalError(e.toString(), e);
        } catch (InvocationTargetException e) {
            Throwable t = e.getCause();
            if (t instanceof RuntimeException) {
                throw (RuntimeException) t;
            } else {
                throw new InternalError(t.toString(), t);
            }
        } catch (NoSuchMethodException e) {
            throw new InternalError(e.toString(), e);
        }
    }
    
    private static Class<?> getProxyClass0(ClassLoader loader,
                                           Class<?>... interfaces) {
         //接口数不超过65535
        if (interfaces.length > 65535) {
            throw new IllegalArgumentException("interface limit exceeded");
        }

        // If the proxy class defined by the given loader implementing
        // the given interfaces exists, this will simply return the cached copy;
        // otherwise, it will create the proxy class via the ProxyClassFactory
        // 如果该代理类已经存在了，那么他会直接返回缓存拷贝
        // 如果不存在，他会通过 ProxyClassFactory 创建一个。
        return proxyClassCache.get(loader, interfaces);
    }    
}
```

## 生成代理类的字节码，并保存

### 如何生成 

```java
public interface IUser {
    void add();
    String update(String aa);
}

public class Main {
    public static void main(String[] args) {
        String proxyName = "Ttest";
        Class<?>[] interfaces = {IUser.class};

        byte[] classFile = ProxyGenerator.generateProxyClass(proxyName, interfaces);
        String paths = IUser.class.getResource(".").getPath();
        System.out.println(paths);

        try (FileOutputStream out = new FileOutputStream(paths + proxyName + ".class")) {
            out.write(classFile);
            out.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

### 生成结果

```java
public final class Ttest extends Proxy implements IUser {
    private static Method m1;
    private static Method m2;
    private static Method m3;
    private static Method m4;
    private static Method m0;

    public Ttest(InvocationHandler var1) throws  {
        super(var1);
    }

    public final boolean equals(Object var1) throws  {
        try {
            return (Boolean)super.h.invoke(this, m1, new Object[]{var1});
        } catch (RuntimeException | Error var3) {
            throw var3;
        } catch (Throwable var4) {
            throw new UndeclaredThrowableException(var4);
        }
    }

    public final String toString() throws  {
        try {
            return (String)super.h.invoke(this, m2, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    public final void add() throws  {
        try {
            super.h.invoke(this, m3, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    public final String update(String var1) throws  {
        try {
            return (String)super.h.invoke(this, m4, new Object[]{var1});
        } catch (RuntimeException | Error var3) {
            throw var3;
        } catch (Throwable var4) {
            throw new UndeclaredThrowableException(var4);
        }
    }

    public final int hashCode() throws  {
        try {
            return (Integer)super.h.invoke(this, m0, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    static {
        try {
            m1 = Class.forName("java.lang.Object").getMethod("equals", Class.forName("java.lang.Object"));
            m2 = Class.forName("java.lang.Object").getMethod("toString");
            m3 = Class.forName("IUser").getMethod("add");
            m4 = Class.forName("IUser").getMethod("update", Class.forName("java.lang.String"));
            m0 = Class.forName("java.lang.Object").getMethod("hashCode");
        } catch (NoSuchMethodException var2) {
            throw new NoSuchMethodError(var2.getMessage());
        } catch (ClassNotFoundException var3) {
            throw new NoClassDefFoundError(var3.getMessage());
        }
    }
}

```

## 来源

https://blog.csdn.net/mantantan/article/details/51873755
https://www.jianshu.com/p/1a87323164f5