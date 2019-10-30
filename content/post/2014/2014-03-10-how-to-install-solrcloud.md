---
layout: post
title: Apache SolrCloud安装
date: 2014-03-10T08:00:00+08:00
description: 本文基于Solr最新的4.4.0版本进行安装配置SolrCloud集群。SolrCloud通过ZooKeeper集群来进行协调，使一个索引进行分片，各个分片可以分布在不同的物理节点上，多个物理分片组成一个完成的索引Collection。SolrCloud自动支持Solr Replication，可以同时对分片进行复制，冗余存储。
categories: [ search-engine ]
tags: [solr,solrcloud]
---

SolrCloud 通过 ZooKeeper 集群来进行协调，使一个索引进行分片，各个分片可以分布在不同的物理节点上，多个物理分片组成一个完成的索引 Collection。SolrCloud 自动支持 Solr Replication，可以同时对分片进行复制，冗余存储。下面，我们基于 Solr 最新的 4.4.0 版本进行安装配置 SolrCloud 集群。

# 1. 安装环境

我使用的安装程序各版本如下：

- Solr： [Apache Solr-4.4.0](http://archive.apache.org/dist/lucene/solr/4.4.0/)
- Tomcat： [Apache Tomcat 6.0.36](http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.36/)
- ZooKeeper： [Apache ZooKeeper 3.4.5](http://www.apache.org/dyn/closer.cgi/zookeeper/)

各个目录说明：

- 所有的程序安装在 `/opt` 目录下，你可以依照你的实际情况下修改安装目录。
- ZooKeeper的数据目录在： `/data/zookeeper/data`
- solrhome设置在： `/usr/local/solrhome`

# 2. 规划SolrCloud

- 单一SolrCloud数据集合： primary
- ZooKeeper集群： 3台
- SolrCloud实例： 3节点
- 索引分片： 3
- 复制因子： 2

手动将3个索引分片(Shard)的复本(Replica)分布在3个 SolrCloud 节点上

三个节点：

- 192.168.56.121
- 192.168.56.122
- 192.168.56.123

# 3. 安装ZooKeeper集群

由于需要用到 ZooKeeper，故我们先安装好 ZooKeeper 集群。

安装 ZooKeeper 集群之前，请确保每台机器上配置 `/etc/hosts`文件，使每个节点都能通过机器名访问。

首先，在第一个节点上将 zookeeper-3.4.5.tar.gz 解压到 `/opt` 目录：

~~~
$ tar zxvf zookeeper-3.4.5.tar.gz -C /opt/
~~~

创建 ZooKeeper 配置文件 zookeeper-3.4.5/conf/zoo.cfg，内容如下：

~~~properties
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/zookeeper/data
clientPort=2181
server.1=192.168.56.121:2888:3888
server.2=192.168.56.122:2888:3888
server.3=192.168.56.123:2888:3888
~~~

ZooKeeper 的数据目录指定在 `/data/zookeeper/data` ，你也可以使用其他目录，通过下面命令进行创建该目录：

~~~bash
$ mkdir /data/zookeeper/data -p
~~~

然后，初始化 myid ，三个节点编号依次为 `1，2，3` ，在其余节点上分别执行命令（注意修改编号）。

~~~bash
$ echo "1" >/data/zookeeper/data/myid
~~~

然后，在第二个和第三个节点上依次重复上面的操作。这样第一个节点中 myid 内容为1，第二个节点为2，第三个节点为3。

最后，启动 ZooKeeper 集群，在每个节点上分别启动 ZooKeeper 服务：

~~~bash
$ cd /opt
$ sh zookeeper-3.4.5/bin/zkServer.sh start
~~~

可以查看 ZooKeeper 集群的状态，保证集群启动没有问题：

~~~bash
[root@192.168.56.121 opt]# sh zookeeper-3.4.5/bin/zkServer.sh status
JMX enabled by default
Using config: /opt/zookeeper-3.4.5/bin/../conf/zoo.cfg
Mode: follower
~~~

# 4. 安装Solr

你可以参考[《Apache Solr介绍及安装》](/images/02/26/how-to-install-solr.html)

简单来说，执行以下命令：

~~~bash
$ unzip apache-tomcat-6.0.36.zip  -d /opt
$ unzip solr-4.4.0.zip  -d /opt

$ cd /opt
$ chmod +x apache-tomcat-6.0.36/bin/*.sh

$ cp solr-4.4.0/example/webapps/solr.war apache-tomcat-6.0.36/webapps/
$ cp solr-4.4.0/example/lib/ext/* apache-tomcat-6.0.36/webapps/solr/WEB-INF/lib/
$ cp solr-4.4.0/example/resources/log4j.properties apache-tomcat-6.0.36/lib/
~~~

在其他节点上重复以上操作完成所有节点的 solr 的安装。

# 5. 设置 SolrCloud 配置文件

1、 创建一个 SolrCloud 目录，并将 solr 的 lib 文件拷贝到这个目录：

~~~bash
$ mkdir -p /usr/local/solrcloud/solr-lib/
$ cp apache-tomcat-6.0.36/webapps/solr/WEB-INF/lib/* /usr/local/solrcloud/solr-lib/
~~~

2、 通过 bootstrap 设置 solrhome ：

这里设置 solrhome 为 /usr/local/solrhome，创建该目录：

~~~bash
mkdir -p /usr/local/solrhome 
~~~

然后，运行下面命令将 solrhome 下面的配置上传到 zookeeper：

~~~bash
$ java -classpath .:/usr/local/solrcloud/solr-lib/* org.apache.solr.cloud.ZkCLI -zkhost 192.168.56.121:2181,192.168.56.122:2181,192.168.56.123:2181 -cmd bootstrap -solrhome 
~~~

SolrCloud 集群的所有的配置存储在 ZooKeeper。 一旦 SolrCloud 节点启动时配置了 `-Dbootstrap_confdir` 参数， 该节点的配置信息将发送到 ZooKeeper 上存储。基它节点启动时会应用 ZooKeeper 上的配置信息，这样当我们改动配置时就不用一个个机子去更改了。

3、SolrCloud 是通过 ZooKeeper 集群来保证配置文件的变更及时同步到各个节点上，所以，需要将我们自己的配置文件（在 /usr/local/solrcloud/conf/primary/conf 目录下）上传到 ZooKeeper 集群中，配置名称设为 primaryconf：

~~~bash
$ java -classpath .:/usr/local/solrcloud/solr-lib/* org.apache.solr.cloud.ZkCLI -zkhost 192.168.56.121:2181,192.168.56.122:2181,192.168.56.123:2181 -cmd upconfig -confdir /usr/local/solrcloud/conf/primary/conf -confname primaryconf
~~~

说明：

- `zkhost` 指定 ZooKeeper 地址，逗号分割
- `/usr/local/solrcloud/conf/` 目录下存在名称为 primary 的目录，该目录下的配置是后面需要用到的。
- `primaryconf` 为在 ZooKeeper 上的配置文件名称。

/usr/local/solrcloud/conf 结构如下：

~~~bash
$ tree /usr/local/solrcloud/conf
/usr/local/solrcloud/conf
├── primary
│   └── conf
│       ├── schema.xml
│       └── solrconfig.xml
└── solr.xml

2 directories, 3 files
~~~

schema.xml 内容如下：

~~~xml
<?xml version="1.0" encoding="UTF-8" ?>
<schema name="example" version="1.5">
    <fields>
        <field name="namespace" type="string" indexed="true" stored="true" />
        <field name="id" type="string" indexed="true" stored="true" />
        <field name="productId" type="long" indexed="true" stored="true" />
        <field name="category" type="long" indexed="true" stored="true" multiValued="true" />
        <field name="explicitCategory" type="long" indexed="true" stored="true" multiValued="true" />
        <field name="searchable" type="text_general" indexed="true" stored="false" />
        <field name="_version_" type="long" indexed="true" stored="true" multiValued="false"/>
        <dynamicField name="*_searchable" type="text_general" indexed="true" stored="true" />

        <dynamicField name="*_i" type="int" indexed="true" stored="true" />
        <dynamicField name="*_is" type="int" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_s" type="string" indexed="true" stored="true" />
        <dynamicField name="*_ss" type="string" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_l" type="long" indexed="true" stored="true" />
        <dynamicField name="*_ls" type="long" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_t" type="text_general" indexed="true" stored="true" />
        <dynamicField name="*_txt" type="text_general" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_b" type="boolean" indexed="true" stored="true" />
        <dynamicField name="*_bs" type="boolean" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_d" type="double" indexed="true" stored="true" />
        <dynamicField name="*_ds" type="double" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_p" type="double" indexed="true" stored="true" />

        <dynamicField name="*_dt" type="date" indexed="true" stored="true" />
        <dynamicField name="*_dts" type="date" indexed="true" stored="true" multiValued="true" />

        <!-- some trie-coded dynamic fields for faster range queries -->
        <dynamicField name="*_ti" type="tint" indexed="true" stored="true" />
        <dynamicField name="*_tl" type="tlong" indexed="true" stored="true" />
        <dynamicField name="*_td" type="tdouble" indexed="true" stored="true" />
        <dynamicField name="*_tdt" type="tdate" indexed="true" stored="true" />
    </fields>

    <uniqueKey>id</uniqueKey>

    <types>
        <fieldType name="string" class="solr.StrField" sortMissingLast="true" />
        <fieldType name="boolean" class="solr.BoolField" sortMissingLast="true" />

        <fieldType name="int" class="solr.TrieIntField" precisionStep="0" positionIncrementGap="0" />
        <fieldType name="long" class="solr.TrieLongField" precisionStep="0" positionIncrementGap="0" />
        <fieldType name="double" class="solr.TrieDoubleField" precisionStep="0" positionIncrementGap="0" />
        <fieldType name="tint" class="solr.TrieIntField" precisionStep="8" positionIncrementGap="0" />
        <fieldType name="tlong" class="solr.TrieLongField" precisionStep="8" positionIncrementGap="0" />
        <fieldType name="tdouble" class="solr.TrieDoubleField" precisionStep="8" positionIncrementGap="0" />

        <fieldType name="date" class="solr.TrieDateField" precisionStep="0" positionIncrementGap="0" />
        <!-- A Trie based date field for faster date range queries and date faceting. -->
        <fieldType name="tdate" class="solr.TrieDateField" precisionStep="6" positionIncrementGap="0" />

        <fieldType name="text_general" class="solr.TextField" positionIncrementGap="100">
            <analyzer type="index">
                <tokenizer class="solr.StandardTokenizerFactory" />
                <filter class="solr.LowerCaseFilterFactory" />
            </analyzer>
            <analyzer type="query">
                <tokenizer class="solr.StandardTokenizerFactory" />
                <filter class="solr.LowerCaseFilterFactory" />
            </analyzer>
        </fieldType>

    </types>
</schema>
~~~

solrconfig.xml 内容如下：

~~~xml
<?xml version="1.0" encoding="UTF-8" ?>
<config>
  <luceneMatchVersion>4.4</luceneMatchVersion>
  <directoryFactory name="DirectoryFactory" class="${solr.directoryFactory:solr.StandardDirectoryFactory}"/>

  <schemaFactory class="ClassicIndexSchemaFactory"/>

  <updateHandler class="solr.DirectUpdateHandler2">
    <updateLog>
            <str name="dir">${solr.data.dir:}</str>
        </updateLog>
  </updateHandler>

  <requestHandler name="/get" class="solr.RealTimeGetHandler">
    <lst name="defaults">
      <str name="omitHeader">true</str>
    </lst>
  </requestHandler>

  <requestHandler name="/replication" class="solr.ReplicationHandler" startup="lazy" />

  <requestDispatcher handleSelect="true" >
    <requestParsers enableRemoteStreaming="false" multipartUploadLimitInKB="2048" formdataUploadLimitInKB="2048" />
    <httpCaching never304="true" />
  </requestDispatcher>

  <requestHandler name="standard" class="solr.StandardRequestHandler" default="true" />
  <requestHandler name="/analysis/field" startup="lazy" class="solr.FieldAnalysisRequestHandler" />
  <requestHandler name="/update" class="solr.UpdateRequestHandler"  />
  <requestHandler name="/update/json" class="solr.JsonUpdateRequestHandler" startup="lazy" />
  <requestHandler name="/admin/" class="org.apache.solr.handler.admin.AdminHandlers" />

  <requestHandler name="/admin/ping" class="solr.PingRequestHandler">
    <lst name="invariants">
      <str name="q">solrpingquery</str>
    </lst>
    <lst name="defaults">
      <str name="echoParams">all</str>
      <str name="df">id</str>
    </lst>
  </requestHandler>

  <queryResponseWriter name="json" class="solr.JSONResponseWriter">
        <str name="content-type">text/plain; charset=UTF-8</str>
  </queryResponseWriter>

  <updateRequestProcessorChain name="sample">
     <processor class="solr.LogUpdateProcessorFactory" />
     <processor class="solr.DistributedUpdateProcessorFactory"/>
     <processor class="solr.RunUpdateProcessorFactory" />
  </updateRequestProcessorChain>

  <!-- config for the admin interface -->
  <admin>
    <defaultQuery>solr</defaultQuery>
    <pingQuery>q=solr&amp;version=2.0&amp;start=0&amp;rows=0</pingQuery>
    <healthcheck type="file">server-enabled</healthcheck>
  </admin>

</config>
~~~

4、创建 collection 并和配置文件关联：

~~~bash
$ java -classpath .:/usr/local/solrcloud/solr-lib/* org.apache.solr.cloud.ZkCLI -zkhost 192.168.56.121:2181,192.168.56.122:2181,192.168.56.123:2181 -cmd linkconfig -collection primary -confname primaryconf
~~~

说明：

- 创建的 collection 叫做 primary，并指定和 primaryconf 连接

5、查看 ZooKeeper 上状态

在任意一个节点的 /opt 目录下执行如下命令：

~~~bash
$  zookeeper-3.4.5/bin/zkCli.sh 

[zk: localhost:2181(CONNECTED) 0] ls /
[configs,zookeeper,clusterstate.json,aliases.json,live_nodes,overseer,collections,overseer_elect]

[zk: localhost:2181(CONNECTED) 1] ls /configs
[primaryconf,]

[zk: localhost:2181(CONNECTED) 1] ls /collections
[primary]

~~~

查看 `/configs` 和 `/collections` 目录均有值，说明配置文件已经上传到 ZooKeeper 上了，接下来启动 solr。


# 6. Tomcat 配置与启动

1、修改每个节点上的 tomcat 配置文件，在环境变量中添加 `zkHost` 变量

编辑 `apache-tomcat-6.0.36/bin/catalina.sh` ，添加如下代码：

~~~bash
JAVA_OPTS='-Djetty.port=8080 -Dsolr.solr.home=/usr/local/solrhome -DzkHost=192.168.56.122:2181,192.168.56.122:2181,192.168.56.123:2181'
~~~

在 `/usr/local/solrhome/` 目录创建 solr.xml ：

~~~xml
<?xml version="1.0" encoding="UTF-8" ?>
<solr persistent="true" sharedLib="lib">
    <cores adminPath="/admin/cores" zkClientTimeout="${zkClientTimeout:15000}" hostPort="${jetty.port:8080}" hostContext="${hostContext:solr}"></cores>
</solr>
~~~

说明：

- `-Djetty.port`：配置 solr 使用的端口，默认为 8983，这里我们使用的是 tomcat，端口为 8080
- `-Dsolr.solr.home`：配置 solr/home
- `-zkHost`: 配置 zookeeper 集群地址，多个地址逗号分隔

最后，在 /opt 目录下启动 tomcat：

~~~bash
$ sh apache-tomcat-6.0.36/bin/startup.sh
~~~

通过 <http://192.168.56.121:8080/solr/> 进行访问，界面如图提示 `There are no SolrCores running. `，这是因为配置文件尚未配置 solrcore。

![There are no SolrCores running](/images/solr-no-solrcores.png)

# 7. 创建 Collection、Shard 和 Replication

## 手动创建 Collection 及初始 Shard

直接通过 REST 接口来创建 Collection，你也可以通过浏览器访问下面地址，如下所示：

~~~bash
$ curl 'http://192.168.56.121:8080/solr/admin/collections?action=CREATE&name=primary&numShards=3&replicationFactor=1'
~~~

如果成功，会输出如下响应内容：

~~~xml
<response>
<lst name="responseHeader">
	<int name="status">0</int>
	<int name="QTime">2649</int>
</lst>
<lst name="success">
	<lst>
		<lst name="responseHeader">
			<int name="status">0</int>
			<int name="QTime">2521</int>
		</lst>
		<str name="core">primary_shard2_replica1</str>
		<str name="saved">/usr/local/solrhome/solr.xml</str>
	</lst>
	<lst>
		<lst name="responseHeader">
			<int name="status">0</int>
			<int name="QTime">2561</int>
		</lst>
		<str name="core">primary_shard3_replica1</str>
		<str name="saved">/usr/local/solrhome/solr.xml</str>
	</lst>
	<lst>
		<lst name="responseHeader">
		<int name="status">0</int>
		<int name="QTime">2607</int>
		</lst>
		<str name="core">primary_shard1_replica1</str>
		<str name="saved">/usr/local/solrhome/solr.xml</str>
	</lst>
</lst>
</response>
~~~

上面链接中的几个参数的含义，说明如下：

- `name`：               待创建Collection的名称
- `numShards`：          分片的数量
- `replicationFactor`：   复制副本的数量

可以通过 Web 管理页面，访问 `http://192.168.56.121:8080/solr/#/~cloud`，查看 SolrCloud 集群的分片信息，如图所示:

![SolrCloud-collection-shard](/images/solrcloud-collection-shard.png)

实际上，我们从192.168.56.121节点可以看到，SOLR 的配置文件内容，已经发生了变化，如下所示：

~~~xml
<?xml version="1.0" encoding="UTF-8" ?>
<solr persistent="true" sharedLib="lib">
  <cores adminPath="/admin/cores" zkClientTimeout="20000" hostPort="${jetty.port:8080}" hostContext="${hostContext:solr}">
    <core shard="shard2" instanceDir="primary_shard2_replica1/" name="primary_shard2_replica1" collection="primary"/>
  </cores>
</solr>
~~~

同时，你还可以看另外两个节点上的 solr.xml 文件的变化。

## 手动创建 Replication

下面对已经创建的初始分片进行复制。 shard1 已经在 192.168.56.123 上，我们复制分片到 192.168.56.121 和 192.168.56.122 上，执行如下命令：

~~~bash
$ curl 'http://192.168.56.121:8080/solr/admin/cores?action=CREATE&collection=primary&name=primary_shard1_replica_2&shard=shard1'

$ curl 'http://192.168.56.122:8080/solr/admin/cores?action=CREATE&collection=primary&name=primary_shard1_replica_3&shard=shard1'
~~~

最后的结果是，192.168.56.123 上的 shard1，在 192.168.56.121 节点上有1个副本，名称为 `primary_shard1_replica_2` ，在 192.168.56.122 节点上有一个副本，名称为 `primary_shard1_replica_3` 。也可以通过查看 192.168.56.121 和 192.168.56.122 上的目录变化，如下所示：

~~~bash
$  ll /usr/local/solrhome/
total 16
drwxr-xr-x 3 root root 4096 Mar 10 17:11 primary_shard1_replica2
drwxr-xr-x 3 root root 4096 Mar 10 17:02 primary_shard2_replica1
-rw-r--r-- 1 root root  444 Mar 10 17:16 solr.xml
~~~

你还可以对 shard2 和 shard3 添加副本。shard2 已经在 192.168.56.121 上，我们复制分片到 192.168.56.122 和 192.168.56.123 上，执行如下命令：

~~~bash
$ curl 'http://192.168.56.122:8080/solr/admin/cores?action=CREATE&collection=primary&name=primary_shard2_replica_2&shard=shard2'
$ curl 'http://192.168.56.123:8080/solr/admin/cores?action=CREATE&collection=primary&name=primary_shard2_replica_3&shard=shard2'
~~~

shard3 已经在 192.168.56.122 上，我们复制分片到 192.168.56.121 和 192.168.56.123 上，执行如下命令：

~~~bash
$ curl 'http://192.168.56.121:8080/solr/admin/cores?action=CREATE&collection=primary&name=primary_shard3_replica_2&shard=shard3'
$ curl 'http://192.168.56.123:8080/solr/admin/cores?action=CREATE&collection=primary&name=primary_shard3_replica_3&shard=shard3'
~~~

我们再次从 192.168.56.121 节点可以看到，SOLR 的配置文件内容，又发生了变化，如下所示：

~~~xml
<?xml version="1.0" encoding="UTF-8" ?>
<solr persistent="true" sharedLib="lib">
  <cores adminPath="/admin/cores" zkClientTimeout="20000" hostPort="${jetty.port:8080}" hostContext="${hostContext:solr}">
    <core shard="shard1" instanceDir="primary_shard1_replica2/" name="primary_shard1_replica_2" collection="primary"/>
    <core shard="shard2" instanceDir="primary_shard2_replica1/" name="primary_shard2_replica_1" collection="primary"/>
    <core shard="shard3" instanceDir="primary_shard2_replica2/" name="primary_shard2_replica_2" collection="primary"/>
  </cores>
</solr>
~~~

到此为止，我们已经基于3个节点，配置完成了 SolrCloud 集群。最后效果如下：

![solrcloud-collection-shard-replica](/images/solrcloud-collection-shard-replica.png)


# 8. 其他说明

## 8.1 SolrCloud 的一些必要配置

### schema.xml

必须定义 `_version_` 字段：

~~~xml
<field name="_version_" type="long" indexed="true" stored="true" multiValued="false"/>
~~~

### solrconfig.xml

updateHandler 节点下需要定义 updateLog：

~~~xml
    <!-- Enables a transaction log， currently used for real-time get.
         "dir" - the target directory for transaction logs， defaults to the
         solr data directory.  -->
    <updateLog>
      <str name="dir">${solr.data.dir:}</str>
      <!-- if you want to take control of the synchronization you may specify the syncLevel as one of the
           following where ''flush'' is the default. fsync will reduce throughput.
      <str name="syncLevel">flush|fsync|none</str>
      -->
    </updateLog>
~~~

需要定义一个 `replication handler`，名称为 `/replication` ：

~~~xml
<requestHandler name="/replication" class="solr.ReplicationHandler" startup="lazy" />
~~~

需要定义一个 `realtime get handler`，名称为`/get`:

~~~xml
	<requestHandler name="/get" class="solr.RealTimeGetHandler">
      <lst name="defaults">
        <str name="omitHeader">true</str>
     </lst>
    </requestHandler>
~~~

需要定义 `admin handlers`：

~~~
<requestHandler name="/admin/" class="solr.admin.AdminHandlers" />
~~~

需要定义 `updateRequestProcessorChain`：

~~~xml
 <updateRequestProcessorChain name="sample">
     <processor class="solr.LogUpdateProcessorFactory" />
     <processor class="solr.DistributedUpdateProcessorFactory"/>
     <processor class="solr.RunUpdateProcessorFactory" />
   </updateRequestProcessorChain>
~~~

### solr.xml

cores 节点需要定义 `adminPath` 属性：

~~~xml
<cores adminPath="/admin/cores" >
~~~

## 8.2 SolrCloud 分布式检索时忽略宕机的 Shard

~~~xml
<lst name=”error”>
	<str name=”msg”>no servers hosting shard:</str>
	<int name=”code”>503</int>
</lst>
~~~

加入下面参数，只从存活的 shards 获取数据：

~~~properties
shards.tolerant=true 
~~~

如：`http://192.168.56.121:8080/solr/primary_shard2_replica1/select?q=*%3A*&wt=xml&indent=true&shards.tolerant=true`
 
没有打此参数，如果集群内有挂掉的 shard，将显示：

~~~
no servers hosting shard
~~~

## 8.3 自动创建 Collection 及初始 Shard

自动创建 Collection 及初始 Shard，不需要通过 zookeeper 手动上传配置文件并关联 collection。

1、在第一个节点修改 tomcat 启动参数

~~~
JAVA_OPTS='-Djetty.port=8080 -Dsolr.solr.home=/usr/local/solrhome -DzkHost=192.168.56.122:2181,192.168.56.122:2181,192.168.56.123:2181 -DnumShards=3 -Dbootstrap_confdir=/usr/local/solrhome/primary/conf -Dcollection.configName=primaryconf '
~~~

然后启动 tomcat。这个步骤上传了集群的相关配置信息(`/usr/local/solrhome/primary/conf`)到 ZooKeeper 中去，所以启动下一个节点时不用再指定配置文件了。


2、在第二个和第三个节点修改 tomcat 启动参数

~~~
JAVA_OPTS='-Djetty.port=8080 -Dsolr.solr.home=/usr/local/solrhome -DzkHost=192.168.56.122:2181,192.168.56.122:2181,192.168.56.123:2181 -DnumShards=3'
~~~

然后启动 tomcat。


这样就会创建3个 shard 分别分布在三个节点上，如果你在增加一个节点，这节点会附加到一个 shard 上成为一个 replica，而不会创建新的 shard。

# 9. 总结

本文记录了如何 zookeeper、SolrCloud 的安装和配置过程，solrcore 是通过 restapi 进行手动创建，然后又对自动创建 Collection 及初始 Shard 进行了说明。

# 10. 参考文章

- [1] [SolrCloud 4.3.1+Tomcat 7安装配置实践](http://shiyanjun.cn/archives/100.html)
- [2] [SolrCloud Wiki](http://wiki.apache.org/solr/SolrCloud)
- [3] [SolrCloud使用教程、原理介绍](http://www.wxdl.cn/index/solrcloud.html)

