---

title: springboot-8-async

date: 2019-10-14 09:00:06

categories: [spring,springboot]

tags: [springboot,async]

---

Async 原理

<!--more-->

##Async

待续

## EnableAsync注解

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

使能注解中包含一个至关重要的`@Import`。

还是以`@EnableAsync`为例。

从`EnableAsync注解`源码中可以看到

- `@EnableAsync`的`@Import`会将`AsyncConfigurationSelector`注入到spring容器中
- `AsyncConfigurationSelector`又是`ImportSelector`的子类，其会根据 `selectImports()`的返回值注入指定类。

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
  // 子类实现：根据配置，导入指定的类
	protected abstract String[] selectImports(AdviceMode adviceMode);
}

```



##参考

[](https://www.cnblogs.com/dennyzhangdd/p/9026303.html)