---
layout: post

title:  升级cdh4到cdh5

description: 本文主要记录从CDH4升级到CDH5的过程和遇到的问题，当然本文同样适用于CDH5低版本向最新版本的升级。

keywords:  

category:  hadoop

tags: [hadoop,cdh]

published: true

---

本文主要记录从CDH4升级到CDH5的过程和遇到的问题，当然本文同样适用于CDH5低版本向最新版本的升级。

# 1. 不兼容的变化

升级前，需要注意 cdh5 有哪些不兼容的变化，具体请参考：[Apache Hadoop Incompatible Changes](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_rn_incompatible_changes.html)。

# 2. 升级过程

## 2.1. 备份数据和停止所有服务

### 2.1.1 让 namenode 进入安全模式

在NameNode或者配置了 HA 中的 active NameNode上运行下面命令：

~~~bash
$ sudo -u hdfs hdfs dfsadmin -safemode enter
~~~

保存 fsimage：

~~~bash
$ sudo -u hdfs hdfs dfsadmin -saveNamespace
~~~

如果使用了kerberos，则先获取hdfs用户凭证，再执行下面代码：

~~~bash
$ kinit -k -t /etc/hadoop/conf/hdfs.keytab hdfs/cdh1@JAVACHEN.COM
$ hdfs dfsadmin -safemode enter
$ hdfs dfsadmin -saveNamespace
~~~

### 2.1.2 备份配置文件、数据库和其他重要文件

根据你安装的cdh组件，可能需要备份的配置文件包括：

~~~bash
/etc/hadoop/conf
/etc/hive/conf
/etc/hbase/conf
/etc/zookeeper/conf
/etc/impala/conf
/etc/conf
/etc/sentry/conf
/etc/default/impala
~~~

### 2.1.3 停止所有服务

在每个节点上运行：

~~~bash
for x in `cd /etc/init.d ; ls hadoop-*` ; do sudo service $x stop ; done
for x in `cd /etc/init.d ; ls hbase-*` ; do sudo service $x stop ; done
for x in `cd /etc/init.d ; ls hive-*` ; do sudo service $x stop ; done
for x in `cd /etc/init.d ; ls zookeeper-*` ; do sudo service $x stop ; done
for x in `cd /etc/init.d ; ls hadoop-*` ; do sudo service $x stop ; done
for x in `cd /etc/init.d ; ls impala-*` ; do sudo service $x stop ; done
~~~

### 2.1.4 在每个节点上查看进程

~~~bash
$ ps -aef | grep java
~~~

## 2.2. 备份 hdfs 元数据（可选，防止在操作过程中对数据的误操作）

 a，查找本地配置的文件目录（属性名为 `dfs.name.dir` 或者 `dfs.namenode.name.dir或者hadoop.tmp.dir` ）

~~~bash
grep -C1 hadoop.tmp.dir /etc/hadoop/conf/hdfs-site.xml

#或者
grep -C1 dfs.namenode.name.dir /etc/hadoop/conf/hdfs-site.xml
~~~

通过上面的命令，可以看到类似以下信息：

~~~xml
<property>
<name>hadoop.tmp.dir</name>
<value>/data/dfs/nn</value>
</property>
~~~

b，对hdfs数据进行备份

~~~bash
cd /data/dfs/nn
tar -cvf /root/nn_backup_data.tar .
~~~

## 2.3. 更新 yum 源

如果你使用的是官方的远程yum源，则下载 [cloudera-cdh5.repo](http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo) 文件到 /etc/yum.repos.d 目录：

~~~bash
$ wget http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo -P /etc/yum.repos.d
~~~

如果你使用本地yum，则需要从 http://archive-primary.cloudera.com/cdh5/repo-as-tarball 下载最新的压缩包文件，然后解压到对于目录，以 CDH5.4 版本为例：

~~~bash
$ cd /var/ftp/pub
$ rm -rf cdh
$ wget http://archive-primary.cloudera.com/cdh5/repo-as-tarball/5.4.0/cdh5.4.0-centos6.tar.gz
$ tar zxvf cdh5.4.0-centos6.tar.gz
~~~

然后，在 /etc/yum.repos.d 目录创建一个 repos 文件，指向本地yum源即可，详细过程请自行百度。

## 2.4. 升级组件

在所有节点上运行：

~~~bash
$ sudo yum update hadoop* hbase* hive* zookeeper* bigtop* impala* spark* llama* lzo* sqoop* parquet* sentry* avro* mahout* -y
~~~

启动ZooKeeper集群，如果配置了 HA，则在原来的所有 Journal Nodes 上启动 hadoop-hdfs-journalnode：

~~~bash
# 在安装zookeeper-server的节点上运行
$ /etc/init.d/zookeeper-server start

# 在安装zkfc的节点上运行
$ /etc/init.d/hadoop-hdfs-zkfc

# 在安装journalnode的节点上运行
$ /etc/init.d/hadoop-hdfs-journalnode start
~~~

## 2.5. 更新 hdfs 元数据

在NameNode或者配置了 HA 中的 active NameNode上运行下面命令：

~~~bash
$ sudo service hadoop-hdfs-namenode upgrade
~~~

查看日志，检查是否完成升级，例如查看日志中是否出现`/var/lib/hadoop-hdfs/cache/hadoop/dfs/<name> is complete`

~~~bash
$ sudo tail -f /var/log/hadoop-hdfs/hadoop-hdfs-namenode-<hostname>.log
~~~

如果配置了 HA，在另一个 NameNode 节点上运行：

~~~bash
# 输入 Y
$ sudo -u hdfs hdfs namenode -bootstrapStandby
=====================================================
Re-format filesystem in Storage Directory /data/dfs/nn ? (Y or N)
$ sudo service hadoop-hdfs-namenode start
~~~

启动所有的 DataNode：

~~~bash
$ sudo service hadoop-hdfs-datanode start
~~~

打开 web 界面查看 hdfs 文件是否都存在。

待集群稳定运行一段时间，可以完成升级：

~~~bash
$ sudo -u hdfs hadoop dfsadmin -finalizeUpgrade
~~~

## 2.6. 更新 YARN

更新 YARN 需要注意以下节点：

- `yarn-site.xml` 中做如下改变：
  - `yarn.nodemanager.aux-services`的值从`mapreduce.shuffle` 修改为  `mapreduce_shuffle` 
  - `yarn.nodemanager.aux-services.mapreduce.shuffle.class` 改名为 `yarn.nodemanager.aux-services.mapreduce_shuffle.class`
  - `yarn.resourcemanager.resourcemanager.connect.max.wait.secs` 修改为 `yarn.resourcemanager.connect.max-wait.secs`
  - `yarn.resourcemanager.resourcemanager.connect.retry_interval.secs` 修改为 `yarn.resourcemanager.connect.retry-interval.secs`
 - `yarn.resourcemanager.am. max-retries` 修改为 `yarn.resourcemanager.am.max-attempts`
  - `yarn.application.classpath` 中的环境变量 `YARN_HOME` 属性修改为` HADOOP_YARN_HOME`

然后在启动 YARN 的相关服务。

## 2.7. 更新 HBase

升级 HBase 之前，先启动 zookeeper。

在启动hbase-master进程和hbase-regionserver进程之前，更新 HBase：

~~~bash
$ sudo -u hdfs hbase upgrade -execute
~~~

如果你使用了 phoenix，则请删除 HBase lib 目录下对应的 phoenix 的 jar 包。

启动 HBase：

~~~bash
$ service hbase-master start
$ service hbase-regionserver start
~~~

## 2.8. 更新 hive

在启动hive之前，进入 `/usr/lib/hive/bin` 执行下面命令升级元数据（这里元数据使用的是postgres数据库）：

~~~bash
$ cd /usr/lib/hive/bin
# ./schematool -dbType 数据库类型 -upgradeSchemaFrom 版本号
# 升级之前 hive 版本为 0.14.0，下面命令会运行  /usr/lib/hive/scripts/metastore/upgrade/postgres/upgrade-0.14.0-to-1.1.0.postgres.sql
$ ./schematool -dbType postgres -upgradeSchemaFrom 0.14.0
~~~

确认 /etc/hive/conf/hive-site.xml 和 /etc/hive/conf/hive-env.sh 是否需要修改，例如 /etc/hive/conf/hive-env.sh 配置了如下参数，需要修改到 cdh-5.2 对应的版本：

~~~bash
# 请修改到 cdh5.4对应的 jar 包
$ export HIVE_AUX_JARS_PATH=/usr/lib/hive/lib/hive-contrib-1.1.0-cdh5.4.0.jar
~~~

修改完之后，请同步到其他节点。

然后启动 hive 服务：

~~~bash
$ service hive-metastore start
$ service hive-server2 start
~~~

## 2.9 更新Sentry

如果你从 CDH 5.2.0 以前的版本更新到 CDH 5.2.0 以后的版本，请更新sentry的元数据库：

~~~bash
$ bin/sentry --command schema-tool --conffile <sentry-site.xml> --dbType <db-type> --upgradeSchema
~~~

# 3. 参考文章

- [Upgrading Unmanaged CDH Using the Command Line](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_ig_upgrade_command_line.html)
- [CDH Incompatible Changes](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_rn_incompatible_changes.html)
