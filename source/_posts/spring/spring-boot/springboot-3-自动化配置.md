---

title: springboot-3-自动化配置

date: 2019-08-05 00:00:03

categories: [spring,springboot]

tags: [springboot,自动化配置,AutoConfigure]

---

springboot 自动化配置注解 EnableAutoConfiguration

<!--more-->

##SpringBootApplication注解

在编写springboot程序时，我们通常会添加 @SpringBootApplication。

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = {
		@Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
		@Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {
//..
}
```

该注解包含了三个注解:

- SpringBootConfiguration
- EnableAutoConfiguration
- ComponentScan

本文介绍主要 EnableAutoConfiguration注解

##EnableAutoConfiguration注解

EnableAutoConfiguration 源码如下

```java
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import({EnableAutoConfigurationImportSelector.class})
public @interface EnableAutoConfiguration {
    Class<?>[] exclude() default {};
    String[] excludeName() default {};
}
```

该注解导入了 `EnableAutoConfigurationImportSelector`。

EnableAutoConfigurationImportSelector 主要作用为 查找出ClassPath下面的所有`META-INF/spring
.factories`文件，获取 spring.factories 文件中 EnableAutoConfiguration 对应的属性，然后加载并实例化这些属性对应的类信息。

EnableAutoConfigurationImportSelector 中较为重要的代码片段如下

```java
protected List<String> getCandidateConfigurations(
  AnnotationMetadata metadata,
  AnnotationAttributes attributes) {
  List<String> configurations = SpringFactoriesLoader.loadFactoryNames(
    getSpringFactoriesLoaderFactoryClass(), getBeanClassLoader());
  // .. 
  return configurations;
}
// 指定要加载的key
protected Class<?> getSpringFactoriesLoaderFactoryClass() {
  return EnableAutoConfiguration.class;
}

/**
 * FACTORIES_RESOURCE_LOCATION = META-INF/spring.factories
 */
public static List<String> loadFactoryNames(
  Class<?> factoryClass, 
  ClassLoader classLoader) {
  String factoryClassName = factoryClass.getName();
  try {
    //查找出 ClassPath 路径下所有的 META-INF/spring.factories 文件
    Enumeration<URL> urls = (
      classLoader != null ? 
      				classLoader.getResources(FACTORIES_RESOURCE_LOCATION) :
      				ClassLoader.getSystemResources(FACTORIES_RESOURCE_LOCATION));
    List<String> result = new ArrayList<String>();
    
    while (urls.hasMoreElements()) {
      URL url = urls.nextElement();
      Properties properties = PropertiesLoaderUtils.loadProperties(
        																											new UrlResource(url));
      //获取 spring.factories 文件中 EnableAutoConfiguration 对应的属性 
      String factoryClassNames = properties.getProperty(factoryClassName);
    	result.addAll(
      	Arrays.asList(StringUtils.commaDelimitedListToStringArray(factoryClassNames)));
    	}
    return result;
  }
  catch (IOException ex) {
    throw new IllegalArgumentException(
      "Unable to load [" + factoryClass.getName() +
      "] factories from location [" + FACTORIES_RESOURCE_LOCATION + "]", ex);
  }
}
```

如下为 spring-boot-autoconfigure-2.1.6.RELEASE.jar中 META-INF/spring.factories 文件，以下为文件的部分

```properties
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.admin.SpringApplicationAdminJmxAutoConfiguration,\
org.springframework.boot.autoconfigure.aop.AopAutoConfiguration,\
org.springframework.boot.autoconfigure.context.ConfigurationPropertiesAutoConfiguration,\
org.springframework.boot.autoconfigure.context.MessageSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.context.PropertyPlaceholderAutoConfiguration,\
org.springframework.boot.autoconfigure.data.web.SpringDataWebAutoConfiguration,\
org.springframework.boot.autoconfigure.http.HttpMessageConvertersAutoConfiguration,\
org.springframework.boot.autoconfigure.http.codec.CodecsAutoConfiguration,\
org.springframework.boot.autoconfigure.jackson.JacksonAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.JdbcTemplateAutoConfiguration,\
```

## 其他文章
https://blog.csdn.net/jeffleo/article/details/77173551