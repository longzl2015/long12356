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

