---
title: OGNL 语言介绍与实践(转)
date: 2018-06-04 23:22:58
tags: 
  - OGNL
  - mybaits
categories:
  - mybaits
---

## OGNL 的基本语法

OGNL 表达式一般都很简单。虽然 OGNL 语言本身已经变得更加丰富了也更强大了，但是一般来说那些比较复杂的语言特性并未影响到 OGNL 的简洁：简单的部分还是依然那么简单。比如要获取一个对象的 name 属性，OGNL 表达式就是 name, 要获取一个对象的 headline 属性的 text 属性，OGNL 表达式就是 headline.text 。 OGNL 表达式的基本单位是“导航链”，往往简称为“链”。最简单的链包含如下部分：

| 表达式组成部分 | 示例                                                  |
| -------------- | ----------------------------------------------------- |
| 属性名称       | 如上述示例中的 name 和 headline.text                  |
| 方法调用       | hashCode() 返回当前对象的哈希码。                     |
| 数组元素       | listeners[0] 返回当前对象的监听器列表中的第一个元素。 |

所有的 OGNL 表达式都基于当前对象的上下文来完成求值运算，链的前面部分的结果将作为后面求值的上下文。你的链可以写得很长，例如：

`name.toCharArray()[0].numericValue.toString()`

上面的表达式的求值步骤：

 - 提取根 (root) 对象的 name 属性。
 - 调用上一步返回的结果字符串的 toCharArray() 方法。
 - 提取返回的结果数组的第一个字符。
 - 获取字符的 numericValue 属性，该字符是一个 Character 对象，Character 类有一个 getNumericValue() 方法。
 - 调用结果 Integer 对象的 toString() 方法。

上面的例子只是用来得到一个对象的值，OGNL 也可以用来去设置对象的值。当把上面的表达式传入 Ognl.setValue() 方法将导致 InappropriateExpressionException，因为链的最后的部分（`toString()`）既不是一个属性的名字也不是数组的某个元素。 了解了上面的语法基本上可以完成绝大部分工作了。


### OGNL 表达式

1. 常量： 字符串：“ hello ” 字符：‘ h ’ 数字：除了像 java 的内置类型 int,long,float 和 double,Ognl 还有如例：10.01B，相当于 java.math.BigDecimal，使用’ b ’或者’ B ’后缀。 100000H，相当于 java.math.BigInteger，使用’ h ’ 或 ’ H ’ 后缀。
2. 属性的引用 例如：user.name
3. 变量的引用 例如：#name
4. 静态变量的访问 使用 @class@field
5. 静态方法的调用 使用 @class@method(args), 如果没有指定 class 那么默认就使用 java.lang.Math.
6. 构造函数的调用 例如：new java.util.ArrayList();

其它的 Ognl 的表达式可以参考 Ognl 的语言手册。

### mybatis 使用 OGNL 例子


```xml
<select id="select" parameterType="com.xingguo.springboot.model.User"  resultType="com.xingguo.springboot.model.User">
        select username,password from t_user 
        where 1=1
        <choose>
        <!--调用静态方法 -->
            <when test="@com.xingguo.springboot.model.TestConstant@checkStatus(state,0)">
                <!--调用静态常量 -->
                AND state = ${@com.xingguo.springboot.model.TestConstant@STATUS_0}
            </when>
            <otherwise>
                AND state = ${@com.xingguo.springboot.model.TestConstant@STATUS_1}
            </otherwise>
        </choose>
    </select>
```

```java
package com.xingguo.springboot.model;

public class TestConstant {
    //静态常量
    public static final int STATUS_0 = 0;
    public static final int STATUS_1 = 1;

    //静态方法
    public static Boolean checkStatus(int sourceStatus,int targetStatus){
        return sourceStatus == targetStatus;
    }
}
```





## 来源

[](https://www.ibm.com/developerworks/cn/opensource/os-cn-ognl/index.html)