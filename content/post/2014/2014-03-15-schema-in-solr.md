---
layout: post
title: Solr的schema.xml
date: 2014-03-15T08:00:00+08:00
description: schema.xml是Solr一个配置文件，它包含了你的文档所有的字段，以及当文档被加入索引或查询字段时，这些字段是如何被处理的。
categories: [ search-engine ]
tags: [solr]
---

schema.xml是Solr一个配置文件，它包含了你的文档所有的字段，以及当文档被加入索引或查询字段时，这些字段是如何被处理的。这个文件被存储在Solr主文件夹下的conf目录下，默认的路径`./solr/conf/schema.xml`，也可以是Solr webapp的类加载器所能确定的路径。在下载的Solr包里，有一个schema的样例文件，用户可以从那个文件出发，来观察如何编写自己的Schema.xml。

# type节点

先来看下type节点，这里面定义FieldType子节点，包括name、class、positionIncrementGap等一些参数。必选参数：

- name：就是这个FieldType的名称。
- class：指向org.apache.solr.analysis包里面对应的class名称，用来定义这个类型的行为。

其他可选的属性： 

- sortMissingLast，sortMissingFirst两个属性是用在可以内在使用String排序的类型上，默认false，适用于字段类型：string、boolean、sint、slong、sfloat、sdouble、pdate。
- sortMissingLast="true"，没有该field的数据排在有该field的数据之后，而不管请求时的排序规则，在Java中对应的意思就是，该字段为NULL，排在后面。
- sortMissingFirst="true"，排序规则与sortMissingLast相反。
- positionIncrementGap：可选属性，定义在同一个文档中此类型数据的空白间隔，避免短语匹配错误。

在配置中，string类型的class是solr.StrField，而这个字段是不会被分析存储的，也就是说不会被分词。

而对于文章或者长文本来说，我们必须对其进行分词才能保证搜索某些字段时能够给出正确的结果。这时我们就可以用到另外一个class，solr.TextField。它允许用户通过分析器来定制索引和查询，分析器包括一个分词器（tokenizer）和多个过滤器（filter） 。

一个标准的分词：

~~~xml
<fieldType name="text_general" class="solr.TextField" positionIncrementGap="100">
    <analyzer type="index">
        <tokenizer class="solr.StandardTokenizerFactory" />
        <filter class="solr.LowerCaseFilterFactory" />
    </analyzer>
    <analyzer type="query">
        <tokenizer class="solr.StandardTokenizerFactory" />
        <filter class="solr.LowerCaseFilterFactory" />
        <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords.txt" enablePositionIncrements="true" />
    </analyzer>
</fieldType>
~~~

分词用的依旧是fieldType，为的是在下面的field中能够用到。有两个analyzer，一个是index，一个是query，index是针对于所有，query是针对于搜索。

tokenizer节点当然就是对应分析链中的起点Tokenizer。接下来串联了2个filter，分别是solr.StopFilterFactory，solr.LowerCaseFilterFactory。stop word filter就是把那些the、 of、 on之类的词从token中去除掉，由于这类词在文档中出现的频率非常高，而对文档的特征又没什么影响，所以这类词对查询没什么意义。Lower case filter的作用是将所有的token转换成小写，也就是在最终的index中保存的都是小写

你也可以定义一个analyzer，例如使用mmseg4j进行中文分词：

~~~xml
<fieldType name="text_zh" class="solr.TextField" positionIncrementGap="100">
    <analyzer> 
        <tokenizer class="com.chenlb.mmseg4j.solr.MMSegTokenizerFactory" mode="complex" />
    </analyzer>
</fieldType>
~~~

# filed节点

filed节点用于定义数据源字段所使用的搜索类型与相关设置。含有以下属性

- name：数据源字段名，搜索使用到。
- type：搜索类型名例如中文ika搜索名text_ika，对应于fieldType中的name。不需要分词的字符串类型，string即可，如果需要分词，用上面配置好的分词type。
- indexed：是否被索引，只有设置为true的字段才能进行搜索排序分片(earchable、 sortable、 facetable)。
- stored：是否存储内容，如果不需要存储字段值，尽量设置为false以提高效率。
- multiValued：是否为多值类型，SOLR允许配置多个数据源字段存储到一个搜索字段中。多个值必须为true，否则有可能抛出异常。
- omitNorms：是否忽略掉Norm，可以节省内存空间，只有全文本field和need an index-time boost的field需要norm。（具体没看懂，注释里有矛盾）
- termVectors：当设置true，会存储 term vector。当使用MoreLikeThis，用来作为相似词的field应该存储起来。
- termPositions：存储 term vector中的地址信息，会消耗存储开销。
- termOffsets：存储 term vector 的偏移量，会消耗存储开销。
- default：如果没有属性需要修改，就可以用这个标识下。
- docValues：Solr 4.2中加入了该属性
- docValuesFormat：可选的值为Disk或者Memory

举例：

~~~xml
<field name="manu_exact" type="string" indexed="false" stored="false" docValues="true" />
~~~

# copyField节点

如果我们的搜索需要搜索多个字段该怎么办呢？这时候，我们就可以使用copyField。代码如下：

~~~xml
<copyField source="name" dest="all" maxChars="30000"/>
<copyField source="address" dest="all" maxChars="30000"/>
~~~

作用：

- 将多个field的数据放在一起同时搜索，提供速度
- 将一个field的数据拷贝到另一个，可以用2种不同的方式来建立索引

我们将所有的中文分词字段全部拷贝至all中，当我们进行全文检索是，只用搜索all字段就OK了。

其包含属性：

- source：源field字段
- dest：目标field字段
- maxChars：最多拷贝多少字符

注意，这里的目标字段必须支持多值，最好不要存储，因为他只是做搜索。indexed为true，stored为false。

copyField节点和field节点都在fields节点之内。

# dynamicField节点

动态字段，没有具体名称的字段，用dynamicField字段

如：name为`*_i`，定义它的type为int，那么在使用这个字段的时候，任务以`_i`结果的字段都被认为符合这个定义。如`name_i`、 `school_i`

~~~xml
<dynamicField name="*_i"  type="int"    indexed="true"  stored="true"/> 
<dynamicField name="*_s"  type="string"  indexed="true"  stored="true"/>
<dynamicField name="*_l"  type="long"   indexed="true"  stored="true"/>
~~~

# uniqueKey节点

solr必须设置一个唯一字段，常设置为id，此唯一一段有uniqueKey节点指定。

例如：

~~~xml
<uniqueKey>id</uniqueKey>
~~~

# defaultSearchField节点

默认搜索的字段，我们已经将需要搜索的字段拷贝至all字段了，在这里设为all即可。

~~~xml
<defaultSearchField>all</defaultSearchField>
~~~

# solrQueryParser节点

默认搜索操作符参数，及搜索短语间的逻辑，用AND增加准确率，用OR增加覆盖面，建议用AND，也可在搜索语句中定义。例如搜索“手机 苹果”，使用AND默认搜索为“手机AND苹果“。

~~~xml
<solrQueryParser defaultOperator="OR"/> 
~~~

# similarity节点

Similarity式lucene中的一个类，用来在搜索过程中对一个文档进行评分。该类可以做些修改以支持自定义的排序。在Solr4中，你可以为每一个field配置一个不同的similarity，你也可以在schema.xml中使用DefaultSimilarityFactory类配置一个全局的similarity。

你可以使用默认的工厂类来创建一个实例，例如：

~~~xml
<similarity class="solr.DefaultSimilarityFactory"/>
~~~

你也可以使用其他的工厂类，然后设置一些可选的初始化参数：

~~~xml
<similarity class="solr.DFRSimilarityFactory">
  <str name="basicModel">P</str>
  <str name="afterEffect">L</str>
  <str name="normalization">H2</str>
  <float name="c">7</float>
</similarity>
~~~

在Solr 4中，你可以为每一个field配置：

~~~xml
<fieldType name="text_ib">
   <analyzer/>
   <similarity class="solr.IBSimilarityFactory">
      <str name="distribution">SPL</str>
      <str name="lambda">DF</str>
      <str name="normalization">H2</str>
   </similarity>
</fieldType>
~~~

上面例子中，使用了DFRSimilarityFactory和IBSimilarityFactory，这里还有一些其他的实现类。在Solr 4.2中加入了SweetSpotSimilarityFactory。其他还有：BM25SimilarityFactory、SchemaSimilarityFactory等。

# 参考文章

- [1] [Solr配置，schema.xml的配置，以及中文分词](http://www.cnblogs.com/wrt2010/archive/2012/11/14/2769521.html)
- [2] [Other Schema Elements](https://cwiki.apache.org/confluence/display/solr/Other+Schema+Elements)
