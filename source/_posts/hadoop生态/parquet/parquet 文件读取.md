
---
title: parquet 文件读取
date: 2016-04-02 22:46:48
tags: 
  - parquet
categories: [hadoop生态,parquet]
---

## 获取文件行数 - ParquetFileReader.readFooters

```java
  String hdfspath = "/user/mls_zl/mysql2hdfs/parquet/time";
        Configuration configuration = new Configuration(true);
        configuration.set("fs.defaultFS", "hdfs://10.100.1.131:9000");
        Path inputPath = new Path(hdfspath);

        FileStatus inputFileStatus = inputPath.getFileSystem(configuration).getFileStatus(inputPath);
        List<Footer> footers = org.apache.parquet.hadoop.ParquetFileReader.readFooters(HdfsUtils.getConfiguration(),
                inputFileStatus, false);
        for (Footer footer : footers) {
            System.out.println("file:" + footer.getFile().toString());
            long cout = 0;
            for (BlockMetaData blockMetaData : footer.getParquetMetadata().getBlocks()) {
                cout += blockMetaData.getRowCount();
            }

            System.out.println("size:" + cout);
        }
```



## 递归统计 - RemoteIterator<LocatedFileStatus>

```Java
fs = FileSystem.get(HdfsUtils.getConfiguration());
Path parquetFile;
boolean isFirst = true;

RemoteIterator<LocatedFileStatus> listFiles = fs.listFiles(new Path(tablePath), true);
while (listFiles.hasNext()) {
    LocatedFileStatus fileStatus = listFiles.next();
    if (fileStatus.isFile() && fileStatus.getPath().toString().toLowerCase().endsWith(".parquet")) {
        parquetFile = fileStatus.getPath();
        fileSize += fileStatus.getLen();

        parquetFileReader = new ParquetFileReader(HdfsUtils.getConfiguration(), parquetFile,
                ParquetMetadataConverter.NO_FILTER);
        rows += parquetFileReader.getRecordCount();
        if (isFirst) {
            columns = (long) parquetFileReader.getFileMetaData().getSchema().getFieldCount();
            isFirst = false;
        }
        parquetFileReader.close();
    }
}
```



## 读取文件信息

```java
public void read1(){
	ParquetMetadata readFooter = ParquetFileReader.readFooter(fs.getConf(), path, ParquetMetadataConverter.NO_FILTER);
    MessageType schema = readFooter.getFileMetaData().getSchema();
    List<type> columnInfos = schema.getFields();
    ParquetReader<group> reader = ParquetReader.builder(new GroupReadSupport(), path).
                             withConf(fs.getConf()).build();
    int count = 0;
    Group recordData = reader.read();
 
    while (count < 10 && recordData != null) {
                 int last = columnInfos.size() - 1;
                 StringBuilder builder = new StringBuilder();
                 builder.append("{\"");
                 for (int j = 0; j < columnInfos.size(); j++) {
                     if (j < columnInfos.size() - 1) {
                         String columnName = columnInfos.get(j).getName();
                         String value = recordData.getValueToString(j, 0);
                         builder.append(columnName + "\":\"" + value + "\",");
                     }
                 }
                 String columnName = columnInfos.get(last).getName();
                 String value = recordData.getValueToString(last, 0);
 
                 System.out.println(builder.toString());
                 count++;
                 recordData = reader.read();
    }
 
   } catch (Exception e) {
   }
}

```