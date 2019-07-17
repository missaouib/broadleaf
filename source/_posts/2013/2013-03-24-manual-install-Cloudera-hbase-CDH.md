---
layout: post
title: 手动安装Cloudera HBase CDH
description: 本文主要记录手动安装Cloudera HBase集群过程，环境设置及Hadoop安装过程见上篇文章。
category: hbase
tags: [hbase, cdh]
keywords: hbase, cdh, cloudera manager
---

本文主要记录手动安装Cloudera HBase集群过程，环境设置及Hadoop安装过程见[手动安装Cloudera Hadoop CDH](/images/03/24/manual-install-Cloudera-Hadoop-CDH.html),参考这篇文章，hadoop各个组件和jdk版本如下：

~~~
	hadoop-2.0.0-cdh4.6.0
	hbase-0.94.15-cdh4.6.0
	hive-0.10.0-cdh4.6.0
	jdk1.6.0_38
~~~

hadoop各组件可以在[这里](http://archive.cloudera.com/cdh4/cdh/4/)下载。

集群规划为7个节点，每个节点的ip、主机名和部署的组件分配如下：

~~~
	192.168.0.1        desktop1     NameNode、Hive、ResourceManager、impala
	192.168.0.2        desktop2     SSNameNode
	192.168.0.3        desktop3     DataNode、HBase、NodeManager、impala
~~~

# 安装HBase

HBase安装在desktop3、desktop1、desktop2节点上。

上传hbase压缩包(hbase-0.94.15-cdh4.6.0.tar.gz)到desktop3上的/opt目录，先在desktop3上修改好配置文件，在同步到其他机器上。

`hbase-site.xml`内容修改如下：

~~~xml
	<configuration>
	<property>
		<name>hbase.rootdir</name>
		<value>hdfs://desktop1/hbase-${user.name}</value>
	</property>
	<property>
		<name>hbase.cluster.distributed</name>
		<value>true</value>
	</property>
	<property>
		<name>hbase.tmp.dir</name>
		<value>/opt/data/hbase-${user.name}</value>
	</property>
	<property>
		<name>hbase.zookeeper.quorum</name>
		<value>desktop3,desktop4,desktop6,desktop7,desktop8</value>
	</property>
	</configuration>
~~~

regionservers内容修改如下：

~~~
	desktop1
	desktop2
	desktop3
~~~

接下来将上面几个文件同步到其他各个节点：

~~~
	[root@desktop3 ~]# scp /opt/hbase-0.94.15-cdh4.6.0/conf/ desktop1:/opt/hbase-0.94.15-cdh4.6.0/conf/
	[root@desktop3 ~]# scp /opt/hbase-0.94.15-cdh4.6.0/conf/ desktop2:/opt/hbase-0.94.15-cdh4.6.0/conf/
~~~

# 环境变量

参考[手动安装Cloudera Hadoop CDH](/hadoop/images/03/24/manual-install-Cloudera-Hadoop-CDH.html)中环境变量的设置。

# 启动脚本

在desktop1、desktop2、desktop3节点上分别启动hbase：

~~~
	start-hbase.sh 
~~~

# 相关文章

- [手动安装Hadoop集群](/2019/03/24/manual-install-Cloudera-hadoop-CDH.html)
- [手动安装HBase集群](/2019/03/24/manual-install-Cloudera-hbase-CDH.html)
- [手动安装Hive群](/2019/03/24/manual-install-Cloudera-hive-CDH.html)