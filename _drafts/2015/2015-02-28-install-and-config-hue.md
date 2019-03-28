---
layout: post

title: 安装和配置Hue

category: hadoop

tags: [ hadoop,hue ]

description:  本文主要记录使用 yum 源安装 Hue 以及配置 Hue 集成 Hdfs、Hive、Impala、Yarn、Kerberos、LDAP、Sentry、Solr 等的过程。

published: true

---

本文主要记录使用 yum 源安装 Hue 以及配置 Hue 集成 Hdfs、Hive、Impala、Yarn、Kerberos、LDAP、Sentry、Solr 等的过程。

安装环境：

- 操作系统：`CentOs6.5`
- Hadoop：`cdh5.2.0`
- Hue：`3.6.0+cdh5.2.0`

# 安装 Hue

在 Hadoop 集群的一个节点上安装 Hue server，这里我是在我的测试集群中的 `cdh1` 节点上安装：

~~~bash
$ yum install hue hue-server
~~~

# 配置 Hue

## 配置hue server

~~~ini
[desktop]
    http_host=cdh1
    http_port=8888
    secret_key=qpbdxoewsqlkhztybvfidtvwekftusgdlofbcfghaswuicmqp
    time_zone=Asia/Shanghai
~~~

如果想配置 SSL，则添加下面设置：

~~~ini
ssl_certificate=/path/to/certificate
ssl_private_key=/path/to/key
~~~

并使用下面命令生成证书：

~~~bash
# Create a key 
$ openssl genrsa 1024 > host.key 
# Create a self-signed certificate 
$ openssl req -new -x509 -nodes -sha1 -key host.key > host.cert
~~~

## 配置 DB Query

DB Query 的相关配置在 hue.ini 中 databases 节点下面，目前共支持 sqlite, mysql, postgresql 和 oracle 四种数据库，默认使用的是 sqlite 数据库，你可以按自己的需要修改为其他的数据库。

~~~ini
[[database]]
    engine=sqlite3
    name=/var/lib/hue/desktop.db
~~~

## 配置 Hadoop 参数

### HDFS 集群配置

在 hadoop.hdfs_clusters.default 节点下配置以下参数：

- `fs_defaultfs`：
- `logical_name`： NameNode 逻辑名称
- `webhdfs_url`：
- `security_enabled`：是否开启 Kerberos
- `hadoop_conf_dir`： hadoop 配置文件路径

完整配置如下：

~~~ini
[hadoop]
  [[hdfs_clusters]]
    [[[default]]]
      # Enter the filesystem uri
      fs_defaultfs=hdfs://mycluster

      # NameNode logical name.
      logical_name=mycluster

      # Use WebHdfs/HttpFs as the communication mechanism.
      # Domain should be the NameNode or HttpFs host.
      # Default port is 14000 for HttpFs.
      ## webhdfs_url=http://localhost:50070/webhdfs/v1
      webhdfs_url=http://cdh1:14000/webhdfs/v1

      # Change this if your HDFS cluster is Kerberos-secured
      security_enabled=true

      hadoop_conf_dir=/etc/hadoop/conf
~~~

### 配置 WebHDFS 或者 HttpFS 

Hue 可以通过下面两种方式访问 Hdfs 中的数据：

- `WebHDFS`：提供高速的数据传输，客户端直接和 DataNode 交互
- `HttpFS`：一个代理服务，方便与集群外部的系统集成

两者都支持 HTTP REST API，但是 Hue 只能配置其中一种方式；对于 HDFS HA部署方式，只能使用 HttpFS。

- 1、对于 WebHDFS 方式，在每个节点上的 hdfs-site.xml 文件添加如下配置并重启服务：

~~~xml
<property>
  <name>dfs.webhdfs.enabled</name>
  <value>true</value>
</property>
~~~

- 2、 配置 Hue 为其他用户和组的代理用户。对于 WebHDFS 方式，在 core-site.xml 添加：

~~~xml
<!-- Hue WebHDFS proxy user setting -->
<property>
  <name>hadoop.proxyuser.hue.hosts</name>
  <value>*</value>
</property>
<property>
  <name>hadoop.proxyuser.hue.groups</name>
  <value>*</value>
</property>
~~~

对于 HttpFS 方式，在 /etc/hadoop-httpfs/conf/httpfs-site.xml  中添加下面配置并重启 HttpFS 进程：

~~~xml
<!-- Hue HttpFS proxy user setting -->
<property>
  <name>httpfs.proxyuser.hue.hosts</name>
  <value>*</value>
</property>
<property>
  <name>httpfs.proxyuser.hue.groups</name>
  <value>*</value>
</property>
~~~

对于 HttpFS 方式，在 core-site.xml 中添加下面配置并重启 hadoop 服务：

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

- 3、修改 /etc/hue/conf/hue.ini 中 hadoop.hdfs_clusters.default.webhdfs_url 属性。

对于 WebHDFS：

~~~ini
webhdfs_url=http://cdh1:50070/webhdfs/v1/
~~~

对于 HttpFS：

~~~ini
webhdfs_url=http://cdh1:14000/webhdfs/v1/
~~~

### YARN 集群配置

在 hadoop.yarn_clusters.default 节点下配置：

~~~ini
[hadoop]
  [[yarn_clusters]]
    [[[default]]]
        resourcemanager_host=cdh1
        resourcemanager_port=8032
        submit_to=True
        security_enabled=true
        resourcemanager_api_url=http://cdh1:8088
        proxy_api_url=http://cdh1:8088
        history_server_api_url=http://cdh1:19888
~~~

## 集成 Hive

在 beeswax 节点下配置：

~~~ini
[beeswax]
    hive_server_host=cdh1
    hive_server_port=10000 
    hive_conf_dir=/etc/hive/conf
~~~

这里是配置为连接一个 Hive Server2 节点，如有需要可以配置负载均衡，连接一个负载节点。

## 集成 Impala

在 impala 节点下配置

~~~ini
[impala]
  # Host of the Impala Server (one of the Impalad)
  server_host=cdh1

  # Port of the Impala Server
  server_port=21050

  # Kerberos principal
  impala_principal=impala/cdh1@JAVACHEN.COM

  # Turn on/off impersonation mechanism when talking to Impala
  impersonation_enabled=True
~~~

这里是配置为连接一个 Impala Server 节点，如有需要可以配置负载均衡，连接一个负载节点。

参考 [Configuring Per-User Access for Hue](http://www.cloudera.com/content/cloudera/en/documentation/core/v5-2-x/topics/impala_authorization.html#impersonation_unique_1) 和 [Use the Impala App with Sentry for real security](http://gethue.com/use-the-impala-app-with-sentry-for-real-security/)，在配置 `impersonation_enabled` 为 true 的情况下，还需要在 impalad 的启动参数中添加 `authorized_proxy_user_config` 参数，修改 /etc/default/impala中的 IMPALA_SERVER_ARGS 添加下面一行：

~~~ini
-authorized_proxy_user_config=hue=*  \
~~~

另外，如果集群开启了 Kerberos，别忘了配置 `impala_principal` 参数。

## 集成 kerberos

首先，需要在 kerberos server 节点上生成 hue 用户的凭证，并将其拷贝到 /etc/hue/conf 目录。：

~~~bash
$ kadmin: addprinc -randkey hue/cdh1@JAVACHEN.COM
$ kadmin: xst -k hue.keytab hue/cdh1@JAVACHEN.COM

$ cp hue.keytab /etc/hue/conf/
~~~

然后，修改 hue.ini 中 kerberos 节点：

~~~ini
[[kerberos]]
    # Path to Hue's Kerberos keytab file
    hue_keytab=/etc/hue/conf/hue.keytab

    # Kerberos principal name for Hue
    hue_principal=hue/cdh1@JAVACHEN.COM

    # Path to kinit
    kinit_path=/usr/bin/kinit
~~~

接下来，修改 /etc/hadoop/conf/core-site.xml，添加：

~~~xml
<!--hue kerberos-->
<property>
    <name>hadoop.proxyuser.hue.groups</name>
    <value>*</value>
</property>
<property>
    <name>hadoop.proxyuser.hue.hosts</name>
    <value>*</value>
</property>
<property>
    <name>hue.kerberos.principal.shortname</name>
    <value>hue</value>
</property>
~~~

最后，重启 hadoop 服务。

## 集成 LDAP

开启 ldap 验证，使用 ldap 用户登录 hue server，修改 auth 节点：

~~~ini
[desktop]
    [[auth]]
        backend=desktop.auth.backend.LdapBackend
~~~

另外修改 ldap 节点：

~~~ini
[desktop]
    [[ldap]]
        base_dn="dc=javachen,dc=com"
        ldap_url=ldap://cdh1

        # ldap用户登陆时自动在hue创建用户
        create_users_on_login = true

        # 开启direct bind mechanism
        search_bind_authentication=false

        # ldap登陆用户的模板，username运行时被替换
        ldap_username_pattern="uid=<username>,ou=people,dc=javachen,dc=com"
~~~

 注意：在开启ldap验证前，先普通方法创建一个ldap存在的用户，赋超级用户权限，否则无法管理hue用户。

## 集成 Sentry

如果 hive 和 impala 中集成了 Sentry，则需要修改 hue.ini 中的 libsentry 节点：

~~~ini
[libsentry]
  # Hostname or IP of server.
  hostname=cdh1

  # Port the sentry service is running on.
  port=8038

  # Sentry configuration directory, where sentry-site.xml is located.
  sentry_conf_dir=/etc/sentry/conf
~~~

另外，修改 /etc/sentry/conf/sentry-store-site.xml 确保 hue 用户可以连接 sentry：

~~~xml
<property>
  <name>sentry.service.allow.connect</name>
  <value>impala,hive,solr,hue</value>
</property>
~~~

## 集成 Sqoop2

在 sqoop 节点配置 server_url 参数为 sqoop2 的地址即可。

## 集成 HBase

在 hbase 节点配置下面参数：

- `truncate_limit`：Hard limit of rows or columns per row fetched before truncating.
- `hbase_clusters`：HBase Thrift 服务列表，例如：`Cluster1|cdh1:9090,Cluster2|cdh2:9090`，默认为：`Cluster|localhost:9090`

## 集成 Zookeeper

在 zookeeper 节点配置下面两个参数：

- `host_ports`：zookeeper 节点列表，例如：`localhost:2181,localhost:2182,localhost:2183`
- `rest_url`：zookeeper 的 REST 接口，默认值为 <http://localhost:9998>

## 集成 Oozie

未使用，暂不记录。

# 管理 Hue

如果配置了 kerberos，则先获取 hue 凭证：

~~~bash
kinit -k -t /etc/hue/conf/hue.keytab hue/cdh1@JAVACHEN.COM
~~~

启动 hue server：

~~~bash
$ service hue start
~~~

停止 hue server：

~~~bash
$ service hue stop
~~~

hue server 默认使用 8888 作为 web 访问端口，故需要在防火墙上开放该端口。

你可以在 /var/log/hue 目录查看 hue 的日志，或者通过 <http://cdh1:8888/logs> 查看。

# 测试

在开启了 LDAP 后，使用 LDAP 中的管理员用户登录 hue，根据提示向导进行设置并将 LDAP 中的用户同步到 Hue Server，然后依次测试每一个功能是否运行正常。

关于 Hue 的使用向导，请参考 <http://archive.cloudera.com/cdh5/cdh/5/hue/user-guide/index.html>。

Enjoy it !
