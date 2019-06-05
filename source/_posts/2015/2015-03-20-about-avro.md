---
layout: post

title: Avro介绍

category: hadoop

tags: [ avro ]

description: Avro 是 Hadoop 中的一个子项目，也是 Apache 中一个独立的项目，Avro 是一个基于二进制数据传输高性能的中间件。

published: true

---

# 1. 介绍

[Avro](http://avro.apache.org/) 是 Hadoop 中的一个子项目，也是 Apache 中一个独立的项目，Avro 是一个基于二进制数据传输高性能的中间件。在 Hadoop 的其他项目中，例如 HBase 和 Hive 的 Client 端与服务端的数据传输也采用了这个工具。Avro 是一个数据序列化的系统，它可以提供：

- 1、丰富的数据结构类型
- 2、快速可压缩的二进制数据形式
- 3、存储持久数据的文件容器
- 4、远程过程调用 RPC
- 5、简单的动态语言结合功能，Avro 和动态语言结合后，读写数据文件和使用 RPC 协议都不需要生成代码，而代码生成作为一种可选的优化只值得在静态类型语言中实现。

Avro 支持跨编程语言实现（C, C++, C#，Java, Python, Ruby, PHP），Avro 提供着与诸如 Thrift 和 Protocol Buffers 等系统相似的功能，但是在一些基础方面还是有区别的，主要是：

- 1、动态类型：Avro 并不需要生成代码，模式和数据存放在一起，而模式使得整个数据的处理过程并不生成代码、静态数据类型等等。这方便了数据处理系统和语言的构造。
- 2、未标记的数据：由于读取数据的时候模式是已知的，那么需要和数据一起编码的类型信息就很少了，这样序列化的规模也就小了。
- 3、不需要用户指定字段号：即使模式改变，处理数据时新旧模式都是已知的，所以通过使用字段名称可以解决差异问题。

Avro 和动态语言结合后，读/写数据文件和使用 RPC 协议都不需要生成代码，而代码生成作为一种可选的优化只需要在静态类型语言中实现。

当在 RPC 中使用 Avro 时，服务器和客户端可以在握手连接时交换模式。服务器和客户端有着彼此全部的模式，因此相同命名字段、缺失字段和多余字段等信息之间通信中需要解决的一致性问题就可以容易解决。

还有，Avro 模式是用 JSON（一种轻量级的数据交换模式）定义的，这样对于已经拥有 JSON 库的语言可以容易实现。

# 2. Schema

Schema 通过 JSON 对象表示。Schema 定义了简单数据类型和复杂数据类型，其中复杂数据类型包含不同属性。通过各种数据类型用户可以自定义丰富的数据结构。

基本类型有：

|类型 | 说明 |
|:----|:---|
| null | no value |
| boolean | a binary value |
| int | 32-bit signed integer |
| long | 64-bit signed integer |
| float | single precision (32-bit) IEEE 754 floating-point number |
| double | double precision (64-bit) IEEE 754 floating-point number |
| bytes |sequence of 8-bit unsigned bytes |
|string | unicode character sequence |

Avro定义了六种复杂数据类型：

- Record：record 类型，任意类型的一个命名字段集合，JSON对象表示。支持以下属性：
    - name：名称，必须
    - namespace
    - doc
    - aliases
    - fields：一个 JSON 数组，必须
        - name
        - doc
        - type
        - default
        - order
        - aliases
- Enum：enum 类型，支持以下属性：
    - name：名称，必须
    - namespace
    - doc
    - aliases
    - symbols：枚举值，必须
- Array：array 类型，未排序的对象集合，对象的模式必须相同。支持以下属性：
    - items
- Map：map 类型，未排序的对象键/值对。键必须是字符串，值可以是任何类型，但必须模式相同。支持以下属性：
    - values 
- Fixed：fixed 类型，一组固定数量的8位无符号字节。支持以下属性：
    - name：名称，必须
    - namespace
    - size：每个值的 byte 长度
    - aliases 
- Union：union 类型，模式的并集，可以用JSON数组表示，每个元素为一个模式。

每一种复杂数据类型都含有各自的一些属性，其中部分属性是必需的，部分是可选的。

举例，一个 linked-list of 64-bit 的值：

~~~json
{
  "type": "record", 
  "name": "LongList",
  "aliases": ["LinkedLongs"],                      // old name for this
  "fields" : [
    {"name": "value", "type": "long"},             // each element has a long
    {"name": "next", "type": ["null", "LongList"]} // optional next element
  ]
}
~~~

一个 enum 类型的：

~~~json
{ "type": "enum",
  "name": "Suit",
  "symbols" : ["SPADES", "HEARTS", "DIAMONDS", "CLUBS"]
}
~~~

array 类型：

~~~json
{"type": "array", "items": "string"}
~~~

map 类型：

~~~json
{"type": "map", "values": "long"}
~~~

fixed 类型：

~~~json
{"type": "fixed", "size": 16, "name": "md5"}
~~~

这里需要说明Record类型中field属性的默认值，当Record Schema实例数据中某个field属性没有提供实例数据时，则由默认值提供，具体值见下表。Union的field默认值由Union定义中的第一个Schema决定。

| avro type |  json type | example |
|:----|:---|:---|
| null | null | null |
| boolean | boolean | true |
| int,long | integer | 1 |
| float,double | number |1.1 |
| bytes | string | "\u00FF" |
| string | string | "foo" |
| record | object | {"a": 1} |
| enum | string | "FOO" |
| array | array | [1] |
| map | object | {"a": 1} |
| fixed | string | "\u00ff" |

# 3.  序列化/反序列化

Avro 指定两种数据序列化编码方式：binary encoding 和 Json encoding。使用二进制编码会高效序列化，并且序列化后得到的结果会比较小；而 JSON 一般用于调试系统或是基于 WEB 的应用。

TODO

# 4. Avro Tools

Avro Tools 不加参数时:

~~~
$ java -jar /usr/lib/avro/avro-tools.jar
Version 1.7.6-cdh5.2.0 of Apache Avro
Copyright 2010 The Apache Software Foundation

This product includes software developed at
The Apache Software Foundation (http://www.apache.org/).

C JSON parsing provided by Jansson and
written by Petri Lehtinen. The original software is
available from http://www.digip.org/jansson/.
----------------
Available tools:
          cat  extracts samples from files
      compile  Generates Java code for the given schema.
       concat  Concatenates avro files without re-compressing.
   fragtojson  Renders a binary-encoded Avro datum as JSON.
     fromjson  Reads JSON records and writes an Avro data file.
     fromtext  Imports a text file into an avro data file.
      getmeta  Prints out the metadata of an Avro data file.
    getschema  Prints out schema of an Avro data file.
          idl  Generates a JSON schema from an Avro IDL file
 idl2schemata  Extract JSON schemata of the types from an Avro IDL file
       induce  Induce schema/protocol from Java class/interface via reflection.
   jsontofrag  Renders a JSON-encoded Avro datum as binary.
       random  Creates a file with randomly generated instances of a schema.
      recodec  Alters the codec of a data file.
  rpcprotocol  Output the protocol of a RPC service
   rpcreceive  Opens an RPC Server and listens for one message.
      rpcsend  Sends a single RPC message.
       tether  Run a tethered mapreduce job.
       tojson  Dumps an Avro data file as JSON, record per line or pretty.
       totext  Converts an Avro data file to a text file.
     totrevni  Converts an Avro data file to a Trevni file.
  trevni_meta  Dumps a Trevni file's metadata as JSON.
trevni_random  Create a Trevni file filled with random instances of a schema.
trevni_tojson  Dumps a Trevni file as JSON.
~~~

fromjson 命令语法如下：

~~~bash
$ java -jar /usr/lib/avro/avro-tools.jar fromjson
Expected 1 arg: input_file
Option                                  Description
------                                  -----------
--codec                                 Compression codec (default: null)
--level <Integer>                       Compression level (only applies to
                                          deflate and xz) (default: -1)
--schema                                Schema
--schema-file                           Schema File
~~~

以 [将Avro数据加载到Spark](/2015/03/24/how-to-load-some-avro-data-into-spark.html) 为例，将 json 数据转换为 avro 数据：

~~~bash
$ java -jar /usr/lib/avro/avro-tools.jar fromjson --schema-file twitter.avsc twitter.json > twitter.avro
~~~

设置压缩格式：

~~~bash
$ java -jar /usr/lib/avro/avro-tools.jar fromjson --codec snappy --schema-file twitter.avsc twitter.json > twitter.snappy.avro
~~~

将 avro 转换为 json：

~~~bash
$ java -jar /usr/lib/avro/avro-tools.jar tojson twitter.avro > twitter.json
$ java -jar /usr/lib/avro/avro-tools.jar tojson twitter.snappy.avro > twitter.json
~~~

获取 avro 文件的 schema：

~~~bash
$ java -jar /usr/lib/avro/avro-tools.jar getschema twitter.avro > twitter.avsc
$ java -jar /usr/lib/avro/avro-tools.jar getschema twitter.snappy.avro > twitter.avsc
~~~

将 Avro 数据编译为 Java：

~~~bash
$ java -jar /usr/lib/avro/avro-tools.jar compile schema twitter.avsc .
~~~

# 5. 文件结构

TODO

# 6. 参考文章

- [Avro简介](http://blog.csdn.net/xyw_blog/article/details/8967362)
- [Reading and Writing Avro Files From the Command Line](http://www.michael-noll.com/blog/2013/03/17/reading-and-writing-avro-files-from-the-command-line/)
