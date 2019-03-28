---
layout: post
title: 手动安装Cloudera Hive CDH
description: 本文主要记录手动安装CDH Hive过程，环境设置及Hadoop、HBase安装过程见上篇文章。
category: hive
tags: [hadoop, hive]
---

本文主要记录手动安装Cloudera Hive集群过程，环境设置及Hadoop安装过程见[手动安装Cloudera Hadoop CDH](/2013/03/24/manual-install-Cloudera-Hadoop-CDH.html),参考这篇文章，hadoop各个组件和jdk版本如下：

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

# 安装hive

hive安装在desktop1上，**注意**：hive默认是使用derby数据库保存元数据，这里替换为postgresql，下面会提到postgresql的安装说明，并且需要拷贝postgres的jdbc jar文件导hive的lib目录下。

上传`hive-0.10.0-cdh4.6.0.tar`到desktop1的`/opt`，并解压缩。

# 安装postgres

## 创建数据库

这里创建数据库metastore并创建hiveuser用户，其密码为redhat。

~~~
	bash# sudo -u postgres psql
	bash$ psql
	postgres=# CREATE USER hiveuser WITH PASSWORD 'redhat';
	postgres=# CREATE DATABASE metastore owner=hiveuser;
	postgres=# GRANT ALL privileges ON DATABASE metastore TO hiveuser;
	postgres=# \q;
~~~

## 初始化数据库

~~~
psql  -U hiveuser -d metastore
 \i /opt/hive-0.10.0-cdh4.6.0/scripts/metastore/upgrade/postgres/hive-schema-0.10.0.postgres.sql 
~~~

编辑postgresql配置文件(`/opt/PostgreSQL/9.1/data/pg_hba.conf`)，修改访问权限

~~~
host    all             all             0.0.0.0/0            md5
~~~

修改postgresql.conf

~~~
	standard_conforming_strings = of
~~~

## 重起postgres

拷贝postgres的jdbc驱动到`/opt/hive-0.10.0-cdh4.6.0/lib`目录。

~~~
su -c '/opt/PostgreSQL/9.1/bin/pg_ctl -D /opt/PostgreSQL/9.1/data restart' postgres
~~~

# 修改配置文件

## hive-site.xml 

注意修改下面配置文件中postgres数据库的密码，注意配置`hive.aux.jars.path`，在hive集成hbase时候需要从该路径家在hbase的一些jar文件。

hive-site.xml文件内容如下：

~~~xml
<configuration>
<property>
  <name>javax.jdo.option.ConnectionURL</name>
  <value>jdbc:postgresql://127.0.0.1/metastore</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionDriverName</name>
  <value>org.postgresql.Driver</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionUserName</name>
  <value>hiveuser</value>
</property>
<property>
  <name>javax.jdo.option.ConnectionPassword</name>
  <value>redhat</value>
</property>
<property>
 <name>mapred.job.tracker</name>
 <value>desktop1:8031</value>
</property>
<property>
 <name>mapreduce.framework.name</name>
 <value>yarn</value>
</property>
<property>
  <name>hive.aux.jars.path</name>
  <value>file:///opt/hive-0.10.0-cdh4.6.0/lib/zookeeper-3.4.5-cdh4.6.0.jar,
	file:///opt/hive-0.10.0-cdh4.6.0/lib/hive-hbase-handler-0.10.0-cdh4.6.0.jar,
	file:///opt/hive-0.10.0-cdh4.6.0/lib/hbase-0.94.15-cdh4.6.0.jar,
	file:///opt/hive-0.10.0-cdh4.6.0/lib/guava-11.0.2.jar</value>
</property>
<property>
  <name>hive.metastore.warehouse.dir</name>
  <value>/opt/data/warehouse-${user.name}</value>
</property>
<property>
  <name>hive.exec.scratchdir</name>
  <value>/opt/data/hive-${user.name}</value>
</property>
<property>
  <name>hive.querylog.location</name>
  <value>/opt/data/querylog-${user.name}</value>
</property>
<property>
  <name>hive.support.concurrency</name>
  <value>true</value>
</property>
<property>
  <name>hive.zookeeper.quorum</name>
  <value>desktop3,desktop4,desktop5,desktop6,desktop7</value>
</property>
<property>
  <name>hive.hwi.listen.host</name>
  <value>desktop1</value>
</property>
<property>
  <name>hive.hwi.listen.port</name>
  <value>9999</value>
</property>
<property>
  <name>hive.hwi.war.file</name>
  <value>lib/hive-hwi-0.10.0-cdh4.6.0.war</value>
</property>
</configuration>
~~~

## 环境变量

参考[手动安装Cloudera Hadoop CDH](/hadoop/2013/03/24/manual-install-Cloudera-Hadoop-CDH.html)中环境变量的设置。

## 启动hive

在启动完之后，执行一些sql语句可能会提示错误，如何解决错误可以参考[Hive安装与配置](http://kicklinux.com/hive-deploy/)。

## hive与hbase集成

在`hive-site.xml`中配置`hive.aux.jars.path`,在环境变量中配置hadoop、mapreduce的环境变量


# 异常说明

## 异常1：

~~~
FAILED: Error in metadata: MetaException(message:org.apache.hadoop.hbase.ZooKeeperConnectionException: An error is preventing HBase from connecting to ZooKeeper
~~~

原因：hadoop配置文件没有zk

## 异常2

~~~
FAILED: Error in metadata: MetaException(message:Got exception: org.apache.hadoop.hive.metastore.api.MetaException javax.jdo.JDODataStoreException: Error executing JDOQL query "SELECT "THIS"."TBL_NAME" AS NUCORDER0 FROM "TBLS" "THIS" LEFT OUTER JOIN "DBS" "THIS_DATABASE_NAME" ON "THIS"."DB_ID" = "THIS_DATABASE_NAME"."DB_ID" WHERE "THIS_DATABASE_NAME"."NAME" = ? AND (LOWER("THIS"."TBL_NAME") LIKE ? ESCAPE '\\' ) ORDER BY NUCORDER0 " : ERROR: invalid escape string 建议：Escape string must be empty or one character..
~~~

参考：https://issues.apache.org/jira/browse/HIVE-3994

## 异常3，以下语句没反应

~~~	
select count(*) from hive_userinfo
~~~
## 异常4

~~~
zookeeper.ClientCnxn (ClientCnxn.java:logStartConnect(966)) - Opening socket connection to server localhost/127.0.0.1:2181. Will not attempt to authenticate using SASL (无法定位登录配置)
~~~

原因：hive中没有设置zk

## 异常5

~~~
hbase 中提示：WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
~~~

原因：cloudera hadoop lib中没有hadoop的native jar

## 异常6

~~~	
Exception in thread "main" java.lang.NoClassDefFoundError: org/apache/hadoop/mapreduce/v2/app/MRAppMaster
~~~

原因：classpath没有配置正确，检查环境变量以及yarn的classpath

# 参考文章

* [Hive安装与配置](http://kicklinux.com/hive-deploy/)
* [Hive Installation](https://ccp.cloudera.com/display/CDH4DOC/Hive+Installation)
