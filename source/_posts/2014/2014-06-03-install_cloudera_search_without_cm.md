---
layout: post

title: 不用Cloudera Manager安装Cloudera Search

description: Cloudera Search 用来在 hadoop 基础上建立索引和全文检索，本文主要记录如何安装 CLoudera Search 的过程，其中也包括如何安装和启动 Zookeeper、Solr、MapReduce等工具和服务。

keywords: Cloudera Search 用来在 hadoop 基础上建立索引和全文检索

category: hadoop

tags: [solr,hadoop,solrcloud]

published: true

---

Cloudera Search 用来在 hadoop 基础上建立索引和全文检索，本文主要记录如何安装 CLoudera Search 的过程，其中也包括如何安装和启动 Zookeeper、Solr、MapReduce等工具和服务。

# Cloudera Search介绍

Cloudera Search 核心部件包括 Hadoop 和 Solr，后者建立在 Lucene 之上；而 Hadoop 也正是在06年正式成为 Lucene 的一个子项目而发展起来的。

通过 Tika, Cloudera Search 支持大量的被广泛使用的文件格式；除此之外，Cloudera Search 还支持很多其他在Hadoop应用中常用的数据，譬如 Avro, SequenceFile, 日志文件等。

用来建立索引和全文检索的数据可以是来自于 HDFS，譬如日志文件，Hive 或者 HBase 的表等等（通过集成 NGData 的 Lily 项目，对 HBasae 的支持工作也在进行中）。或者通过结合使用 Flume 采集于外部数据源，通过一个新支持的 Flume Sink 直接写到索引库里；同时还可以充分利用 Flume 来对要建立索引的数据进行各种预处理，譬如转换，提取创建元数据等。
 
建立的索引存储于 HDFS。这给搜索带来了易于扩展，冗余和容错的好处。此外，我们还可以运行 MapReduce 来对我们所需要检索的数据进行索引，提供给 Solr。

# 环境

- 操作系统：`CentOs6.5`
- Hadoop：`cdh5.3.0`

# 安装 Hadoop集群

这里使用参考 [通过Cloudera Manager安装CDH](/images/06/24/install-cdh-by-cloudera-manager.html)一文搭建的集群，其中也包括了一个三节点的 ZooKeeper 集群。该集群包括三个节点：

~~~
	192.168.56.121        cdh1     NameNode、Hive、ResourceManager、HBase
	192.168.56.122        cdh2     DataNode、SSNameNode、NodeManager、HBase
	192.168.56.123        cdh3     DataNode、HBase、NodeManager
~~~

# 安装 ZooKeeper

Zookeeper 的安装过程，请参考 [使用yum安装CDH Hadoop集群](/images/04/06/install-cloudera-cdh-by-yum.html)。

# 安装 Solr

Zookeeper 启动之后，需要安装 Solr，关于 Solr 的安装，可以参考 [Apache SolrCloud安装](/2014/03/10/how-to-install-solrcloud.html)。

在三个节点上安装 solr-server：

~~~
$ sudo yum install solr-server solr solr-doc -y
~~~

安装 Spark Indexer：

~~~bash
$ sudo yum install solr-crunch
~~~

安装 MapReduce Tools：

~~~bash
$ sudo yum install solr-mapreduce
~~~

安装 Lily HBase Indexer：

~~~bash
$ sudo yum install hbase-solr-indexer hbase-solr-doc
~~~

> 注意：Lily HBase Indexer和 cdh5 工作的时候，你需要在运行 MapReduce 任务之前运行下面命令：
> `export HADOOP_CLASSPATH=<Path to hbase-protocol-**.jar>`


# 配置 Solr

修改 solr 配置文件 `/etc/default/solr` 中 ZooKeeper 连接地址：

~~~
SOLR_ZK_ENSEMBLE=cdh1:2181,cdh2:2181,cdh3:2181/solr
~~~

修改 solr 配置文件 `/etc/default/solr` 中 HDFS 连接地址：

~~~
SOLR_HDFS_HOME=hdfs://cdh1:8020/solr
~~~

设置 HDFS 配置文件目录：

~~~properties
SOLR_HDFS_CONFIG=/etc/hadoop/conf
~~~

如果你配置了 Kerberos，则在 kerberos 服务器上为每个安装 solr 的节点先生成 solr 的凭证：

~~~bash
kadmin:  addprinc -randkey solr/cdh1@JAVACHEN.COM
kadmin:  xst -norandkey -k solr.keytab solr/cdh1

kadmin:  addprinc -randkey solr/cdh2@JAVACHEN.COM
kadmin:  xst -norandkey -k solr.keytab solr/cdh2

kadmin:  addprinc -randkey solr/cdh3@JAVACHEN.COM
kadmin:  xst -norandkey -k solr.keytab solr/cdh3
~~~

然后，将 solr.keytab 拷贝到 /etc/solr/conf：

~~~bash
$ sudo mv solr.keytab /etc/solr/conf/

$ sudo chown solr:hadoop /etc/solr/conf/solr.keytab
$ sudo chmod 400 /etc/solr/conf/solr.keytab
~~~

最后，修改每个安装了 solr 节点的 /etc/default/solr，例如在 cdh1节点上修改为：

~~~properties
SOLR_KERBEROS_ENABLED=true
SOLR_KERBEROS_KEYTAB=/etc/solr/conf/solr.keytab
SOLR_KERBEROS_PRINCIPAL=solr/cdh1@JAVACHEN.COM
~~~

在 HDFS 中创建 `/solr` 目录：

~~~
$ sudo -u hdfs hadoop fs -mkdir /solr
$ sudo -u hdfs hadoop fs -chown solr /solr
~~~

如果开启了 kerberos，则先获取 hdfs 服务的凭证在运行：

~~~bash
$ kinit -k -t /etc/hadoop/conf/hdfs.keytab hdfs/cdh1@JAVACHEN.com

$ hadoop fs -mkdir /solr
$ hadoop fs -chown solr /solr
~~~

集成 Sentry，取消 /etc/default/solr 下面注释：

~~~properties
# SOLR_AUTHORIZATION_SENTRY_SITE=/etc/solr/conf/sentry-site.xml
# SOLR_AUTHORIZATION_SUPERUSER=solr
~~~

集成 Hue，取消 /etc/default/solr 下面注释：

~~~properties
# SOLR_SECURITY_ALLOWED_PROXYUSERS=hue
# SOLR_SECURITY_PROXYUSER_hue_HOSTS=*
# SOLR_SECURITY_PROXYUSER_hue_GROUPS=*
~~~

初始化 ZooKeeper Namespace：

~~~
$ solrctl init
~~~

> 注意：你可以添加 `--force` 参数强制清空 ZooKeeper 数据，清空之前，请先停止 ZooKeeper 集群。

# 启动 Solr

在每一个安装了 Solr server 的节点上运行：

~~~bash
$ sudo service solr-server restart
~~~

通过下面命令查看 Solr 是否启动成功：

~~~
$ jps -lm
28053 org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer
31710 org.apache.zookeeper.server.quorum.QuorumPeerMain /etc/zookeeper/conf/zoo.cfg
14479 org.apache.catalina.startup.Bootstrap start
29994 org.apache.hadoop.hdfs.server.namenode.SecondaryNameNode
29739 org.apache.hadoop.yarn.server.resourcemanager.ResourceManager
27298 org.apache.catalina.startup.Bootstrap httpfs start
30123 org.apache.hadoop.hdfs.server.namenode.NameNode
21761 sun.tools.jps.Jps -lm
~~~

上面用到了 solrctl 命令，该命令用来管理 SolrCloud 的部署和配置，其语法如下：

~~~
solrctl [options] command [command-arg] [command [command-arg]] ...
~~~

可选参数有：

 - `--solr`：指定 SolrCloud 的 web API，如果在 SolrCloud 集群之外的节点运行命令，就需要指定该参数。
 - `--zk`：指定 zk 集群地址。
 - `--help`：打印帮助信息。
 - `--quiet`：静默模式运行。

command 命令有：

 - `init [--force]`：初始化配置。
 - `instancedir`：维护实体目录。可选的参数有：
   - `--generate path`
   - `--create name path`
   - `--update name path`
   - `--get name path`
   - `--delete name`
   - `--list`
 - `collection`：维护 collections。可选的参数有：
   - `--create name -s <numShards> [-c <collection.configName>] [-r <replicationFactor>] [-m <maxShardsPerNode>] [-n <createNodeSet>]]`
   - `--delete name`: Deletes a collection.
   - `--reload name`: Reloads a collection.
   - `--stat name`: Outputs SolrCloud specific run-time information for a collection.
   - ``--list`: Lists all collections registered in SolrCloud.
   - `--deletedocs name`: Purges all indexed documents from a collection.
 - `core`：维护 cores。可选的参数有：
   - `--create name [-p name=value]...]`
   - `--reload name`: Reloads a core.
   - `--unload name`: Unloads a core.
   - `--status name`: Prints status of a core.
 - `cluster`：维护集群配置信息。可选的参数有：
   - `--get-solrxml file`
   - `--put-solrxml file`

# 创建 Solr 运行时配置

在一个节点上（例如 cdh1）生成配置文件：

~~~
$ solrctl instancedir --generate $HOME/solr_configs
~~~

> 注意：你可以在 `/var/lib/solr` 创建目录，维护配置文件。

执行完之后，你可以修改 $HOME/solr_configs/conf 目录下的配置文件，其目录下文件如下。

~~~
$ ll ~/solr_configs/conf/
total 348
-rw-r--r-- 1 root root  1092 Jun  2 23:10 admin-extra.html
-rw-r--r-- 1 root root   953 Jun  2 23:10 admin-extra.menu-bottom.html
-rw-r--r-- 1 root root   951 Jun  2 23:10 admin-extra.menu-top.html
-rw-r--r-- 1 root root  4041 Jun  2 23:10 currency.xml
-rw-r--r-- 1 root root  1386 Jun  2 23:10 elevate.xml
drwxr-xr-x 2 root root  4096 Jun  2 23:10 lang
-rw-r--r-- 1 root root 82327 Jun  2 23:10 mapping-FoldToASCII.txt
-rw-r--r-- 1 root root  3114 Jun  2 23:10 mapping-ISOLatin1Accent.txt
-rw-r--r-- 1 root root   894 Jun  2 23:10 protwords.txt
-rw-r--r-- 1 root root 59635 Jun  2 23:10 schema.xml
-rw-r--r-- 1 root root   921 Jun  2 23:10 scripts.conf
-rw-r--r-- 1 root root 72219 Jun  2 23:10 solrconfig.xml
-rw-r--r-- 1 root root 73608 Jun  2 23:10 solrconfig.xml.secure
-rw-r--r-- 1 root root    16 Jun  2 23:10 spellings.txt
-rw-r--r-- 1 root root   795 Jun  2 23:10 stopwords.txt
-rw-r--r-- 1 root root  1148 Jun  2 23:10 synonyms.txt
-rw-r--r-- 1 root root  1469 Jun  2 23:10 update-script.js
drwxr-xr-x 2 root root  4096 Jun  2 23:10 velocity
drwxr-xr-x 2 root root  4096 Jun  2 23:10 xslt
~~~

创建 collection1 实例并将配置文件上传到 zookeeper：

~~~
$ solrctl instancedir --create collection1 $HOME/solr_configs
~~~

你可以通过下面命令查看上传的 instance：

~~~
$ solrctl instancedir --list
~~~

上传到 zookeeper 之后，其他节点就可以从上面下载配置文件。

接下来，还是在 cdh1 节点上创建 collection，因为我的 SolrCloud 集群有三个节点，故这里分片数设为3，并设置副本为1，如果有更多节点，可以将副本设置为更大的一个数：

~~~
$ solrctl collection --create collection1 -s 3 -r 1
~~~

运行成功之后，你可以通过 <http://cdh1:8983/solr/#/~cloud>、<http://cdh2:8983/solr/#/~cloud>、<http://cdh3:8983/solr/#/~cloud> 查看创建的分片。从网页上可以看到，已经自动创建了三个分片，并且三个分片分布在3个节点之上。

# 配置 hbase-solr-indexer

1）开启 HBase replication

Lily HBase Indexer 的实现依赖于 HBase的replication，故需要开启复制。将 `/usr/share/doc/hbase-solr-doc*/demo/hbase-site.xml`文件的内容拷贝到 `hbase-site.xml`，**注意**：删除掉 `replication.replicationsource.implementation` 参数配置。

2）将 hbase-solr-indexer 服务指向 hbase 集群

修改 `/etc/hbase-solr/conf/hbase-indexer-site.xml`，添加如下参数，其值和 `hbase-site.xml` 中的 `hbase.zookeeper.quorum` 属性值保持一致（注意添加上端口）：

~~~xml
<property>
   <name>hbaseindexer.zookeeper.connectstring</name>
   <value>cdh1:2181,cdh2:2181,cdh3:2181</value>
</property> 
~~~

最后再重启服务：

~~~
$ sudo service hbase-solr-indexer restart
~~~

# 总结

本文内容主要介绍了如何不使用 Cloudera Manager 来安装 Cloudera Search，下篇文章将介绍如何使用 Cloudera Search。

# 参考资料

- [1] [Cloudera Search: 轻松实现Hadoop全文检索 ](http://blog.sina.com.cn/s/blog_9bf980ad010182ph.html)
- [2] [Cloudera-Search-User-Guide](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Search/latest/Cloudera-Search-User-Guide/Cloudera-Search-User-Guide.html)
