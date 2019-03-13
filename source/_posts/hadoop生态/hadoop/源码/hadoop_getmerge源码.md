---
title: hadoop 源码 - 命令getMerge
date: 2016-04-02 22:46:48
tags: 
  - hadoop
categories: [hadoop生态,hadoop]
---

`hadoop fs -getMerge` 源码位于 `hadoop-common` 包的 `org.apache.hadoop.fs.shell.CopyCommands `类中，以下文章以2.7.3版本为例。


```java
class CopyCommands {  
  public static void registerCommands(CommandFactory factory) {
    factory.addClass(Merge.class, "-getmerge");
    factory.addClass(Cp.class, "-cp");
    factory.addClass(CopyFromLocal.class, "-copyFromLocal");
    factory.addClass(CopyToLocal.class, "-copyToLocal");
    factory.addClass(Get.class, "-get");
    factory.addClass(Put.class, "-put");
    factory.addClass(AppendToFile.class, "-appendToFile");
  }
  /** merge multiple files together */
  public static class Merge extends FsCommand {
    public static final String NAME = "getmerge";    
    public static final String USAGE = "[-nl] <src> <localdst>";
    public static final String DESCRIPTION =
      "Get all the files in the directories that " +
      "match the source file pattern and merge and sort them to only " +
      "one file on local fs. <src> is kept.\n" +
      "-nl: Add a newline character at the end of each file.";

    protected PathData dst = null;
    protected String delimiter = null;
    protected List<PathData> srcs = null;

    @Override
    /** 准备输入输出变量 */
    protected void processOptions(LinkedList<String> args) throws IOException {
      try {
        CommandFormat cf = new CommandFormat(2, Integer.MAX_VALUE, "nl");
        cf.parse(args);

        delimiter = cf.getOpt("nl") ? "\n" : null;

        dst = new PathData(new URI(args.removeLast()), getConf());
        if (dst.exists && dst.stat.isDirectory()) {
          throw new PathIsDirectoryException(dst.toString());
        }
        srcs = new LinkedList<PathData>();
      } catch (URISyntaxException e) {
        throw new IOException("unexpected URISyntaxException", e);
      }
    }

    @Override
    /** 依次将Input文件流写入outPut文件流*/
    protected void processArguments(LinkedList<PathData> items)
    throws IOException {
      super.processArguments(items);
      if (exitCode != 0) { // check for error collecting paths
        return;
      }
      FSDataOutputStream out = dst.fs.create(dst.path);
      try {
        for (PathData src : srcs) {
          FSDataInputStream in = src.fs.open(src.path);
          try {
            IOUtils.copyBytes(in, out, getConf(), false);
            if (delimiter != null) {
              out.write(delimiter.getBytes("UTF-8"));
            }
          } finally {
            in.close();
          }
        }
      } finally {
        out.close();
      }      
    }
 
    @Override
    protected void processNonexistentPath(PathData item) throws IOException {
      exitCode = 1; // flag that a path is bad
      super.processNonexistentPath(item);
    }

    // this command is handled a bit differently than others.  the paths
    // are batched up instead of actually being processed.  this avoids
    // unnecessarily streaming into the merge file and then encountering
    // a path error that should abort the merge
    
    @Override
    protected void processPath(PathData src) throws IOException {
      // for directories, recurse one level to get its files, else skip it
      if (src.stat.isDirectory()) {
        if (getDepth() == 0) {
          recursePath(src);
        } // skip subdirs
      } else {
        srcs.add(src);
      }
    }
  }
}
```

