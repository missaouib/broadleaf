---
layout: post

title: 编译CDH Spark源代码
date: 2015-04-28T08:00:00+08:00

categories: [ spark ]

tags: [ spark ]

description: 本文以Cloudera维护的Spark分支项目为例，记录跟新Spark分支以及编译Spark源代码的过程。

published: true

---

本文以Cloudera维护的Spark分支项目为例，记录跟新Spark分支以及编译Spark源代码的过程。

# 下载代码

在Github上fork Cloudera维护的[Spark]( https://github.com/cloudera)项目到自己的github账号里，对应的地址为<https://github.com/javachen>。

下载代码：

~~~bash
$ git clone https://github.com/javachen
~~~

然后，切换到最新的分支，当前为 cdh5-1.3.0_5.4.0。

~~~bash
$ cd spark
$ git checkout cdh5-1.3.0_5.4.0
~~~

查看当前分支：

~~~bash
⇒  git branch
* cdh5-1.3.0_5.4.0
  master
~~~

如果spark发布了新的版本，需要同步到我自己维护的spark项目中，可以按以下步骤进行操作:

~~~bash
# 添加远程仓库地址
$ git remote add cdh git@github.com:cloudera.git

# 抓取远程仓库更新：
$ git fetch cdh

# 假设cloudera发布了新的版本 cdh/cdh5-1.3.0_5.4.X
$ git checkout -b cdh5-1.3.0_5.4.X cdh/cdh5-1.3.0_5.4.X

# 切换到新下载的分支 
$ git checkout cdh5-1.3.0_5.4.X

# 将其提交到自己的远程仓库：
$ git push origin cdh5-1.3.0_5.4.X:cdh5-1.3.0_5.4.X
~~~

# 编译

## 安装 zinc

在mac上安装[zinc](https://github.com/typesafehub/zinc)：

~~~bash
$ brew install zinc
~~~

## 使用maven编译

指定hadoop版本为`2.6.0-cdh5.4.0`，并集成yarn和hive：

~~~bash
$ export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"
$ mvn -Pyarn -Dhadoop.version=2.6.0-cdh5.4.0 -Phive -DskipTests clean package
~~~

在CDH的spark中，要想集成`hive-thriftserver`进行编译，需要修改 pom.xml 文件，添加一行 <module>sql/hive-thriftserver</module>：

~~~xml
<modules>
    <module>core</module>
    <module>bagel</module>
    <module>graphx</module>
    <module>mllib</module>
    <module>tools</module>
    <module>streaming</module>
    <module>sql/catalyst</module>
    <module>sql/core</module>
    <module>sql/hive</module>
    <module>sql/hive-thriftserver</module> <!--添加的一行-->
    <module>repl</module>
    <module>assembly</module>
    <module>external/twitter</module>
    <module>external/kafka</module>
    <module>external/flume</module>
    <module>external/flume-sink</module>
    <module>external/zeromq</module>
    <module>external/mqtt</module>
    <module>examples</module>
  </modules>
~~~

然后，再执行：

~~~bash
$ export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"
$ mvn -Pyarn -Dhadoop.version=2.6.0-cdh5.4.0 -Phive -Phive-thriftserver -DskipTests clean package
~~~

运行测试用例：

~~~bash
$ mvn -Pyarn -Dhadoop.version=2.6.0-cdh5.4.0 -Phive  test
~~~

运行java8测试：

~~~bash
$ mvn install -DskipTests -Pjava8-tests
~~~

## 使用sbt编译

~~~bash
$ build/sbt -Pyarn -Dhadoop.version=2.6.0-cdh5.4.0 -Phive assembly
~~~

## 生成压缩包

~~~bash
$ ./make-distribution.sh
~~~

# 排错

1. ` Unable to find configuration file at location scalastyle-config.xml` 异常

在idea中使用maven对examples模块运行`package`或者`install`命令会出现` Unable to find configuration file at location scalastyle-config.xml`异常，解决办法是将根目录下的scalastyle-config.xml拷贝到examples目录下去，这是因为pom.xml中定义的是scalastyle-maven-plugin插件从maven运行的当前目录查找该文件。

~~~xml
<plugin>
    <groupId>org.scalastyle</groupId>
    <artifactId>scalastyle-maven-plugin</artifactId>
    <version>0.4.0</version>
    <configuration>
      <verbose>false</verbose>
      <failOnViolation>true</failOnViolation>
      <includeTestSourceDirectory>false</includeTestSourceDirectory>
      <failOnWarning>false</failOnWarning>
      <sourceDirectory>${basedir}/src/main/scala</sourceDirectory>
      <testSourceDirectory>${basedir}/src/test/scala</testSourceDirectory>
      <configLocation>scalastyle-config.xml</configLocation>
      <outputFile>scalastyle-output.xml</outputFile>
      <outputEncoding>UTF-8</outputEncoding>
    </configuration>
    <executions>
      <execution>
        <phase>package</phase>
        <goals>
          <goal>check</goal>
        </goals>
      </execution>
    </executions>
</plugin>
~~~



# 参考

- [Building Spark](http:/.apache.org/docs/latest/building-spark.html)
