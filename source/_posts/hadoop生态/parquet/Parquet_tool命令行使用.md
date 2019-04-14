---
title: Parquet-tool命令行使用
date: 2016-04-02 22:46:48
tags: 
  - parquet
categories: [hadoop生态,parquet]
---

To examine the internal structure and data of Parquet files, you can use the parquet-tools command that comes with CDH. Make sure this command is in your $PATH. (Typically, it is symlinked from /usr/bin; sometimes, depending on your installation setup, you might need to locate it under a CDH-specific bin directory.) The arguments to this command let you perform operations such as:

- cat:    打印文件的全部内容信息到标准输出
- head:  打印文件的头几行内容信息到标准输出
- schema: 打印Parquet的schema
- meta: 打印 file footer metadata, 包含 key-value properties (like Avro schema), compression ratios, encodings, compression used, and row group information.
- dump: 打印所有数据和metadata.

如果没有将jar配置到环境变量，可以使用`java -jar parquet-tools-1.8.2.jar -h`

Use parquet-tools -h to see usage information for all the arguments. Here are some examples showing parquet-tools usage

### cat 命令
```bash
$ # Be careful doing this for a big file! Use parquet-tools head to be safe.
$ parquet-tools cat sample.parq
year = 1992
month = 1
day = 2
dayofweek = 4
dep_time = 748
crs_dep_time = 750
arr_time = 851
crs_arr_time = 846
carrier = US
flight_num = 53
actual_elapsed_time = 63
crs_elapsed_time = 56
arrdelay = 5
depdelay = -2
origin = CMH
dest = IND
distance = 182
cancelled = 0
diverted = 0

year = 1992
month = 1
day = 3
...
```

### head 命令
```bash
$ parquet-tools head -n 2 sample.parq
year = 1992
month = 1
day = 2
dayofweek = 4
dep_time = 748
crs_dep_time = 750
arr_time = 851
crs_arr_time = 846
carrier = US
flight_num = 53
actual_elapsed_time = 63
crs_elapsed_time = 56
arrdelay = 5
depdelay = -2
origin = CMH
dest = IND
distance = 182
cancelled = 0
diverted = 0

year = 1992
month = 1
day = 3
...
```

### schema命令
```bash
$ parquet-tools schema sample.parq
message schema {
optional int32 year;
optional int32 month;
optional int32 day;
optional int32 dayofweek;
optional int32 dep_time;
optional int32 crs_dep_time;
optional int32 arr_time;
optional int32 crs_arr_time;
optional binary carrier;
optional int32 flight_num;
...
```

### meta 命令
```bash
$ parquet-tools meta sample.parq
creator:             impala version 2.2.0-cdh5.4.3 (build 517bb0f71cd604a00369254ac6d88394df83e0f6)

file schema:         schema
-------------------------------------------------------------------
year:                OPTIONAL INT32 R:0 D:1
month:               OPTIONAL INT32 R:0 D:1
day:                 OPTIONAL INT32 R:0 D:1
dayofweek:           OPTIONAL INT32 R:0 D:1
dep_time:            OPTIONAL INT32 R:0 D:1
crs_dep_time:        OPTIONAL INT32 R:0 D:1
arr_time:            OPTIONAL INT32 R:0 D:1
crs_arr_time:        OPTIONAL INT32 R:0 D:1
carrier:             OPTIONAL BINARY R:0 D:1
flight_num:          OPTIONAL INT32 R:0 D:1
...

row group 1:         RC:20636601 TS:265103674
-------------------------------------------------------------------
year:                 INT32 SNAPPY DO:4 FPO:35 SZ:10103/49723/4.92 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
month:                INT32 SNAPPY DO:10147 FPO:10210 SZ:11380/35732/3.14 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
day:                  INT32 SNAPPY DO:21572 FPO:21714 SZ:3071658/9868452/3.21 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
dayofweek:            INT32 SNAPPY DO:3093276 FPO:3093319 SZ:2274375/5941876/2.61 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
dep_time:             INT32 SNAPPY DO:5367705 FPO:5373967 SZ:28281281/28573175/1.01 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
crs_dep_time:         INT32 SNAPPY DO:33649039 FPO:33654262 SZ:10220839/11574964/1.13 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
arr_time:             INT32 SNAPPY DO:43869935 FPO:43876489 SZ:28562410/28797767/1.01 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
crs_arr_time:         INT32 SNAPPY DO:72432398 FPO:72438151 SZ:10908972/12164626/1.12 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
carrier:              BINARY SNAPPY DO:83341427 FPO:83341558 SZ:114916/128611/1.12 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
flight_num:           INT32 SNAPPY DO:83456393 FPO:83488603 SZ:10216514/11474301/1.12 VC:20636601 ENC:PLAIN_DICTIONARY,RLE,PLAIN
...
```

## Meta Legend

### Row Group Totals

| Acronym | Definition      |
| ------- | --------------- |
| RC      | Row Count       |
| TS      | Total Byte Size |

### Row Group Column Details

| Acronym        | Definition                               |
| -------------- | ---------------------------------------- |
| DO             | Dictionary Page Offset                   |
| FPO            | First Data Page Offset                   |
| SZ:{x}/{y}/{z} | Size in bytes. x = Compressed total, y = uncompressed total, z = y:x ratio |
| VC             | Value Count                              |
| RLE            | Run-Length Encoding                      |
