---
layout: post
title: PostgreSQL测试工具PGbench
description: pgbench 是一个简单的给 PostgreSQL 做性能测试的程序。它反复运行同样的 SQL 命令序列，可能是在多个并发数据库会话上头，然后检查平均的事务速度（每秒的事务数 tps）。缺省的时候，pgbench 测试一个（松散的）接近 TPC-B 的情况，每个事务包括五个 SELECT，UPDATE，和 INSERT命令。不过，我们可以很轻松地使用自己的事务脚本文件来实现其它情况。
category: database
tags: 
 - postgresql
published: true
---

pgbench 是一个简单的给 PostgreSQL 做性能测试的程序。它反复运行同样的 SQL 命令序列，可能是在多个并发数据库会话上头，然后检查平均的事务速度（每秒的事务数 tps）。缺省的时候，pgbench 测试一个（松散的）接近 TPC-B 的情况，每个事务包括五个 SELECT，UPDATE，和 INSERT命令。不过，我们可以很轻松地使用自己的事务脚本文件来实现其它情况。

典型的输出看上去会是这样：

~~~
transaction type: TPC-B (sort of)
scaling factor: 10
number of clients: 10
number of transactions per client: 1000
number of transactions actually processed: 10000/10000
tps = 85.184871 (including connections establishing)
tps = 85.296346 (excluding connections establishing)
~~~

头四行只是报告一些最重要的参数设置。跟着的一行报告完成的事务数和期望完成的事务数（后者只是客户端数乘以事务数）；这两个会相等，除非在完成之前运行就失败了。最后两行报告 TPS 速率，分别有计算启动数据库会话时间和不计算启动会话时间的。

**使用环境：**

在比较新的9.1，9.2，9.3数据库的发行版本中,pgbench是在安装contrib包时直接编译的,可以在postgres的bin目录下找到该命令，如果没有发现该命令可以在安装contrib的目录下找到pgbench的源码文件包，编译一下就可以使用。

# 1. pgbench测试库初始化

~~~bash
postgres$ pgbench --help                 # 和postgres其他命令的使用方式一样，--help获取命令使用方式的简单介绍
postgres$ createdb pgbench               # 创建测试库
postgres$ pgbench -i pgbench             # 初始化测试库
~~~

默认会在测试库中建4张表`pgbench_accounts`，`pgbench_branches`，`pgbench_history`，`pgbench_tellers` 。当然也可以自己建表，自己写测试脚本，这四张表只是默认的测试脚本会用到。

pgbench在建默认库时 `-s` 参数设定测设表的大小，默认参数是1 。`pgbench_accounts` 总行数是10W,`-s`后面接具体数值如100，则`pgbench_accounts`中的测试数据将达到1千万行

# 2. 默认的测试脚本介绍

默认的测试脚本可以在官方文档中找到（新的版本中不指定模板就会使用默认模板）

~~~bash
$ cat test.sql
\set nbranches 1 * :scale
\set ntellers 10 * :scale
\set naccounts 100000 * :scale
\setrandom aid 1 :naccounts
\setrandom bid 1 :nbranches
\setrandom tid 1 :ntellers
\setrandom delta -5000 5000
BEGIN;
UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
END;
~~~

脚本说明：

可以看到脚本中的一个事物包含了update,select,insert操作，不同的操作起到不同的测试目的

- （1）UPDATE pgbench_accounts:作为最大的表，起到促发磁盘I/O的作用。
- （2）SELECT abalance:由于上一条UPDATE语句更新一些信息，存在于缓存内用于回应这个查询。
- （3）UPDATE pgbench_tellers:职员的数量比账号的数量要少得多，所以这个表也很小，并且极有可能存在于内存中。
- （4）UPDATE pgbench_branches:作为更小的表，内容被缓存，如果用户的环境是数量较小的数据库和多个客户端时，对其锁操作可能会成为性能的瓶颈。
- （5）INSERT INTO pgbench_history:history表是个附加表，后续并不会进行更新或查询操作，而且也没有任何索引。相对于UPDATE语句，对其的插入操作对磁盘的写入成本也很小。
 
# 3. 测试结果说明

~~~bash
postgres$ pgbench -c 15 -t 300 pgbench -r -f test.sql             #执行命令
starting vacuum...end.
transaction type: Custom query
scaling factor: 1
query mode: simple 
number of clients: 15                                            #-c参数控制并发量
number of threads: 1                                                    
number of transactions per client: 300                           #每个客户端执行事务的数量
number of transactions actually processed: 4500/4500             #总执行量
tps = 453.309203 (including connections establishing)            #tps每秒钟处理的事务数包含网络开销      
tps = 457.358998 (excluding connections establishing)            #不包含网络开销
statement latencies in milliseconds:                             #带-r的效果，每个客户端事务具体的执行时间，单位是毫秒
0.005198 \set nbranches 1 * :scale                               
0.001144 \set ntellers 10 * :scale
0.001088 \set naccounts 100000 * :scale                     
0.001400 \setrandom aid 1 :naccounts
0.000814 \setrandom bid 1 :nbranches
0.000929 \setrandom tid 1 :ntellers
0.000981 \setrandom delta -5000 5000
0.613757 BEGIN;
1.027969 UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;
0.754162 SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
14.167980 UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;
13.587156 UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;
0.582075 INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);
1.628262 END;
~~~

默认的基准测试给出了一个指标TPS，同样的测试参数，tps的值越高，相对来说服务器的性能越好。上面的测试由于数据量的问题，表的内容全部缓存进了内存,磁盘io对上面的结果影响较小。

# 4. 自定义测试环境

在实际的应用中测试可以自己定义测试环境，模拟生产需求。

测试举例

~~~bash
pgbench=# create table pg_test (a1 serial,a2 int,a3 varchar(20),a4 timestamp);                        #创建测试表
postgres$cat pg_test.sql
pgbench=# insert into pg_test(a2,a3,a4) select (random()*(2*10^5)),substr('abcdefghijklmnopqrstuvwxyz',1, (random()*26)::integer),now();
                                                                                                      #每个事务插入一条数据 
postgres$pgbench -c 90 -T 10 pgbench -r -f pg_test.sql                                                   #90个并发测试每秒插入的数据量
~~~ 
测试结果截取：

~~~
number of transactions actually processed: 20196             #10秒钟90并发用户共插入20196条数据，每条数据插入费时42ms，平均每秒插入2000条数据 
tps = 1997.514876 (including connections establishing)
tps = 2119.279239 (excluding connections establishing)
statement latencies in milliseconds:
42.217948
 
pgbench=# select count(*) from pg_test;
count 
-------
20196
~~~

# 5. pgbench在参数调节上的辅助使用

简单举例：`work_mem`

~~~bash
postgres=# show work_mem ;                                              #数据库当前的work_mem
work_mem 
----------
1MB
~~~

查询样本：

~~~bash
postgres$cat select.sql
SELECT customerid FROM customers ORDER BY zip;                          #orders表是一张postgres样例表，样例库全名dellstore2
postgres$pgbench -c 90 -T 5 pgbench -r -f select.sql                    #多用户并发做单表排序操作单个事务执行的时间可能会很大，但是平均事务执行时间和单个用户的执行时间差距没那么明显。
~~~

执行结果截取

~~~
number of clients: 90
number of threads: 1
duration: 5 s
number of transactions actually processed: 150
tps = 26.593887 (including connections establishing)
tps = 27.972988 (excluding connections establishing)
statement latencies in milliseconds:
3115.754673 SELECT customerid FROM customers ORDER BY zip;
~~~

测试环境相同调节`work_mem`参数为2M试试

~~~
number of clients: 90
number of threads: 1
duration: 5 s
number of transactions actually processed: 243
tps = 44.553026 (including connections establishing)
tps = 47.027276 (excluding connections establishing)
statement latencies in milliseconds:
1865.636761 SELECT customerid FROM customers ORDER BY zip;             #5s内事务执行的总量明显增加一共做了243次单表排序
~~~   

原因分析，由于排序操作会关系到`work_mem`，排序操作能全在缓存中进行当然速度会明显加快，查看执行计划

~~~sql
postgres=# explain analyze SELECT customerid FROM customers ORDER BY zip;
QUERY PLAN 

--------------------------------------------------------------------------------------------
Sort (cost=2116.77..2166.77 rows=20000 width=8) (actual time=42.536..46.117 rows=20000 loo
ps=1)
Sort Key: zip
Sort Method: external sort Disk: 352kB
-> Seq Scan on customers (cost=0.00..688.00 rows=20000 width=8) (actual time=0.013..8.9
42 rows=20000 loops=1)
Total runtime: 48.858 ms
~~~

由上面的执行计划可以看出在`work_mem`大小为1M的时候排序一共需要1.352M空间做排序,所以加大`work_mem`参数排序速度明显增加。

这只是个简单的例子，`work_mem`的大小调节还有很多其他方面要考虑的，比如在高并发的情况下，需要为每个用户分配同样大小的排序空间，会占用大量的内存空间。参数调节在任何时候保持一个均衡才是应该考虑的。

# 参考文章

- [1] [PGbench](http://www.pgsqldb.com:8079/mwiki/index.php/PGbench)
