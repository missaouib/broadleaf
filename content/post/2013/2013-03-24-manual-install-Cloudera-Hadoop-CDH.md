---
layout: post
title: 手动安装Hadoop集群
date: 2013-03-24T00:00:00+08:00
description: 手动安装Cloudera Hadoop CDH4
categories: [hadoop]
tags: [hadoop,cdh]
---

# 安装版本

centos版本为6。

hadoop各个组件和jdk版本如下：

~~~
	hadoop-2.0.0-cdh4.6.0
	hbase-0.94.15-cdh4.6.0
	hive-0.10.0-cdh4.6.0
	jdk1.6.0_38
~~~

hadoop各组件可以在[这里](http://archive.cloudera.com/cdh4/cdh/4/)下载。

# 安装前说明

* 确定安装目录为/opt
* 检查hosts文件是否设置集群各节点的hostname和ip映射
* 关闭每个节点的防火墙
* 设置每个节点时钟同步

# 规划

集群规划为3个节点，每个节点的ip、主机名和部署的组件分配如下：

~~~
	192.168.0.1        desktop1     NameNode、Hive、ResourceManager、impala
	192.168.0.2        desktop2     SSNameNode
	192.168.0.3        desktop3     DataNode、HBase、NodeManager、impala
~~~

# 部署过程
## 系统和网络配置

1. 修改每个节点的主机名称

	例如在desktop1节点上做如下修改：

~~~
	[root@desktop1 ~]# cat /etc/sysconfig/network
	NETWORKING=yes
	HOSTNAME=desktop1
~~~

2. 在每个节点上修改`/etc/hosts`增加以下内容:

~~~
	[root@desktop1 ~]# cat /etc/hosts
	127.0.0.1   localhost
	192.168.0.1		desktop1
	192.168.0.2		desktop2
~~~

修改一台机器之后，可以使用scp同步到其他机器。

3. 配置ssh无密码登陆

以下是设置desktop1上可以无密码登陆到其他机器上。

~~~
	[root@desktop1 ~]# ssh-keygen
	[root@desktop1 ~]# ssh-copy-id -i .ssh/id_rsa.pub desktop2
	[root@desktop1 ~]# ssh-copy-id -i .ssh/id_rsa.pub desktop3
~~~

4. 每台机器上关闭防火墙：

~~~
	[root@desktop1 ~]# service iptables stop
	[root@desktop1 ~]# ssh desktop2 'service iptables stop'
	[root@desktop1 ~]# ssh desktop3 'service iptables stop'
~~~

# 安装Hadoop
## 配置Hadoop

将jdk1.6.0_38.zip上传到/opt，并解压缩。

将hadoop-2.0.0-cdh4.2.0.zip上传到/opt，并解压缩。

**在NameNode上需要修改以下文件**：

-	core-site.xml fs.defaultFS指定NameNode文件系统，开启回收站功能。
-	hdfs-site.xml 
 - 		dfs.namenode.name.dir指定NameNode存储meta和editlog的目录，
 -		dfs.datanode.data.dir指定DataNode存储blocks的目录，
 -	 	dfs.namenode.secondary.http-address指定Secondary NameNode地址。
 -		开启WebHDFS。
-	slaves 添加DataNode节点主机

**注意**：在desktop1节点上修改如下几个文件的内容：

1. core-site.xml

在该文件中修改fs.defaultFS指向desktop1节点，即配置desktop1为NameNode节点。

修改后的core-site.xml(`/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/core-site.xml`)目录如下：

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<!--fs.default.name for MRV1 ,fs.defaultFS for MRV2(yarn) -->
<property>
     <name>fs.defaultFS</name>
         <!--这个地方的值要和hdfs-site.xml文件中的dfs.federation.nameservices一致-->
     <value>hdfs://desktop1</value>
</property>
<property>
<name>fs.trash.interval</name>
<value>10080</value>
</property>
<property>
<name>fs.trash.checkpoint.interval</name>
<value>10080</value>
</property>
</configuration>
~~~

2. hdfs-site.xml

该文件主要设置数据副本保存份数，以及namenode、datanode数据保存路径(`/opt/data/hadoop-${user.name}`)以及http-address。

修改后的hdfs-site.xml(`/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/hdfs-site.xml`)文件内容如下：

~~~
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>dfs.replication</name>
  <value>1</value>
</property>
<property>
  <name>hadoop.tmp.dir</name>
  <value>/opt/data/hadoop-${user.name}</value>
</property>
<property>
<name>dfs.namenode.http-address</name>
<value>desktop1:50070</value>
</property>
<property>
<name>dfs.namenode.secondary.http-address</name>
<value>desktop2:50090</value>
</property>
<property>
<name>dfs.webhdfs.enabled</name>
<value>true</value>
</property>
</configuration>
~~~

3. masters

设置namenode和secondary namenode节点。

修改后的masters(`/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/masters`)文件内容如下：

~~~
desktop1
desktop2
~~~

第一行为namenode，第二行为secondary namenode。

4. slaves

设置哪些机器上安装datanode节点。
修改后的slaves(`/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/slaves`)文件内容如下：

~~~
desktop3
desktop4
desktop5
desktop6
desktop7
~~~

接下来将上面几个文件同步到其他各个节点：

~~~
	[root@desktop1 ~]# scp /opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/ desktop2:/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/
	[root@desktop1 ~]# scp /opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/ desktop3:/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/
~~~

## 配置MapReduce

接下来还是在desktop1节点上修改以下几个文件：

1. mapred-site.xml

配置使用yarn计算框架，以及jobhistory的地址。

修改后的mapred-site.xml(`/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/mapred-site.xml`)文件内容如下：

~~~
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
 <name>mapreduce.framework.name</name>
 <value>yarn</value>
</property>
<property>
 <name>mapreduce.jobhistory.address</name>
 <value>desktop1:10020</value>
</property>
<property>
 <name>mapreduce.jobhistory.webapp.address</name>
 <value>desktop1:19888</value>
</property>
</configuration>
~~~

2. yarn-site.xml

主要配置resourcemanager地址以及`yarn.application.classpath`（这个路径很重要，要不然集成hive时候会提示找不到class）

修改后的yarn-site.xml(`/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/yarn-site.xml`)文件内容如下：

~~~
<?xml version="1.0"?>
<configuration>
<property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>desktop1:8031</value>
  </property>
  <property>
    <name>yarn.resourcemanager.address</name>
    <value>desktop1:8032</value>
  </property>
  <property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>desktop1:8030</value>
  </property>
  <property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>desktop1:8033</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>desktop1:8088</value>
  </property>
  <property>
    <description>Classpath for typical applications.</description>
    <name>yarn.application.classpath</name>
    <value>$HADOOP_CONF_DIR,$HADOOP_COMMON_HOME/share/hadoop/common/*,
	$HADOOP_COMMON_HOME/share/hadoop/common/lib/*,
	$HADOOP_HDFS_HOME/share/hadoop/hdfs/*,$HADOOP_HDFS_HOME/share/hadoop/hdfs/lib/*,
	$YARN_HOME/share/hadoop/yarn/*,$YARN_HOME/share/hadoop/yarn/lib/*,
	$YARN_HOME/share/hadoop/mapreduce/*,$YARN_HOME/share/hadoop/mapreduce/lib/*</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce.shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
  <property>
    <name>yarn.nodemanager.local-dirs</name>
    <value>/opt/data/yarn/local</value>
  </property>
  <property>
    <name>yarn.nodemanager.log-dirs</name>
    <value>/opt/data/yarn/logs</value>
  </property>
  <property>
    <description>Where to aggregate logs</description>
    <name>yarn.nodemanager.remote-app-log-dir</name>
    <value>/opt/data/yarn/logs</value>
  </property>
  <property>
    <name>yarn.app.mapreduce.am.staging-dir</name>
    <value>/user</value>
 </property>
</configuration>
~~~

同样地，将上面2个文件同步到其他各个节点：

~~~
	[root@desktop1 ~]# scp /opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/ desktop2:/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/
	[root@desktop1 ~]# scp /opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/ desktop3:/opt/hadoop-2.0.0-cdh4.6.0/etc/hadoop/
~~~

## 修改环境变量

修改`/root/.bashrc`环境变量，并将其同步到其他几台机器

~~~
[root@desktop1 ~] # cat .bashrc 
# .bashrc
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
# User specific environment and startup programs
export LANG=zh_CN.utf8
export JAVA_HOME=/opt/jdk1.6.0_38
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=./:$JAVA_HOME/lib:$JRE_HOME/lib:$JRE_HOME/lib/tools.jar
export HADOOP_HOME=/opt/hadoop-2.0.0-cdh4.2.0
export HIVE_HOME=/opt/hive-0.10.0-cdh4.2.0
export HBASE_HOME=/opt/hbase-0.94.2-cdh4.2.0
export HADOOP_MAPRED_HOME=${HADOOP_HOME}
export HADOOP_COMMON_HOME=${HADOOP_HOME}
export HADOOP_HDFS_HOME=${HADOOP_HOME}
export YARN_HOME=${HADOOP_HOME}
export HADOOP_YARN_HOME=${HADOOP_HOME}
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export HDFS_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export YARN_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export PATH=$PATH:$HOME/bin:$JAVA_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin:$HIVE_HOME/bin
~~~

修改配置文件之后，使其生效。

~~~
[root@desktop1 ~]# source .bashrc 
~~~

将该文件同步到其他各个节点：

~~~
	[root@desktop1 ~]# scp /root/.bashrc desktop2:/root
	[root@desktop1 ~]# scp /root/.bashrc desktop3:/root
~~~

并且使各个节点的环境变量生效：

~~~
	[root@desktop1 ~]# ssh desktop2 'source .bashrc'
	[root@desktop1 ~]# ssh desktop3 'source .bashrc'
~~~


## 启动脚本

第一次启动hadoop需要先格式化NameNode，该操作只做一次。当修改了配置文件时，需要重新格式化

在desktop1上格式化：

~~~
[root@desktop1 hadoop]hadoop namenode -format
~~~

在desktop1上启动hdfs：

~~~
[root@desktop1 hadoop]#start-dfs.sh
~~~

在desktop1上启动mapreduce：

~~~
[root@desktop1 hadoop]#start-yarn.sh
~~~

在desktop1上启动historyserver：

~~~
[root@desktop1 hadoop]#mr-jobhistory-daemon.sh start historyserver
~~~

查看MapReduce：

~~~
http://desktop1:8088/cluster
~~~

查看节点：

~~~
http://desktop2:8042/
http://desktop2:8042/node
~~~

## 检查集群进程 

~~~
[root@desktop1 ~]# jps
5389 NameNode
5980 Jps
5710 ResourceManager
7032 JobHistoryServer
[root@desktop2 ~]# jps
3187 Jps
3124 SecondaryNameNode
[root@desktop3 ~]# jps
3187 Jps
3124 DataNode
5711 NodeManager
~~~

# 相关文章

- [手动安装Hadoop集群](/2019/03/24/manual-install-Cloudera-hadoop-CDH.html)
- [手动安装HBase集群](/2019/03/24/manual-install-Cloudera-hbase-CDH.html)
- [手动安装Hive群](/2019/03/24/manual-install-Cloudera-hive-CDH.html)
