---
layout: post

title: Hive Over HBase的介绍
date: 2014-06-12T08:00:00+08:00

description: Hive Over HBase是基于Hive的HQL查询引擎支持对hbase表提供及时查询的功能，它并不是将hql语句翻译成mapreduce来运行，其响应时间在秒级别。

keywords: Hive over hbase是基于hive支持对hbase表提供直接查询功能

categories: [ hive ]

tags: [hbase,hive]

published: true

---

Hive Over HBase是基于Hive的HQL查询引擎支持对hbase表提供及时查询的功能，它并不是将hql语句翻译成mapreduce来运行，其响应时间在秒级别。

# 特性

支持的字段类型：

 boolean, tinyint, smallint, int, bigint, float, double, string, struct
(当hbase中的rowkey字段为struct类型，请将子字段定义为string类型，同时指定表的collection items terminated分隔字符以及各字段的长度参数:hbase.rowkey.column.length)

支持的sql语法：

- where子句
- group by，having子句
- 聚合函数: count, max, min, sum, avg
- order by with limit(top N)
- limit 子句
- explain

支持的运算

- 关系操作：>, >=, <=, <, =
- 算术操作：+, - , * , / , %
- 逻辑操作：and, or, not
- 字符串操作函数: substring, concat
- Distinct : 支持`select distinct <col-list> from <tab> where <expr>, select aggr-fun(distinct <col_list>) from <tab> where <expr>`
- Like: 通配符’_’, ’%’
- Case when子句

不支持:

- Sub-query
- Join
- Union

# 原理

扩展HBase客户端代码，实现[简单聚合计算](/2014/06/12/hbase-aggregate-client.html)，基于协作器实现分组计算的功能，并且修改hive的查询引擎，将HQL语句转换成HBase的Task，然后调用HBase中的api实现对HQL语句的解析。

# 源码

暂时不公开。
