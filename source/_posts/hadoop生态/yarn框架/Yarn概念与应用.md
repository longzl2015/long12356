---
title: yarn概念与应用
date: 2016-04-02 22:46:48
tags: 
  - yarn
categories: [hadoop生态,yarn]
---

如前面所描述的, YARN 实质上是管理分布式app的系统。他由一个全局的**ResourceManager**和 每一个节点上的**NodeManager**组成。**ResourceManager**用于管理集群所有的可用资源，而每一个节点上的 **NodeManager**用于与ResourceManager沟通并负责管理单节点的可用资源。

![yarnflow1](/images/Yarn概念与应用/yarnflow1.png)

## 1、Resource Manager

在YARN里, ResourceManager 是一个主要的纯粹的scheduler。从本质上讲，它严格限制系统中可用资源的竞争。它优化了集群利用率（保持所有资源始终处于可用状态），以抵御各种限制，如容量保证，公平性和slas。为了允许不同的策略约束，资源管理器具有可插入的调度器，允许根据需要使用不同的算法，例如容量和公平调度。

## 2、ApplicationMaster

许多人会将yarn与现有的hadoop mapreduce系统（apache hadoop 1.x中的MR1）相提并论。然而，他们之间关键的区别：ApplicationMaster概念的加入。

ApplicationMaster 实际上是一个特定框架库的一个实例，负责与ResourceManager协商资源，并与NodeManager（s）一起执行和监视这些容器及其资源消耗。AM的功能就是向ResourceManager申请适当的资源容器，跟踪他们的状态和监测进度。

ApplicationMaster 使 YARN 具有以下几个特性：

- 可扩展：ApplicationMaster提供给传统的ResourceManager很多功能，使整个系统拥有了更好的可扩展性。在测试中，我们已经成功模拟了10000个由现代硬件组成的节点集群，没有出现重大问题。这是我们选择将ResourceManager设计成纯调度器的关键原因之一，它并不试图为资源提供容错。我们将其转移到了ApplicationMaster实例的主要职责上。此外，由于每个应用程序都有一个ApplicationMaster的实例，所以ApplicationMaster本身并不是集群中常见的瓶颈。
- 开放：将所有应用程序框架特定的代码移动到ApplicationMaster中，以使我们现在可以支持多种框架，比如MapReduce、mpi和图形处理。

下面有一些YARN设计的关键点：

- 把所有的复杂性（尽可能的）交给ApplicationMaster，同时提供足够的功能以允许applicaiton-framework的开发者有足够的灵活性和权利。
- 既然他实际上是用户端代码，所以不必信任ApplicationMasters，即任何ApplicationMaster都不是一个特权服务。
- YARN 系统 (ResourceManager 和 NodeManager) 能够保护他们自己免受错误的或者恶意的ApplicationMasters的影响。

记住这点是重要的，每个application有它自己的ApplicationMaster实例。然而，ApplicationMaster管理一组applications也是完全可行的（比如Pig或者Hive的ApplicationMaster就管理一系列的MapReduce作业）。此外，这个概念已经被延伸到管理长期运行的服务，这些长期运行的服务管理着他们自己的应用（比如通过一个虚拟的HBaseAppMaster启动HBase）。

## 3、Resource Model

YARN 给applications提供了一个非常通用的Resource Model。一个application（通过ApplicationMaster）可以请求的资源包括如下：

- Resource-name (hostname, rackname – 我们正在进一步将其用于支持更复杂的网络拓扑结构).
- Memory (in MB)
- CPU (cores, for now)
- 将来, 我们会添加更多的资源类型比如磁盘/网络I/O，GPU等。

## 4、ResourceRequest and Container

YARN的设计允许个别应用程序（通过应用程序管理器）以共享，安全和多租户的方式利用集群资源。此外，为了有效地调度和优化数据访问，它使用集群拓扑结构以尽可能减少应用程序的数据移动。

为了实现这些目标，ResourceManager的Scheduler获取了广泛的application的资源需求信息，这样使他能够给集群里所有的applications做出更好的调度决定。这就带给我们了 **ResourceRequest** 和 **Container**.

### 4.1 ResourceRequest 

一个application可以通过ApplicationMaster请求到足够的资源来满足application的资源需求。调度程序通过授予容器来响应资源请求，该容器满足初始资源请求中由应用程序管理器规定的要求。

看一下 ResourceRequest – 有如下形式：

> <resource-name, priority, resource-requirement, number-of-containers>

####4.1.1 ResourceRequest的每个组件

- resource-name:  hostname, rackname 或者 * 表示没有特别要求。在未来，我们希望能够支持更复杂的虚拟机拓扑结构，更复杂的网络等等。
- priority: 这个请求的优先级是应用内优先级（强调，这不是跨多个应用程序）。
- resource-requirement: 如内存，CPU等（编写时只支持内存和CPU）。。
- number-of-containers: 容器个数

### 4.2 Container

本质上，Container 是资源分配，这是ResourceManager 授予特定ResourceRequest的成功结果。Container为application授予在特定主机上使用特定数量的资源（内存，CPU等）的权限。

ApplicationMaster必须将Container提交给对应的NodeManager，以便使用资源启动其任务。当然，在安全模式下验证容器分配是为了确保 ApplicationMaster(s) 不能在集群中伪造分配。

### 4.2.1 容器运行期间的容器规格

如上所述，容器仅仅拥有在集群中的特定计算机上使用指定数量资源的权利，ApplicationMaster必须向NodeManager提供相当多的信息才能真正启动容器。

yarn允许应用程序启动任何进程，而不像hadoop-1.x（aka MR1）中现有的hadoop mapreduce，它不仅仅局限于java应用程序。

yarn容器的启动规范API是平台不可知的，包含：

- 命令行来启动容器内的进程。
- 环境变量。
- 机器启动前必需的本地资源，如罐子，共享对象，辅助数据文件等
- 与安全有关的令牌。

这允许ApplicationMaster使用NodeManager来启动容器，从unix / windows上的简单shell脚本到c / java / python进程到完整的虚拟机（例如kvms）。

## 5、YARN - 应用

掌握了上述概念的知识后，概略地说明applications在YARN上的工作原理是有用的。

applications执行包括以下步骤：

- 申请提交。
- 引导applications的ApplicationMaster实例。
- applications执行由ApplicationMaster实例管理。

让我们来看一下应用程序的执行顺序（步骤如图所示）：

1. 客户端程序提交applications，包括启动特定于applications的ApplicationMaster本身的必要规范。
2. Resource Manager承担协商指定容器的责任，在该容器中启动ApplicationMaster，然后启动ApplicationMaster。
3. 在启动时，ApplicationMaster向ResourceManager注册 - 注册允许客户端程序查询资源管理器的细节，这使得它可以直接与自己的ApplicationMaster进行通信。
4. 在正常操作期间，ApplicationMaster通过资源请求协议来协商合适的资源容器。
5. 在成功分配容器时，ApplicationMaster通过向NodeManager提供容器启动规范来启动容器。启动规范通常包含允许容器与应用程序管理器本身通信的必要信息。
6. 在容器内执行的应用程序代码然后通过应用程序特定的协议向其应用程序主管提供必要的信息（进度，状态等）。
7. 在应用程序执行期间，提交程序的客户端通过应用程序特定的协议直接与应用程序管理器通信以获取状态，进度更新等。
8. 一旦申请完成，并且所有必要的工作已经完成，申请管理员就会注销资源管理器并关闭，从而允许自己的容器被重新利用。

![img](/images/Yarn概念与应用/yarnflow.png)



## 参考

[APACHE HADOOP YARN – CONCEPTS AND APPLICATIONS](https://hortonworks.com/blog/apache-hadoop-yarn-concepts-and-applications/)