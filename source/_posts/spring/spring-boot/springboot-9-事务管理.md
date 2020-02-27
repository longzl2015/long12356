---

title: springboot-9-事务管理

date: 2019-10-14 09:00:06

categories: [spring,springboot]

tags: [springboot,事务管理]

---

事务管理 原理

<!--more-->

PlatformTransactionManager 接口

```java
public interface PlatformTransactionManager {

	TransactionStatus getTransaction(@Nullable TransactionDefinition definition) throws TransactionException;

	void commit(TransactionStatus status) throws TransactionException;

	void rollback(TransactionStatus status) throws TransactionException;

}
```

PlatformTransactionManager实现类:

- HibernateTransactionManager
- DataSourceTransactionManager
- JtaTransactionManager
- JpaTransactionManager













##参考

 [@Transactional原理]( https://www.jianshu.com/p/b33c4ff803e0)

[Spring源码学习之十二：@Transactional是如何工作的]( https://juejin.im/post/59e87b166fb9a045030f32ed)

[关于Spring+Mybatis事务管理中数据源的思考](https://juejin.im/post/59c259665188253407012580)

