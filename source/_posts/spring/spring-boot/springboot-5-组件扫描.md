---

title: springboot-5-组件扫描

date: 2019-08-05 00:00:05

categories: [spring,springboot]

tags: [springboot]

---

@ComponentScan注解用于定义spring程序启动时扫描的包路径。

<!--more-->

## 简介

@ComponentScan注解用于定义spring程序启动时扫描的包路径。

ComponentScan 定义如下:

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@Documented
@Repeatable(ComponentScans.class)
public @interface ComponentScan {
	@AliasFor("basePackages")
	String[] value() default {};
	@AliasFor("value")
	String[] basePackages() default {};
  
	Class<?>[] basePackageClasses() default {};
	Class<? extends BeanNameGenerator> nameGenerator() 
    																	default BeanNameGenerator.class;
	Class<? extends ScopeMetadataResolver> scopeResolver() 
    																	default AnnotationScopeMetadataResolver.class;
	ScopedProxyMode scopedProxy() default ScopedProxyMode.DEFAULT;
	String resourcePattern() 
    			default ClassPathScanningCandidateComponentProvider.DEFAULT_RESOURCE_PATTERN;
	boolean useDefaultFilters() default true;
	Filter[] includeFilters() default {};
	Filter[] excludeFilters() default {};
	boolean lazyInit() default false;
	@Retention(RetentionPolicy.RUNTIME)
	@Target({})
	@interface Filter {
		FilterType type() default FilterType.ANNOTATION;
		@AliasFor("classes")
		Class<?>[] value() default {};
		@AliasFor("value")
		Class<?>[] classes() default {};
		String[] pattern() default {};
	}
}
```

## 原理

ComponentScan注解的处理是由 org.springframework.context.annotation.ConfigurationClassParser 完成的。






## 来源

https://blog.csdn.net/qq_20597727/article/details/82713306