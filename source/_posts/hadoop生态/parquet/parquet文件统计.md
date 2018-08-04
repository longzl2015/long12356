---
title: parquet文件统计
tags: 
  - parquet
categories:
  - hadoop
---

```Java
 public static Map<String, Long> statisticsParquet(String tablePath) throws IOException {
        Map<String, Long> map = new HashMap<>(3);
        Long rows = 0L;
        Long columns = 0L;
        Long fileSize = 0L;

        FileSystem fs = null;
        ParquetFileReader parquetFileReader = null;
        try {
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

        } finally {
            if (fs != null) {
                try {
                    fs.close();
                } catch (IOException e) {
                    logger.error("FileSystem close ", e);
                }
            }
            if (parquetFileReader != null) {
                try {
                    parquetFileReader.close();
                } catch (IOException e) {
                    logger.error(e.getLocalizedMessage(), e);
                }
            }
        }

        map.put("rows", rows);
        map.put("columns", columns);
        map.put("fileSize", fileSize);
        return map;
    }
```