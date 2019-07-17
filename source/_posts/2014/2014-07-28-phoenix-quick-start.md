---
layout: post

title:  Phoenix Quick Start

description: Phoenix 是 Salesforce.com 开源的一个 Java 中间件，可以让开发者在Apache HBase 上执行 SQL 查询。Phoenix完全使用Java编写，代码位于 GitHub 上，并且提供了一个客户端可嵌入的 JDBC 驱动。

keywords:  Phoenix,hbase

category:  hbase

tags: [hbase,phoenix]

published: true

---

# 1. 介绍

Phoenix 是 Salesforce.com 开源的一个 Java 中间件，可以让开发者在Apache HBase 上执行 SQL 查询。Phoenix完全使用Java编写，代码位于 GitHub 上，并且提供了一个客户端可嵌入的 JDBC 驱动。

> 根据项目所述，Phoenix 被 Salesforce.com 内部使用，对于简单的低延迟查询，其量级为毫秒；对于百万级别的行数来说，其量级为秒。Phoenix 并不是像 HBase 那样用于 map-reduce job 的，而是通过标准化的语言来访问 HBase 数据的。
>
>Phoenix 为 HBase 提供 SQL 的查询接口，它在客户端解析SQL语句，然后转换为 HBase native 的客户端语言，并行执行查询然后生成标准的JDBC结果集。

Phoenix [最值得关注的一些特性](http://phoenix-hbase.blogspot.com/images/01/announcing-phoenix-sql-layer-over-hbase.html) 有：

- 嵌入式的JDBC驱动，实现了大部分的java.sql接口，包括元数据API
- 可以通过多部行键或是键/值单元对列进行建模
- 完善的查询支持，可以使用多个谓词以及优化的扫描键
- DDL支持：通过CREATE TABLE、DROP TABLE及ALTER TABLE来添加/删除列
- 版本化的模式仓库：当写入数据时，快照查询会使用恰当的模式
- DML支持：用于逐行插入的UPSERT VALUES、用于相同或不同表之间大量数据传输的UPSERT SELECT、用于删除行的DELETE
- 通过客户端的批处理实现的有限的事务支持
- [表连接](http://phoenix.apache.org/joins.html) 和[二级索引](http://phoenix.apache.org/secondary_indexing.htm)
- 紧跟ANSI SQL标准

SQL Support 可以参考 [language reference](http://phoenix.apache.org/language/index.html)，Phoenix 当前不支持：

- 完全的事物支持
- 嵌套查询
- 关联操作: Union、Intersect、Minus
- 各种各样的内建函数。可以参考[这篇文章](http://phoenix-hbase.blogspot.com/images/04/how-to-add-your-own-built-in-function.html)添加自定义函数。


# 2. 安装

HBase 兼容性：

- Phoenix 2.x - HBase 0.94.x
- Phoenix 3.x - HBase 0.94.x
- Phoenix 4.x - HBase 0.98.1+


安装已经编译好的 phoenix ：

- 下载对应你 hbase 版本的 phoenix-[version]-incubating.tar 并解压，下载地址：<http://www.apache.org/dyn/closer.cgi/incubator/phoenix/>。
- 添加 phoenix-core-[version]-incubating.jar 到 HBase region server 的 classpath 中，或者直接将其加载到 hbase 的 lib 目录
- 重启 HBase region server
- 添加 phoenix-[version]-incubating-client.jar 到 hadoop 客户端的 lib 目录。

# 3. 使用

## 3.1 JDBC

Java 客户端连接 jdbc 代码如下：

~~~java
Connection conn = DriverManager.getConnection("jdbc:phoenix:server1,server2:2181");
~~~

jdbc 的 url 类似为 `jdbc:phoenix [ :<zookeeper quorum> [ :<port number> ] [ :<root node> ] ]`，需要引用三个参数：`hbase.zookeeper.quorum`、`hbase.zookeeper.property.clientPort`、`and zookeeper.znode.parent`，这些参数可以缺省不填而在 hbase-site.xml 中定义。

## 3.2 sqlline 命令行

进入解压后的 bin 目录，执行下面命令可以进入一个命令行模式：

~~~bash
$ sqlline.py localhost
~~~

进入之后，可以查看表和列：

~~~sql
sqlline version 1.1.2
0: jdbc:phoenix:localhost> !tables
+------------+-------------+------------+------------+------------+------------+---------------------------+----------------+--------+
| TABLE_CAT  | TABLE_SCHEM | TABLE_NAME | TABLE_TYPE |  REMARKS   | TYPE_NAME  | SELF_REFERENCING_COL_NAME | REF_GENERATION | INDEX_ |
+------------+-------------+------------+------------+------------+------------+---------------------------+----------------+--------+
| null       | SYSTEM      | CATALOG    | SYSTEM TABLE | null       | null       | null                      | null           | null |
| null       | SYSTEM      | SEQUENCE   | SYSTEM TABLE | null       | null       | null                      | null           | null |
+------------+-------------+------------+------------+------------+------------+---------------------------+----------------+--------+
0: jdbc:phoenix:localhost> !columns sequence
+------------+-------------+------------+-------------+------------+------------+-------------+---------------+----------------+-----+
| TABLE_CAT  | TABLE_SCHEM | TABLE_NAME | COLUMN_NAME | DATA_TYPE  | TYPE_NAME  | COLUMN_SIZE | BUFFER_LENGTH | DECIMAL_DIGITS | NUM |
+------------+-------------+------------+-------------+------------+------------+-------------+---------------+----------------+-----+
| null       | SYSTEM      | SEQUENCE   | TENANT_ID   | 12         | VARCHAR    | null        | null          | null           | nul |
+------------+-------------+------------+-------------+------------+------------+-------------+---------------+----------------+-----+
0: jdbc:phoenix:localhost>
~~~

从上面可以看出来，phoenix 中存在两个系统表：

- SYSTEM.CATALOG
- SYSTEM.SEQUENCE

通过 HBase Master 的 web 页面，可以看到上面两个表的建表语句，例如：

~~~
'SYSTEM.CATALOG', {METHOD => 'table_att', coprocessor$1 => '|org.apache.phoenix.coprocessor.ScanRegionObserver|1|', coprocessor$2 => '|org.apache.phoenix.coprocessor.UngroupedAggregateRegionObserver|1|', coprocessor$3 => '|org.apache.phoenix.coprocessor.GroupedAggregateRegionObserver|1|', coprocessor$4 => '|org.apache.phoenix.coprocessor.ServerCachingEndpointImpl|1|', coprocessor$5 => '|org.apache.phoenix.coprocessor.MetaDataEndpointImpl|1|', coprocessor$6 => '|org.apache.phoenix.coprocessor.MetaDataRegionObserver|2|', CONFIG => {'SPLIT_POLICY' => 'org.apache.phoenix.schema.MetaDataSplitPolicy', 'UpgradeTo30' => 'true'}}, {NAME => '0', DATA_BLOCK_ENCODING => 'FAST_DIFF', VERSIONS => '1000', KEEP_DELETED_CELLS => 'true'}
~~~

可以用下面脚本执行一个 sql 语句：

~~~bash
$ ./sqlline.py localhost ../examples/STOCK_SYMBOL.sql
~~~

执行结果如下：

~~~sql
1/4          /*
* Licensed to the Apache Software Foundation (ASF) under one
* or more contributor license agreements.  See the NOTICE file
* distributed with this work for additional information
* regarding copyright ownership.  The ASF licenses this file
* to you under the Apache License, Version 2.0 (the
* "License"); you may not use this file except in compliance
* with the License.  You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

-- creates stock table with single row
CREATE TABLE IF NOT EXISTS STOCK_SYMBOL (SYMBOL VARCHAR NOT NULL PRIMARY KEY, COMPANY VARCHAR);
No rows affected (1.714 seconds)
2/4          UPSERT INTO STOCK_SYMBOL VALUES ('CRM','SalesForce.com');
1 row affected (0.035 seconds)
3/4          SELECT * FROM STOCK_SYMBOL;
+------------+------------+
|   SYMBOL   |  COMPANY   |
+------------+------------+
| CRM        | SalesForce.com |
+------------+------------+
1 row selected (0.117 seconds)
4/4
Closing: org.apache.phoenix.jdbc.PhoenixConnection
sqlline version 1.1.2
~~~

../examples/STOCK_SYMBOL.sql 文件主要包括三个 sql 语句：

~~~sql
CREATE TABLE IF NOT EXISTS STOCK_SYMBOL (SYMBOL VARCHAR NOT NULL PRIMARY KEY, COMPANY VARCHAR);
UPSERT INTO STOCK_SYMBOL VALUES ('CRM','SalesForce.com');
SELECT * FROM STOCK_SYMBOL;
~~~

- 第一个语句创建表
- 第二个语句插入一条记录
- 第三个语句查询数据

在 hbase shell 中查看存在的表：

~~~bash
hbase(main):001:0> list
TABLE
STOCK_SYMBOL
SYSTEM.CATALOG
SYSTEM.SEQUENCE
~~~

查看 `STOCK_SYMBOL` 表中数据：

~~~bash
hbase(main):004:0> scan 'STOCK_SYMBOL'
ROW                                COLUMN+CELL
 CRM                               column=0:COMPANY, timestamp=1406535419510, value=SalesForce.com
 CRM                               column=0:_0, timestamp=1406535419510, value=
1 row(s) in 0.0210 seconds
~~~

可以看到插入了一行记录，rowkey 为 CRM，而列族名称为 0 ，存在两列，一列为指定的COMPANY，另一列为 phoenix 插入的 `_0` 

然后，也可以通过 sqlline.py 来查看数据：

~~~sql
0: jdbc:phoenix:localhost> select * from STOCK_SYMBOL;
+------------+------------+
|   SYMBOL   |  COMPANY   |
+------------+------------+
| CRM        | SalesForce.com |
+------------+------------+
1 row selected (0.144 seconds)
~~~

注意到：从上面查询看到的就只有两列，没有看到 `_0` 这一列。

从上可以知道，Phoenix 是构建在 HBase 之上的 SQL 中间层，向 HBase 发送标准 sql 语句，对 HBase 进行操作。

## 3.3 加载数据

你可以使用 bin/psql.py 来加载 CSV 数据 或者执行 SQL 脚本，例如：

~~~bash
$ ./psql.py localhost ../examples/WEB_STAT.sql ../examples/WEB_STAT.csv ../examples/WEB_STAT_QUERIES.sql
~~~

其输出结果为：

~~~
no rows upserted
Time: 1.528 sec(s)

csv columns from database.
CSV Upsert complete. 39 rows upserted
Time: 0.122 sec(s)

DOMAIN     AVERAGE_CPU_USAGE AVERAGE_DB_USAGE
---------- ----------------- ----------------
Salesforce.com       260.727          257.636
Google.com           212.875           213.75
Apple.com            114.111          119.556
Time: 0.062 sec(s)

DAY                 TOTAL_CPU_USAGE MIN_CPU_USAGE MAX_CPU_USAGE
------------------- --------------- ------------- -------------
2013-01-01 00:00:00              35            35            35
2013-01-02 00:00:00             150            25           125
2013-01-03 00:00:00              88            88            88
2013-01-04 00:00:00              26             3            23
2013-01-05 00:00:00             550            75           475
2013-01-06 00:00:00              12            12            12
2013-01-08 00:00:00             345           345           345
2013-01-09 00:00:00             390            35           355
2013-01-10 00:00:00             345           345           345
2013-01-11 00:00:00             335           335           335
2013-01-12 00:00:00               5             5             5
2013-01-13 00:00:00             355           355           355
2013-01-14 00:00:00               5             5             5
2013-01-15 00:00:00             720            65           655
2013-01-16 00:00:00             785           785           785
2013-01-17 00:00:00            1590           355          1235
Time: 0.045 sec(s)

HOST TOTAL_ACTIVE_VISITORS
---- ---------------------
EU                     150
NA                       1
Time: 0.058 sec(s)
~~~

WEB_STAT.sql 中 sql 语句为：

~~~sql
CREATE TABLE IF NOT EXISTS WEB_STAT (
     HOST CHAR(2) NOT NULL,
     DOMAIN VARCHAR NOT NULL,
     FEATURE VARCHAR NOT NULL,
     DATE DATE NOT NULL,
     USAGE.CORE BIGINT,  -- 指定了列族： USAGE
     USAGE.DB BIGINT,	-- 指定了列族： USAGE
     STATS.ACTIVE_VISITOR INTEGER ,  --指定了列族： STATS
     CONSTRAINT PK PRIMARY KEY (HOST, DOMAIN, FEATURE, DATE)
);
~~~

从 sql 语句上可以看出来，HOST、DOMAIN、FEATURE、DATE 这四列前面并没有指定列族，并且通过约束设置这四列组成 hbase 的 rowkey，其他三列都指定了列族。

通过 sqlline.py 查询第一条记录：

~~~sql
0: jdbc:phoenix:localhost> select * from WEB_STAT limit 1;
+------+------------+------------+---------------------+------------+------------+----------------+
| HOST |   DOMAIN   |  FEATURE   |        DATE         |    CORE    |     DB     | ACTIVE_VISITOR |
+------+------------+------------+---------------------+------------+------------+----------------+
| EU   | Apple.com  | Mac        | 2013-01-01          | 35         | 22         | 34             |
+------+------------+------------+---------------------+------------+------------+----------------+
~~~

而通过 hbase shell 查询 `WEB_STAT` 表第一条记录：

~~~
 EUApple.com\x00Mac\x00\x80\x00\x0 column=STATS:ACTIVE_VISITOR, timestamp=1406535785946, value=\x80\x00\x00"
 1;\xF3\xA04\xC8
 EUApple.com\x00Mac\x00\x80\x00\x0 column=USAGE:CORE, timestamp=1406535785946, value=\x80\x00\x00\x00\x00\x00\x00#
 1;\xF3\xA04\xC8
 EUApple.com\x00Mac\x00\x80\x00\x0 column=USAGE:DB, timestamp=1406535785946, value=\x80\x00\x00\x00\x00\x00\x00\x16
 1;\xF3\xA04\xC8
 EUApple.com\x00Mac\x00\x80\x00\x0 column=USAGE:_0, timestamp=1406535785946, value=
 1;\xF3\xA04\xC8
~~~

通过上面对比知道：

- phoenix 对用户屏蔽了 rowkey 的设计细节
- USAGE 列族中存在一列为 `_0`，而 STATS 列族中却没有，**这是为什么？**
- Phoenix 把 rowkey 内化为 table 的 PRIMARY KEY 处理，由 HOST、DOMAIN、FEATURE、DATE 这四列拼接在一起，组成了 rowkey

其他可选的加载数据的方法：

- 使用 [map-reduce based CSV loader](http://phoenix.apache.org/bulk_dataload.html) 加载更大的数据
- [映射一个存在的 HBase 表到 Phoenix 表](http://phoenix.apache.org/index.html#Mapping-to-an-Existing-HBase-Table) 以及使用  [UPSERT SELECT](http://phoenix.apache.org/language/index.html#upsert_select) 来创建一个新表
- 使用 [UPSERT VALUES](http://phoenix.apache.org/language/index.html#upsert_values) 插入记录

## 3.4 映射到存在的 HBase 表

创建一张hbase表：

~~~
create 't1', 'f'

put 't1', "row1", 'f:q', 1
put 't1', "row2", 'f:q', 2
put 't1', "row3", 'f:q', 3
put 't1', "row4", 'f:q', 4
put 't1', "row5", 'f:q', 5
~~~

在phoenix建一张同样的表：

~~~sql
./sqlline.py localhost 

CREATE TABLE IF NOT EXISTS "t1" (
     row VARCHAR NOT NULL,
     "f"."q" VARCHAR
     CONSTRAINT PK PRIMARY KEY (row)
);

~~~

t1、f、q 需要用双引号括起来，原因主要是大小写的问题，参考 phoenix 的 [wiki](https://github.com/forcedotcom/phoenix/wiki)。

>**注意：**
>
> 在这里， phoenix 会修改 table 的 Descriptor，然后添加 coprocessor，所以会先 disable，在 modify，最后 enable 表。

接下来就可以查询了：

~~~sql
0: jdbc:phoenix:localhost> select * from "t1";
+------------+------------+
|    ROW     |     q      |
+------------+------------+
| row1       | 1          |
| row2       | 2          |
| row3       | 3          |
| row4       | 4          |
| row5       | 5          |
+------------+------------+
5 rows selected (0.101 seconds)
0: jdbc:phoenix:localhost> select count(1) from "t1";
+------------+
|  COUNT(1)  |
+------------+
| 5          |
+------------+
1 row selected (0.068 seconds)
~~~

# 4. 总结

这篇文章主要是介绍了什么是 Phoenix 、如何安装以及他的一些特性，然后介绍了他的使用方法，主要包括命令行使用、加载数据以及如何映射存在的 HBase 表，通过该篇文章对 Phoenix 有了一个初步的认识。
