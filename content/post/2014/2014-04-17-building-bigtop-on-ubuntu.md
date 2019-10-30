---
layout: post
title: Ubuntu系统编译Bigtop
date: 2014-04-17T08:00:00+08:00
description: Bigtop是apache基金会推出的一个对Hadoop及其周边生态进行打包、分发和测试的工具。本篇文章尝试在linux-mint系统上编译bigtop源代码并生成hadoop的deb包。
categories: [ hadoop ]
tags: 
 - bigtop
published: true
---

# 1. 安装系统依赖

## 系统更新并安装新的包

~~~bash
sudo apt-get update

sudo apt-get install -y cmake git-core git-svn subversion checkinstall build-essential dh-make debhelper ant ant-optional autoconf automake liblzo2-dev libzip-dev sharutils libfuse-dev reprepro libtool libssl-dev asciidoc xmlto ssh curl

sudo apt-get install -y devscripts

sudo apt-get build-dep pkg-config
~~~

## 安装Sun JDK 6或OpenJDK 7

Sun JDK 6:

执行以下脚本：

~~~bash
wget http://archive.cloudera.com/cm4/ubuntu/precise/amd64/cm/pool/contrib/o/oracle-j2sdk1.6/oracle-j2sdk1.6_1.6.0+update31_amd64.deb
dpkg -i oracle-j2sdk1.6_1.6.0+update31_amd64.deb

sudo rm /usr/lib/jvm/default-java
sudo ln -s /usr/lib/jvm/j2sdk1.6-oracle /usr/lib/jvm/default-java
sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/default-java/bin/java 5
sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/default-java/bin/javac 5
sudo update-alternatives --set java /usr/lib/jvm/default-java/bin/java
~~~

OpenJDK 7:

> OpenJDK 6 fails to build Hadoop because of issue MAPREDUCE-4115 Need to use [OpenJDK 7](http://www.shinephp.com/install-jdk-7-on-ubuntu/)

~~~bash
sudo apt-get install openjdk-7-jdk
sudo rm /usr/lib/jvm/default-java
sudo ln -s /usr/lib/jvm/java-7-openjdk-amd64 /usr/lib/jvm/default-java
sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/default-java/bin/java 5
sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/default-java/bin/javac 5
sudo update-alternatives --set java /usr/lib/jvm/default-java/bin/java
~~~

## 安装Maven 3

~~~bash
wget http://apache.petsads.us/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
tar -xzvf apache-maven-3.0.5-bin.tar.gz

sudo mkdir /usr/local/maven-3
sudo mv apache-maven-3.0.5 /usr/local/maven-3/
~~~

## 安装Apache Forrest

~~~bash
cd $HOME
wget http://archive.apache.org/dist/forrest/0.9/apache-forrest-0.9.tar.gz
tar -xzvf /home/ubuntu/Downloads/apache-forrest-0.9.tar.gz
# modify certain lines in the forrest-validate xml, otherwise build fails. either sed or nano are fine.
sed -i 's/property name="forrest.validate.sitemap" value="${forrest.validate}"/property name="forrest.validate.sitemap" value="false"/g' apache-forrest-0.9/main/targets/validate.xml
sed -i 's/property name="forrest.validate.stylesheets" value="${forrest.validate}"/property name="forrest.validate.stylesheets" value="false"/g' apache-forrest-0.9/main/targets/validate.xml
sed -i 's/property name="forrest.validate.stylesheets.failonerror" value="${forrest.validate.failonerror}"/property name="forrest.validate.stylesheets.failonerror" value="false"/g' apache-forrest-0.9/main/targets/validate.xml
sed -i 's/property name="forrest.validate.skins.stylesheets" value="${forrest.validate.skins}"/property name="forrest.validate.skins.stylesheets" value="false"/g' apache-forrest-0.9/main/targets/validate.xml
~~~

## 安装protobuf

protobuf版本至少需要2.4.0,具体版本视hadoop版本而定，例如`hadoop-2.4.0`即需要依赖`protobuf-2.5.0`

到 Protocol Buffers 的官网[https://code.google.com/p/protobuf/](https://code.google.com/p/protobuf/)下载2.5.0的安装源文件进行安装：

~~~bash
tar -zxf protobuf-2.5.0.tar.gz
cd protobuf-2.5.0
./configure --prefix=/usr/local/protobuf
make check
make install
~~~

安装完成后，执行 `protoc --vresion` 验证是否安装成功。

# 2. 设置环境变量

创建`/etc/profile.d/bigtop.sh`并添加如下内容：

~~~bash
export JAVA_HOME="/usr/lib/jvm/default-java"
export JAVA5_HOME="/usr/lib/jvm/default-java"
export JVM_ARGS="-Xmx1024m -XX:MaxPermSize=512m"
export MAVEN_HOME="/usr/local/maven-3/apache-maven-3.0.5"
export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=512m"
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:$MAVEN_HOME/bin"
~~~

将`FORREST_HOME`添加到`~/.bashrc`:

~~~bash
export FORREST_HOME="$HOME/apache-forrest-0.9"
~~~

# 3. 下载并编译源代码

~~~bash
git clone git://git.apache.org/bigtop.git # put files under bigtop directory
cd bigtop
# you can also use a different branch, e.g. git checkout branch-0.7
~~~

为了加快编译速度，你可以修改`Makefile`文件中的`APACHE_MIRROR`和`APACHE_ARCHIVE`为国内的速度较快的apache镜像地址，例如：[http://mirror.bit.edu.cn/apache](http://mirror.bit.edu.cn/apache)

编译源代码：

~~~bash
./check-env.sh # make sure all the required environment variables are set
make realclean
make bigtop-utils-deb # build this project first
make bigtop-jsvc-deb
make bigtop-tomcat-deb
make hadoop-deb # to build just for hadoop first
make deb # build all the rest
~~~

编译之后deb输出在output目录


# 4. 安装和测试

在使用`dpkg`命令安装之前，先关掉自动启动服务。使用root用欢创建`/usr/sbin/policy-rc.d`，该文件内容如下：

~~~
#!/bin/sh
exit 101
~~~

添加执行权限：

~~~
sudo chmod +x /usr/sbin/policy-rc.d
~~~

安装deb文件：

~~~
cd output/bigtop-utils
sudo dpkg --install *.deb
cd ..
sudo dpkg --install **/**.deb
~~~

最后别忘了删除掉`policy-rc.d`：

~~~
sudo rm /usr/sbin/policy-rc.d
~~~

初始化hdfs：

~~~
sudo -u hdfs hadoop namenode -format
~~~

启动服务：

~~~
sudo /etc/init.d/hadoop-hdfs-namenode start
sudo /etc/init.d/hadoop-hdfs-datanode start

#sudo /etc/init.d/hadoop-xxxx start
~~~

接下来可以查看日志和web页面是否正常了。访问[http://localhost:50070/](http://localhost:50070/)，你就可以看到hadoop-2.3.0的小清新的管理界面了。

# 5. 排错

1) bigtop-0.7依赖的是`protobuf-2.4.0`而不是`protobuf-2.5.0`，导致编译过程出现protobuf的版本需要2.5.0的提示，请卸载2.4.0版本重新编译protobuf-2.5.0。

2) 运行`make deb`时出现`more change data or trailer`的异常(详细异常信息见下面)，请将操作系统的LANG修改为`en_US`

~~~
parsechangelog/debian: warning:     debian/changelog(l4): badly formatted trailer line
LINE:  -- Bigtop <dev@bigtop.apache.org>  四, 17 4月 2014 14:30:17 +0800
parsechangelog/debian: warning:     debian/changelog(l4): found eof where expected more change data or trailer
dpkg-buildpackage: source package zookeeper
dpkg-buildpackage: source version 3.4.5-1
dpkg-buildpackage: error: unable to determine source changed by
~~~

# 6. 参考文章

- [1] [Building Bigtop on Ubuntu](https://cwiki.apache.org/confluence/display/BIGTOP/Building+Bigtop+on+Ubuntu)


