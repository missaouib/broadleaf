---
layout: post

title: 安装和配置Sentry
date: 2015-04-30T08:00:00+08:00

categories: [ hive ]

tags: [sentry]

description: 本文主要记录安装和配置Sentry的过程。

published: true

---

本文主要记录安装和配置Sentry的过程，关于Sentry的介绍，请参考[Apache Sentry架构介绍](/2015/04/29/apache-sentry-architecture)。

# 1. 环境说明

系统环境：

- 操作系统：CentOs 6.6
- Hadoop版本：`CDH5.4`
- 运行用户：root

这里，我参考[使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum)一文搭建了一个测试集群，并选择cdh1节点来安装sentry服务。

# 2. 安装

在cdh1节点上运行下面命令查看Sentry的相关组件有哪些:

~~~bash
$ yum list sentry*

sentry.noarch                        1.4.0+cdh5.4.0+155-1.cdh5.4.0.p0.47.el6                            @cdh
sentry-hdfs-plugin.noarch        1.4.0+cdh5.4.0+155-1.cdh5.4.0.p0.47.el6                            @cdh
sentry-store.noarch                1.4.0+cdh5.4.0+155-1.cdh5.4.0.p0.47.el6                            @cdh
~~~

以上组件说明：

- `sentry`：sentry的基本包
- `sentry-hdfs-plugin`：hdfs插件
- `sentry-store`：sentry store组件

这里安装以上所有组件：

~~~bash
$ yum install sentry* -y
~~~

# 3. 配置

参考[sentry-site.xml.service.template](https://github.com/cloudera/sentry/blob/cdh5-1.4.0_5.4.0/conf/sentry-site.xml.service.template)，来修改Sentry的配置文件 /etc/sentry/conf/sentry-site.xml。

## 配置 sentry service 相关的参数

~~~xml
    <property>
        <name>sentry.service.admin.group</name>
        <value>impala,hive,solr,hue</value>
    </property>
    <property>
        <name>sentry.service.allow.connect</name>
        <value>impala,hive,solr,hue</value>
    </property>
    <property>
        <name>sentry.verify.schema.version</name>
        <value>false</value>
    </property>
    <property>
        <name>sentry.service.reporting</name>
        <value>JMX</value>
    </property>
    <property>
        <name>sentry.service.server.rpc-address</name>
        <value>cdh1</value>
    </property>
    <property>
        <name>sentry.service.server.rpc-port</name>
        <value>8038</value>
    </property>
    <property>
        <name>sentry.service.web.enable</name>
        <value>true</value>
    </property>
~~~

如果需要使用kerberos认证，则还需要配置以下参数：

~~~xml
    <property>
        <name>sentry.service.security.mode</name>
        <value>kerberos</value>
    </property>
    <property>
       <name>sentry.service.server.principal</name>
        <value></value>
    </property>
    <property>
        <name>sentry.service.server.keytab</name>
        <value></value>
    </property>
~~~

## 配置 sentry store 相关参数

sentry store可以使用两种方式，如果使用基于SimpleDbProviderBackend的方式，则需要设置jdbc相关的参数：

~~~xml
    <property>
        <name>sentry.store.jdbc.url</name>
        <value>jdbc:postgresql://cdh1:5432/sentry</value>
    </property>
    <property>
        <name>sentry.store.jdbc.driver</name>
        <value>org.postgresql.Driver</value>
    </property>
    <property>
        <name>sentry.store.jdbc.user</name>
        <value>sentry</value>
    </property>
    <property>
        <name>sentry.store.jdbc.password</name>
        <value>sentry</value>
    </property>
~~~

Sentry store的组映射`sentry.store.group.mapping`有些两种配置方式：`org.apache.sentry.provider.common.HadoopGroupMappingService`或者`org.apache.sentry.provider.file.LocalGroupMapping`，当使用后者的时候，还需要配置`sentry.store.group.mapping.resource`参数，即设置Policy file的路径。

~~~xml
    <property>
        <name>sentry.store.group.mapping</name>
        <value>org.apache.sentry.provider.common.HadoopGroupMappingService</value>
    </property>
    <property>
        <name>sentry.store.group.mapping.resource</name>
        <value> </value>
        <description> Policy file for group mapping. Policy file path for local group mapping, when sentry.store.group.mapping is set to LocalGroupMapping Service class.</description>
  </property>
~~~

## 配置客户端的参数：

配置Sentry和hive集成时的服务名称，默认值为`HS2`，这里设置为server1：

~~~xml
    <property>
        <name>sentry.hive.server</name>
        <value>server1</value>
    </property>
~~~


## 初始化数据库

如果配置 sentry store 使用 `posrgres` 数据库，当然你也可以使用其他的数据库，则需要创建并初始化数据库。数据库的创建过程，请参考 [Hadoop自动化安装shell脚本](/images/08/02/hadoop-install-script/)，下面列出关键脚本。

~~~bash
yum install postgresql-server postgresql-jdbc -y

ln -s /usr/share/java/postgresql-jdbc.jar /usr/lib/hive/lib/postgresql-jdbc.jar
ln -s /usr/share/java/postgresql-jdbc.jar /usr/lib/sentry/lib/postgresql-jdbc.jar

su -c "cd ; /usr/bin/pg_ctl start -w -m fast -D /var/lib/pgsql/data" postgres
su -c "cd ; /usr/bin/psql --command \"create user sentry with password 'sentry'; \" " postgres
su -c "cd ; /usr/bin/psql --command \"drop database sentry;\" " postgres
su -c "cd ; /usr/bin/psql --command \"CREATE DATABASE sentry owner=sentry;\" " postgres
su -c "cd ; /usr/bin/psql --command \"GRANT ALL privileges ON DATABASE sentry TO sentry;\" " postgres
su -c "cd ; /usr/bin/pg_ctl restart -w -m fast -D /var/lib/pgsql/data" postgres
~~~

然后，修改 /var/lib/pgsql/data/pg_hba.conf 内容如下：

~~~
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD

# "local" is for Unix domain socket connections only
local   all         all                               md5
# IPv4 local connections:
#host    all         all         0.0.0.0/0             trust
host    all         all         127.0.0.1/32          md5

# IPv6 local connections:
#host    all         all         ::1/128               nd5
~~~

如果是第一次安装，则初始化 sentry 的元数据库：

~~~bash
$ sentry --command schema-tool --conffile /etc/sentry/conf/sentry-site.xml --dbType postgres --initSchema
Sentry store connection URL:     jdbc:postgresql://cdh1/sentry
Sentry store Connection Driver :     org.postgresql.Driver
Sentry store connection User:    sentry
Starting sentry store schema initialization to 1.4.0-cdh5-2
Initialization script sentry-postgres-1.4.0-cdh5-2.sql
Connecting to jdbc:postgresql://cdh1/sentry
Connected to: PostgreSQL (version 8.4.18)
Driver: PostgreSQL Native Driver (version PostgreSQL 9.0 JDBC4 (build 801))
Transaction isolation: TRANSACTION_REPEATABLE_READ
Autocommit status: true
1 row affected (0.002 seconds)
No rows affected (0.004 seconds)
Closing: 0: jdbc:postgresql://cdh1/sentry
Initialization script completed
Sentry schemaTool completed
~~~

如果是更新，则执行：

~~~bash
$ sentry --command schema-tool --conffile /etc/sentry/conf/sentry-site.xml --dbType postgres --upgradeSchema
~~~

# 4. 启动

在cdh1上启动sentry-store服务：

~~~bash
$ /etc/init.d/sentry-store start
~~~

查看日志：

~~~bash
$ cat /var/log/sentry/sentry-store.out
~~~

查看sentry的web监控界面<http://cdh1:51000/>。


# 5. 参考文章

- [Setting Up Hive Authorization with Sentry](http://www.cloudera.com/content/cloudera/en/documentation/cloudera-manager/v4-8-0/Cloudera-Manager-Managing-Clusters/cmmc_sentry_config.html)
