---

title: arthas 运维监控

date: 2018-09-25 10:21:00

categories: [linux,命令]

tags: [linux]

---

alibaba 开源的一个jvm监控软件，能够 

- 反编译运行中的java程序的代码，
- 查看java程序的内存、
- 查看java程序的线程
- 查看类的静态变量值
- 查看classloader的继承树，urls，类加载信息
- 等等



https://alibaba.github.io/arthas/sysenv.html

下面为精简的常用接口

### 查看类的静态属性 

```
$ getstatic demo.MathGame random
field: random
@Random[
    serialVersionUID=@Long[3905348978240129619],
    seed=@AtomicLong[120955813885284],
    multiplier=@Long[25214903917],
    addend=@Long[11],
    mask=@Long[281474976710655],
    DOUBLE_UNIT=@Double[1.1102230246251565E-16],
    BadBound=@String[bound must be positive],
    BadRange=@String[bound must be greater than origin],
    BadSize=@String[size must be non-negative],
    seedUniquifier=@AtomicLong[-3282039941672302964],
    nextNextGaussian=@Double[0.0],
    haveNextNextGaussian=@Boolean[false],
    serialPersistentFields=@ObjectStreamField[][isEmpty=false;size=3],
    unsafe=@Unsafe[sun.misc.Unsafe@2eaa1027],
    seedOffset=@Long[24],
]
```

### 打印出类的Field信息

该方法只能获取 类信息，无法获取实例信息

```
$ sc -d -f demo.MathGame
class-info        demo.MathGame
code-source       /private/tmp/arthas-demo.jar
name              demo.MathGame
isInterface       false
isAnnotation      false
isEnum            false
isAnonymousClass  false
isArray           false
isLocalClass      false
isMemberClass     false
isPrimitive       false
isSynthetic       false
simple-name       MathGame
modifier          public
annotation
interfaces
super-class       +-java.lang.Object
class-loader      +-sun.misc.Launcher$AppClassLoader@3d4eac69
                    +-sun.misc.Launcher$ExtClassLoader@66350f69
classLoaderHash   3d4eac69
fields            modifierprivate,static
                  type    java.util.Random
                  name    random
                  value   java.util.Random@522b4
                          08a
 
                  modifierprivate
                  type    int
                  name    illegalArgumentCount
 
Affect(row-cnt:1) cost in 19 ms.
```

### 反编译指定已加载类的源码

```
jad demo.MathGame
```

### 查看ClassLoader的继承树

```
$ classloader -t
+-BootstrapClassLoader
+-sun.misc.Launcher$ExtClassLoader@66350f69
  +-com.taobao.arthas.agent.ArthasClassloader@68b31f0a
  +-sun.misc.Launcher$AppClassLoader@3d4eac69
Affect(row-cnt:4) cost in 3 ms.
```

### 使用ClassLoader去查找resource

```
$ classloader -c 3d4eac69  -r META-INF/MANIFEST.MF
 jar:file:/System/Library/Java/Extensions/MRJToolkit.jar!/META-INF/MANIFEST.MF
 jar:file:/private/tmp/arthas-demo.jar!/META-INF/MANIFEST.MF
 jar:file:/Users/hengyunabc/.arthas/lib/3.0.5/arthas/arthas-agent.jar!/META-INF/MANIFEST.MF
```

### 观察方法调用前和方法返回后

watch 命令 具体 https://alibaba.github.io/arthas/watch.html

### 输出当前方法被调用的调用路径

```
$ stack demo.MathGame primeFactors 'params[0]<0' -n 2
Press Ctrl+C to abort.
Affect(class-cnt:1 , method-cnt:1) cost in 30 ms.
ts=2018-12-04 01:34:27;thread_name=main;id=1;is_daemon=false;priority=5;TCCL=sun.misc.Launcher$AppClassLoader@3d4eac69
    @demo.MathGame.run()
        at demo.MathGame.main(MathGame.java:16)
 
ts=2018-12-04 01:34:30;thread_name=main;id=1;is_daemon=false;priority=5;TCCL=sun.misc.Launcher$AppClassLoader@3d4eac69
    @demo.MathGame.run()
        at demo.MathGame.main(MathGame.java:16)
 
Command execution times exceed limit: 2, so command will exit. You can set it with -n option.

```

### 排查 method not found

先通过sc获取当前类的来源，执行以下命令后 查看 `code-source` 信息

> sc -d 类名

使用 jad 反编译 代码，确认方法是否存在。

> jad 类名

使用maven排查依赖



### 其他实践

- http://localhost:8080/user/0 500

> watch com.example.demo.arthas.user.UserController * '{params, throwExp} –e

- http://localhost:8080/a.txt 404
  
> trace javax.servlet.Servlet * > servlet.txt # 结果在 ~/logs/arthas-cache/

- http://localhost:8080/admin 401
  
> trace javax.servlet.Filter *

- 动态修复代码/测试
  
> redefine –p UserController.class

- UserController的logger是什么实现？

> ognl '@com.example.demo.arthas.user.UserController@logger'

-  动态修改logger级别

> ognl '@org.slf4j.LoggerFactory@getLogger("root").setLevel(@ch.qos.logback.classic.Level@DEBUG)'

- 查找冲突的logback.xml/log4j.properties

> classloader -c 18b4aac2 -r logback.xml 

- Spring Boot应用的Classloader结构

> classloader –t
> classloader -a -c 758f7d25

- jad反编绎jsp的实现

> jad org.apache.jsp.jsp.hello_jsp

- tt 获取Spring Context

> tt -t org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter invokeHandlerMethod

> tt -i 1000 -w 'target.getApplicationContext().getBean("helloWorldService").getHelloMessage()'

[http://hengyunabc.github.io/spring-boot-inside/](http://hengyunabc.github.io/spring-boot-inside/)