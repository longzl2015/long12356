---
title: spring-2-依赖注入-xml
date: 2015-08-10 13:26:58
tag: [依赖注入,xml]
categories: [spring,springmvc]

---
本章介绍依赖注入的相关细节

<!--more-->

# 属性注入和构造器注入
---

## 属性注入

class: bean的**全类名**，通过反射的方式在IOC容器中创建Bean，所以要求Bean中必须有**无参数**的构造器。
id：标识容器中的 bean。id 唯一。

`xml文件`

```xml
    <bean id="employeeDao" class="com.atguigu.ssh.dao.EmployeeDao" scope="Singleton" autowire="byName">
    <property name="sessionFactory" ref="sessionFactory"></property>
    </bean>
```

### autowire标签：

> autowire="byName"

表示会根据name来完成注入。

> autowire="byType"

byType表示根据类型注入。

使用byType注入:如果一个类中有两个同类型的对象就会抛出异常。所以在开发中**一般都是使用byName。**

虽然自动注入可以减少配置，但是通过bean文件无法很好了解整个类的结果，**所以不建议使用autowire。**

### scope标签：

对应四个属性：默认为Singleton

- 	Propotypr： 多例
- 	Singleton： 单例,只实例化一个bean对象
- 	Session：
- 	Request：

### property属性：

- Name:

Name 中的值会在对应对象中调用 setXX 方法来注入，xx代表 name 的值。

> name="userDao"

在具体注入时会调用 setUserDao(IUserDao userDao) 来完成注入。

- ref：

> ref="sessionFactory"

表示是配置文件中的 bean 中所创建的 DAO 的 id 。

- value：

> value="2"

创建了一个User对象user,id为1，username为悟空，如果要注入值不使用ref而是使用value
	<bean id="user" class="org.zttc.itat.spring.model.User">
		<property name="id" value="2"/>
		<property name="username" value="八戒"/>
	</bean>

## 构造器注入。

要求bean当中需要**对应的有参数**构造函数。这方式不常用，基本都是使用set方法注入

- **按索引匹配入参**
`xml文件`
```xml
<bean id="car" chass="com.zju.spring.beans.HelloWorld">
	<constructor-arg value="奥迪" index= '0' > </constructor-arg>
	<constructor-arg value="长春一汽" index='1'> </constructor-arg>
</bean>
```

- **按类型匹配入参**
使用构造器注入属性值可以指定参数的位置和参数的类型！以区分重载的构造器！
`xml文件`
```xml
<bean id="helloworld" chass="com.zju.spring.beans.HelloWorld">
	<constructor-arg value="奥迪" type="java.lang.String"></constructor-arg>
	<constructor-arg value="长春一汽" type="java.lang.String"></constructor-arg>
</bean>
```

# 注入属性值的细节

---


### 特殊字符赋值

如果字面值包含特殊字符，可以使用 <![CDATA[]]> 包裹起来

```xml
<constructor-arg type="java.lang.String">
	<value><![CDATA[<shanghai^>]]></value>
</constructor-arg>
```

### 引用其他Bean

如果bean当中有使用其他类，就无法使用value对其进行复制了，改为使用ref

- **外部bean**
```xml
<property name ="car">
	<ref bean="car"/>
</property>
```

- **内部bean**
  当 Bean 实例仅仅给一个特定的属性使用时, 可以将其声明为内部 Bean. 内部 Bean 声明直接包含在 `<property>` 或 `<constructor-arg>` 元素里, 不需要设置任何 id 或 name 属性
  内部bean，不能被外部引用，只能被内部引用。
```xml
<property name ="car">
	<constructor-arg value="奥迪" index=0></constructor-arg>
	<constructor-arg value="长春一汽" index=1></constructor-arg>
</property>
```

### 赋值null

```xml
<constructor-arg><null/></constructor-arg>
```

### 级联属性复制

注意：属性需要先初始化后才可以为级联属性赋值，否则会出现异常，和strusts2不同。
```xml
<property name ="Car.maxSpeed" value="251"></property>
```

### 配置集合属性

- **list属性值**
使用list节点为list类型的属性赋值
```xml
<property name="cars">
	<list>
		<ref bean="car1"/>
		<ref bean="car2"/>
		<bean class="com.zju.spring.beans.Car">
			<constructor-arg value="奥迪" index=0></constructor-arg>
			<constructor-arg value="长春一汽" index=1></constructor-arg>
		</bean>
	</list>
</property>
```
- **map属性值**
使用map节点及map的entry子节点配置map类型的子成员对象。
```xml
<property name="cars">
	<map>
		<entry key="AA" value-ref="car"></entry>
		<entry key="BB" value-ref="car2"></entry>
	</map>
</property>
```

- **properties属性值**
```xml
<property name="properties">
	<props>
		<prop key="user">root</prop>
		<prop key="password">1234</prop>
		<prop key="jdbd">jdbc:mysql:///test</prop>
		<prop key="driverClass">com.mysql.jdbc.Driver</prop>
</property>
```

### util标签
必须在文件头部添加 util 命名空间
```xml
<util:list id="cars">
	<ref bean="car">
	<ref bean="car2">
</util:list>

<bean id="persion" class="com.zju.spring.collection.Persion">
	<property name="name" value="jack"></property>
	<property age="age" value="29"></property>
	<property name="cars" ref="cars"></property>
</bean>
```

### p命名空间
必须在文件头部添加 p 命名空间
```xml
<bean id="persion5" class="com.zju.spring.collection.Persion" p:age="30" p:name="Queen" p:cars-ref="cars"></bean>
```
  方法