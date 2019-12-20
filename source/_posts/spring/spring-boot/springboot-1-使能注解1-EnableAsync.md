---

title: springboot-1-使能注解1-EnableAsync

date: 2019-08-05 00:00:01

categories: [spring,springboot]

tags: [springboot]

---

@enableXXX是springboot中用来启用某一个功能特性的一类注解，如:

- @EnableAutoConfiguration，
- @EnableAsync，
- @EnableTransactionManagement。

本文以@EnableAsync为例，介绍使能注解的生效过程。

<!--more-->

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

##Import注解

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

上述代码中，我们可以看到`Import注解`支持注入4种类型。在本章中仅介绍 ImportSelector。

##ImportSelector接口

ImportSelector 只有一个方法。该方法会返回 `全类名字符串`。而这些全类名字符串会被注入到spring中

```java
public interface ImportSelector {
	String[] selectImports(AnnotationMetadata importingClassMetadata);
}
```

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

## Import注解是如何被spring识别的

Import注解的生效过程中有一个至关重要的类ConfigurationClassPostProcessor。我们先从该类开始。

###ConfigurationClassPostProcessor

以下代码为精简的部分代码:

```java
public class ConfigurationClassPostProcessor implements BeanDefinitionRegistryPostProcessor,
		PriorityOrdered, ResourceLoaderAware, BeanClassLoaderAware, EnvironmentAware {
	/**
	 * 程序启动后，AbstractApplicationContext.refresh()会调用如下方法
	 */
	@Override
	public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
		int registryId = System.identityHashCode(registry);
		this.registriesPostProcessed.add(registryId);
		processConfigBeanDefinitions(registry);
	}

	/**
	 * 构建与验证 a configuration model based on the registry of
	 * {@link Configuration} classes.
	 */
	public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
		List<BeanDefinitionHolder> configCandidates = new ArrayList<>();
		String[] candidateNames = registry.getBeanDefinitionNames();
    // 将所有符合 ConfigurationClass 的 BeanDefinition 加入到 configCandidates 中。
		for (String beanName : candidateNames) {
			BeanDefinition beanDef = registry.getBeanDefinition(beanName);
			if (ConfigurationClassUtils.isFullConfigurationClass(beanDef) ||
					ConfigurationClassUtils.isLiteConfigurationClass(beanDef)) {
				// BeanDefinition 已经被处理为了 configurationClass,无需再次处理
			}
			else if (ConfigurationClassUtils.checkConfigurationClassCandidate(beanDef, this.metadataReaderFactory)) {
        // 若 BeanDefinition 包含 
        // @Configuration、@Bean、@Component、@ComponentScan、@Import、@ImportResource
        // 则将其加入 configCandidates
				configCandidates.add(new BeanDefinitionHolder(beanDef, beanName));
			}
		}
		if (configCandidates.isEmpty()) {
      //没有配置类候选，直接返回
			return;
		}

		// 根据 @Order 排序，配置类候选
		configCandidates.sort((bd1, bd2) -> {
			int i1 = ConfigurationClassUtils.getOrder(bd1.getBeanDefinition());
			int i2 = ConfigurationClassUtils.getOrder(bd2.getBeanDefinition());
			return Integer.compare(i1, i2);
		});

		// 初始化 配置类parser 实例
		ConfigurationClassParser parser = new ConfigurationClassParser(
				this.metadataReaderFactory, this.problemReporter, this.environment,
				this.resourceLoader, this.componentScanBeanNameGenerator, registry);

		Set<BeanDefinitionHolder> candidates = new LinkedHashSet<>(configCandidates);
		Set<ConfigurationClass> alreadyParsed = new HashSet<>(configCandidates.size());
    // 解析每一个 配置类候选。
		do {
      // 解析配置类候选人后，可以通过 parser.getConfigurationClasses() 获取到配置类列表
			parser.parse(candidates);
      // 校验配置类
			parser.validate();
      // 通过 parser.getConfigurationClasses() 获取，解析的到的配置类
			Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
			configClasses.removeAll(alreadyParsed);

			// 根据configClasses生成一个或者多个BeanDefinitions，然后注册到BeanDefinitionRegistry
			this.reader.loadBeanDefinitions(configClasses);
      // 标记解析过的类
			alreadyParsed.addAll(configClasses);
      // 清空 candidates
			candidates.clear();
      // 获取一下容器中BeanDefinition的数据,如果发现数量增加了,说明有新的BeanDefinition被注册了
			if (registry.getBeanDefinitionCount() > candidateNames.length) {
				String[] newCandidateNames = registry.getBeanDefinitionNames();
				Set<String> oldCandidateNames = new HashSet<>(Arrays.asList(candidateNames));
				Set<String> alreadyParsedClasses = new HashSet<>();
				for (ConfigurationClass configurationClass : alreadyParsed) {
					alreadyParsedClasses.add(configurationClass.getMetadata().getClassName());
				}
				for (String candidateName : newCandidateNames) {
					if (!oldCandidateNames.contains(candidateName)) {
						BeanDefinition bd = registry.getBeanDefinition(candidateName);
						if (ConfigurationClassUtils.checkConfigurationClassCandidate(bd, this.metadataReaderFactory) &&
								!alreadyParsedClasses.contains(bd.getBeanClassName())) {
							candidates.add(new BeanDefinitionHolder(bd, candidateName));
						}
					}
				}
				candidateNames = newCandidateNames;
			}
		}
		while (!candidates.isEmpty());
    //.. 
	}
}
```

简单来说，ConfigurationClassPostProcessor 主要是 

1. 扫描程序中的 配置类（如Configuration注解、Bean注解、Component注解、ComponentScan注解、Import注解、ImportResource注解）
2. 通过ConfigurationClassParser解析配置类，将解析得到的配置类注册成相应的BeanDefinitions

### ConfigurationClassParser

ConfigurationClassParser主要作用是: 根据不同注解，解析出配置类，并将解析出的配置类放入 configurationClasses中。

例如:

1. `BeanDefinitionHolder`包含 `@Import` 注解且`@Import`注解的值为 `ImportSelector`的实现类(假设为`ImportSelectorImplA`)，
2.  `ConfigurationClassParser` 会调用 `ImportSelectorImplA.selectImports()`获取一个全类名列表，
3. 将这全类名列表逐个转成`ConfigurationClass`类实例 ，
4. 将`ConfigurationClass`类实例 put进`ConfigurationClassParser.configurationClassesMap`变量中。

```java
class ConfigurationClassParser {
  // 保存 已解析到的 配置类
	private final Map<ConfigurationClass, ConfigurationClass> configurationClasses = new LinkedHashMap<>();
  // 遍历解析每个 BeanDefinitionHolder 
	public void parse(Set<BeanDefinitionHolder> configCandidates) {
		for (BeanDefinitionHolder holder : configCandidates) {
			BeanDefinition bd = holder.getBeanDefinition();
			try {
        // 根据不同子类，选择不同的parse方法，
        // 最终都会收束到 processConfigurationClass方法
				if (bd instanceof AnnotatedBeanDefinition) {
					parse(((AnnotatedBeanDefinition) bd).getMetadata(), holder.getBeanName());
				}
				else if (bd instanceof AbstractBeanDefinition && ((AbstractBeanDefinition) bd).hasBeanClass()) {
					parse(((AbstractBeanDefinition) bd).getBeanClass(), holder.getBeanName());
				}
				else {
					parse(bd.getBeanClassName(), holder.getBeanName());
				}
			}
			catch (Throwable ex) {
			  // 向外抛异常
			}
		}
    // 忽略
	}
 
  // 经过parse方法后，会走到 processConfigurationClass 方法。
	protected void processConfigurationClass(ConfigurationClass configClass) throws IOException {

		ConfigurationClass existingClass = this.configurationClasses.get(configClass);
		if (existingClass != null) {
			if (configClass.isImported()) {
        // 已被导入，直接跳过
				if (existingClass.isImported()) {
					existingClass.mergeImportedBy(configClass);
				}
				return;
			}
			else {
        // 未被导入，从configurationClasses移除，之后重新导入
				this.configurationClasses.remove(configClass);
				this.knownSuperclasses.values().removeIf(configClass::equals);
			}
		}

		//Recursively process the configuration class and its superclass hierarchy.
		SourceClass sourceClass = asSourceClass(configClass);
		do {
			sourceClass = doProcessConfigurationClass(configClass, sourceClass);
		}
		while (sourceClass != null);
    // 将 处理过的类 放入 map中
		this.configurationClasses.put(configClass, configClass);
	}

	/**
	 * 通过解析 annotations, members 和 methods来构建一个完整的 ConfigurationClass。
	 * @param configClass the configuration class being build
	 * @param sourceClass a source class
	 * @return the superclass, or {@code null} if none found or previously processed
	 */
	@Nullable
	protected final SourceClass doProcessConfigurationClass(ConfigurationClass configClass, SourceClass sourceClass)
			throws IOException {
    // @Component、@PropertySource、@ComponentScan、@ImportResource、@Bean等
    // 的处理逻辑，这里省略了。自行源码查看	
    
		// @Import 注解
		processImports(configClass, sourceClass, getImports(sourceClass), true);

		return null;
	}
	/**
	 * 递归获取 @Import 的 值
	 */
	private Set<SourceClass> getImports(SourceClass sourceClass) throws IOException {
		Set<SourceClass> imports = new LinkedHashSet<>();
		Set<SourceClass> visited = new LinkedHashSet<>();
		collectImports(sourceClass, imports, visited);
		return imports;
	}
  
	private void processImports(ConfigurationClass configClass, SourceClass currentSourceClass,
			Collection<SourceClass> importCandidates, boolean checkForCircularImports) {
		if (importCandidates.isEmpty()) {
			return;
		}

		if (checkForCircularImports && isChainedImportOnStack(configClass)) {
      // 循环检测
			this.problemReporter.error(new CircularImportProblem(configClass, this.importStack));
		}
		else {
			this.importStack.push(configClass);
			try {
				for (SourceClass candidate : importCandidates) {
					if (candidate.isAssignable(ImportSelector.class)) {
            // Import注解的值引用了 ImportSelector实现类

						Class<?> candidateClass = candidate.loadClass();
            //实例化 ImportSelector 实现类
						ImportSelector selector = BeanUtils.instantiateClass(candidateClass, ImportSelector.class);
						ParserStrategyUtils.invokeAwareMethods(
								selector, this.environment, this.resourceLoader, this.registry);
						if (selector instanceof DeferredImportSelector) {
							this.deferredImportSelectorHandler.handle(
									configClass, (DeferredImportSelector) selector);
						}
						else {
              //提取出 ImportSelector 实现类 指定要导入的类
							String[] importClassNames = selector.selectImports(currentSourceClass.getMetadata());
              // 重新调用 processImports，处理新出现的配置类。
							Collection<SourceClass> importSourceClasses = asSourceClasses(importClassNames);
							processImports(configClass, currentSourceClass, importSourceClasses, false);
						}
					}
					else if (candidate.isAssignable(ImportBeanDefinitionRegistrar.class)) {
						// Import注解的值引用了 ImportBeanDefinitionRegistrar 实现类
            Class<?> candidateClass = candidate.loadClass();
						ImportBeanDefinitionRegistrar registrar =
								BeanUtils.instantiateClass(candidateClass, ImportBeanDefinitionRegistrar.class);
						ParserStrategyUtils.invokeAwareMethods(
								registrar, this.environment, this.resourceLoader, this.registry);
						configClass.addImportBeanDefinitionRegistrar(registrar, currentSourceClass.getMetadata());
					}
					else {
						// 重新调用开头的processConfigurationClass方法
						this.importStack.registerImport(
								currentSourceClass.getMetadata(), candidate.getMetadata().getClassName());
						processConfigurationClass(candidate.asConfigClass(configClass));
					}
				}
			}
			catch (BeanDefinitionStoreException ex) {
				throw ex;
			}
			catch (Throwable ex) {
				throw new BeanDefinitionStoreException(
						"Failed to process import candidates for configuration class [" +
						configClass.getMetadata().getClassName() + "]", ex);
			}
			finally {
				this.importStack.pop();
			}
		}
	}
}
```



## 来源

https://www.jianshu.com/p/3da069bd865c

[Spring5源码解析5-ConfigurationClassPostProcessor (上)](https://juejin.im/post/5d69e26cf265da03f33369f3)