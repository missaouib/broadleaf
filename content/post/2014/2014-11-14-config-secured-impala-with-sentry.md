---
layout: post

title: 配置安全的Impala集群集成Sentry
date: 2014-11-14T08:00:00+08:00

categories: [ impala ]

tags: [sentry,kerberos,hive]

description: 本文主要记录配置安全的Impala集群集成Sentry的过程。

published: true

---

本文主要记录配置安全的Impala集群集成Sentry的过程。Impala集群上配置了Kerberos认证，并且需要提前配置好Hive与Kerberos和Sentry的集成：

- [使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum)
- [Hive配置kerberos认证](/2014/11/06/config-kerberos-in-cdh-hive)
- [Impala配置kerberos认证](/2014/11/06/config-kerberos-in-cdh-impala)
- [配置安全的Hive集群集成Sentry](/2014/11/14/config-secured-hive-with-sentry)

# 1. 环境说明

系统环境：

- 操作系统：CentOs 6.6
- Hadoop版本：`CDH5.4`
- JDK版本：`1.7.0_71`
- 运行用户：root

集群各节点角色规划为：

~~~
192.168.56.121        cdh1     NameNode、ResourceManager、HBase、Hive metastore、Impala Catalog、Impala statestore、Sentry 
192.168.56.122        cdh2     DataNode、NodeManager、HBase、Hiveserver2、Impala Server
192.168.56.123        cdh3     DataNode、HBase、NodeManager、Hiveserver2、Impala Server
~~~

# 2. 修改Impala配置

修改 /etc/default/impala 文件中的 `IMPALA_SERVER_ARGS` 参数，添加：

~~~bash
-server_name=server1
-sentry_config=/etc/hive/conf/sentry-site.xml
~~~

在 `IMPALA_CATALOG_ARGS` 中添加：

~~~bash
-sentry_config=/etc/hive/conf/sentry-site.xml
~~~

 /etc/hive/conf/sentry-site.xml 内容如下：

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>sentry.service.client.server.rpc-port</name>
        <value>8038</value>
    </property>
    <property>
        <name>sentry.service.client.server.rpc-address</name>
        <value>cdh1</value>
    </property>
    <property>
        <name>sentry.service.client.server.rpc-connection-timeout</name>
        <value>200000</value>
    </property>
    <property>
        <name>sentry.provider</name>
        <value>org.apache.sentry.provider.file.HadoopGroupResourceAuthorizationProvider</value>
    </property>
    <property>
        <name>sentry.hive.provider.backend</name>
        <value>org.apache.sentry.provider.db.SimpleDBProviderBackend</value>
    </property>
    <property>
        <name>sentry.metastore.service.users</name>
        <value>hive</value><!--queries made by hive user (beeline) skip meta store check-->
    </property>
    <property>
        <name>sentry.hive.server</name>
        <value>server1</value>
    </property>
    <property>
        <name>sentry.hive.testing.mode</name>
        <value>true</value>
    </property>
</configuration>
~~~

# 3. 重启Impala服务

在cdh1节点

# 4. 测试

# 5. 其他说明

如果要使用基于文件存储的方式配置Sentry store，则需要修改 /etc/default/impala 文件中的 `IMPALA_SERVER_ARGS` 参数，添加：

~~~properties
-server_name=server1
-authorization_policy_file=/user/hive/sentry/sentry-provider.ini
-authorization_policy_provider_class=org.apache.sentry.provider.file.LocalGroupResourceAuthorizationProvider
~~~

创建 sentry-provider.ini 文件并将其上传到 hdfs 的 /user/hive/sentry/ 目录：

~~~
$ cat /tmp/sentry-provider.ini
[databases]
# Defines the location of the per DB policy file for the customers DB/schema
#db1 = hdfs://cdh1:8020/user/hive/sentry/db1.ini

[groups]
admin = any_operation
hive = any_operation
test = select_filtered

[roles]
any_operation = server=server1->db=*->table=*->action=*
select_filtered = server=server1->db=filtered->table=*->action=SELECT
select_us = server=server1->db=filtered->table=events_usonly->action=SELECT

[users]
test = test
hive= hive

$ hdfs dfs -rm -r /user/hive/sentry/sentry-provider.ini
$ hdfs dfs -put /tmp/sentry-provider.ini /user/hive/sentry/
$ hdfs dfs -chown hive:hive /user/hive/sentry/sentry-provider.ini
$ hdfs dfs -chmod 640 /user/hive/sentry/sentry-provider.ini
~~~

注意：server1 必须和 sentry-provider.ini 文件中的保持一致。

# 6. 参考文章

- [Securing Impala for analysts](http://blog.evernote.com/tech/2014/06/09/securing-impala-for-analysts/)  

# 7. 相关文章

 - [HDFS配置Kerberos认证](/2014/11/04/config-kerberos-in-cdh-hdfs)
 - [YARN配置Kerberos认证](/2014/11/05/config-kerberos-in-cdh-yarn)
 - [Hive配置Kerberos认证](/2014/11/06/config-kerberos-in-cdh-hive)
 - [Impala配置Kerberos认证](/2014/11/06/config-kerberos-in-cdh-impala)
 - [Zookeeper配置Kerberos认证](/2014/11/18/config-kerberos-in-cdh-zookeeper.)
 - [Hadoop配置LDAP集成Kerberos](/2014/11/12/config-ldap-with-kerberos-in-cdh-hadoop)
 - [配置安全的Hive集群集成Sentry](/2014/11/14/config-secured-hive-with-sentry)
 - [配置安全的Impala集群集成Sentry](/2014/11/14/config-secured-impala-with-sentry)
 - [Hadoop集群部署权限总结](/2014/11/25/quikstart-for-config-kerberos-ldap-and-sentry-in-hadoop)
