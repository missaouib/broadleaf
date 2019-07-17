---
layout: post

title: Impala配置Kerberos认证

category: impala

tags: [hadoop,kerberos,impala]

description: 记录 CDH Hadoop 集群上配置 Impala 集成 Kerberos 的过程，包括 Kerberos 的安装和 Impala 相关配置修改说明。

---

# 1. 环境说明

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

cdh1作为master节点，其他节点作为slave节点，hostname 请使用小写，要不然在集成 kerberos 时会出现一些错误。


# 2. 安装必须的依赖

在每个节点上运行下面的命令：

~~~bash
$ yum install python-devel openssl-devel python-pip cyrus-sasl cyrus-sasl-gssapi cyrus-sasl-devel -y
$ pip-python install ssl
~~~

# 3. 生成 keytab

在 cdh1 节点，即 KDC server 节点上执行下面命令：

~~~bash
$ cd /var/kerberos/krb5kdc/

kadmin.local -q "addprinc -randkey impala/cdh1@JAVACHEN.COM "
kadmin.local -q "addprinc -randkey impala/cdh2@JAVACHEN.COM "
kadmin.local -q "addprinc -randkey impala/cdh3@JAVACHEN.COM "

kadmin.local -q "xst  -k impala-unmerge.keytab  impala/cdh1@JAVACHEN.COM "
kadmin.local -q "xst  -k impala-unmerge.keytab  impala/cdh2@JAVACHEN.COM "
kadmin.local -q "xst  -k impala-unmerge.keytab  impala/cdh3@JAVACHEN.COM "
~~~

另外，如果你使用了haproxy来做负载均衡，参考官方文档[Using Impala through a Proxy for High Availability](http://www.cloudera.com/content/cloudera/en/documentation/cloudera-impala/latest/topics/impala_proxy.html)，还需生成 proxy.keytab：

~~~bash
$ cd /var/kerberos/krb5kdc/

# proxy 为安装了 haproxy 的机器
kadmin.local -q "addprinc -randkey impala/proxy@JAVACHEN.COM "

kadmin.local -q "xst  -k proxy.keytab impala/proxy@JAVACHEN.COM "
~~~

合并 proxy.keytab 和 impala-unmerge.keytab 生成 impala.keytab：

~~~bash
$ ktutil
ktutil: rkt proxy.keytab
ktutil: rkt impala-unmerge.keytab
ktutil: wkt impala.keytab
ktutil: quit
~~~

拷贝 impala.keytab 和 proxy_impala.keytab 文件到其他节点的 /etc/impala/conf 目录

~~~bash
$ scp impala.keytab cdh1:/etc/impala/conf
$ scp impala.keytab cdh2:/etc/impala/conf
$ scp impala.keytab cdh3:/etc/impala/conf
~~~

并设置权限，分别在 cdh1、cdh2、cdh3 上执行：

~~~bash
$ ssh cdh1 "cd /etc/impala/conf/;chown impala:hadoop *.keytab ;chmod 400 *.keytab"
$ ssh cdh2 "cd /etc/impala/conf/;chown impala:hadoop *.keytab ;chmod 400 *.keytab"
$ ssh cdh3 "cd /etc/impala/conf/;chown impala:hadoop *.keytab ;chmod 400 *.keytab"
~~~

由于 keytab 相当于有了永久凭证，不需要提供密码(如果修改 kdc 中的 principal 的密码，则该 keytab 就会失效)，所以其他用户如果对该文件有读权限，就可以冒充 keytab 中指定的用户身份访问 hadoop，所以 keytab 文件需要确保只对 owner 有读权限(0400)

# 4. 修改 impala 配置文件

修改 cdh1 节点上的 /etc/default/impala，在 `IMPALA_CATALOG_ARGS` 、`IMPALA_SERVER_ARGS` 和 `IMPALA_STATE_STORE_ARGS` 中添加下面参数：

~~~bash
-kerberos_reinit_interval=60
-principal=impala/_HOST@JAVACHEN.COM
-keytab_file=/etc/impala/conf/impala.keytab
~~~

如果使用了 HAProxy（关于 HAProxy 的配置请参考 [Hive使用HAProxy配置HA](/2014/01/08/hive-ha-by-haproxy.html)），则 `IMPALA_SERVER_ARGS` 参数需要修改为（proxy为 HAProxy 机器的名称，这里我是将 HAProxy 安装在 cdh1 节点上）：

~~~bash
-kerberos_reinit_interval=60
-be_principal=impala/_HOST@JAVACHEN.COM
-principal=impala/proxy@JAVACHEN.COM
-keytab_file=/etc/impala/conf/impala.keytab
~~~

在 `IMPALA_CATALOG_ARGS` 中添加：

~~~
-state_store_host=${IMPALA_STATE_STORE_HOST} \
~~~

将修改的上面文件同步到其他节点。最后，/etc/default/impala 文件如下，这里，为了避免 hostname 存在大写的情况，使用 `hostname` 变量替换 `_HOST`：

~~~bash
IMPALA_CATALOG_SERVICE_HOST=cdh1
IMPALA_STATE_STORE_HOST=cdh1
IMPALA_STATE_STORE_PORT=24000
IMPALA_BACKEND_PORT=22000
IMPALA_LOG_DIR=/var/log/impala

IMPALA_MEM_DEF=$(free -m |awk 'NR==2{print $2-5120}')
hostname=`hostname -f |tr "[:upper:]" "[:lower:]"`

IMPALA_CATALOG_ARGS=" -log_dir=${IMPALA_LOG_DIR} -state_store_host=${IMPALA_STATE_STORE_HOST} \
    -kerberos_reinit_interval=60\
    -principal=impala/${hostname}@JAVACHEN.COM \
    -keytab_file=/etc/impala/conf/impala.keytab
"

IMPALA_STATE_STORE_ARGS=" -log_dir=${IMPALA_LOG_DIR} -state_store_port=${IMPALA_STATE_STORE_PORT}\
    -statestore_subscriber_timeout_seconds=15 \
    -kerberos_reinit_interval=60 \
    -principal=impala/${hostname}@JAVACHEN.COM \
    -keytab_file=/etc/impala/conf/impala.keytab
"
IMPALA_SERVER_ARGS=" \
    -log_dir=${IMPALA_LOG_DIR} \
    -catalog_service_host=${IMPALA_CATALOG_SERVICE_HOST} \
    -state_store_port=${IMPALA_STATE_STORE_PORT} \
    -use_statestore \
    -state_store_host=${IMPALA_STATE_STORE_HOST} \
    -be_port=${IMPALA_BACKEND_PORT} \
    -kerberos_reinit_interval=60 \
    -be_principal=impala/${hostname}@JAVACHEN.COM \
    -principal=impala/cdh1@JAVACHEN.COM \
    -keytab_file=/etc/impala/conf/impala.keytab \
    -mem_limit=${IMPALA_MEM_DEF}m
"

ENABLE_CORE_DUMPS=false
~~~

将修改的上面文件同步到其他节点：cdh2、cdh3：

~~~bash
$ scp /etc/default/impala cdh2:/etc/default/impala
$ scp /etc/default/impala cdh3:/etc/default/impala
~~~

更新 impala 配置文件下的文件并同步到其他节点：

~~~bash
cp /etc/hadoop/conf/core-site.xml /etc/impala/conf/
cp /etc/hadoop/conf/hdfs-site.xml /etc/impala/conf/
cp /etc/hive/conf/hive-site.xml /etc/impala/conf/

scp -r /etc/impala/conf cdh2:/etc/impala
scp -r /etc/impala/conf cdh3:/etc/impala
~~~

# 5. 启动服务

## 启动 impala-state-store

impala-state-store 是通过 impala 用户启动的，故在 cdh1 上先获取 impala 用户的 ticket 再启动服务：

~~~bash
$ kinit -k -t /etc/impala/conf/impala.keytab impala/cdh1@JAVACHEN.COM
$ service impala-state-store start
~~~

然后查看日志，确认是否启动成功。

~~~bash
$ tailf /var/log/impala/statestored.INFO
~~~

## 启动 impala-catalog

impala-catalog 是通过 impala 用户启动的，故在 cdh1 上先获取 impala 用户的 ticket 再启动服务：

~~~bash
$ kinit -k -t /etc/impala/conf/impala.keytab impala/cdh1@JAVACHEN.COM
$ service impala-catalog start
~~~

然后查看日志，确认是否启动成功。

~~~bash
$ tailf /var/log/impala/catalogd.INFO
~~~

## 启动 impala-server

impala-server 是通过 impala 用户启动的，故在 cdh1 上先获取 impala 用户的 ticket 再启动服务：

~~~bash
$ kinit -k -t /etc/impala/conf/impala.keytab impala/cdh1@JAVACHEN.COM
$ service impala-server start
~~~

然后查看日志，确认是否启动成功。

~~~bash
$ tailf /var/log/impala/impalad.INFO
~~~

# 6. 测试

## 测试 impala-shell

在启用了 kerberos 之后，运行 impala-shell 时，需要添加 `-k` 参数：

~~~bash
$ impala-shell -k
Starting Impala Shell using Kerberos authentication
Using service name 'impala'
Connected to cdh1:21000
Server version: impalad version 1.3.1-cdh4 RELEASE (build 907481bf45b248a7bb3bb077d54831a71f484e5f)
Welcome to the Impala shell. Press TAB twice to see a list of available commands.

Copyright (c) 2012 Cloudera, Inc. All rights reserved.

(Shell build version: Impala Shell v1.3.1-cdh4 (907481b) built on Wed Apr 30 14:23:48 PDT 2014)
[cdh1:21000] >
[cdh1:21000] > show tables;
Query: show tables
+------+
| name |
+------+
| a    |
| b    |
| c    |
| d    |
+------+
Returned 4 row(s) in 0.08s
~~~

# 7. 排错

如果出现下面异常：

~~~
[cdh1:21000] > select * from test limit 10;
Query: select * from test limit 10
ERROR: AnalysisException: Failed to load metadata for table: default.test
CAUSED BY: TableLoadingException: Failed to load metadata for table: test
CAUSED BY: TTransportException: java.net.SocketTimeoutException: Read timed out
CAUSED BY: SocketTimeoutException: Read timed out
~~~

则需要在 hive-site.xml 中将 `hive.metastore.client.socket.timeout` 值设置大一些：

~~~xml
<property>
  <name>hive.metastore.client.socket.timeout</name>
  <value>36000</value>
</property>
~~~

# 8. 相关文章

 - [HDFS配置Kerberos认证](/2014/11/04/config-kerberos-in-cdh-hdfs)
 - [YARN配置Kerberos认证](/2014/11/05/config-kerberos-in-cdh-yarn)
 - [Hive配置Kerberos认证](/2014/11/06/config-kerberos-in-cdh-hive)
 - [Impala配置Kerberos认证](/2014/11/06/config-kerberos-in-cdh-impala)
 - [Zookeeper配置Kerberos认证](/2014/11/18/config-kerberos-in-cdh-zookeeper.)
 - [Hadoop配置LDAP集成Kerberos](/2014/11/12/config-ldap-with-kerberos-in-cdh-hadoop)
 - [配置安全的Hive集群集成Sentry](/2014/11/14/config-secured-hive-with-sentry)
 - [配置安全的Impala集群集成Sentry](/2014/11/14/config-secured-impala-with-sentry)
 - [Hadoop集群部署权限总结](/2014/11/25/quikstart-for-config-kerberos-ldap-and-sentry-in-hadoop)