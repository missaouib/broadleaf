---
layout: post

title:  2014年7月总结
date: 2014-07-31T08:00:00+08:00

description: 在休息了将近三个月之后，7月9日终于开始上班了，新的工作还是和 hadoop 相关。

keywords:  

categories: [  work ]

tags: []

published: true

---

在休息了将近三个月之后，7月9日终于开始上班了，新的工作还是和 hadoop 相关。7月主要的工作内容如下：

- 搭建新的 hadoop 集群，hadoop 版本为 CDH4.7.0，并配置 NameNode 的 QJM HA 方案。配置 HA 方法见 [CDH 中配置 HDFS HA](/2014/07/18/install-hdfs-ha-in-cdh.html)
- 购买了三本书：
	- mahout实战
	- 机器学习实战
	- 这才是搜索引擎
- 调研了 [flume-ng]() 日志采集方案
	- [大众点评的大数据实践](http://www.csdn.net/article/images-12-18/2817838-big-data-practice-in-dianping)
	- [analyzing-twitter-data-with-hadoop](http://blog.cloudera.com/blog/2012/09/analyzing-twitter-data-with-hadoop/)
	- [Hadoop Analysis of Apache Logs Using Flume-NG, Hive and Pig](http://cuddletech.com/?p=795)
	- [Log Files with Flume and Hive](http://www.lopakalogic.com/articles/hadoop-articles/log-files-flume-hive/)
	- [Solving Small Files Problem on CDH4](https://sskaje.me/images/12/solving-small-files-problem-cdh4/#.U8I48Y2SywI)
	- [flume-ng+Kafka+Storm+HDFS 实时系统搭建](http://blog.csdn.net/weijonathan/article/details/18301321)
	- [flume-ng+Hadoop实现日志收集](http://gdcsy.blog.163.com/blog/static/127343609201452532339253/)
	- [基于Flume的美团日志收集系统(一)架构和设计](http://tech.meituan.com/mt-log-system-arch.html)

- 查看关系数据库数据同步到 hadoop 的相关方法
   	- a. 查看sqoop 和 sqoop2 的相关文档
  	- b. 测试使用kettle 连接 hdfs 和 hive
- 熟悉原来 hadoop 数据同步和调度的代码逻辑，查看一些开源的任务调度框架：
	- <https://github.com/alibaba/zeus>
	- <https://github.com/thieman/dagobah>
	- <https://github.com/azkaban/azkaban>
	- <http://demo.gethue.com/>
- 熟悉 phoenix 用法（phoenix 为 HBase 提供 sql 支持），Phoenix 快速入门见[Phoenix Quick Start](/2014/07/28/phoenix-quick-start.html)
- 测试 impala 是否支持 hive 的自定义文件格式，见[Impala 新特性](/2014/07/29/new-features-in-impala.html)
- 完善下载日志文件并上传到 hive 的 python 脚本，见[采集日志到 hive](/2014/07/25/collect-log-to-hive.html)

另外萌生了一些想法，例如，开发一个java web 项目，支持 hive 查询、任务调度、查看 hdfs 等功能。可参考的资源：

- <https://github.com/dianping/hiveweb>
- <https://github.com/dianping/polestar>
