---
title: mybaits like 使用
date: 2018-04-02 22:46:48
tags: 
  - mybatis
categories:
  - mybatis
---

通用 like 查询：

```
<select id="xxx" ...>
    select id,name,... from country
    <where>
        <if test="name != null and name != ''">
        <bind name="nameLike" value="'%' + name + '%'"/>
            name like #{nameLike}
        </if>
    </where>
</select>
```

bind 标签最好放到 if 标签内部，如果放在 if 标签外部，可能会引起空指针异常


## 模糊查询3中方式

### OGNL 

```xml
<select id="select" parameterType="com.xingguo.springboot.model.User"  resultType="com.xingguo.springboot.model.User">
        select username,password from t_user 
        where 1=1
        <!-- OGNL处理${这里的表达式}的结果值 -->
        <if test="username != null and username != ''">
          and username like '${'%' + username + '%'}'
        </if>
    </select>
```

### 一般方式

```xml
<select id="select" parameterType="com.xingguo.springboot.model.User"  resultType="com.xingguo.springboot.model.User">
        select username,password from t_user 
        <where>
            <!-- 使用concat -->
            <if test="username != null and username != ''">
              username like concat('%', #{username}, '%')
            </if>
        </where>

    </select>
```

### bind

```xml
<select id="select" parameterType="com.xingguo.springboot.model.User"  resultType="com.xingguo.springboot.model.User">
        select username,password from t_user 
        <bind name="nameLike" value="'%' + username + '%'"/>
        <where>
            <if test="username != null and username != ''">
              username like #{nameLike}
            </if>
        </where>
</select>
```