---
layout: post
title:  使用yum源安装CDH Hadoop集群
description: 本文主要是记录使用yum源安装CDH Hadoop集群的过程，包括HDFS、Yarn、Hive和HBase。本文针对的集群版本为CDH5.4。
category: hadoop
tags: [hadoop, hdfs, yarn, hive ,hbase]
---

本文主要是记录使用yum安装CDH Hadoop集群的过程，包括HDFS、Yarn、Hive和HBase。`本文使用CDH5.4版本进行安装，故下文中的过程都是针对CDH5.4版本的`。

# 0. 环境说明

系统环境：

- 操作系统：CentOs 6.6
- Hadoop版本：`CDH5.4`
- JDK版本：`1.7.0_71`
- 运行用户：root

集群各节点角色规划为：

~~~
192.168.56.121        cdh1     NameNode、ResourceManager、HBase、Hive metastore、Impala Catalog、Impala statestore、Sentry 
192.168.56.122        cdh2     DataNode、SecondaryNameNode、NodeManager、HBase、Hive Server2、Impala Server
192.168.56.123        cdh3     DataNode、HBase、NodeManager、Hive Server2、Impala Server
~~~

cdh1作为master节点，其他节点作为slave节点。

# 1. 准备工作

安装 Hadoop 集群前先做好下面的准备工作，在修改配置文件的时候，建议在一个节点上修改，然后同步到其他节点，例如：对于 hdfs 和 yarn ，在 NameNode 节点上修改然后再同步，对于 HBase，选择一个节点再同步。因为要同步配置文件和在多个节点启动服务，建议配置 ssh 无密码登陆。

## 1.1 配置hosts

CDH 要求使用 IPv4，IPv6 不支持，**禁用IPv6方法：**

~~~bash
$ vim /etc/sysctl.conf
#disable ipv6
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
~~~

使其生效：

~~~bash
$ sysctl -p
~~~

最后确认是否已禁用：

~~~bash
$ cat /proc/sys/net/ipv6/conf/all/disable_ipv6
1
~~~

1、设置hostname，以cdh1为例：

~~~bash
$ hostname cdh1
~~~

2、确保`/etc/hosts`中包含ip和FQDN，如果你在使用DNS，保存这些信息到`/etc/hosts`不是必要的，却是最佳实践。

3、确保`/etc/sysconfig/network`中包含`hostname=cdh1`

4、检查网络，运行下面命令检查是否配置了hostname以及其对应的ip是否正确。

运行`uname -a`查看hostname是否匹配`hostname`命令运行的结果：

~~~bash
$ uname -a
Linux cdh1 2.6.32-358.23.2.el6.x86_64 #1 SMP Wed Oct 16 18:37:12 UTC 2013 x86_64 x86_64 x86_64 GNU/Linux
$ hostname
cdh1
~~~

运行`/sbin/ifconfig`查看ip:

~~~bash
$ ifconfig
eth1      Link encap:Ethernet  HWaddr 08:00:27:75:E0:95  
          inet addr:192.168.56.121  Bcast:192.168.56.255  Mask:255.255.255.0
......
~~~

先安装bind-utils，才能运行host命令：

~~~bash
$ yum install bind-utils -y
~~~

运行下面命令查看hostname和ip是否匹配:

~~~bash
$ host -v -t A `hostname`
Trying "cdh1"
...
;; ANSWER SECTION:
cdh1. 60 IN	A	192.168.56.121
~~~

5、hadoop的所有配置文件中配置节点名称时，请使用hostname和不是ip

## 1.2 关闭防火墙

~~~bash
$ setenforce 0
$ vim /etc/sysconfig/selinux #修改SELINUX=disabled

#清空iptables
$ iptables -F
~~~

## 1.3 时钟同步

## 搭建时钟同步服务器

这里选择 cdh1 节点为时钟同步服务器，其他节点为客户端同步时间到该节点。安装ntp:

~~~bash
$ yum install ntp
~~~

修改 cdh1 上的配置文件 `/etc/ntp.conf` :

~~~
restrict default ignore   //默认不允许修改或者查询ntp,并且不接收特殊封包
restrict 127.0.0.1        //给于本机所有权限
restrict 192.168.56.0 mask 255.255.255.0 notrap nomodify  //给于局域网机的机器有同步时间的权限
server  192.168.56.121     # local clock
driftfile /var/lib/ntp/drift
fudge   127.127.1.0 stratum 10
~~~

启动 ntp：

~~~bash
#设置开机启动
$ chkconfig ntpd on

$ service ntpd start
~~~

ntpq用来监视ntpd操作，使用标准的NTP模式6控制消息模式，并与NTP服务器通信。

`ntpq -p` 查询网络中的NTP服务器，同时显示客户端和每个服务器的关系。

~~~
$ ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*LOCAL(1)        .LOCL.           5 l    6   64    1    0.000    0.000   0.000
~~~

- "* "：响应的NTP服务器和最精确的服务器。
- "+"：响应这个查询请求的NTP服务器。
- "blank（空格）"：没有响应的NTP服务器。
- "remote" ：响应这个请求的NTP服务器的名称。
- "refid "：NTP服务器使用的更高一级服务器的名称。
- "st"：正在响应请求的NTP服务器的级别。
- "when"：上一次成功请求之后到现在的秒数。
- "poll"：当前的请求的时钟间隔的秒数。
- "offset"：主机通过NTP时钟同步与所同步时间源的时间偏移量，单位为毫秒（ms）。

## 客户端的配置

在cdh2和cdh3节点上执行下面操作：

~~~bash
$ ntpdate cdh1
~~~

Ntpd启动的时候通常需要一段时间大概5分钟进行时间同步，所以在ntpd刚刚启动的时候还不能正常提供时钟服务，报错"no server suitable for synchronization found"。启动时候需要等待5分钟。

如果想定时进行时间校准，可以使用crond服务来定时执行。

~~~bash
# 每天 1:00 Linux 系统就会自动的进行网络时间校准
00 1 * * * root /usr/sbin/ntpdate 192.168.56.121 >> /root/ntpdate.log 2>&1
~~~

## 1.4 安装jdk

CDH5.4要求使用JDK1.7，JDK的安装过程请参考网上文章。

## 1.5 设置本地yum源

CDH官方的yum源地址在 http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/cloudera-cdh4.repo 或 http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo ，请根据你安装的cdh版本修改该文件中baseurl的路径。

你可以从[这里](http://archive.cloudera.com/cdh4/repo-as-tarball/)下载 cdh4 的仓库压缩包，或者从[这里](http://archive.cloudera.com/cdh5/repo-as-tarball/) 下载 cdh5 的仓库压缩包。

因为我是使用的centos操作系统，故我这里下载的是cdh5的centos6压缩包，将其下载之后解压到ftp服务的路径下，然后配置cdh的本地yum源：

~~~
[hadoop]
name=hadoop
baseurl=ftp://cdh1/cdh/5/
enabled=1
gpgcheck=0
~~~

操作系统的yum源，建议你通过下载 centos 的 dvd 然后配置一个本地的 yum 源。

# 2. 安装和配置HDFS

根据文章开头的节点规划，cdh1 为NameNode节点，cdh2为SecondaryNameNode节点，cdh2 和 cdh3 为DataNode节点

在 cdh1 节点安装 hadoop-hdfs-namenode：

~~~bash
$ yum install hadoop hadoop-hdfs hadoop-client hadoop-doc hadoop-debuginfo hadoop-hdfs-namenode
~~~

在 cdh2 节点安装 hadoop-hdfs-secondarynamenode

~~~bash
$ yum install hadoop-hdfs-secondarynamenode -y
~~~

在 cdh2、cdh3节点安装 hadoop-hdfs-datanode

~~~bash
$ yum install hadoop hadoop-hdfs hadoop-client hadoop-doc hadoop-debuginfo hadoop-hdfs-datanode -y
~~~

NameNode HA 的配置过程请参考[CDH中配置HDFS HA](/2014/07/18/install-hdfs-ha-in-cdh.html)，建议暂时不用配置。

## 2.1 修改hadoop配置文件

在`/etc/hadoop/conf/core-site.xml`中设置`fs.defaultFS`属性值，该属性指定NameNode是哪一个节点以及使用的文件系统是file还是hdfs，格式：`hdfs://<namenode host>:<namenode port>/`，默认的文件系统是`file:///`：

~~~xml
<property>
 <name>fs.defaultFS</name>
 <value>hdfs://cdh1:8020</value>
</property>
~~~

在`/etc/hadoop/conf/hdfs-site.xml`中设置`dfs.permissions.superusergroup`属性，该属性指定hdfs的超级用户，默认为hdfs，你可以修改为hadoop：

~~~xml
<property>
 <name>dfs.permissions.superusergroup</name>
 <value>hadoop</value>
</property>
~~~

> 更多的配置信息说明，请参考 [Apache Cluster Setup](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html)

## 2.2 指定本地文件目录

在hadoop中默认的文件路径以及权限要求如下：

~~~
目录									所有者		权限		默认路径
hadoop.tmp.dir						hdfs:hdfs	drwx------	/var/hadoop
dfs.namenode.name.dir				hdfs:hdfs	drwx------	file://${hadoop.tmp.dir}/dfs/name
dfs.datanode.data.dir				hdfs:hdfs	drwx------	file://${hadoop.tmp.dir}/dfs/data
dfs.namenode.checkpoint.dir			hdfs:hdfs	drwx------	file://${hadoop.tmp.dir}/dfs/namesecondary
~~~

说明你可以在 hdfs-site.xm l中只配置`hadoop.tmp.dir`，也可以分别配置上面的路径。这里使用分别配置的方式，hdfs-site.xml中配置如下：

~~~xml
<property>
 <name>dfs.namenode.name.dir</name>
 <value>file:///data/dfs/nn</value>
</property>

<property>
 <name>dfs.datanode.data.dir</name>
<value>file:///data/dfs/dn</value>
</property>
~~~

在**NameNode**上手动创建 `dfs.name.dir` 或 `dfs.namenode.name.dir` 的本地目录：

~~~bash
$ mkdir -p /data/dfs/nn
~~~

在**DataNode**上手动创建 `dfs.data.dir` 或 `dfs.datanode.data.dir` 的本地目录：

~~~bash
$ mkdir -p /data/dfs/dn
~~~

修改上面目录所有者：

~~~
$ chown -R hdfs:hdfs /data/dfs/nn /data/dfs/dn
~~~

hadoop的进程会自动设置 `dfs.data.dir` 或 `dfs.datanode.data.dir`，但是 `dfs.name.dir` 或 `dfs.namenode.name.dir` 的权限默认为755，需要手动设置为700：

~~~bash
$ chmod 700 /data/dfs/nn

# 或者
$ chmod go-rx /data/dfs/nn
~~~

注意：DataNode的本地目录可以设置多个，你可以设置 `dfs.datanode.failed.volumes.tolerated` 参数的值，表示能够容忍不超过该个数的目录失败。

## 2.3 配置 SecondaryNameNode

配置 SecondaryNameNode 需要在 `/etc/hadoop/conf/hdfs-site.xml` 中添加以下参数：

~~~bash
dfs.namenode.checkpoint.check.period
dfs.namenode.checkpoint.txns
dfs.namenode.checkpoint.dir
dfs.namenode.checkpoint.edits.dir
dfs.namenode.num.checkpoints.retained
~~~

在 `/etc/hadoop/conf/hdfs-site.xml` 中加入如下配置，将cdh2设置为 SecondaryNameNode：

~~~xml
<property>
  <name>dfs.secondary.http.address</name>
  <value>cdh2:50090</value>
</property>
~~~

设置多个secondarynamenode，请参考[multi-host-secondarynamenode-configuration](http://blog.cloudera.com/blog/2009/02/multi-host-secondarynamenode-configuration/).

## 2.4 开启回收站功能

回收站功能默认是关闭的，建议打开。在 `/etc/hadoop/conf/core-site.xml` 中添加如下两个参数：

- `fs.trash.interval`,该参数值为时间间隔，单位为分钟，默认为0，表示回收站功能关闭。该值表示回收站中文件保存多长时间，如果服务端配置了该参数，则忽略客户端的配置；如果服务端关闭了该参数，则检查客户端是否有配置该参数；
- `fs.trash.checkpoint.interval`，该参数值为时间间隔，单位为分钟，默认为0。该值表示检查回收站时间间隔，该值要小于`fs.trash.interval`，该值在服务端配置。如果该值设置为0，则使用 `fs.trash.interval` 的值。

## 2.5 (可选)配置DataNode存储的负载均衡

在 `/etc/hadoop/conf/hdfs-site.xml` 中配置以下三个参数：

- `dfs.datanode.fsdataset. volume.choosing.policy`
- `dfs.datanode.available-space-volume-choosing-policy.balanced-space-threshold`
- `dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction`

详细说明，请参考 [Optionally configure DataNode storage balancing](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hdfs_cluster_deploy.html#concept_ncq_nnk_ck_unique_1)。

## 2.6 开启WebHDFS

在NameNode节点上安装：

~~~bash
$ yum install hadoop-httpfs -y
~~~

然后修改 /etc/hadoop/conf/core-site.xml配置代理用户：

~~~xml
<property>  
<name>hadoop.proxyuser.httpfs.hosts</name>  
<value>*</value>  
</property>  
<property>  
<name>hadoop.proxyuser.httpfs.groups</name>  
<value>*</value>  
</property>
~~~

## 2.7 配置LZO

下载repo文件到 `/etc/yum.repos.d/`:

 - 如果你安装的是 CDH4，请下载[Red Hat/CentOS 6](http://archive.cloudera.com/gplextras/redhat/6/x86_64/gplextras/cloudera-gplextras4.repo)
 - 如果你安装的是 CDH5，请下载[Red Hat/CentOS 6](http://archive.cloudera.com/gplextras5/redhat/6/x86_64/gplextras/cloudera-gplextras5.repo)

然后，安装lzo:

~~~bash
$ yum install hadoop-lzo* impala-lzo  -y
~~~

最后，在 `/etc/hadoop/conf/core-site.xml` 中添加如下配置：

~~~xml
<property>
  <name>io.compression.codecs</name>
  <value>org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.GzipCodec,
org.apache.hadoop.io.compress.BZip2Codec,com.hadoop.compression.lzo.LzoCodec,
com.hadoop.compression.lzo.LzopCodec</value>
</property>
<property>
  <name>io.compression.codec.lzo.class</name>
  <value>com.hadoop.compression.lzo.LzoCodec</value>
</property>
~~~

更多关于LZO信息，请参考：[Using LZO Compression](http://wiki.apache.org/hadoop/UsingLzoCompression)

## 2.8 (可选)配置Snappy

cdh 的 rpm 源中默认已经包含了 snappy ，直接在每个节点安装Snappy：

~~~bash
$ yum install snappy snappy-devel  -y
~~~

然后，在 `core-site.xml` 中修改`io.compression.codecs`的值，添加 `org.apache.hadoop.io.compress.SnappyCodec` 。

使 snappy 对 hadoop 可用：

~~~bash
$ ln -sf /usr/lib64/libsnappy.so /usr/lib/hadoop/lib/native/
~~~

## 2.9 启动HDFS

将cdh1上的配置文件同步到每一个节点：

~~~bash
$ scp -r /etc/hadoop/conf root@cdh2:/etc/hadoop/
$ scp -r /etc/hadoop/conf root@cdh3:/etc/hadoop/
~~~

在cdh1节点格式化NameNode：

~~~bash
$ sudo -u hdfs hadoop namenode -format
~~~

在每个节点运行下面命令启动hdfs：

~~~bash
$ for x in `ls /etc/init.d/|grep  hadoop-hdfs` ; do service $x start ; done
~~~

在 hdfs 运行之后，创建 `/tmp` 临时目录，并设置权限为 `1777`：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir /tmp
$ sudo -u hdfs hadoop fs -chmod -R 1777 /tmp
~~~

如果安装了HttpFS，则启动 HttpFS 服务：

~~~bash
$ service hadoop-httpfs start
~~~

## 2.10 测试

通过 <http://cdh1:50070/> 可以访问 NameNode 页面。使用 curl 运行下面命令，可以测试 webhdfs 并查看执行结果：

~~~bash
$ curl "http://localhost:14000/webhdfs/v1?op=gethomedirectory&user.name=hdfs"
{"Path":"\/user\/hdfs"}
~~~

更多的 API，请参考 [WebHDFS REST API](http://archive.cloudera.com/cdh5/cdh/5/hadoop/hadoop-project-dist/hadoop-hdfs/WebHDFS.html)

# 3. 安装和配置YARN

根据文章开头的节点规划，cdh1 为resourcemanager节点，cdh2 和 cdh3 为nodemanager节点，为了简单，historyserver 也装在 cdh1 节点上。

## 3.1 安装服务

在 cdh1 节点安装:

~~~bash
$ yum install hadoop-yarn hadoop-yarn-resourcemanager -y

#安装 historyserver
$ yum install hadoop-mapreduce-historyserver hadoop-yarn-proxyserver -y
~~~

在 cdh2、cdh3 节点安装:

~~~bash
$ yum install hadoop-yarn hadoop-yarn-nodemanager hadoop-mapreduce -y
~~~

## 3.2 修改配置参数

要想使用YARN，需要在 `/etc/hadoop/conf/mapred-site.xml` 中做如下配置:

~~~xml
<property>
	<name>mapreduce.framework.name</name>
	<value>yarn</value>
</property>
~~~

修改/etc/hadoop/conf/yarn-site.xml，配置resourcemanager的节点名称以及一些服务的端口号：

~~~xml
<property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>cdh1:8031</value>
</property>
<property>
    <name>yarn.resourcemanager.address</name>
    <value>cdh1:8032</value>
</property>
<property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>cdh1:8030</value>
</property>
<property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>cdh1:8033</value>
</property>
<property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>cdh1:8088</value>
</property>
~~~

在 `/etc/hadoop/conf/yarn-site.xml` 中添加如下配置：

~~~xml
<property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
</property>
<property>
    <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
</property>
<property>
    <name>yarn.log-aggregation-enable</name>
    <value>true</value>
</property>
<property>
    <name>yarn.application.classpath</name>
   <value>
    $HADOOP_CONF_DIR,
    $HADOOP_COMMON_HOME/*,
    $HADOOP_COMMON_HOME/lib/*,
    $HADOOP_HDFS_HOME/*,
    $HADOOP_HDFS_HOME/lib/*,
    $HADOOP_MAPRED_HOME/*,
    $HADOOP_MAPRED_HOME/lib/*,
    $HADOOP_YARN_HOME/*,
    $HADOOP_YARN_HOME/lib/*
    </value>
</property>
<property>
	<name>yarn.log.aggregation.enable</name>
	<value>true</value>
</property>
~~~

**注意：**

- `yarn.nodemanager.aux-services` 的值在 cdh4 中应该为 `mapreduce.shuffle`，并配置参数`yarn.nodemanager.aux-services.mapreduce.shuffle.class`值为 `org.apache.hadoop.mapred.ShuffleHandler` ，在cdh5中为`mapreduce_shuffle`，这时候请配置`yarn.nodemanager.aux-services.mapreduce_shuffle.class`参数

- 这里配置了 `yarn.application.classpath` ，需要设置一些喜欢环境变量：

~~~bash
export HADOOP_HOME=/usr/lib/hadoop
export HIVE_HOME=/usr/lib/hive
export HBASE_HOME=/usr/lib/hbase
export HADOOP_HDFS_HOME=/usr/lib/hadoop-hdfs
export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
export HADOOP_COMMON_HOME=${HADOOP_HOME}
export HADOOP_HDFS_HOME=/usr/lib/hadoop-hdfs
export HADOOP_LIBEXEC_DIR=${HADOOP_HOME}/libexec
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export HDFS_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export HADOOP_YARN_HOME=/usr/lib/hadoop-yarn
export YARN_CONF_DIR=${HADOOP_HOME}/etc/hadoop
~~~

在hadoop中默认的文件路径以及权限要求如下：

~~~
目录									                   所有者		 权限		        默认路径
yarn.nodemanager.local-dirs			      yarn:yarn	  drwxr-xr-x    ${hadoop.tmp.dir}/nm-local-dir
yarn.nodemanager.log-dirs			        yarn:yarn	  drwxr-xr-x	  ${yarn.log.dir}/userlogs
yarn.nodemanager.remote-app-log-dir							                hdfs://cdh1:8020/var/log/hadoop-yarn/apps
~~~

故在 `/etc/hadoop/conf/yarn-site.xml` 文件中添加如下配置:

~~~xml
<property>
    <name>yarn.nodemanager.local-dirs</name>
    <value>/data/yarn/local</value>
</property>
<property>
    <name>yarn.nodemanager.log-dirs</name>
    <value>/data/yarn/logs</value>
</property>
<property>
    <name>yarn.nodemanager.remote-app-log-dir</name>
    <value>/yarn/apps</value>
</property>
~~~

创建 `yarn.nodemanager.local-dirs` 和 `yarn.nodemanager.log-dirs` 参数对应的目录：

~~~bash
$ mkdir -p /data/yarn/{local,logs}
$ chown -R yarn:yarn /data/yarn
~~~

在 hdfs 上创建 `yarn.nodemanager.remote-app-log-dir` 对应的目录：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir -p /yarn/apps
$ sudo -u hdfs hadoop fs -chown yarn:mapred /yarn/apps
$ sudo -u hdfs hadoop fs -chmod 1777 /yarn/apps
~~~

在 `/etc/hadoop/conf/mapred-site.xml` 中配置 MapReduce History Server：

~~~xml
<property>
    <name>mapreduce.jobhistory.address</name>
    <value>cdh1:10020</value>
</property>
<property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>cdh1:19888</value>
</property>
~~~

此外，确保 mapred、yarn 用户能够使用代理，在 `/etc/hadoop/conf/core-site.xml` 中添加如下参数：

~~~xml
<property>
    <name>hadoop.proxyuser.mapred.groups</name>
    <value>*</value>
</property>
<property>
    <name>hadoop.proxyuser.mapred.hosts</name>
    <value>*</value>
</property>
<property>
    <name>hadoop.proxyuser.yarn.groups</name>
    <value>*</value>
</property>
<property>
    <name>hadoop.proxyuser.yarn.hosts</name>
    <value>*</value>
</property>
~~~

配置 Staging 目录：

~~~xml
<property>
    <name>yarn.app.mapreduce.am.staging-dir</name>
    <value>/user</value>
</property>
~~~

并在 hdfs 上创建相应的目录：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir -p /user
$ sudo -u hdfs hadoop fs -chmod 777 /user
~~~

可选的，你可以在 `/etc/hadoop/conf/mapred-site.xml` 设置以下两个参数：

- `mapreduce.jobhistory.intermediate-done-dir`，该目录权限应该为1777，默认值为 `${yarn.app.mapreduce.am.staging-dir}/history/done_intermediate`
- `mapreduce.jobhistory.done-dir`，该目录权限应该为750，默认值为 `${yarn.app.mapreduce.am.staging-dir}/history/done`

然后，在 hdfs 上创建目录并设置权限：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir -p /user/history
$ sudo -u hdfs hadoop fs -chmod -R 1777 /user/history
$ sudo -u hdfs hadoop fs -chown mapred:hadoop /user/history
~~~

设置 `HADOOP_MAPRED_HOME`，或者把其加入到 hadoop 的配置文件中

~~~bash
$ export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
~~~

## 3.4 验证 HDFS 结构：

~~~bash
$ sudo -u hdfs hadoop fs -ls -R /
~~~

你应该看到如下结构：

~~~bash
drwxrwxrwt   - hdfs hadoop          0 2014-04-19 14:21 /tmp
drwxrwxrwx   - hdfs hadoop          0 2014-04-19 14:26 /user
drwxrwxrwt   - mapred hadoop        0 2014-04-19 14:31 /user/history
drwxr-x---   - mapred hadoop        0 2014-04-19 14:38 /user/history/done
drwxrwxrwt   - mapred hadoop        0 2014-04-19 14:48 /user/history/done_intermediate
drwxr-xr-x   - hdfs   hadoop        0 2014-04-19 15:31 /yarn
drwxrwxrwt   - yarn   mapred        0 2014-04-19 15:31 /yarn/apps
~~~

## 3.5 同步配置文件

同步配置文件到整个集群:

~~~bash
$ scp -r /etc/hadoop/conf root@cdh2:/etc/hadoop/
$ scp -r /etc/hadoop/conf root@cdh3:/etc/hadoop/
~~~

## 3.6 启动服务

在每个节点启动 YARN :

~~~bash
$ for x in `ls /etc/init.d/|grep hadoop-yarn` ; do service $x start ; done
~~~

在 cdh1 节点启动 mapred-historyserver :

~~~bash
$ /etc/init.d/hadoop-mapreduce-historyserver start
~~~

为每个 MapReduce 用户创建主目录，比如说 hive 用户或者当前用户：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir /user/$USER
$ sudo -u hdfs hadoop fs -chown $USER /user/$USER
~~~

## 3.7 测试

通过 <http://cdh1:8088/> 可以访问 Yarn 的管理页面，通过 <http://cdh1:19888/> 可以访问 JobHistory 的管理页面，查看在线的节点：<http://cdh1:8088/cluster/nodes>。

运行下面的测试程序，看是否报错：

~~~bash
# Find how many jars name ending with examples you have inside location /usr/lib/
$ find /usr/lib/ -name "*hadoop*examples*.jar"

# To list all the class name inside jar
$ find /usr/lib/ -name "hadoop-examples.jar" | xargs -0 -I '{}' sh -c 'jar tf {}'

# To search for specific class name inside jar
$ find /usr/lib/ -name "hadoop-examples.jar" | xargs -0 -I '{}' sh -c 'jar tf {}' | grep -i wordcount.class

# 运行 randomwriter 例子
$ sudo -u hdfs hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar randomwriter out
~~~

# 4. 安装 Zookeeper

Zookeeper 至少需要3个节点，并且节点数要求是基数，这里在所有节点上都安装 Zookeeper。

## 4.1 安装

在每个节点上安装zookeeper：

~~~bash
$ yum install zookeeper* -y
~~~

## 4.2 修改配置文件

设置 zookeeper 配置 `/etc/zookeeper/conf/zoo.cfg`

~~~properties
maxClientCnxns=50
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper
clientPort=2181
server.1=cdh1:2888:3888
server.2=cdh3:2888:3888
server.3=cdh3:2888:3888
~~~

##4.3  同步配置文件

将配置文件同步到其他节点：

~~~bash
$ scp -r /etc/zookeeper/conf root@cdh2:/etc/zookeeper/
$ scp -r /etc/zookeeper/conf root@cdh3:/etc/zookeeper/
~~~

## 4.4 初始化并启动服务

在每个节点上初始化并启动 zookeeper，注意 n 的值需要和 zoo.cfg 中的编号一致。

在 cdh1 节点运行：

~~~bash
$ service zookeeper-server init --myid=1
$ service zookeeper-server start
~~~

在 cdh2 节点运行：

~~~bash
$ service zookeeper-server init --myid=2
$ service zookeeper-server start
~~~

在 cdh3 节点运行：

~~~
$ service zookeeper-server init --myid=3
$ service zookeeper-server start
~~~

## 4.5 测试

通过下面命令测试是否启动成功：

~~~bash
$ zookeeper-client -server cdh1:2181
~~~

# 5. 安装 HBase

HBase 依赖 ntp 服务，故需要提前安装好 ntp。

## 5.1 安装前设置

1）修改系统 ulimit 参数，在 `/etc/security/limits.conf` 中添加下面两行并使其生效：

~~~
hdfs  -       nofile  32768
hbase -       nofile  32768
~~~

2）修改 `dfs.datanode.max.xcievers`，在 `hdfs-site.xml` 中修改该参数值，将该值调整到较大的值：

~~~xml
<property>
  <name>dfs.datanode.max.xcievers</name>
  <value>8192</value>
</property>
~~~

## 5.2 安装

在每个节点上安装 master 和 regionserver，如果需要你可以安装 hbase-rest、hbase-solr-indexer、hbase-thrift

~~~bash
$ yum install hbase hbase-master hbase-regionserver -y
~~~

## 5.3 修改配置文件

修改 `hbase-site.xml`文件，关键几个参数及含义如下：

- `hbase.distributed`：是否为分布式模式
- `hbase.rootdir`：HBase在hdfs上的目录路径
- `hbase.tmp.dir`：本地临时目录
- `hbase.zookeeper.quorum`：zookeeper集群地址，逗号分隔
- `hbase.hregion.max.filesize`：hregion文件最大大小
- `hbase.hregion.memstore.flush.size`：memstore文件最大大小

另外，在CDH5中建议`关掉Checksums`（见[Upgrading HBase](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hbase_upgrade.html)）以提高性能，最后的配置如下：

~~~xml
<configuration>
  <property>
      <name>hbase.cluster.distributed</name>
      <value>true</value>
  </property>
  <property>
      <name>hbase.rootdir</name>
      <value>hdfs://cdh1:8020/hbase</value>
  </property>
  <property>
      <name>hbase.tmp.dir</name>
      <value>/data/hbase</value>
  </property>
  <property>
      <name>hbase.zookeeper.quorum</name>
      <value>cdh1,cdh2,cdh3</value>
  </property>
  <property>
    <name>hbase.hregion.max.filesize</name>
    <value>536870912</value>
  </property>
  <property>
    <name>hbase.hregion.memstore.flush.size</name>
    <value>67108864</value>
  </property>
  <property>
    <name>hbase.regionserver.lease.period</name>
    <value>600000</value>
  </property>
  <property>
    <name>hbase.client.retries.number</name>
    <value>3</value>
  </property>
  <property>
    <name>hbase.regionserver.handler.count</name>
    <value>100</value>
  </property>
  <property>
    <name>hbase.hstore.compactionThreshold</name>
    <value>10</value>
  </property>
  <property>
    <name>hbase.hstore.blockingStoreFiles</name>
    <value>30</value>
  </property>

  <property>
    <name>hbase.regionserver.checksum.verify</name>
    <value>false</value>
  </property>
  <property>
    <name>hbase.hstore.checksum.algorithm</name>
    <value>NULL</value>
  </property>
</configuration>
~~~

在 hdfs 中创建 `/hbase` 目录

~~~bash
$ sudo -u hdfs hadoop fs -mkdir /hbase
$ sudo -u hdfs hadoop fs -chown hbase:hbase /hbase
~~~

设置 crontab 定时删除日志：

~~~
$ crontab -e
* 10 * * * cd /var/log/hbase/; rm -rf `ls /var/log/hbase/|grep -P 'hbase\-hbase\-.+\.log\.[0-9]'\`>> /dev/null &
~~~

## 5.4 同步配置文件

将配置文件同步到其他节点：

~~~bash
$ scp -r /etc/hbase/conf root@cdh2:/etc/hbase/
$ scp -r /etc/hbase/conf root@cdh3:/etc/hbase/
~~~

## 5.5 创建本地目录

在 hbase-site.xml 配置文件中配置了 `hbase.tmp.dir` 值为 `/data/hbase`，现在需要在每个 hbase 节点创建该目录并设置权限：

~~~bash
$ mkdir /data/hbase
$ chown -R hbase:hbase /data/hbase/
~~~

## 5.6 启动HBase

~~~bash
$ for x in `ls /etc/init.d/|grep hbase` ; do service $x start ; done
~~~

## 5.7 测试

通过 <http://cdh1:60030/> 可以访问 RegionServer 页面，然后通过该页面可以知道哪个节点为 Master，然后再通过 60010 端口访问 Master 管理界面。

# 6. 安装hive

在一个 NameNode 节点上安装 hive：

~~~bash
$ yum install hive hive-metastore hive-server2 hive-jdbc hive-hbase  -y
~~~

在其他 DataNode 上安装：

~~~bash
$ yum install hive hive-server2 hive-jdbc hive-hbase -y
~~~

## 安装postgresql

这里使用 postgresq l数据库来存储元数据，如果你想使用 mysql 数据库，请参考下文。手动安装、配置 postgresql 数据库，请参考 [手动安装Cloudera Hive CDH](/hadoop/2013/03/24/manual-install-Cloudera-hive-CDH.html)

yum 方式安装：

~~~
$ yum install postgresql-server postgresql-jdbc -y

$ ln -s /usr/share/java/postgresql-jdbc.jar /usr/lib/hive/lib/postgresql-jdbc.jar
~~~

配置开启启动，并初始化数据库：

~~~bash
$ chkconfig postgresql on
$ service postgresql initdb
~~~

修改配置文件postgresql.conf，修改完后内容如下：

~~~bash
$ cat /var/lib/pgsql/data/postgresql.conf  | grep -e listen -e standard_conforming_strings
	listen_addresses = '*'
	standard_conforming_strings = off
~~~

修改 /var/lib/pgsql/data/pg_hba.conf，添加以下一行内容：

~~~
	host    all         all         0.0.0.0/0                     trust
~~~

创建数据库和用户，设置密码为hive：

~~~bash
su -c "cd ; /usr/bin/pg_ctl start -w -m fast -D /var/lib/pgsql/data" postgres
su -c "cd ; /usr/bin/psql --command \"create user hive with password 'hive'; \" " postgres
su -c "cd ; /usr/bin/psql --command \"drop database hive;\" " postgres
su -c "cd ; /usr/bin/psql --command \"CREATE DATABASE sentry owner=hive;\" " postgres
su -c "cd ; /usr/bin/psql --command \"GRANT ALL privileges ON DATABASE hive TO hive;\" " postgres
su -c "cd ; /usr/bin/pg_ctl restart -w -m fast -D /var/lib/pgsql/data" postgres
~~~

这时候的hive-site.xml文件内容如下：

~~~xml
<configuration>
	    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:postgresql://localhost/hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.postgresql.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive</value>
    </property>
    <property>
        <name>datanucleus.autoCreateSchema</name>
        <value>false</value>
    </property>

    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>cdh1:8031</value>
    </property>

    <property>
        <name>hive.auto.convert.join</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.metastore.schema.verification</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>
    <property>
        <name>hive.warehouse.subdir.inherit.perms</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://cdh1:9083</value>
    </property>
    <property>
        <name>hive.metastore.client.socket.timeout</name>
        <value>36000</value>
    </property>
    <property>
        <name>hive.support.concurrency</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.zookeeper.quorum</name>
        <value>cdh1,cdh2,cdh3</value>
    </property>
    <property>
        <name>hive.server2.thrift.min.worker.threads</name>
        <value>5</value>
    </property>
    <property>
        <name>hive.server2.thrift.max.worker.threads</name>
        <value>100</value>
    </property>
</configuration>
~~~

默认情况下，hive-server和 hive-server2 的 thrift 端口都为10000，如果要修改 hive-server2 thrift 端口，请修改 `hive.server2.thrift.port` 参数的值。

如果要设置运行 hive 的用户为连接的用户而不是启动用户，则添加：

~~~xml
<property>
    <name>hive.server2.enable.impersonation</name>
    <value>true</value>
</property>
~~~

并在 core-site.xml 中添加：

~~~xml
<property>
  <name>hadoop.proxyuser.hive.hosts</name>
  <value>*</value>
</property>
<property>
  <name>hadoop.proxyuser.hive.groups</name>
  <value>*</value>
</property>
~~~

## 安装mysql

yum方式安装mysql以及jdbc驱动：

~~~bash
$ yum install mysql mysql-devel mysql-server mysql-libs -y

$ yum install mysql-connector-java
$ ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/hive/lib/mysql-connector-java.jar
~~~

创建数据库和用户，并设置密码为hive：

~~~bash
$ mysql -e "
	CREATE DATABASE hive;
	USE hive;
	CREATE USER 'hive'@'localhost' IDENTIFIED BY 'hive';
	GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'localhost';
	GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'cdh1';
	FLUSH PRIVILEGES;
"
~~~

如果是第一次安装，则初始化 hive 的元数据库：

~~~bash
$ /usr/lib/hive/bin/schematool --dbType mysql --initSchema
~~~

如果是更新，则执行：

~~~bash
$ /usr/lib/hive/bin/schematool --dbType mysql --upgradeSchema
~~~

配置开启启动并启动数据库：

~~~bash
$ chkconfig mysqld on
$ service mysqld start
~~~

修改 hive-site.xml 文件中以下内容：

~~~xml
	<property>
	  <name>javax.jdo.option.ConnectionURL</name>
	  <value>jdbc:mysql://cdh1:3306/hive?useUnicode=true&amp;characterEncoding=UTF-8</value>
	</property>
	<property>
	  <name>javax.jdo.option.ConnectionDriverName</name>
	  <value>com.mysql.jdbc.Driver</value>
	</property>
            <property>
                <name>javax.jdo.option.ConnectionUserName</name>
                <value>hive</value>
            </property>

            <property>
                <name>javax.jdo.option.ConnectionPassword</name>
                <value>hive</value>
            </property>
~~~

## 配置hive

修改`/etc/hadoop/conf/hadoop-env.sh`，添加环境变量 `HADOOP_MAPRED_HOME`，如果不添加，则当你使用 yarn 运行 mapreduce 时候会出现 `UNKOWN RPC TYPE` 的异常

~~~bash
export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
~~~

在 hdfs 中创建 hive 数据仓库目录:

- hive 的数据仓库在 hdfs 中默认为 `/user/hive/warehouse`,建议修改其访问权限为 `1777`，以便其他所有用户都可以创建、访问表，但不能删除不属于他的表。
- 每一个查询 hive 的用户都必须有一个 hdfs 的 home 目录( `/user` 目录下，如 root 用户的为 `/user/root`)
- hive 所在节点的 `/tmp` 必须是 world-writable 权限的。

创建目录并设置权限：

~~~bash
$ sudo -u hdfs hadoop fs -mkdir /user/hive
$ sudo -u hdfs hadoop fs -chown hive /user/hive

$ sudo -u hdfs hadoop fs -mkdir /user/hive/warehouse
$ sudo -u hdfs hadoop fs -chmod 1777 /user/hive/warehouse
$ sudo -u hdfs hadoop fs -chown hive /user/hive/warehouse
~~~

启动hive-server和metastore:

~~~bash
$ service hive-metastore start
$ service hive-server start
$ service hive-server2 start
~~~

## 测试

~~~bash
$ hive -e 'create table t(id int);'
$ hive -e 'select * from t limit 2;'
$ hive -e 'select id from t;'
~~~

访问beeline:

~~~bash
$ beeline
beeline> !connect jdbc:hive2://localhost:10000 hive hive org.apache.hive.jdbc.HiveDriver
~~~

## 与hbase集成

先安装 hive-hbase:

~~~bash
$ yum install hive-hbase -y
~~~

如果你是使用的 cdh4，则需要在 hive shell 里执行以下命令添加 jar：

~~~bash
$ ADD JAR /usr/lib/hive/lib/zookeeper.jar;
$ ADD JAR /usr/lib/hive/lib/hbase.jar;
$ ADD JAR /usr/lib/hive/lib/hive-hbase-handler-<hive_version>.jar
# guava 包的版本以实际版本为准。
$ ADD JAR /usr/lib/hive/lib/guava-11.0.2.jar;
~~~

如果你是使用的 cdh5，则需要在 hive shell 里执行以下命令添加 jar：

~~~
ADD JAR /usr/lib/hive/lib/zookeeper.jar;
ADD JAR /usr/lib/hive/lib/hive-hbase-handler.jar;
ADD JAR /usr/lib/hbase/lib/guava-12.0.1.jar;
ADD JAR /usr/lib/hbase/hbase-client.jar;
ADD JAR /usr/lib/hbase/hbase-common.jar;
ADD JAR /usr/lib/hbase/hbase-hadoop-compat.jar;
ADD JAR /usr/lib/hbase/hbase-hadoop2-compat.jar;
ADD JAR /usr/lib/hbase/hbase-protocol.jar;
ADD JAR /usr/lib/hbase/hbase-server.jar;
~~~

以上你也可以在 hive-site.xml 中通过 `hive.aux.jars.path` 参数来配置，或者你也可以在 hive-env.sh 中通过 `export HIVE_AUX_JARS_PATH=` 来设置。

# 7. 参考文章

* [1] [CDH5-Installation-Guide](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/CDH5-Installation-Guide.html)
* [2] [hadoop cdh 安装笔记](http://roserouge.iteye.com/blog/1558498)
