---
title: SparkContext初始化过程
date: 2017-06-04 23:22:58
tags: 
  - spark
categories:
  - spark
---

# SparkContext初始化过程

SparkContext是程序执行的入口，一个SparkContext代表一个应用，深入理解spark运行时机制，首先要了解SparkContext初始化过程。

### 一、SparkContext的定义

```scala
//Spark程序的入口
class SparkContext(config: SparkConf) extends Logging {
  private val creationSite: CallSite = Utils.getCallSite()
  private val allowMultipleContexts: Boolean =
    config.getBoolean("spark.driver.allowMultipleContexts", false)

```

构造参数为SparkConf，SparkConf内部用ConcurrentHashMap存储各种配置信息，初始化时会加载所有以**spark.**开头的环境变量。 

```scala
// Spark程序的配置信息
// 加载所有以Spark开头的环境变量
class SparkConf(loadDefaults: Boolean) extends Cloneable with Logging with Serializable {
  import SparkConf._
  def this() = this(true)
  private val settings = new ConcurrentHashMap[String, String]()

  @transient private lazy val reader: ConfigReader = {
    val _reader = new ConfigReader(new SparkConfigProvider(settings))
    _reader.bindEnv(new ConfigProvider {
      override def get(key: String): Option[String] = Option(getenv(key))
    })
    _reader
  }

  if (loadDefaults) {
    loadFromSystemProperties(false)
  }
```



### 二、SparkContext初始化

查看初始化对应代码 (位于374行)

克隆和校验SparkConf的变量，接着判断spark.master和spark.app.name是否存在，如果是YARN cluster模式则必须设置spark.yarn.app.id，然后是driver的host，port信息，最后是jars和files，

```scala
try {
    _conf = config.clone()
    _conf.validateSettings()

    if (!_conf.contains("spark.master")) {
      throw new SparkException("A master URL must be set in your configuration")
    }
    if (!_conf.contains("spark.app.name")) {
      throw new SparkException("An application name must be set in your configuration")
    }

    // System property spark.yarn.app.id must be set if user code ran by AM on a YARN cluster
    if (master == "yarn" && deployMode == "cluster" && !_conf.contains("spark.yarn.app.id")) {
      throw new SparkException("Detected yarn cluster mode, but isn't running on a cluster. " +
        "Deployment to YARN is not supported directly by SparkContext. Please use spark-submit.")
    }

    if (_conf.getBoolean("spark.logConf", false)) {
      logInfo("Spark configuration:\n" + _conf.toDebugString)
    }

    // Set Spark driver host and port system properties. This explicitly sets the configuration
    // instead of relying on the default value of the config constant.
    _conf.set(DRIVER_HOST_ADDRESS, _conf.get(DRIVER_HOST_ADDRESS))
    _conf.setIfMissing("spark.driver.port", "0")

    _conf.set("spark.executor.id", SparkContext.DRIVER_IDENTIFIER)

    _jars = Utils.getUserJars(_conf)
    _files = _conf.getOption("spark.files").map(_.split(",")).map(_.filter(_.nonEmpty))
      .toSeq.flatten
```

_eventLogDir 是否记录运行时信息，由**spark.eventLog.enabled**和**spark.eventLog.dir**控制

_eventLogCodec 是否压缩该信息

```scala
    _eventLogDir =
      if (isEventLogEnabled) {
        val unresolvedDir = conf.get("spark.eventLog.dir", EventLoggingListener.DEFAULT_LOG_DIR)
          .stripSuffix("/")
        Some(Utils.resolveURI(unresolvedDir))
      } else {
        None
      }

    _eventLogCodec = {
      val compress = _conf.getBoolean("spark.eventLog.compress", false)
      if (compress && isEventLogEnabled) {
        Some(CompressionCodec.getCodecName(_conf)).map(CompressionCodec.getShortName)
      } else {
        None
      }
    }
```

如果为yarn-client模式，设置SPARK_YARN_MODE=true

```scala
    if (master == "yarn" && deployMode == "client") System.setProperty("SPARK_YARN_MODE", "true")
```

使用JobProgressListener跟踪运行时信息，用于UI展示，最后创建**SparkEnv**对象，创建SparkEnv的过程涉及到非常多spark-core中的核心类。

```scala
    _jobProgressListener = new JobProgressListener(_conf)
    listenerBus.addListener(jobProgressListener)

    // Create the Spark execution environment (cache, map output tracker, etc)
    _env = createSparkEnv(_conf, isLocal, listenerBus)
    SparkEnv.set(_env)

    // If running the REPL, register the repl's output dir with the file server.
    _conf.getOption("spark.repl.class.outputDir").foreach { path =>
      val replUri = _env.rpcEnv.fileServer.addDirectory("/classes", new File(path))
      _conf.set("spark.repl.class.uri", replUri)
    }
```

有关UI的信息展示

```scala
    _statusTracker = new SparkStatusTracker(this)

    _progressBar =
      if (_conf.getBoolean("spark.ui.showConsoleProgress", true) && !log.isInfoEnabled) {
        Some(new ConsoleProgressBar(this))
      } else {
        None
      }

    _ui =
      if (conf.getBoolean("spark.ui.enabled", true)) {
        Some(SparkUI.createLiveUI(this, _conf, listenerBus, _jobProgressListener,
          _env.securityManager, appName, startTime = startTime))
      } else {
        // For tests, do not enable the UI
        None
      }
    // Bind the UI before starting the task scheduler to communicate
    // the bound port to the cluster manager properly
    _ui.foreach(_.bind())
```

读取hadoop配置，将jar和file的路径添加到rpcEnv的fileServer，读取Executor相关变量，重要的参数为ExecutorMemory 

```scala
    _hadoopConfiguration = SparkHadoopUtil.get.newConfiguration(_conf)

    // Add each JAR given through the constructor
    if (jars != null) {
      jars.foreach(addJar)
    }

    if (files != null) {
      files.foreach(addFile)
    }

    _executorMemory = _conf.getOption("spark.executor.memory")
      .orElse(Option(System.getenv("SPARK_EXECUTOR_MEMORY")))
      .orElse(Option(System.getenv("SPARK_MEM"))
      .map(warnSparkMem))
      .map(Utils.memoryStringToMb)
      .getOrElse(1024)

    // Convert java options to env vars as a work around
    // since we can't set env vars directly in sbt.
    for { (envKey, propKey) <- Seq(("SPARK_TESTING", "spark.testing"))
      value <- Option(System.getenv(envKey)).orElse(Option(System.getProperty(propKey)))} {
      executorEnvs(envKey) = value
    }
    Option(System.getenv("SPARK_PREPEND_CLASSES")).foreach { v =>
      executorEnvs("SPARK_PREPEND_CLASSES") = v
    }
    // The Mesos scheduler backend relies on this environment variable to set executor memory.
    // TODO: Set this only in the Mesos scheduler.
    executorEnvs("SPARK_EXECUTOR_MEMORY") = executorMemory + "m"
    executorEnvs ++= _conf.getExecutorEnv
    executorEnvs("SPARK_USER") = sparkUser
```

_heartbeatReceiver是默认基于netty实现的心跳机制，创建schedulerBackend用于提交任务，创建taskScheduler和dagScheduler，获取applicationId，启动度量系统，获取eventLogger 

```scala   
    _heartbeatReceiver = env.rpcEnv.setupEndpoint(
      HeartbeatReceiver.ENDPOINT_NAME, new HeartbeatReceiver(this))

    // Create and start the scheduler
    val (sched, ts) = SparkContext.createTaskScheduler(this, master, deployMode)
    _schedulerBackend = sched
    _taskScheduler = ts
    _dagScheduler = new DAGScheduler(this)
    _heartbeatReceiver.ask[Boolean](TaskSchedulerIsSet)

    // start TaskScheduler after taskScheduler sets DAGScheduler reference in DAGScheduler's
    // constructor
    _taskScheduler.start()

    _applicationId = _taskScheduler.applicationId()
    _applicationAttemptId = taskScheduler.applicationAttemptId()
    _conf.set("spark.app.id", _applicationId)
    if (_conf.getBoolean("spark.ui.reverseProxy", false)) {
      System.setProperty("spark.ui.proxyBase", "/proxy/" + _applicationId)
    }
    _ui.foreach(_.setAppId(_applicationId))
    _env.blockManager.initialize(_applicationId)

    // The metrics system for Driver need to be set spark.app.id to app ID.
    // So it should start after we get app ID from the task scheduler and set spark.app.id.
    _env.metricsSystem.start()
    // Attach the driver metrics servlet handler to the web ui after the metrics system is started.
    _env.metricsSystem.getServletHandlers.foreach(handler => ui.foreach(_.attachHandler(handler)))

    _eventLogger =
      if (isEventLogEnabled) {
        val logger =
          new EventLoggingListener(_applicationId, _applicationAttemptId, _eventLogDir.get,
            _conf, _hadoopConfiguration)
        logger.start()
        listenerBus.addListener(logger)
        Some(logger)
      } else {
        None
      }

    // Optionally scale number of executors dynamically based on workload. Exposed for testing.
    val dynamicAllocationEnabled = Utils.isDynamicAllocationEnabled(_conf)
```

executorAllocationManager关于Executor动态资源分配，通过spark.dynamicAllocation.enabled设置，创建contextcleaner用于清理过期的RDD, shuffle和broadcast ，启动ListenerBus，并post环境信息和应用信息，最后添加确保context停止的hook，至此整个sparkcontext的初始化流程结束。
```scala    
    _executorAllocationManager =
      if (dynamicAllocationEnabled) {
        schedulerBackend match {
          case b: ExecutorAllocationClient =>
            Some(new ExecutorAllocationManager(
              schedulerBackend.asInstanceOf[ExecutorAllocationClient], listenerBus, _conf))
          case _ =>
            None
        }
      } else {
        None
      }
    _executorAllocationManager.foreach(_.start())

    _cleaner =
      if (_conf.getBoolean("spark.cleaner.referenceTracking", true)) {
        Some(new ContextCleaner(this))
      } else {
        None
      }
    _cleaner.foreach(_.start())

    setupAndStartListenerBus()
    postEnvironmentUpdate()
    postApplicationStart()

    // Post init
    _taskScheduler.postStartHook()
    _env.metricsSystem.registerSource(_dagScheduler.metricsSource)
    _env.metricsSystem.registerSource(new BlockManagerSource(_env.blockManager))
    _executorAllocationManager.foreach { e =>
      _env.metricsSystem.registerSource(e.executorAllocationManagerSource)
    }

    // Make sure the context is stopped if the user forgets about it. This avoids leaving
    // unfinished event logs around after the JVM exits cleanly. It doesn't help if the JVM
    // is killed, though.
    logDebug("Adding shutdown hook") // force eager creation of logger
    _shutdownHookRef = ShutdownHookManager.addShutdownHook(
      ShutdownHookManager.SPARK_CONTEXT_SHUTDOWN_PRIORITY) { () =>
      logInfo("Invoking stop() from shutdown hook")
      stop()
    }
  } catch {
    case NonFatal(e) =>
      logError("Error initializing SparkContext.", e)
      try {
        stop()
      } catch {
        case NonFatal(inner) =>
          logError("Error stopping SparkContext after init error.", inner)
      } finally {
        throw e
      }
  }
```

### 三、总结

通过对sparkcontext初始化过程的跟踪，主要涉及到的内容如下

1. SparkConf读取配置和校验，log和UI相关的度量系统。
2. 创建SparkEnv，涉及到众多重要对象，如rpcEnv, actorSystem, serializer, closureSerializer, cacheManager, mapOutputTracker, shuffleManager, broadcastManager, blockTransferService, blockManager, securityManager, sparkFilesDir, metricsSystem, memoryManager等。
3. 心跳机制，taskScheduler和dagScheduler的创建。