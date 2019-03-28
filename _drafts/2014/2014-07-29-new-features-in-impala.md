---
layout: post

title:  Impala新特性

description: 本文主要整理一下 Impala 每个版本的新特性，方便了解 Impala 做了哪些改进、修复了哪些 bug。

category:  impala

tags: [impala]

published: true

---

本文主要整理一下 Impala 每个版本的新特性，方便了解 Impala 做了哪些改进、修复了哪些 bug。

Impala 目前最新版本为 1.4.0，其下载地址为：<http://archive.cloudera.com/impala/redhat/6/x86_64/impala/>

不得不说的事情：

- 1.3.1 用于 CDH4
- 1.4.0 用于 CDH5

# 1.4.0

- [CDH5](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_decimal.html#decimal) 中增加 DECIMAL 数据类型，可以设置精度，其语法为：`DECIMAL[(precision[,scale])]`
- CDH5 中，impala 可以使用 HDFS 缓存特性加快频繁访问的数据的速度，减少 cpu 使用率。当数据缓存到 hdfs cache 中时，impala 可以直接从缓存中读取数据而不需要读磁盘并且减少额外的内存拷贝。
     - [Centralized Cache Management in HDFS](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hdfs_caching.html)
     - impala 中使用 HDFS Caching，参考 [sing HDFS Caching with Impala (CDH 5 Only)](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_perf_hdfs_caching.html#hdfs_caching)
- Impala 可以使用基于 Sentry 的授权策略，详细说明可以参考：[Enabling Sentry Authorization for Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_authorization.html#authorization)
- Impala 支持其他 hadoop 组件创建的 Parquet 格式的文件，你可以在建表语句中指定 Parquet 格式，Impala 中创建 parquet 格式的表，请参考：[Using the Parquet File Format with Impala Tables](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_parquet.html#parquet_ddl_unique_1)
- ORDER BY 查询不再要求一个 limit 语句，如果需要排序的结果集的大小超过了内存限制，则会使用临时的磁盘空间用于排序，ORDER BY 语法为：`ORDER BY col1 [, col2 ...] [ASC | DESC] [NULLS FIRST | NULLS LAST]`，详细说明见：[ORDER BY Clause](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_order_by.html#order_by)
- LDAP 连接可以使用 SSL 或者 TLS 加密，详细说明参考：[Enabling LDAP Authentication for Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_ldap.html#ldap)
- 增加以下内建函数：
     - `EXTRACT()`，用于从一个 TIMESTAMP 字段返回一个 date 或者 time 的字段，详细说明参考：[Date and Time Functions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_datetime_functions.html#datetime_functions)
     - `TRUNC()`，用于将一个 date/time 类型的字段裁剪为一个特定格式的值，如年、月、日、小时等等，详细说明参考：[Date and Time Functions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_datetime_functions.html#datetime_functions)
     - `ADD_MONTHS()`
     - `ROUND()`，对 DECIMAL 类型的值四舍五入，详细说明参考：[Mathematical Functions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_math_functions.html#math_functions)
     - [  `STDDEV`, `STDDEV_SAMP`, `STDDEV_POP` Functions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_stddev.html#stddev) 和 [`VARIANCE`, `VARIANCE_SAMP`, `VARIANCE_POP` Functions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_variance.html#variance)
     - `MAX_INT()`、`MIN_SMALLINT()`等，用于判断数组是否超过最大值和最小值。
     - `IS_INF()` 和 `IS_NAN()`，用于判断是否为数值。
- `SHOW PARTITIONS` 语句用于查看分区情况，详细说明参考：[SHOW Statement](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_show.html#show)
- 添加 impalad 进程设置参数让你设置所有查询的初始化内存值，详细说明参考：[Using YARN Resource Management with Impala (CDH 5 Only)](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_resource_management.html#resource_management)
- CDH 5.1 中可以利用 Llama 高可用的特性，详细说明参考：[Using Impala with a Llama High Availability Configuration](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_resource_management.html#llama_ha_unique_2)
- `CREATE TABLE` 语句支持 `STORED AS AVRO`，详细说明参考：[Using the Avro File Format with Impala Tables](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_avro.html#avro)
- impala-shell 中添加 `SUMMARY` 命令用于查看摘要信息，详细说明参考：[Using the SUMMARY Report for Performance Tuning](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_explain_plan.html#perf_summary_unique_1)
- `COMPUTE STATS` 语句性能改进：
     - `NDV` 函数通过生成本地代码加快速度
     - 在 1.4.0 或者更高版本，不再统计 NULL 值，其值被看做为 -1，详细说明参考：[How Impala Uses Statistics for Query Optimization](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_perf_stats.html#perf_stats)
- 分区性能改进。之前只能处理3000个分区，现在没有这个限制，详细说明参考：[Partition Pruning for Queries](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_partitioning.html#partition_pruning_unique_1)
- impala-shell 支持 UTF-8 字符的输入和输出，可以通过参数 `--strict_unicode` 控制是否忽略不合法的 Unicode 字符。

# 1.3.1

该版本主要是 bug 修复，可以在 CDH 4 和 CDH 5 中使用。

- 在 impalad 启动参数中，添加 `--insert_inherit_permissions` 参数用于设置创建分区的用户。默认的，INSERT 会使用 HDFS 权限为新分区创建目录，详细说明参考：[INSERT Statement](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_insert.html#insert)
- `SHOW` 函数显示每个函数的返回类型，详细说明参考：[SHOW Statement](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_show.html#show)
- `CREATE TABLE` 语句可以使用 ` FIELDS TERMINATED BY '\0'` 语句，详细说明参考：[Using Text Data Files with Impala Tables](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_txtfile.html#txtfile)
- 在 1.3.1 以及更高版本后，`REGEXP` 和 `RLIKE` 的语义进行修正，和数据库中的语义进行兼容，详细说明参考：[REGEXP Operator](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_operators.html#regexp_unique_1)。`regexp_extract()` 和 `regexp_replace()` 可以不再使用。

# 1.3.0

- [Admission Control and Query Queuing](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_admission.html#admission_control)
- `EXPLAIN` 以一种更容易读的格式显示更加详细的内容，详细说明参考：[EXPLAIN Statement](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_explain.html#explain) 和 [ Understanding Impala Query Performance - EXPLAIN Plans and Query Profiles](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_explain_plan.html#explain_plan)
- `UNIX_TIMESTAMP` 、`FROM_UNIXTIME` 和 `INTERVAL`
- 增加条件函数： `NULLIF()`、`NULLIFZERO()`、 `ZEROIFNULL()`，详细说明参考：[Conditional Functions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_conditional_functions.html#conditional_functions)
- 添加新的功能函数：`CURRENT_DATABASE()`，详细说明参考：[Miscellaneous Functions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_misc_functions.html#misc_functions)
- 和 yarn 集成，只在 CDH5 中可用，详细说明参考：[Using YARN Resource Management with Impala (CDH 5 Only)](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_resource_management.html#resource_management)

# 1.2.4

该版本用于 CDH4，主要针对 1.2.3 做了一些 bug 修复。

- 增加 `INVALIDATE METADATA table_name` 语法刷新新建的一个表
- 添加 catalogd 启动参数：
     - `--load_catalog_in_background`，是否后台运行
     - `--num_metadata_loading_threads`，并行加载线程

# 1.2.3

> Impala 1.2.3 works with CDH 4 and with CDH 5 beta 2. The resource management feature requires CDH 5 beta.

该版本主要是在 1.2.2 基础上修复 Parquet 兼容性，详细说明参考：[Known Issues and Workarounds in Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Cloudera-Impala-Release-Notes/cirn_known_issues.html#known_issues)

# 1.2.2

> Impala 1.2.2 works with CDH 4. Its feature set is a superset of features in the Impala 1.2.0 beta, with the exception of resource management, which relies on CDH 5.

- `Join order optimizations`，详细说明参考：[Performance Considerations for Join Queries](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_perf_joins.html#perf_joins)
- `COMPUTE STATS`
- `STRAIGHT_JOIN`，详细说明参考：[Overriding Join Reordering with STRAIGHT_JOIN](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_perf_joins.html#straight_join_unique_1)
- `CROSS JOIN`，详细说明参考：[Cross Joins and Cartesian Products with the CROSS JOIN Operator](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_tutorial.html#tut_cross_join_unique_2)
- LDAP 支持
- 添加 [`GROUP_CONCAT()`](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_string_functions.html#string_functions__group_concat)
- `INSERT` 语句可以添加 `SHUFFLE` 或者 `NOSHUFFLE`，主要是用在插入数据到 Parquet 表的分区的时候。
- 添加 `CAST()` 用于类型转换
- 添加 `fnv_hash()` 用于计算 hash 值，详细说明参考：[Mathematical Functions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_math_functions.html#math_functions)
- 支持 `STORED AS PARQUET` 语句。

# 1.2.1

- 添加 `SHOW TABLE STATS table_name` 和 `SHOW COLUMN STATS table_name` 语法
- 添加 `CREATE TABLE AS SELECT` 语法
- 支持 `OFFSET` 语句，用于分页查询
- `ORDER BY` 语句中添加 `NULLS FIRST` 和 `NULLS LAST` 语法支持
- 添加[内置函数](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_functions.html#functions)： `least()`, `greatest()`, `initcap()`
- 添加 `ndv()` 函数来计算 `COUNT(DISTINCT col)`
- `LIMIT` 语句接受数值表达式作为参数
-  `SHOW CREATE TABLE`
- 添加两个参数：`--idle_query_timeout` 和 `--idle_session_timeout`，详细说明参考：[Setting Timeout Periods for Daemons, Queries, and Sessions](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_timeouts.html#timeouts)
- 支持 UDFs，详细说明参考：[CREATE FUNCTION Statement](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_create_function.html#create_function) 和 [DROP FUNCTION Statement](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_drop_function.html#drop_function)
- 添加新的同步元数据的机制，详细参考：[The Impala Catalog Service](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_concepts.html#intro_catalogd_unique_2)
- 添加 `CREATE TABLE ... AS SELECT` 语法
- `CREATE TABLE` 和 `ALTER TABLE` 支持 `TBLPROPERTIES` 和 `WITH SERDEPROPERTIES` 语句，详细说明参考：[CREATE TABLE Statement](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_create_table.html#create_table) 和 [ALTER TABLE Statement](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Installing-and-Using-Impala/ciiu_alter_table.html#alter_table)
- `EXPLAIN`
- `SHOW CREATE TABLE`
- `LIMIT` 语句支持算术表达式


另外，impala 的一些不兼容的变化，请参考：[Incompatible Changes in Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Cloudera-Impala-Release-Notes/cirn_incompatible_changes.html)

Impala 一些已知的问题：[Known Issues and Workarounds in Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Cloudera-Impala-Release-Notes/cirn_known_issues.html)

已经修复的问题：[Fixed Issues in Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Impala/latest/Cloudera-Impala-Release-Notes/cirn_fixed_issues.html)
