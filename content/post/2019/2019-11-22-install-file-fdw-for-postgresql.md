---
layout: post
title: PostgreSQL安装并测试file_fdw
date: 2019-11-22T08:00:00+08:00
categories: [ database ]
tags: [postgresql]
---

file_fdw模块提供了外部数据封装器，可以用来在服务器的文件系统中访问数据文件。本文主要是记录安装file_fdw模块的过程，并做测试。



# 安装PostgreSQL

参考[RHEL系统安装PostgreSQL](/2014/04/07/install-postgresql-on-rhel-system/)，安装PostgreSQL 12：

```bash
sudo yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

sudo yum install postgresql12 postgresql12-server -y

sudo /usr/pgsql-12/bin/postgresql-12-setup initdb

sudo systemctl enable postgresql-12
sudo systemctl start postgresql-12
```

# 安装file_fdw

进入PostgreSQL数据库，并安装扩展file_fdw：

```bash
$ sudo -u postgres psql
psql (12.1)
Type "help" for help.

postgres=# create extension mysql_fdw ;
ERROR:  could not open extension control file "/usr/pgsql-12/share/extension/mysql_fdw.control": No such file or directory
```

提示没有mysql_fdw.control这个文件，可以进入usr/pgsql-12/share/extension目录查看已经安装了哪些扩展：

```bash
ll  /usr/pgsql-12/share/extension;
total 12
-rw-r--r-- 1 root root 310 Nov 13 01:22 plpgsql--1.0.sql
-rw-r--r-- 1 root root 370 Nov 13 01:22 plpgsql--unpackaged--1.0.sql
-rw-r--r-- 1 root root 179 Nov 13 01:22 plpgsql.control
```

# 安装postgresql12-contrib

```bash
sudo yum install postgresql12-contrib -y
```

再次查看已经安装的扩展：

```bash
ls  /usr/pgsql-12/share/extension |grep control
adminpack.control
amcheck.control
autoinc.control
bloom.control
btree_gin.control
btree_gist.control
citext.control
cube.control
dblink.control
dict_int.control
dict_xsyn.control
earthdistance.control
file_fdw.control
fuzzystrmatch.control
hstore.control
hstore_plperl.control
hstore_plperlu.control
insert_username.control
intagg.control
intarray.control
isn.control
jsonb_plperl.control
jsonb_plperlu.control
lo.control
ltree.control
moddatetime.control
pageinspect.control
pg_buffercache.control
pg_freespacemap.control
pg_prewarm.control
pg_stat_statements.control
pg_trgm.control
pg_visibility.control
pgcrypto.control
pgrowlocks.control
pgstattuple.control
plpgsql.control
postgres_fdw.control
refint.control
seg.control
sslinfo.control
tablefunc.control
tcn.control
tsm_system_rows.control
tsm_system_time.control
unaccent.control
uuid-ossp.control
xml2.control
```

可以看到，PostgreSQL官方已经支持一些扩展，但是不包括MySQL和MongoDB。

# 测试file_fdw

进入PostgreSQL数据库，并安装扩展file_fdw：

```bash
$ sudo -u postgres psql
psql (12.1)
Type "help" for help.

postgres=# create extension file_fdw;
CREATE EXTENSION
```

查看已经安装的扩展：

```bash
postgres=# \dx
                        List of installed extensions
   Name   | Version |   Schema   |                Description
----------+---------+------------+-------------------------------------------
 file_fdw | 1.0     | public     | foreign-data wrapper for flat file access
 plpgsql  | 1.0     | pg_catalog | PL/pgSQL procedural language
(2 rows)
```

创建一个表并生成数据：

```bash
postgres=# create table tb10(id integer,name character varying,passworld character varying);
CREATE TABLE
postgres=# insert into tb10 select generate_series(1,50),'john',md5(random()::text);
INSERT 0 50
```

将数据导出到本地文件，注意：导出目录必须是postgres有权限访问

```bash
copy tb10 to '/var/lib/pgsql/tb10.csv';
```

创建SERVER（外部服务器）

```bash
postgres=# create server server_file_fdw foreign data wrapper file_fdw;
CREATE SERVER
```

查看外部服务器：

```bash
postgres=# \des
              List of foreign servers
      Name       |  Owner   | Foreign-data wrapper
-----------------+----------+----------------------
 server_file_fdw | postgres | file_fdw
(1 row)
```

创建外部表：

```bash
postgres=# create foreign table foreign_tb10 (id integer,name character varying,password character varying)server server_file_fdw  options (filename '/var/lib/pgsql/tb10.csv');
CREATE FOREIGN TABLE
```

options里面参数的说明：

- filename表示外部文件的绝对路径,是必须选项
- format是格式,csv是一种文件格式（还可以选择text格式和binary格式），默认为text格式
- delimiter是分隔符（如果format是binary，则此选项不可用；如果format是text，默认为tab；如果format是csv，默认为逗号）
- header表示第一行数据是否需要（文件中是第一行数据是否为包含每列的字段名的行）
- null表示空数据的转化处理

查看表：

```bash
postgres=#  \d
                List of relations
 Schema |     Name     |     Type      |  Owner
--------+--------------+---------------+----------
 public | foreign_tb10 | foreign table | postgres
 public | tb10         | table         | postgres
(2 rows)
```

查看外部表foreign_tb10的结构：

```bash
postgres=# \d foreign_tb10
                     Foreign table "public.foreign_tb10"
  Column  |       Type        | Collation | Nullable | Default | FDW options
----------+-------------------+-----------+----------+---------+-------------
 id       | integer           |           |          |         |
 name     | character varying |           |          |         |
 password | character varying |           |          |         |
Server: server_file_fdw
FDW options: (filename '/var/lib/pgsql/tb10.csv')
```

查询外部表：

```bash
postgres=# select * from foreign_tb10 order by id limit 10;
 id | name |             password
----+------+----------------------------------
  1 | john | 7cb3c9bdeeaffb45e6efebbfdae43830
  2 | john | d1d0c1e276c86f36515faf173a3fc8f3
  3 | john | 27af132b61a774d6dcad453e9b360d68
  4 | john | 8f262762daa2ef9b5b82f2345c3e79e6
  5 | john | b8a92749560fbaa6a10b6ab8bf655f00
  6 | john | 677760eb4bd282ba25e318d837f3ddd2
  7 | john | 717f18fd00a1ab7d590210652973ad7f
  8 | john | 6c1934107960dfe85aa708e0979d39e1
  9 | john | d445c3d9405fe575d94f4a7c71a78fb0
 10 | john | 944b7112c9a55e774798d61844cc87c2
(10 rows)
```

查看执行计划：

```bash
postgres=# explain select * from foreign_tb10 order by id limit 10;
                                  QUERY PLAN
------------------------------------------------------------------------------
 Limit  (cost=3.55..3.58 rows=10 width=68)
   ->  Sort  (cost=3.55..3.61 rows=21 width=68)
         Sort Key: id
         ->  Foreign Scan on foreign_tb10  (cost=0.00..3.10 rows=21 width=68)
               Foreign File: /var/lib/pgsql/tb10.csv
               Foreign File Size: 2041 b
(6 rows)
```

测试往外部表写数据：

```bash
postgres=# insert into foreign_tb10 select generate_series(51,100),'som',md5(random()::text);
ERROR:  cannot insert into foreign table "foreign_tb10"
```

可以看到不支持往file_fdw的外部表写数据。

退出：

```bash
postgres=#  \q
```

查看导出的本地文件：

```bash
$ cat /var/lib/pgsql/tb10.csv |head -n 10
1	john	7cb3c9bdeeaffb45e6efebbfdae43830
2	john	d1d0c1e276c86f36515faf173a3fc8f3
3	john	27af132b61a774d6dcad453e9b360d68
4	john	8f262762daa2ef9b5b82f2345c3e79e6
5	john	b8a92749560fbaa6a10b6ab8bf655f00
6	john	677760eb4bd282ba25e318d837f3ddd2
7	john	717f18fd00a1ab7d590210652973ad7f
8	john	6c1934107960dfe85aa708e0979d39e1
9	john	d445c3d9405fe575d94f4a7c71a78fb0
10	john	944b7112c9a55e774798d61844cc87c2
```

可以看到，数据是从外部文件扫描获取，文件的位置，大小也有展示。

# 配置选项

使用这个封装器创建的外部表可以有下列选项：

| 参数      | 说明                                                 |
| --------- | ---------------------------------------------------- |
| filename  | 指定要读取的文件。这是必需的。必须是一个绝对路径名。 |
| format    | 指定文件的格式，与COPY的FORMAT选项相同。             |
| header    | 指定文件是否有标题行，与COPY的HEADER选项相同。       |
| delimiter | 指定文件的分隔符，与COPY的DELIMITER选项相同。        |
| quote     | 指定文件的引用字符，与COPY的QUOTE选项相同。          |
| escape    | 指定文件的逃逸字符，与COPY的ESCAPE选项相同。         |
| null      | 指定文件的null字符串，与COPY的NULL选项相同。         |
| encoding  | 指定文件的编码，与COPY的ENCODING选项相同。           |

关于Copy的用法，参考 https://www.postgresql.org/docs/current/sql-copy.html

# 参考文章

- [PostgreSQL file_fdw的使用](https://blog.csdn.net/luojinbai/article/details/45673113)