---
layout: post

title: Spark SQL中的数据源

category: spark

tags: [ spark-sql,spark,avro,parquet ]

description: Spark 支持通过 DataFrame 来操作大量的数据源，包括外部文件（如 json、avro、parquet、sequencefile 等等）、hive、关系数据库、cassandra 等等。

published: true

---

Spark 支持通过 DataFrame 来操作大量的数据源，包括外部文件（如 json、avro、parquet、sequencefile 等等）、hive、关系数据库、cassandra 等等。

本文测试环境为 Spark 1.3。

# 加载和保存文件

最简单的方式是调用 load 方法加载文件，默认的格式为 parquet，你可以修改 `spark.sql.sources.default` 指定默认的格式：

~~~scala
scala> val df = sqlContext.load("people.parquet")
scala> df.select("name", "age").save("namesAndAges.parquet")
~~~

你也可以收到指定数据源，使用全路径名称，如：`org.apache.spark.sql.parquet`，对于内置的数据源，你也可以使用简称，如：`json`、`parquet`、`jdbc`。

~~~scala
scala> val df = sqlContext.load("people.json", "json")
scala> df.select("name", "age").save("namesAndAges.parquet", "parquet")
~~~

保存操作还可以指定保存模式，用于处理文件已经存在的情况下如何操作。

| Scala/Java |  Python | 含义 |
|:----|:-----|:----|
| SaveMode.ErrorIfExists (default) | "error" (default) | 如果存在，则报错 |
| SaveMode.Append | "append" | 追加模式 | 
| SaveMode.Overwrite | "overwrite" | 覆盖模式 | 
| SaveMode.Ignore | "ignore" | 忽略，类似 SQL 中的 `CREATE TABLE IF NOT EXISTS` | 

# Parquet 数据源

## 加载数据

Spark SQL 支持读写 Parquet文件。

Scala:

~~~scala
// sqlContext from the previous example is used in this example.
// This is used to implicitly convert an RDD to a DataFrame.
import sqlContext.implicits._

val people: RDD[Person] = ... // An RDD of case class objects, from the previous example.

// The RDD is implicitly converted to a DataFrame by implicits, allowing it to be stored using Parquet.
people.saveAsParquetFile("people.parquet")

// Read in the parquet file created above.  Parquet files are self-describing so the schema is preserved.
// The result of loading a Parquet file is also a DataFrame.
val parquetFile = sqlContext.parquetFile("people.parquet")

//Parquet files can also be registered as tables and then used in SQL statements.
parquetFile.registerTempTable("parquetFile")
val teenagers = sqlContext.sql("SELECT name FROM parquetFile WHERE age >= 13 AND age <= 19")
teenagers.map(t => "Name: " + t(0)).collect().foreach(println)
~~~

Java:

~~~java
// sqlContext from the previous example is used in this example.

DataFrame schemaPeople = ... // The DataFrame from the previous example.

// DataFrames can be saved as Parquet files, maintaining the schema information.
schemaPeople.saveAsParquetFile("people.parquet");

// Read in the Parquet file created above.  Parquet files are self-describing so the schema is preserved.
// The result of loading a parquet file is also a DataFrame.
DataFrame parquetFile = sqlContext.parquetFile("people.parquet");

//Parquet files can also be registered as tables and then used in SQL statements.
parquetFile.registerTempTable("parquetFile");
DataFrame teenagers = sqlContext.sql("SELECT name FROM parquetFile WHERE age >= 13 AND age <= 19");
List<String> teenagerNames = teenagers.map(new Function<Row, String>() {
  public String call(Row row) {
    return "Name: " + row.getString(0);
  }
}).collect();
~~~

Python:

~~~python
# sqlContext from the previous example is used in this example.

schemaPeople # The DataFrame from the previous example.

# DataFrames can be saved as Parquet files, maintaining the schema information.
schemaPeople.saveAsParquetFile("people.parquet")

# Read in the Parquet file created above.  Parquet files are self-describing so the schema is preserved.
# The result of loading a parquet file is also a DataFrame.
parquetFile = sqlContext.parquetFile("people.parquet")

# Parquet files can also be registered as tables and then used in SQL statements.
parquetFile.registerTempTable("parquetFile");
teenagers = sqlContext.sql("SELECT name FROM parquetFile WHERE age >= 13 AND age <= 19")
teenNames = teenagers.map(lambda p: "Name: " + p.name)
for teenName in teenNames.collect():
  print teenName
~~~

SQL:

~~~sql
CREATE TEMPORARY TABLE parquetTable
USING org.apache.spark.sql.parquet
OPTIONS (
  path "examples/src/main/resources/people.parquet"
)

SELECT * FROM parquetTable
~~~

## 自动发现分区

Parquet 数据源可以自动识别分区目录以及分区列的类型，目前支持数据类型和字符串类型。

例如，对于这样一个目录结构，有两个分区字段：gender、country。

~~~
path
└── to
    └── table
        ├── gender=male
        │   ├── ...
        │   │
        │   ├── country=US
        │   │   └── data.parquet
        │   ├── country=CN
        │   │   └── data.parquet
        │   └── ...
        └── gender=female
            ├── ...
            │
            ├── country=US
            │   └── data.parquet
            ├── country=CN
            │   └── data.parquet
            └── ...
~~~

将 path/to/table 路径传递给 SQLContext.parquetFile 或 SQLContext.load 时，Spark SQL 将会字段获取分区信息，并返回 DataFrame 的 schema 如下：

~~~
root
|-- name: string (nullable = true)
|-- age: long (nullable = true)
|-- gender: string (nullable = true)
|-- country: string (nullable = true)
~~~

## schema 自动扩展

Parquet 还支持 schema 自动扩展。

Scala:

~~~scala
// sqlContext from the previous example is used in this example.
// This is used to implicitly convert an RDD to a DataFrame.
import sqlContext.implicits._

// Create a simple DataFrame, stored into a partition directory
val df1 = sparkContext.makeRDD(1 to 5).map(i => (i, i * 2)).toDF("single", "double")
df1.saveAsParquetFile("data/test_table/key=1")

// Create another DataFrame in a new partition directory,
// adding a new column and dropping an existing column
val df2 = sparkContext.makeRDD(6 to 10).map(i => (i, i * 3)).toDF("single", "triple")
df2.saveAsParquetFile("data/test_table/key=2")

// Read the partitioned table
val df3 = sqlContext.parquetFile("data/test_table")
df3.printSchema()

// The final schema consists of all 3 columns in the Parquet files together
// with the partiioning column appeared in the partition directory paths.
// root
// |-- single: int (nullable = true)
// |-- double: int (nullable = true)
// |-- triple: int (nullable = true)
// |-- key : int (nullable = true)
~~~

Python:

~~~python
# sqlContext from the previous example is used in this example.

# Create a simple DataFrame, stored into a partition directory
df1 = sqlContext.createDataFrame(sc.parallelize(range(1, 6))\
                                   .map(lambda i: Row(single=i, double=i * 2)))
df1.save("data/test_table/key=1", "parquet")

# Create another DataFrame in a new partition directory,
# adding a new column and dropping an existing column
df2 = sqlContext.createDataFrame(sc.parallelize(range(6, 11))
                                   .map(lambda i: Row(single=i, triple=i * 3)))
df2.save("data/test_table/key=2", "parquet")

# Read the partitioned table
df3 = sqlContext.parquetFile("data/test_table")
df3.printSchema()

# The final schema consists of all 3 columns in the Parquet files together
# with the partiioning column appeared in the partition directory paths.
# root
# |-- single: int (nullable = true)
# |-- double: int (nullable = true)
# |-- triple: int (nullable = true)
# |-- key : int (nullable = true)
~~~

## 配置参数

- `spark.sql.parquet.binaryAsString`：默认为 false，是否将 binary 当做字符串处理
- `spark.sql.parquet.int96AsTimestamp`：默认为 true
- `spark.sql.parquet.cacheMetadata` ：默认为 true，是否缓存元数据
- `spark.sql.parquet.compression.codec`：默认为 gzip，支持的值：uncompressed, snappy, gzip, lzo
- `spark.sql.parquet.filterPushdown`：默认为 false
- `spark.sql.hive.convertMetastoreParquet`：默认为 false 

# JSON 数据源

Spark SQL 能够自动识别 JSON 数据的 schema ，SQLContext 中有两个方法处理 JSON：

- `jsonFile`：从一个 JSON 目录中加载数据，JSON 文件中每一行为一个 JSON 对象。
- `jsonRDD`：从一个 RDD 中加载数据，RDD 的每一个元素为一个 JSON 对象的字符串。

一个 Scala 的例子如下：

~~~scala
// sc is an existing SparkContext.
val sqlContext = new org.apache.spark.sql.SQLContext(sc)

// A JSON dataset is pointed to by path.
// The path can be either a single text file or a directory storing text files.
val path = "people.json"
// Create a DataFrame from the file(s) pointed to by path
val people = sqlContext.jsonFile(path)

// The inferred schema can be visualized using the printSchema() method.
people.printSchema()
// root
//  |-- age: integer (nullable = true)
//  |-- name: string (nullable = true)

// Register this DataFrame as a table.
people.registerTempTable("people")

// SQL statements can be run by using the sql methods provided by sqlContext.
val teenagers = sqlContext.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")

// Alternatively, a DataFrame can be created for a JSON dataset represented by
// an RDD[String] storing one JSON object per string.
val anotherPeopleRDD = sc.parallelize(
  """{"name":"Yin","address":{"city":"Columbus","state":"Ohio"}}""" :: Nil)
val anotherPeople = sqlContext.jsonRDD(anotherPeopleRDD)
~~~

# Hive 数据源

Spark SQL 支持读和写 Hive 中的数据。Spark  源码本身不包括 Hive，故编译时候需要添加  `-Phive` 和 `-Phive-thriftserver` 开启对 Hive 的支持。另外，Hive assembly jar 需要存在于每一个 worker 节点上，因为他们需要 SerDes 去访问存在于 Hive 中的数据。

Scala:

~~~scala
// sc is an existing SparkContext.
val sqlContext = new org.apache.spark.sql.hive.HiveContext(sc)

sqlContext.sql("CREATE TABLE IF NOT EXISTS src (key INT, value STRING)")
sqlContext.sql("LOAD DATA LOCAL INPATH 'examples/src/main/resources/kv1.txt' INTO TABLE src")

// Queries are expressed in HiveQL
sqlContext.sql("FROM src SELECT key, value").collect().foreach(println)
~~~

Java:

~~~java
// sc is an existing JavaSparkContext.
HiveContext sqlContext = new org.apache.spark.sql.hive.HiveContext(sc);

sqlContext.sql("CREATE TABLE IF NOT EXISTS src (key INT, value STRING)");
sqlContext.sql("LOAD DATA LOCAL INPATH 'examples/src/main/resources/kv1.txt' INTO TABLE src");

// Queries are expressed in HiveQL.
Row[] results = sqlContext.sql("FROM src SELECT key, value").collect();
~~~

Python:

~~~python
# sc is an existing SparkContext.
from pyspark.sql import HiveContext
sqlContext = HiveContext(sc)

sqlContext.sql("CREATE TABLE IF NOT EXISTS src (key INT, value STRING)")
sqlContext.sql("LOAD DATA LOCAL INPATH 'examples/src/main/resources/kv1.txt' INTO TABLE src")

# Queries can be expressed in HiveQL.
results = sqlContext.sql("FROM src SELECT key, value").collect()
~~~

# JDBC 数据源

Spark SQL 支持通过 JDBC 访问关系数据库，这需要用到 [JdbcRDD](https:/.apache.org/docs/latest/api/scala/index.html#org.apache.spark.rdd.JdbcRDD)。为了访问某一个关系数据库，需要将其驱动添加到 classpath，例如：

~~~
SPARK_CLASSPATH=postgresql-9.3-1102-jdbc41.jar bin-shell
~~~

访问 jdbc 数据源需要提供以下参数：

- url
- dbtable
- driver
- partitionColumn, lowerBound, upperBound, numPartitions

Scala 示例：

~~~scala
val jdbcDF = sqlContext.load("jdbc", Map(
  "url" -> "jdbc:postgresql:dbserver",
  "dbtable" -> "schema.tablename"))
~~~

Java:

~~~java
Map<String, String> options = new HashMap<String, String>();
options.put("url", "jdbc:postgresql:dbserver");
options.put("dbtable", "schema.tablename");

DataFrame jdbcDF = sqlContext.load("jdbc", options)
~~~

Python:

~~~python
df = sqlContext.load("jdbc", url="jdbc:postgresql:dbserver", dbtable="schema.tablename")
~~~

SQL:

~~~sql
CREATE TEMPORARY TABLE jdbcTable
USING org.apache.spark.sql.jdbc
OPTIONS (
  url "jdbc:postgresql:dbserver",
  dbtable "schema.tablename"
)
~~~

# 访问 Avro

这不是 Spark 内置的数据源，要想访问 Avro 数据源 ，需要做些处理。这部分内容可以参考 [如何将Avro数据加载到Spark](http://blog.javachen.com/2015/03/24/how-to-load-some-avro-data-into-spark.html) 和 [Spark with Avro](http://www.infoobjects.com-with-avro.html)。

# 访问 Cassandra

TODO

# 测试

## Spark 和 Parquet

参考上面的例子，将 people.txt 文件加载到 Spark：

~~~scala
scala> import sqlContext.implicits._
scala> case class People(name: String, age: Int)
scala> val people = sc.textFile("people.txt").map(_.split(",")).map(p => People(p(0), p(1).trim.toInt)).toDF()
scala> people.registerTempTable("people")
scala> val teenagers = sqlContext.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")
scala> teenagers.map(t => "Name: " + t(0)).collect().foreach(println)
~~~

然后，将 people 这个 DataFrame 转换为 parquet 格式：

~~~scala
scala> people.saveAsParquetFile("people.parquet")
scala> val parquetFile = sqlContext.parquetFile("people.parquet")
~~~

另外，也可以从 hive 中加载 parquet 格式的文件。

~~~sql
hive> create table people_parquet like people stored as parquet;
hive> insert overwrite table people_parquet select * from people;
~~~

使用 HiveContext 来从 hive 中加载 parquet 文件，这里不再需要定义一个 case class ，因为 parquet 中已经包含了文件的 schema。

~~~scala
scala> val hc = new org.apache.spark.sql.hive.HiveContext(sc)
scala> import hc.implicits._
scala>val peopleRDD = hc.parquetFile("people.parquet")
scala> peopleRDD.registerAsTempTable("pp")
scala>val teenagers = hc.sql("SELECT name FROM pp WHERE age >= 13 AND age <= 19")
scala>teenagers.collect.foreach(println)
~~~

注意到 impala 中处理 parquet 文件时，会将字符串保存为 Binary，为了修正这个问题，可以添加下面一行代码：

~~~scala
scala> sqlContext.setConf("spark.sql.parquet.binaryAsString","true")
~~~

## SparkSql Join

下面是两个表左外连接的例子：

~~~scala
scala>import sqlContext.implicits._
scala>import org.apache.spark.sql.catalyst.plans._

scala> case class Dept(dept_id:String,dept_name:String)
scala> val dept = sc.parallelize(List( ("DEPT01","Information Technology"), ("DEPT02","WHITE HOUSE"),("DEPT03","EX-PRESIDENTS OFFICE"),("DEPT04","SALES"))).map( d => Dept(d._1,d._2)).toDF.as( "dept" )

scala> case class Emp(first_name:String,last_name:String,dept_id:String)
scala> val emp = sc.parallelize(List( ("Rishi","Yadav","DEPT01"),("Barack","Obama","DEPT02"),("Bill","Clinton","DEPT04"))).map( e => Emp(e._1,e._2,e._3)).toDF.as("emp")

scala> val alldepts = dept.join(emp,dept("dept_id") === emp("dept_id"), "left_outer").select("dept.dept_id","dept_name","first_name","last_name")

scala> alldepts.foreach(println)
[DEPT01,Information Technology,Rishi,Yadav]
[DEPT02,WHITE HOUSE,Barack,Obama]
[DEPT04,SALES,Bill,Clinton]
[DEPT03,EX-PRESIDENTS OFFICE,null,null]
~~~

支持的连接类型有：`inner`、`outer`、`left_outer`、`right_outer`、`semijoin`。

# 参考文章

- [Spark SQL and DataFrame Guide](https:/.apache.org/docs/latest/sql-programming-guide.html#dataframes)
- [Spark 编程指南简体中文版-Spark SQL](http://endymecy.gitbooks.io-programming-guide-zh-cn/content-sql/README.html)
- [spark-cookbook](http://www.infoobjects.com-cookbook/)
