---
layout: post
title: Greenplum常用命令
date: 2019-12-16T08:00:00+08:00
categories: [ database ]
tags: [greenplum]
---

# 查看数据库状态

1、查看segment

列出当前状态为down的Segment：

```sql
SELECT * FROM gp_segment_configuration WHERE status <> 'u';
```

检查当前处于改变跟踪模式的Segment。

```sql
SELECT * FROM gp_segment_configuration WHERE mode = 'c';
```

检查当前在重新同步的Segment。

```sql
SELECT * FROM gp_segment_configuration WHERE mode = 'r';
```

检查没有以其最优角色运转的Segment。

```sql
SELECT * FROM gp_segment_configuration WHERE preferred_role <> role;
```

运行一个分布式查询来测试它运行在所有Segment上。对每个主Segment都应返回一行。

```sql
SELECT gp_segment_id, count(*) FROM gp_dist_random('pg_class') GROUP BY 1;
```



2、查看数据库连接

查看到当前数据库连接的IP 地址，用户名，提交的查询等。

```sql
select * from pg_stat_activity 
```



3、查看表存储结构

查看表的存储结构:

```sql
select distinct relstorage from pg_class;
```

查询当前数据库有哪些AO表：

```sql
select t2.nspname, t1.relname from pg_class t1, pg_namespace t2 where t1.relnamespace=t2.oid and relstorage in ('c', 'a');
```

查询当前数据库有哪些堆表：

```sql
select t2.nspname, t1.relname from pg_class t1, pg_namespace t2 where t1.relnamespace=t2.oid and relstorage in ('h')  and relkind='r'; 
```



# 维护数据库

检查表上缺失的统计信息。

```sql
SELECT * FROM gp_toolkit.gp_stats_missing;
```

检查数据文件中出现膨胀（死亡空间）且无法用常规VACUUM命令恢复的表。

```sql
SELECT * FROM gp_toolkit.gp_bloat_diag;
```

清理用户表

```sql
VACUUM <table>;
```

分析用户表。

```sql
analyzedb -d <database> -a

analyzedb -s pg_catalog -d <database>
```

推荐周期性地在系统目录上运行VACUUM和REINDEX来清理系统表和索引中已删除对象所占用的空间：

下面的示例脚本在一个Greenplum数据库系统目录上执行一次VACUUM、REINDEX以及ANALYZE：

```bash
#!/bin/bash
DBNAME="<database-name>"
SYSTABLES="' pg_catalog.' || relname || ';' from pg_class a, pg_namespace b 
where a.relnamespace=b.oid and b.nspname='pg_catalog' and a.relkind='r'"
psql -tc "SELECT 'VACUUM' || $SYSTABLES" $DBNAME | psql -a $DBNAME
reindexdb --system -d $DBNAME
analyzedb -s pg_catalog -d $DBNAME
```

# 查看磁盘空间

1、检查磁盘空间使用

以使用gp_toolkit管理方案中的gp_disk_free外部表来检查Segment主机文件系统中的剩余空闲空间（以千字节计）。

```sql
dw_lps=# SELECT * FROM gp_toolkit.gp_disk_free ORDER BY dfsegment;
 dfsegment |    dfhostname    | dfdevice  |  dfspace
-----------+------------------+-----------+-----------
         0 |  dw-test-node001 |  /dev/sdb | 472594712
         1 |  dw-test-node001 |  /dev/sdb | 472594712
(2 rows)
```

2、查看数据库的磁盘空间使用

要查看一个数据库的总尺寸（以字节计），使用*gp_toolkit*管理方案中的*gp_size_of_database*视图。

```sql
dw_lps=# SELECT * FROM gp_toolkit.gp_size_of_database ORDER BY sodddatname;
 sodddatname | sodddatsize
-------------+-------------
 dw_lps      |  3833874988
 gpperfmon   |    63310532
(2 rows)
```

查看某个数据库占用空间：

```sql
dw_lps=# select pg_size_pretty(pg_database_size('dw_lps'));
 pg_size_pretty
----------------
 3656 MB
(1 row)
```



3、查看一个表的磁盘空间使用

```sql
SELECT relname AS name, sotdsize AS size, sotdtoastsize 
   AS toast, sotdadditionalsize AS other 
   FROM gp_toolkit.gp_size_of_table_disk as sotd, pg_class 
   WHERE sotd.sotdoid=pg_class.oid ORDER BY relname;
```



4、查看索引的磁盘空间使用

```sql
SELECT soisize, relname as indexname
   FROM pg_class, gp_toolkit.gp_size_of_index
   WHERE pg_class.oid=gp_size_of_index.soioid 
   AND pg_class.relkind='i';
```



# 查看数据分布

1、查看某个表的数据分布：

```sql
dw_lps=# select gp_segment_id,count(*) from ods_lps_bill group by gp_segment_id;

 gp_segment_id |  count
---------------+---------
             0 | 1440129
             1 | 1439143
(2 rows)
```

2、查询压缩率：

```sql
select get_ao_compression_ratio('ods_lps_bill');
```

3、查看AO表的膨胀率

```sql
select * from gp_toolkit.__gp_aovisimap_compaction_info('ods_lps_bill'::regclass);
```

膨胀率超过千分之2的AO表：

```sql
select * from (  
  select t2.nspname, t1.relname, (gp_toolkit.__gp_aovisimap_compaction_info(t1.oid)).*   
  from pg_class t1, pg_namespace t2 where t1.relnamespace=t2.oid and relstorage in ('c', 'a')   
) t   
where t.percent_hidden > 0.2;
```

# 查看元数据

1、查看表元数据

```sql
\d+ ods_lps_bill
```

2、查看某一个表上执行的操作

```sql
SELECT schemaname as schema, objname as table, 
   usename as role, actionname as action, 
   subtype as type, statime as time 
   FROM pg_stat_operations 
   WHERE objname='ods_lps_bill';
```

