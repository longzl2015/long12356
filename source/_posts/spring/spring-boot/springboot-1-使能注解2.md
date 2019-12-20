---

title: springboot-1-使能注解

date: 2019-08-05 00:00:01

categories: [spring,springboot]

tags: [springboot]

---

前面一片文章讲了 EnableAsync 注解的使能过程。EnableAsync 使用的是 ImportSelector方法 引入其他类。

本文将会介绍 ImportBeanDefinitionRegistrar 方式的引入。

<!--more-->

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