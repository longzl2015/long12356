---

title: mybaits 处理大数据集

date: 2019-04-14 20:51:00

categories: [mybatis]

tags: [mybatis]

---


mybaits 处理大数据集 本文只介绍 游标方式(Cursor). ResultHandler方式自行搜索。

<!--more-->


## Cursor(since 3.4.1)

使用 游标方式能 明显降低 应用内存的使用量

```java
public interface PersonMapper {
     Cursor<Person> selectAllPersons();
}


class Test{
    public static void main(String[] args){
        PersonMapper personMapper = ...;
        try (Cursor<Person> persons = personMapper.selectAllPersons()) {
           for (Person person : persons) {
              // process one person
           }
        }
    }
}
```

详细 内容 可见 https://ifrenzyc.github.io/2017/11/16/mysql-streaming/。



## 其他参考

[mysql streaming 的使用和约束](https://ifrenzyc.github.io/2017/11/16/mysql-streaming/)
[mybatis处理大数据集](https://stackoverflow.com/questions/32333461/mybatis-return-large-result-with-xml-configuration-in-spring)
[mybaits使用流式查询避免数据量过大造成oom](http://ifeve.com/mybatis%E4%B8%AD%E4%BD%BF%E7%94%A8%E6%B5%81%E5%BC%8F%E6%9F%A5%E8%AF%A2%E9%81%BF%E5%85%8D%E6%95%B0%E6%8D%AE%E9%87%8F%E8%BF%87%E5%A4%A7%E5%AF%BC%E8%87%B4oom/)
[mysql stream方式读取超大结果集](https://www.cnblogs.com/logicbaby/p/4281100.html)
