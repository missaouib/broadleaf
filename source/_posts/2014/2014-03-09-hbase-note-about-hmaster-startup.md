---
layout: post

title: HBase源码：HMaster启动过程

description: 记录HBase中HMaster启动过程

keywords: HBase源码：HMaster启动过程

category: hbase

tags: [hbase]

published: true

---

版本：HBase 0.94.15-cdh4.7.0

# 调试HMaster

> **说明：**
>
> 这部分参考和使用了<https://github.com/codefollower/HBase-Research>上的代码（注意：原仓库已经被作者删除了），包括该作者自己写的一些[测试类](https://github.com/codefollower/HBase-Research/tree/0.94/src/test/java/my/test)和[文档](https://github.com/codefollower/HBase-Research/blob/0.94/my-docs)。

首先，在IDE里启动HMaster和HRegionServer：

运行`/hbase/src/test/java/my/test/start/HMasterStarter.java`，当看到提示`Waiting for region servers count to settle`时，
再打开同目录中的HRegionServerStarter，统一运行该类。

此时会有两个Console，在HMasterStarter这个Console最后出现`Master has completed initialization`，这样的信息时就表示它启动成功了，而HRegionServerStarter这个Console最后出现`Done with post open deploy task`这样的信息时说明它启动成功了。

# main方法

运行HMasterStarter类启动HMaster：

~~~java
package my.test.start;

import java.io.File;

import my.test.TestBase;

import org.apache.hadoop.hbase.HConstants;
import org.apache.hadoop.hbase.master.HMaster;
import org.apache.hadoop.hbase.zookeeper.MiniZooKeeperCluster;

public class HMasterStarter {
    public static void deleteRecursive(File[] files) {
        if (files == null)
            return;
        for (File f : files) {
            if (f.isDirectory()) {
                deleteRecursive(f.listFiles());
            }
            f.delete();
        }
    }

    public static void main(String[] args) throws Exception {
        File f = TestBase.getTestDir();
        //删除临时测试目录
        deleteRecursive(f.listFiles());

        new ZookeeperThread().start();
        Thread.sleep(1000);
        HMaster.main(new String[] { "start" });
    }

    public static class ZookeeperThread extends Thread {
        public void run() {
            MiniZooKeeperCluster zooKeeperCluster = new MiniZooKeeperCluster();

            File zkDataPath = new File(TestBase.sharedConf.get(HConstants.ZOOKEEPER_DATA_DIR));
            int zkClientPort = TestBase.sharedConf.getInt(HConstants.ZOOKEEPER_CLIENT_PORT, 2181);
            zooKeeperCluster.setDefaultClientPort(zkClientPort);
            try {
                zooKeeperCluster.startup(zkDataPath);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
~~~

HMaster的入口是main方法，main方法需要传递一个参数，start或者stop。

main方法内首先打印hbase版本信息，然后在调用HMasterCommandLine的doMain方法。HMasterCommandLine继承自ServerCommandLine类并且ServerCommandLine类实现了Tool接口。

~~~java
public void doMain(String args[]) throws Exception {
    int ret = ToolRunner.run(
      HBaseConfiguration.create(), this, args);
    if (ret != 0) {
      System.exit(ret);
    }
  }
~~~

doMain方法内会调用ToolRunner的run方法，查看ToolRunner类可以知道，实际上最后会调用HMasterCommandLine的run方法。

接下来会解析参数，根据参数值判断是执行startMaster方法还是stopMaster方法。

startMaster方法中分两种情况：本地模式和分布式模式。如果是分布式模式，通过反射调用HMaster的**构造方法**，并调用其start和join方法。

HMaster继承自HasThread类，而HasThread类实现了Runnable接口，故HMaster也是一个线程。

# HMaster类图

HMaster类继承关系如下图：

![](http://7xnrdo.com1.z0.glb.clouddn.com/2014/hbase-hmaster-class.jpg)

# HMaster的构造方法

1、构造方法总体过程

创建Configuration并设置和获取一些参数。包括：

- 在master上禁止block cache
- 设置服务端重试次数
- 获取主机名称和master绑定的ip和端口号，端口号默认为60000
- 设置regionserver的coprocessorhandler线程数为0
- **创建rpcServer**（见下文分析）
- 初始化serverName，其值为：`192.168.1.129,60000,1404117936154`
- zk授权登录和hbase授权
- 设置当前线程名称：`master + "-" + this.serverName.toString()`
- 判断是否开启复制：`Replication.decorateMasterConfiguration(this.conf);`
- 设置`mapred.task.id`，如果其为空，则其值为：`"hb_m_" + this.serverName.toString()`
- **创建ZooKeeperWatcher监听器**（见下文分析），并在zookeeper上创建一些节点
- 启动rpcServer中的线程
- 创建一个MasterMetrics
- 判断是否进行健康检测：HealthCheckChore
- 另外还初始化两个参数：shouldSplitMetaSeparately、waitingOnLogSplitting

涉及到的参数有：

~~~
hfile.block.cache.size
hbase.master.dns.interface
hbase.master.dns.nameserver
hbase.master.port
hbase.master.ipc.address
hbase.master.handler.count
hbase.regionserver.handler.count
hbase.master.buffer.for.rs.fatals
hbase.zookeeper.client.keytab.file
hbase.zookeeper.client.kerberos.principal
hbase.master.keytab.file
hbase.master.kerberos.principal
hbase.master.logcleaner.plugins
mapred.task.id
hbase.node.health.script.frequency
hbase.regionserver.separate.hlog.for.meta
hbase.master.wait.for.log.splitting
~~~

2、创建rpcServer并启动其中的线程：

这部分涉及到RPC的使用，包括的知识点有`动态代理`、`Java NIO`等。
	
通过反射创建RpcEngine的实现类，实现类可以在配置文件中配置（`hbase.rpc.engine`），默认实现为WritableRpcEngine。
调用getServer方法，其实也就是new一个HBaseServer类。

构造方法中：

- 启动一个Listener线程，功能是监听client的请求，将请求放入nio请求队列，逻辑如下：
 - -->创建n个selector，和一个n个线程的readpool，n由`ipc.server.read.threadpool.size`决定，默认为10
 - -->读取每个请求的头和内容，将内容放入priorityQueue中
- 启动一个Responder线程，功能是将响应队列里的数据写给各个client的connection通道，逻辑如下：
 - -->创建nio selector
 - -->默认超时时间为15 mins
 - -->依次将responseQueue中的内容写回各通道，并关闭连接，buffer=8k
 - -->如果该请求的返回没有写完，则放回队列头，推迟再发送
 - -->对于超时未完成的响应，丢弃并关闭相应连接
- 启动N（n默认为10）个Handler线程，功能是处理请求队列，并将结果写到响应队列
 - -->读取priorityQueue中的call，调用对应的call方法获得value，写回out并调用doRespond方法，处理该请求，并唤醒writable　selector
 - -->启动M(m默认为0)个Handler线程以处理priority

3、创建ZooKeeperWatcher

构造函数中生成如下持久节点：

~~~
/hbase
/hbase/root-region-server
/hbase/rs
/table/draining
/hbase/master
/hbase/backup-masters
/hbase/shutdown
/hbase/unassigned
/hbase/table94
/hbase/table
/hbase/hbaseid
/hbase/splitlog
~~~

# run方法

接下来看HMaster的run方法做了哪些事情。

1、总体过程

- 创建MonitoredTask，并把HMaster的状态设置为Master startup
- 启动info server，即Jetty服务器，端口默认为60010，其对外提供两个接口：/master-status和/dump
- **调用becomeActiveMaster方法**（见下文分析），阻塞等待直至当前master成为active master
- 当成为了master之后并且当前master进程正在运行，则调用finishInitialization方法（见下文分析），并且调用loop方法循环等待，一直到stop发生
- 当HMaster停止运行时候，会做以下事情：
	- 清理startupStatus
	- 停止balancerChore和catalogJanitorChore
	- 让RegionServers shutdown 
	- 停止服务线程：rpcServer、logCleaner、hfileCleaner、infoServer、executorService、healthCheckChore
	- 停止以下线程：activeMasterManager、catalogTracker、serverManager、assignmentManager、fileSystemManager、snapshotManager、zooKeeper  	 

2、becomeActiveMaster方法：

- 创建ActiveMasterManager
- ZooKeeperWatcher注册activeMasterManager监听器
- 调用stallIfBackupMaster：
	-->先检查配置项 "hbase.master.backup"，自己是否backup机器，如果是则直接block直至检查到系统中的active master挂掉（`zookeeper.session.timeout`，默认每3分钟检查一次） 
- 创建clusterStatusTracker并启动
- 调用activeMasterManager的blockUntilBecomingActiveMaster方法。
	- 创建短暂的"/hbase/master"，此节点值为version+ServerName，如果创建成功，则删除备份节点；否则，创建备份节点
	- 获得"/hbase/master"节点上的数据，如果不为null，则获得ServerName，并判断是否是在当前节点上创建了"/hbase/master"，如果是则删除该节点，这是因为该节点已经是备份节点了。

3、finishInitialization方法：

- 创建MasterFileSystem对象，封装了master常用的一些文件系统操作，包括splitlog file、删除region目录、删除table目录、删除cf目录、检查文件系统状态等.
- 创建FSTableDescriptors对象
- 设置集群id
- 如果不是备份master：
	- 创建ExecutorService，维护一个ExecutorMap,一种Event对应一个Executor(线程池).可以提交EventHandler来执行异步事件；
 	- 创建serverManager，管理regionserver信息,维护着onlineregion server 和deadregion server列表，处理regionserver的startups、shutdowns、 deaths，同时也维护着每个regionserver rpc stub.
- 调用initializeZKBasedSystemTrackers，初始化zk文件系统
	- 创建CatalogTracker, 它包含RootRegionTracker和MetaNodeTracker，对应"/hbase/root-region-server"和/"hbase/unassigned/1028785192"这两个结点(1028785192是.META.的分区名)。如果之前从未启动过hbase，那么在start CatalogTracker时这两个结点不存在。"/hbase/root-region-server"是一个持久结点，在RootLocationEditor中建立
	- 创建 LoadBalancer，负责region在regionserver之间的移动，关于balancer的策略，可以通过hbase.regions.slop来设置load区间
	- 创建 AssignmentManager，负责管理和分配region，同时它也会接受zk上关于region的event，根据event来完成region的上下线、关闭打开等工作。
	- 创建 RegionServerTracker: 监控"/hbase/rs"结点，通过ZK的Event来跟踪onlineregion servers， 如果有rs下线，删除ServerManager中对应的onlineregions.
	- 创建 DrainingServerTracker: 监控"/hbase/draining"结点
	- 创建 ClusterStatusTracker，监控"/hbase/shutdown"结点维护集群状态
	- 创建SnapshotManager
- 如果不是备份master，初始化MasterCoprocessorHost并执行startServiceThreads()。说明：`info server的启动移到构造函数了去了，这样可以早点通过Jetty服务器查看HMaster启动状态。`
	- 创建一些executorService
	- 创建logCleaner并启动
	- 创建hfileCleaner并启动
	- 启动healthCheckChore
	- 打开rpcServer
- 等待RegionServer注册。满足以下这些条件后返回当前所有region server上的region数后继续： 
    - a 至少等待4.5s，"hbase.master.wait.on.regionservers.timeout"
    - b 成功启动regionserver节点数>=1，"hbase.master.wait.on.regionservers.mintostart"
    - c 1.5s内没有regionsever死掉或重新启动，`hbase.master.wait.on.regionservers.interval`)
- serverManager注册新的在线region server
- 如果不是备份master，启动assignmentManager
- 获取下线的Region server，然后拆分HLog
	- -->依次检查每一个hlog目录，查看它所属的region server是否online，如果是则不需要做任何动作，region server自己会恢复数据，如果不是，则需要将它分配给其它的region server 
	- -->split是加锁操作: 
	- --> 创建一个新的hlogsplitter,遍历每一个server目录下的所有hlog文件，依次做如下操作。（如果遇到文件损坏等无法跳过的错误，配 置 `hbase.hlog.split.skip.errors=true` 以忽略之） 
	- -->启动`hbase.regionserver.hlog.splitlog.writer.threads`（默认为3）个线程，共使用128MB内存，启动这些写线程 
	- -->先通过lease机制检查文件是否能够append，如果不能则死循环等待 
	- -->把hlog中的内容全部加载到内存中（内存同时被几个写线程消费)）
	   - -->把有损坏并且跳过的文件移到`/hbase/.corrupt/`目录中 
	   - --> 把其余己经处理过的文件移到`/hbase/.oldlogs`中，然后删除原有的server目录 
	   - --> 等待写线程结束，返回新写的所有路径 
	- -->解锁
	- 写线程逻辑： 
	   - -->从内存中读出每一行数据的key和value，然后查询相应的region路径。如果该region路径不存在，说明该region很可能己经被split了，则不处理这部分数据,因为此时忽略它们是安全的。 
	   - -->如果上一步能查到相应的路径，则到对应路径下创建"recovered.edits"文件夹(如果该文件夹存在则删除后覆盖之)，然后将数据写入该文件夹  
- 调用assignRoot方法，检查是否分配了-ROOT-表，如果没有，则通过assignmentManager.assignRoot()来分配root表，并激活该表
- 运行this.serverManager.enableSSHForRoot()方法
- 拆分.META. server上的HLog
- 分配.META.表
- enableServerShutdownHandler
- 处理dead的server
- assignmentManager.joinCluster();
- 设置balancer
- fixupDaughters(status)
- 如果不是备份master
   - 启动balancerChore线程，运行LoadBalancer
   - 启动startCatalogJanitorChore，周期性扫描`.META.`表上未使用的region并回收
   - registerMBean
- serverManager.clearDeadServersWithSameHostNameAndPortOfOnlineServer，清理dead的server
- 如果不是备份master，cpHost.postStartMaster
       
# MasterFileSystem构造方法

在`HMaster.finishInitialization`方法中触发了MasterFileSystem的构造方法，该类在HMaster类中会被以下类使用：

- LogCleaner
- HFileCleaner

另外该类可以完成拆分log的工作：

~~~java
  /**
   * Override to change master's splitLogAfterStartup. Used testing
   * @param mfs
   */
  protected void splitLogAfterStartup(final MasterFileSystem mfs){
    mfs.splitLogAfterStartup();
  }
~~~

这里主要是关心创建了哪些目录，其他用途暂不分析。

1、接下来，看其构造方法运行过程：

- 获取rootdir：由参数`hbase.rootdir`配置
- 获取tempdir：`${hbase.rootdir}/.tmp`
- 获取文件系统的uri，并设置到`fs.default.name`和`fs.defaultFS`
- 判断是否进行分布式文件拆分，参数：`hbase.master.distributed.log.splitting`，如果需要，则创建SplitLogManager
- 创建oldLogDir，调用createInitialFileSystemLayout方法
  - checkRootDir
    - 等待fs退出安全模式(默认10秒钟轮循一次，可通过参数`hbase.server.thread.wakefrequency`调整
    - 如果hbase.rootdir目录不存在则创建它，然后在此目录中创建名为"hbase.version"的文件，内容是文件系统版本号，当前为7；如果hbase.rootdir目录已存在，则读出"hbase.version"文件的内容与当前的版本号相比，如果不相等，则打印错误信息(提示版本不对)，抛出异常FileSystemVersionException
    - 检查`${hbase.rootdir}`目录下是否有名为"hbase.id"的文件，如果没有则创建它，内容是随机生成的UUID(总长度36位，由5部份组成，用"-"分隔)，如：6c43f934-37a2-4cae-9d49-3f5abfdc113d
    - 读出"hbase.id"的文件的内容存到clusterId字段
    - 判断hbase.rootdir目录中是否有"-ROOT-/70236052"目录，没有的话说明是第一次启动hbase，进入**bootstrap**方法
    - createRootTableInfo 建立"-ROOT-"表的描述文件，判断`hbase.rootdir/-ROOT-`目录中是否存在tableinfo开头的文件，另外还创建了.tmp目录
  - checkTempDir
  - 如果oldLogDir（`${hbase.rootdir}/.oldlogs`）不存在，则创建
 

2、bootstrap方法运行过程：

 - 调用HRegion.createHRegion建立"-ROOT-"分区和".META."分区
 - 把".META."分区信息加到"-ROOT-"表，并关闭分区和hlog

# 总结

经过上面分析之后，来看看zookeeper创建的一些目录分布式由哪个类来监控的：

- `/hbase`
- `/hbase/root-region-server`：RootRegionTracker，监控root所在的regionserver
- `/hbase/rs`：RegionServerTracker，监控regionserver的上线和下线
- `/table/draining`：DrainingServerTracker，监听regionserver列表的变化
- `/hbase/master`：在HMaster中建立，并且是一个短暂结点，结点的值是HMaster的ServerName：`hostname,port,当前毫秒`
- `/hbase/backup-masters`
- `/hbase/shutdown`：ClusterStatusTracker，当HMaster启动之后，会将当前时间（`Bytes.toBytes(new java.util.Date().toString())`）存到该节点
- `/hbase/unassigned`：MetaNodeTracker
- `/hbase/table94`
- `/hbase/table`
- `/hbase/hbaseid`：在`HMaster.finishInitialization`方法中调用ClusterId.setClusterId建立，结点值是UUID
- `/hbase/splitlog`


在HMaster启动之后，`${hbase.rootdir}`目录如下:

~~~
.
├── -ROOT-                            //"-ROOT-"表名
│   ├── ..tableinfo.0000000001.crc    //crc校验文件
│   ├── .tableinfo.0000000001
│   ├── .tmp
│   └── 70236052                      //"-ROOT-"分区名
│       ├── ..regioninfo.crc
│       ├── .oldlogs                  //存放hlog文件
│       │   ├── .hlog.1402551641526.crc
│       │   └── hlog.1402551641526
│       ├── .regioninfo               //"-ROOT-"分区描述表件
│       ├── .tmp
│       └── info                      //列族名
│           ├── .5037e69a0c244bd78945aaa333d0230a.crc
│           └── 5037e69a0c244bd78945aaa333d0230a  //存放".META."分区信息的StoreFile
├── .META.
│   └── 1028785192
│       ├── ..regioninfo.crc
│       ├── .oldlogs
│       │   ├── .hlog.1402551641701.crc
│       │   └── hlog.1402551641701
│       ├── .regioninfo
│       └── info
├── .hbase.id.crc
├── .hbase.version.crc
├── .oldlogs
├── .tmp
├── hbase.id                         //集群uuid
└── hbase.version                    //hbase版本
~~~

简单总结一下HMaster启动过程做了哪些事情：

- 创建rpcServer，及HBaseServer
- 创建ZooKeeperWatcher监听器
- 阻塞等待成为activeMaster
- 创建master的一些文件目录
- 初始化一些基于zk的跟踪器
- 创建LoadBalancer
- 创建SnapshotManager
- 如果不是备份master
	- 创建logCleaner并启动
	- 创建hfileCleaner并启动
	- 创建jetty的infoServer并启动
	- 启动健康检查
	- 打开rpcServer
- 等待RegionServer注册
- 从hlog中恢复数据
- 分配root和meta表
- 分配region
- 运行负载均衡线程
- 周期性扫描.META.表上未使用的region并回收
