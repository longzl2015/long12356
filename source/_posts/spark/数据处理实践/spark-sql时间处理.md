---
title: Date and Time Functions
date: 2017-06-04 23:22:58
tags: 
  - spark
categories:
  - spark
---

## Date and Time Functions

[TOC]

| Name                | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| [current_date]      | Gives current date as a date column                          |
| [current_timestamp] |                                                              |
| [date_format]       |                                                              |
| [to_date]           | Converts column to date type (with an optional date format)  |
| [to_timestamp]      | Converts column to timestamp type (with an optional timestamp format) |
| [unix_timestamp]    | Converts current or specified time to Unix timestamp (in seconds) |
| [window]            | Generates time windows (i.e. tumbling, sliding and delayed windows) |

### current_date - Current Date As Date Column

```
current_date(): Column
```

`current_date` function gives the current date as a [date] column.

```
val df = spark.range(1).select(current_date)
scala> df.show
+--------------+
|current_date()|
+--------------+
|    2017-09-16|
+--------------+

scala> df.printSchema
root
 |-- current_date(): date (nullable = false)
```

Internally, `current_date` creates a [Column](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Column.html) with `CurrentDate` Catalyst leaf expression.

```
val c = current_date()
import org.apache.spark.sql.catalyst.expressions.CurrentDate
val cd = c.expr.asInstanceOf[CurrentDate]
scala> println(cd.prettyName)
current_date

scala> println(cd.numberedTreeString)
00 current_date(None)
```

### date_format

```
date_format(dateExpr: Column, format: String): Column
```

Internally, `date_format` creates a [Column](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Column.html) with `DateFormatClass` binary expression. `DateFormatClass` takes the expression from `dateExpr` column and `format`.

```
val c = date_format($"date", "dd/MM/yyyy")

import org.apache.spark.sql.catalyst.expressions.DateFormatClass
val dfc = c.expr.asInstanceOf[DateFormatClass]
scala> println(dfc.prettyName)
date_format

scala> println(dfc.numberedTreeString)
00 date_format('date, dd/MM/yyyy, None)
01 :- 'date
02 +- dd/MM/yyyy
```

### current_timestamp

```
current_timestamp(): Column
```

Note : `current_timestamp` is also `now` function in SQL. 

### unix_timestamp - Converting Current or Specified Time to Unix Timestamp

```
unix_timestamp(): Column  (1)
unix_timestamp(time: Column): Column (2)
unix_timestamp(time: Column, format: String): Column
```

1. Gives current timestamp (in seconds)
2. Converts `time` string in format `yyyy-MM-dd HH:mm:ss` to Unix timestamp (in seconds)

`unix_timestamp` converts the current or specified `time` in the specified `format` to a Unix timestamp (in seconds).

`unix_timestamp` supports a column of type `Date`, `Timestamp` or `String`.

```
// no time and format => current time
scala> spark.range(1).select(unix_timestamp as "current_timestamp").show
+-----------------+
|current_timestamp|
+-----------------+
|       1493362850|
+-----------------+

// no format so yyyy-MM-dd HH:mm:ss assumed
scala> Seq("2017-01-01 00:00:00").toDF("time").withColumn("unix_timestamp", unix_timestamp($"time")).show
+-------------------+--------------+
|               time|unix_timestamp|
+-------------------+--------------+
|2017-01-01 00:00:00|    1483225200|
+-------------------+--------------+

scala> Seq("2017/01/01 00:00:00").toDF("time").withColumn("unix_timestamp", unix_timestamp($"time", "yyyy/MM/dd")).show
+-------------------+--------------+
|               time|unix_timestamp|
+-------------------+--------------+
|2017/01/01 00:00:00|    1483225200|
+-------------------+--------------+
```

`unix_timestamp` returns `null` if conversion fails.

```
// note slashes as date separators
scala> Seq("2017/01/01 00:00:00").toDF("time").withColumn("unix_timestamp", unix_timestamp($"time")).show
+-------------------+--------------+
|               time|unix_timestamp|
+-------------------+--------------+
|2017/01/01 00:00:00|          null|
+-------------------+--------------+
```

Note:  `unix_timestamp` is also supported in [SQL mode]

```
scala> spark.sql("SELECT unix_timestamp() as unix_timestamp").show 
unix_timestamp
1493369225
```

Internally, `unix_timestamp` creates a [Column](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Column.html) with [UnixTimestamp](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Expression-UnixTimestamp.html) binary expression (possibly with `CurrentTimestamp`).

### window - Generating Time Windows 

```
window(
  timeColumn: Column,
  windowDuration: String): Column  (1)
window(
  timeColumn: Column,
  windowDuration: String,
  slideDuration: String): Column   (2)
window(
  timeColumn: Column,
  windowDuration: String,
  slideDuration: String,
  startTime: String): Column       (3)
```

1. Creates a tumbling time window with `slideDuration` as `windowDuration` and `0 second` for `startTime`
2. Creates a sliding time window with `0 second` for `startTime`
3. Creates a delayed time window

`window` generates **tumbling**, **sliding** or **delayed** time windows of `windowDuration` duration given a `timeColumn` timestamp specifying column.

Note:  From [Tumbling Window (Azure Stream Analytics)](https://msdn.microsoft.com/en-us/library/azure/dn835055.aspx):**Tumbling windows** are a series of fixed-sized, non-overlapping and contiguous time intervals.                                                       |

Note:  From [Introducing Stream Windows in Apache Flink](https://flink.apache.org/news/2015/12/04/Introducing-windows.html):**Tumbling windows** group elements of a stream into finite sets where each set corresponds to an interval.**Tumbling windows** discretize a stream into non-overlapping windows. 

```
scala> val timeColumn = window('time, "5 seconds")
timeColumn: org.apache.spark.sql.Column = timewindow(time, 5000000, 5000000, 0) AS `window`
```

`timeColumn` should be of [TimestampType](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-DataType.html#TimestampType), i.e. with [java.sql.Timestamp](https://docs.oracle.com/javase/8/docs/api/java/sql/Timestamp.html) values.

| Tip  | Use [java.sql.Timestamp.from](https://docs.oracle.com/javase/8/docs/api/java/sql/Timestamp.html#from-java.time.Instant-) or [java.sql.Timestamp.valueOf](https://docs.oracle.com/javase/8/docs/api/java/sql/Timestamp.html#valueOf-java.time.LocalDateTime-) factory methods to create `Timestamp` instances. |
| ---- | ------------------------------------------------------------ |
|      |                                                              |

```
// https://docs.oracle.com/javase/8/docs/api/java/time/LocalDateTime.html
import java.time.LocalDateTime
// https://docs.oracle.com/javase/8/docs/api/java/sql/Timestamp.html
import java.sql.Timestamp
val levels = Seq(
  // (year, month, dayOfMonth, hour, minute, second)
  ((2012, 12, 12, 12, 12, 12), 5),
  ((2012, 12, 12, 12, 12, 14), 9),
  ((2012, 12, 12, 13, 13, 14), 4),
  ((2016, 8,  13, 0, 0, 0), 10),
  ((2017, 5,  27, 0, 0, 0), 15)).
  map { case ((yy, mm, dd, h, m, s), a) => (LocalDateTime.of(yy, mm, dd, h, m, s), a) }.
  map { case (ts, a) => (Timestamp.valueOf(ts), a) }.
  toDF("time", "level")
scala> levels.show
+-------------------+-----+
|               time|level|
+-------------------+-----+
|2012-12-12 12:12:12|    5|
|2012-12-12 12:12:14|    9|
|2012-12-12 13:13:14|    4|
|2016-08-13 00:00:00|   10|
|2017-05-27 00:00:00|   15|
+-------------------+-----+

val q = levels.select(window($"time", "5 seconds"), $"level")
scala> q.show(truncate = false)
+---------------------------------------------+-----+
|window                                       |level|
+---------------------------------------------+-----+
|[2012-12-12 12:12:10.0,2012-12-12 12:12:15.0]|5    |
|[2012-12-12 12:12:10.0,2012-12-12 12:12:15.0]|9    |
|[2012-12-12 13:13:10.0,2012-12-12 13:13:15.0]|4    |
|[2016-08-13 00:00:00.0,2016-08-13 00:00:05.0]|10   |
|[2017-05-27 00:00:00.0,2017-05-27 00:00:05.0]|15   |
+---------------------------------------------+-----+

scala> q.printSchema
root
 |-- window: struct (nullable = true)
 |    |-- start: timestamp (nullable = true)
 |    |-- end: timestamp (nullable = true)
 |-- level: integer (nullable = false)

// calculating the sum of levels every 5 seconds
val sums = levels.
  groupBy(window($"time", "5 seconds")).
  agg(sum("level") as "level_sum").
  select("window.start", "window.end", "level_sum")
scala> sums.show
+-------------------+-------------------+---------+
|              start|                end|level_sum|
+-------------------+-------------------+---------+
|2012-12-12 13:13:10|2012-12-12 13:13:15|        4|
|2012-12-12 12:12:10|2012-12-12 12:12:15|       14|
|2016-08-13 00:00:00|2016-08-13 00:00:05|       10|
|2017-05-27 00:00:00|2017-05-27 00:00:05|       15|
+-------------------+-------------------+---------+
```

`windowDuration` and `slideDuration` are strings specifying the width of the window for duration and sliding identifiers, respectively.

Use `CalendarInterval` for valid window identifiers.

`window` is available as of Spark **2.0.0**. 

Internally, `window` creates a [Column](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Column.html) (with [TimeWindow](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Expression-TimeWindow.html) expression) available as `window` alias.

```
// q is the query defined earlier
scala> q.show(truncate = false)
+---------------------------------------------+-----+
|window                                       |level|
+---------------------------------------------+-----+
|[2012-12-12 12:12:10.0,2012-12-12 12:12:15.0]|5    |
|[2012-12-12 12:12:10.0,2012-12-12 12:12:15.0]|9    |
|[2012-12-12 13:13:10.0,2012-12-12 13:13:15.0]|4    |
|[2016-08-13 00:00:00.0,2016-08-13 00:00:05.0]|10   |
|[2017-05-27 00:00:00.0,2017-05-27 00:00:05.0]|15   |
+---------------------------------------------+-----+

scala> println(timeColumn.expr.numberedTreeString)
00 timewindow('time, 5000000, 5000000, 0) AS window#22
01 +- timewindow('time, 5000000, 5000000, 0)
02    +- 'time
```

#### Example — Traffic Sensor

The example is borrowed from [Introducing Stream Windows in Apache Flink](https://flink.apache.org/news/2015/12/04/Introducing-windows.html). 

The example shows how to use `window` function to model a traffic sensor that counts every 15 seconds the number of vehicles passing a certain location.

### to_date — Converting Column To DateType 

```
to_date(e: Column): Column
to_date(e: Column, fmt: String): Column
```

`to_date` converts the column into [DateType](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-DataType.html#DateType) (by casting to `DateType`).

`fmt` follows [the formatting styles](http://docs.oracle.com/javase/tutorial/i18n/format/simpleDateFormat.html).

Internally, `to_date` creates a [Column](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Column.html#creating-instance) with [ParseToDate](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Expression-ParseToDate.html) expression (and `Literal` expression for `fmt`).

Use [ParseToDate](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Expression-ParseToDate.html) expression to use a column for the values of `fmt`. 

### to_timestamp — Converting Column To TimestampType 

```
to_timestamp(s: Column): Column
to_timestamp(s: Column, fmt: String): Column
```

`to_timestamp` converts the column into [TimestampType](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-DataType.html#TimestampType) (by casting to `TimestampType`).

`fmt` follows [the formatting styles](http://docs.oracle.com/javase/tutorial/i18n/format/simpleDateFormat.html). 

Internally, `to_timestamp` creates a [Column](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Column.html#creating-instance) with [ParseToTimestamp](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Expression-ParseToTimestamp.html) expression (and `Literal`expression for `fmt`).

Use [ParseToTimestamp](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/spark-sql-Expression-ParseToTimestamp.html) expression to use a column for the values of `fmt`. 