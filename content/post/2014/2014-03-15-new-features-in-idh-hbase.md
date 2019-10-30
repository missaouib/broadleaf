---
layout: post

title: IDH HBase中实现的一些特性
date: 2014-03-15T08:00:00+08:00

description: IDH HBase中实现的一些特性

keywords: 

categories: [ hbase ]

tags: [hbase]

published: true

---

IDH为Intel's Distribution of Hadoop的简称，中文为英特尔Hadoop发行版，目前应该没有人在维护该产品了。这里简单介绍一下IDH HBase中实现的一些特性。

以下部分内容摘自IDH官方的一些文档，部分内容来自我的整理：


1、 单调数据的加盐处理

对于写入的rowkey是基本单调的（例如时序数据），IDH引入了一个新的接口：SaltedTableInterface

- 提高近乎透明的“加盐”，方便使用
- 封装了get、scan、put、delete等操作

2、提供了Rolling Scanner应对HFile数量大量增加情况下的get、scan性能

3、提供了ParallelClientScanner加速大范围查询性能

具体实现，请参考[HBase客户端实现并行扫描](/2014/06/12/hbase-parallel-client-scanner.html)

4、使得协作器实用化，从而可使用协作器来进行计算

相关说明，可以参考[HBase实现简单聚合计算](/2014/06/12/hbase-aggregate-client.html)

5、提供基于lucene的全文检索

6、提供大对象的高效存储

- 类似Oracle的BLOB存储
- 对用户透明
- 2x以上的写入性能，还有些进步空间
- 2x的随机访问性能
- 1.3x的scan性能
- 接近直接写入hdfs性能

7、引入交互式的hive over hbase

- 完全的hive支持，常用功能（select、group by、top n等等）用hbase协作器实现，其余功能（大表关联等等）用mapreduce无缝对接
- 去除mapreduce的overhead，大大地减少了数据传输
- 性能有3x-10x提升

具体介绍，请参考[Hive Over HBase的介绍](/2014/06/12/intro-of-hive-over-hbase.html)

8、支持跨数据中心的大表

9、HBase中支持对某列族设置副本数

10、可以通过定时任务设置文件压缩合并频率

