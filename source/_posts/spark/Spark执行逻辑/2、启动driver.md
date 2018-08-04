
---
title: 启动Driver
tags: 
  - spark
categories:
  - spark
---

# 启动Driver

前面介绍了从命令行提交任务开始，至Master注册Driver的流程。接下来是 Master将注册的Driver信息发送到Worker，在Worker节点启动Driver。

## 一、Master发送LaunchDriver消息

上一节讲到 Master 接收 ClientEndPoint发送的注册Driver的信息。接下来调用schedule()方法，启动Driver和Executor，查看schedule() 

```scala
override def receiveAndReply(context: RpcCallContext): PartialFunction[Any, Unit] = {
    case RequestSubmitDriver(description) =>
      if (state != RecoveryState.ALIVE) {
        val msg = s"${Utils.BACKUP_STANDALONE_MASTER_PREFIX}: $state. " +
          "Can only accept driver submissions in ALIVE state."
        context.reply(SubmitDriverResponse(self, false, None, msg))
      } else {
        logInfo("Driver submitted " + description.command.mainClass)
        val driver = createDriver(description)
        // 持久化Driver 用于master recovery 时恢复Driver
        persistenceEngine.addDriver(driver)
        // 注册 Driver
        waitingDrivers += driver
        drivers.add(driver)
        // launch Driver 和 Executor
        schedule()
        context.reply(SubmitDriverResponse(self, true, Some(driver.id),
          s"Driver successfully submitted as ${driver.id}"))
      }
    //忽略
    ...
  }
```

schedule() 方法

```scala
private def schedule(): Unit = {
  if (state != RecoveryState.ALIVE) {
    return
  }
  // 打乱Worker顺序，避免Driver过度集中
  val shuffledAliveWorkers = Random.shuffle(workers.toSeq.filter(_.state == WorkerState.ALIVE))
  val numWorkersAlive = shuffledAliveWorkers.size
  var curPos = 0
  // 变量Worker如果Work节点剩余内存和core足够，启动Driver
  for (driver <- waitingDrivers.toList) { // iterate over a copy of waitingDrivers
    var launched = false
    var numWorkersVisited = 0
    while (numWorkersVisited < numWorkersAlive && !launched) {
      val worker = shuffledAliveWorkers(curPos)
      numWorkersVisited += 1
      if (worker.memoryFree >= driver.desc.mem && worker.coresFree >= driver.desc.cores) {
        launchDriver(worker, driver)
        waitingDrivers -= driver
        launched = true
      }
      curPos = (curPos + 1) % numWorkersAlive
    }
  }
  startExecutorsOnWorkers()
}

```

schedule中调用**launchDriver(worker, driver)**方法

```scala
private def launchDriver(worker: WorkerInfo, driver: DriverInfo) {
    logInfo("Launching driver " + driver.id + " on worker " + worker.id)
    worker.addDriver(driver)
    driver.worker = Some(worker)
    // 调用RpcEndPointRef，发送LauncherDriver消息给Worker节点
    // 此Work是 schedule 随机选择的
    worker.endpoint.send(LaunchDriver(driver.id, driver.desc))
    driver.state = DriverState.RUNNING
  }
```

## 二、Worker节点启动Driver

Worker的receive方法接收并处理**LaunchDriver**信息，如下 

```scala
 override def receive: PartialFunction[Any, Unit] = synchronized {
 
    case LaunchDriver(driverId, driverDesc) =>
      logInfo(s"Asked to launch driver $driverId")
     // 封装Driver信息为DriverRunner
      val driver = new DriverRunner(
        conf,
        driverId,
        workDir,
        sparkHome,
        driverDesc.copy(command = Worker.maybeUpdateSSLSettings(driverDesc.command, conf)),
        self,
        workerUri,
        securityMgr)
      drivers(driverId) = driver
     // 启动Driver
      driver.start()

      coresUsed += driverDesc.cores
      memoryUsed += driverDesc.mem
   // 忽略
     ...
  }
```

查看DriverRunner的start方法

```scala
 /** Starts a thread to run and manage the driver. */
  private[worker] def start() = {
    new Thread("DriverRunner for " + driverId) {
      override def run() {
        var shutdownHook: AnyRef = null
        try {
          shutdownHook = ShutdownHookManager.addShutdownHook { () =>
            logInfo(s"Worker shutting down, killing driver $driverId")
            kill()
          }

          // 准备 driver jars and 运行 driver
          val exitCode = prepareAndRunDriver()

          // set final state depending on if forcibly killed and process exit code
          finalState = if (exitCode == 0) {
            Some(DriverState.FINISHED)
          } else if (killed) {
            Some(DriverState.KILLED)
          } else {
            Some(DriverState.FAILED)
          }
        } catch {
          case e: Exception =>
            kill()
            finalState = Some(DriverState.ERROR)
            finalException = Some(e)
        } finally {
          if (shutdownHook != null) {
            ShutdownHookManager.removeShutdownHook(shutdownHook)
          }
        }

        // notify worker of final driver state, possible exception
        worker.send(DriverStateChanged(driverId, finalState.get, finalException))
      }
    }.start()
  }

```

```scala
private[worker] def prepareAndRunDriver(): Int = {
  // 下载Driver jar 到Worker本地，即本示例中的 /path/to/examples.jar
  val driverDir = createWorkingDirectory()
  val localJarFilename = downloadUserJar(driverDir)
  // 替换参数中的workerUrl和localJarFilename
  def substituteVariables(argument: String): String = argument match {
    case "{{WORKER_URL}}" => workerUrl
    case "{{USER_JAR}}" => localJarFilename
    case other => other
  }

  // 将Driver中的参数组织为Linux命令
  // 通过java执行组织好的命令
  val builder = CommandUtils.buildProcessBuilder(driverDesc.command, securityManager,
    driverDesc.mem, sparkHome.getAbsolutePath, substituteVariables)
  // 这一步就是启动Driver，即执行 /parh/to/examples.jar中的main方法
  runDriver(builder, driverDir, driverDesc.supervise)
}
```

执行步骤如上图注释，最终使用Java中的**java.lang.ProcessBuilder**类执行Linux命令的方式启动Driver，Linux命令大致如下 

```sh
java -cp $SPARK_ASSEMBLY_JAR \
  -Xms1024M -Xmx1024M -Dakka.loglevel=WARNING \
  -Dspark.executor.memory=512m \
  -Dspark.driver.supervise=false \
  -Dspark.submit.deployMode=cluster \
  -Dspark.app.name=org.apache.spark.examples.SparkPi \
  -Dspark.rpc.askTimeout=10 \
  -Dspark.master=$MasterUrl -XX:MaxPermSize=256m \
  org.apache.spark.deploy.worker.DriverWrapper \
  $WorkerUrl \
  /path/to/example.jar \
  org.apache.spark.examples.SparkPi \
  1000
```

到这里，通过spark-submit上传的**/path/to/examples.jar**，通过**java -cp**命令在Worker节点开始运行了，即Launch Driver，所谓的Driver就是**/path/to/examples.jar**。 
最后，将Driver的执行状态返回给Master。

## 总结

介绍了Master将Driver发送到Worker，及在Worker节点启动Driver的流程，如下 

```sequence
title:master启动driver节点

note over Master: receiveAndReply\n(case RequsetSubmitDriver)
Master -> Master: 调用
note over Master: schedule
Master -> Master: 调用
note over Master: launchDriver
Master -> Worker: 发送LaunchDriver消息
note over Worker: receive\n(case LaunchDriver)
Worker -> DriverRunner: 启动Driver命令
note over DriverRunner: start
DriverRunner -> DriverRunner:调用 
note over DriverRunner: launchDriver
DriverRunner -> ProcessBuilder: 调用
note over ProcessBuilder: 拼装 java 启动命令，并执行
```