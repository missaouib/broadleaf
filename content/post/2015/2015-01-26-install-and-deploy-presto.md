---
layout: post

title: 安装和部署Presto
date: 2015-01-26T08:00:00+08:00

categories: [ hadoop ]

tags: [ hadoop,presto ]

description: 本文主要记录 Presto 的安装部署过程，并使用 hive-cdh5 连接器进行简单测试。

published: true

---

# 1. 安装环境

- 操作系统：CentOs6.5
- Hadoop 集群：CDH5.3
- JDK 版本：jdk1.8.0_31

为了测试简单，我是将 Presto 的 coordinator 和 worker 都部署在 `cdh1` 节点上，并且该节点上部署了 hive-metastore 服务。下面的安装和部署过程参考自 <http://prestodb.io/docs/current/installation.html>。

# 2. 安装 Presto

下载 Presto 的压缩包，目前最新版本为 [presto-server-0.90](https://repo1.maven.org/maven2/com/facebook/presto/presto-server/0.90/presto-server-0.90.tar.gz)，然后解压为 presto-server-0.90 。

~~~
wget https://repo1.maven.org/maven2/com/facebook/presto/presto-server/0.90/presto-server-0.90.tar.gz
tar zxvf presto-server-0.90.tar.gz
~~~

解压后的目录结构为：

~~~
[$ presto-server-0.90]# tree -L 2
.
├── bin
│   ├── launcher
│   ├── launcher.properties
│   ├── launcher.py
│   └── procname
├── lib
├── NOTICE
├── plugin
│   ├── cassandra
│   ├── example-http
│   ├── hive-cdh4
│   ├── hive-cdh5
│   ├── hive-hadoop1
│   ├── hive-hadoop2
│   ├── kafka
│   ├── ml
│   ├── mysql
│   ├── postgresql
│   ├── raptor
│   └── tpch
└── README.txt
~~~

从 plugin 目录可以看到所有 Presto 支持的插件有哪些，这里我主要使用 hive-cdh5 插件，也成为连接器。

# 3. 配置 Presto

在 presto-server-0.90 目录创建 etc 目录，并创建以下文件：

- `node.properties`：每个节点的环境配置
- `jvm.config`：jvm 参数
- `config.properties`：配置 Presto Server 参数
- `log.properties`：配置日志等级
- `Catalog Properties`：Catalog 的配置

`etc/node.properties` 示例配置如下：

~~~properties
node.environment=production
node.id=ffffffff-ffff-ffff-ffff-ffffffffffff
node.data-dir=/var/presto/data
~~~

参数说明：

- `node.environment`：环境名称。一个集群节点中的所有节点的名称应该保持一致。
- `node.id`：节点唯一标识的名称。
- `node.data-dir`：数据和日志存放路径。

`etc/jvm.config` 示例配置如下：

~~~sql
-server
-Xmx16G
-XX:+UseConcMarkSweepGC
-XX:+ExplicitGCInvokesConcurrent
-XX:+CMSClassUnloadingEnabled
-XX:+AggressiveOpts
-XX:+HeapDumpOnOutOfMemoryError
-XX:OnOutOfMemoryError=kill -9 %p
-XX:ReservedCodeCacheSize=150M
~~~

`etc/config.properties` 包含 Presto Server 相关的配置，每一个 Presto Server 可以通时作为 coordinator 和 worker 使用。你可以将他们配置在一个极点上，但是，在一个大的集群上建议分开配置以提高性能。

coordinator 的最小配置：

~~~properties
coordinator=true
node-scheduler.include-coordinator=false
http-server.http.port=8080
task.max-memory=1GB
discovery-server.enabled=true
discovery.uri=http://cdh1:8080
~~~

worker 的最小配置：

~~~properties
coordinator=false
http-server.http.port=8080
task.max-memory=1GB
discovery.uri=http://cdh1:8080
~~~

可选的，作为测试，你可以在一个节点上同时配置两者：

~~~properties
coordinator=true
node-scheduler.include-coordinator=true
http-server.http.port=8080
task.max-memory=1GB
discovery-server.enabled=true
discovery.uri=http://cdh1:8080
~~~

参数说明：

- `coordinator`：Presto 实例是否以 coordinator 对外提供服务
- `node-scheduler.include-coordinator`：是否允许在 coordinator 上进行调度任务
- `http-server.http.port`：HTTP 服务的端口
- `task.max-memory=1GB`：每一个任务（对应一个节点上的一个查询计划）所能使用的最大内存
- `discovery-server.enabled`：是否使用 Discovery service 发现集群中的每一个节点。
- `discovery.uri`：Discovery server 的 url


`etc/log.properties` 可以设置某一个 java 包的日志等级：

~~~properties
com.facebook.presto=INFO
~~~

关于 Catalog 的配置，首先需要创建 etc/catalog 目录，然后根据你想使用的连接器来创建对应的配置文件，比如，你想使用 jmx 连接器，则创建 jmx.properties：

~~~properties
connector.name=jmx
~~~

如果你想使用 hive 的连接器，则创建 hive.properties：

~~~properties
connector.name=hive-cdh5
hive.metastore.uri=thrift://cdh1:9083  #修改为 hive-metastore 服务所在的主机名称，这里我是安装在 cdh1节点
hive.config.resources=/etc/hadoop/conf/core-site.xml,/etc/hadoop/conf/hdfs-site.xml
~~~

更多关于连接器的说明，请参考 [Connectors ](http://prestodb.io/docs/current/connector.html)。

# 4. 运行 Presto

你可以使用下面命令后台启动：

~~~
bin/launcher start
~~~

也可以前台启动，观察输出日志：

~~~
bin/launcher run
~~~

另外，你也可以通过下面命令停止：

~~~
bin/launcher stop
~~~

更多命令，你可以通过 `--help` 参数来查看。

~~~bash
[root@cdh1 presto-server-0.90]# bin/launcher --help
Usage: launcher [options] command

Commands: run, start, stop, restart, kill, status

Options:
  -h, --help            show this help message and exit
  -v, --verbose         Run verbosely
  --launcher-config=FILE
                        Defaults to INSTALL_PATH/bin/launcher.properties
  --node-config=FILE    Defaults to INSTALL_PATH/etc/node.properties
  --jvm-config=FILE     Defaults to INSTALL_PATH/etc/jvm.config
  --config=FILE         Defaults to INSTALL_PATH/etc/config.properties
  --log-levels-file=FILE
                        Defaults to INSTALL_PATH/etc/log.properties
  --data-dir=DIR        Defaults to INSTALL_PATH
  --pid-file=FILE       Defaults to DATA_DIR/var/run/launcher.pid
  --launcher-log-file=FILE
                        Defaults to DATA_DIR/var/log/launcher.log (only in daemon mode)
  --server-log-file=FILE
                        Defaults to DATA_DIR/var/log/server.log (only in daemon mode)
  -D NAME=VALUE         Set a Java system property
~~~ 

启动之后，你可以观察 /var/presto/data/ 目录：

~~~
[root@cdh1 /var/presto/data/]# tree
.
├── etc -> /opt/presto-server-0.90/etc
├── plugin -> /opt/presto-server-0.90/plugin
└── var
    ├── log
    │   ├── http-request.log
    │   ├── launcher.log
    │   └── server.log
    └── run
        └── launcher.pid

5 directories, 4 files
~~~

在 /var/presto/data/var/log 目录可以查看日志：

- `launcher.log`：启动日志
- `server.log`：Presto Server 输出日志
- `http-request.log`：HTTP 请求日志

# 5. 测试 Presto CLI 

下载 [presto-cli-0.90-executable.jar](https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/0.90/presto-cli-0.90-executable.jar) 并将其重命名为 presto-cli（你也可以重命名为 presto），然后添加执行权限。

运行下面命令进行测试：

~~~bash
[root@cdh1 bin]# ./presto-cli --server localhost:8080 --catalog hive --schema default
presto:default> show tables;
 Table
-------
(0 rows)

Query 20150126_062137_00012_qgwvy, FINISHED, 1 node
Splits: 2 total, 2 done (100.00%)
0:00 [0 rows, 0B] [0 rows/s, 0B/s]
~~~

在 执行 show tables 命令之前，你可以查看 <http://cdh1:8080/> 页面：

![](/images/presto-web-01.jpg)

然后在执行该命令之后再观察页面变化。单击第一行记录，会跳转到明细页面：

![](/images/presto-web-02.jpg)

可以运行 `--help` 命令查看更多参数，例如你可以在命令行直接运行下面命令：

~~~
./presto-cli --server localhost:8080 --catalog hive --schema default --execute "show tables;"
~~~

默认情况下，Presto 的查询结果是使用 `less` 程序分页输出的，你可以通过修改环境变量 `PRESTO_PAGER` 的值将其改为其他命令，如 `more`，或者将其置为空以禁止分页输出。

# 6. 测试 jdbc

使用 jdbc 连接 Presto，需要下载 jdbc 驱动 [presto-jdbc-0.90](https://repo1.maven.org/maven2/com/facebook/presto/presto-jdbc/0.90/presto-jdbc-0.90.jar) 并将其加到你的应用程序的 classpath 中。

支持以下几种 JDBC URL 格式：

~~~
jdbc:presto://host:port
jdbc:presto://host:port/catalog
jdbc:presto://host:port/catalog/schema
~~~

连接 hive 数据库中 sales 库，示例如下：

~~~
jdbc:presto://cdh1:8080/hive/sales
~~~

# 7. 总结

本文主要记录 Presto 的安装部署过程，并使用 hive-cdh5 连接器进行简单测试。下一步，需要基于一些生产数据做一些功能测试以及和 impala 做一些对比测试。
