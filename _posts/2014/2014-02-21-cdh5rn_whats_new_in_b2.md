---
layout: post
title: CDH 5 Beta 2 的新变化 
description: 这是 CDH 5.0.0 Beta 2的初稿。鉴于 CDH5 目前的发布版本是测试版，它不应用于生产环境中；它只是用来评估、测试的。对于生产环境，请使用 CDH 4。
category: hadoop
tags: [hadoop, cdh]
---

本文是同事对[CDH 5.0.0 Beta 2](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Release-Notes/cdh5rn_whats_new_in_b2.html)的翻译，仅供大家参考。

这是 CDH 5.0.0 Beta 2的初稿。鉴于 CDH 5 目前的发布版本是测试版，它不应用于生产环境中；它只是用来评估、测试的。对于生产环境，请使用 CDH 4,最近的文档在 [CDH Documentation](http://www.cloudera.com/content/support/en/documentation/cdh4-documentation/cdh4-documentation-v4-latest.html)

# Apache Crunch

Apache Crunch 项目开发了新的 Java API，简化了在 Apache Hadoop 之上的数据管道的创建过程。

Crunch APIs 是以 FlumeJava 为蓝本开发的，FlumeJava 是 Google 用来在他们自己的 MapReduce 实现之上构建数据管道的工具库。

更多信息和安装指南，见 [Crunch Installation](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_Crunch_install.html#xd_583c10bfdbd326ba--6eed2fb8-14349d04bee--7ed4)

# Apache DateFu 

从 0.4 更新到 1.1.0(此更新不向后兼容)。
 
新特性包含了 UDFS SHA, SimpleRandomSample, COALESCE, ReservoirSample, EmptyBagToNullFields 以及很多其他部分。

# Apache Flume 

- [FLUME-2294](https://issues.apache.org/jira/browse/FLUME-2294) - 添加了一个 支持 Kite dataset 的 sink
- [FLUME-2056](https://issues.apache.org/jira/browse/FLUME-2056) - Spooling Directory Source 现在只能向 event headers 中传入文件名(而不是文件的完整路径名)。
- [FLUME-2155](https://issues.apache.org/jira/browse/FLUME-2155) - 在文件回放时对文件通道建立索引来提高性能，使它能更快地启动
- [FLUME-2217](https://issues.apache.org/jira/browse/FLUME-2217) - Syslog Source 可选择性地在消息体中保存所有的系统日志头部属性信息(syslog headers)
- [FLUME-2052](https://issues.apache.org/jira/browse/FLUME-2052) - Spooling Directory Source 现在可以替换或忽略所有输入文件中不正常的(malformed)字符

# Apache HBase 

- 支持在线修改表结构
- 支持在线合并 Region
- 命名空间:CDH 5 Beta 2 包含的命名空间特性可以使不同的管理员用户分别管理不同的表。所有被更新的表都会被放在 "hbase" 命名空间中。超级管理员可以创建新命名空间和表。对命名空间拥有权限的用户可以管理里面的表的权限
- 已经有了几个针对 HBase 在 Master 或 RegionServer 出故障时的的平均恢复时间 的改进:
  - 分布式日志分割(split)已经成熟，并且总是被启用的。原来的比较慢的分割机制现在已经没有了
  - 失败检测时间有了提升。若 RegionServer 或 Master 发生故障会很快触发补救措施，此时会发送新的通知。
  - 元数据表有一个专用的 WAL(write ahead log) ,此时如果 RegionServer 的元数据已经保存，它能使 region 更快地恢复
- Region Balancer 有了显著更新，兼顾了更多的负载特性。
- 添加了 TableSnapshotInputFormat 和 TableSnapshotScanner 来扫描 HBase 表的客户端快照，而不是服务器上的,后者将引发一个 MapReduce 作业，前者只会对客户端快照文件做单一的扫描。它们也可用于拥有快照文件的离线 HBase，或直接用于导出的快照文件
- KeyValue API 已经废弃，取而代之的是 Cell 接口。更新到 HBase 0.96 的用户仍可以使用 KeyValue，但以后的更新可能会去掉这个类或它的部分功能。建议用户更新更新他们的应用来使用新的 Cell 接口。
- 当前试验性的一些特性：
  - 分布式日志回放：这个机制使 RegionServer 能更快地从失败中恢复，但它会导致一个特殊情况：它不能保证 ACID(原子性、一致性、隔离性、持久性) 要素Cloudera 现在不建议启用这个特性
  - 大缓存(Bucket cache): 这是个 off-heap 缓存机制，它使用额外的 RAM 和 块设备(如闪存盘等)来极大地增强了 BlockCache 提供的读取缓存的能力。Cloudera 现在不建议启用这个特性
  - 垂青节点(Favored nodes,客户端希望存储数据的节点):为了在发生故障后更好地恢复现场(preserve performance)，这个特性使 HBase 能更好地控制它的数据是从哪里写入HDFS的。目前它还不能很好地与 HBase Balancer 和 HDFS Balancer 交互，所以目前还不可用。Cloudera 现在不建议启用这个特性

更多细节见这个[博客](https://blogs.apache.org/hbase/entry/hbase_0_96_0_released)

# Apache HDFS 

## 新特性及改进：

- 从 CDH 5 Beta 2 开始，你可以更新 HDFS 并启用 HA 特性，如果你使用集群存储(Quorum-based storage)(CDH 5 不支持 NFS 共享存储，唯一的方法是集群存储)。从 CDH 4 到 CDH 5 的更新说明见 [Upgrading to CDH 5 from CDH 4](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_topic_6.html#topic_6)
- [HDFS-4949](https://issues.apache.org/jira/browse/HDFS-4949) - CDH 5 Beta 2 支持 [HDFS 的集中化缓存管理](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hdfs_caching.html#xd_583c10bfdbd326ba--6eed2fb8-14349d04bee--7e7d)
- 从 CDH 5 Beta 2 开始，你可以配置一个 NFSv3 网关，它允许任何 NFSv3 兼容的客户端将 HDFS 挂载为一个客户端的本地文件系统。更多信息和说明，见 [配置 NFSv3 网关](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_NFSv3_gateway.html#xd_583c10bfdbd326ba--6eed2fb8-14349d04bee--7ef4)。
- [HDFS-5709](https://issues.apache.org/jira/browse/HDFS-5709) - 改进对名为 .snapshot 的目录和文件的更新

## 主要的Bug修复:

- [HDFS-5449](https://issues.apache.org/jira/browse/HDFS-5449)- 修股 WebHDFS 的不兼容问题
- [HDFS-5671](https://issues.apache.org/jira/browse/HDFS-5671)- 修复 `DFSInputStream#getBlockReader` 中的 socket 泄漏
- [HDFS-5353](https://issues.apache.org/jira/browse/HDFS-5353)- 启用 `dfs.encrypt.data.transfer` 导致 Short circuit reads 失败的问题
- [HDFS-5438](https://issues.apache.org/jira/browse/HDFS-5438)- 处理文件块报告过程中的导致数据丢失的缺陷

## 改变的行为:

- 从 CDH 5 Beta 2 开始，为了让 NameNode 在一个安全的集群中启动，应该在 `hdfs-site.xml` 中设置 `dfs.web.authentication.kerberos.principal`	 属性。[CDH 5 的安全指南](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Security-Guide/cdh5sg_topic_3_7.html#topic_3_7_unique_2)已经包含了这点。Cloudera Manager 管理的集群则无需显式定义这个属性。
- HDFS-5037 - 启动 NameNode 的操作应该触发它进行日志滚动。当碰到 NameNode 处在安全模式时，客户端会在配置的时间范围内重试。
- mkdir 命令的默认行为有了变化。从 CDH 5 Beta 2 开始，如果父目录不存在就必须使用 `-p` 选项，否则操作将会失败。

# Apache Hive 

## 新特性:

- 改进的 JDBC 规范包括：
  - 改进 `getDatabaseMajorVersion()`, `getDatabaseMinorVersion()` APIs ([HIVE-3181](https://issues.apache.org/jira/browse/HIVE-3181))
  - 添加了对新的数据类型的支持:Char ([HIVE-5683](https://issues.apache.org/jira/browse/HIVE-5209)), Decimal ([HIVE-5355](https://issues.apache.org/jira/browse/HIVE-5355)) and Varchar ([HIVE-5209](https://issues.apache.org/jira/browse/HIVE-5209))
  - 现在可以在 HiveServer2 连接地址(connection URL) 中为会话指定要连接的数据库
- Hive Server 和 Clients 的加密通信。 包括 HiveServer2 对 SSL 加密的支持(非 Kerberos 连接).([HIVE-5351](https://issues.apache.org/jira/browse/HIVE-5351))
- CDH 5 Beta 2 包含了一个可用的本地 Parquet SerDe。用户不需要依赖任何外部包即可直接创建一个 Parquet 格式的表。

## 改变的行为:

- [HIVE-4256](https://issues.apache.org/jira/browse/HIVE-4256)- 启用 Sentry 的情况下，与 HiveServer2 建立连接的工作包含了 use <database> 这个命令 的执行。因此，没有权限访问相应数据库的用户不允许连接到 HiveServer2

# Hue 

- Hue 版本更新到 3.5.0.
- 添加了一个新的 [Spark Editor](http://gethue.tumblr.com/post/71963991256/a-new-spark-web-ui-spark-app) 应用。
- Impala 和 Hive Editor 现在都是单页应用(one-page apps). 编辑器、进度、Table 列表和结果都在同一个页面。
- 用图展示 Impala 和 Hive Editor 的结果数据
- Oozie SLA 的 Editor 和 Dashboard，定时任务，认证信息
- Sqoop2 应用支持数据库和表名/属性的自动补全
- [DBQuery App](http://gethue.tumblr.com/post/66661074125/dbquery-app-mysql-postgresql-oracle-and-sqlite-query): MySQL 和 PostgreSQL Query Editors.
- 新的搜索特性：[支持图形化的套件](http://gethue.tumblr.com/post/66351828212/new-search-feature-graphical-facets)(Graphical facets)
- 集成外部 Web 应用，应用可以是基于任何语言的。更多信息见 [blog post](http://gethue.tumblr.com/post/66367939672/integrate-external-web-applications-in-any-language)
- 创建 Hive 表，加载 quoted CSV data。[参考手册](http://gethue.tumblr.com/post/68282571607/hadoop-tutorial-create-hive-tables-with-headers-and)
- 从 HDFS 直接提交任意 Oozie 作业。[参考手册](http://gethue.tumblr.com/post/68781982681/hadoop-tutorial-submit-any-oozie-jobs-directly-from)
- 新的 [SAML backend](http://gethue.tumblr.com/post/62273866476/sso-with-hue-new-saml-backend) 支持使用 Hue 单点登录

# Apache MapReduce (MRv1 and YARN) 

- 公平调度器支持自动将应用存入队列的高级配置
- MapReduce 支持在 uber 模式和本地 job runner 中运行多个 reducer

# Apache Oozie 

- Oozie now supports cron-style scheduling capability.
- Oozie 现在支持安全的 HA(High Availability with security)

# Apache Pig 

- 重写了 AvroStorage 以提升性能，并且从 piggybank 移到了 core Pig.
- 添加了 ASSERT, IN, 和 CASE 操作
- 添加了 ParquetStorage 来与 Parquet 集成

# Apache Spark (孵化中) 

Spark 是一个快速，通用用于大规模数据处理的引擎。安装和配置指南见 [Spark Installation](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_Spark_install.html#xd_583c10bfdbd326ba--6eed2fb8-14349d04bee--7eff)

# Apache Sqoop2 

版本从 1.99.2 更新到 1.99.3.
 
 
