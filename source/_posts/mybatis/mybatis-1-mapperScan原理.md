---
title: mybatis-1-mapperScan原理
date: 2018-09-03 10:00:02
tag: ["mybatis"]
categories: mybatis
---

MapperScan的作用原理

<!--more-->

## MapperScan 注解

在不使用 MapperScan 注解时，我们需要在每一个Mapper 类上添加 Mapper注解，用于标识该类为为Mapper。当Mapper类较多时，这种操作会非常的麻烦。因此mybatis-spring提供了  MapperScan 注解。

通过添加 MapperScan 注解，spring程序会自动去要扫描的指定包路径下的类，然后将mapper添加到spring容器中。

MapperScan 部分源码如下

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@Documented
@Import(MapperScannerRegistrar.class)
public @interface MapperScan {
  // 与 basePackages() 相同
  String[] value() default {};
  // 设置扫描的包路径，仅加载 interface 接口
  String[] basePackages() default {};
  // 提取指定类的包路径，然后扫描该包路径
  Class<?>[] basePackageClasses() default {};
  Class<? extends BeanNameGenerator> nameGenerator() default BeanNameGenerator.class;
  Class<? extends Annotation> annotationClass() default Annotation.class;
  Class<?> markerInterface() default Class.class;
  String sqlSessionTemplateRef() default "";
  String sqlSessionFactoryRef() default "";
  Class<? extends MapperFactoryBean> factoryBean() default MapperFactoryBean.class;
}
```

通过上述源码可以发现，MapperScan 会引入 MapperScannerRegistrar类。

##MapperScannerRegistrar

将 MapperScan 中的属性 添加到 ClassPathMapperScanner 中，然后 ClassPathMapperScanner 调用 doScan()

```java
public class MapperScannerRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware {

  private ResourceLoader resourceLoader;


  @Override
  public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
    // 获取 MapperScan 属性
    AnnotationAttributes annoAttrs = AnnotationAttributes.fromMap(importingClassMetadata.getAnnotationAttributes(MapperScan.class.getName()));
    ClassPathMapperScanner scanner = new ClassPathMapperScanner(registry);

    // this check is needed in Spring 3.1
    if (resourceLoader != null) {
      scanner.setResourceLoader(resourceLoader);
    }
    // MapperScan.annotationClass
    Class<? extends Annotation> annotationClass = annoAttrs.getClass("annotationClass");
    if (!Annotation.class.equals(annotationClass)) {
      scanner.setAnnotationClass(annotationClass);
    }
    // MapperScan.markerInterface
    Class<?> markerInterface = annoAttrs.getClass("markerInterface");
    if (!Class.class.equals(markerInterface)) {
      scanner.setMarkerInterface(markerInterface);
    }
    // MapperScan.nameGenerator
    Class<? extends BeanNameGenerator> generatorClass = annoAttrs.getClass("nameGenerator");
    if (!BeanNameGenerator.class.equals(generatorClass)) {
      scanner.setBeanNameGenerator(BeanUtils.instantiateClass(generatorClass));
    }
    // MapperScan.factoryBean
    Class<? extends MapperFactoryBean> mapperFactoryBeanClass = annoAttrs.getClass("factoryBean");
    if (!MapperFactoryBean.class.equals(mapperFactoryBeanClass)) {
      scanner.setMapperFactoryBean(BeanUtils.instantiateClass(mapperFactoryBeanClass));
    }
    // MapperScan.sqlSessionTemplateRef 
    // MapperScan.sqlSessionFactoryRef 
    scanner.setSqlSessionTemplateBeanName(annoAttrs.getString("sqlSessionTemplateRef"));
    scanner.setSqlSessionFactoryBeanName(annoAttrs.getString("sqlSessionFactoryRef"));
    
    // MapperScan.basePackages
    List<String> basePackages = new ArrayList<String>();
    for (String pkg : annoAttrs.getStringArray("value")) {
      if (StringUtils.hasText(pkg)) {
        basePackages.add(pkg);
      }
    }
    for (String pkg : annoAttrs.getStringArray("basePackages")) {
      if (StringUtils.hasText(pkg)) {
        basePackages.add(pkg);
      }
    }
    for (Class<?> clazz : annoAttrs.getClassArray("basePackageClasses")) {
      basePackages.add(ClassUtils.getPackageName(clazz));
    }
    scanner.registerFilters();
    scanner.doScan(StringUtils.toStringArray(basePackages));
  }

  /**
   * {@inheritDoc}
   */
  @Override
  public void setResourceLoader(ResourceLoader resourceLoader) {
    this.resourceLoader = resourceLoader;
  }
}
```

##ClassPathMapperScanner

ClassPathMapperScanner的doScan主要做了两步操作:

- 调用 super.doscan()
- 调用 this.processBeanDefinitions

我们先来看 super.doscan()

```java
//ClassPathBeanDefinitionScanner
protected Set<BeanDefinitionHolder> doScan(String... basePackages) {
 Assert.notEmpty(basePackages, "At least one base package must be specified");
 Set<BeanDefinitionHolder> beanDefinitions = new LinkedHashSet<>();
 for (String basePackage : basePackages) {
  // 查找 classPath*:${basePackage}/**/*.class; 
  // 默认的filter不做过滤；
  // 仅将 interface 类加入 candidates 中
	Set<BeanDefinition> candidates = findCandidateComponents(basePackage);
	for (BeanDefinition candidate : candidates) {
    //设置 bean 为单例 
	  ScopeMetadata scopeMetadata = this.scopeMetadataResolver
                                     .resolveScopeMetadata(candidate);
	  candidate.setScope(scopeMetadata.getScopeName());
    //设置bean的名称
		String beanName = this.beanNameGenerator.generateBeanName(candidate, this.registry);
		if (candidate instanceof AbstractBeanDefinition) {
      // 组装BeanDefinition默认属性
			postProcessBeanDefinition((AbstractBeanDefinition) candidate, beanName);
		}
		if (candidate instanceof AnnotatedBeanDefinition) {
      // 解析类中的注解配置
			AnnotationConfigUtils
          .processCommonDefinitionAnnotations((AnnotatedBeanDefinition) candidate);
		}
    // 核对是否已存在该bean；若存在，新旧Bean是否兼容
		if (checkCandidate(beanName, candidate)) {
      // 将 新bean 注册到 spring 容器中
			BeanDefinitionHolder definitionHolder=new BeanDefinitionHolder(candidate, beanName);
			definitionHolder = AnnotationConfigUtils
               .applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
			beanDefinitions.add(definitionHolder);
			registerBeanDefinition(definitionHolder, this.registry);
		}
	}
 }
 return beanDefinitions;
}
```

有上面代码可以看出，其doScan的主要目的是扫描出符合条件的class文件，并将其注入到spring容器中。

接下来看 this.processBeanDefinitions

```java
private void processBeanDefinitions(Set<BeanDefinitionHolder> beanDefinitions) {
    GenericBeanDefinition definition;
    for (BeanDefinitionHolder holder : beanDefinitions) {
      definition = (GenericBeanDefinition) holder.getBeanDefinition();
      // 将 Mapper 接口改成 mapperFactoryBean 的类型
      definition.getConstructorArgumentValues()
          .addGenericArgumentValue(definition.getBeanClassName()); // issue #59
      definition.setBeanClass(this.mapperFactoryBean.getClass());
      // 添加 addToConfig
      definition.getPropertyValues().add("addToConfig", this.addToConfig);
      
      boolean explicitFactoryUsed = false;
      // 添加 sqlSessionFactory
      if (StringUtils.hasText(this.sqlSessionFactoryBeanName)) {
        definition.getPropertyValues().add("sqlSessionFactory", new RuntimeBeanReference(this.sqlSessionFactoryBeanName));
        explicitFactoryUsed = true;
      } else if (this.sqlSessionFactory != null) {
        definition.getPropertyValues().add("sqlSessionFactory", this.sqlSessionFactory);
        explicitFactoryUsed = true;
      }
      // 添加 sqlSessionTemplate
      if (StringUtils.hasText(this.sqlSessionTemplateBeanName)) {
        if (explicitFactoryUsed) {
          logger.warn("Cannot use both: sqlSessionTemplate and sqlSessionFactory together. sqlSessionFactory is ignored.");
        }
        definition.getPropertyValues().add("sqlSessionTemplate", new RuntimeBeanReference(this.sqlSessionTemplateBeanName));
        explicitFactoryUsed = true;
      } else if (this.sqlSessionTemplate != null) {
        if (explicitFactoryUsed) {
          logger.warn("Cannot use both: sqlSessionTemplate and sqlSessionFactory together. sqlSessionFactory is ignored.");
        }
        definition.getPropertyValues().add("sqlSessionTemplate", this.sqlSessionTemplate);
        explicitFactoryUsed = true;
      }
      // 将 bean 设置为 按类型注入
      if (!explicitFactoryUsed) {
        if (logger.isDebugEnabled()) {
          logger.debug("Enabling autowire by type for MapperFactoryBean with name '" + holder.getBeanName() + "'.");
        }
        definition.setAutowireMode(AbstractBeanDefinition.AUTOWIRE_BY_TYPE);
      }
    }
}
```

有上面的代码可以看出，processBeanDefinitions 的主要工作为 将 beanClass 改为 mapperFactoryBean，并添加addToConfig、sqlSessionFactory、sqlSessionTemplate信息，最后将 bean设置为 按类型注入。

## MapperFactoryBean

MapperFactoryBean 类图如下

![image-20190826212647991](/images/mybatis-1-mapperScan原理/image-20190826212647991.png)

代码如下:

```java
public class MapperFactoryBean<T> extends SqlSessionDaoSupport 
																	implements FactoryBean<T> {
	// 省略部分代码
  public MapperFactoryBean(Class<T> mapperInterface) {
    this.mapperInterface = mapperInterface;
  }

  // 获取 Mapper 代理对象
  @Override
  public T getObject() throws Exception {
    return getSqlSession().getMapper(this.mapperInterface);
  }
}
```

MapperFactoryBean 继承自 DaoSupport 。

DaoSupport 的主要方法是 afterPropertiesSet

```java
	@Override
	public final void afterPropertiesSet() throws IllegalArgumentException, BeanInitializationException {
		// 将该 mapperInterface 加入 mapperRegistry 中
		checkDaoConfig();

		// Let concrete implementations initialize themselves.
		try {
      //默认为 啥也不执行
			initDao();
		}
		catch (Exception ex) {
			throw new BeanInitializationException("Initialization of DAO failed", ex);
		}
	}
```

SqlSessionDaoSupport 主要提供 getSqlSession()方法，用于获取 SqlSession

