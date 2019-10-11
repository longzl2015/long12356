---

title: springboot-7-fat_jar启动过程

date: 2019-08-05 00:00:06

categories: [spring,springboot]

tags: [springboot]

---



有关 `fat_jar结构与原理` 的部分，[官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/executable-jar.html)描述的比较详细了。因此本文是对官方文档的简单补充。

<!--more-->

## Launcher

`springboot应用的fatjar启动方式` 并不是通过应用程序的主类直接启动的，而是通过Launcher代理启动的。

Launcher 有三种子类: JarLauncher、WarLauncher、PropertiesLauncher。

- JarLauncher: 加载 `BOOT-INF/lib/`下的类
- WarLauncher: 加载 `WEB-INF/lib/`和`WEB-INF/lib-provided/`下的类
- PropertiesLauncher: 加载 `BOOT-INF/lib/`下的类，同时可以使用 `loader.path` 添加更多的类扫描路径

![launcher](/images/springboot-7-fat_jar启动过程/bV4Tu5.png)

下面以JarLauncher为例，简单介绍下springboot的启动过程。

###JarLauncher

JarLauncher 的源码非常简单: 

```java
public class JarLauncher extends ExecutableArchiveLauncher {
  //应用源码编译得到的 .class 文件
	static final String BOOT_INF_CLASSES = "BOOT-INF/classes/";
  //应用依赖第各种jar
	static final String BOOT_INF_LIB = "BOOT-INF/lib/";

	public JarLauncher() {
	}

	protected JarLauncher(Archive archive) {
		super(archive);
	}

  //用于过滤，获取jar中的嵌套资源
	@Override
	protected boolean isNestedArchive(Archive.Entry entry) {
		if (entry.isDirectory()) {
			return entry.getName().equals(BOOT_INF_CLASSES);
		}
		return entry.getName().startsWith(BOOT_INF_LIB);
	}
  // main 启动入口
	public static void main(String[] args) throws Exception {
		new JarLauncher().launch(args);
	}
}
```

Launcher.launch() 源码

```java
public abstract class Launcher {

	protected void launch(String[] args) throws Exception {
    //注册自定义URL处理器，用于支持包含多个'!/'的url，以实现jar in jar的资源识别
		JarFile.registerUrlProtocolHandler();
    //自定义ClassLoader(即LaunchedURLClassLoader)，
    //用于加载 "BOOT-INF/classes/" 和 "BOOT-INF/lib/" 中的资源
		ClassLoader classLoader = createClassLoader(getClassPathArchives());
    //通过反射方式运行 springboot 应用的主类。
		launch(args, getMainClass(), classLoader);
	}
  
	protected ClassLoader createClassLoader(List<Archive> archives) throws Exception {
		List<URL> urls = new ArrayList<>(archives.size());
		for (Archive archive : archives) {
			urls.add(archive.getUrl());
		}
		return createClassLoader(urls.toArray(new URL[0]));
	}
	protected ClassLoader createClassLoader(URL[] urls) throws Exception {
		return new LaunchedURLClassLoader(urls, getClass().getClassLoader());
	}
  
	protected void launch(String[] args, String mainClass, ClassLoader classLoader) throws Exception {
    //将 LaunchedURLClassLoader 放入线程上下文中
		Thread.currentThread().setContextClassLoader(classLoader);
		createMainMethodRunner(mainClass, args, classLoader).run();
	}
  //使用线程上下文中的LaunchedURLClassLoader， 并反射运行springboot应用的主类
	protected MainMethodRunner createMainMethodRunner(String mainClass, String[] args, ClassLoader classLoader) {
		return new MainMethodRunner(mainClass, args);
	}
  //获得spring应用的启动类 对应MANIFEST.MF中的 Start-Class
	protected abstract String getMainClass() throws Exception;

	protected abstract List<Archive> getClassPathArchives() throws Exception;
  
  //获取到包含该类的jar包路径，并生成 JarFileArchive
	protected final Archive createArchive() throws Exception {
		ProtectionDomain protectionDomain = getClass().getProtectionDomain();
		CodeSource codeSource = protectionDomain.getCodeSource();
		URI location = (codeSource != null) ? codeSource.getLocation().toURI() : null;
		String path = (location != null) ? location.getSchemeSpecificPart() : null;
		if (path == null) {
			throw new IllegalStateException("Unable to determine code source archive");
		}
		File root = new File(path);
		if (!root.exists()) {
			throw new IllegalStateException("Unable to determine code source archive from " + root);
		}
		return (root.isDirectory() ? new ExplodedArchive(root) : new JarFileArchive(root));
	}

}
```

###PropertiesLauncher

有关PropertiesLauncher 更详细的配置 可以 翻看 [官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/executable-jar.html#executable-jar-property-launcher-features) 。





## 参考

https://docs.spring.io/spring-boot/docs/current/reference/html/executable-jar.html

https://segmentfault.com/a/1190000013532009