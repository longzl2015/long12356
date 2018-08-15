---

title: spring(2)-依赖注入-注解-自动装配

date: 2018-08-15 17:45:50

categories: [spring]

tags: [spring,依赖注入,注解]

---


依赖注入-注解形式

<!--more-->

## 构造方法注入

```java
public class MovieRecommender {

    private final CustomerPreferenceDao customerPreferenceDao;

    @Autowired
    public MovieRecommender(CustomerPreferenceDao customerPreferenceDao) {
        this.customerPreferenceDao = customerPreferenceDao;
    }

    // ...

}
```

## set 方法注入


单参数 

```java
public class SimpleMovieLister {

    private MovieFinder movieFinder;

    @Autowired
    public void setMovieFinder(MovieFinder movieFinder) {
        this.movieFinder = movieFinder;
    }

    // ...

}
```


多参数 

```java
public class MovieRecommender {

    private MovieCatalog movieCatalog;

    private CustomerPreferenceDao customerPreferenceDao;

    @Autowired
    public void prepare(MovieCatalog movieCatalog,
            CustomerPreferenceDao customerPreferenceDao) {
        this.movieCatalog = movieCatalog;
        this.customerPreferenceDao = customerPreferenceDao;
    }

    // ...

}
```

## 字段注入

```java
public class MovieRecommender {

    private final CustomerPreferenceDao customerPreferenceDao;

    @Autowired
    private MovieCatalog movieCatalog;

    @Autowired
    public MovieRecommender(CustomerPreferenceDao customerPreferenceDao) {
        this.customerPreferenceDao = customerPreferenceDao;
    }

    // ...

}
```


## 集合 注入

注入指定类型的所有实例 到 集合变量中 。

如果 需要 将 所有实例按指定顺序排序，则可以使用 @Order 或 @Priority 指定顺序。

```java
public class MovieRecommender {
    @Autowired
    private MovieCatalog[] movieCatalogs;
    // ...
}

public class MovieRecommender {

    private Set<MovieCatalog> movieCatalogs;
    @Autowired
    public void setMovieCatalogs(Set<MovieCatalog> movieCatalogs) {
        this.movieCatalogs = movieCatalogs;
    }
    // ...
}
```

## map<String,SomeType> 注入

以 string 类型为 key 的map: spring 会将 ApplicationContext 中的对应的 SomeType 注入 该map中。

key: 对应 bean 的 name
value: 对应 bean 的 instance 

```java
public class MovieRecommender {
    private Map<String, MovieCatalog> movieCatalogs;
    @Autowired
    public void setMovieCatalogs(Map<String, MovieCatalog> movieCatalogs) {
        this.movieCatalogs = movieCatalogs;
    }
    // ...
}
```

## 其他

@Autowired 也可以用在一些众所周知的接口上(BeanFactory, ApplicationContext, Environment, ResourceLoader, ApplicationEventPublisher, and MessageSource),
或者他们的 extended interfaces 上。

such as ConfigurableApplicationContext or ResourcePatternResolver, are automatically resolved, with no special setup necessary.

```java
public class MovieRecommender {

    @Autowired
    private ApplicationContext context;

    public MovieRecommender() {
    }

    // ...

}
```
