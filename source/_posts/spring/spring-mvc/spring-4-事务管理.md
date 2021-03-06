---
title: spring-4-事务管理
date: 2019-06-09 11:09:04
tags: [aop,事务管理]
categories: [spring,springmvc]
---

事务管理是企业级应用程序开发中必不可少的技术,用来确保数据的完整性和一致性.
事务就是一系列的动作, 它们被当做一个单独的工作单元. 这些动作要么全部完成, 要么全部不起作用

<!--more-->

## 事务的四个关键属性(ACID)
原子性(atomicity)、一致性(consistency)、隔离性(isolation)、持久性(durability)


## 声明式事务管理-配置步骤：

声明式事务最大的优点就是不需要通过编程的方式管理事务，这样就不需要在业务逻辑代码中掺杂事务管理的代码，只需在配置文件中做相关的事务规则声明（或通过等价的基于标注的方式），便可以将事务规则应用到业务逻辑中。

### 使用 xml 配置 

```xml
<!-- 配置事务管理器 -->
<bean id="transactionManager"
	class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
	<property name="dataSource" ref="dataSource"></property>
</bean>

<!-- 启用事务注解 -->
<tx:annotation-driven transaction-manager="transactionManager"/>
```

在函数前，添加事务注解

```java
@Transactional
public void purchase(String username,string isbn){

}
```

### 纯注解形式

```java
// 在启动类上 添加 @EnableTransactionManagement
@SpringBootApplication
@EnableTransactionManagement
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}

//在服务层的方法上加上 @Transactional 注解即可
@Component
public class BookingService {

    private final static Logger logger = LoggerFactory.getLogger(BookingService.class);

    private final JdbcTemplate jdbcTemplate;

    public BookingService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public void book(String... persons) {
        for (String person : persons) {
            logger.info("Booking " + person + " in a seat...");
            jdbcTemplate.update("insert into BOOKINGS(FIRST_NAME) values (?)", person);
        }
    }

    public List<String> findAllBookings() {
        return jdbcTemplate.query("select FIRST_NAME from BOOKINGS",
                (rs, rowNum) -> rs.getString("FIRST_NAME"));
    }
}
```

### Transactional使用注意点

1. 由于 Transactional 注解使用的是AOP形式，因此，Transactional注解只能作用在 public 方法上。如果放在了非public方法上，编译器并不会报错，但是不会有事务功能。
2. spring事务管理器，默认只对运行时异常进行回滚操作。如果方法抛出的是 unchecked 异常，事务不会进行回滚。若需要进行回滚可以指定 rollbackFor 属性。
3. spring团队建议将 Transactional 放在 具体的类或者具体的方法上。因为如果将注解写在接口上，而此时aop使用的是cglib代理，那么事务就会失效。
4. 一个方法调用被 Transactional 注解标记的同类中的另一个方法时，事务不会生效。(可以使用自注入或者新增一个事务层解决)
5. “proxy-target-class” 属性值来控制是基于接口的还是基于类的代理被创建。默认为 fasle 即 jdk代理。


## 事务的相关标签介绍

### 传播属性
使用propagation指定事务的传播属性，共有7种，默认为REQUIRED。

**常用的2种：**
- **REQUIRED**：业务方法需要在一个事务中运行。如果方法运行时，已经处在一个事务中，那么加入到该事务，否则为自己创建一个新的事务。

![REQUIRED](http://i.imgur.com/Len9pXU.jpg)

- **REQUIRESNEW**：属性表明不管是否存在事务，业务方法总会为自己发起一个新的事务。如果方法已经运行在一个事务中，则原有事务会被挂起，新的事务会被创建，直到方法执行结束，新事务才算结束，原先的事务才会恢复执行。

![REQUIRESNEW](http://i.imgur.com/hohUw71.jpg)

**其他5种：**
- **NOT_SUPPORTED**：声明方法不需要事务。如果方法没有关联到一个事务，容器不会为它开启事务。如果方法在一个事务中被调用，该事务会被挂起，在方法调用结束后，原先的事务便会恢复执行。
- **MANDATORY**：该属性指定业务方法只能在一个已经存在的事务中执行，业务方法不能发起自己的事务。如果业务方法在没有事务的环境下调用，容器就会抛出例外。
- **SUPPORTS**：这一事务属性表明，如果业务方法在某个事务范围内被调用，则方法成为该事务的一部分。如果业务方法在事务范围外被调用，则方法在没有事务的环境下执行。
- **Never**：指定业务方法绝对不能在事务范围内执行。如果业务方法在某个事务中执行，容器会抛出例外，只有业务方法没有关联到任何事务，才能正常执行。
- **NESTED**：如果一个活动的事务存在，则运行在一个嵌套的事务中. 如果没有活动事务, 则按REQUIRED属性执行.它使用了一个单独的事务， 这个事务拥有多个可以回滚的保存点。内部事务的回滚不会对外部事务造成影响。它只对DataSourceTransactionManager事务管理器起效

### 隔离级别
使用isolation指定事务的隔离级别，常用的取值为Read_committed。

声明式事务的第二个方面是隔离级别。隔离级别定义一个事务可能受其他并发事务活动活动影响的程度。另一种考虑一个事务的隔离级别的方式，是把它想象为那个事务对于事物处理数据的自私程度。

在一个典型的应用程序中，多个事务同时运行，经常会为了完成他们的工作而操作同一个数据。并发虽然是必需的，但是会导致一下问题：

- 脏读（Dirty read）-- 脏读发生在一个事务读取了被另一个事务改写但尚未提交的数据-时。如果这些改变在稍后被回滚了，那么第一个事务读取的数据就会是无效的。
- 不可重复读（Nonrepeatable read）-- 不可重复读发生在一个事务执行相同的查询两次或两次以上，但每次查询结果都不相同时。这通常是由于另一个并发事务在两次查询之间更新了数据。
- 幻影读（Phantom reads）-- 幻影读和不可重复读相似。当一个事务（T1）读取几行记录后，另一个并发事务（T2）插入了一些记录时，幻影读就发生了。在后来的查询中，第一个事务（T1）就会发现一些原来没有的额外记录。

在理想状态下，事务之间将完全隔离，从而可以防止这些问题发生。然而，完全隔离会影响性能，因为隔离经常牵扯到锁定在数据库中的记录（而且有时是锁定完整的数据表）。侵占性的锁定会阻碍并发，要求事务相互等待来完成工作。

考虑到完全隔离会影响性能，而且并不是所有应用程序都要求完全隔离，所以有时可以在事务隔离方面灵活处理。因此，就会有好几个隔离级别。

1. **ISOLATION_DEFAULT**：  使用后端数据库默认的隔离级别。
1. **ISOLATION_READ_UNCOMMITTED**：  允许读取尚未提交的更改。可能导致脏读、幻影读或不可重复读。
1. **ISOLATION_READ_COMMITTED**：  允许从已经提交的并发事务读取。可防止脏读，但幻影读和不可重复读仍可能会发生。
1. **ISOLATION_REPEATABLE_READ**：  对相同字段的多次读取的结果是一致的，除非数据被当前事务本身改变。可防止脏读和不可重复读，但幻影读仍可能发生。
1. **ISOLATION_SERIALIZABLE**：  完全服从ACID的隔离级别，确保不发生脏读、不可重复读和幻影读。这在所有隔离级别中也是最慢的，因为它通常是通过完全锁定当前事务所涉及的数据表来完成的。

### 只读
使用readOnly指定。

声明式事务的第三个特性是：它是否是一个只读事务。如果一个事务只对后端数据库执行读操作，那么该数据库就可能利用那个事务的只读特性，采取某些优化措施。通过把一个事务声明为只读，可以给后端数据库一个机会来应用那些它认为合适的优化措施。

由于只读的优化措施是在一个事务启动时由后端数据库实施的，因此，只有对于那些具有可能启动一个新事务的传播行为（PROPAGATION_REQUIRES_NEW、PROPAGATION_REQUIRED、ROPAGATION_NESTED）的方法来说，将事务声明为只读才有意义。

此外，如果使用Hibernate作为持久化机制，那么把一个事务声明为只读，将使Hibernate的flush模式被设置为FLUSH_NEVER。这就告诉Hibernate避免和数据库进行不必要的对象同步，从而把所有更新延迟到事务的结束。

### 事务超时
使用timeOut指定。

为了使一个应用程序很好地执行，它的事务不能运行太长时间。因此，声明式事务的下一个特性就是它的超时。

假设事务的运行时间变得格外的长，由于事务可能涉及对后端数据库的锁定，所以长时间运行的事务会不必要地占用数据库资源。这时就可以声明一个事务在特定秒数后自动回滚，不必等它自己结束。

由于超时时钟在一个事务启动的时候开始的，因此，只有对于那些具有可能启动一个新事务的传播行为（PROPAGATION_REQUIRES_NEW、PROPAGATION_REQUIRED、ROPAGATION_NESTED）的方法来说，声明事务超时才有意义。

### 回滚规则
使用rollbackFor 和 noRollbackFor 属性来指定。.

- **rollbackFor:**  遇到时必须进行回滚
- **noRollbackFor:** 一组异常类，遇到时必须不回滚


它们定义哪些异常引起回滚，哪些不引起。在默认设置下，事务只在出现运行时异常（runtime exception）时回滚，而在出现受检查异常（checked exception）时不回滚（这一行为和EJB中的回滚行为是一致的）。

不过，也可以声明在出现特定受检查异常时像运行时异常一样回滚。同样，也可以声明一个事务在出现特定的异常时不回滚，即使那些异常是运行时一场。


## 事务应该放在服务层 

将事务发到服务层，这个只是最佳实践。在技术上是可以将事务注解放到控制层的。

参考 https://stackoverflow.com/questions/23118789/why-we-shouldnt-make-a-spring-mvc-controller-transactional


## 来源

https://spring.io/guides/gs/managing-transactions/
https://mojito515.github.io/blog/2016/08/31/transactionalinspring/