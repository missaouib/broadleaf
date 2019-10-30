---
layout: post

title:  CDH中配置HDFS HA
date: 2014-07-18T08:00:00+08:00

description: 最近又安装 hadoop 集群， 故尝试了一下配置 HDFS 的 HA，这里使用的是 QJM 的 HA 方案。

keywords:  

categories: [ hadoop ]

tags: [hadoop]

published: true

---

最近又安装 hadoop 集群， 故尝试了一下配置 HDFS 的 HA，CDH4支持[Quorum-based Storage](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_hdfs_ha_intro.html#topic_2_1_3_unique_1__section_ptk_fh5_mj_unique_1)和[shared storage using NFS](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_hdfs_ha_intro.html#topic_2_1_3_unique_1__section_czt_fh5_mj_unique_1)两种HA方案，而CDH5只支持第一种方案，即 QJM 的 HA 方案。

关于 hadoop 集群的安装部署过程你可以参考 [使用yum安装CDH Hadoop集群](/2019/04/06/install-cloudera-cdh-by-yum) 或者 [手动安装 hadoop 集群的过程](/2014/07/17/manual-install-cdh-hadoop)。

## 集群规划

我一共安装了三个节点的集群，对于 HA 方案来说，三个节点准备安装如下服务：

- cdh1：hadoop-hdfs-namenode(primary) 、hadoop-hdfs-journalnode、hadoop-hdfs-zkfc
- cdh2：hadoop-hdfs-namenode(standby)、hadoop-hdfs-journalnode、hadoop-hdfs-zkfc
- cdh3: hadoop-hdfs-journalnode

根据上面规划，在对应节点上安装相应的服务。

## 安装步骤

### 停掉集群

停掉集群上所有服务。

~~~bash
$ sh /opt/cmd.sh ' for x in `ls /etc/init.d/|grep spark` ; do service $x stop ; done'
​$ sh /opt/cmd.sh ' for x in `ls /etc/init.d/|grep impala` ; do service $x stop ; done'
$ sh /opt/cmd.sh ' for x in `ls /etc/init.d/|grep hive` ; do service $x stop ; done'
$ sh /opt/cmd.sh ' for x in `ls /etc/init.d/|grep hbase` ; do service $x stop ; done'
$ sh /opt/cmd.sh ' for x in `ls /etc/init.d/|grep hadoop` ; do service $x stop ; done'
~~~

cmd.sh代码内容见[Hadoop集群部署权限总结](/2014/11/25/quikstart-for-config-kerberos-ldap-and-sentry-in-hadoop.html)一文中的`/opt/shell/cmd.sh`。

### 停止客户端程序

停止服务集群的所有客户端程序，包括定时任务。

### 备份 hdfs 元数据

a，查找本地配置的文件目录（属性名为 dfs.name.dir 或者 dfs.namenode.name.dir或者hadoop.tmp.dir ）

~~~bash
grep -C1 hadoop.tmp.dir /etc/hadoop/conf/hdfs-site.xml
grep -C1 hadoop.tmp.dir /etc/hadoop/conf/core-site.xml

#或者
grep -C1 dfs.namenode.name.dir /etc/hadoop/conf/hdfs-site.xml
~~~

通过上面的命令，可以看到类似以下信息：

~~~xml
<property>
<name>hadoop.tmp.dir</name>
<value>/var/hadoop</value>
</property>
~~~

b，对hdfs数据进行备份

~~~bash
cd /var/hadoop/dfs/name
tar -cvf /root/name_backup_data.tar .
~~~

### 安装服务

在 cdh1、cdh2、cdh3 上安装 hadoop-hdfs-journalnode 

~~~bash
$ ssh cdh1 'yum install hadoop-hdfs-journalnode -y '
$ ssh cdh2 'yum install hadoop-hdfs-journalnode -y '
$ ssh cdh3 'yum install hadoop-hdfs-journalnode -y '
~~~

在 cdh1、cdh2 上安装 hadoop-hdfs-zkfc：

~~~bash
ssh cdh1 "yum install hadoop-hdfs-zkfc -y "
ssh cdh2 "yum install hadoop-hdfs-zkfc -y "
~~~

### 修改配置文件

修改`/etc/hadoop/conf/core-site.xml`，做如下修改：

~~~xml
<property>
	<name>fs.defaultFS</name>
	<value>hdfs://mycluster:8020</value>
</property>
<property>
	<name>ha.zookeeper.quorum</name>
	<value>cdh1:21088,cdh2:21088,cdh3:21088</value>
</property>
~~~

修改`/etc/hadoop/conf/hdfs-site.xml`，删掉一些原来的 namenode 配置，增加如下：

~~~xml
<!--  hadoop  HA -->
<property>
	<name>dfs.nameservices</name>
	<value>mycluster</value>
</property>
<property>
	<name>dfs.ha.namenodes.mycluster</name>
	<value>nn1,nn2</value>
</property>
<property>
	<name>dfs.namenode.rpc-address.mycluster.nn1</name>
	<value>cdh1:8020</value>
</property>
<property>
	<name>dfs.namenode.rpc-address.mycluster.nn2</name>
	<value>cdh2:8020</value>
</property>
<property>
	<name>dfs.namenode.http-address.mycluster.nn1</name>
	<value>cdh1:50070</value>
</property>
<property>
	<name>dfs.namenode.http-address.mycluster.nn2</name>
	<value>cdh2:50070</value>
</property>
<property>
	<name>dfs.namenode.shared.edits.dir</name>
	<value>qjournal://cdh1:8485,cdh2:8485,cdh3:8485/mycluster</value>
</property>
<property>
	<name>dfs.journalnode.edits.dir</name>
	<value>/var/hadoop/dfs/jn</value>
</property>
<property>
	<name>dfs.client.failover.proxy.provider.mycluster</name>
	<value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
</property>
<property>
	<name>dfs.ha.fencing.methods</name>
	<value>sshfence(hdfs)</value>
</property>
<property>
	<name>dfs.ha.fencing.ssh.private-key-files</name>
	<value>/var/lib/hadoop-hdfs/.ssh/id_rsa</value>
</property>
<property>
	<name>dfs.ha.automatic-failover.enabled</name>
	<value>true</value>
</property>
~~~

### 同步配置文件

将配置文件同步到集群其他节点：

~~~bash
$ sh /opt/syn.sh /etc/hadoop/conf /etc/hadoop/
~~~

在journalnode的三个节点上创建目录：

~~~bash
$ ssh cdh1 'mkdir -p /var/hadoop/dfs/jn ; chown -R hdfs:hdfs /var/hadoop/dfs/jn'
$ ssh cdh2 'mkdir -p /var/hadoop/dfs/jn ; chown -R hdfs:hdfs /var/hadoop/dfs/jn'
$ ssh cdh3 'mkdir -p /var/hadoop/dfs/jn ; chown -R hdfs:hdfs /var/hadoop/dfs/jn'
~~~

### 配置无密码登陆

在两个NN上配置hdfs用户间无密码登陆：

对于 cdh1： 
 
~~~bash           
$ passwd hdfs
$ su - hdfs
$ ssh-keygen
$ ssh-copy-id  cdh2
~~~

对于 cdh2： 

~~~bash
$ passwd hdfs
$ su - hdfs
$ ssh-keygen
$ ssh-copy-id   cdh1
~~~

### 启动journalnode

启动cdh1、cdh2、cdh3上的 hadoop-hdfs-journalnode 服务

~~~bash
$ ssh cdh1 'service hadoop-hdfs-journalnode start'
$ ssh cdh2 'service hadoop-hdfs-journalnode start'
$ ssh cdh3 'service hadoop-hdfs-journalnode start'
~~~

### 初始化共享存储

在namenode上初始化共享存储，如果没有格式化，则先格式化：

~~~bash
hdfs namenode -initializeSharedEdits
~~~

启动NameNode：

~~~bash
$ service hadoop-hdfs-namenode start
~~~

### 同步 Standby NameNode

cdh2作为 Standby NameNode，在该节点上先安装namenode服务

~~~bash
$ yum install hadoop-hdfs-namenode -y
~~~

再运行：

~~~bash
$ sudo -u hdfs hadoop namenode -bootstrapStandby
~~~

如果是使用了kerberos，则先获取hdfs的ticket再执行：

~~~bash
$ kinit -k -t /etc/hadoop/conf/hdfs.keytab hdfs/cdh1@JAVACHEM.COM
$ hadoop namenode -bootstrapStandby
~~~

然后，启动 Standby NameNode：

~~~bash
$ service hadoop-hdfs-namenode start
~~~

### 配置自动切换

在两个NameNode上，即cdh1和cdh2，安装hadoop-hdfs-zkfc

~~~bash
$ ssh cdh1 'yum install hadoop-hdfs-zkfc -y'
$ ssh cdh2 'yum install hadoop-hdfs-zkfc -y'
~~~

在任意一个NameNode上下面命令，其会创建一个znode用于自动故障转移。

~~~bash
$ hdfs zkfc -formatZK
~~~

如果你想对zookeeper的访问进行加密，则请参考 [Enabling HDFS HA](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_hdfs_ha_enabling.html) 中 Securing access to ZooKeeper 这一节内容。

然后再两个 NameNode 节点上启动zkfc：

~~~bash
$ ssh cdh1 "service hadoop-hdfs-zkfc start"
$ ssh cdh2 "service hadoop-hdfs-zkfc start"
~~~

### 测试

分别访问 http://cdh1:50070/ 和 http://cdh2:50070/ 查看谁是 active namenode，谁是 standyby namenode。

查看某Namenode的状态：

~~~bash
#查看cdh1状态
$ sudo -u hdfs hdfs haadmin -getServiceState nn1
active

#查看cdh2状态
$ sudo -u hdfs hdfs haadmin -getServiceState nn2
standby
~~~

执行手动切换：

~~~bash
$ sudo -u hdfs hdfs haadmin -failover nn1 nn2
Failover to NameNode at cdh2/192.168.56.122:8020 successful
~~~

再次访问 http://cdh1:50070/ 和 http://cdh2:50070/ 查看谁是 active namenode，谁是 standyby namenode。

## 配置HBase HA

先停掉 hbase，然后修改/etc/hbase/conf/hbase-site.xml，做如下修改：

~~~ xml
<!-- Configure HBase to use the HA NameNode nameservice -->
<property>
    <name>hbase.rootdir</name>
    <value>hdfs://mycluster:8020/hbase</value>       
  </property>
~~~

在 zookeeper 节点上运行/usr/lib/zookeeper/bin/zkCli.sh

~~~bash
$ ls /hbase/splitlogs
$ rmr /hbase/splitlogs
~~~

最后启动 hbase 服务。

## 配置 Hive HA

运行下面命令将hive的metastore的root地址的HDFS nameservice。

~~~bash
$ /usr/lib/hive/bin/metatool -listFSRoot 
Initializing HiveMetaTool..
Listing FS Roots..
hdfs://cdh1:8020/user/hive/warehouse  

$ /usr/lib/hive/bin/metatool -updateLocation hdfs://mycluster hdfs://cdh1 -tablePropKey avro.schema.url 
-serdePropKey schema.url  

$ metatool -listFSRoot 
Listing FS Roots..
Initializing HiveMetaTool..
hdfs://mycluster:8020/user/hive/warehouse
~~~

## 配置 Impala 

不需要做什么修改，但是一定要记住 core-site.xml 中 `fs.defaultFS` 参数值要带上端口号，在CDH中为 8020。

## 配置 YARN

修改yarn-site.xml：

~~~xml
<property>
  <name>yarn.resourcemanager.ha.enabled</name>
  <value>true</value>
</property>
<property>
  <name>yarn.resourcemanager.cluster-id</name>
  <value>cluster1</value>
</property>
<property>
  <name>yarn.resourcemanager.ha.rm-ids</name>
  <value>rm1,rm2</value>
</property>
<property>
  <name>yarn.resourcemanager.hostname.rm1</name>
  <value>cdh1</value>
</property>
<property>
  <name>yarn.resourcemanager.hostname.rm2</name>
  <value>cdh2</value>
</property>
<property>
  <name>yarn.resourcemanager.webapp.address.rm1</name>
  <value>cdh1:8088</value>
</property>
<property>
  <name>yarn.resourcemanager.webapp.address.rm2</name>
  <value>cdh2:8088</value>
</property>
<property>
  <name>yarn.resourcemanager.zk-address</name>
  <value>cdh1:2181,cdh2:2181,cdh3:2181</value>
</property>
~~~

详细说明请参考 [ResourceManager High Availability](http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html)。

重启yarn，然后查看状态：

```
$ yarn rmadmin -getServiceState cdh1
active

$ yarn rmadmin -getServiceState cdh2
standby
```

## 配置 Hue

暂时未使用

## 配置  Llama

暂时未使用
