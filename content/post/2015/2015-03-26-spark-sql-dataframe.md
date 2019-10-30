---
layout: post

title: Spark SQL中的DataFrame
date: 2015-03-26T08:00:00+08:00

categories: [ spark ]

tags: [ spark-sql,spark ]

description: 在 Spark 1.3 中，SchemaRDD 改为叫做 DataFrame，DataFrame 与关系型数据库中的表很相似，可以通过存在的 RDD、一个 Parquet 文件、结构化的文件、外部数据库、或者对存储在 Apache Hive 中的数据执行 HiveSQL 查询中创建。

published: true

---

在2014年7月1日的 Spark Summit 上，Databricks 宣布终止对 Shark 的开发，将重点放到 Spark SQL 上。在会议上，Databricks 表示，Shark 更多是对 Hive 的改造，替换了 Hive 的物理执行引擎，因此会有一个很快的速度。然而，不容忽视的是，Shark 继承了大量的 Hive 代码，因此给优化和维护带来了大量的麻烦。随着性能优化和先进分析整合的进一步加深，基于 MapReduce 设计的部分无疑成为了整个项目的瓶颈。 详细内容请参看 [Shark, Spark SQL, Hive on Spark, and the future of SQL on Spark](http://databricks.com/blog/2014/07/01/shark-spark-sql-hive-on-spark-and-the-future-of-sql-on-spark.html)。

Spark SQL 允许 Spark 执行用 SQL, HiveQL 或者 Scala 表示的关系查询。在 Spark 1.3 之前，这个模块的核心是一个新类型的 RDD-[SchemaRDD](http:/.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.SchemaRDD)。 SchemaRDDs 由[行](http:/.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.package@Row:org.apache.spark.sql.catalyst.expressions.Row.type)对象组成，行对象拥有一个模式（scheme） 来描述行中每一列的数据类型。SchemaRDD 与关系型数据库中的表很相似，可以通过存在的 RDD、一个 [Parquet](http://parquet.io/) 文件、结构化的文件、外部数据库、或者对存储在 Apache Hive 中的数据执行 HiveSQL 查询中创建。

当前 Spark SQL 还处于 alpha 阶段，一些 API 在将将来的版本中可能会有所改变。例如，[Apache Spark 1.3发布，新增Data Frames API，改进Spark SQL和MLlib](http://www.infoq.com/cn/news/2015/03/apache-spark-1.3-released)。在 Spark 1.3 中，SchemaRDD 改为叫做 DataFrame。

本文是基于 Spark 1.3 写成，特此说明。

# 创建 SQLContext

Spark SQL 中所有相关功能的入口点是 [SQLContext](http:/.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.SQLContext) 类或者它的子类， 创建一个 SQLContext 的所有需要仅仅是一个 SparkContext。

使用 Scala 创建方式如下：

~~~scala
val sc: SparkContext // An existing SparkContext.
val sqlContext = new org.apache.spark.sql.SQLContext(sc)

// this is used to implicitly convert an RDD to a DataFrame.
import sqlContext.implicits._
~~~

使用 Java 创建方式如下：

~~~java
JavaSparkContext sc = ...; // An existing JavaSparkContext.
SQLContext sqlContext = new org.apache.spark.sql.SQLContext(sc);
~~~

使用 Python 创建方式如下：

~~~python
from pyspark.sql import SQLContext
sqlContext = SQLContext(sc)
~~~

除了一个基本的 SQLContext，你也能够创建一个 HiveContext，它支持基本 SQLContext 所支持功能的一个超集。它的额外的功能包括用更完整的 HiveQL 分析器写查询去访问 HiveUDFs 的能力、 从 Hive 表读取数据的能力。用 HiveContext 你不需要一个已经存在的 Hive 开启，SQLContext 可用的数据源对 HiveContext 也可用。HiveContext 分开打包是为了避免在 Spark 构建时包含了所有 的 Hive 依赖。如果对你的应用程序来说，这些依赖不存在问题，Spark 1.3 推荐使用 HiveContext。以后的稳定版本将专注于为 SQLContext 提供与 HiveContext 等价的功能。

用来解析查询语句的特定 SQL 变种语言可以通过 `spark.sql.dialect` 选项来选择。这个参数可以通过两种方式改变，一种方式是通过 `setConf` 方法设定，另一种方式是在 SQL 命令中通过 `SET key=value` 来设定。对于 SQLContext，唯一可用的方言是 “sql”，它是 Spark SQL 提供的一个简单的 SQL 解析器。在 HiveContext 中，虽然也支持"sql"，但默认的方言是 “hiveql”，这是因为 HiveQL 解析器更完整。

# 创建 DataFrame

使用 SQLContext，应用可以从一个存在的 RDD、Hive 表或者数据源中创建 DataFrame。

下载测试数据 [people.json](https://raw.githubusercontent.com/apache/master/examples/src/main/resources/people.json)，并将其上传到 HDFS 上：

~~~bash
$ wget https://raw.githubusercontent.com/apache/master/examples/src/main/resources/people.json
$ hadoop fs -put people.json
~~~

下面是使用 Scala 创建方式：

~~~scala
val sqlContext = new org.apache.spark.sql.SQLContext(sc)

val df = sqlContext.jsonFile("people.json")

// Displays the content of the DataFrame to stdout
df.show()
~~~

下面是使用 Java 创建方式：

~~~java
JavaSparkContext sc = ...; // An existing JavaSparkContext.
SQLContext sqlContext = new org.apache.spark.sql.SQLContext(sc);

DataFrame df = sqlContext.jsonFile("people.json");

// Displays the content of the DataFrame to stdout
df.show();
~~~

下面是使用 Python 创建方式：

~~~python
from pyspark.sql import SQLContext
sqlContext = SQLContext(sc)

df = sqlContext.jsonFile("people.json")

# Displays the content of the DataFrame to stdout
df.show()
~~~

DataFrame API 请参考 [Scala](https:/.apache.org/docs/latest/api/scala/index.html#org.apache.spark.sql.DataFrame)、[Java](https:/.apache.org/docs/latest/api/java/index.html?org/apache/sql/DataFrame.html) 以及 [Python](https:/.apache.org/docs/latest/api/python/pyspark.sql.html#pyspark.sql.DataFrame)。

## DataFrame 操作

运行 spark-shell 执行下面代码进行测试，运行的代码和输出结果如下：

~~~scala
$ spark-shell
Spark context available as sc.
SQL context available as sqlContext.

// Create the DataFrame
scala> val df = sqlContext.jsonFile("people.json")

scala> df.count()
res1: Long = 3

scala> df.first()
res2: org.apache.spark.sql.Row = [null,Michael]

scala> df.head()
res3: org.apache.spark.sql.Row = [null,Michael]

scala> df.collect()
res4: Array[org.apache.spark.sql.Row] = Array([null,Michael], [30,Andy], [19,Justin])

scala> df.collectAsList()
res5: java.util.List[org.apache.spark.sql.Row] = [[null,Michael], [30,Andy], [19,Justin]]

// Show the content of the DataFrame
scala> df.show()
age  name
null Michael
30   Andy
19   Justin

scala> df.take(2)
res6: Array[org.apache.spark.sql.Row] = Array([null,Michael], [30,Andy])

scala> df.columns
res7: Array[String] = Array(age, name)

scala> df.dtypes
res8: Array[(String, String)] = Array((age,LongType), (name,StringType))

// Print the schema in a tree format
scala> df.printSchema()
root
 |-- age: long (nullable = true)
 |-- name: string (nullable = true)

scala> df.explain()
== Physical Plan ==
PhysicalRDD [age#0L,name#1], MapPartitionsRDD[96] at map at JsonRDD.scala:41

// age column
scala> val ageCol = df("age")  

// The following creates a new column that increases everybody's age by 10.
scala> df("age") + 10 

// Select only the "name" column
scala> df.select("name").show()
name
Michael
Andy
Justin

// Select everybody, but increment the age by 1
scala> df.select(df("name"), df("age")+1).show()
name    (age + 1)
Michael null
Andy    31
Justin  20

// Select people older than 21
scala> df.filter(df("age") > 21).show()
age name
30  Andy

// Count people by age
scala> df.groupBy("age").count().show()
age  count
null 1
19   1
30   1
~~~

## 运行 SQL 查询

SQLContext 有一个 sql 方法，可以运行 SQL 查询。

~~~java
sqlContext.sql("SELECT * FROM table")
~~~

Spark SQL 支持两种方法将存在的 RDD 转换为 DataFrame 。第一种方法使用反射来推断包含特定对象类型的 RDD 的模式。在你写 spark 程序的同时，当你已经知道了模式，这种基于反射的方法可以使代码更简洁并且程序工作得更好。

第二种方法是通过一个编程接口来实现，这个接口允许你构造一个模式，然后在存在的 RDD 上使用它。虽然这种方法更冗长，但是它允许你在运行期之前不知道列以及列的类型的情况下构造 DataFrame。

SQLContext 的 API 见 [SQLContext](https:/.apache.org/docs/1.3.0/api/scala/index.html#org.apache.spark.sql.SQLContext) 。

### 利用反射推断模式

Spark SQL的 Scala 接口支持将包含样本类的 RDD 自动转换为 DataFrame。这个样本类定义了表的模式。样本类的参数名字通过反射来读取，然后作为列的名字。样本类可以嵌套或者包含复杂的类型如序列或者数组。这个 RDD 可以隐式转化为一个 DataFrame，然后注册为一个表，表可以在后续的 sql 语句中使用。

以 [people.txt](https://raw.githubusercontent.com/apache/master/examples/src/main/resources/people.txt) 作为测试数据，使用 Scala 语言来创建 DataFrame：

~~~scala
// sc is an existing SparkContext.
val sqlContext = new org.apache.spark.sql.SQLContext(sc)
// this is used to implicitly convert an RDD to a DataFrame.
import sqlContext.implicits._

// Define the schema using a case class.
// Note: Case classes in Scala 2.10 can support only up to 22 fields. To work around this limit,
// you can use custom classes that implement the Product interface.
case class People(name: String, age: Int)

// Create an RDD of Person objects and register it as a table.
val people = sc.textFile("people.txt").map(_.split(",")).map(p => People(p(0), p(1).trim.toInt)).toDF()
people.registerTempTable("people")

// SQL statements can be run by using the sql methods provided by sqlContext.
val teenagers = sqlContext.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")

// The results of SQL queries are DataFrames and support all the normal RDD operations.
// The columns of a row in the result can be accessed by ordinal.
teenagers.map(t => "Name: " + t(0)).collect().foreach(println)
~~~

对于 Java 语言，需要创建一个 JavaBean，然后在将数据映射到它上面：

~~~java
public static class People implements Serializable {
  private String name;
  private int age;

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public int getAge() {
    return age;
  }

  public void setAge(int age) {
    this.age = age;
  }
}
~~~

然后，使用 sqlContext 的 createDataFrame 方法，从 JavaBean 和数据上创建一个 DataFrame 并注册一个表，下面是一个比较完整的例子：

~~~java
import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.api.java.function.Function;
import org.apache.spark.sql.DataFrame;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SQLContext;

import java.io.Serializable;
import java.util.Arrays;
import java.util.List;

public class JavaSparkSQLByReflection {
    public static void main(String[] args) throws Exception {
        SparkConf sparkConf = new SparkConf().setAppName("JavaSparkSQLByReflection");
        JavaSparkContext ctx = new JavaSparkContext(sparkConf);
        SQLContext sqlCtx = new SQLContext(ctx);

        System.out.println("=== Data source: RDD ===");
        // Load a text file and convert each line to a Java Bean.
        JavaRDD<People> people = ctx.textFile("people.txt").map(
                new Function<String, People>() {
                    @Override
                    public People call(String line) {
                        String[] parts = line.split(",");

                        People people = new People();
                        people.setName(parts[0]);
                        people.setAge(Integer.parseInt(parts[1].trim()));
                        return people;
                    }
                });

        // Apply a schema to an RDD of Java Beans and register it as a table.
        DataFrame schemaPeople = sqlCtx.createDataFrame(people, People.class);
        schemaPeople.registerTempTable("people");

        // SQL can be run over RDDs that have been registered as tables.
        DataFrame teenagers = sqlCtx.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19");

        // The results of SQL queries are DataFrames and support all the normal RDD operations.
        // The columns of a row in the result can be accessed by ordinal.
        List<String> teenagerNames = teenagers.toJavaRDD().map(new Function<Row, String>() {
            @Override
            public String call(Row row) {
                return "Name: " + row.getString(0);
            }
        }).collect();

        for (String name : teenagerNames) {
            System.out.println(name);
        }


        System.out.println("=== Data source: Parquet File ===");
        // DataFrames can be saved as parquet files, maintaining the schema information.
        schemaPeople.saveAsParquetFile("people.parquet");

        // Read in the parquet file created above.
        // Parquet files are self-describing so the schema is preserved.
        // The result of loading a parquet file is also a DataFrame.
        DataFrame parquetFile = sqlCtx.parquetFile("people.parquet");

        //Parquet files can also be registered as tables and then used in SQL statements.
        parquetFile.registerTempTable("parquetFile");
        DataFrame teenagers2 =
                sqlCtx.sql("SELECT name FROM parquetFile WHERE age >= 13 AND age <= 19");
        teenagerNames = teenagers2.toJavaRDD().map(new Function<Row, String>() {
            @Override
            public String call(Row row) {
                return "Name: " + row.getString(0);
            }
        }).collect();
        for (String name : teenagerNames) {
            System.out.println(name);
        }

        System.out.println("=== Data source: JSON Dataset ===");
        // A JSON dataset is pointed by path.
        // The path can be either a single text file or a directory storing text files.
        String path = "people.json";
        // Create a DataFrame from the file(s) pointed by path
        DataFrame peopleFromJsonFile = sqlCtx.jsonFile(path);

        // Because the schema of a JSON dataset is automatically inferred, to write queries,
        // it is better to take a look at what is the schema.
        peopleFromJsonFile.printSchema();
        // The schema of people is ...
        // root
        //  |-- age: IntegerType
        //  |-- name: StringType

        // Register this DataFrame as a table.
        peopleFromJsonFile.registerTempTable("people");

        // SQL statements can be run by using the sql methods provided by sqlCtx.
        DataFrame teenagers3 = sqlCtx.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19");

        // The results of SQL queries are DataFrame and support all the normal RDD operations.
        // The columns of a row in the result can be accessed by ordinal.
        teenagerNames = teenagers3.toJavaRDD().map(new Function<Row, String>() {
            @Override
            public String call(Row row) {
                return "Name: " + row.getString(0);
            }
        }).collect();
        for (String name : teenagerNames) {
            System.out.println(name);
        }

        // Alternatively, a DataFrame can be created for a JSON dataset represented by
        // a RDD[String] storing one JSON object per string.
        List<String> jsonData = Arrays.asList(
                "{\"name\":\"Yin\",\"address\":{\"city\":\"Columbus\",\"state\":\"Ohio\"}}");
        JavaRDD<String> anotherPeopleRDD = ctx.parallelize(jsonData);
        DataFrame peopleFromJsonRDD = sqlCtx.jsonRDD(anotherPeopleRDD.rdd());


        // Take a look at the schema of this new DataFrame.
        peopleFromJsonRDD.printSchema();
        // The schema of anotherPeople is ...
        // root
        //  |-- address: StructType
        //  |    |-- city: StringType
        //  |    |-- state: StringType
        //  |-- name: StringType
        peopleFromJsonRDD.registerTempTable("people2");

        DataFrame peopleWithCity = sqlCtx.sql("SELECT name, address.city FROM people2");
        List<String> nameAndCity = peopleWithCity.toJavaRDD().map(new Function<Row, String>() {
            @Override
            public String call(Row row) {
                return "Name: " + row.getString(0) + ", City: " + row.getString(1);
            }
        }).collect();
        for (String name : nameAndCity) {
            System.out.println(name);
        }

        ctx.stop();
    }
}
~~~

使用 Python 语言则需要用到 sqlContext 的 inferSchema 方法：

~~~python
# sc is an existing SparkContext.
from pyspark.sql import SQLContext, Row
sqlContext = SQLContext(sc)

# Load a text file and convert each line to a Row.
lines = sc.textFile("people.txt")
parts = lines.map(lambda l: l.split(","))
people = parts.map(lambda p: Row(name=p[0], age=int(p[1])))

# Infer the schema, and register the DataFrame as a table.
schemaPeople = sqlContext.inferSchema(people)
schemaPeople.registerTempTable("people")

# SQL can be run over DataFrames that have been registered as a table.
teenagers = sqlContext.sql("SELECT name FROM people WHERE age >= 13 AND age <= 19")

# The results of SQL queries are RDDs and support all the normal RDD operations.
teenNames = teenagers.map(lambda p: "Name: " + p.name)
for teenName in teenNames.collect():
  print teenName
~~~

### 编程指定模式

当样本类不能提前确定（例如，记录的结构是经过编码的字符串，或者一个文本集合将会被解析，不同的字段投影给不同的用户），一个 DataFrame 可以通过三步来创建。

- 从原来的 RDD 创建一个行的 RDD
- 创建由一个 StructType 表示的模式与第一步创建的 RDD 的行结构相匹配
- 在行 RDD 上通过 applySchema 方法应用模式

直接贴出代码，Scala 语言创建方式：

~~~scala
val sc = new SparkContext(new SparkConf().setAppName("ScalaSparkSQL"))
val sqlContext = new org.apache.spark.sql.SQLContext(sc)

// Create an RDD
val people = sc.textFile("people.txt")

// The schema is encoded in a string
val schemaString = "name age"

// Import Spark SQL data types and Row.
import org.apache.spark.sql._

// Generate the schema based on the string of schema
val schema =
  StructType(
    schemaString.split(" ").map(fieldName => StructField(fieldName, StringType, true)))

// Convert records of the RDD (people) to Rows.
val rowRDD = people.map(_.split(",")).map(p => Row(p(0), p(1).trim))

// Apply the schema to the RDD.
val peopleDataFrame = sqlContext.createDataFrame(rowRDD, schema)

// Register the DataFrames as a table.
peopleDataFrame.registerTempTable("people")

// SQL statements can be run by using the sql methods provided by sqlContext.
val results = sqlContext.sql("SELECT name FROM people")

// The results of SQL queries are DataFrames and support all the normal RDD operations.
// The columns of a row in the result can be accessed by ordinal.
results.map(t => "Name: " + t(0)).collect().foreach(println)
~~~

Java 创建的方式或许对一个 Java 程序员来说，更容易理解：

~~~java
import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.api.java.function.Function;
import org.apache.spark.sql.DataFrame;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SQLContext;

import java.util.List;

public class JavaSparkSQLBySchema {
    public static void main(String[] args) throws Exception {
        SparkConf sparkConf = new SparkConf().setAppName("JavaSparkSQLBySchema");
        JavaSparkContext ctx = new JavaSparkContext(sparkConf);
        SQLContext sqlContext = new org.apache.spark.sql.SQLContext(sc);

        // Load a text file and convert each line to a JavaBean.
        JavaRDD<String> people = sc.textFile("people.txt");

        // The schema is encoded in a string
        String schemaString = "name age";

        // Generate the schema based on the string of schema
        List<StructField> fields = new ArrayList<StructField>();
        for (String fieldName : schemaString.split(" ")) {
            fields.add(DataType.createStructField(fieldName, DataType.StringType, true));
        }
        StructType schema = DataType.createStructType(fields);

        // Convert records of the RDD (people) to Rows.
        JavaRDD<Row> rowRDD = people.map(
                new Function<String, Row>() {
                    public Row call(String record) throws Exception {
                        String[] fields = record.split(",");
                        return Row.create(fields[0], fields[1].trim());
                    }
                });

        // Apply the schema to the RDD.
        DataFrame peopleDataFrame = sqlContext.createDataFrame(rowRDD, schema);

        // Register the DataFrame as a table.
        peopleDataFrame.registerTempTable("people");

        // SQL can be run over RDDs that have been registered as tables.
        DataFrame results = sqlContext.sql("SELECT name FROM people");

        // The results of SQL queries are DataFrames and support all the normal RDD operations.
        // The columns of a row in the result can be accessed by ordinal.
        List<String> names = results.map(new Function<Row, String>() {
            public String call(Row row) {
                return "Name: " + row.getString(0);
            }
        }).collect();
    }
}

~~~

Python 语言的例子：

~~~python
# Import SQLContext and data types
from pyspark.sql import *

# sc is an existing SparkContext.
sqlContext = SQLContext(sc)

# Load a text file and convert each line to a tuple.
lines = sc.textFile("people.txt")
parts = lines.map(lambda l: l.split(","))
people = parts.map(lambda p: (p[0], p[1].strip()))

# The schema is encoded in a string.
schemaString = "name age"

fields = [StructField(field_name, StringType(), True) for field_name in schemaString.split()]
schema = StructType(fields)

# Apply the schema to the RDD.
schemaPeople = sqlContext.createDataFrame(people, schema)

# Register the DataFrame as a table.
schemaPeople.registerTempTable("people")

# SQL can be run over DataFrames that have been registered as a table.
results = sqlContext.sql("SELECT name FROM people")

# The results of SQL queries are RDDs and support all the normal RDD operations.
names = results.map(lambda p: "Name: " + p.name)
for name in names.collect():
  print name
~~~

# 总结

本文主要介绍了 DataFrame 是什么以及两种从 RDD 创建 DataFrame 的方法，完整的代码见 [Github](https://github.com/javachen-examples)。

# 参考文章

- [Spark SQL and DataFrame Guide](https:/.apache.org/docs/latest/sql-programming-guide.html#dataframes)
- [Spark 编程指南简体中文版-Spark SQL](http://endymecy.gitbooks.io-programming-guide-zh-cn/content-sql/README.html)
