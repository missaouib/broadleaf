---
layout: post
title: 在Eclipse中调试运行HBase
description: 这篇文章记录一下如何在eclipse中调试运行hbase。
category: hbase
tags: [hbase]
---

这篇文章记录一下如何在eclipse中调试运行hbase。

# 下载并编译源代码
请参考[编译hbase源代码并打补丁](http://blog.javachen.com/hbase/2013/10/28/compile-hbase-source-code-and-apply-patches/)

# 修改配置文件

修改 `conf/hbase-site.xml`文件：

~~~
<property>
<name>hbase.defaults.for.version</name>
<value>0.94.6-cdh4.4.0</value>
</property>

<property>
<name>hbase.rootdir</name>
<value>file:///home/june/tmp/data</value>
</property>
~~~

把conf文件夹加到Classpath中

# 运行HMaster

新建一个`Debug Configuration`,  main class 是`org.apache.hadoop.hbase.master.HMaster`,  参数填start

<!-- more -->

调试运行该类，运行成功之后日志如下：

~~~
13/10/29 14:38:29 WARN zookeeper.RecoverableZooKeeper: Node /hbase/table/.META. already deleted, and this is not a retry
13/10/29 14:38:29 INFO regionserver.HRegionServer: Received request to open region: .META.,,1.1028785192
13/10/29 14:38:29 INFO regionserver.HRegion: Setting up tabledescriptor config now ...
13/10/29 14:38:29 INFO regionserver.Store: time to purge deletes set to 0ms in store info
13/10/29 14:38:29 INFO regionserver.HRegion: Onlined .META.,,1.1028785192; next sequenceid=1
13/10/29 14:38:29 INFO regionserver.HRegionServer: Post open deploy tasks for region=.META.,,1.1028785192, daughter=false
13/10/29 14:38:29 INFO catalog.MetaEditor: Updated row .META.,,1.1028785192 with server=june-mint,47477,1383028701871
13/10/29 14:38:29 INFO regionserver.HRegionServer: Done with post open deploy task for region=.META.,,1.1028785192, daughter=false
13/10/29 14:38:29 INFO handler.OpenedRegionHandler: Handling OPENED event for .META.,,1.1028785192 from june-mint,47477,1383028701871; deleting unassigned node
13/10/29 14:38:29 INFO master.AssignmentManager: The master has opened the region .META.,,1.1028785192 that was online on june-mint,47477,1383028701871
13/10/29 14:38:29 INFO master.HMaster: .META. assigned=2, rit=false, location=june-mint,47477,1383028701871
13/10/29 14:38:29 INFO catalog.MetaMigrationRemovingHTD: Meta version=0; migrated=true
13/10/29 14:38:29 INFO catalog.MetaMigrationRemovingHTD: ROOT/Meta already up-to date with new HRI.
13/10/29 14:38:29 INFO master.AssignmentManager: Clean cluster startup. Assigning userregions
13/10/29 14:38:29 INFO master.HMaster: Registered HMaster MXBean
13/10/29 14:38:29 INFO master.HMaster: Master has completed initialization
~~~

如果想修改日志级别，请修改`conf/log4j.properties`中级别为INFO:

~~~
#Logging Threshold
log4j.threshold=INFO
~~~

# 运行HRegionServer

参考上面的方法，运行HRegionServer，这时候会出现如下日志：

~~~
13/11/04 11:50:47 INFO util.VersionInfo: HBase 0.94.6-cdh4.4.0
13/11/04 11:50:47 INFO util.VersionInfo: Subversion git://june-mint/chan/workspace/hadoop/hbase -r 979969e1d0d95ce3b8c1d14593f55148da8bc98f
13/11/04 11:50:47 INFO util.VersionInfo: Compiled by june on Tue Oct 29 15:11:51 CST 2013
13/11/04 11:50:47 WARN regionserver.HRegionServerCommandLine: Not starting a distinct region server because hbase.cluster.distributed is false
~~~

这是因为当`hbase.cluster.distributed=false`时，hbase为本地模式，master和regionserver在同一个jvm启动，并且会启动一个最小化的zookeeper集群。请参看：`HMasterCommandLine.java`的startMaster()方法。

如果你把该值设为true，则hbase集群为分布式模式，这时候默认会连接`127.0.0.1：2181`对应的zookeeper集群（该集群需要在master启动之前启动）。当然，你可以修改参数让hbase自己维护一个zookeeper集群。

# 调试hbase shell

新建一个`Debug Configuration`,  main class 是`org.jruby.Main`，在程序参数中添加`bin/hirb.rb`,然后运行即可。

# 一些技巧

* 调试java代码的时候, byte[]的变量总是显示成数字,如果要显示对应的字符

~~~
Window->Preference->Java->Debug->Primitive Display Options->Check some of them
~~~

* hbase源码中默认依赖的是hadoop 1.0.x版本，所以mavne依赖中会引入hadoop-core-1.0.4.jar，你可以修改pom.xml文件，将默认的profile修改为你需要的hadoop版本，如2.0版本的hadoop。这样做之后，当你看HMaster的源代码时，你会很方便的关联并浏览ToolRunner类中的源代码。

默认的profile是hadoop-1.0，配置文件如下：

~~~
  <!-- profile for building against Hadoop 1.0.x: This is the default. -->
    <profile>
      <id>hadoop-1.0</id>
      <activation>
        <property>
          <name>!hadoop.profile</name>
        </property>

   <profile>
      <id>hadoop-2.0</id>
      <activation>
        <property>
          <name>hadoop.profile</name>
          <value>2.0</value>
        </property>
~~~

你可以将默认的profile改为hadoop-2.0,修改之后的配置文件如下：

~~~
    <profile>
      <id>hadoop-1.0</id>
      <activation>
        <property>
          <name>hadoop.profile</name>
	  <value>1.0</value>
        </property>

   <profile>
      <id>hadoop-2.0</id>
      <activation>
        <property>
          <name>!hadoop.profile</name>
        </property>
~~~
