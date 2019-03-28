---
layout: post

title: HBase源码：HRegionServer启动过程

description: 记录HBase中HRegionServer启动过程

keywords: HBase源码：HRegionServer启动过程

category: hbase

tags: [hbase]

published: true

---

版本：HBase 0.94.15-cdh4.7.0

关于HMaster启动过程，请参考[HBase源码：HMaster启动过程](/2014/03/09/hbase-note-about-hmaster-startup.html)。先启动了HMaster之后，再启动HRegionServer。

运行HRegionServerStarter类启动HRegionServer：

~~~java
package my.test.start;

import org.apache.hadoop.hbase.regionserver.HRegionServer;

public class HRegionServerStarter {

    public static void main(String[] args) throws Exception {
        //new HMasterStarter.ZookeeperThread().start();

        HRegionServer.main(new String[] { "start" });
    }

}
~~~

同样参考[HBase源码：HMaster启动过程](/2014/03/09/hbase-note-about-hmaster-startup.html)，运行HRegionServer.main方法，会通过反射创建一个HRegionServer实例，然后调用其run方法。

HRegionServer类继承关系如下：

![](http://7xnrdo.com1.z0.glb.clouddn.com/2014/hbase-hregionserver-class.jpg)

# 构造方法

主要包括：

- 设置服务端HConnection重试次数
- 检查压缩编码，通过hbase.regionserver.codecs可以配置编码类，一一检测，判断是否支持其压缩算法。
- 获取useHBaseChecksum值，是否开启hbase checksum校验
- 获取`hbase.regionserver.separate.hlog.for.meta`参数值
- 获取客户端重复次数
- 获取threadWakeFrequency值
- 获取`hbase.regionserver.msginterval`值
- 创建Sleeper对象，用于周期性休眠线程
- 获取最大扫描结果集大小，`hbase.client.scanner.max.result.size`，默认无穷大
- 获取`hbase.regionserver.numregionstoreport`值
- 获取rpctimeout值，`hbase.rpc.timeout`，默认60000
- 获取主机名和绑定的ip和端口，端口默认为60020
- 创建rpcServer
- zk授权登录和hbase授权
- 创建RegionServerAccounting
- 创建CacheConfig

# run方法

- preRegistrationInitialization
   - initializeZooKeeper，此方法不会创建任何节点
	  	- 创建ZooKeeperWatcher
	  	- 创建MasterAddressTracker 并等到"/hbase/master"节点有数据为止
	  	- 创建ClusterStatusTracker 并等到"/hbase/shutdown"节点有数据为止
	  	- 创建CatalogTracker 不做任何等待
	  	- 创建RegionServerSnapshotManager
  - 设置集群id 
  - 初始化线程：initializeThreads
	  	- 创建 cacheFlusher
		- 创建 compactSplitThread
		- 创建 compactionChecker
  		- 创建 periodicFlusher
    	- 创建 healthCheckChore 	
		- 创建 Leases
  		- 判断是否启动 HRegionThriftServer	
   - 参数`hbase.regionserver.nbreservationblocks`默认为4，默认会预留20M(每个5M,20M = 4*5M)的内存防止OOM
   - 初始化rpcEngine = HBaseRPC.getProtocolEngine(conf)
- reportForDuty，轮询，向汇报master自己已经启动
	- getMaster()，取出"/hbase/master"节点中的数据，构造一个master的ServerName，然后基于此生成一个HMasterRegionInterface接口的代理，此代理用于调用master的方法
	- regionServerStartup
- 当轮询结果不为空时，调用handleReportForDutyResponse
  	- regionServerStartup会返回来一个MapWritable，这个MapWritable有三个值，这三个key的值会覆盖rs原有的conf:
		- "hbase.regionserver.hostname.seen.by.master" = master为rs重新定义的hostname(通常跟rs的InetSocketAddress.getHostName一样)rs会用它重新得到serverNameFromMasterPOV
		- "fs.default.name" = "file:///"
		- "hbase.rootdir"	= "file:///E:/hbase/tmp"
  	- 查看conf中是否有"mapred.task.id"，没有就自动设一个(格式: "hb_rs_"+serverNameFromMasterPOV)，例如: hb_rs_localhost,60050,1323525314060
  	- createMyEphemeralNode：在zk中建立 短暂节点"/hbase/rs/localhost,60050,1323525314060"，也就是把当前rs的serverNameFromMasterPOV(为null的话用rs的InetSocketAddress、port、startcode构建新的ServerName)放到/hbase/rs节点下，"/hbase/rs/localhost,60050,1323525314060"节点没有数据
  	- 设置fs.defaultFS值为hbase.rootdir的值
  	- 生成一个只读的FSTableDescriptors
  	- 调用setupWALAndReplication
  	- 初始化 hlog、metrics、dynamicMetrics、rsHost
  	- 调用startServiceThreads启动服务线程
  	 	- 启动一些ExecutorService
  	 	- 启动hlogRoller
  	 	- 启动cacheFlusher
  	 	- 启动compactionChecker
  	 	- 启动healthCheckChore
     	- 启动periodicFlusher 
  	 	- leases.start()
  	 	- 启动jetty的infoServer，默认端口为60030
  	 	- 启动复制相关打的一些handler：replicationSourceHandler、replicationSourceHandler、replicationSinkHandler
  	 	- rpcServer启动
  	 	- 创建并启动SplitLogWorker
- registerMBean
- snapshotManager启动快照服务
- 在master上注册之后，进入运行模式，周期性(msgInterval默认3妙)调用doMetrics，tryRegionServerReport
   - isHealthy健康检查，只要Leases、MemStoreFlusher、LogRoller、periodicFlusher、CompactionChecker有一个线程退出，rs就停止
   - doMetrics
   - tryRegionServerReport向master汇报rs的负载HServerLoad
- shutdown之后的一些操作
	- unregisterMBean
 	- 停掉thriftServer、leases、rpcServer、splitLogWorker、infoServer、cacheConfig
  	- 中断一些线程：cacheFlusher、compactSplitThread、hlogRoller、metaHLogRoller、compactionChecker、healthCheckChore
   - 停掉napshotManager 
   - 停掉 catalogTracker、compactSplitThread
   - 等待所有region关闭
   - 关闭wal
   - 删除zk上的一些临时节点，zooKeeper关闭

总结一下，HRegionServer主要干以下事情：

- 在zk上注册自己，表明自己上线了
- 跟master汇报
- 设置wal和复制
- 注册协作器RegionServerCoprocessorHost
- 启动hlogRoller
- 定期刷新memstore
- 定期检测是否需要压缩合并
- 启动租约
- 启动jetty的infoserver
- 创建SplitLogWorker，用于拆分HLog
- 快照管理

# 总结

HRegionServer类中创建了一些对象：

- HBaseServer：处理客户端请求
- Leases：租约
- InfoServer：Jetty服务器
- RegionServerMetrics：
- RegionServerDynamicMetrics：
- CompactSplitThread：合并文件线程
- MemStoreFlusher：刷新memstore线程
- 两个Chore：compactionChecker、periodicFlusher
- 两个LogRoller：hlogRoller、metaHLogRoller
- MasterAddressTracker：跟踪master地址
- CatalogTracker：跟踪-ROOT-和.META.表
- ClusterStatusTracker：跟踪集群状态
- SplitLogWorker：拆分log
- Sleeper：
- ExecutorService：
- ReplicationSourceService和ReplicationSinkService：复制服务
- RegionServerAccounting：
- CacheConfig：缓存配置和block
- RegionServerCoprocessorHost：RegionServer协作器
- HealthCheckChore：健康检查
