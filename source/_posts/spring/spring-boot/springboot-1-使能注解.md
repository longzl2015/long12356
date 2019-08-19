---

title: springboot-1-使能注解

date: 2019-08-05 00:00:01

categories: [spring,springboot]

tags: [springboot]

---

@enableXXX是springboot中用来启用某一个功能特性的一类注解，如 @EnableAutoConfiguration，@EnableAsync

<!--more-->

## enableXXX注解

@enableXXX注解通常会与@Import一起。如 EnableAsync

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

@Import 注解只有一个方法，它的返回值会被注入到spring容器中。

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

我们在本章中仅介绍 ImportSelector 和 ImportBeanDefinitionRegistrar。

##ImportSelector

ImportSelector 只有一个方法。该方法会返回 全类名字符串。而这些全类名字符串会被注入到spring中

```java
public interface ImportSelector {
	String[] selectImports(AnnotationMetadata importingClassMetadata);
}
```

还是以@EnableAsync为例。

从EnableAsync注解源码中可以看到

- @EnableAsync的@Import会将AsyncConfigurationSelector注入到spring容器中
- AsyncConfigurationSelector又是ImportSelector的子类，其会根据 selectImports()的返回值注入指定类。

```java
public class AsyncConfigurationSelector extends AdviceModeImportSelector<EnableAsync> {
	private static final String ASYNC_EXECUTION_ASPECT_CONFIGURATION_CLASS_NAME =
			"org.springframework.scheduling.aspectj.AspectJAsyncConfiguration";
  // 根据 @EnableAsync 的 AdviceMode 字段返回指定的全类名。
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
```

```java
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

## ImportBeanDefinitionRegistrar

还有一个和ImportSelector功能差不多的类，ImportBeanDefinitionRegistrar 使用 beanDefinitionRegistry 对象将 bean 加入 Spring 容器中，源码如下：

```java
public interface ImportBeanDefinitionRegistrar {
	public void registerBeanDefinitions(
			AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry);
}

```

**例子**

创建EchoBeanPostProcessor.class，实现BeanPostProcessor接口。

```java
//实现BeanPostProcessor接口的类，放入spring容器中后，容器启动和关闭时会执行以下两个重写的方法
public class EchoBeanPostProcessor implements BeanPostProcessor {
    //getter、setter省略，读者在试验的时候要加上
    private List<String> packages;
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

创建BamuImportBeanDefinitionRegistrar，实现ImportBeanDefinitionRegistrar

```java
public class BamuImportBeanDefinitionRegistrar implements ImportBeanDefinitionRegistrar {

    @Override
    public void registerBeanDefinitions(AnnotationMetadata annotationMetadata, BeanDefinitionRegistry beanDefinitionRegistry) {

        //获取EnableEcho注解的所有属性的value
        Map<String, Object> attributes = annotationMetadata.getAnnotationAttributes(EnableEcho.class.getName());
        //获取package属性的value
        List<String> packages = Arrays.asList((String[]) attributes.get("packages"));

        //使用beanDefinitionRegistry对象将EchoBeanPostProcessor注入至Spring容器中
        BeanDefinitionBuilder beanDefinitionBuilder = 
          BeanDefinitionBuilder.rootBeanDefinition(EchoBeanPostProcessor.class);
        //给EchoBeanPostProcessor.class中注入packages
        beanDefinitionBuilder.addPropertyValue("packages", packages);
    		beanDefinitionRegistry.registerBeanDefinition(
      		EchoBeanPostProcessor.class.getName(), 
      		beanDefinitionBuilder.getBeanDefinition()
        );
    }
}
```

创建注解@EnableEcho

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