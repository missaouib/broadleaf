---
layout: post

title:  HBase中的一些注意事项
date: 2014-06-26T08:00:00+08:00

description: 列举HBase中的一些注意事项

keywords:  

categories: [ hbase ]

tags: [hbase]

published: true

---

# 1. 安装集群前

- 配置SSH无密码登陆
- DNS。HBase使用本地 hostname 才获得IP地址，正反向的DNS都是可以的。你还可以设置 `hbase.regionserver.dns.interface` 来指定主接口，设置 `hbase.regionserver.dns.nameserver` 来指定nameserver，而不使用系统带的
- 安装NTP服务，并配置和检查crontab是否生效
- 操作系统调优，包括最大文件句柄，nproc hard 和 soft limits等等
- `conf/hdfs-site.xml`里面的 `dfs.datanode.max.xcievers` 参数，至少要有4096

# 2. HDFS客户端配置

如果你希望Hadoop集群上做HDFS 客户端配置 ，例如你的HDFS客户端的配置和服务端的不一样。按照如下的方法配置，HBase就能看到你的配置信息:

- 在hbase-env.sh里将 `HBASE_CLASSPATH` 环境变量加上 `HADOOP_CONF_DIR` 。
- 在`${HBASE_HOME}/conf` 下面加一个 hdfs-site.xml (或者 hadoop-site.xml) ，最好是软连接
- 如果你的HDFS客户端的配置不多的话，你可以把这些加到 hbase-site.xml上面.

例如HDFS的配置 `dfs.replication` 你希望复制5份，而不是默认的3份。如果你不照上面的做的话，Hbase只会复制3份。

# 3. 一些配置参数

以下参数来自apache的hbase版本，如果你使用的其他厂商的hbase，有可能默认值不一样。

- `zookeeper.session.timeout`：这个默认值是3分钟。这意味着一旦一个server宕掉了，Master至少需要3分钟才能察觉到宕机，开始恢复。你可能希望将这个超时调短，这样Master就能更快的察觉到了。在你调这个值之前，你需要确认你的JVM的GC参数，否则一个长时间的GC操作就可能导致超时。
- `hbase.regionserver.handler.count`：这个设置决定了处理用户请求的线程数量。默认是10，这个值设的比较小，主要是为了预防用户用一个比较大的写缓冲，然后还有很多客户端并发，这样region servers会垮掉。有经验的做法是，当请求内容很大(上MB，如大puts, 使用缓存的scans)的时候，把这个值放低。请求内容较小的时候(gets, 小puts, ICVs, deletes)，把这个值放大。把这个值放大的危险之处在于，把所有的Put操作缓冲意味着对内存有很大的压力，甚至会导致OutOfMemory.一个运行在内存不足的机器的RegionServer会频繁的触发GC操作，渐渐就能感受到停顿。一段时间后，集群也会受到影响，因为所有的指向这个region的请求都会变慢。这样就会拖累集群，加剧了这个问题。
- `hbase.client.keyvalue.maxsize`：一个KeyValue实例的最大size。如果设置为0或者更小，就会禁用这个检查。默认10MB。
- `hbase.regionserver.lease.period`：户端租用HRegion server 期限，即超时阀值。单位是毫秒。默认情况下，客户端必须在这个时间内发一条信息，否则视为死掉。默认值为60000。
- `hbase.regionserver.msginterval`：RegionServer 发消息给 Master 时间间隔，单位是毫秒，默认: 3000
- `hbase.regionserver.optionallogflushinterval`：将Hlog同步到HDFS的间隔。如果Hlog没有积累到一定的数量，到了时间，也会触发同步。默认是1秒，单位毫秒。
- `hbase.regionserver.logroll.period`：提交commit log的间隔，不管有没有写足够的值。默认: 3600000
- `hbase.regionserver.thread.splitcompactcheckfrequency`：region server 多久执行一次split/compaction 检查。默认: 20000
- `hbase.balancer.period`：Master执行region balancer的间隔。默认: 300000
- `hbase.hregion.memstore.block.multiplier`：如果memstore有`hbase.hregion.memstore.block.multiplier`倍数的`hbase.hregion.flush.size`的大小，就会阻塞update操作。这是为了预防在update高峰期会导致的失控。如果不设上界，flush的时候会花很长的时间来合并或者分割，最坏的情况就是引发out of memory异常。默认: 2
- `hbase.hstore.compactionThreshold`：当一个HStore含有多于这个值的HStoreFiles(每一个memstore flush产生一个HStoreFile)的时候，会执行一个合并操作，把这HStoreFiles写成一个。这个值越大，需要合并的时间就越长。默认: 3
- `hbase.hstore.blockingStoreFiles`：当一个HStore含有多于这个值的HStoreFiles(每一个memstore flush产生一个HStoreFile)的时候，会执行一个合并操作，update会阻塞直到合并完成，直到超过了`hbase.hstore.blockingWaitTime`的值。默认: 7

# 4. Shell 技巧

## irbrc

可以在你自己的Home目录下创建一个.irbrc文件，在这个文件里加入自定义的命令。有一个有用的命令就是记录命令历史，这样你就可以把你的命令保存起来。

~~~
$ more .irbrc
require 'irb/ext/save-history'
IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-save-history"
~~~

##  Shell 切换成debug 模式

你可以将shell切换成debug模式。这样可以看到更多的信息。例如可以看到命令异常的stack trace:

~~~
hbase> debug
~~~

想要在shell中看到 DEBUG 级别的 logging ，可以在启动的时候加上 `-d` 参数.

~~~
$ ./bin/hbase shell -d
~~~

# 5. HBase 和 MapReduce

当 MapReduce job的HBase table 使用TableInputFormat为数据源格式的时候,他的splitter会给这个table的每个region一个map。因此，如果一个table有100个region，就有100个map-tasks，不论需要scan多少个column families 。

通常建议关掉针对HBase的MapReduce job的`预测执行`(speculative execution)功能。这个功能也可以用每个Job的配置来完成。对于整个集群，使用预测执行意味着双倍的运算量。这可不是你所希望的。

# 6.HBase 的 Schema 设计

flush和compaction操作是针对一个Region。

Compaction操作现在是根据一个column family下的全部文件的数量触发的，而不是根据文件大小触发的。当很多的column families在flush和compaction时,会造成很多没用的I/O负载(要想解决这个问题，需要将flush和compaction操作只针对一个column family)

行的版本的数量是HColumnDescriptor设置的，每个column family可以单独设置，默认是3。

# 7. 性能调优

1、长时间GC停顿

Hbase中常见的两种stop-the-world的GC操作：

- 一种是CMS失败的模式
- 另一种是老一代的堆碎片导致的

要想定位第一种，只要将CMS执行的时间提前就可以了，加入 `-XX:CMSInitiatingOccupancyFraction` 参数，把值调低。可以先从60%和70%开始(这个值调的越低，触发的GC次数就越多，消耗的CPU时间就越长)。要想定位第二种错误，Todd加入了一个实验性的功能，将你的Configuration中的 `hbase.hregion.memstore.mslab.enabled` 设置为true。

2、使用压缩

3、设置合理的版本

4、控制split和compaction

# 8. 需要理解一些过程

## 8.1 什么时候做split？

答：根据拆分策略算法来定，具体过程见：[HBase笔记：Region拆分策略](/2014/01/16/hbase-region-split-policy.html)

## 8.2 什么时候做compaction？

答：当有3个小文件时候，会进行合并小文件

## 8.3 memstore什么时候flush，什么时候阻塞写？

答：memstore满了64M就会flush，当memstore大小达到128M时候，聚会阻塞update，进行flush。

## 8.4 HLog什么时候会阻塞写？
