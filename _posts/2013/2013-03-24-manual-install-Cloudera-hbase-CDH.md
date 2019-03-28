---
layout: post
title: 手动安装Cloudera HBase CDH
description: 本文主要记录手动安装Cloudera HBase集群过程，环境设置及Hadoop安装过程见上篇文章。
category: hbase
tags: [hbase, cdh]
keywords: hbase, cdh, cloudera manager
---

本文主要记录手动安装Cloudera HBase集群过程，环境设置及Hadoop安装过程见[手动安装Cloudera Hadoop CDH](/2013/03/24/manual-install-Cloudera-Hadoop-CDH.html),参考这篇文章，hadoop各个组件和jdk版本如下：

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
	192.168.0.4        desktop4     DataNode、HBase、NodeManager、impala
	192.168.0.5        desktop5     DataNode、HBase、NodeManager、impala
	192.168.0.6        desktop6     DataNode、HBase、NodeManager、impala
	192.168.0.7        desktop7     DataNode、HBase、NodeManager、impala
~~~

# 安装HBase

HBase安装在desktop3、desktop4、desktop5、desktop6、desktop7节点上。

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
	desktop3
	desktop4
	desktop5
	desktop6
	desktop7
~~~

接下来将上面几个文件同步到其他各个节点（desktop4、desktop5、desktop6、desktop7）：

~~~
	[root@desktop3 ~]# scp /opt/hbase-0.94.15-cdh4.6.0/conf/ desktop4:/opt/hbase-0.94.15-cdh4.6.0/conf/
	[root@desktop3 ~]# scp /opt/hbase-0.94.15-cdh4.6.0/conf/ desktop5:/opt/hbase-0.94.15-cdh4.6.0/conf/
	[root@desktop3 ~]# scp /opt/hbase-0.94.15-cdh4.6.0/conf/ desktop6:/opt/hbase-0.94.15-cdh4.6.0/conf/
	[root@desktop3 ~]# scp /opt/hbase-0.94.15-cdh4.6.0/conf/ desktop7:/opt/hbase-0.94.15-cdh4.6.0/conf/
~~~

# 环境变量

参考[手动安装Cloudera Hadoop CDH](/hadoop/2013/03/24/manual-install-Cloudera-Hadoop-CDH.html)中环境变量的设置。

# 启动脚本

在desktop3、desktop4、desktop5、desktop6、desktop7节点上分别启动hbase：

~~~
	start-hbase.sh 
~~~
