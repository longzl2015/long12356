---
title: spring-2-自动扫描组件或Bean
date: 2019-06-09 11:09:02
tag: [自动扫描,components]
categories: [spring,springmvc]

---

Spring Auto Scanning Components —— 自动扫描组件
Spring Filter Components In Auto Scanning —— 在自动扫描中过滤组件

<!--more-->



通常你可以在xml配置文件中，声明一个bean或者component，然后Spring容器会检查和注册你的bean或component。实际上，Spring支持自动扫描bean或component，你可以不必再在xml文件中繁琐的声明bean，Spring会自动扫描、检查你指定包的bean或component。

以下列举一个简单的Spring Project，包含了Customer、Service、DAO层，让我们来看一下手动配置和自动扫描的不同。

## 手动配置组件

先看一下正常手动配置一个bean

DAO层，CustomerDAO.java如下：

```java
package com.lei.customer.dao;

public class CustomerDAO
{
    @Override
    public String toString() {
        return "Hello , This is CustomerDAO";
    }
}
```

Service层，CustomerService.java如下：

```java
package com.lei.customer.services;

import com.lei.customer.dao.CustomerDAO;

public class CustomerService
{
    CustomerDAO customerDAO;

    public void setCustomerDAO(CustomerDAO customerDAO) {
        this.customerDAO = customerDAO;
    }

    @Override
    public String toString() {
        return "CustomerService [customerDAO=" + customerDAO + "]";
    }

}
```

配置文件，Spring-Customer.xml文件如下：

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans-2.5.xsd">

    <bean id="customerService" class="com.lei.customer.services.CustomerService">
        <property name="customerDAO" ref="customerDAO" />
    </bean>

    <bean id="customerDAO" class="com.lei.customer.dao.CustomerDAO" />

</beans>
```

运行如下代码，App.java如下：

```java
package com.lei.common;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import com.lei.customer.services.CustomerService;

public class App
{
    public static void main( String[] args )
    {
        ApplicationContext context =
          new ClassPathXmlApplicationContext(new String[] {"Spring-Customer.xml"});

        CustomerService cust = (CustomerService)context.getBean("customerService");
        System.out.println(cust);

    }
}
```

输出结果：`CustomerService [customerDAO=Hello , This is CustomerDAO]`

## 自动扫描组件

现在，看一下怎样运用Spring的自动扫描。

用注释@Component来表示这个Class是一个自动扫描组件。

Customer.java如下：

```java
package com.lei.customer.dao;

import org.springframework.stereotype.Component;

@Component
public class CustomerDAO
{
    @Override
    public String toString() {
        return "Hello , This is CustomerDAO";
    }
}
```

CustomerService.java如下：

```java
package com.lei.customer.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.lei.customer.dao.CustomerDAO;

@Component
public class CustomerService
{
    @Autowired
    CustomerDAO customerDAO;

    @Override
    public String toString() {
        return "CustomerService [customerDAO=" + customerDAO + "]";
    }
}
```

配置文件Spring-customer.xml如下

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:context="http://www.springframework.org/schema/context"
    xsi:schemaLocation="http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans-2.5.xsd
    http://www.springframework.org/schema/context
    http://www.springframework.org/schema/context/spring-context-2.5.xsd">

    <context:component-scan base-package="com.lei.customer" />

</beans>
```

注意：

以上xml文件中，加入了“context:component-scan”标签，这样就将Spring的自动扫描特性引入，base-package表示你的组件的存放位置，Spring将扫描对应文件夹下的bean（用@Component注释过的），将这些bean注册到容器中。

最后运行结果与手动配置的结果一致。

### 自定义扫描组件名称

上例中，默认情况下，Spring将把组件Class的第一个字母变成小写，来作为自动扫描组件的名称，例如将“CustomerService”转变为“customerService”，你可以用“customerService”这个名字调用组件，如下：

CustomerService cust = (CustomerService)context.getBean("customerService");

你可以像下边这样，创建自定义的组件名称：

```java
@Service("AAA")
public class CustomerService
...
```

现在，可以调用自己定义的组件了，如下：
```java
CustomerService cust = (CustomerService)context.getBean("AAA");
```

### 自动扫描组件的注释类型

有4种注释类型，分别是：

@Component      ——表示一个自动扫描component

@Repository     ——表示持久化层的DAO component

@Service        ——表示业务逻辑层的Service component

@Controller     ——表示表示层的Controller component

以上4种，在应用时，我们应该用哪一种？让我们先看一下@Repository、@Service、@Controller的源代码

```java
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Component
public @interface Repository {

    String value() default "";

}
```

你还可以看一下@Service、@Controller的源代码，发现它们都用@Component注释过了，所以，在项目中，我们可以将所有自动扫描组件都用@Component注释，Spring将会扫描所有用@Component注释过得组件。

实际上，@Repository、@Service、@Controller三种注释是为了加强代码的阅读性而创造的，你可以在不同的应用层中，用不同的注释，就像下边这样。

DAO层：

```java
package com.lei.customer.dao;

import org.springframework.stereotype.Repository;

@Repository
public class CustomerDAO
{
    @Override
    public String toString() {
        return "Hello , This is CustomerDAO";
    }
}
```

Service层：

```java
package com.lei.customer.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.lei.customer.dao.CustomerDAO;

@Service
public class CustomerService
{
    @Autowired
    CustomerDAO customerDAO;

    @Override
    public String toString() {
        return "CustomerService [customerDAO=" + customerDAO + "]";
    }

}
```

Control层：

```java
@Controller("userAction")
public class UserAction {
    
}
```

## 在自动扫描中过滤组件

### Filter Component——include

下例演示了用“filter”自动扫描注册组件，这些组件只要匹配定义的“regex”的命名规则，Clasee前就不需要用@Component进行注释。

DAO层，CustomerDAO.java如下：

```java
package com.lei.customer.dao;

public class CustomerDAO
{
    @Override
    public String toString() {
        return "Hello , This is CustomerDAO";
    }
}
```


Service层，CustomerService.java如下：

```java
package com.lei.customer.services;

import org.springframework.beans.factory.annotation.Autowired;
import com.lei.customer.dao.CustomerDAO;

public class CustomerService
{
    @Autowired
    CustomerDAO customerDAO;

    @Override
    public String toString() {
        return "CustomerService [customerDAO=" + customerDAO + "]";
    }

}
```


Spring Filtering，xml配置如下：

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:context="http://www.springframework.org/schema/context"
    xsi:schemaLocation="http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans-2.5.xsd
    http://www.springframework.org/schema/context
    http://www.springframework.org/schema/context/spring-context-2.5.xsd">

    <context:component-scan base-package="com.lei" >

        <context:include-filter type="regex"
                       expression="com.lei.customer.dao.*DAO.*" />

        <context:include-filter type="regex"
                       expression="com.lei.customer.services.*Service.*" />

    </context:component-scan>

```

注意：

以上xml文件中，所有文件名字，只要包含DAO和Service（*DAO.*，*Service.*）关键字的，都将被检查注册到Spring容器中。



运行以下代码：

```java
package com.lei.common;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

import com.lei.customer.services.CustomerService;

public class App
{
    public static void main( String[] args )
    {
        ApplicationContext context =
        new ClassPathXmlApplicationContext(new String[] {"Spring-AutoScan.xml"});

        CustomerService cust = (CustomerService)context.getBean("customerService");
        System.out.println(cust);

    }
}
```


运行结果：`CustomerService [customerDAO=Hello , This is CustomerDAO]`


### Filter Component——exclude

你也可以用exclude，制定组件避免被Spring发现并被注册到容器中。

以下配置排除用@Service注释过的组件

```xml
<context:component-scan base-package="com.lei.customer" >
        <context:exclude-filter type="annotation"
            expression="org.springframework.stereotype.Service" />
</context:component-scan>
```

以下配置排除包含“DAO”关键字的组件

```xml
<context:component-scan base-package="com.lei" >
        <context:exclude-filter type="regex"
            expression="com.lei.customer.dao.*DAO.*" />
</context:component-scan>
```



参考：

[Spring3系列7- 自动扫描组件或Bean](http://www.cnblogs.com/leiOOlei/p/3547589.html)
