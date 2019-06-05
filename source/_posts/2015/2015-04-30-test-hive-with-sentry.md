---
layout: post

title: 测试Hive集成Sentry

category: hive

tags: [sentry,hive]

description: 本文主要记录测试Hive集成Sentry的过程。

published: true

---

本文在[安装和配置Sentry](/2015/04/30/install-and-config-sentry.html)基础之上测试Hive集成Sentry。注意：**这里Hive中并没有配置Kerberos认证**。

关于配置了Kerberos的Hive集群如何集成Sentry，请参考[配置安全的Hive集群集成Sentry](/2014/11/14/config-secured-hive-with-sentry.html)。

# 1. 配置Sentry

见[安装和配置Sentry](/2015/04/30/install-and-config-sentry.html)。

# 2. 配置Hive

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

修改 /etc/hive/conf/hive-site.xml，添加以下内容：

~~~xml
    <property>
      <name>hive.server2.enable.impersonation</name>
      <value>true</value>
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

# 3. 重启Hive

在cdh1上启动或重启hiveserver2：

~~~bash
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
# 注意：我设置了hiveserver2的jdbc端口为10001
$  beeline -u "jdbc:hive2://cdh1:10001/" -n hive -p hive -d org.apache.hive.jdbc.HiveDriver
~~~

执行下面的 sql 语句创建 role、group等：

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

因为系统上没有test用户和组，所以需要手动创建：

~~~bash
$ useradd test
~~~

# 5. 测试

## 测试admin_role角色

使用hive用户访问beeline：

~~~bash
$ beeline -u "jdbc:hive2://cdh1:10000/" -n hive -p hive -d org.apache.hive.jdbc.HiveDriver
~~~

查看当前系统用户是谁：

~~~sql
0: jdbc:hive2://cdh1:10000/> set system:user.name;
+------------------------+--+
|          set           |
+------------------------+--+
| system:user.name=hive  |
+------------------------+--+
1 row selected (0.188 seconds)
~~~

hive属于admin_role组，具有管理员权限，可以查看所有角色：

~~~sql
0: jdbc:hive2://cdh1:10000/> show roles;
+-------------+--+
|    role     |
+-------------+--+
| test_role   |
| admin_role  |
+-------------+--+
2 rows selected (0.199 seconds)
~~~

查看所有权限：

~~~sql
0: jdbc:hive2://cdh1:10000/> SHOW GRANT ROLE test_role;
+-----------+--------+------------+---------+-----------------+-----------------+------------+---------------+---------------+
| database  | table  | partition  | column  | principal_name  | principal_type  | privilege  | grant_option  | grant_time | 
+-----------+--------+------------+---------+-----------------+-----------------+------------+---------------+---------------+
| filtered   |        |            |         | test_role       | ROLE            | *          | false       | 1430293474047000  | 
+-----------+--------+------------+---------+-----------------+-----------------+------------+---------------+---------------+

0: jdbc:hive2://cdh1:10000/> SHOW GRANT ROLE admin_role;
+-----------+--------+------------+---------+-----------------+-----------------+------------+---------------+---------------+
| database  | table  | partition  | column  | principal_name  | principal_type  | privilege  | grant_option  | grant_time  | 
+-----------+--------+------------+---------+-----------------+-----------------+------------+---------------+---------------+
| *         |        |            |         | admin_role      | ROLE            | *          | false       | 1430293473308000  
+-----------+--------+------------+---------+-----------------+-----------------+------------+---------------+---------------+
1 row selected (0.16 seconds)
~~~

hive用户可以查看所有数据库、访问所有表：

~~~sql
0: jdbc:hive2://cdh1:10000/> show databases;
+----------------+--+
| database_name  |
+----------------+--+
| default        |
| filtered       |
| sensitive      |
+----------------+--+
3 rows selected (0.391 seconds)
0: jdbc:hive2://cdh1:10000/> use filtered;
No rows affected (0.101 seconds)
0: jdbc:hive2://cdh1:10000/> select * from filtered.events;
+-----------------+----------------+----------------+--+
| events.country  | events.client  | events.action  |
+-----------------+----------------+----------------+--+
| US              | android        | createNote     |
| FR              | windows        | updateNote     |
| US              | android        | updateNote     |
| FR              | ios            | createNote     |
| US              | windows        | updateTag      |
+-----------------+----------------+----------------+--+
5 rows selected (0.431 seconds)
0: jdbc:hive2://cdh1:10000/> select * from sensitive.events;
+---------------+-----------------+----------------+----------------+--+
|   events.ip   | events.country  | events.client  | events.action  |
+---------------+-----------------+----------------+----------------+--+
| 10.1.2.3      | US              | android        | createNote     |
| 10.200.88.99  | FR              | windows        | updateNote     |
| 10.1.2.3      | US              | android        | updateNote     |
| 10.200.88.77  | FR              | ios            | createNote     |
| 10.1.4.5      | US              | windows        | updateTag      |
+---------------+-----------------+----------------+----------------+--+
5 rows selected (0.247 seconds)
~~~

## 测试test_role角色

使用test用户访问beeline：

~~~bash
$ beeline -u "jdbc:hive2://cdh1:10000/" -n test -p test -d org.apache.hive.jdbc.HiveDriver
~~~

查看当前系统用户是谁：

~~~sql
0: jdbc:hive2://cdh1:10000/> set system:user.name;
+------------------------+--+
|          set           |
+------------------------+--+
| system:user.name=hive  |
+------------------------+--+
1 row selected (0.188 seconds)
~~~

test用户不是管理员，是不能查看所有角色的：

~~~sql
0: jdbc:hive2://cdh1:10000/> show roles;
ERROR : Error processing Sentry command: Access denied to test. Server Stacktrace: org.apache.sentry.provider.db.SentryAccessDeniedException: Access denied to test
~~~

test用户可以列出所有数据库：

~~~sql
0: jdbc:hive2://cdh1:10000/> show databases;
+----------------+--+
| database_name  |
+----------------+--+
| default        |
| filtered       |
| sensitive      |
+----------------+--+
3 rows selected (0.079 seconds)
~~~

test用户可以filtered库：

~~~sql
0: jdbc:hive2://cdh1:10000/> use filtered;
No rows affected (0.206 seconds)
0: jdbc:hive2://cdh1:10000/> select * from events;
+-----------------+----------------+----------------+--+
| events.country  | events.client  | events.action  |
+-----------------+----------------+----------------+--+
| US              | android        | createNote     |
| FR              | windows        | updateNote     |
| US              | android        | updateNote     |
| FR              | ios            | createNote     |
| US              | windows        | updateTag      |
+-----------------+----------------+----------------+--+
5 rows selected (0.361 seconds)
~~~

但是，test用户没有权限访问sensitive库：

~~~sql
0: jdbc:hive2://cdh1:10000/> use sensitive;
Error: Error while compiling statement: FAILED: SemanticException No valid privileges
 Required privileges for this query: Server=server1->Db=sensitive->Table=*->action=insert;Server=server1->Db=sensitive->Table=*->action=select; (state=42000,code=40000)
~~~

# 6. 排错

在CDH5的高版本中，hive cli 不建议使用，在hive集成sentry之后，再运行hive cli 会提示找不到sentry的类的遗产，解决办法是，将sentry相关的jar包链接到hive的home目录下的lib目录下：

~~~bash
ln -s /usr/lib/sentry/lib/sentry-binding-hive.jar /usr/lib/hive/lib/
ln -s /usr/lib/sentry/lib/sentry-core-common.jar /usr/lib/hive/lib
ln -s /usr/lib/sentry/lib/sentry-core-common-db.jar /usr/lib/hive/lib
ln -s /usr/lib/sentry/lib/sentry-policy-common.jar /usr/lib/hive/lib
ln -s /usr/lib/sentry/lib/sentry-policy-db.jar /usr/lib/hive/lib
ln -s /usr/lib/sentry/lib/sentry-policy-cache.jar /usr/lib/hive/lib
ln -s /usr/lib/sentry/lib/sentry-provider-common.jar /usr/lib/hive/lib
ln -s /usr/lib/sentry/lib/sentry-provider-db.jar /usr/lib/hive/lib
ln -s /usr/lib/sentry/lib/sentry-provider-cache.jar /usr/lib/hive/lib
ln -s /usr/lib/sentry/lib/sentry-provider-file.jar /usr/lib/hive/lib
~~~

# 7. 参考文章

- [Securing Impala for analysts](http://blog.evernote.com/tech/2014/06/09/securing-impala-for-analysts/)  
