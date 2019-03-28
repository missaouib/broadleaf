---
layout: post
title: CDH4.5.0 新特性
description: CDH4.5.0 新特性
category: hadoop
tags: [hadoop,cdh]
---

# Apache Flume

## 新特性：

- [FLUME-2190](https://issues.apache.org/jira/browse/FLUME-2190) - 引入一个新的Twitter firehose的feed源
- [FLUME-2109](https://issues.apache.org/jira/browse/FLUME-2109) - HTTP输入源支持HTTPS.
- [FLUME-1666](https://issues.apache.org/jira/browse/FLUME-1666) - 系统日志的TCP源现在可以保持时间戳和处理领域中的事件主体.
- [FLUME-2202](https://issues.apache.org/jira/browse/FLUME-2202) - AsyncHBaseSink can now coalesce increments to the same row and column per transaction to reduce the number of RPC calls
- [FLUME-2189](https://issues.apache.org/jira/browse/FLUME-2189) - Avro Source can now accept events from a restricted set of peers
- [FLUME-2052](https://issues.apache.org/jira/browse/FLUME-2052) - Spooling Directory Source can now ignore or replace malformed characters.
- Flume自动检测Cloudera Search依赖。

## 变化的特性：

- Memory Channel calculates byte capacity usage on transaction commits instead of puts to improve performance

# Apache Hive

## 新特性：

- 新增支持非Kerberos身份验证HiveServer2和JDBC客户端之间的SSL加密通信,请见[Configuring Encrypted Client/Server Communication for non-Kerberos HiveServer2 Connections](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-Security-Guide/cdh4sg_topic_9_1.html#concept_rqh_sff_cm_unique_2)

# Hue

## 新特性：

- 增加了对SAML验证后端和其他安全修补程序支持.

## 变化的特性:

- [HUE-1609](https://issues.apache.org/jira/browse/HUE-1609) - [core] LDAP后端和进口应不区分大小写.
- [HUE-1632](https://issues.apache.org/jira/browse/HUE-1632) - [oozie] Workflow with & in a property fails to submit.
- [HUE-1555](https://issues.apache.org/jira/browse/HUE-1555) - [hbase] Python 2.4 支持.
- [HUE-1521](https://issues.apache.org/jira/browse/HUE-1521) - [core] 改进 JobTracker HA.
- [search] 默认的模板应显示的所有字段.
- [core] 让搜索绑定认证可选的LDAP

# Apache MapReduce v1 (MRv1)

## 新特性:

- HDFS访问追踪：当`mapreduce.job.token.tracking.ids`设置为true时，MRv1任务根据持有的HDFS访问凭证来访问HDFS上的数据。而且，当MRv1其访问数据数据时HDFS日志会记录其访问信息。 
- 堆栈跟踪的任务超时： 为了便于调试，当MR任务超时时会累记其堆栈信息.
- `KeyOnlyTextInputWriter` 和`KeyOnlyTextOutputReader`使工作流不使用分隔符即可写入/读取文本.

## 变化的特性：

- 用户在使用MRv1压缩包的`bin-mapreduce1`目录下的脚本时，不再需要根据情况的不同而设置不同的环境变量了.

# Apache MapReduce v2 (YARN)

## 新特性:

- HDFS访问追踪：当`mapreduce.job.token.tracking.ids`设置为true时，MRv1任务根据持有的HDFS访问凭证来访问HDFS上的数据。而且，当MRv1其访问数据数据时HDFS日志会记录其访问信.
- `KeyOnlyTextInputWriter` 和`KeyOnlyTextOutputReader`使工作流不使用分隔符即可写入/读取文本.
- 公平调度器现在可以不用受节点心跳检测的判断影响，从而可以更快的调度

# Apache Oozie

## 新特性:

- Pig和Hive现在无需手动操作或配置即可访问 Parquet 文件.

# Apache Sentry (孵化中)

## 新特性:

- Hive Metastore服务的访问可以不受`IPTables`的限定。在HiveServer2和ImpalaD运行的用户必须要首先在`core-site.xml`中配置，然后才可以访问Hive Metastore服务。
例如，hivemetastore 是Hive Metastore服务的用户。`hive`和`impala`分别是运行HiveServer2 和 ImpalaD不同用户。按如下的配置，这些用户将被允许访问Hive Metastore服务.

~~~
<property>
    <name>hadoop.proxyuser.hivemetastore.groups</name>
    <value>hive，impala</value>
</property>
~~~
Sentry现在已经集成到Cloudera Search中，配置方法请参考：[ Configuring Sentry for Search](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Search/latest/Cloudera-Search-User-Guide/csug_sentry.html)

原文地址：[What's New in CDH4.5.0](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-Release-Notes/Whats_New_in_4-5.html)

