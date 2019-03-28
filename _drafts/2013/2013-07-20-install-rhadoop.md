---
layout: post
title:  安装RHadoop
category: hadoop
tags: [hadoop, rhadoop]
---

# 1. R Language Install

## 安装相关依赖

	yum install -y perl* pcre-devel tcl-devel zlib-devel bzip2-devel libX11-devel tk-devel tetex-latex *gfortran*  compat-readline5
	yum install libRmath-*
	rpm -Uvh --force --nodeps  R-core-2.10.0-2.el5.x86_64.rpm
	rpm -Uvh R-2.10.0-2.el5.x86_64.rpm R-devel-2.10.0-2.el5.x86_64.rpm

<!-- more -->

## 编译安装：R-3.0.1

	tar -zxvf R-3.0.1 
	./configure
	make 
	make install #R运行
	export HADOOP_CMD=/usr/bin/hadoop

## 排错

1、错误1

	error: --with-readline=yes (default) 

安装readline 

	yum install readline*

2、错误2

	error: No F77 compiler found 

安装gfortran

3、错误3

	error: –with-x=yes (default) and X11 headers/libs are not available 

安装

	yum install libXt*

4、错误4
	
	error: C++ preprocessor "/lib/cpp" fails sanity check 

安装g++或build-essential（redhat6.2安装gcc-c++和glibc-headers）

## 验证是否安装成功

	[root@node1 bin]# R
	R version 3.0.1 (2013-05-16) -- "Good Sport"
	Copyright (C) 2013 The R Foundation for Statistical Computing
	Platform: x86_64-unknown-linux-gnu (64-bit)

	R是自由软件，不带任何担保。
	在某些条件下你可以将其自由散布。
	用'license()'或'licence()'来看散布的详细条件。

	R是个合作计划，有许多人为之做出了贡献.
	用'contributors()'来看合作者的详细情况
	用'citation()'会告诉你如何在出版物中正确地引用R或R程序包。

	用'demo()'来看一些示范程序，用'help()'来阅读在线帮助文件，或
	用'help.start()'通过HTML浏览器来看帮助文件。
	用'q()'退出R.

# 2. 安装Rhadoop

## 安装rhdfs，rmr2

	cd Rhadoop/
	R CMD javareconf
	R CMD INSTALL 'plyr_1.8.tar.gz'
	R CMD INSTALL 'stringr_0.6.2.tar.gz'
	R CMD INSTALL 'reshape2_1.2.2.tar.gz'
	R CMD INSTALL 'digest_0.6.3.tar.gz'
	R CMD INSTALL 'functional_0.4.tar.gz'
	R CMD INSTALL 'iterators_1.0.6.tar.gz'
	R CMD INSTALL 'itertools_0.1-1.tar.gz'
	R CMD INSTALL 'Rcpp_0.10.3.tar.gz'
	R CMD INSTALL 'rJava_0.9-4.tar.gz'
	R CMD INSTALL 'RJSONIO_1.0-3.tar.gz'
	R CMD INSTALL 'reshape2_1.2.2.tar.gz'
	R CMD INSTALL 'rhdfs_1.0.5.tar.gz'
	R CMD INSTALL 'rmr2_2.2.0.tar.gz'

R library(rhdfs)检查是否能正常工作

## 验证测试

Rmr测试命令： 

	> train.mr<-mapreduce( + train.hdfs, + map = function(k, v) { + keyval(k,v$item) + } + ,reduce=function(k,v){ + m<-merge(v,v) + keyval(m$x,m$y) + } + )

出现如下错误：

	packageJobJar: [/tmp/RtmpCuhs7d/rmr-local-env18916b6f86b3, /tmp/RtmpCuhs7d/rmr-global-env18913824c681, /tmp/RtmpCuhs7d/rmr-streaming-map18912d6c2b1c, /tmp/RtmpCuhs7d/rmr-streaming-reduce1891179bb645, /tmp/hadoop-root/hadoop-unjar4575094085541826184/] [] /tmp/streamjob2910108622786868147.jar tmpDir=null 13/06/05 18:22:28
	WARN mapred.JobClient: Use GenericOptionsParser for parsing the arguments. Applications should implement Tool for the same. 13/06/05 18:22:28 INFO mapred.FileInputFormat: Total input paths to process : 1 13/06/05 18:22:29
	INFO streaming.StreamJob: getLocalDirs(): [/tmp/hadoop-root/mapred/local] 13/06/05 18:22:29 INFO streaming.StreamJob: Running job: job_201306050931_0004 13/06/05 18:22:29
	INFO streaming.StreamJob: To kill this job, run: 13/06/05 18:22:29
	INFO streaming.StreamJob: /usr/lib/hadoop/bin/hadoop job  -Dmapred.job.tracker=cdh1:8021 -kill job_201306050931_0004 13/06/05 18:22:29 INFO streaming.StreamJob: Tracking URL: http://cdh1:50030/jobdetails.jsp?jobid=job_201306050931_0004 13/06/05 18:22:30 
	INFO streaming.StreamJob:  map 0%  reduce 0% 13/06/05 18:22:56
	INFO streaming.StreamJob:  map 100%  reduce 100% 13/06/05 18:22:56
	INFO streaming.StreamJob: To kill this job, run: 13/06/05 18:22:56
	INFO streaming.StreamJob: /usr/lib/hadoop/bin/hadoop job  -Dmapred.job.tracker=cdh1:8021 -kill job_201306050931_0004 13/06/05 18:22:56
	INFO streaming.StreamJob: Tracking URL: http://cdh1:50030/jobdetails.jsp?jobid=job_201306050931_0004 13/06/05 18:22:56 
	ERROR streaming.StreamJob: Job not successful. Error: NA 13/06/05 18:22:56
	INFO streaming.StreamJob: killJob... Streaming Command Failed! Error in mr(map = map, reduce = reduce, combine = combine, vectorized.reduce,  :   hadoop streaming failed with error code 1

错误解决方法： 通过查看日志，hadoop没有在`/usr/bin`下找到Rscript,于是从R的安装目录`/usr/local/bin`下做R和Rscript的符号链接到`/usr/bin`下，再次执行即可解决次错。

	#ln -s /usr/loca/bin/R  /usr/bin
	#ln -s /usr/local/bin/Rscript  /usr/bin

# 3. 安装rhbase    
## 安装依赖
	
	#yum install boost*
	#yum install openssl*

## 安装thrift ##

	#tar -zxvf thrift-0.9.0.tar.gz
	#mv thrift-0.9.0/lib/cpp/src/thrift/qt/moc_TQTcpServer.cpp  thrift-0.9.0/lib/cpp/src/thrift/qt/moc_TQTcpServer.cpp.bak
	#cd thrift-0.9.0
	#./configure --with-boost=/usr/include/boost JAVAC=/usr/java/jdk1.6.0_31/bin/javac
	#make
	#make install

如果报错：error: "Error: libcrypto required."

	#yum install openssl*


如果报错：

	src/thrift/qt/moc_TQTcpServer.cpp:14:2: error: #error "This file was generated using the moc from 4.8.1. It"
	src/thrift/qt/moc_TQTcpServer.cpp:15:2: error: #error "cannot be used with the include files from this version of Qt."
	src/thrift/qt/moc_TQTcpServer.cpp:16:2: error: #error "(The moc has changed too much.)"

则运行下面命令：

	#mv thrift-0.9.0/lib/cpp/src/thrift/qt/moc_TQTcpServer.cpp  thrift-0.9.0/lib/cpp/src/thrift/qt/moc_TQTcpServer.cpp.bak

## 配置PKG_CONFIG_PATH

	export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig/
 	pkg-config --cflags thrift    #返回：-I/usr/local/include/thrift为正确
 	cp /usr/local/lib/libthrift-0.9.0.so /usr/lib/
 	cp /usr/local/lib/libthrift-0.9.0.so /usr/lib64/
 
启动hbase：

	/usr/lib/hbase/bin/hbase-daemon.sh  start  thrift 

使用jps查看thrift进程
 
## 安装rhbase

	R CMD INSTALL 'rhbase_1.1.1.tar.gz'

## 验证并测试 

在R命令行中输入library(rmr2)、library(rhdfs)、library(rhbase)，载入成功即表示安装成功

	[root@desktop27 hadoop]# R
	R version 3.0.1 (2013-05-16) -- "Good Sport"
	Copyright (C) 2013 The R Foundation for Statistical Computing
	Platform: x86_64-unknown-linux-gnu (64-bit)
	R is free software and comes with ABSOLUTELY NO WARRANTY.
	You are welcome to redistribute it under certain conditions.
	Type 'license()' or 'licence()' for distribution details.
	Natural language support but running in an English locale
	R is a collaborative project with many contributors.
	Type 'contributors()' for more information and
	'citation()' on how to cite R or R packages in publications.
	Type 'demo()' for some demos, 'help()' for on-line help, or
	'help.start()' for an HTML browser interface to help.
	Type 'q()' to quit R.
	> library(rhdfs)
	Loading required package: rJava
	HADOOP_CMD=/usr/bin/hadoop
	Be sure to run hdfs.init()
	> library(rmr2)
	Loading required package: Rcpp
	Loading required package: RJSONIO
	Loading required package: digest
	Loading required package: functional
	Loading required package: stringr
	Loading required package: plyr
	Loading required package: reshape2
	> library(rhbase)
	>

# 4. 装RHive

## 环境变量
设置环境变量 `vim /etc/profile`,末行添加如下：

	export HADOOP_CMD=/usr/bin/hadoop
	export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/
	export HADOOP_STREAMING=/usr/lib/hadoop-0.20-mapreduce/contrib/streaming/hadoop-streaming-2.0.0-mr1-cdh4.2.1.jar
	export HADOOP_HOME=/usr/lib/hadoop
	export RHIVE_DATA=/hadoop/dfs/rhive/data
	export HIVE_HOME=/usr/lib/hive

## 安装Rserve：

	#R CMD INSTALL 'Rserve_1.7-1.tar.gz'

在安装Rsever用户下，创建一目录，并创建Rserv.conf文件，写入``remote enable''保存并退出。

	#cd /usr/local/lib64/R/
	#echo remote enable > Rserv.conf

启动Rserve：

	#R CMD Rserve --RS-conf /usr/local/lib64/R/Rserv.conf

检查Rserve启动是否正常：

	#telnet localhost 6311

显示 Rsrv0103QAP1 则表示连接成功

## 安装RHive
创建数据目录：

	#R CMD INSTALL RHive_0.0-7.tar.gz
	#cd /usr/local/lib64/R/
	mkdir -p rhive/data

在上传rhive_udf.jar到hdfs上：

	hadoop fs -mkdir /rhive/lib
	cd /usr/local/lib64/R/library/RHive/java
	hadoop fs -put rhive_udf.jar /rhive/lib
	hadoop fs -chmod a+rw /rhive/lib/rhive_udf.jar
	cd /usr/lib/hadoop
	ln -s /etc/hadoop/conf conf

测试RHive安装是否成功：

	R
	library（RHive）
	rhive.connect('192.168.0.27')【hive的地址】
	rhive.env()


