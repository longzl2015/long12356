---

title: enable注解

date: 2018-08-31 00:02:00

categories: [springboot]

tags: [springboot]

---

`@enable*`是springboot中用来启用某一个功能特性的一类注解。其中包括我们常用的@SpringBootApplication注解中用于开启自动注入的annotation`@EnableAutoConfiguration`，开启异步方法的annotation`@EnableAsync`，
开启将配置文件中的属性以bean的方式注入到IOC容器的annotation`@EnableConfigurationProperties`等。

<!--more-->

## 以@EnableAsync为例

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Import(AsyncConfigurationSelector.class)
public @interface EnableAsync {

	Class<? extends Annotation> annotation() default Annotation.class;

	boolean proxyTargetClass() default false;

	AdviceMode mode() default AdviceMode.PROXY;

	int order() default Ordered.LOWEST_PRECEDENCE;
}
```
@EnableAsync 的作用是启用异步执行，使标注@Async注解的方法能够和其他方法异步执行。

我们发现，这个注解的重点在`@Import({AsyncConfigurationSelector.class})`这段代码。解释一下@Import和XxxSelector.class的作用。

### @Import

用来导入一个或多个class，这些类会注入到spring容器中: 这些类 Configuration、ImportSelector 、ImportBeanDefinitionRegistrar 和 普通类

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Import {
	/**
	 * {@link Configuration}, {@link ImportSelector}, {@link ImportBeanDefinitionRegistrar}
	 * or regular component classes to import.
	 */
	Class<?>[] value();

}
```

### AsyncConfigurationSelector.class

实现了ImportSelector.class。

```java
public class AsyncConfigurationSelector extends AdviceModeImportSelector<EnableAsync> {

	private static final String ASYNC_EXECUTION_ASPECT_CONFIGURATION_CLASS_NAME =
			"org.springframework.scheduling.aspectj.AspectJAsyncConfiguration";

	@Override
	public String[] selectImports(AdviceMode adviceMode) {
		switch (adviceMode) {
			case PROXY:
				return new String[] { ProxyAsyncConfiguration.class.getName() };
			case ASPECTJ:
				return new String[] { ASYNC_EXECUTION_ASPECT_CONFIGURATION_CLASS_NAME };
			default:
				return null;
		}
	}
}

public abstract class AdviceModeImportSelector<A extends Annotation> implements ImportSelector {

	public static final String DEFAULT_ADVICE_MODE_ATTRIBUTE_NAME = "mode";


	protected String getAdviceModeAttributeName() {
		return DEFAULT_ADVICE_MODE_ATTRIBUTE_NAME;
	}

	@Override
	public final String[] selectImports(AnnotationMetadata importingClassMetadata) {
		Class<?> annoType = GenericTypeResolver.resolveTypeArgument(getClass(), AdviceModeImportSelector.class);
		AnnotationAttributes attributes = AnnotationConfigUtils.attributesFor(importingClassMetadata, annoType);
		if (attributes == null) {
			throw new IllegalArgumentException(String.format(
				"@%s is not present on importing class '%s' as expected",
				annoType.getSimpleName(), importingClassMetadata.getClassName()));
		}

		AdviceMode adviceMode = attributes.getEnum(this.getAdviceModeAttributeName());
		String[] imports = selectImports(adviceMode);
		if (imports == null) {
			throw new IllegalArgumentException(String.format("Unknown AdviceMode: '%s'", adviceMode));
		}
		return imports;
	}

	protected abstract String[] selectImports(AdviceMode adviceMode);
}

```

打开ImportSelector.class阅读源码：

```java
public interface ImportSelector {

	String[] selectImports(AnnotationMetadata importingClassMetadata);
}
```

Spring会把实现ImportSelector接口的类中的SelectImport方法返回的值注入到Spring容器中。这个方法的返回值必须是一个class的全类名的String[]。举个例子：

```java

public class MyImportSelector implements ImportSelector {
    
    @Override
    public String[] selectImports(AnnotationMetadata annotationMetadata) {
        return new String[]{"com.springboot.enable.User", "com.springboot.enable.Car"};
    }
}
```

spring容器会把com.springboot.enable包下的User和Car这两个类放入容器中。

## ImportBeanDefinitionRegistrar

还有一个和ImportSelector功能差不多的类，ImportBeanDefinitionRegistrar 使用 beanDefinitionRegistry 对象将 bean 加入 Spring 容器中，源码如下：

```java
public interface ImportBeanDefinitionRegistrar {

	/**
	 * Register bean definitions as necessary based on the given annotation metadata of
	 * the importing {@code @Configuration} class.
	 * <p>Note that {@link BeanDefinitionRegistryPostProcessor} types may <em>not</em> be
	 * registered here, due to lifecycle constraints related to {@code @Configuration}
	 * class processing.
	 * @param importingClassMetadata annotation metadata of the importing class
	 * @param registry current bean definition registry
	 */
	public void registerBeanDefinitions(
			AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry);

}

```
## 小实验：
下面我们做一个小实验印证一下，下图有三个包，每个包下分别有三个bean，他们都加了@Component注解，会被spring加入到容器中。

```java
package  dto;
@Component
public class User{
    
}
```

```java
package entity;
@Component
public class Bird{
    
}
```

```java
package vo;
@Component
public class Car{
    
}
```


需求是，
当注入dto和vo两个包下的bean时，输出一段话：echo bean ：+ bean的全类名，
当注入entity包下的bean时，不输出。

### 实现BeanPostProcessor接口
创建EchoBeanPostProcessor.class，实现BeanPostProcessor接口，作用是实现上文的业务逻辑。

```java
//实现BeanPostProcessor接口的类，放入spring容器中后，容器启动和关闭时会执行以下两个重写的方法
public class EchoBeanPostProcessor implements BeanPostProcessor {

    //getter、setter省略，读者在试验的时候要加上
    private List<String> packages;

    //该方法在spring容器初始化前执行
    @Override
    public Object postProcessBeforeInitialization(Object bean, String s) throws BeansException {
        for (String pack : packages) {
            if (bean.getClass().getName().startsWith(pack)) {
                System.out.println("echo bean: " + bean.getClass().getName());
            }
        }
        return bean;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String s) throws BeansException {
        return bean;
    }
}
```

## 实现ImportBeanDefinitionRegistrar

创建BamuImportBeanDefinitionRegistrar.class，实现ImportBeanDefinitionRegistrar

```java

public class BamuImportBeanDefinitionRegistrar implements ImportBeanDefinitionRegistrar {

    @Override
    public void registerBeanDefinitions(AnnotationMetadata annotationMetadata, BeanDefinitionRegistry beanDefinitionRegistry) {

        //获取EnableEcho注解的所有属性的value
        Map<String, Object> attributes = annotationMetadata.getAnnotationAttributes(EnableEcho.class.getName());
        //获取package属性的value
        List<String> packages = Arrays.asList((String[]) attributes.get("packages"));

        //使用beanDefinitionRegistry对象将EchoBeanPostProcessor注入至Spring容器中
        BeanDefinitionBuilder beanDefinitionBuilder = BeanDefinitionBuilder.rootBeanDefinition(EchoBeanPostProcessor.class);
        //给EchoBeanPostProcessor.class中注入packages
        beanDefinitionBuilder.addPropertyValue("packages", packages);
        beanDefinitionRegistry.registerBeanDefinition(EchoBeanPostProcessor.class.getName(), beanDefinitionBuilder.getBeanDefinition());
    }
}
```

### 创建注解@EnableEcho

创建注解@EnableEcho，ImportBamuImportBeanDefinitionRegistrar.class

```java

@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Import({BamuImportBeanDefinitionRegistrar.class})
public @interface EnableEcho {
    //传入包名
    String[] packages() default "";
}
```
### 启动类
在springboot启动类中加入我们创建的注解，并传入指定的包名，执行main方法：

```java

@SpringBootApplication
@EnableEcho(packages = {"com.springboot.vo", "com.springboot.dto"})
public class BlogApplication {

    public static void main(String[] args) {

        ConfigurableApplicationContext context = SpringApplication.run(BlogApplication.class, args);
        context.close();
    }
}
```


## 来源

https://www.jianshu.com/p/3da069bd865c