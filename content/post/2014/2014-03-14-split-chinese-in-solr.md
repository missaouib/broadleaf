---
layout: post
title: 在Solr中使用中文分词
date: 2014-03-14T08:00:00+08:00
description: 使用全文检索，中文分词是离不开的，这里我采用的是mmseg4j分词器。mmseg4j分词器内置了对solr的支持，最新版本可支持4.X版本的sorl，使用起来很是方便。
categories: [ search-engine ]
tags: [solr, solrcloud]
---

使用全文检索，中文分词是离不开的，这里我采用的是 **mmseg4j** 分词器。mmseg4j分词器内置了对solr的支持，最新版本可支持4.X版本的sorl，使用起来很是方便。

# 下载mmseg4j

GoogleCode地址：[http://code.google.com/p/mmseg4j/](http://code.google.com/p/mmseg4j/)

请下载最新版本：mmseg4j-1.9.1，然后将mmseg4j-1.9.1/dist下的jar包拷贝至solr.war的lib目录，例如：*apache-tomcat-6.0.36/webapps/solr/WEB-INF/lib/*


# 配置schema.xml

使用mmseg4j中文分词器，首先需要在schema.xml文件中配置一个fieldType节点：

~~~xml
<fieldType name="text_zh" class="solr.TextField" positionIncrementGap="100">
    <analyzer> 
        <tokenizer class="com.chenlb.mmseg4j.solr.MMSegTokenizerFactory" mode="complex" />
    </analyzer>
</fieldType>
~~~

然后就可以在field节点中引用该filedType了，假设你有个字段叫content需要支持中文分词，则需要定义示例filed节点如下：

~~~xml
<field name="content" type="text_zh" indexed="true" stored="false" multiValued="true"/> 
~~~

接下来，重启solr服务器。

# 测试

我这里使用的是broadleaf项目(broadleaf是什么，请参考：[BroadLeaf项目搜索功能改进](/2014/03/13/improve-the-search-function-in-broadleaf-project.html))中的schema.xml，需要修改成如下：

~~~xml
<?xml version="1.0" encoding="UTF-8" ?>
<schema name="example" version="1.5">
    <fields>
        <field name="namespace" type="string" indexed="true" stored="true" />
        <field name="id" type="string" indexed="true" stored="true" />
        <field name="productId" type="long" indexed="true" stored="true" />
        <field name="category" type="long" indexed="true" stored="true" multiValued="true" />
        <field name="explicitCategory" type="long" indexed="true" stored="true" multiValued="true" />
        <field name="searchable" type="text_zh" indexed="true" stored="false" />
        <field name="_version_" type="long" indexed="true" stored="true" multiValued="false"/>
        <dynamicField name="*_searchable" type="text_zh" indexed="true" stored="true" />
        
        <dynamicField name="*_i" type="int" indexed="true" stored="true" />
        <dynamicField name="*_is" type="int" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_s" type="text_zh" indexed="true" stored="true" />
        <dynamicField name="*_ss" type="text_zh" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_l" type="long" indexed="true" stored="true" />
        <dynamicField name="*_ls" type="long" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_t" type="text_zh" indexed="true" stored="true" />
        <dynamicField name="*_txt" type="text_zh" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_b" type="boolean" indexed="true" stored="true" />
        <dynamicField name="*_bs" type="boolean" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_d" type="double" indexed="true" stored="true" />
        <dynamicField name="*_ds" type="double" indexed="true" stored="true" multiValued="true" />
        <dynamicField name="*_p" type="double" indexed="true" stored="true" />

        <dynamicField name="*_dt" type="date" indexed="true" stored="true" />
        <dynamicField name="*_dts" type="date" indexed="true" stored="true" multiValued="true" />

        <!-- some trie-coded dynamic fields for faster range queries -->
        <dynamicField name="*_ti" type="tint" indexed="true" stored="true" />
        <dynamicField name="*_tl" type="tlong" indexed="true" stored="true" />
        <dynamicField name="*_td" type="tdouble" indexed="true" stored="true" />
        <dynamicField name="*_tdt" type="tdate" indexed="true" stored="true" />
    </fields>
    
    <uniqueKey>id</uniqueKey>

    <types>
		<fieldType name="text_zh" class="solr.TextField" positionIncrementGap="100">
			<analyzer> 
				<tokenizer class="com.chenlb.mmseg4j.solr.MMSegTokenizerFactory" mode="complex" />
			</analyzer>
		</fieldType>
        <fieldType name="string" class="solr.StrField" sortMissingLast="true" />
        <fieldType name="boolean" class="solr.BoolField" sortMissingLast="true" />
        <fieldType name="int" class="solr.TrieIntField" precisionStep="0" positionIncrementGap="0" />
        <fieldType name="long" class="solr.TrieLongField" precisionStep="0" positionIncrementGap="0" />
        <fieldType name="double" class="solr.TrieDoubleField" precisionStep="0" positionIncrementGap="0" />
        <fieldType name="tint" class="solr.TrieIntField" precisionStep="8" positionIncrementGap="0" />
        <fieldType name="tlong" class="solr.TrieLongField" precisionStep="8" positionIncrementGap="0" />
        <fieldType name="tdouble" class="solr.TrieDoubleField" precisionStep="8" positionIncrementGap="0" />
        <fieldType name="date" class="solr.TrieDateField" precisionStep="0" positionIncrementGap="0" />
        <fieldType name="tdate" class="solr.TrieDateField" precisionStep="6" positionIncrementGap="0" />

        <fieldType name="text_general" class="solr.TextField" positionIncrementGap="100">
            <analyzer type="index">
                <tokenizer class="solr.StandardTokenizerFactory" />
                <filter class="solr.LowerCaseFilterFactory" />
            </analyzer>
            <analyzer type="query">
                <tokenizer class="solr.StandardTokenizerFactory" />
                <filter class="solr.LowerCaseFilterFactory" />
            </analyzer>
        </fieldType>
    </types>
</schema>
~~~

接下来，在浏览器中进行测试,输入下面url：

~~~
http://192.168.56.123:8080/solr/primary_shard2_replica1/select?q=*%3A*&wt=json&indent=true&rows=6&start=0&fq=category%3A2002&fq=namespace%3Ad&fq=%7B%21tag%3Da%7D%28en_US_name_s%3A大理%29
~~~
以上搜索的是category=2002,namespace=d，`en_US_name_s`=大理的记录，查询结果为：

~~~
{
  "responseHeader":{
    "status":0,
    "QTime":20},
  "response":{"numFound":1,"start":0,"maxScore":1.0,"docs":[
      {
        "namespace":"d",
        "id":"5",
        "productId":5,
        "explicitCategory":[2002],
        "category_2002_sort_i":4,
        "category":[2002,
          1,
          2],
        "price_p":480.0,
        "en_US_name_t":"大理风情",
        "en_name_t":"大理风情",
        "en_US_name_s":"大理风情",
        "en_name_s":"大理风情",
        "en_US_desc_t":"体验不一样的风景",
        "en_desc_t":"体验不一样的风景",
        "en_US_ldesc_t":"大理风情养老基地坐落在美丽的洱海边，这里依山傍水，鲜花遍地，适合老年人居住、旅游。",
        "en_ldesc_t":"大理风情养老基地坐落在美丽的洱海边，这里依山傍水，鲜花遍地，适合老年人居住、旅游。",
        "en_US_city_t":"5329",
        "en_city_t":"5329",
        "en_US_city_i":5329,
        "en_city_i":5329,
        "en_US_hotelType_t":"A",
        "en_hotelType_t":"A",
        "en_US_hotelType_s":"A",
        "en_hotelType_s":"A",
        "en_US_county_t":"532901",
        "en_county_t":"532901",
        "en_US_county_i":532901,
        "en_county_i":532901,
        "en_US_estatePrice_p":480.0,
        "en_estatePrice_p":480.0,
        "_version_":1462514915941023744}]
  }}
~~~

通过查询结果，可以知道：只搜索"大理"关键字，可以查询出`en_US_name_s`为"大理风情"的记录。

# 参考文章

- [1] [Solr4.4的安装与配置](http://blog.csdn.net/zhyh1986/article/details/9856115)

