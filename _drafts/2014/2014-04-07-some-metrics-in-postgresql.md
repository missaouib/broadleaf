---
layout: post
title: PostgreSQL监控指标
description: PostgreSQL监控指标
category: database
tags: 
 - postgresql
published: true
---

数据库版本：9.3.1（不同版本数据库相关表列名可能略有不同）

# 数据库状态信息

数据库状态信息主要体现数据库的当前状态

1.目前客户端的连接数

~~~sql
postgres=# SELECT count(*) FROM pg_stat_activity WHERE NOT pid=pg_backend_pid();
~~~

2.连接状态

~~~sql
postgres=# SELECT pid,waiting,current_timestamp - least(query_start,xact_start) AS runtime,substr(query,1,25) AS current_query 
FROM pg_stat_activity WHERE NOT pid=pg_backend_pid();
 pid  | waiting | runtime         | current_query 
------+---------+-----------------+-----------------------
9381  | f       | 00:01:24.425487 | select * from orders;
~~~

可以查看每个连接的pid，执行的操作，是否发生等待，根据查询,或者事务统计开始时间等等。有多少个链接查询就有多少行 所以可以用order by,limit限制查询行数

3.数据库占用空间

~~~sql
postgres=# select pg_size_pretty(pg_database_size('postgres'));
~~~

一个数据库数据文件对应存储在以这个数据库PID命名的文件中,通过统计所有以PID命名文件的总大小，也可以得出这个数据库占用的空间。

表占用的空间使用`pg_relation_size()`查询，对应的系统中的文件名和pg_class中的filenode相同，一个热点的表最好一天一统计大小，获得表的一个增长状况，来预测数据库未来可能的增长状况。根据需求提前准备空间应付数据库的增长。

4.等待事件

~~~sql
postgres# SELECT bl.pid AS blocked_pid, a.usename AS blocked_user, kl.pid AS blocking_pid, ka.usename AS blocking_user, a.query AS blocked_statement 
FROM pg_locks bl 
JOIN pg_stat_activity a ON a.pid = bl.pid 
JOIN pg_locks kl ON kl.transactionid = bl.transactionid AND kl.pid != bl.pid 
JOIN pg_stat_activity ka ON ka.pid = kl.pid WHERE NOT bl.granted;
~~~

根据阻塞的语句的会话PID做相应处理

# 数据库统计信息

1.sql语句统计

实现上述统计需要安装一个pg的extension:`pg_stat_statements–1.1.sql`，调整postgres.conf:`shared_preload_libraries = 'pg_stat_statements'`,就可以使用了

~~~sql
postgres=# SELECT calls, total_time, rows, 100.0 * shared_blks_hit /nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent,substr(query,1,25)
FROM pg_stat_statements ORDER BY total_time DESC LIMIT 5;
calls  | total_time | rows | hit_percent          | substr 
-------+------------+------+----------------------+---------------------------
1      | 23.104     | 17   | 99.4974874371859296  | SELECT n.nspname as Sche
1      | 21.808     | 2    |                      | select * from pg_stat_sta
2      | 5.391      | 2    |                      | SELECT name FROM (SELECT
3      | 3.307      | 57   | 100.0000000000000000 | SELECT pg_catalog.quote_i
4      | 1.318      | 19   | 100.0000000000000000 | SELECT calls, total_time,
~~~
上述查询是按照查询的执行时间来排序的，可以定位执行比较慢的sql,也可以用来查出常用sql，以及sql共享内存的命中率等信息

2.表的共享内存的利用情况统计

实现上述统计需要安装一个pg的extension:`pg_buffercache–1.0.sql`

~~~sql
postgres=# SELECT c.relname, count(*) AS buffers 
FROM pg_buffercache b INNER JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid) 
AND b.reldatabase IN (0, (SELECT oid FROM pg_database WHERE datname = current_database())) GROUP BY c.relname ORDER BY 2 DESC LIMIT 5;
relname                         | buffers 
--------------------------------+---------
pg_proc                         | 28
pg_attribute                    | 23
pg_operator                     | 14
pg_proc_proname_args_nsp_index  | 10
pg_class                        | 9
~~~

表在共享内存中占用的块数，用来查看表是不是在内存中，buffers的单位是数据块，默认8K，如果计算大小等于表的大小，说明全表的数据都在缓存中，这时的查询速度是很快的

3.对一个表执行操作的统计

实现统计对一个表操作的偏重，insert,update,delete的比率

~~~sql
postgres=# update products set price=11.00 where prod_id=30;
UPDATE 1
postgres=# delete from products where prod_id=30;
DELETE 1
postgres=# SELECT relname,cast(n_tup_ins AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del) AS ins_pct,
cast(n_tup_upd AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del) AS upd_pct, 
cast(n_tup_del AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del) AS del_pct 
FROM pg_stat_user_tables where relname='products';
relname   | ins_pct                | upd_pct                | del_pct 
----------+------------------------+------------------------+------------------------
products  | 0.00000000000000000000 | 0.50000000000000000000 | 0.50000000000000000000
~~~

4.表的IO和索引的IO

表的IO主要涉及查询的时候查询的逻辑块和物理块，归到底也是命中率的问题，当然最简单的思维方式，一张表存在内存中的内容越多，相应的查询速度越快。相关视图：`pg_stat_user_tables`

相对于表的大小来说，索引占用的空间要小的多，所以常用的表，可以让其索引一直存在内存中，很多时候保持索引的一个高命中率是非常必要的。相关视图: `pg_stat_user_indexes`

~~~sql
postgres# SELECT indexrelname,cast(idx_blks_hit as numeric) / (idx_blks_hit + idx_blks_read) AS hit_pct,
idx_blks_hit,idx_blks_read 
FROM pg_statio_user_indexes WHERE (idx_blks_hit + idx_blks_read)>0 ORDER BY hit_pct;
~~~

5.buffer background 和 checkpoint

涉及检查点写和后台写的比率问题，检查点的集中数据写入会对数据库IO的性能有很大的提升，但相应的需要部分空间存储脏数据，而且一旦数据库崩溃，内存中未被写入磁盘的脏数据越多，数据库恢复时间也就越长，这是一个数据库的平衡问题，相关问题在调优文档中做深入研究。 相关视图：`pg_stat_bgwriter`

~~~sql
postgres=# SELECT
(100 * checkpoints_req) / (checkpoints_timed + checkpoints_req) AS checkpoints_req_pct,
pg_size_pretty(buffers_checkpoint * block_size / (checkpoints_timed + checkpoints_req)) AS avg_checkpoint_write,
pg_size_pretty(block_size * (buffers_checkpoint + buffers_clean + buffers_backend)) AS total_written,
100 * buffers_checkpoint / (buffers_checkpoint + buffers_clean + buffers_backend) AS checkpoint_write_pct,
100 * buffers_backend / (buffers_checkpoint + buffers_clean + buffers_backend) AS backend_write_pct,*
FROM pg_stat_bgwriter,(SELECT cast(current_setting('block_size') AS integer) AS block_size) AS bs;
~~~

# 系统监控信息

介绍一些关于数据库需要查看的系统状态信息

1.数据库基本状态信息

~~~bash
# ps -ef | grep postgres
# netstat -altunp | grep 5432
# pg_controdata   
~~~

pg_controdata命令和psql同在postgres的bin目录下,系统命令下查询到最全面的数据库快照信息

2.top动态信息配合其他命令使用(截取相关行)

~~~bash
# top -u postgres
Cpu(s): 1.7%us, 1.0%sy, 0.0%ni, 97.3%id, 0.0%wa, 0.0%hi, 0.0%si, 0.0%st
Mem: 2051164k total, 1476536k used, 574628k free, 239624k buffers
Swap: 2097144k total, 0k used, 2097144k free, 768676k cached
PID   USER    PR NI VIRT RES SHR   S %CPU %MEM TIME+ COMMAND 
11172 postgres 20 0 709m 34m 33m   S 0.0  1.7 0:00.79 postgres 
9380  postgres 20 0 167m 5284 2272 S 0.0  0.3 0:00.05 psql 
11178 postgres 20 0 709m 5168 4408 S 0.0  0.3 0:00.01 postgres 
11179 postgres 20 0 709m 4656 3920 S 0.0  0.2 0:00.01 postgres 
~~~

~~~bash
# free
total used free shared buffers cached
Mem: 2051164 1476032 575132 0 239624 768676
-/+ buffers/cache: 467732 1583432
Swap: 2097144 0 2097144
~~~

~~~bash
# iotop -u postgres
Total DISK READ: 0.00 B/s | Total DISK WRITE: 0.00 B/s
11175 be/4 postgres 0.00 B/s 0.00 B/s 0.00 % 0.00 % postgres: logger process
11181 be/4 postgres 0.00 B/s 0.00 B/s 0.00 % 0.00 % postgres: autovacuum launcher process
11178 be/4 postgres 0.00 B/s 0.00 B/s 0.00 % 0.00 % postgres: checkpointer process
11180 be/4 postgres 0.00 B/s 0.00 B/s 0.00 % 0.00 % postgres: wal writer process
11182 be/4 postgres 0.00 B/s 0.00 B/s 0.00 % 0.00 % postgres: stats collector process
11179 be/4 postgres 0.00 B/s 0.00 B/s 0.00 % 0.00 % postgres: writer process
~~~
 
简单分析下top命令,用top可以分析出系统的当前总体的负载状况，如上例，总体负载率很低，在io等待率高的时候可以使用iotop来定位io具体的进程，top中的VIRT RES 可以看出进程希望获取的内存，和占用系统内存的数量，可以根据来判定系统内存的分配情况，内存的值也关联到一些参数的设定，如postgres在发生检查点之前checkpointer process进程会消耗比较大的物理内存，直到检查点发生后，占用的内存才会被释放掉，所以在设置检查点时间的时候也要将内存的占用考虑进去。

free总体的表现内存的使用情况，buffers和cached在应用申请内存的时候会被系统释放掉，所以应用实际可以使用的内存是free的值加上buffers和cached的。

3.sar做辅助分析

sar类似于快照的方式来保存系统过去的信息

~~~bash
# sar
03:40:01 PM CPU %user %nice %system %iowait %steal %idle
03:50:01 PM all 1.56  0.00  0.68    0.10    0.00   97.67
04:00:02 PM all 1.91  0.00  0.63    0.05    0.00   97.41
Average:    all 1.07  0.04  1.95    2.65    0.00   94.29
~~~

~~~bash
# sar -r
12:40:01 PM kbmemfree kbmemused %memused kbbuffers kbcached kbcommit %commit
12:50:01 PM 567124    1484040   72.35    237596    755720   1426740  34.39
01:10:01 PM 567256    1483908   72.34    237600    755720   1426740  34.39
01:20:01 PM 567132    1484032   72.35    237600    755724   1426740  34.39
Average:    742177    1308987   63.82    195809    669444   1390037  33.51
~~~

这些统计信息可以对照性能问题，查看当时的系统状态。


