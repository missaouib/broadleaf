---
layout: post

title:  Sqoop导入关系数据库到Hive

description: Sqoop 是 apache 下用于 RDBMS 和 HDFS 互相导数据的工具。

keywords:  Sqoop 是 apache 下用于 RDBMS 和 HDFS 互相导数据的工具。

category:  hadoop

tags: [sqoop]

published: true

---

Sqoop 是 apache 下用于 RDBMS 和 HDFS 互相导数据的工具。本文以 mysql 数据库为例，实现关系数据库导入到 hdfs 和 hive。

# 1. 安装 Sqoop

使用 rpm 安装即可。

~~~
yum install sqoop sqoop-metastore -y
~~~

> 安装完之后需要下载 mysql jar 包到 sqoop 的 lib 目录。

这里使用 hive 的 metastore 的 mysql 数据库作为关系数据库，以 TBLS 表为例，该表结构和数据如下：

~~~sql
mysql> select * from TBLS limit 3;
+------+-----------+-----+----------------+-----+--------+------+---------+----------------+------------------+-------------------+
|TBL_ID|CREATE_TIME|DB_ID|LAST_ACCESS_TIME|OWNER|RETENTI | SD_ID| TBL_NAME| TBL_TYPE       |VIEW_EXPANDED_TEXT| VIEW_ORIGINAL_TEXT|
+------+-----------+-----+----------------+-----+--------+------+---------+----------------+------------------+-------------------+
|    34|1406784308 |    8|               0|root |       0|    45| test1   | EXTERNAL_TABLE | NULL             | NULL              |
|    40|1406797005 |    9|               0|root |       0|    52| test2   | EXTERNAL_TABLE | NULL             | NULL              |
|    42|1407122307 |    7|               0|root |       0|    59| test3   | EXTERNAL_TABLE | NULL             | NULL              |
+------+-----------+-----+----------------+-----+--------+------+---------+----------------+------------------+-------------------+
~~~

# 2. 使用

## 2.1 命令说明

查看 sqoop 命令说明：

~~~bash
$ sqoop help
usage: sqoop COMMAND [ARGS]

Available commands:
  codegen            Generate code to interact with database records
  create-hive-table  Import a table definition into Hive
  eval               Evaluate a SQL statement and display the results
  export             Export an HDFS directory to a database table
  help               List available commands
  import             Import a table from a database to HDFS
  import-all-tables  Import tables from a database to HDFS
  list-databases     List available databases on a server
  list-tables        List available tables in a database
  version            Display version information

See 'sqoop help COMMAND' for information on a specific command.
~~~

你也可以查看某一个命令的使用说明：

~~~bash
$ sqoop import --help
$ sqoop help import
~~~

你也可以使用别名来代替 `sqoop (toolname)`：

~~~bash
$ sqoop-import
~~~

sqoop import 的一个示例如下：

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS
~~~

你还可以使用 `--options-file` 来传入一个文件，使用这种方式可以重用一些配置参数：
 
~~~bash
$ sqoop --options-file /users/homer/work/import.txt --table TEST
~~~

/users/homer/work/import.txt 文件内容如下：

~~~
import
--connect
jdbc:mysql://192.168.56.121:3306/metastore
--username
hiveuser
--password 
redhat
~~~

# 2.2 导入数据到 hdfs

使用 sqoop-import 命令可以从关系数据库导入数据到 hdfs。

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS --target-dir /user/hive/result
~~~

注意：

- mysql jdbc url 请使用 ip 地址
- 如果重复执行，会提示目录已经存在，可以手动删除
- 如果不指定 `--target-dir`，导入到用户家目录下的 TBLS 目录


你还可以指定其他的参数：

参数	|说明|
|:---|:---|
| `--append` |将数据追加到hdfs中已经存在的dataset中。使用该参数，sqoop将把数据先导入到一个临时目录中，然后重新给文件命名到一个正式的目录中，以避免和该目录中已存在的文件重名。|
| `--as-avrodatafile` |	将数据导入到一个Avro数据文件中||
| `--as-sequencefile` |	将数据导入到一个sequence文件中|
| `--as-textfile` |	将数据导入到一个普通文本文件中，生成该文本文件后，可以在hive中通过sql语句查询出结果。|
| `--boundary-query <statement>`|	边界查询，也就是在导入前先通过SQL查询得到一个结果集，然后导入的数据就是该结果集内的数据，格式如：`--boundary-query 'select id,no from t where id = 3'`，表示导入的数据为id=3的记录，或者 `select min(<split-by>), max(<split-by>) from <table name>`，注意查询的字段中不能有数据类型为字符串的字段，否则会报错|
| `--columns<col,col>`	|指定要导入的字段值，格式如：`--columns id,username`|
| `--direct`	|直接导入模式，使用的是关系数据库自带的导入导出工具。官网上是说这样导入会更快|
| `--direct-split-size`|在使用上面direct直接导入的基础上，对导入的流按字节数分块，特别是使用直连模式从PostgreSQL导入数据的时候，可以将一个到达设定大小的文件分为几个独立的文件。|
| `--inline-lob-limit`	|设定大对象数据类型的最大值|
| `-m,--num-mappers`	|启动N个map来并行导入数据，默认是4个，最好不要将数字设置为高于集群的节点数|
| `--query，-e <sql>`|	从查询结果中导入数据，该参数使用时必须指定`–target-dir`、`–hive-table`，在查询语句中一定要有where条件且在where条件中需要包含 `\$CONDITIONS`，示例：`--query 'select * from t where \$CONDITIONS ' --target-dir /tmp/t –hive-table t `|
| `--split-by <column>`	|表的列名，用来切分工作单元，一般后面跟主键ID|
| `--table <table-name>`	|关系数据库表名，数据从该表中获取|
| `--delete-target-dir`|删除目标目录|
| `--target-dir <dir>`	|指定hdfs路径|
| `--warehouse-dir <dir>`|	与 `--target-dir` 不能同时使用，指定数据导入的存放目录，适用于hdfs导入，不适合导入hive目录|
| `--where`	|从关系数据库导入数据时的查询条件，示例：`--where "id = 2"`|
| `-z,--compress`	|压缩参数，默认情况下数据是没被压缩的，通过该参数可以使用gzip压缩算法对数据进行压缩，适用于SequenceFile, text文本文件, 和Avro文件|
| `--compression-codec`	|Hadoop压缩编码，默认是gzip|
| `--null-string <null-string>`	|可选参数，如果没有指定，则字符串null将被使用|
| `--null-non-string <null-string>`	|可选参数，如果没有指定，则字符串null将被使用||


示例程序：

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS --columns "tbl_id,create_time" --where "tbl_id > 1" --target-dir /user/hive/result
~~~

### 使用 sql 语句

参照上表，使用 sql 语句查询时，需要指定 `$CONDITIONS`

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --query 'SELECT * from TBLS where \$CONDITIONS ' --split-by tbl_id -m 4 --target-dir /user/hive/result
~~~

上面命令通过 `-m 1` 控制并发的 map 数。

### 使用 direct 模式：

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS --delete-target-dir --direct --default-character-set UTF-8 --target-dir /user/hive/result
~~~

### 指定文件输出格式：

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS --fields-terminated-by "\t" --lines-terminated-by "\n" --delete-target-dir  --target-dir /user/hive/result
~~~

这时候查看 hdfs 中数据(观察分隔符是否为制表符)：

~~~bash
$ hadoop fs -ls result
Found 5 items
-rw-r--r--   3 root hadoop          0 2014-08-04 16:07 result/_SUCCESS
-rw-r--r--   3 root hadoop         69 2014-08-04 16:07 result/part-m-00000
-rw-r--r--   3 root hadoop          0 2014-08-04 16:07 result/part-m-00001
-rw-r--r--   3 root hadoop        142 2014-08-04 16:07 result/part-m-00002
-rw-r--r--   3 root hadoop         62 2014-08-04 16:07 result/part-m-00003

$ hadoop fs -cat result/part-m-00000
34	1406784308	8	0	root	0	45	test1	EXTERNAL_TABLE	null	null	null

$ hadoop fs -cat result/part-m-00002
40	1406797005	9	0	root	0	52	test2	EXTERNAL_TABLE	null	null	null
42	1407122307	7	0	root	0	59	test3	EXTERNAL_TABLE	null	null	null
~~~

指定空字符串：

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS --fields-terminated-by "\t" --lines-terminated-by "\n" --delete-target-dir --null-string '\\N' --null-non-string '\\N' --target-dir /user/hive/result
~~~

如果需要指定压缩：

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS --fields-terminated-by "\t" --lines-terminated-by "\n" --delete-target-dir --null-string '\\N' --null-non-string '\\N' --compression-codec "com.hadoop.compression.lzo.LzopCodec" --target-dir /user/hive/result
~~~

附：可选的文件参数如下表。

|参数|说明|
|:---|:---|
|`--enclosed-by <char>`	|给字段值前后加上指定的字符，比如双引号，示例：`--enclosed-by '\"'`，显示例子："3","jimsss","dd@dd.com"|
|`--escaped-by <char>`	|给双引号作转义处理，如字段值为"测试"，经过 `--escaped-by "\\"` 处理后，在hdfs中的显示值为：`\"测试\"`，对单引号无效|
|`--fields-terminated-by <char>`	|设定每个字段是以什么符号作为结束的，默认是逗号，也可以改为其它符号，如句号`.`，示例如：`--fields-terminated-by`|
|`--lines-terminated-by <char>`	|设定每条记录行之间的分隔符，默认是换行串，但也可以设定自己所需要的字符串，示例如：`--lines-terminated-by "#"` 以#号分隔|
|`--mysql-delimiters`|	Mysql默认的分隔符设置，字段之间以`,`隔开，行之间以换行`\n`隔开，默认转义符号是`\`，字段值以单引号`'`包含起来。|
|`--optionally-enclosed-by <char>`|	enclosed-by是强制给每个字段值前后都加上指定的符号，而`--optionally-enclosed-by`只是给带有双引号或单引号的字段值加上指定的符号，故叫可选的|

# 2.3 创建 hive 表

生成与关系数据库表的表结构对应的HIVE表：

~~~bash
$ sqoop create-hive-table --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS 
~~~

|参数|说明|
|:---|:---|
|`--hive-home <dir>`|Hive的安装目录，可以通过该参数覆盖掉默认的hive目录|
|`--hive-overwrite`|覆盖掉在hive表中已经存在的数据|
|`--create-hive-table`|默认是false，如果目标表已经存在了，那么创建任务会失败|
|`--hive-table`|后面接要创建的hive表|
|`--table`|指定关系数据库表名|

# 2.4 导入数据到 hive

执行下面的命令会将 mysql 中的数据导入到 hdfs 中，然后创建一个hive 表，最后再将 hdfs 上的文件移动到 hive 表的目录下面。

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS --fields-terminated-by "\t" --lines-terminated-by "\n" --hive-import --hive-overwrite --create-hive-table --hive-table dw_srclog.TBLS --delete-target-dir
~~~

说明：

- 可以在 hive 的表名前面指定数据库名称
- 可以通过 `--create-hive-table` 创建表，如果表已经存在则会执行失败

接下来可以查看 hive 中的数据：

~~~bash
$ hive -e 'select * from dw_srclog.tbls'
34	1406784308	8	0	root	0	45	test1	EXTERNAL_TABLE	null	null	NULL
40	1406797005	9	0	root	0	52	test2	EXTERNAL_TABLE	null	null	NULL
42	1407122307	7	0	root	0	59	test3	EXTERNAL_TABLE	null	null	NULL
~~~

直接查看文件内容：
 
~~~bash
$ hadoop fs -cat /user/hive/warehouse/dw_srclog.db/tbls/part-m-00000
34140678430880root045go_goodsEXTERNAL_TABLEnullnullnull
40140679700590root052merchantEXTERNAL_TABLEnullnullnull
~~~

从上面可见，数据导入到 hive 中之后分隔符为默认分隔符，参考上文你可以通过设置参数指定其他的分隔符。

另外，Sqoop 默认地导入空值（NULL）为 null 字符串，而 hive 使用 \N 去标识空值（NULL），故你在 import 或者 export 时候，需要做相应的处理。在 import 时，使用如下命令：

~~~bash
$ sqoop import  ... --null-string '\\N' --null-non-string '\\N'
~~~

在导出时，使用下面命令：

~~~bash
$ sqoop import  ... --input-null-string '' --input-null-non-string ''
~~~

一个完整的例子如下：

~~~bash
$ sqoop import --connect jdbc:mysql://192.168.56.121:3306/metastore --username hiveuser --password redhat --table TBLS --fields-terminated-by "\t" --lines-terminated-by "\n" --hive-import --hive-overwrite --create-hive-table --hive-table dw_srclog.TBLS --null-string '\\N' --null-non-string '\\N' --compression-codec "com.hadoop.compression.lzo.LzopCodec"
~~~

# 2.5 增量导入

|参数|说明|
|:---|:---|
|`--check-column (col)`|用来作为判断的列名，如id|
|`--incremental (mode)`|append：追加，比如对大于last-value指定的值之后的记录进行追加导入。lastmodified：最后的修改时间，追加last-value指定的日期之后的记录|
|`--last-value (value)`|指定自从上次导入后列的最大值（大于该指定的值），也可以自己设定某一值|

# 2.6 合并 hdfs 文件

将HDFS中不同目录下面的数据合在一起，并存放在指定的目录中，示例如：

~~~bash
sqoop merge –new-data /test/p1/person –onto /test/p2/person –target-dir /test/merged –jar-file /opt/data/sqoop/person/Person.jar –class-name Person –merge-key id
~~~

其中，`–class-name` 所指定的 class 名是对应于 Person.jar 中的 Person 类，而 Person.jar 是通过 Codegen 生成的

|参数|	说明|
|:---|:---|
|`--new-data <path>`	|Hdfs中存放数据的一个目录，该目录中的数据是希望在合并后能优先保留的，原则上一般是存放越新数据的目录就对应这个参数。|
|`--onto <path>`	|Hdfs中存放数据的一个目录，该目录中的数据是希望在合并后能被更新数据替换掉的，原则上一般是存放越旧数据的目录就对应这个参数。|
|`--merge-key <col>`	|合并键，一般是主键ID|
|`--jar-file <file>`	|合并时引入的jar包，该jar包是通过Codegen工具生成的jar包|
|`--class-name <class>`|对应的表名或对象名，该class类是包含在jar包中的。|
|`--target-dir <path>`|合并后的数据在HDFS里的存放目录|

# 3. 参考文章

- [Sqoop中文手册](http://www.zihou.me/html/2014/01/28/9114.html)

