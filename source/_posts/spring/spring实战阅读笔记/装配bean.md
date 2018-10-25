---

title: 装配bean

date: 2018-10-24 17:19:00

categories: [spring]

tags: [spring]

---





<!--more-->

## 自动装配bean

- `@Component` 放在类名上: 表明该类为 一个spring 组件类。
- `@ComponentScan` 放在类名上: 开启扫描功能， spring 会去扫描指定 包名 或者 类名 的 java 配置类。
- `@Autowired` 放在字段或者方法上: 从应用上下文中，找到符合条件的类实例A，将该实例A与被注解的变量绑定。

## 配置类

当引用第三方jar时，是无法在需要的类上加 `@Component` 注解的，因此 需要使用另一种方法: 配置类。

- `@Configuration` 放在类名上: 表明该类为配置类，该类包含各种 bean 实例
- `@Bean` 放在方法上: 表明 该方法的返回对象 为一个 bean 实例，该实例会被注册到spring应用上下文中。
- `@Import` 放在类名上: 将 `@Import` 的 `value`属性指定的普通类或者配置类加载到当前应用上下文中。

需要注意的是 当调用 `@Bean` 注解的方法，spring会拦截该方法的调用，返回该方法创建的bean，而不是创建新的对象。


## 通过 XML 装配

由于通过注解形式基本能代替xml方式。这里就不介绍了。

