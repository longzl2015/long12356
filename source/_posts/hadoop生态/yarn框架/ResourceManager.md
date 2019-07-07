---
title: ResourceManager
date: 2016-04-02 22:46:48
tags: 
  - yarn
categories: [hadoop生态,yarn]
---

##简介 

在YARN中，ResourceManager负责集群中所有资源的统一管理和分配，它接收来自各个节点（NodeManager）的资源汇报信息，并把这些信息按照一定的策略分配给各个应用程序（ApplicationMasters）。

1. NodeManager:  接收来自ResourceManager的信息，并管理单个节点上的可用资源
2. ApplicationMasters: 负责向ResourceManager申请相关资源，并与NodeManagers一起处理containers的启动

![resource_manager](/images/ResourceManager/resource_manager.gif)



## 1 客户端和RM的接口组件

   - **ClientService**: 客户端和Resource Manager的接口。这个组件控制所有从客户端到RM的RPC接口，包括application提交，中断，获取查询信息，集群统计等。
   - **AdminService**: 为了确保管理请求不受普通用户的请求影响，给操作者的命令更高的优先权，所有的管理操作，比如刷新节点列表，队列配置等，都通过这个独立的接口提供服务。

## 2 RM连接节点的组件

   - **ResourceTrackerService**: 这是响应所有节点RPC请求的组件。他负责注册新节点，拒绝任何无效/退役的节点请求，收集节点心跳并发送给YarnScheduler。他和下面说的NMLivelinessMonitor和NodesListManager结合紧密。
   - **NMLivelinessMonitor**: 跟踪活跃的节点，特别关注关闭和死掉得节点，这个组件保持跟踪每个节点的最新心跳时间。任何在设定间隔时间内没有新掉的节点被认为是死掉了，默认是10分钟，被RM认为是失效。所有当时运行在失效节点上的container被标记为死亡，不会有新的container被安排在这个节点。
   - **NodesListManager**: 收集有效和失效节点。通过读取配置文件`yarn.resourcemanager.nodes.include-path` 和 `yarn.resourcemanager.nodes.exclude-path，来初始化节点列表。同时持续跟踪节点失效情况。`

## 3 和每个AMs交互的组件

   - **ApplicationMasterService**: 这个组件响应所有AMs的RPCs请求。他负责处理注册新的AMs，中断/注销任何完成的AMs，从所有正在运行的AMs获取container分配和处理请求，并发送到YarnScheduler。他和下面说的AMLivelinessMonitor紧密结合。
   - **AMLivelinessMonitor**: 帮助管理活跃AMs和死亡/无响应AMs列表，这个组件持续跟踪每个AM和他的最新心跳时间。任何在配置的间隔时间内无心跳的AM被认为死亡，并从RM里失效，默认是10分钟。所有失效AM的containers也会被标记死亡。RM会安排同一个AM在一个新的container上，最大重试次数是默认是4。

## 4 ResourceManager的核心 – 调度器相关组件

   - **ApplicationsManager**: 负责维护一个已提交applications的集合。保存完成applications缓存，用来给用户的web UI或者命令行请求提供完成applications的信息。
   - **ApplicationACLsManager**: RM需要面对用户通过客户端或者管理者的API请求，并只允许授权的用户。这个组件维护着每个application的ACLs列表，强制接收杀应用和查看应用状态的请求。
   - **ApplicationMasterLauncher**: 维护一个线程池去启动最新提交applications的AMs，以及那些之前由于原因需要退出的applications的AMs。也负责当一个application正常完成或者强制中断后清理AM。
   - **YarnScheduler**: 这个调度者负责根据性能，队列等因素分配资源给各种运行的applications。他基于applications资源请求来执行调度，比如内存，CPU，磁盘，网络等。当前只支持内存，CPU支持很快会完成。
   - **ContainerAllocationExpirer**: 这个组件确保所有已经分配的containers正在被AMs使用，和之后要被启动的container对应的NMs。AMs上运行的是不被信赖的用户代码，分配的资源有可能不被使用，就造成了集群利用率的降低。为了解决这个问题，ContainerAllocationExpirer维护着一个已分配但是没有在相应NM上使用的containers列表。对于任意container，如果对应的NM在配置的时间间隔(默认10分钟)内没有报告给RM这个container已经启动，这个container就被RM认为是死亡了或者失效了。

## 5 TokenSecretManagers (for security)

   ResourceManager 有几个 SecretManagers负责管理 tokens, secret-keys，用于认证/授权各种RPC接口的请求。一些YARN上的覆盖tokens，secret-keys和secret-managers的细节概要如下：

   - **ApplicationTokenSecretManager**: 为了避免从RM发送过来的任意进程的请求，RM使用每个应用的tokens，ApplicationTokens。这个组件保存token在本地内存里直到applications完成，使用他去认证从一个有效AM进程来的任何请求。
   - **ContainerTokenSecretManager**: ContainerTokens的SecretManager是被RM标记的特殊tokens用于给AM一个在指定节点上的container。ContainerTokens被AMs用于创建一个和相应的分配container的NM的连接。这个组件是RM特定的，跟踪相关的主机和secret-keys，并定时更新keys。
   - **RMDelegationTokenSecretManager**: 一个ResourceManager有一个特定的 delegation-token secret-manager. 他负责生成委托token给客户端，客户端可以传给未认证的希望和RM交互的进程。

## 6 DelegationTokenRenewer
在安全模式，RM是Kerberos认证的，提供更新文件系统的tokens服务给applications代表。这个组件更新已经提交的applications的tokens，只要这个applications在运行中，直到这个tokens不再被更新。

## 结束

在YARN里, ResourceManage主要被限制于调度用途，即只可以做系统中可用资源的竞争applications间的仲裁，并不关心每个application的状态管理。由于这种如之前所说的模块化的清晰的责任划分，使用前面说的强大的调度器API，RM能够满足最重要的设计要求 – 可扩展性，支持多种编程模型。

要允许不同的策略实现，RM的调度器是可插拔的，允许不同的策略算法。在未来很长时间，我们会深入挖掘各种特性的性能调度器，确保基于性能保证和队列安排containers。

## 参考网址

[介绍resourcemanager](https://hortonworks.com/blog/apache-hadoop-yarn-resourcemanager/)