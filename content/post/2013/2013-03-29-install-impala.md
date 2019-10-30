---
layout: post
title: 使用yum源安装Impala过程
date: 2013-03-29T00:00:00+08:00
categories: [impala]
tags: [impala]
keywords: impala,cdh,hadoop,hive
---

与Hive类似，Impala也可以直接与HDFS和HBase库直接交互。只不过Hive和其它建立在MapReduce上的框架适合需要长时间运行的批处理任务。例如：那些批量提取，转化，加载（ETL）类型的Job，而Impala主要用于实时查询。

# 1. 环境

基于 [使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum) 这篇文章中的集群环境，进行impala的安装。

# 2. 安装

在管理节点 cdh1 上安装：

~~~bash
$ sudo yum install impala-server impala-state-store impala-catalog impala-shell -y
~~~

在 hive metastore 所在节点安装impala-state-store和impala-catalog

在datanode节点上安装：

~~~bash
$ sudo yum install impala-server impala-shell -y
~~~

# 3. 配置

## 3.1 修改配置文件

查看安装路径：

~~~bash
$ find / -name impala
	/var/run/impala
	/var/lib/alternatives/impala
	/var/log/impala
	/usr/lib/impala
	/etc/alternatives/impala
	/etc/default/impala
	/etc/impala
	/etc/default/impala
~~~

impalad的配置文件路径由环境变量`IMPALA_CONF_DIR`指定，默认为`/usr/lib/impala/conf`，impala 的默认配置在/etc/default/impala，修改该文件中的 `IMPALA_CATALOG_SERVICE_HOST` 和 `IMPALA_STATE_STORE_HOST`

~~~bash
IMPALA_CATALOG_SERVICE_HOST=cdh1
IMPALA_STATE_STORE_HOST=cdh1
IMPALA_STATE_STORE_PORT=24000
IMPALA_BACKEND_PORT=22000
IMPALA_LOG_DIR=/var/log/impala

IMPALA_CATALOG_ARGS=" -log_dir=${IMPALA_LOG_DIR} "
IMPALA_STATE_STORE_ARGS=" -log_dir=${IMPALA_LOG_DIR} -state_store_port=${IMPALA_STATE_STORE_PORT}"
IMPALA_SERVER_ARGS=" \
    -log_dir=${IMPALA_LOG_DIR} \
    -catalog_service_host=${IMPALA_CATALOG_SERVICE_HOST} \
    -state_store_port=${IMPALA_STATE_STORE_PORT} \
    -use_statestore \
    -state_store_host=${IMPALA_STATE_STORE_HOST} \
    -be_port=${IMPALA_BACKEND_PORT}"

ENABLE_CORE_DUMPS=false

# LIBHDFS_OPTS=-Djava.library.path=/usr/lib/impala/lib
# MYSQL_CONNECTOR_JAR=/usr/share/java/mysql-connector-java.jar
# IMPALA_BIN=/usr/lib/impala/sbin
# IMPALA_HOME=/usr/lib/impala
# HIVE_HOME=/usr/lib/hive
# HBASE_HOME=/usr/lib/hbase
# IMPALA_CONF_DIR=/etc/impala/conf
# HADOOP_CONF_DIR=/etc/impala/conf
# HIVE_CONF_DIR=/etc/impala/conf
# HBASE_CONF_DIR=/etc/impala/conf
~~~

设置 impala 可以使用的最大内存：在上面的 `IMPALA_SERVER_ARGS` 参数值后面添加 `-mem_limit=70%` 即可。

如果需要设置 impala 中每一个队列的最大请求数，需要在上面的 `IMPALA_SERVER_ARGS` 参数值后面添加 `-default_pool_max_requests=-1` ，该参数设置每一个队列的最大请求数，如果为-1，则表示不做限制。

在节点cdh1上拷贝`hive-site.xml`、`core-site.xml`、`hdfs-site.xml`至`/usr/lib/impala/conf`目录并作下面修改在`hdfs-site.xml`文件中添加如下内容：

~~~xml
<property>
    <name>dfs.client.read.shortcircuit</name>
    <value>true</value>
</property>
 
<property>
    <name>dfs.domain.socket.path</name>
    <value>/var/run/hadoop-hdfs/dn._PORT</value>
</property>

<property>
  <name>dfs.datanode.hdfs-blocks-metadata.enabled</name>
  <value>true</value>
</property>
~~~

同步以上文件到其他节点。


## 3.2 创建socket path

在每个节点上创建/var/run/hadoop-hdfs:

~~~bash
$ mkdir -p /var/run/hadoop-hdfs
~~~

拷贝postgres jdbc jar：

~~~bash
$ ln -s /usr/share/java/postgresql-jdbc.jar /usr/lib/impala/lib/
~~~

## 3.3 用户要求

impala 安装过程中会创建名为 impala 的用户和组，不要删除该用户和组。

如果想要 impala 和 YARN 和 Llama 合作，需要把 impala 用户加入 hdfs 组。

impala 在执行 DROP TABLE 操作时，需要把文件移到到 hdfs 的回收站，所以你需要创建一个 hdfs 的目录 /user/impala，并将其设置为impala 用户可写。同样的，impala 需要读取 hive 数据仓库下的数据，故需要把 impala 用户加入 hive 组。

impala 不能以 root 用户运行，因为 root 用户不允许直接读。

创建 impala 用户家目录并设置权限：

~~~bash
sudo -u hdfs hadoop fs -mkdir /user/impala
sudo -u hdfs hadoop fs -chown impala /user/impala
~~~

查看 impala 用户所属的组：

~~~bash
$ groups impala
impala : impala hadoop hdfs hive
~~~

由上可知，impala 用户是属于 imapal、hadoop、hdfs、hive 用户组的

# 4. 启动服务

在 cdh1节点启动：

~~~bash
$ service impala-state-store start
$ service impala-catalog start
~~~

如果impalad正常启动，可以在`/tmp/ impalad.INFO`查看。如果出现异常，可以查看`/tmp/impalad.ERROR`定位错误信息。

# 5. 使用shell

使用`impala-shell`启动Impala Shell，连接 cdh1，并刷新元数据

~~~bash
>impala-shell
[Not connected] >connect cdh1
[cdh1:21000] >invalidate metadata
[cdh2:21000] >connect cdh2
[cdh2:21000] >select * from t
~~~

当在 Hive 中创建表之后，第一次启动 impala-shell 时，请先执行 `INVALIDATE METADATA` 语句以便 Impala 识别出新创建的表(在 Impala 1.2 及以上版本，你只需要在一个节点上运行 `INVALIDATE METADATA` ，而不是在所有的 Impala 节点上运行)。

你也可以添加一些其他参数，查看有哪些参数：

~~~bash
# impala-shell -h
Usage: impala_shell.py [options]

Options:
  -h, --help            show this help message and exit
  -i IMPALAD, --impalad=IMPALAD
                        <host:port> of impalad to connect to
  -q QUERY, --query=QUERY
                        Execute a query without the shell
  -f QUERY_FILE, --query_file=QUERY_FILE
                        Execute the queries in the query file, delimited by ;
  -k, --kerberos        Connect to a kerberized impalad
  -o OUTPUT_FILE, --output_file=OUTPUT_FILE
                        If set, query results will written to the given file.
                        Results from multiple semicolon-terminated queries
                        will be appended to the same file
  -B, --delimited       Output rows in delimited mode
  --print_header        Print column names in delimited mode, true by default
                        when pretty-printed.
  --output_delimiter=OUTPUT_DELIMITER
                        Field delimiter to use for output in delimited mode
  -s KERBEROS_SERVICE_NAME, --kerberos_service_name=KERBEROS_SERVICE_NAME
                        Service name of a kerberized impalad, default is
                        'impala'
  -V, --verbose         Enable verbose output
  -p, --show_profiles   Always display query profiles after execution
  --quiet               Disable verbose output
  -v, --version         Print version information
  -c, --ignore_query_failure
                        Continue on query failure
  -r, --refresh_after_connect
                        Refresh Impala catalog after connecting
  -d DEFAULT_DB, --database=DEFAULT_DB
                        Issue a use database command on startup.
~~~


例如，你可以在连接时候字段刷新：

~~~bash
$ impala-shell -r
Starting Impala Shell in unsecure mode
Connected to 192.168.56.11:21000
Server version: impalad version 1.1.1 RELEASE (build 83d5868f005966883a918a819a449f636a5b3d5f)
Invalidating Metadata
Welcome to the Impala shell. Press TAB twice to see a list of available commands.

Copyright (c) 2012 Cloudera, Inc. All rights reserved.

(Shell build version: Impala Shell v1.1.1 (83d5868) built on Fri Aug 23 17:28:05 PDT 2013)
Query: invalidate metadata
Query finished, fetching results ...

Returned 0 row(s) in 5.13s
[192.168.56.11:21000] >                  
~~~

使用 impala 导出数据：

~~~bash
$ impala-shell -i '192.168.56.11:21000' -r -q "select * from test" -B --output_delimiter="\t" -o result.txt
~~~

# 6. 参考文章

- [Impala安装文档完整版](http://yuntai.1kapp.com/?p=904)
- [Impala入门笔记](http://tech.uc.cn/?p=817)
- [Installing and Using Cloudera Impala](https://ccp.cloudera.com/display/IMPALA10BETADOC/Installing+and+Using+Cloudera+Impala)
