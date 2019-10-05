---

title: spark_udf_udaf

date: 2019-09-11 10:47:35

categories: [spark]

tags: [spark,udf,udaf]

---

spark_udf_udaf

<!--more-->

## 简要使用

### udf 

[Spark笔记之使用UDF](https://www.cnblogs.com/cc11001100/p/9463909.html)

#### udf 匿名函数

```scala
object SparkUdfInSqlBasicUsageStudy {
  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder().master("local[*]").appName("SparkUdfStudy").getOrCreate()
    import spark.implicits._
    // 注册可以在sql语句中使用的UDF
    spark.udf.register("to_uppercase", (s: String) => s.toUpperCase())
    // 创建一张表
    Seq((1, "foo"), (2, "bar")).toDF("id", "text").createOrReplaceTempView("t_foo")
    spark.sql("select id, to_uppercase(text) from t_foo").show()
  }
}
```

#### udf 实现 UDF0-UDF22 接口

UDF1中的 1 代表 入参个数。

即: 实现 UDF1 的类接收 1 个入参和 1 个返回值

```scala
object SparkUdfInSqlBasicUsageStudy {
  def main(args: Array[String]): Unit = {
	SparkSession spark = SparkSession.builder().appName("CSV to Dataset").master("local").getOrCreate();
	spark.udf().register("x2Multiplier", new UDF1<Integer, Integer>() {
		private static final long serialVersionUID = -5372447039252716846L;
		@Override
		public Integer call(Integer x) {
			return x * 2;
		}
	}, DataTypes.IntegerType);
    //....
  }
}
```


### udaf

[Spark笔记之使用UDAF](https://www.cnblogs.com/cc11001100/p/9471859.html)

## udf 使用注意点

### udf 调用顺序不被保证

[Evaluation order and null checking](https://docs.databricks.com/spark/latest/spark-sql/udf-scala.html)

如下语句中，`s is not null` 和 `strlen(s) > 1` 的先后执行顺序无法保证。

```sparksql
spark.udf.register("strlen", (s: String) => s.length)
spark.sql("select s from test1 where s is not null and strlen(s) > 1") // no guarantee
```

因此，对于控制检查的推荐做法有二:

1. 在 UDF 函数中处理空值问题
2. 在 sql 中 使用 `if` 或者 `CASE WHEN`语句

```sparksql
spark.udf.register("strlen_nullsafe", (s: String) => if (s != null) s.length else -1)
spark.sql("select s from test1 where s is not null and strlen_nullsafe(s) > 1") // ok

spark.sql("select s from test1 where if(s is not null, strlen(s), null) > 1")   // ok
```

