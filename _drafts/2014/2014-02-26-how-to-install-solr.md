---
layout: post
title: Apache Solr介绍及安装

description: 本文记录如何安装Solr。Solr是一个基于Lucene的Java搜索引擎服务器。Solr提供了层面搜索、命中醒目显示并且支持多种输出格式。

category: search-engine

tags: [solr]
---

# Solr是什么

Solr是一个基于Lucene java库的企业级搜索服务器，包含XML/HTTP，JSON API，高亮查询结果，缓存，复制，还有一个WEB管理界面。Solr运行在Servlet容器中，其架构如下：

![](http://7xnrdo.com1.z0.glb.clouddn.com/2014/solr-architecture.jpg)

主要功能包括全文检索，高亮命中，分面搜索(faceted search)，近实时索引，动态集群，数据库集成，富文本索引，空间搜索；通过提供分布式索引，复制，负载均衡查询，自动故障转移和恢复，集中配置等功能实现高可用，可伸缩和可容错。

Solr和Lucene的本质区别有以下三点：搜索服务器、企业级和管理。Lucene本质上是搜索库，不是独立的应用程序，而Solr是。Lucene专注于搜索底层的建设，而Solr专注于企业应用。Lucene不负责支撑搜索服务所必须的管理，而Solr负责。所以说Solr是Lucene面向企业搜索应用的扩展。

Solr目前有很多用户了，比较著名的用户有 AOL、 Disney、 Apple等，国内的有淘宝，淘宝的终搜就是基于Solr改造的，终搜用于淘宝的SNS、淘女郎等处的搜索。

# 安装和部署

## 1. 下载

官方网址：[http://lucene.apache.org/solr/](http://lucene.apache.org/solr/) 

下载地址：[http://archive.apache.org/dist/lucene/solr/](http://archive.apache.org/dist/lucene/solr/)

## 2. 安装与配置

以solr-4.4.0为例，解压之后的目录如下：

~~~
➜  solr-4.4.0  tree -L 1
.
├── CHANGES.txt
├── contrib
├── dist
├── docs
├── example
├── licenses
├── LICENSE.txt
├── NOTICE.txt
├── README.txt
└── SYSTEM_REQUIREMENTS.txt

5 directories, 5 files
~~~

solr提供一个war包可以运行web界面，该文件位于`exmaple/webapps`目录下，发布该war包之前需要配置solr home，solr home是索引和配置文件所在的目录。

solr home的设置有好几种方式：

1、 基于环境变量solr.solr.home 

直接修改JAVA全局环境变量

~~~
export JAVA_OPTS="$JAVA_OPTS -Dsolr.solr.home=/tmp/solrhome"
~~~

你也可以修改`TOMCAT_HOME/bin/catalina.sh`，在文件开头添加：

~~~
JAVA_OPTS='-Dsolr.solr.home=/tmp/solrhome'
~~~

或者，在启动时进行设置。start.jar在源码包中可以找到，内部包含jetty容器。

~~~
$ java -Dsolr.solr.home=/tmp/solrhome -jar start.jar
~~~

2、 基于JNDI配置 

修改war中的web.xml文件，取消下面对下面的注视，并修改`env-entry-value`的值。

~~~xml
<env-entry>
   <env-entry-name>solr/home</env-entry-name>
   <env-entry-value>/tmp/solrhome</env-entry-value>
   <env-entry-type>java.lang.String</env-entry-type>
</env-entry>
~~~

或者，创建solr.xml文件放于`TOMCAT_HOME/conf/Catalina/localhost`，内容如下： 

~~~xml
<?xml version="1.0" encoding="utf-8"?>
<Context docBase="TOMCAT_HOME/webapps/solr.war" debug="0" crossContext="true">
   <Environment name="solr/home" type="java.lang.String" value="/tmp/solrhomehome" override="true"/>
</Context>
~~~

3、 基于当前路径的方式

这种情况需要在example目录下去启动tomcat，Solr查找./solr，因此在启动时候需要切换到example目录下面

## 3. 在Jetty上运行Solr

在example目录下，运行下面命令即可启动一个内置的jetty容器：

~~~
$ java -Dsolr.solr.home=/tmp/solrhome -jar start.jar
~~~

通过`http://localhost:8983/solr`即可访问。

## 4. 在tomcat中运行Solr

将`example/webapps/solr.war`拷贝到tomcat的webapps目录下，然后参照上面的说明设置solr home值。tomcat版本可以使用tomcat-6.0.36。

其次，将`example/lib/ext`目录中的jar包拷贝到`tomcat-6.0.36/webapps/solr/WEB-INF/lib`目录下。

然后，将`example/resources/log4j.properties`也拷到classpath，或者在tomcat-6.0.36/webapps/solr/目录下新建了一个classes目录，将log4j.properties放进去。

这时候启动tomcat后访问`http://localhost:8080/solr`会提示错误，这是因为solr home目录下没有solr的配置文件和一些目录。请将solr-4.4.0/example/solr/目录下的文件拷贝到solr home目录下，例如：

~~~
$ cp -r solr-4.4.0/example/solr/ /tmp/solrhome/
~~~

最后，启动tomcat，然后通过浏览器访问。

## 5. 其他

### 关于中文支持

关于中文，solr内核支持UTF-8编码，所以在tomcat里的server.xml需要进行配置

~~~xml
<Connector port="8080" maxHttpHeaderSize="8192" URIEncoding="UTF-8" />
~~~

另外，向solr Post请求的时候需要转为utf-8编码。对solr 返回的查询结果也需要进行一次utf-8的转码。检索数据时对查询的关键字也需要转码，然后用“+”连接。

~~~java
String[] array = StringUtils.split(query, null, 0);
for (String str : array) {
    result = result + URLEncoder.encode(str, "UTF-8") + "+";
}
~~~

