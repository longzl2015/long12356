---
title: spring(2)-依赖注入-xml-自动装配autowired
date: 2015-08-10 13:26:58
tags: [自动装配,autowired]
categories: spring
---

自动装配的好处是 无须在Spring配置文件中描述javaBean之间的依赖关系（如配置<property>、<constructor-arg>）。IOC容器会自动建立javabean之间的关联关系.

<!--more-->


## 自动装配autowire模式
Spring支持多种自动装配模式，如下：

1. **no**
  默认情况下，不自动装配，通过“ref”attribute手动设定。
2. **byName**
  根据Property的Name自动装配，如果一个bean的name，和另一个bean中的Property的name相同，则自动装配这个bean到Property中。
3. **byType**
  根据Property的数据类型（Type）自动装配，如果一个bean的数据类型，兼容另一个bean中Property的数据类型，则自动装配。
4. **constructor**
  根据构造函数参数的数据类型，进行byType模式的自动装配。
5. **autodetect**  
  如果发现默认的构造函数，用constructor模式，否则，用byType模式。


## 下例中演示自动装配

Customer.java如下：

```java
package com.lei.common;
public class Customer
{
    private Person person;
    public Customer(Person person) {
        this.person = person;
    }
    public void setPerson(Person person) {
        this.person = person;
    }
    //...
}
```

Person.java如下：

```java
package com.lei.common;

public class Person
{
    //...
}
```

### autowire ‘no’

默认情况下，需要通过'ref'或'value'者来装配bean，如下：

```xml
<bean id="customer" class="com.lei.common.Customer">
    <property name="person" ref="person" />
</bean>
 <bean id="person" class="com.lei.common.Person" />
```

### autowire ‘byName’

根据属性Property的名字装配bean，这种情况，Customer设置了autowire="byName"，Spring会自动寻找与属性名字“person”相同的bean，找到后，通过调用setPerson(Person person)将其注入属性。

```xml
<bean id="customer" class="com.lei.common.Customer" autowire="byName" />
<bean id="person" class="com.lei.common.Person" />
```

如果根据 Property name找不到对应的bean配置，如下
```xml
<bean id="customer" class="com.lei.common.Customer" autowire="byName" />
<bean id="person_another" class="com.lei.common.Person" />
```
Customer中Property名字是person，但是配置文件中找不到person，只有person_another，这时就会装配失败，运行后，Customer中person=null。

### autowire ‘byType

根据属性Property的数据类型自动装配，这种情况，Customer设置了autowire="byType"，Spring会总动寻找与属性类型相同的bean，找到后，通过调用setPerson(Person person)将其注入。

```xml
<bean id="customer" class="com.lei.common.Customer" autowire="byType" />
<bean id="person" class="com.lei.common.Person" />
```
如果配置文件中有两个类型相同的bean会怎样呢？如下：

```xml
<bean id="customer" class="com.lei.common.Customer" autowire="byType" />
<bean id="person" class="com.lei.common.Person" />
<bean id="person_another" class="com.lei.common.Person" />
 ```

 一旦配置如上，有两种相同数据类型的bean被配置，将抛出**UnsatisfiedDependencyException**异常，见以下：

```java
Exception in thread "main" org.springframework.beans.factory.UnsatisfiedDependencyException:
```

所以，一旦选择了’byType’类型的自动装配，请确认你的配置文件中每个数据类型定义一个**唯一**的bean。
### autowire ‘constructor’
这种情况下，Spring会寻找与参数数据类型相同的bean，通过构造函数public Customer(Person person)将其注入。

```xml
<bean id="customer" class="com.lei.common.Customer" autowire="constructor" />
<bean id="person" class="com.lei.common.Person" />
```
### autowire ‘autodetect’

这种情况下，Spring会先寻找Customer中是否有默认的构造函数，如果有相当于上边的’constructor’这种情况，用构造函数注入，否则，用’byType’这种方式注入，所以，此例中通过调用public Customer(Person person)将其注入。
```xml
<bean id="customer" class="com.lei.common.Customer" autowire="autodetect" />
<bean id="person" class="com.lei.common.Person" />
 ```

## 注意：

项目中autowire结合dependency-check一起使用是一种很好的方法，这样能够确保属性总是可以成功注入。
```xml
<bean id="customer" class="com.lei.common.Customer"
	autowire="autodetect" dependency-check="objects" />
<bean id="person" class="com.lei.common.Person" />
 ```

