---
title: 日志获取API
date: 2016-04-02 22:46:48
tags: 
  - yarn
categories: [hadoop生态,yarn]
---

```java
package test;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileContext;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.fs.RemoteIterator;
import org.apache.hadoop.security.UserGroupInformation;
import org.apache.hadoop.yarn.api.records.ApplicationId;
import org.apache.hadoop.yarn.api.records.ApplicationReport;
import org.apache.hadoop.yarn.client.api.YarnClient;
import org.apache.hadoop.yarn.conf.YarnConfiguration;
import org.apache.hadoop.yarn.exceptions.YarnException;
import org.apache.hadoop.yarn.logaggregation.AggregatedLogFormat;
import org.apache.hadoop.yarn.logaggregation.LogAggregationUtils;
import org.apache.hadoop.yarn.util.Times;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.DataInputStream;
import java.io.EOFException;
import java.io.FileNotFoundException;
import java.io.IOException;

public class GetLogTask {

    private static Logger logger = LoggerFactory.getLogger(GetLogTask.class);

    public String getLog(ApplicationId appId, String appOwner, Configuration conf) throws Exception {
        checkLogAggregationEnable(conf);
        int resultCode = verifyApplicationState(appId, conf);
        if (resultCode != 0) {
            throw new Exception("Application has not completed." +
                    " Logs are only available after an application completes");
        }

        if (appOwner == null || appOwner.isEmpty()) {
            appOwner = UserGroupInformation.getCurrentUser().getShortUserName();
        }

        return dumpAllContainersLogs(appId, appOwner, conf);
    }

    private String dumpAllContainersLogs(ApplicationId appId, String appOwner, Configuration conf) throws
            Exception {

        StringBuilder output = new StringBuilder();
        Path remoteRootLogDir = new Path(conf.get(
                YarnConfiguration.NM_REMOTE_APP_LOG_DIR,
                YarnConfiguration.DEFAULT_NM_REMOTE_APP_LOG_DIR));
        String logDirSuffix = LogAggregationUtils.getRemoteNodeLogDirSuffix(conf);

        Path remoteAppLogDir = LogAggregationUtils.getRemoteAppLogDir(
                remoteRootLogDir, appId, appOwner, logDirSuffix);
        RemoteIterator<FileStatus> nodeFiles = null;
        try {
            Path qualifiedLogDir = FileContext.getFileContext(conf).makeQualified(remoteAppLogDir);
            nodeFiles = FileContext.getFileContext(qualifiedLogDir.toUri(), conf).listStatus(remoteAppLogDir);
        } catch (FileNotFoundException fnf) {
            logDirNotExist(remoteAppLogDir.toString());
        }
        boolean foundAnyLogs = false;
        assert nodeFiles != null;

        //遍历 所有节点
        while (nodeFiles.hasNext()) {
            FileStatus thisNodeFile = nodeFiles.next();
            if (!thisNodeFile.getPath().getName().endsWith(LogAggregationUtils.TMP_FILE_SUFFIX)) {
                AggregatedLogFormat.LogReader reader = new AggregatedLogFormat.LogReader(conf, thisNodeFile.getPath());
                try {
                    DataInputStream valueStream;
                    AggregatedLogFormat.LogKey key = new AggregatedLogFormat.LogKey();
                    valueStream = reader.next(key);

                    while (valueStream != null) {

                        String containerString = "\n\nContainer: " + key + " on " + thisNodeFile.getPath().getName();
                        output.append(containerString).append("\n");
                        output.append(StringUtils.repeat("=", containerString.length())).append("\n");
                        while (true) {
                            try {
                                readContainerLogs(valueStream, output, thisNodeFile.getModificationTime());
                                foundAnyLogs = true;
                            } catch (EOFException eof) {
                                break;
                            }
                        }

                        // Next container
                        key = new AggregatedLogFormat.LogKey();
                        valueStream = reader.next(key);
                    }
                } finally {
                    reader.close();
                }
            }
        }
        if (!foundAnyLogs) {
            emptyLogDir(remoteAppLogDir.toString());
        }

        return output.toString();
    }

    private int verifyApplicationState(ApplicationId appId, Configuration conf) throws IOException,
            YarnException {
        YarnClient yarnClient = null;
        try {
            yarnClient = YarnClient.createYarnClient();
            yarnClient.init(conf);
            yarnClient.start();
            ApplicationReport appReport = yarnClient.getApplicationReport(appId);
            switch (appReport.getYarnApplicationState()) {
                case NEW:
                case NEW_SAVING:
                case ACCEPTED:
                case SUBMITTED:
                case RUNNING:
                    return -1;
                case FAILED:
                case FINISHED:
                case KILLED:
                default:
                    break;
            }
        } finally {
            if (yarnClient != null) {
                yarnClient.close();
            }
        }
        return 0;
    }

    private void logDirNotExist(String remoteAppLogDir) throws Exception {
        throw new FileNotFoundException(remoteAppLogDir + " does not exist.\n" + "Log aggregation has not completed " +
                "or is not " + "enabled.");
    }

    private void emptyLogDir(String remoteAppLogDir) throws Exception {
        logger.warn(remoteAppLogDir + " does not have any log files.");
    }


    private void readContainerLogs(DataInputStream valueStream,
                                   StringBuilder out, long logUploadedTime) throws IOException {
        byte[] buf = new byte[65535];

        String fileType = valueStream.readUTF();
        String fileLengthStr = valueStream.readUTF();
        long fileLength = Long.parseLong(fileLengthStr);

        out.append("ContainerLog-start ").append(StringUtils.repeat("-", 80)).append("\n");

        out.append("LogType:").append(fileType).append("\n");
        if (logUploadedTime != -1) {
            out.append("Log Upload Time:").append(Times.format(logUploadedTime)).append("\n");
        }
        out.append("LogLength:");
        out.append(fileLengthStr).append("\n\n");
        out.append("Log Contents:").append("\n");

        long curRead = 0;
        long pendingRead = fileLength - curRead;
        int toRead = pendingRead > buf.length ? buf.length : (int) pendingRead;
        int len = valueStream.read(buf, 0, toRead);
        while (len != -1 && curRead < fileLength) {
            out.append(new String(buf, 0, len));
            curRead += len;

            pendingRead = fileLength - curRead;
            toRead =
                    pendingRead > buf.length ? buf.length : (int) pendingRead;
            len = valueStream.read(buf, 0, toRead);
        }
        out.append("End of LogType:").append(fileType).append("\n");
        out.append("").append("\n");
    }


    private void checkLogAggregationEnable(Configuration conf) throws Exception {
        String isEnable = conf.get(YarnConfiguration.LOG_AGGREGATION_ENABLED);
        if (!"true".equalsIgnoreCase(isEnable)) {
            throw new Exception("LOG_AGGREGATION_ENABLED must be ENABLED");
        }
    }
}

```

