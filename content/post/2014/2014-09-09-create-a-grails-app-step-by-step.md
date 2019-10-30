---
layout: post

title:  从零开始创建Grails应用
date: 2014-09-09T08:00:00+08:00

description: 本篇文章主要介绍如何从零开始一步一步创建一个 Grails 应用程序。整个过程中，你将学到如何改变 Grails 运行的端口，了解 Grails 应用的基础组成部分(领域类、控制器和 视图)、指定字段的缺省值，以及其他许多内容。

keywords:  

categories: [  java ]

tags: [grails]

published: true

---

本篇文章主要介绍如何从零开始一步一步创建一个 Grails 应用程序。整个过程中，你将学到如何改变 Grails 运行的端口，了解 Grails 应用的基础组成部分(领域类、控制器和视图)、指定字段的缺省值，以及其他许多内容。

# 1. 安装

下载压缩包然后解压或者通过rpm、deb发行包安装。

这里，我在 mac 上安装 grails ：

~~~bash
$ brew install grails
~~~

# 2. 创建应用

以 blog 为例，创建一个应用程序，在命令行输入 `grails create-app blog` ：

~~~bash
$ grails create-app blog
2014-9-9 10:43:29 org.codehaus.groovy.runtime.m12n.MetaInfExtensionModule newModule
警告: Module [groovy-all] - Unable to load extension class [org.codehaus.groovy.runtime.NioGroovyMethods]
2014-9-9 10:43:29 org.codehaus.groovy.runtime.m12n.MetaInfExtensionModule newModule
| Created Grails Application at /Users/june/workspace/groovy/blog
~~~

这样，就创建了一个空的应用程序，进入到 blog 目录，输入 `grails run-app` :

~~~bash
$ cd blog
$ grails run-app
...
2014-9-9 10:45:31 org.codehaus.groovy.runtime.m12n.MetaInfExtensionModule newModule
警告: Module [groovy-all] - Unable to load extension class [org.codehaus.groovy.runtime.NioGroovyMethods]
| Server running. Browse to http://localhost:8080/blog
~~~

一切顺刟癿话，你应该可以在浏觅器中访问 `http://localhost:8080/blog/` 并查看欢迎页面。

如果发现端口冲突，你可以[修改默认端口](http://tilt.lib.tsinghua.edu.cn/node/624)：

- 在启动时添加参数：`grails -Dserver.port=9090 run-app`
- 在 grails-app/conf 目录修改 BuildConfig.groovy，添加 `grails.server.port.http=9090` 或 `server.port=9090`
- 修改用户的默认设置。修改 `~/.grails/settings.groovy`，添加 `grails.server.port.http = 9000`
- 修改Grails程序的默认设置。在 `$GRAILS_HOME/scripts/_GrailsSettings.groovy` 中添加：`serverPort = getPropertyValue("server.port", 9000).toInteger()`

测试应用：

~~~bash
grails test-app
~~~

如果想部署应用：

~~~bash
grails war
~~~

上面命令默认使用的是 production 环境，也可以添加参数使用 dev 环境：

~~~bash
grails dev war
~~~

当部署应用时候，最后是设置 jvm 内存：

~~~bash
-server -Xmx512M -XX:MaxPermSize=256m
~~~

在 blog 目录查看应用目录结构：

~~~bash
$ blog  tree -L 2
.
├── application.properties
├── grails-app
│   ├── assets
│   ├── conf			# 配置文件(如数据源、URL 映射、遗留的 Spring 和 Hibernate 配置文件)
│   ├── controllers		# 控制器(MVC 中的“C”)
│   ├── domain			# 领域类(MVC 中的模型或“M”。该目弽中 癿每个文件在数据库中都有对应癿表。)
│   ├── i18n			# 国际化
│   ├── migrations		# 迁移
│   ├── services		# 服务类
│   ├── taglib			# 自定义标签库
│   ├── utils			# 工具
│   └── views			# 视图
├── grailsw
├── grailsw.bat
├── lib					# 存放第三方 jar
├── scripts				# Gant 脚本
├── src 				# 源代码文件
│   ├── groovy
│   └── java
├── target
│   ├── classes
│   ├── stacktrace.log
│   └── work
├── test				# 单元测试
│   ├── integration
│   └── unit
├── web-app				# web 资源文件
│   ├── META-INF
│   ├── WEB-INF
│   ├── css
│   ├── images
│   └── js
└── wrapper
    ├── grails-wrapper-runtime-2.4.3.jar
    ├── grails-wrapper.properties
    └── springloaded-1.2.0.RELEASE.jar

29 directories, 7 files
~~~

Grails 非常强调惯例优于配置(convention over configuration)。这意味着 Grails 并不是靠配置(configuration)文件来把应用各部分组织在一起，相反，它靠的是惯例 (convention)。所有领域类都存放在 domain 目录，控制器保存在 controllers 目录，视图则=放在 views 目录，等等。

# 3. 创建领域类

Grails 接受这些简单的类，并用它们完成许多工作。相应的数据库表会自劢为每个领域 类创建，控制器和视图会从关联的领域类中派生出相应的类。领域类还是存放验证规则、定义 “一对多”关系，以及包含其他许多信息的地方。

创建 User 领域类：

~~~bash
$ grails create-domain-class User
...
| Created file grails-app/domain/blog/User.groovy
| Compiling 1 source files
| Created file test/unit/blog/UserSpec.groovy
~~~

你会发现 Grails 同时创建了一个领域类和一个测试类，领域类中包名为 blog，其实，你也可以在创建领域类的时候自定义包名。

编辑 `grails-app/domain/blog/User.groovy`，添加一些属性：

~~~groovy
class User { 
	String name
	Integer age
	String sex
	Date dateCreated
	Date lastUpdated

	static mapping = { 
		autoTimestamp false
	}

	static constraints = {

	}
}
~~~

以上只是添加了一些简单的属性，你还可以添加两个特殊的属性。如果你定义了一个名为 dateCreated 的日期字段，Grails 将自动在第一次向数据库保存实例的时候填上这个值。要是你创建了
另一个名为 lastUpdated 的日期字段，Grails 将在每次把更新后的记录存回数据库的时候填充这个日期。这个可以在 static mapping 代码块中来配置：

~~~groovy
class User { 

	Date dateCreated
	Date lastUpdated

	static mapping = { 
		autoTimestamp false
	}

}
~~~

另外，你也可以定义一些领域类的生命周期事件来做一些复杂的事情：

~~~groovy
class User { 
	// ...
	def beforeInsert = {
		// your code goes here
	}
	def beforeUpdate = {
		// your code goes here 
	}
	def beforeDelete = {
		// your code goes here
	}
	def onLoad = {
		// your code goes here 
	}
}
~~~

static mapping 还可以做一些其他事情，如制定列表排列顺序：

~~~
class User {
	static mapping = {
		sort "name" 
	}
	// ... 
}
~~~

关亍 static mapping 代码块更多的信息，请参见：<http://grails.org/GORM+-+Mapping+DSL>。


# 4. 创建控制器和视图

在命令行下，输入 `grails create-controller User`：

~~~bash
$ grails create-controller User
| Compiling 1 source files
| Created file grails-app/controllers/blog/UserController.groovy
| Created file grails-app/views/user
| Compiling 1 source files
| Created file test/unit/blog/UserControllerSpec.groovy
~~~

查看 User 的控制器 grails-app/controllers/blog/UserController.groovy，你会发现没有多少内容 ：

~~~groovy
package blog

class UserController {

    def index() { }
}
~~~

修改一下内容：

~~~groovy
package blog

class UserController {

    def index={
		render "Hello World"
    }
}
~~~

这时候启动应用，访问 <http://localhost:8080/blog/user> 你会看到 “Hello World”。

在控制器中定义的任何一个闭包都会暴露成一个 url。

重新修改控制器类代码如下：

~~~groovy
package blog

class UserController {
	def scaffold = User
}
~~~

当 Grails 看到控制器中的 scaffold 属性,它会动态地产生针对指定领域类的控制器逻辑和必要的CRUD视图。所有这些只需要这一行代码。

进入 <http://localhost:8080/blog/user/create> 页面，你会发现表单字段排列顺序没有按照预想的情况排列，这时候可在 static constraints 代码块中指定表单顺序：

~~~groovy
class User { 
	String name
	Integer age
	String sex
	Date dateCreated
	Date lastUpdated

	static mapping = { 
		autoTimestamp false
		sort "name"
	}

	static constraints = {
		name()
		age()
		sex()
		dateCreated()
		lastUpdated()
	}
}
~~~

当然，也可以增加一些约束条件：

~~~groovy
class User { 
	String name
	Integer age
	String sex
	Date activeDate
	Date dateCreated
	Date lastUpdated

	static mapping = { 
		autoTimestamp false
		sort "name"
	}

	static constraints = {
		name(blank:false, maxSize:50)
		age(min:0)
		sex(inList:["F", "M"])
		activeDate()
		dateCreated()
		lastUpdated()
	}
}
~~~

Grails 所有可用的验证选项：

- blank、nullable
- creditCard
- display
- email
- password
- inList
- matches
- min, max
- minSize,maxSize,size
- notEqual
- range
- scale
- unique
- url
- validator

而校验失败的国际化消息保存在 grails-app/i18n 目录下的 messages.properties 文件里。

你可以通过 validator 来指定自定义的校验器，例如，startDate要大于当前时间：

~~~groovy
static constraints = {
	// ...
	activeDate(validator: {return (it > new Date())}) // ...
}
~~~

然后在 messages.properties 文件里添加一行：

~~~properties
user.activeDate.validator.invalid=Sorry, but the date is the past. 
~~~

# 5. 对象关联映射

不管愿不愿意,我们都已经创建了领域类，从来没有操心过这些数据的保存和位置。之所以我们能够如此享福，这都得感谢 GORM。Grails 对象-关系映射(Grails Object-Relational Mapping)API 得以让我们放心地以对象方式去思考问题——而不至于陷入到关系数据库相关的 SQL 当中。

## 5.1 DataSource

GORM 缺醒设置在 grails-app/conf/DataSource.groovy：

~~~groovy
dataSource {
    pooled = true
    jmxExport = true
    driverClassName = "org.h2.Driver"
    username = "sa"
    password = ""
}
hibernate {
    cache.use_second_level_cache = true
    cache.use_query_cache = false
//    cache.region.factory_class = 'net.sf.ehcache.hibernate.EhCacheRegionFactory' // Hibernate 3
    cache.region.factory_class = 'org.hibernate.cache.ehcache.EhCacheRegionFactory' // Hibernate 4
    singleSession = true // configure OSIV singleSession mode
    flush.mode = 'manual' // OSIV session flush mode outside of transactional context
}

// environment specific settings
environments {
    development {
        dataSource {
            dbCreate = "create-drop" // one of 'create', 'create-drop', 'update', 'validate', ''
            url = "jdbc:h2:mem:devDb;MVCC=TRUE;LOCK_TIMEOUT=10000;DB_CLOSE_ON_EXIT=FALSE"
        }
    }
    test {
        dataSource {
            dbCreate = "update"
            url = "jdbc:h2:mem:testDb;MVCC=TRUE;LOCK_TIMEOUT=10000;DB_CLOSE_ON_EXIT=FALSE"
        }
    }
    production {
        dataSource {
            dbCreate = "update"
            url = "jdbc:h2:prodDb;MVCC=TRUE;LOCK_TIMEOUT=10000;DB_CLOSE_ON_EXIT=FALSE"
            properties {
               // See http://grails.org/doc/latest/guide/conf.html#dataSource for documentation
               jmxEnabled = true
               initialSize = 5
               maxActive = 50
               minIdle = 5
               maxIdle = 25
               maxWait = 10000
               maxAge = 10 * 60000
               timeBetweenEvictionRunsMillis = 5000
               minEvictableIdleTimeMillis = 60000
               validationQuery = "SELECT 1"
               validationQueryTimeout = 3
               validationInterval = 15000
               testOnBorrow = true
               testWhileIdle = true
               testOnReturn = false
               jdbcInterceptors = "ConnectionState"
               defaultTransactionIsolation = java.sql.Connection.TRANSACTION_READ_COMMITTED
            }
        }
    }
}
~~~

从上面可以看到，Grails 的环境分为三种模式：

- development：开发模式
- test：测试模式
- production：生产模式

并且每种模式下的数据源配置有些许差异，如：dbCreate 值不一样， Grails 默认使用的是 H2内存数据库来保存数据，并三种模式下使用的 JDBC url（内存或者文件）不一样，等等。

> 如果在 DataSource 上设置dbCreate属性为"update", "create" or "create-drop", Grails 会为你自动生成/修改数据表格。

你也可以修改该文件，使用其他的数据库，从而清楚的看到 Grails 创建的表以及其中每一个字段。

~~~groovy
dataSource {
    pooled = true
    jmxExport = true
    driverClassName = "com.mysql.jdbc.Driver"
    username = "grails"
    password = "grails"
}
hibernate {
    cache.use_second_level_cache = true
    cache.use_query_cache = false
//    cache.region.factory_class = 'net.sf.ehcache.hibernate.EhCacheRegionFactory' // Hibernate 3
    cache.region.factory_class = 'org.hibernate.cache.ehcache.EhCacheRegionFactory' // Hibernate 4
    singleSession = true // configure OSIV singleSession mode
    flush.mode = 'manual' // OSIV session flush mode outside of transactional context
}

// environment specific settings
environments {
    development {
        dataSource {
            dbCreate = "create-drop" // one of 'create', 'create-drop', 'update', 'validate', ''
            url = "jdbc:mysql://localhost:3306/grails?autoreconnect=true"
        }
    }
    test {
        dataSource {
            dbCreate = "update"
            url = "jdbc:mysql://localhost:3306/grails?autoreconnect=true"
        }
    }
    production {
        dataSource {
            dbCreate = "update"
            url = "jdbc:mysql://localhost:3306/grails?autoreconnect=true"
        }
    }
}
~~~

当然，你还需要在 mysql 中创建 grails 用户和 grails 数据库，并将 mysql 的 jdbc 驱动拷贝到 lib 目录下。

然后，启动应用观察日志中是否有报错。

## 5.2 One-to-many

创建 Blog 领域类，并设置 User 和 Blog 的 `一对多` 的关系。

先创建 Blog 领域类：

~~~bash
$ grails create-domain-class Blog
~~~

然后修改 User 领域类：

~~~groovy
class User { 
  // ...
  static hasMany = [blogs:Blog] 
}
~~~

上述代码创建了一个名为 blogs 的新字段，类型是 java.util.Set。如果有多个关系，可以用逗号分隔。

> Grails中默认使用的fetch策略是 "lazy", 意思就是集合将被延迟初始化。 如果你不小心，这会导致 [n+1](http://www.javalobby.org/java/forums/t20533.html) 问题 。
如果需要"eager" 抓取 ，需要使用 [ORM DSL](http://www.cjsdn.net/doc/jvm/grails/docs/1.1/guide/single.html#5.5.2 Custom ORM Mapping) 或者指定立即抓取作为query的一部分

默认的级联行为是级联保存和更新，但不删除，除非 belongsTo 被指定:

~~~groovy
class Blog { 
  // ...
  static belongsTo = [user:User] 
}
~~~

这不仅形成了闭环，它还强制了级联更新和删除。

如果在one-to-many的多方拥有2个同类型的属性，必须使用mappedBy 指定哪个集合被映射：

~~~groovy
class User {
        static hasMany = [blogs:Blog]
        static mappedBy = [blogs:"users1"]
}
class Blog {
        User users1
        User users2
}
~~~

如果多方拥有多个集合被映射到不同的属性，也是一样的：

~~~groovy
class User {
        static hasMany = [blogs1:Blog, blogs2:Blog]
        static mappedBy = [blogs1:"users1", blogs2:"users2"]
}
class Blog {
        User users1
        User users2
}
~~~

另外，为了代码的可读性，我们可以修改领域类的 `toString()` 方法：

~~~groovy
class User { 
  // ...
  String toString(){
    return "${name}, ${activeDate.format('MM/dd/yyyy')}"
  }
}
~~~

## 5.3 Many-to-many

Grails 支持 many-to-many 关联，通过在关联双方定义 hasMany ，并在关联拥有方定义 belongsTo ：

~~~groovy
class Book {
   static belongsTo = Author
   static hasMany = [authors:Author]
   String title
}
class Author {
   static hasMany = [books:Book]
   String name
}
~~~

Grails 在数据库层使用一个连接表来映射 many-to-many，在这种情况下，Author 负责持久化关联，并且是唯一可以级联保存另一端的一方 。

## 5.4 数据初始化

在 grails-app/conf 目录下有一个文件叫做 BootStrap.groovy，可以用来做一些初始化的工作：

~~~groovy
class BootStrap {
  def init = { servletContext -> }
  def destroy = {} 
}
~~~

init 闭包会每次在 Grails 启动时被调用; destroy 闭包会每次在 Grails 停止时被调用。

# 6. 参考

- [1] [The Grails Framework - Reference Documentation-v1.1](http://www.cjsdn.net/doc/jvm/grails/docs/1.1/)
- [2] [Grails Tutorial for Beginners](http://grails.asia/grails-tutorial-for-beginners/)
- [3] [使用 Grails 快速开发 Web 应用程序](http://tilt.lib.tsinghua.edu.cn/docs/program/grails/j-grails/section5.html)
