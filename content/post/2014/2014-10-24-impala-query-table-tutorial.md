---
layout: post

title:  Impala查询功能测试
date: 2014-10-24T08:00:00+08:00

description:  关于 Impala 使用方法的一些测试，包括加载数据、查看数据库、聚合关联查询、子查询等等。

keywords:  hadoop

categories: [  impala ]

tags: [impala]

published: true 

---

关于 Impala 使用方法的一些测试，包括加载数据、查看数据库、聚合关联查询、子查询等等。

# 1. 准备测试数据

以下测试以 impala 用户来运行：

~~~
$ su - impala
-bash-4.1$ whoami
impala
$ hdfs dfs -ls /user
Found 5 items
drwxr-xr-x   - hdfs   hadoop          0 2014-09-22 18:36 /user/hdfs
drwxrwxrwt   - mapred hadoop          0 2014-07-23 21:37 /user/history
drwxr-xr-x   - hive   hadoop          0 2014-08-04 16:57 /user/hive
drwxr-xr-x   - impala hadoop          0 2014-10-24 10:13 /user/impala
drwxr-xr-x   - root   hadoop          0 2014-09-22 10:22 /user/root
~~~

准备一些测试数据，tab1.csv 文件内容如下：

~~~
1,true,123.123,2012-10-24 08:55:00 
2,false,1243.5,2012-10-25 13:40:00
3,false,24453.325,2008-08-22 09:33:21.123
4,false,243423.325,2007-05-12 22:32:21.33454
5,true,243.325,1953-04-22 09:11:33
~~~

tab1.csv 文件内容如下：

~~~
1,true,12789.123
2,false,1243.5
3,false,24453.325
4,false,2423.3254
50,true,243.325
60,false,243565423.325
70,true,243.325
80,false,243423.325
90,true,243.325
~~~

将这两个表上传到 hdfs：

~~~bash
$ hdfs dfs -mkdir -p sample_data/tab1 sample_data/tab2

$ hdfs dfs -put tab1.csv /user/impala/sample_data/tab1
$ hdfs dfs -ls /user/impala/sample_data/tab1
Found 1 items
-rw-r--r--   3 impala hadoop        193 2014-10-24 10:13 /user/impala/sample_data/tab1/tab1.csv

$ hdfs dfs -put tab2.csv /user/impala/sample_data/tab2
$ hdfs dfs -ls /user/impala/sample_data/tab2
Found 1 items
-rw-r--r--   3 impala hadoop        158 2014-10-24 10:13 /user/impala/sample_data/tab2/tab2.csv
~~~

在 impala 中建表，建表语句如下：

~~~sql
DROP TABLE IF EXISTS tab1;
CREATE EXTERNAL TABLE tab1 (
   id INT,
   col_1 BOOLEAN,
   col_2 DOUBLE,
   col_3 TIMESTAMP
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/user/impala/sample_data/tab1';

DROP TABLE IF EXISTS tab2;
CREATE EXTERNAL TABLE tab2 (
   id INT,
   col_1 BOOLEAN,
   col_2 DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/user/impala/sample_data/tab2';

DROP TABLE IF EXISTS tab3;
CREATE TABLE tab3 (
   id INT,
   col_1 BOOLEAN,
   col_2 DOUBLE,
   month INT,
   day INT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';
~~~

其中 tab1 和 tab2 都是外部表，tab3 是内部表。

将上面 sql 保存在 init.sql 语句，然后运行下面命令进行创建表：

~~~bash
$ impala-shell -i localhost -f init.sql
~~~

也可以进入到 impala-shell 命令行模式，直接运行 sql 语句。

# 2. 查看表结构

查看所有数据库：

~~~bash
[192.168.56.121:21000] > show databases;
Query: show databases
+------------------+
| name             |
+------------------+
| _impala_builtins |
| default          |          
| testdb           |
+------------------+
Returned 3 row(s) in 0.05s
~~~

查看默认数据库下的所有表：

~~~bash
[192.168.56.121:21000] > show tables;
Query: show tables
+------+
| name |
+------+
| tab1 |
| tab2 |
| tab3 |
+------+
Returned 3 row(s) in 0.01s
~~~

查看 tab1 表结构：

~~~bash
[192.168.56.121:21000] > describe tab1;
Query: describe tab1
+-------+-----------+---------+
| name  | type      | comment |
+-------+-----------+---------+
| id    | int       |         |
| col_1 | boolean   |         |
| col_2 | double    |         |
| col_3 | timestamp |         |
+-------+-----------+---------+
Returned 4 row(s) in 0.07s
~~~

# 3. impala-shell 命令

使用 impala-shell 进入命令行交互模式：

~~~bash
$ impala-shell -i localhost
~~~

传入一个文件：

~~~bash
$ impala-shell -i localhost -f init.sql
~~~

执行指定的 sql：

~~~bash
$ impala-shell -i localhost -q 'select count(*) from tab1;'
~~~

# 4. 导入数据并查询

导入数据：

- 准备数据
- 创建表
- 加数据导入到创建的表

查询数据：

~~~
[192.168.56.121:21000] > SELECT * FROM tab1;
Query: select * FROM tab1
+----+-------+------------+-------------------------------+
| id | col_1 | col_2      | col_3                         |
+----+-------+------------+-------------------------------+
| 1  | true  | 123.123    | 2012-10-24 08:55:00           |
| 2  | false | 1243.5     | 2012-10-25 13:40:00           |
| 3  | false | 24453.325  | 2008-08-22 09:33:21.123000000 |
| 4  | false | 243423.325 | 2007-05-12 22:32:21.334540000 |
| 5  | true  | 243.325    | 1953-04-22 09:11:33           |
+----+-------+------------+-------------------------------+
Returned 5 row(s) in 0.24s
[192.168.56.121:21000] > SELECT * FROM tab2;
Query: select * FROM tab2
+----+-------+---------------+
| id | col_1 | col_2         |
+----+-------+---------------+
| 1  | true  | 12789.123     |
| 2  | false | 1243.5        |
| 3  | false | 24453.325     |
| 4  | false | 2423.3254     |
| 50 | true  | 243.325       |
| 60 | false | 243565423.325 |
| 70 | true  | 243.325       |
| 80 | false | 243423.325    |
| 90 | true  | 243.325       |
+----+-------+---------------+
Returned 9 row(s) in 0.44s
[192.168.56.121:21000] > SELECT * FROM tab2 LIMIT 5;
Query: select * FROM tab2 LIMIT 5
+----+-------+-----------+
| id | col_1 | col_2     |
+----+-------+-----------+
| 1  | true  | 12789.123 |
| 2  | false | 1243.5    |
| 3  | false | 24453.325 |
| 4  | false | 2423.3254 |
| 50 | true  | 243.325   |
+----+-------+-----------+
Returned 5 row(s) in 0.44s
~~~

带 OFFSET 语句查询

> 带 OFFSET 语句查询，需要和 order by 一起使用，起始编号从 0 开始往后偏移，offset 为 0 时，其结果和去掉 offset 的 limit 结果一致。

测试如下：

~~~bash
[192.168.56.121:21000] > SELECT * FROM tab2 order by id LIMIT 3 offset 0;
Query: select * FROM tab2 order by id LIMIT 3 offset 0
+----+-------+-----------+
| id | col_1 | col_2     |
+----+-------+-----------+
| 1  | true  | 12789.123 |
| 2  | false | 1243.5    |
| 3  | false | 24453.325 |
+----+-------+-----------+
Returned 3 row(s) in 0.45s
[192.168.56.121:21000] > SELECT * FROM tab2 order by id LIMIT 3 offset 2;
Query: select * FROM tab2 order by id LIMIT 3 offset 2
+----+-------+-----------+
| id | col_1 | col_2     |
+----+-------+-----------+
| 3  | false | 24453.325 |
| 4  | false | 2423.3254 |
| 50 | true  | 243.325   |
+----+-------+-----------+
Returned 3 row(s) in 0.45s
~~~

# 5. join 连接查询

## 5.1 左外连接：

~~~bash
[192.168.56.121:21000] > SELECT tab1.id,tab1.col_1,tab2.col_2 FROM tab1 LEFT OUTER JOIN tab2 USING (id);
+----+-------+-----------+
| id | col_1 | col_2     |
+----+-------+-----------+
| 1  | true  | 12789.123 |
| 2  | false | 1243.5    |
| 3  | false | 24453.325 |
| 4  | false | 2423.3254 |
| 5  | true  | NULL      |
+----+-------+-----------+
Returned 5 row(s) in 1.12s
~~~

以上 SQL 语句等同于下面语句，用法同样适用于多个字段：

~~~sql
SELECT tab1.id,tab1.col_1,tab2.col_2 FROM tab1 LEFT OUTER JOIN tab2 where tab1.id=tab2.id;
~~~

由上可以看到左边表 tab1 的记录都查询出来了，右边表 tab2 只查询出跟 tab1 关联的记录。

## 5.2 内连接

~~~bash
[192.168.56.121:21000] > SELECT tab1.id,tab1.col_1,tab2.col_2 FROM tab1 INNER JOIN tab2 USING (id);
+----+-------+-----------+
| id | col_1 | col_2     |
+----+-------+-----------+
| 1  | true  | 12789.123 |
| 2  | false | 1243.5    |
| 3  | false | 24453.325 |
| 4  | false | 2423.3254 |
+----+-------+-----------+
Returned 4 row(s) in 0.53s
~~~

以上语句可以修改为：

~~~sql
-- 下面语句都是内连接
SELECT tab1.id,tab1.col_1,tab2.col_2 FROM tab1 JOIN tab2 USING (id);
SELECT tab1.id,tab1.col_1,tab2.col_2 FROM tab1 , tab2 where tab1.id=tab2.id ;
~~~

查询结果为：

~~~bash
[192.168.56.121:21000] > SELECT tab1.id,tab1.col_1,tab2.col_2 FROM tab1 , tab2 where tab1.id=tab2.id ;
Query: select tab1.id,tab1.col_1,tab2.col_2 FROM tab1 , tab2 where tab1.id=tab2.id
+----+-------+-----------+
| id | col_1 | col_2     |
+----+-------+-----------+
| 1  | true  | 12789.123 |
| 2  | false | 1243.5    |
| 3  | false | 24453.325 |
| 4  | false | 2423.3254 |
+----+-------+-----------+
Returned 4 row(s) in 0.38s
~~~

如果去掉 where 语句，会提示错误：

~~~bash
[192.168.56.121:21000] > select tab1.id,tab1.col_1,tab2.col_2 FROM tab1 , tab2;
Query: select tab1.id,tab1.col_1,tab2.col_2 FROM tab1 , tab2
ERROR: NotImplementedException: Join with 'default.tab2' requires at least one conjunctive equality predicate. To perform a Cartesian product between two tables, use a CROSS JOIN.
~~~

## 5.3 自连接

impala 允许自连接，例如：

~~~sql
-- Combine fields from both parent and child rows.
SELECT lhs.id, rhs.parent, lhs.c1, rhs.c2 FROM tree_data lhs, tree_data rhs WHERE lhs.id = rhs.parent;
~~~

## 5.4 交叉连接

为了避免产生大量的结果集，impala 不允许下面形式的笛卡尔连接：

~~~sql
SELECT ... FROM t1 JOIN t2;
SELECT ... FROM t1, t2;
~~~

如果，你的确想使用笛卡尔连接，建议使用 cross join：

~~~bash
[192.168.56.121:21000] > select tab1.id,tab1.col_1,tab2.col_2 FROM tab1 CROSS JOIN tab2 where tab1.id<3;
Query: select tab1.id,tab1.col_1,tab2.col_2 FROM tab1 CROSS JOIN tab2 where tab1.id<3
+----+-------+---------------+
| id | col_1 | col_2         |
+----+-------+---------------+
| 1  | true  | 12789.123     |
| 1  | true  | 1243.5        |
| 1  | true  | 24453.325     |
| 1  | true  | 2423.3254     |
| 1  | true  | 243.325       |
| 1  | true  | 243565423.325 |
| 1  | true  | 243.325       |
| 1  | true  | 243423.325    |
| 1  | true  | 243.325       |
| 2  | false | 12789.123     |
| 2  | false | 1243.5        |
| 2  | false | 24453.325     |
| 2  | false | 2423.3254     |
| 2  | false | 243.325       |
| 2  | false | 243565423.325 |
| 2  | false | 243.325       |
| 2  | false | 243423.325    |
| 2  | false | 243.325       |
+----+-------+---------------+
Returned 18 row(s) in 0.41s
~~~

## 5.5 等值连接和非等值连接

默认地，impala的两表连接需要一个等值的比较，或者使用 ON、USING、WHERE 语句。在Impala 1.2.2 之后，非等值连接也支持。同样需要避免因为产生大量的结果集而造成内存溢出。一旦你想使用非等值连接，建议使用 cross 连接并增加额外的 where 语句。

~~~bash
[192.168.56.121:21000] > select tab1.id,tab1.col_1,tab1.col_2,tab2.col_2 FROM tab1 CROSS JOIN tab2 where tab1.col_2 >tab2.col_2 ;
+----+-------+------------+-----------+
| id | col_1 | col_2      | col_2     |
+----+-------+------------+-----------+
| 2  | false | 1243.5     | 243.325   |
| 2  | false | 1243.5     | 243.325   |
| 2  | false | 1243.5     | 243.325   |
| 3  | false | 24453.325  | 12789.123 |
| 3  | false | 24453.325  | 1243.5    |
| 3  | false | 24453.325  | 2423.3254 |
| 3  | false | 24453.325  | 243.325   |
| 3  | false | 24453.325  | 243.325   |
| 3  | false | 24453.325  | 243.325   |
| 4  | false | 243423.325 | 12789.123 |
| 4  | false | 243423.325 | 1243.5    |
| 4  | false | 243423.325 | 24453.325 |
| 4  | false | 243423.325 | 2423.3254 |
| 4  | false | 243423.325 | 243.325   |
| 4  | false | 243423.325 | 243.325   |
| 4  | false | 243423.325 | 243.325   |
+----+-------+------------+-----------+
Returned 16 row(s) in 0.41s
~~~

查询出来的结果会有一些重复的记录，这个时候可以通过 distinct 去重。

## 5.6 半连接

左半连接是为了实现 in 语句，左边的记录会查询出来，而不管右边表有多少匹配的记录。Impala 2.0版本之后，支持右半连接。

~~~bash
[192.168.56.121:21000] > SELECT tab1.id,tab1.col_1,tab2.col_2 FROM tab1 LEFT SEMI JOIN tab2 USING (id);
Query: select tab1.id,tab1.col_1,tab2.col_2 FROM tab1 LEFT SEMI JOIN tab2 USING (id)
+----+-------+-----------+
| id | col_1 | col_2     |
+----+-------+-----------+
| 1  | true  | 12789.123 |
| 2  | false | 1243.5    |
| 3  | false | 24453.325 |
| 4  | false | 2423.3254 |
+----+-------+-----------+
Returned 4 row(s) in 0.41s
~~~

## 5.7 自然连接（不支持）

Impala 不支持 NATURAL JOIN 操作，以避免产生不一致或者大量的结果。自然连接不适应 ON 和 USING 语句，而是自动的关联所有列相同值的记录。这种连接是不建议的，特别是当表结构发生变化的时候，如添加或者删除列的时候，会产生不一样的结果集。

~~~sql
-- 'NATURAL' is interpreted as an alias for 't1' and Impala attempts an inner join,
-- resulting in an error because inner joins require explicit comparisons between columns.
SELECT t1.c1, t2.c2 FROM t1 NATURAL JOIN t2;
ERROR: NotImplementedException: Join with 't2' requires at least one conjunctive equality predicate.
  To perform a Cartesian product between two tables, use a CROSS JOIN.

-- If you expect the tables to have identically named columns with matching values,
-- list the corresponding column names in a USING clause.
SELECT t1.c1, t2.c2 FROM t1 JOIN t2 USING (id, type_flag, name, address);
~~~

## 5.8 反连接（Impala 2.0 / CDH 5.2 以上版本）

Impala 2.0 / CDH 5.2 以上版本中支持反连接，包括左反连接和右反连接。左反连接的意思是返回左边表不在右边表中的记录。

找出 tab2 的 id 不在 tab1 中的记录：

~~~bash
[192.168.56.121:21000] > SELECT tab2.id FROM tab2 LEFT ANTI JOIN tab1 USING (id);
+----+
| id |
+----+
| 50 |
| 60 |
| 70 |
| 80 |
| 90 |
+----+
Returned 5 row(s) in 0.41s
~~~

# 6. 聚合查询

聚合关联查询：

~~~bash
[192.168.56.121:21000] > select tab1.col_1, MAX(tab2.col_2), MIN(tab2.col_2) FROM tab2 JOIN tab1 USING (id) GROUP BY col_1 ORDER BY 1 LIMIT 5 ;
+-------+-----------------+-----------------+
| col_1 | max(tab2.col_2) | min(tab2.col_2) |
+-------+-----------------+-----------------+
| false | 24453.325       | 1243.5          |
| true  | 12789.123       | 12789.123       |
+-------+-----------------+-----------------+
~~~

聚合关联子查询：

~~~bash
[192.168.56.121:21000] > select tab2.* FROM tab2, (SELECT tab1.col_1, MAX(tab2.col_2) AS max_col2 FROM tab2, tab1 WHERE tab1.id = tab2.id GROUP BY col_1) subquery1 WHERE subquery1.max_col2 = tab2.col_2 ;
+----+-------+-----------+
| id | col_1 | col_2     |
+----+-------+-----------+
| 1  | true  | 12789.123 |
| 3  | false | 24453.325 |
+----+-------+-----------+
Returned 2 row(s) in 0.54s
~~~

Impala 2版本中，支持where 条件子查询，包括 IN 、EXISTS 和比较符的子查询：

~~~sql
select tab2.* from tab2 where tab2.id IN (select max(id) from tab1)
select tab2.* from tab2 where tab2.id EXISTS (select max(id) from tab1)
select tab2.* from tab2 where tab2.id > (select max(id) from tab1)
~~~

插入查询：

~~~bash
[192.168.56.121:21000] > insert OVERWRITE TABLE tab3 SELECT id, col_1, col_2, MONTH(col_3), DAYOFMONTH(col_3) FROM tab1 WHERE YEAR(col_3) = 2012 ;
Inserted 2 rows in 0.44s
~~~

这时候查询 tab3 的记录：

~~~bash
[192.168.56.121:21000] > SELECT * FROM tab3;
+----+-------+---------+-------+-----+
| id | col_1 | col_2   | month | day |
+----+-------+---------+-------+-----+
| 1  | true  | 123.123 | 10    | 24  |
| 2  | false | 1243.5  | 10    | 25  |
+----+-------+---------+-------+-----+
~~~

# 7. 参考文章

- [Cloudera Impala Guide - Impala Joins](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/impala_joins.html)
