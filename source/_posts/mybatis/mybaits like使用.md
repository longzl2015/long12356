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