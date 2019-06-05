---
layout: post
title: 编译CDH HBase源代码并打补丁
description: 写了一篇博客记录编译hbase源代码并打补丁的过程，如有不正确的，欢迎指出！
category: hbase
tags: [hbase]
---

写了一篇博客记录编译CDH HBase源代码并打补丁的过程，如有不正确的，欢迎指出！

# 下载源代码

从[Cloudera github](https://github.com/cloudera/hbase)上下载最新分支源代码，例如：当前最新分支为cdh4-0.94.6_4.4.0

~~~bash
$ git clone git@github.com:cloudera/hbase.git -b cdh4-0.94.6_4.4.0 cdh4-0.94.6_4.4.0
~~~

说明：

1. -b 指定下载哪个分支
2. 最后一个参数指定下载下来的文件名称

# 添加snappy压缩支持

## 编译snappy

~~~bash
$ svn checkout http://snappy.googlecode.com/svn/trunk/ snappy
$ cd snappy
$ sh autogen.sh
$ ./configure
$ sudo make install
~~~

## 编译hadoop-snappy

降低gcc版本到4.4:

~~~bash
$ sudo yum install gcc-4.4
$ rm /usr/bin/gcc
$ ln -s /usr/bin/gcc-4.4 /usr/bin/gcc
~~~

建立libjvm软连接

~~~
$ sudo ln -s /usr/java/latest/jre/lib/amd64/server/libjvm.so  /usr/local/lib/
~~~

<!-- more -->

下载并编译hadoop-snappy

~~~bash
$ svn checkout http://hadoop-snappy.googlecode.com/svn/trunk/ hadoop-snappy
$ cd hadoop-snappy
$ make package -Dsnappy.prefix=/usr/local/
~~~

安装jar包到本地仓库

~~~bash
$ mvn install:install-file -DgroupId=org.apache.hadoop -DartifactId=hadoop-snappy -Dversion=0.0.1-SNAPSHOT -Dpackaging=jar -Dfile=./target/hadoop-snappy-0.0.1-SNAPSHOT.jar
$ mvn install:install-file -DgroupId=org.apache.hadoop -DartifactId=hadoop-snappy -Dversion=0.0.1-SNAPSHOT -Dclassifier=Linux-amd64-64 -Dpackaging=tar -Dfile=./target/hadoop-snappy-0.0.1-SNAPSHOT-Linux-amd64-64.tar
~~~

# 添加lzo压缩支持

暂不在此列出，请参考网上文章。


# 编译Protobuf

注意：目前只能装2.4.1版本的，装最新版本的可能会缺少文件。

~~~bash
$ wget https://protobuf.googlecode.com/files/protobuf-2.4.1.zip
$ unzip protobuf-2.4.1.zip
$ cd protobuf-2.4.1
$ ./configure
$ make
$ sudo make install
~~~

测试是否安装成功，如果成功你会看到：

~~~bash
$ protoc
Missing input file.
~~~

如果安装失败，你可能会看到：

~~~
$ protoc
protoc: error while loading shared libraries: libprotobuf.so.7: cannot open shared object file: No such file or directory
~~~

# 编译hbase

进入到cdh4-0.94.6_4.4.0 目录，然后运行mvn基本命令。

~~~bash
$ cd cdh4-0.94.6_4.4.0
$ mvn clean install
~~~

忽略测试，请添加如下参数：

~~~
-DskipTests
~~~

添加MAVEN运行时jvm大小，请在mvn前面添加如下参数：

~~~
MAVEN_OPTS="-Xmx2g"
~~~

生成javadoc和文档，请添加如下参数：

~~~
javadoc:aggregate site assembly:single
~~~

生成release加入security和native包，请添加如下参数：

~~~
-Prelease,security,native
~~~

基于hadoop2.0进行编译，请添加如下参数：

~~~
-Dhadoop.profile=2.0
~~~

添加hadoop-snappy支持，请添加如下参数：

~~~
-Prelease,hadoop-snappy -Dhadoop-snappy.version=0.0.1-SNAPSHOT
~~~

如果你添加了一些java代码，在每个文件头没有添加license，则需要添加如下参数：

~~~
-Drat.numUnapprovedLicenses=200
~~~

综上，完整命令如下：

~~~bash
$ MAVEN_OPTS="-Xmx2g" mvn clean install javadoc:aggregate site assembly:single -DskipTests -Prelease,security,native,hadoop-snappy -Drat.numUnapprovedLicenses=200 -Dhadoop.profile=2.0 -Dhadoop-snappy.version=0.0.1-SNAPSHOT
~~~

# 生成patch

修改代码之后，在提交代码之前，运行如下命令生成patch：

~~~bash
$ git diff >../XXXXX.patch
~~~

如果你已经将该动文件加入到提交缓存区，即执行了如下代码：

~~~bash
$ git add .
~~~

你可以使用如下代码打补丁：

~~~bash
$ git diff --staged >../XXXXX.patch
~~~

如果在提交之后，想生成patch，执行如下命令：

~~~bash
$ git format-patch -1
~~~

`git format-patch` 的详细说明请参考：[git patch操作](http://devillived.net/forum/home.php?mod=space&uid=2&do=blog&id=211)

更多diff的命令如下：

~~~
git diff <file>   # 比较当前文件和暂存区文件差异
git diff
git diff <$id1> <$id2>    # 比较两次提交之间的差异
git diff <branch1>..<branch2>    # 在两个分支之间比较
git diff --staged   # 比较暂存区和版本库差异
git diff --cached   # 比较暂存区和版本库差异
git diff --stat     # 仅仅比较统计信息
~~~

# 打patch

打patch：

~~~bash
$ git apply ../XXXXX.patch
~~~

测试patch是否打成功：

~~~bash
$ git apply --check  ../add-aggregate-in-hbase-shell.patch
~~~

如果出现以下错误：

~~~bash
$ git apply ../XXXXX.patch
fatal: git apply: bad git-diff - expected /dev/null on line 4
~~~

请安装dos2unix：

~~~bash
$ yum install dos2unix -y
~~~

然后，执行如下代码：

~~~bash
$ dos2unix ../add-aggregate-in-hbase-shell.patch
~~~

最后再尝试打补丁。

注意：

* 请注意，git apply 是一个事务性操作的命令，也就是说，要么所有补丁都打上去，要么全部放弃。
* 对于传统的 diff 命令生成的补丁，则只能用 git apply 处理。对于 format-patch 制作的新式补丁，应当使用 git am 命令。

# 升级版本

当你fork了[Cloudera github](https://github.com/cloudera/hbase)代码之后，cloudera会继续更新代码、发布新的分支，如何将其最新的分支下载到自己的hbase仓库呢？例如，你的仓库中hbase最新分支为`cdh4-0.94.6_4.3.0`，而cdh最新分支为`cdh4-0.94.6_4.4.0`，现在如何将cdh上的分支下载到自己的参考呢？

查看远程服务器地址和仓库名称：

~~~bash
$ git remote -v
origin	git@github.com:javachen/hbase.git (fetch)
origin	git@github.com:javachen/hbase.git (push)
~~~

添加远程仓库地址：

~~~
$ git remote add cdh git@github.com:cloudera/hbase.git
~~~

再一次查看远程服务器地址和仓库名称：

~~~bash
$ git remote -v
cdh	https://github.com/cloudera/hbase (fetch)
cdh	https://github.com/cloudera/hbase (push)
origin	git@github.com:javachen/hbase.git (fetch)
origin	git@github.com:javachen/hbase.git (push)
~~~

抓取远程仓库更新：

~~~bash
$ git fetch cdh
~~~

然后，再执行下面命令查看远程分支：

~~~bash
$ git branch -r
~~~

下载cdh上的cdh4-0.94.6_4.4.0分支，在本地命名为cdh4-0.94.6_4.4.0：

~~~bash
$ git checkout -b cdh4-0.94.6_4.4.0 cdh/cdh4-0.94.6_4.4.0
~~~

将本地的cdh4-0.94.6_4.4.0分支其提交到自己的远程仓库：

~~~bash
$ git push origin cdh4-0.94.6_4.4.0:cdh4-0.94.6_4.4.0
~~~


# 排错

如果在启动 hbase 的服务过程中出现如下日志：

~~~
2013-10-24 22:44:59,921 INFO org.apache.hadoop.hbase.util.VersionInfo: HBase Unknown
2013-10-24 22:44:59,921 INFO org.apache.hadoop.hbase.util.VersionInfo: Subversion Unknown -r Unknown
2013-10-24 22:44:59,921 INFO org.apache.hadoop.hbase.util.VersionInfo: Compiled by Unknown on Unknown
~~~

请查看 src/saveVersion.sh 文件的编码及换行符是否和你的操作系统一致。编码应该设置为 UTF-8，如果你使用的是 linux 系统，则换行符应该为 unix/linux 换行符，不应该为 window 换行符。

# 参考文章

- [1] [Git常用命令备忘](http://robbinfan.com/blog/34/git-common-command)
- [2] [git patch操作](http://devillived.net/forum/home.php?mod=space&uid=2&do=blog&id=211)
- [3] [Git Fetch拉取他人分支](http://blog.tsnrose.com/blog/2012/04/18/git-fetch/)
- [4] [git根据commit生成patch](http://smilejay.com/2012/08/generate-a-patch-from-a-commit/)
