---
title: parquet时间格式总结
tags: 
  - parquet
categories:
  - hadoop
---

## 一、sqoop生成

sqoop 将 mysql 等关系型数据库的数据导入到hive数据库中 并 生成parquet文件时，会将`date类型`转换成 `INT64`。

同时 sqoop 会在 parquet 的`fileMetaData`中记录原先的sql类型信息，如下所示：

| type   | sql type | parquet type | 字段名       |
| ------ | -------- | ------------ | ------------ |
| long   | -5       | INT64        | TABLE_ID     |
| string | 12       | binary       | TABLE_NAME   |
| int    | 4        | int32        | TABLE_TYPE   |
| long   | 93       | Int64        | MODIFY_TIME  |
| bytes  | -4       | binary       | TABLE_SCHEMA |

```json
{
  "type": "record",
  "name": "dw_data_table",
  "doc": "Sqoop import of dw_data_table",
  "fields": [
    {
      "name": "TABLE_ID",
      "type": [
        "null",
        "long"
      ],
      "default": null,
      "columnName": "TABLE_ID",
      "sqlType": "-5"
    },
    {
      "name": "TABLE_NAME",
      "type": [
        "null",
        "string"
      ],
      "default": null,
      "columnName": "TABLE_NAME",
      "sqlType": "12"
    },
    {
      "name": "TABLE_TYPE",
      "type": [
        "null",
        "int"
      ],
      "default": null,
      "columnName": "TABLE_TYPE",
      "sqlType": "4"
    },
    {
      "name": "MODIFY_TIME",
      "type": [
        "null",
        "long"
      ],
      "default": null,
      "columnName": "MODIFY_TIME",
      "sqlType": "93"
    },
    {
      "name": "TABLE_SCHEMA",
      "type": [
        "null",
        "bytes"
      ],
      "default": null,
      "columnName": "TABLE_SCHEMA",
      "sqlType": "-4"
    }
  ],
  "tableName": "dw_data_table"
}
```



## 二、spark 生成

Spark 将 mysql 等关系型数据库的数据导入到hdfs中 并 生成parquet文件时，会将`date类型`转换成 `INT96`。

同样 spark也会在 parquet 的fileMetaData中记录相关类型信息，如下所示：

| type      | 字段名           | parquet type |
| :-------- | ---------------- | ------------ |
| long      | TABLE_ID         | INT64        |
| string    | TABLE_NAME       | binary       |
| int       | TABLE_TYPE       | int32        |
| timestamp | LAST_UPDATE_TIME | Int96        |
| binary    | TABLE_SCHEMA     | binary       |

```json
{
  "type": "struct",
  "fields": [
    {
      "name": "TABLE_ID",
      "type": "long",
      "nullable": false,
      "metadata": {
        "name": "TABLE_ID",
        "scale": 0
      }
    },
    {
      "name": "TABLE_NAME",
      "type": "string",
      "nullable": false,
      "metadata": {
        "name": "TABLE_NAME",
        "scale": 0
      }
    },
    {
      "name": "TABLE_TYPE",
      "type": "integer",
      "nullable": false,
      "metadata": {
        "name": "TABLE_TYPE",
        "scale": 0
      }
    },
    {
      "name": "LAST_UPDATE_TIME",
      "type": "timestamp",
      "nullable": false,
      "metadata": {
        "name": "LAST_UPDATE_TIME",
        "scale": 0
      }
    },
    {
      "name": "TABLE_SCHEMA",
      "type": "binary",
      "nullable": true,
      "metadata": {
        "name": "TABLE_SCHEMA",
        "scale": 0
      }
    }
  ]
}
```

## 三、 总结

### 3.1 对于 INT96

一定是timestamp类型

### 3.2 对于INT64

可能是 





源码：

```scala
 typeName match {
      case BOOLEAN => BooleanType

      case FLOAT => FloatType

      case DOUBLE => DoubleType

      case INT32 =>
        originalType match {
          case INT_8 => ByteType
          case INT_16 => ShortType
          case INT_32 | null => IntegerType
          case DATE => DateType
          case DECIMAL => makeDecimalType(Decimal.MAX_INT_DIGITS)
          case UINT_8 => typeNotSupported()
          case UINT_16 => typeNotSupported()
          case UINT_32 => typeNotSupported()
          case TIME_MILLIS => typeNotImplemented()
          case _ => illegalType()
        }

      case INT64 =>
        originalType match {
          case INT_64 | null => LongType
          case DECIMAL => makeDecimalType(Decimal.MAX_LONG_DIGITS)
          case UINT_64 => typeNotSupported()
          case TIMESTAMP_MILLIS => typeNotImplemented()
          case _ => illegalType()
        }

      case INT96 =>
        ParquetSchemaConverter.checkConversionRequirement(
          assumeInt96IsTimestamp,
          "INT96 is not supported unless it's interpreted as timestamp. " +
            s"Please try to set ${SQLConf.PARQUET_INT96_AS_TIMESTAMP.key} to true.")
        TimestampType

      case BINARY =>
        originalType match {
          case UTF8 | ENUM | JSON => StringType
          case null if assumeBinaryIsString => StringType
          case null => BinaryType
          case BSON => BinaryType
          case DECIMAL => makeDecimalType()
          case _ => illegalType()
        }

      case FIXED_LEN_BYTE_ARRAY =>
        originalType match {
          case DECIMAL => makeDecimalType(maxPrecisionForBytes(field.getTypeLength))
          case INTERVAL => typeNotImplemented()
          case _ => illegalType()
        }

      case _ => illegalType()
    }
```



