---
layout: post

title: Zookeeper配置Kerberos认证

category: hadoop

tags: [hadoop,kerberos,cdh,zookeeper]

description: 记录 CDH Hadoop 集群上配置 Zookeeper 集成 Kerberos 的过程，包括 Kerberos 的安装和 Zookeeper 相关配置修改说明。

---

关于 Hadoop 集群上配置 kerberos 以及 ldap 的过程请参考本博客以下文章：

 - [HDFS配置Kerberos认证](/2014/11/04/config-kerberos-in-cdh-hdfs.html)
 - [YARN配置Kerberos认证](/2014/11/05/config-kerberos-in-cdh-yarn.html)
 - [Hive配置Kerberos认证](/2014/11/06/config-kerberos-in-cdh-hive.html)
 - [Impala配置Kerberos认证](/2014/11/06/config-kerberos-in-cdh-impala.html)
 - [Hadoop配置LDAP集成Kerberos](/2014/11/12/config-ldap-with-kerberos-in-cdh-hadoop.html)


参考 [使用yum安装CDH Hadoop集群](/2013/04/06/install-cloudera-cdh-by-yum.html) 安装 hadoop 集群，集群包括三个节点，每个节点的ip、主机名和部署的组件分配如下：

~~~
192.168.56.121        cdh1     NameNode、Hive、ResourceManager、HBase、impala-state-store、impala-catalog、Kerberos Server、zookeeper-server
192.168.56.122        cdh2     DataNode、SSNameNode、NodeManager、HBase、impala-server、zookeeper-server
192.168.56.123        cdh3     DataNode、HBase、NodeManager、impala-server、zookeeper-server
~~~

# 1. 配置 ZooKeeper Server

# 1.1 生成 keytab

在 cdh1 节点，即 KDC server 节点上执行下面命令：

~~~bash
$ cd /var/kerberos/krb5kdc/

kadmin.local -q "addprinc -randkey zookeeper/cdh1@JAVACHEN.COM "
kadmin.local -q "addprinc -randkey zookeeper/cdh2@JAVACHEN.COM "
kadmin.local -q "addprinc -randkey zookeeper/cdh3@JAVACHEN.COM "

kadmin.local -q "xst  -k zookeeper.keytab  zookeeper/cdh1@JAVACHEN.COM "
kadmin.local -q "xst  -k zookeeper.keytab  zookeeper/cdh2@JAVACHEN.COM "
kadmin.local -q "xst  -k zookeeper.keytab  zookeeper/cdh3@JAVACHEN.COM "
~~~

拷贝 zookeeper.keytab 文件到其他节点的 /etc/zookeeper/conf 目录：

~~~bash
$ scp zookeeper.keytab cdh1:/etc/zookeeper/conf
$ scp zookeeper.keytab cdh2:/etc/zookeeper/conf
$ scp zookeeper.keytab cdh3:/etc/zookeeper/conf
~~~

并设置权限，分别在 cdh1、cdh2、cdh3 上执行：

~~~bash
$ ssh cdh1 "cd /etc/zookeeper/conf/;chown zookeeper:hadoop zookeeper.keytab ;chmod 400 *.keytab"
$ ssh cdh2 "cd /etc/zookeeper/conf/;chown zookeeper:hadoop zookeeper.keytab ;chmod 400 *.keytab"
$ ssh cdh3 "cd /etc/zookeeper/conf/;chown zookeeper:hadoop zookeeper.keytab ;chmod 400 *.keytab"
~~~

由于 keytab 相当于有了永久凭证，不需要提供密码(如果修改 kdc 中的 principal 的密码，则该 keytab 就会失效)，所以其他用户如果对该文件有读权限，就可以冒充 keytab 中指定的用户身份访问 hadoop，所以 keytab 文件需要确保只对 owner 有读权限(0400)

## 1.2 修改 zookeeper 配置文件

在 cdh1 节点上修改 /etc/zookeeper/conf/zoo.cfg 文件，添加下面内容：

~~~properties
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
jaasLoginRenew=3600000
~~~

将修改的上面文件同步到其他节点：cdh2、cdh3：

~~~bash
$ scp /etc/zookeeper/conf/zoo.cfg cdh2:/etc/zookeeper/conf/zoo.cfg
$ scp /etc/zookeeper/conf/zoo.cfg cdh3:/etc/zookeeper/conf/zoo.cfg
~~~

## 1.3 创建 JAAS 配置文件

在 cdh1 的配置文件目录创建 jaas.conf 文件，内容如下：

~~~
Server {
  com.sun.security.auth.module.Krb5LoginModule required
  useKeyTab=true
  keyTab="/etc/zookeeper/conf/zookeeper.keytab"
  storeKey=true
  useTicketCache=false
  principal="zookeeper/cdh1@JAVACHEN.COM";
};
~~~

同样，在 cdh2 和 cdh3 节点也创建该文件，**注意每个节点的 principal 有所不同**。

然后，在 /etc/zookeeper/conf/ 目录创建 java.env，内容如下：

~~~bash
export JVMFLAGS="-Djava.security.auth.login.config=/etc/zookeeper/conf/jaas.conf"
~~~

并将该文件同步到其他节点：

~~~bash
$ scp /etc/zookeeper/conf/java.env cdh2:/etc/zookeeper/conf/java.env
$ scp /etc/zookeeper/conf/java.env cdh3:/etc/zookeeper/conf/java.env
~~~

## 1.4 重启服务

依次重启，并观察日志：

~~~bash
/etc/init.d/zookeeper-server restart
~~~

# 2. 配置 ZooKeeper Client

# 2.1 生成 keytab

在 cdh1 节点，即 KDC server 节点上执行下面命令：

~~~bash
$ cd /var/kerberos/krb5kdc/
kadmin.local -q "addprinc -randkey zkcli/cdh1@JAVACHEN.COM "
kadmin.local -q "addprinc -randkey zkcli/cdh2@JAVACHEN.COM "
kadmin.local -q "addprinc -randkey zkcli/cdh3@JAVACHEN.COM "

kadmin.local -q "xst  -k zkcli.keytab  zkcli/cdh1@JAVACHEN.COM "
kadmin.local -q "xst  -k zkcli.keytab  zkcli/cdh2@JAVACHEN.COM "
kadmin.local -q "xst  -k zkcli.keytab  zkcli/cdh3@JAVACHEN.COM "
~~~

拷贝 zkcli.keytab 文件到其他节点的 /etc/zookeeper/conf 目录：

~~~bash
$ scp zkcli.keytab cdh1:/etc/zookeeper/conf
$ scp zkcli.keytab cdh2:/etc/zookeeper/conf
$ scp zkcli.keytab cdh3:/etc/zookeeper/conf
~~~

并设置权限，分别在 cdh1、cdh2、cdh3 上执行：

~~~bash
$ ssh cdh1 "cd /etc/zookeeper/conf/;chown zookeeper:hadoop zkcli.keytab ;chmod 400 *.keytab"
$ ssh cdh2 "cd /etc/zookeeper/conf/;chown zookeeper:hadoop zkcli.keytab ;chmod 400 *.keytab"
$ ssh cdh3 "cd /etc/zookeeper/conf/;chown zookeeper:hadoop zkcli.keytab ;chmod 400 *.keytab"
~~~

由于 keytab 相当于有了永久凭证，不需要提供密码(如果修改 kdc 中的 principal 的密码，则该 keytab 就会失效)，所以其他用户如果对该文件有读权限，就可以冒充 keytab 中指定的用户身份访问 hadoop，所以 keytab 文件需要确保只对 owner 有读权限(0400)

## 2.2 创建 JAAS 配置文件

在 cdh1 的配置文件目录 /etc/zookeeper/conf/ 创建 client-jaas.conf 文件，内容如下：

~~~
Client {
  com.sun.security.auth.module.Krb5LoginModule required
  useKeyTab=true
  keyTab="/etc/zookeeper/conf/zkcli.keytab"
  storeKey=true
  useTicketCache=false
  principal="zkcli@JAVACHEN.COM";
};
~~~

同步到其他节点：

~~~bash
$ scp client-jaas.conf cdh2:/etc/zookeeper/conf
$ scp client-jaas.conf cdh3:/etc/zookeeper/conf
~~~

然后，在 /etc/zookeeper/conf/ 目录创建或者修改  java.env，内容如下：

~~~bash
export CLIENT_JVMFLAGS="-Djava.security.auth.login.config=/etc/zookeeper/conf/client-jaas.conf"
~~~

> 如果，zookeeper-client 和 zookeeper-server 安装在同一个节点上，则 java.env 中的 `java.security.auth.login.config` 参数会被覆盖，这一点从 zookeeper-client 命令启动日志可以看出来。

并将该文件同步到其他节点：

~~~bash
$ scp /etc/zookeeper/conf/java.env cdh2:/etc/zookeeper/conf/java.env
$ scp /etc/zookeeper/conf/java.env cdh3:/etc/zookeeper/conf/java.env
~~~

## 2.3 验证

启动客户端：

~~~bash
$ zookeeper-client -server cdh1:2181
~~~

创建一个 znode 节点：

~~~bash
k: cdh1:2181(CONNECTED) 0] create /znode1 sasl:zkcli@JAVACHEN.COM:cdwra
    Created /znode1
~~~

验证该节点是否创建以及其 ACL：

~~~bash
[zk: cdh1:2181(CONNECTED) 1] getAcl /znode1
    'world,'anyone
    : cdrwa
~~~
