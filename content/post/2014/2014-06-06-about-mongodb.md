---
layout: post

title: MongoDB介绍
date: 2014-06-06T08:00:00+08:00

description: MongoDB是一个开源的，高性能，无模式（或者说是模式自由），使用C++语言编写的面向文档的数据库。正因为MongoDB是面向文档的，所以它可以管理类似JSON的文档集合。又因为数据可以被嵌套到复杂的体系中并保持可以查询可索引，这样一来，应用程序便可以以一种更加自然的方式来为数据建模。

keywords: MongoDB,开源的,高性能,无模式

categories: [ database ]

tags: [mongodb,nosql]

published: true

---

MongoDB 是一个开源的，高性能，无模式（或者说是模式自由），使用 C++ 语言编写的面向文档的数据库。正因为 MongoDB 是面向文档的，所以它可以管理类似 JSON 的文档集合。又因为数据可以被嵌套到复杂的体系中并保持可以查询可索引，这样一来，应用程序便可以以一种更加自然的方式来为数据建模。

官方网站：<http://www.mongodb.org/>

# MongoDB介绍

所谓“面向集合”（Collenction-Orented），意思是数据被分组存储在数据集中，被称为一个集合（Collenction)。每个集合在数据库中都有一个唯一的标识名，并且可以包含无限数目的文档。集合的概念类似关系型数据库（RDBMS）里的表（table），不同的是它不需要定义任何模式（schema)。

模式自由（schema-free)，意味着对于存储在mongodb数据库中的文件，我们不需要知道它的任何结构定义。如果需要的话，你完全可以把不同结构的文件存储在同一个数据库里。

存储在集合中的文档，被存储为键-值对的形式。键用于唯一标识一个文档，为字符串类型，而值则可以是各中复杂的文件类型。我们称这种存储形式为BSON（Binary Serialized dOcument Format）。

MongoDB 把数据存储在文件中（默认路径为：`/data/db`），为提高效率使用内存映射文件进行管理。MongoDB的主要目标是在键/值存储方式（提供了高性能和高度伸缩性）以及传统的 RDBMS 系统（丰富的功能）架起一座桥梁，集两者的优势于一身。

根据官方网站的描述，Mongo 适合用于以下场景：

- 网站数据：Mongo非常适合实时的插入，更新与查询，并具备网站实时数据存储所需的复制及高度伸缩性。
- 缓存：由于性能很高，Mongo也适合作为信息基础设施的缓存层。在系统重启之后，由Mongo搭建的持久化缓存层可以避免下层的数据源过载。
- 大尺寸，低价值的数据：使用传统的关系型数据库存储一些数据时可能会比较昂贵，在此之前，很多时候程序员往往会选择传统的文件进行存储。
- 高伸缩性的场景：Mongo非常适合由数十或数百台服务器组成的数据库。Mongo的路线图中已经包含对MapReduce引擎的内置支持。
- 用于对象及JSON数据的存储：Mongo的BSON数据格式非常适合文档化格式的存储及查询。

自然，MongoDB 的使用也会有一些限制，例如它不适合：

- 高度事务性的系统：例如银行或会计系统。传统的关系型数据库目前还是更适用于需要大量原子性复杂事务的应用程序。
- 传统的商业智能应用：针对特定问题的BI数据库会对产生高度优化的查询方式。对于此类应用，数据仓库可能是更合适的选择。
- 需要SQL的问题

# MongoDB的安装

mongodb的官网就有下载，根据系统windows还是linux还是别的下载32位还是64位的，然后解压安装。

如果你使用的时mac系统，你可以通过 brewhome 来安装：

~~~
$ brew install mongodb
~~~

# MongoDB的管理

解压完之后进入bin目录，里面都是一些可执行文件，mongo，mongod，mongodump，mongoexport等。

1).启动和停止MongoDB

通过执行mongod来启动MongoDB服务器:

~~~
$ mongod
~~~

mongod有很多的配置启动选项的，可以通过`mongod --help`来查看，其中有一些主要的选项：

- `--dbpath`：指定数据目录，默认是`/data/db/`。每个mongod进程都需要独立的目录，启动mongod时就会在数据目录中创建mongod.lock文件，防止其他mongod进程使用该数据目录。
- `--port`：指定服务器监听的端口，默认是`27017`。
- `--fork`：以守护进程的方式运行MongoDB。
- `--logpath`：指定日志输出路径，如果不指定则会在终端输出。每次启动都会覆盖原来的日志，如果不想覆盖就要用`--logappend`选项。
- `--config`：指定配置文件，加载命令行未指定的各种选项。我们可以讲我们需要用到的选项写在某个文件中，然后通过该选项来指定这个文件就不必每次启动mongod时都要写。

2).数据备份

a. 数据文件备份

最简单的备份就是数据文件的备份，就是直接赋值data/db这个目录，因为我们前面已经指定了数据目录就是data/db，那么MongoDB多有的数据都在这里，但是有个问题就是最新的数据还在缓存中，没用同步到磁盘，可以先停止shutdownServer()再备份。但是这样会影响MongoDB正常的工作。

b. mongodump和mongorestore

bin 中还有 mongodump 和 mongorestore 两个可执行文件，这个是对MongoDB的某个数据库进行备份，可以在MongoDB正在运行时进行备份，比如备份test数据库，然后将备份的数据库文件再倒入别的MongoDB服务器上。这种备份的方式备份的不是最新数据，只是已经写入MongoDB中的数据，可能还有的数据在缓存中没有写入，那么这部分数据就是备份不到的。mongodump和mongorestore也可以通过`--help`查询所有选项。

~~~bash
$ mongodump -d text -o test_db
connected to: 127.0.0.1
2014-06-06T12:54:59.741+0800 DATABASE: text	 to 	test_db/text
~~~

`-d`是指定数据库，`-o`是输出备份文件，上面将 test 数据库备份为 test_db 文件。

~~~bash
$ mongorestore --port 27017 -d temple --drop test_db/test/
~~~

这里将上面备份出来的 test 数据库现在重新导入到 temple 数据库，`--drop`代表如果有了 temple 数据库则将其中的所有集合删除，不指定就会和原来 temple 中的集合合并。

c. mongoexport和mongoimport

备份某个数据库中的某个表，同样可以通过`--help`来查看所有的选项，当然mongoexport也是可以不统计的备份，但是却不一定是最新数据。

~~~
$ mongoexport --port 27017 -d zhihu -c zh_user -o zh_user 
$ mongoimport --port 9352 -d temple -c user zh_user
~~~
`-c`表示 collection 集合，上面将 zhihu 库中的 zh_user 集合备份出来为 zh_user 文件，然后再导入到 temple 库中的user集合。



d. sync和锁

mongodump和mongoexport对都可以不停MongoDB服务器来进行备份，但是却失去了获取实时数据的能力，而fsync命令也能在不停MongoDB的情况下备份实时数据，它的实现其实就是上锁，阻止对数据库的写入操作，然后将缓冲区的数据写入磁盘，备份后再解锁。在这个期间，任何对数据库的写入操作都会阻塞，直到锁被释放。

~~~
> db.runCommand({"fsync" : 1, "lock" : 1})
{
        "info" : "now locked against writes, use db.fsyncUnlock() to unlock",
        "seeAlso" : "http://dochub.mongodb.org/core/fsynccommand",
        "ok" : 1
}
>
>在这之间进行备份，执行任何insert操作都会阻塞
>
> db.fsyncUnlock()
{ "ok" : 1, "info" : "unlock completed" }
~~~

# 数据类型

MongoDB的文件存储格式为BSON,同JSON一样支持往其它文档对象和数组中再插入文档对象和数组，同时扩展了JSON的数据类型.与数据库打交道的那些应用。例如，JSON没有日期类型，这会使得处理本来简单的日期问题变得非常繁琐。只有一种数字类型，没法区分浮点数和整数，更不能区分32位和64位数字。也没有办法表示其他常用类型，如正则表达式或函数。

下面是MongoDB的支持的数据类型：

- null    null用于表示空值或者不存在的字段。 `{"x":null}`
- 布尔   布尔类型有两个值'true'和'false1'。 `{"X":true}`
- 32位整数  类型不可用。JavaScript仅支持64位浮点数，所以32位整数会被自动转换。
- 64位整数  不支持这个类型。shell会使用一个特殊的内嵌文档来显示64位整数。
- 64位浮点数  shell中的数字都是这种类型。下面的表示都是浮点数： `{"X" : 3.1415926} {"X" : 3}`
- 字符串   UTF-8字符串都可表示为字符串类型的数据： `{"x" : "foobar"}`
- 符号  不支持这种类型。shell将数据库里的符号类型转换成字符串。
- 对象id  对象id是文档的12字节的唯一ID：`{"_id":ObjectId() }`
- 日期  日期类型存储的是从标准纪元开始的毫秒数。不存储时区： `{"X" : new Date()}`
- 正则表达式  文档中可以包含正则表达式，采用JavaScript的正则表达式语法：`{"x": /foobar/i}`
- 代码  文档中还可以包含JavaScript代码：`{"x": function() { /* …… */ }}`
- 二进制数据  二进制数据可以由任意字节的串组成。不过shell中无法使用。
- 最大值  BSON包括一个特殊类型，表示可能的最大值。shell中没有这个类型。
- 最小值  BSON包括一个特殊类型，表示可能的最小值。shell中没有这个类型。
- 未定义  文档中也可以使用未定义类型：`{"x":undefined}`
- 数组  值的集合或者列表可以表示成数组：`{"x" : ["a", "b", "c"]}`
- 内嵌文档  文档可以包含别的文档，也可以作为值嵌入到父文档中，数据可以组织得更自然些，不用非得存成扁平结构的：{"x" : {"food" ： "noodle"}}
 
JavaScript中只有一种“数字”类型。因为MongoDB中有3种数字类型（32位整数、64位整数和64位浮点数），shell必须绕过JavaScript的限制。默认情况下，shell中的数字都被MongoDB当做是双精度数。这意味着如果你从数据库中获得的是一个32位整数，修改文档后，将文档存回数据库的时候，这个整数也被转换成了浮点数，即便保持这个整数原封不动也会这样的。所以明智的做法是尽量不要在shell下覆盖整个文档。

由于MongoDB中不同文档的同一个key的value数据类型可以不同，当我们根据某个key查询的时候会发生不同数据类型之间的比较。所以MongoDB内部设定了数据类型间的大小，顺序如下：

~~~
最小值<null<数字(32位整数、63位整形、64位浮点数)<字符串<对象/文档<数组<二进制数据<对象ID<布尔型<日期型<时间戳<正则<最大值
~~~

# 参考资料

- [1] [MongoDB 入门须知](http://segmentfault.com/a/1190000000368210)
- [2] [MongoDB入门学习(一)：MongoDB的安装和管理](http://www.2cto.com/database/201406/306599.html)
