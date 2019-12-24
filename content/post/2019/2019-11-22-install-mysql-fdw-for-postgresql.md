---
layout: post
title: PostgreSQL安装并测试mysql_fdw
date: 2019-11-22T08:00:00+08:00
categories: [ database ]
tags: [postgresql]
---

mysql_fdw PostgreSQL外部MySQL表功能的扩展，所谓外部表，就是在PG数据库中通过SQL访问外部数据源数据，就像访问本地数据库一样，下面就来测试一下使用mysql_fdw 来访问mysql中的数据。

# 安装PostgreSQL

参考[RHEL系统安装PostgreSQL](/2014/04/07/install-postgresql-on-rhel-system/)，安装PostgreSQL 12：

```bash
sudo yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

sudo yum install postgresql12 postgresql12-server -y

sudo /usr/pgsql-12/bin/postgresql-12-setup initdb

sudo systemctl enable postgresql-12
sudo systemctl start postgresql-12
```

# 安装mysql_fdw

可以从源码编译安装，也可以从rpm安装，因为我使用的是PostgreSQL 12，所以对应的rpm下载地址为：https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-7.7-x86_64/ ，你可以根据你的情况去对应的下载地址。

查看下载页面，可以看到已经编译好的mysql_fdw和mongo_fdw rpm文件：

![image-20191122101308298](https://tva1.sinaimg.cn/large/006y8mN6ly1g96licnmmtj30z20nc7ek.jpg)

下载文件：

```bash
wget https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-7.7-x86_64/mysql_fdw_12-2.5.3-1.rhel7.x86_64.rpm

wget https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-7.7-x86_64/mysql_fdw_12-debuginfo-2.5.3-1.rhel7.x86_64.rpm
```

安装：

```bash
yum install mysql_fdw_12-2.5.3-1.rhel7.x86_64.rpm mysql_fdw_12-debuginfo-2.5.3-1.rhel7.x86_64.rpm -y
```

如果提示找不到 mariadb-devel.x86_64 1:5.5.64-1.el7，则在网上搜索：

```bash
ftp://ftp.pbone.net/mirror/ftp.centos.org/7.7.1908/os/x86_64/Packages/mariadb-devel-5.5.64-1.el7.x86_64.rpm
ftp://ftp.pbone.net/mirror/ftp.centos.org/7.7.1908/os/x86_64/Packages/mariadb-libs-5.5.64-1.el7.x86_64.rpm
```

# 测试mysql_fdw

## 安装扩展

进入PostgreSQL数据库，并安装扩展mysql_fdw：

```bash
$ sudo -u postgres psql
psql (12.1)
Type "help" for help.

postgres=# create extension mysql_fdw;
CREATE EXTENSION
```

查看已经安装的扩展：

```bash
postgres=# \dx
                            List of installed extensions
   Name    | Version |   Schema   |                   Description
-----------+---------+------------+--------------------------------------------------
 file_fdw  | 1.0     | public     | foreign-data wrapper for flat file access
 mysql_fdw | 1.1     | public     | Foreign data wrapper for querying a MySQL server
 plpgsql   | 1.0     | pg_catalog | PL/pgSQL procedural language
(3 rows)
```

## 创建外部服务器

```bash
postgres=# CREATE SERVER mysql_server_test FOREIGN DATA WRAPPER mysql_fdw OPTIONS (HOST '192.168.1.75', PORT '3306');
CREATE SERVER
```

查看外部服务器：

```bash
postgres=# \des
               List of foreign servers
       Name        |  Owner   | Foreign-data wrapper
-------------------+----------+----------------------
 mysql_server_test | postgres | mysql_fdw
 server_file_fdw   | postgres | file_fdw
(2 rows)
```

## 创建用户映射

```bash
postgres=# CREATE USER MAPPING FOR postgres SERVER mysql_server_test OPTIONS (username 'root', password '123456');
CREATE USER MAPPING
```

OPTIONS 是指外部拓展的选项，指定了访问外部数据标的本地用户和远程用户信息。

如果想修改密码：

```bash
alter user MAPPING FOR public server mysql_server options ( set password 'xxxxxx');
```



## 创建外部表

```bash
postgres=# create foreign table user(user_id int,username text,status int,email text ) server mysql_server_test options(dbname 'test',table_name 'user');
CREATE FOREIGN TABLE
```



## 查询外部表

```bash
postgres=# select * from user;
 user_id | username | status |       email
---------+----------+--------+--------------------
       1 | a    |      1 | a@test.com
       2 | b  	|      1 | b@test.com
       3 | c    |      1 | c@test.com
```

此时mysql端发生的变化，PG 再次查询时这边马上就能看到



## 反写数据

一般情况下，如果没有唯一键限制，反写数据就会报错

```
ERROR: first column of remote table must be unique for INSERT/UPDATE/DELETE operation
```

如果想反写到mysql，需要在mysql上添加表的限制

```bash
ALTER TABLE user ADD CONSTRAINT idx_id UNIQUE (id);
```

我这边是ID已经是主键唯一键了，所以直接能使用。



事实上现在不仅仅是支持insert语句，update与delete语句均支持，前提是提供给PG的mysql用户是有这些权限的。



## 物化数据

mysql_fdw 实现的一个关键特性就是支持持久连接的能力。查询执行后，不会删除与远程MySQL的连接。相反，它保留来自同一会话的下次查询连接。然而，在某些情况下，因为网络查询等原因不能及时查询数据，则可以考虑在本地实现数据保留。可以通过外部表创建物化视图，如下

```bash
postgres=# CREATE MATERIALIZED VIEW test_view as select * from user;
SELECT 3
postgres=# \d
                  List of relations
 Schema |     Name     |       Type        |  Owner
--------+--------------+-------------------+----------
 public | foreign_tb10 | foreign table     | postgres
 public | user		     | foreign table     | postgres
 public | tb10         | table             | postgres
 public | test_view    | materialized view | postgres
(4 rows)
```

查询物化视图：

```bash
postgres=# select * from test_view;
 user_id | username | status |       email
---------+----------+--------+--------------------
       1 | a    |      1 | a@test.com
       2 | b  	|      1 | b@test.com
       3 | c    |      1 | c@test.com
```

可以将刷新任务放到定时任务中，定时去刷新视图

```sql
REFRESH MATERIALIZED VIEW test_view;
```

## 卸载

```bash
drop foreign table user;
drop user mapping for postgres server mysql_server_test ;
drop server mysql_server_test ;
drop extension mysql_fdw
```

也可以级联删除：

```sql
drop extension mysql_fdw CASCADE
```

# 参考文章

- [PostgreSQL外部数据插件：mysql_fdw](https://yq.aliyun.com/articles/713076)