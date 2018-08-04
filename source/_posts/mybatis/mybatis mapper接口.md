---
title: mybatis mapper接口
date: 2015-09-03 23:22:58
tag: ["mybatis"]
categories: mybatis
---

原始dao开发方法和mapper代理方法的比较。
[原文地址](http://www.cnblogs.com/selene/p/4605191.html)
<!--more-->

## 原始dao开发方法

### DAO接口类UserDAO.java　　

```java
package com.mybatis.dao;
import java.util.List;
import com.mybatis.entity.User;
/**
 *
 * @ClassName: UserDAO
 * @Description: TODO(用户管理DAO接口)
 * @author warcaft
 * @date 2015-6-27 下午10:23:42
 *
 */
public interface UserDAO {
    /** 根据ID查询用户信息*/
    public User findUserById(Integer id);

    /**根据用户名称模糊查询用户信息*/
    public List<User>  findUserByName(String username);

    /** 添加用户*/
    public void insertUser(User user);

    /** 根据ID删除用户*/
    public void deleteUser(Integer id);

    /** 根据ID更新用户*/
    public void updateUser(User user);
}
```

### dao实现类UserDaoImpl.java　

```java
package com.mybatis.dao;
import java.util.List;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import com.mybatis.entity.User;
/**
 *
 * @ClassName: UserDaoImpl
 * @Description: TODO(用户管理接口的实现类)
 * @author warcaft
 * @date 2015-6-27 下午10:29:35
 *
 */
public class UserDaoImpl implements UserDAO {
    private SqlSessionFactory sqlSessionFactory;
    // 需要向dao实现类中注入SqlSessionFactory
    // 通过构造方法注入
    public UserDaoImpl(SqlSessionFactory sqlSessionFactory) {
        this.sqlSessionFactory = sqlSessionFactory;
    }

    @Override
    public User findUserById(Integer id) {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        User user = sqlSession.selectOne("test.findUserById", id);
        // 释放资源
        sqlSession.close();
        return user;
    }

    @Override
    public List<User> findUserByName(String username) {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        List<User> list = sqlSession
                .selectList("test.findUserByName", username);

        // 提交事务
        sqlSession.commit();
        // 释放资源
        sqlSession.close();
        return list;
    }

    @Override
    public void insertUser(User user) {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        // 执行插入操作
        sqlSession.insert("test.insertUser", user);
        // 提交事务
        sqlSession.commit();
        // 释放资源
        sqlSession.close();
    }

    @Override
    public void deleteUser(Integer id) {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        // 执行插入操作
        sqlSession.delete("test.deleteUser", id);
        // 提交事务
        sqlSession.commit();
        // 释放资源
        sqlSession.close();
    }

    @Override
    public void updateUser(User user) {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        // 执行插入操作
        sqlSession.update("test.updateUser", user);
        // 提交事务
        sqlSession.commit();
        // 释放资源
        sqlSession.close();
    }

}
```

### JunitTest测试UserDaoImplTest.java

```java
package com.mybatis.dao.test;
import java.io.InputStream;
import java.util.Date;
import java.util.List;
import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.junit.Before;
import org.junit.Test;

import com.mybatis.dao.UserDaoImpl;
import com.mybatis.entity.User;

public class UserDaoImplTest {

    private SqlSessionFactory sqlSessionFactory;

    @Before
    public void setUp() throws Exception {
        String resource = "SqlMapConfig.xml";
        InputStream inputStream = Resources.getResourceAsStream(resource);
        sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);
    }

    @Test
    public void findUserByIdTest() {
        UserDaoImpl userDao = new UserDaoImpl(sqlSessionFactory);
        User user = userDao.findUserById(1);
        System.out.println(user);
    }

    @Test
    public void findUserByNameTest() {
        UserDaoImpl userDao = new UserDaoImpl(sqlSessionFactory);
        List<User> list = userDao.findUserByName("小");
        System.out.println(list);
    }

    @Test
    public void insertUserTest() {
        UserDaoImpl userDao = new UserDaoImpl(sqlSessionFactory);
        User user = new User();
        user.setUsername("张三丰");
        user.setSex("1");
        user.setBirthday(new Date());
        user.setAddress("武当山");
        userDao.insertUser(user);
    }

    @Test
    public void deleteUserTest() {
        UserDaoImpl userDao = new UserDaoImpl(sqlSessionFactory);
        userDao.deleteUser(8);
    }

    @Test
    public void updateUserTest() {
        UserDaoImpl userDao = new UserDaoImpl(sqlSessionFactory);
        User user = new User();
        user.setId(1);
        user.setUsername("王六");
        user.setSex("2");
        user.setAddress("天津");
        user.setBirthday(new Date());
        userDao.updateUser(user);
    }
}
```

### 小结
该方法存在以下几个问题：

1. dao接口中存在大量模版方法，能否把这些代码提出来，减少我们的工作量

2. 调用sqlSession方法时将statement的id硬编码了

3. 调用sqlSession传入的变量，由于sqlSession方法使用泛型，即使变量类型传入错误，在编译阶段也不报错，不利于程序开发。

所以我们带着这几个问题看看mapper代理开发的方法，是否能解决这些问题呢？

## mapper代理方法(只需要mapper接口，相当于dao接口)

### 概要：
1. 编写XXXmapper.xml的映射文件
2. 编写mapper接口需要遵循一些开发规范，mybatis可以自动生成mapper接口实现类代理对象。

### 开发规范：

- 在XXXmapper.xml中namespace等于mapper接口地址；

![mybatis_mapper_1.png](http://7xlgbq.com1.z0.glb.clouddn.com/static/images/mybatis_mapper_1.png)
- XXXmapper.java接口中的方法和mapper.xml中的statement的Id一致。
- mapper.java接口中的方法输入参数和mapper.xml中statement的parameterType指定的类型一致。
- mapper.java接口中的方法的返回值类型和mapper.xml中statement的resultType指定的类型一致。
![mybatis_mapper_2.png](http://7xlgbq.com1.z0.glb.clouddn.com/static/images/mybatis_mapper_2.png)

![mybatis_mapper_3.png](http://7xlgbq.com1.z0.glb.clouddn.com/static/images/mybatis_mapper_3.png)
　　

以上的开发规范主要是对下面的代码进行统一生成　

```java
    SqlSession sqlSession = sqlSessionFactory.openSession();
    User user = sqlSession.selectOne("test.findUserById", id);
　　......
```

### UserMapper.java类代码

```java
package com.mybatis.mapper;

import java.util.List;
import com.mybatis.entity.User;

/**
 *
 * @ClassName: UserDAO
 * @Description: TODO(用户管理mapper接口)
 * @author warcaft
 * @date 2015-6-27 下午10:23:42
 *
 */
public interface UserMapper {
    /** 根据ID查询用户信息 */
    public User findUserById(int id);

    /** 根据用户名称模糊查询用户信息 */
    public List<User> findUserByName(String username);

    /** 添加用户 */
    public void insertUser(User user);

    /** 根据ID删除用户 */
    public void deleteUser(Integer id);

    /** 根据ID更新用户 */
    public void updateUser(User user);

}
```

### 将原来的User.xml拷贝修改名称为UserMapper.xml,只需修改此行代码即可

```xml
<!-- namespace命名空间,作用就是对sql进行分类化的管理,理解为sql隔离
    注意:使用mapper代理开发时，namespace有特殊作用,namespace等于mapper接口地址
 -->
<mapper namespace="com.mybatis.mapper.UserMapper">
```

### 在SqlMapConfig.xml中加载UserMapper.xml

```xml
<!-- 加载映射文件 -->
    <mappers>
        <mapper resource="sqlmap/User.xml"/>
        <mapper resource="mapper/UserMapper.xml"/>
    </mappers>
```

### Junit测试UserMapperTest.java

```java
package com.mybatis.dao.test;

import java.io.InputStream;
import java.util.Date;
import java.util.List;

import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.junit.Before;
import org.junit.Test;

import com.mybatis.entity.User;
import com.mybatis.mapper.UserMapper;

public class UserMapperTest {

    private SqlSessionFactory sqlSessionFactory;

    // 此方法是在执行findUserByIdTest之前执行
    @Before
    public void setUp() throws Exception {
        String resource = "SqlMapConfig.xml";
        InputStream inputStream = Resources.getResourceAsStream(resource);
        // 创建SqlSessionFcatory
        sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);
    }

    @Test
    public void testFindUserById() {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        // 创建Usermapper对象，mybatis自动生成mapper代理对象
        UserMapper mapper = sqlSession.getMapper(UserMapper.class);
        User user = mapper.findUserById(1);
        System.out.println(user);
        sqlSession.close();
    }

    @Test
    public void testFindUserByName() {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        // 创建Usermapper对象，mybatis自动生成mapper代理对象
        UserMapper mapper = sqlSession.getMapper(UserMapper.class);
        List<User> list = mapper.findUserByName("小");
        System.out.println(list);
        sqlSession.close();
    }

    @Test
    public void testDeleteUser() {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        // 创建Usermapper对象，mybatis自动生成mapper代理对象
        UserMapper mapper = sqlSession.getMapper(UserMapper.class);
        mapper.deleteUser(6);
        sqlSession.commit();
        sqlSession.close();
    }

    @Test
    public void testInsertUser() {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        // 创建Usermapper对象，mybatis自动生成mapper代理对象
        User user = new User();
        user.setUsername("者别");
        user.setSex("1");
        user.setAddress("蒙古乞颜部落");
        user.setBirthday(new Date());
        UserMapper mapper = sqlSession.getMapper(UserMapper.class);
        mapper.insertUser(user);
        sqlSession.commit();
        sqlSession.close();
    }

    @Test
    public void testUpdateUser() {
        SqlSession sqlSession = sqlSessionFactory.openSession();
        // 创建Usermapper对象，mybatis自动生成mapper代理对象
        User user = new User();
        user.setId(11);//必须设置Id
        user.setUsername("神箭手者别");
        user.setSex("1");
        user.setAddress("蒙古乞颜部落");
        user.setBirthday(new Date());
        UserMapper mapper = sqlSession.getMapper(UserMapper.class);
        mapper.updateUser(user);
        sqlSession.commit();
        sqlSession.close();
    }

}
```
### 小结

1. 代理对象内部调用selectOne()和selectList():如果mapper对象返回单个pojo对象(非集合对象)代理对象内部通过selectOne查询数据库，如果mapper方法返回集合对象，代理对象内部通过selectList查询数据库。

2. mapper接口中的方法参数只能有一个是否影响系统开发：

　　mapper接口方法参数只能有一个，系统是否不利于维护？

　　回答：系统框架中，dao层的代码是被业务层公用的。机试mapper接口只有一个参数，可以使用包装类型的pojo满足不同的业务方法的需求。
