
---
title: parquet文件结构相关类
tags: 
  - parquet
categories:
  - hadoop
---

![parquet_classes](../../图/parquet_classes.png)

## 1、parquet文件结构相关类

### ParquetMetadata

ParquetMetaData类封装了Parquet文件的元数据信息，其包含一个FileMetaData类和一个BlockMetaData List，并且提供静态方法，采用org.codehaus.jackson包将ParquetMetaData变成json格式，当然也提供函数将json格式的元数据转换成一个ParquetMetaData对象。

```java
public class ParquetMetadata {
    private static ObjectMapper objectMapper = new ObjectMapper();
    private static ObjectMapper prettyObjectMapper = new ObjectMapper();
    private final FileMetaData fileMetaData;
    private final List<BlockMetaData> blocks;
}
```

### FileMetaData

FileMetaData类包含文件的元数据，包含数据描述信息schema、String键值对`Map<String,String>`、以及文件创建版本信息。

```java
public final class FileMetaData implements Serializable {
    private static final long serialVersionUID = 1L;
    private final MessageType schema;
    private final Map<String, String> keyValueMetaData;
    private final String createdBy;
}
```

keyValueMetaData中一般会存储parquet的补充信息，不同软件生成的信息不同：

- sparksql生成的信息如下：

```
{
org.apache.spark.sql.parquet.row.metadata={
  "type":"struct",
  "fields":[
    {"name":"apply_cnt","type":"string","nullable":true,"metadata":{}},
    {"name":"bbr_addressno","type":"string","nullable":true,"metadata":{}},
    {"name":"bbr_age","type":"string","nullable":true,"metadata":{}},
    {"name":"bbr_is_has_medica","type":"string","nullable":true,"metadata":{}},
    {"name":"bbr_marriage","type":"string","nullable":true,"metadata":{}},
    {"name":"bbr_sex","type":"string","nullable":true,"metadata":{}},
    {"name":"bd_amnt_sum","type":"string","nullable":true,"metadata":{}},
    {"name":"bd_lccont_year","type":"string","nullable":true,"metadata":{}},
    {"name":"dir_work_time","type":"string","nullable":true,"metadata":{}},
    {"name":"dlr_bd_chuxian","type":"string","nullable":true,"metadata":{}},
    {"name":"dlr_if_have_backgroud","type":"string","nullable":true,"metadata":{}},
    {"name":"dlr_kind_accresult2","type":"string","nullable":true,"metadata":{}},
    {"name":"grtno","type":"string","nullable":true,"metadata":{}},
    {"name":"label","type":"string","nullable":true,"metadata":{}},
    {"name":"last_declinepay_amt","type":"double","nullable":true,"metadata":{}},
    {"name":"last_declinepay_cnt","type":"double","nullable":true,"metadata":{}},
    {"name":"last_realpay_amt","type":"double","nullable":true,"metadata":{}},
    {"name":"last_realpay_cnt","type":"double","nullable":true,"metadata":{}},
    {"name":"pol_num","type":"double","nullable":true,"metadata":{}},
    {"name":"prem_sum","type":"double","nullable":true,"metadata":{}},
    {"name":"prt_accidentdate_del","type":"double","nullable":true,"metadata":{}},
    {"name":"self_pol","type":"double","nullable":true,"metadata":{}},
    {"name":"tabfeemoney","type":"double","nullable":false,"metadata":{}},
    {"name":"tbr_accilccont_cnt","type":"double","nullable":false,"metadata":{}},
    {"name":"tbr_age","type":"double","nullable":false,"metadata":{}},
    {"name":"tbr_appntsex","type":"double","nullable":false,"metadata":{}},
    {"name":"tbr_lccont_cnt","type":"double","nullable":false,"metadata":{}},
    {"name":"tbr_marriage","type":"double","nullable":false,"metadata":{}},
    {"name":"tbr_year_prem","type":"double","nullable":false,"metadata":{}},
    {"name":"bsfit_result","type":"string","nullable":true,"metadata":{}}
    ]
  }}
```

- sqoop生成的如下:

```
{
avro.schema={
  "type":"record",
  "name":"dw_data_table",
  "doc":"Sqoop import of dw_data_table",
  "fields":[
    {"name":"TABLE_ID","type":["null","long"],"default":null,"columnName":"TABLE_ID","sqlType":"-5"},
    {"name":"TABLE_NAME","type":["null","string"],"default":null,"columnName":"TABLE_NAME","sqlType":"12"},
    {"name":"TABLE_TYPE","type":["null","int"],"default":null,"columnName":"TABLE_TYPE","sqlType":"4"},
    {"name":"DW_ID","type":["null","long"],"default":null,"columnName":"DW_ID","sqlType":"-5"},
    {"name":"NODE_INSTANCE_ID","type":["null","long"],"default":null,"columnName":"NODE_INSTANCE_ID","sqlType":"-5"},
    {"name":"COLUMNS","type":["null","long"],"default":null,"columnName":"COLUMNS","sqlType":"-5"},
    {"name":"TABLE_ROWS","type":["null","long"],"default":null,"columnName":"TABLE_ROWS","sqlType":"-5"},
    {"name":"FILE_SIZE","type":["null","long"],"default":null,"columnName":"FILE_SIZE","sqlType":"-5"},
    {"name":"FILE_PATH","type":["null","string"],"default":null,"columnName":"FILE_PATH","sqlType":"12"},
    {"name":"MODIFY_TIME","type":["null","long"],"default":null,"columnName":"MODIFY_TIME","sqlType":"93"},
    {"name":"STORAGE_TYPE","type":["null","int"],"default":null,"columnName":"STORAGE_TYPE","sqlType":"4"},
    {"name":"TABLE_DESC","type":["null","string"],"default":null,"columnName":"TABLE_DESC","sqlType":"12"},
    {"name":"STATUS","type":["null","int"],"default":null,"columnName":"STATUS","sqlType":"4"},
    {"name":"LAST_UPDATE_TIME","type":["null","long"],"default":null,"columnName":"LAST_UPDATE_TIME","sqlType":"93"},
    {"name":"LAST_UPDATE_OPER","type":["null","string"],"default":null,"columnName":"LAST_UPDATE_OPER","sqlType":"12"},
    {"name":"CREATE_TIME","type":["null","long"],"default":null,"columnName":"CREATE_TIME","sqlType":"93"},
    {"name":"CREATE_OPER","type":["null","string"],"default":null,"columnName":"CREATE_OPER","sqlType":"12"},
    {"name":"TABLE_SCHEMA","type":["null","bytes"],"default":null,"columnName":"TABLE_SCHEMA","sqlType":"-4"}
    ],
  "tableName":"dw_data_table"}}
```




### BlockMetaData

row group元数据

```Java
public class BlockMetaData {
    private List<ColumnChunkMetaData> columns = new ArrayList();
    private long rowCount;
    private long totalByteSize;
    private String path;
}
```

### MessageType

MessageType 是 GroupType 的子类，代表Parquet描述数据字段的schema的根节点

```java
public final class MessageType extends GroupType {
}
```



## 2、数据类型相关类

### Type

抽象类Type封装了当前字段的名称、重复类型（Repetition）、以及逻辑类型（OriginalType）。

其中OriginalType中对应关系：

|MAP|LIST|UTF8|MAP_KEY_VALUE|ENUM|DECIMAL|
| ---- | ---- | ---- | ---- | ---- | ---- |
|哈希映射表Map|线性表List|UTF8编码的字符串|包含键值对的Map|枚举类型|十进制数|

```Java
public abstract class Type {
    private final String name;
    private final Type.Repetition repetition;
    private final OriginalType originalType;
    private final Type.ID id;
}
```

**Type 有两个子类PrimitiveType和GroupType**，分别代表Parquet支持的原始数据类型和Group多个字段的组合类型。

### GroupType

多个字段的组合类型

```java
public class GroupType extends Type {
    private final List<Type> fields;
    private final Map<String, Integer> indexByName;
}
```

### PrimitiveType

Parquet支持的原始数据类型

```java
public final class PrimitiveType extends Type {
    private final PrimitiveType.PrimitiveTypeName primitive;
    private final int length;
    private final DecimalMetadata decimalMeta;
}
```

## 3、Group相关

### Group

抽象类Group表示包含一组字段的Parquet schema节点类型，封装了各种类型的 add方法和get方法

### SimpleGroup

SimpleGroup是Group的一个子类，一个最简单形式的Group：包含一个GroupType 和字段数据。

GroupType表示Group类型。

`List<Object>[] data `保存该Group中的字段数据，各字段在List数组中的顺序和GroupType中定义的一致。List列表中既可以保存Primitive类型的原始数据类型，也可以保存一个Group。也就是说一个SimpleGroup类型可以表示由schema表示的一行记录。

```
public class SimpleGroup extends Group {
  private final GroupType schema;
  private final List<Object>[] data;
}  
```



## 参考

[列式存储 Parquet](https://my.oschina.net/jhone/blog/517918)

