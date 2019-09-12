---

title: 8_java动态编译

date: 2019-09-11 14:40:39

categories: [语言,java,java基础]

tags: [java]

---

本文简单介绍 java 动态编译。 

<!--more-->

### 动态编译过程

![动态编译过程](/images/8_java动态编译/动态编译过程.png)

## 相关类介绍

### JavaCompiler

JavaCompiler 为动态编译的入口。JavaCompiler的实现类，可以通过如下语句获取

```java
JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
```

### JavaFileObject

在编译过程中，通常需要容器存储 java源文件 和 class文件。JavaFileObject 就是这个容器。

JavaFileObject 有一个 kind 字段，分为以下四种:

```java
enum Kind {
    SOURCE(".java"),  // java 源文件
    CLASS(".class"),  // jvm 能识别的 class 文件
    HTML(".html"),   
    OTHER("");
}
```

### DiagnosticCollector

DiagnosticCollector 为编译的诊断器，当编译结果为失败时，可以通过该类获取 编译失败的原因.

```java
    private String simplifyDiagnostic(DiagnosticCollector<JavaFileObject> collector) {
        StringBuilder builder = new StringBuilder();
        for (Diagnostic<? extends JavaFileObject> diagnostic : collector.getDiagnostics()) {
            builder.append("编译出错原因: ")
                    .append(diagnostic.getMessage(Locale.getDefault())).append("\n")
                    .append("  行数 ").append(diagnostic.getLineNumber()).append("\n")
                    .append("  列数 ").append(diagnostic.getColumnNumber()).append("\n")
                    .append("\n");
        }
        return builder.toString();
    }
```

### JavaFileManager

JavaFileManager 用来创建JavaFileObject，包括从特定位置输出和输入一个 JavaFileObject。

如: 在编译过程中，编译器会通过 JavaFileManager.getJavaFileForOutput() 方法创建一个 JavaFileObject 对象，然后将编译成功的 class 信息写入新生成的 JavaFileObject 中

在 jdk 中有个默认的 JavacFileManager 实现，它会将编译得到的 class 以本地文件的实现保存下来。

如果我们想要实现内存形式的JavaFileManager，我们可以继承 ForwardingJavaFileManager ，并重写 getJavaFileForOutput() 方法。

```java
/**
 * 用于管理 编译生成的 Class 类:
 * <p>
 * 自定义了一个 classMap 字段。该字段用于存储 编译生成的 Class 类
 */
public class MemJavaFileManager extends ForwardingJavaFileManager<JavaFileManager> {
    private Map<String, CharSequenceJavaFileObject> javaFileObjectMap;

    public MemJavaFileManager(JavaFileManager fileManager) {
        super(fileManager);
        javaFileObjectMap = new ConcurrentHashMap<>();
    }

    /**
     * 返回一个 JavaFileObject。在之后的阶段，生成的class字节码会被写入该 JavaFileObject 中。
     */
    @Override
    public JavaFileObject getJavaFileForOutput(Location location, String qualifiedClassName, JavaFileObject.Kind kind, FileObject sibling) {
        CharSequenceJavaFileObject javaFileObject = new CharSequenceJavaFileObject(qualifiedClassName, kind);
        javaFileObjectMap.put(qualifiedClassName, javaFileObject);
        return javaFileObject;
    }

    /**
     * 在 CompilationTask 执行完后，可以通过该方法获取 编译后的
     */
    public Map<String, byte[]> getClassMap() {
        Map<String, byte[]> map = new HashMap<>();
        javaFileObjectMap.forEach(
                (k, v) -> map.put(k, v.getCompiledBytes())
        );
        return map;
    }
}
```

### ClassLoader

在动态编译完成之后，我们需要将其加载到JVM中使用。因此我们需要自定义一个类加载器用于加载 class。

自定义的类加载器，牵扯到双亲委派机制。这个坑暂时先留着。

```java
package zl.compiler.hot;

import java.util.Map;

/**
 * 自定义了一个 ClassLoader，用于加载 动态编译生成的 class
 * <p>
 * classMap 字段: 保存 class 字节码
 */
public class HotClassLoader extends ClassLoader {

    private Map<String, byte[]> classMap;

   public HotClassLoader(Map<String, byte[]> classMap) {
        this.classMap = classMap;
    }

    /**
     * 在调用 loadClass() 时，
     * 如果父类无法加载该类，则会使用 findClass() 加载类。
     */
    @Override
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        byte[] bytes = classMap.get(name);
        if (bytes != null) {
            return defineClass(name, bytes, 0, bytes.length);
        }
        throw new ClassNotFoundException("源文件中找不到类:" + name);
    }
}

```

## 实例

见 github https://github.com/longzl2015/compiler



## 参考资料

[JavaCompilerAPI中文指南](http://pfmiles.github.io/blog/dynamic-java/)

