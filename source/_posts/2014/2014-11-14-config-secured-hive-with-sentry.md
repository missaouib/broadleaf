---
layout: post

title: 配置安全的Hive集群集成Sentry

category: hive

tags: [sentry,kerberos,hive]

description: 本文主要记录配置安全的Hive集群集成Sentry的过程。

published: true

---

本文主要记录配置安全的Hive集群集成Sentry的过程。Hive上配置了Kerberos认证，配置的过程请参考：

- [使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum.html)
- [Hive配置kerberos认证](/2014/11/06/config-kerberos-in-cdh-hive.html)

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

cdh1作为master节点，其他节点作为slave节点，我们在cdh1节点安装kerberos Server，在其他节点安装kerberos client。

# 2. 安装和配置Sentry

这部分内容，请参考[安装和配置Sentry](/2015/04/30/install-and-config-sentry.html)，因为集群中配置了kerberos，所以需要在KDC节点上（cdh1）生成 Sentry 服务的 principal 并导出为 ticket：

~~~bash
$ cd /etc/sentry/conf

$ kadmin.local -q "addprinc -randkey sentry/cdh1@JAVACHEN.COM "
$ kadmin.local -q "xst -k sentry.keytab sentry/cdh1@JAVACHEN.COM "

$ chown sentry:hadoop sentry.keytab ; chmod 400 *.keytab

$ cp sentry.keytab /etc/sentry/conf
~~~

然后，修改/etc/sentry/conf/sentry-site.xml 中下面的参数：

~~~xml
    <property>
        <name>sentry.service.security.mode</name>
        <value>kerberos</value>
    </property>
    <property>
       <name>sentry.service.server.principal</name>
        <value>sentry/cdh1@JAVACHEN.COM</value>
    </property>
    <property>
        <name>sentry.service.server.keytab</name>
        <value>/etc/sentry/conf/sentry.keytab</value>
    </property>
~~~

获取Sentry的ticket再启动sentry-store服务：

~~~bash
$ kinit -k -t /etc/sentry/conf/sentry.keytab sentry/cdh1@JAVACHEN.COM
$ /etc/init.d/sentry-store start
~~~

# 3. 配置Hive

## Hive Metastore集成Sentry

需要在 /etc/hive/conf/hive-site.xml中添加：

~~~xml
    <property>
      <name>hive.metastore.pre.event.listeners</name>
      <value>org.apache.sentry.binding.metastore.MetastoreAuthzBinding</value>
    </property>
    <property>
      <name>hive.metastore.event.listeners</name>
      <value>org.apache.sentry.binding.metastore.SentryMetastorePostEventListener</value>
    </property>
~~~

## Hive-server2集成Sentry

在Hive配置了Kerberos认证之后，Hive-server2集成Sentry有以下要求：

- 修改 `/user/hive/warehouse` 权限：

~~~bash
$ kinit -k -t /etc/hadoop/conf/hdfs.keytab hdfs/cdh1@JAVACHEN.COM

$ hdfs dfs -chmod -R 770 /user/hive/warehouse
$ hdfs dfs -chown -R hive:hive /user/hive/warehouse
~~~

- 禁止 HiveServer2 impersonation：

~~~xml
    <property>
      <name>hive.server2.enable.impersonation</name>
      <value>false</value>
    </property>
~~~

- 确认 /etc/hadoop/conf/container-executor.cfg 文件中 `min.user.id=0`。

修改 /etc/hive/conf/hive-site.xml：

~~~xml
    <property>
      <name>hive.server2.enable.impersonation</name>
      <value>false</value>
    </property>
    <property>
        <name>hive.security.authorization.task.factory</name>
        <value>org.apache.sentry.binding.hive.SentryHiveAuthorizationTaskFactoryImpl</value>
    </property>
    <property>
        <name>hive.server2.session.hook</name>
        <value>org.apache.sentry.binding.hive.HiveAuthzBindingSessionHook</value>
    </property>
    <property>
        <name>hive.sentry.conf.url</name>
        <value>file:///etc/hive/conf/sentry-site.xml</value>
    </property>
~~~

另外，因为集群配置了kerberos，故需要/etc/hive/conf/sentry-site.xml添加以下内容：

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
    <property>
        <name>sentry.service.security.mode</name>
        <value>kerberos</value>
    </property>
    <property>
       <name>sentry.service.server.principal</name>
        <value>sentry/_HOST@JAVACHEN.COM</value>
    </property>
    <property>
        <name>sentry.service.server.keytab</name>
        <value>/etc/sentry/conf/sentry.keytab</value>
    </property>
~~~

参考模板[sentry-site.xml.hive-client.template](https://github.com/cloudera/sentry/blob/cdh5-1.4.0_5.4.0/conf%2Fsentry-site.xml.hive-client.template)在 /etc/hive/conf/ 目录创建 sentry-site.xml：

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

    <!--以下是客户端配置-->
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

>注意：这里`sentry.hive.provider.backend`配置的是`org.apache.sentry.provider.db.SimpleDBProviderBackend`方式，关于`org.apache.sentry.provider.file.SimpleFileProviderBackend`的配置方法，后面再作说明。

hive添加对sentry的依赖，创建软连接：

~~~bash
$ ln -s /usr/lib/sentry/lib/sentry-binding-hive.jar /usr/lib/hive/lib/sentry-binding-hive.jar
~~~

## 重启HiveServer2

在cdh1上启动或重启hiveserver2：

~~~bash
$ kinit -k -t /etc/hive/conf/hive.keytab hive/cdh1@JAVACHEN.COM

$ /etc/init.d/hive-server2 restart
~~~

# 4. 准备测试数据

参考 [Securing Impala for analysts](http://blog.evernote.com/tech/2014/06/09/securing-impala-for-analysts/)，准备测试数据：

~~~bash
$ cat /tmp/events.csv
10.1.2.3,US,android,createNote
10.200.88.99,FR,windows,updateNote
10.1.2.3,US,android,updateNote
10.200.88.77,FR,ios,createNote
10.1.4.5,US,windows,updateTag
~~~

然后，在hive中运行下面 sql 语句：

~~~sql
create database sensitive;

create table sensitive.events (
    ip STRING, country STRING, client STRING, action STRING
  ) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';

load data local inpath '/tmp/events.csv' overwrite into table sensitive.events;
create database filtered;
create view filtered.events as select country, client, action from sensitive.events;
create view filtered.events_usonly as select * from filtered.events where country = 'US';
~~~

在 cdh1上通过 beeline 连接 hiveserver2，运行下面命令创建角色和组：

~~~bash
$ beeline -u "jdbc:hive2://cdh1:10001/default;principal=hive/cdh1@JAVACHEN.COM"
~~~

创建 role、group 等等，执行下面的 sql 语句：

~~~sql
create role admin_role;
GRANT ALL ON SERVER server1 TO ROLE admin_role;
GRANT ROLE admin_role TO GROUP admin;
GRANT ROLE admin_role TO GROUP hive;

create role test_role;
GRANT ALL ON DATABASE filtered TO ROLE test_role;
GRANT ROLE test_role TO GROUP test;
~~~

上面创建了两个角色：

- admin_role，具有管理员权限，可以读写所有数据库，并授权给 admin 和 hive 组（对应操作系统上的组）
- test_role，只能读写 filtered 数据库，并授权给 test 组。

# 5. 测试

## 使用 kerberos 测试

以 test 用户为例，通过 beeline 连接 hive-server2：

~~~bash
$ su test

$ kinit -k -t test.keytab test/cdh1@JAVACHEN.COM

$ beeline -u "jdbc:hive2://cdh1:10001/default;principal=test/cdh1@JAVACHEN.COM"
~~~

接下来运行一些sql查询，查看是否有权限。

## 使用 ldap 用户测试

在 ldap 服务器上创建系统用户 yy_test，并使用 migrationtools 工具将该用户导入 ldap，最后设置 ldap 中该用户密码。

~~~bash
# 创建 yy_test用户
useradd yy_test

grep -E "yy_test" /etc/passwd  >/opt/passwd.txt
/usr/share/migrationtools/migrate_passwd.pl /opt/passwd.txt /opt/passwd.ldif
ldapadd -x -D "uid=ldapadmin,ou=people,dc=lashou,dc=com" -w secret -f /opt/passwd.ldif

#使用下面语句修改密码，填入上面生成的密码，输入两次：

ldappasswd -x -D 'uid=ldapadmin,ou=people,dc=lashou,dc=com' -w secret "uid=yy_test,ou=people,dc=lashou,dc=com" -S
~~~

在每台 datanode 机器上创建 test 分组，并将 yy_test 用户加入到 test 分组：

~~~bash
groupadd test ; useradd yy_test; usermod -G test,yy_test yy_test
~~~

运行 beeline 查看是否能够使用 ldap 用户连接 hiveserver2：

~~~bash
$  beeline -u "jdbc:hive2://cdh1:10001/" -n yy_test -p yy_test -d org.apache.hive.jdbc.HiveDriver
~~~

# 6. 其他说明

如果要使用基于文件存储的方式配置Sentry store，则需要修改/etc/hive/conf/sentry-site.xml为：

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>hive.sentry.server</name>
    <value>server1</value>
  </property>
  <property>
    <name>sentry.hive.provider.backend</name>
    <value>org.apache.sentry.provider.file.SimpleFileProviderBackend</value>
  </property>
  <property>
    <name>hive.sentry.provider</name>
    <value>org.apache.sentry.provider.file.LocalGroupResourceAuthorizationProvider</value>
  </property>
  <property>
    <name>hive.sentry.provider.resource</name>
    <value>/user/hive/sentry/sentry-provider.ini</value>
  </property>
</configuration>
~~~

创建 sentry-provider.ini 文件并将其上传到 hdfs 的 /user/hive/sentry/ 目录：

~~~bash
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

关于 sentry-provider.ini 文件的语法说明，请参考官方文档。这里我指定了 Hive 组有全部权限，并指定 Hive 用户属于 Hive 分组，而其他两个分组只有部分权限。

# 7. 参考文章

- [Securing Impala for analysts](http://blog.evernote.com/tech/2014/06/09/securing-impala-for-analysts/)  

# 8. 相关文章

 - [HDFS配置Kerberos认证](/2014/11/04/config-kerberos-in-cdh-hdfs.html)
 - [YARN配置Kerberos认证](/2014/11/05/config-kerberos-in-cdh-yarn.html)
 - [Hive配置Kerberos认证](/2014/11/06/config-kerberos-in-cdh-hive.html)
 - [Impala配置Kerberos认证](/2014/11/06/config-kerberos-in-cdh-impala.html)
 - [Zookeeper配置Kerberos认证](/2014/11/18/config-kerberos-in-cdh-zookeeper.html)
 - [Hadoop配置LDAP集成Kerberos](/2014/11/12/config-ldap-with-kerberos-in-cdh-hadoop.html)
 - [配置安全的Hive集群集成Sentry](/2014/11/14/config-secured-hive-with-sentry.html)
 - [配置安全的Impala集群集成Sentry](/2014/11/14/config-secured-impala-with-sentry.html)
 - [Hadoop集群部署权限总结](/2014/11/25/quikstart-for-config-kerberos-ldap-and-sentry-in-hadoop.html)