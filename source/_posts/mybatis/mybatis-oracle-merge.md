---

title: mybatis-oracle-merge

date: 2018-08-17 17:27:00

categories: [mybatis]

tags: [mybatis,oracle,merge]

---

merge into 能够以一次请求实现 类似于insertOrUpdate的操作。减少请求次数。


<!--more-->

```xml

    <insert id="insertOrUpdate" parameterType="ArrayList">
        merge into P_MAP_TENANT_USER r using
        (
        <foreach collection="pMapTenantUsers" index="index" item="item" open="" close="" separator="union">
            select
            #{item.tenantId} as TENANT_ID,
            #{item.userId} as USER_ID,
            #{item.roleType} as ROLE_TYPE
            from dual
        </foreach>
        )tmp
        on (
        tmp.TENANT_ID = r.TENANT_ID
        and tmp.USER_ID = r.USER_ID
        )
        when matched THEN
        update
        <set>
            r.ROLE_TYPE = tmp.ROLE_TYPE,
        </set>
        when not matched THEN
        insert
        <trim prefix="(" suffix=")" suffixOverrides="," >
            TENANT_ID ,
            USER_ID ,
            ROLE_TYPE
        </trim>
        <trim  prefix="values (" suffix=")" suffixOverrides=",">
            tmp.TENANT_ID,
            tmp.USER_ID,
            tmp.ROLE_TYPE
        </trim>
    </insert>
```

### merge into clause

需要被更新的表


### using clause

新增或者更新的数据源。


### on clause

指定条件，只有满足条件的行会被更新和替换


### update clause

标准的 update 参数，需要注意的是，set 参数里不能出现 on clause 出现的 参数

### insert clause

标准的 insert 参数

