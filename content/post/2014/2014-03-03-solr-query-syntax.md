---
layout: post
title: Apache Solr查询语法
date: 2014-03-03T08:00:00+08:00
description: Apache Solr查询语法
categories: [ search-engine ]
tags: [solr]
---

# 查询参数

常用：

- `q` - 查询字符串，必须的。
- `fl` - 指定返回那些字段内容，用逗号或空格分隔多个。
- `start` - 返回第一条记录在完整找到结果中的偏移位置，0开始，一般分页用。
- `rows` - 指定返回结果最多有多少条记录，配合start来实现分页。
- `sort` - 排序，格式：`sort=<field name>+<desc|asc>[,<field name>+<desc|asc>]`。示例：（inStock desc, price asc）表示先 "inStock" 降序, 再 "price" 升序，默认是相关性降序。
- `wt` - (writer type)指定输出格式，可以有 xml, json, php, phps。
- `fq` - （filter query）过虑查询，作用：在q查询符合结果中同时是fq查询符合的，例如：`q=mm&fq=date_time:[20081001 TO 20091031]`，找关键字mm，并且date_time是20081001到20091031之间的

不常用：

- `defType`：
- `q.op` - 覆盖schema.xml的defaultOperator（有空格时用"AND"还是用"OR"操作逻辑），一般默认指定
- `df` - 默认的查询字段，一般默认指定
- `qt` - （query type）指定那个类型来处理查询请求，一般不用指定，默认是standard。

其它：

- `indent` - 返回的结果是否缩进，默认关闭，用 `indent=true|on` 开启，一般调试json,php,phps,ruby输出才有必要用这个参数。
- `version `- 查询语法的版本，建议不使用它，由服务器指定默认值。

# 检索运算符

- `:` 指定字段查指定值，如返回所有值*:*
- `?` 表示单个任意字符的通配
- `*` 表示多个任意字符的通配（不能在检索的项开始使用*或者?符号）
- `~` 表示模糊检索，如检索拼写类似于"roam"的项这样写：roam~将找到形如foam和roams的单词；roam~0.8，检索返回相似度在0.8以上的记录。
	邻近检索，如检索相隔10个单词的"apache"和"jakarta"，"jakarta apache"~10
- `^` 控制相关度检索，如检索jakarta apache，同时希望去让"jakarta"的相关度更加好，那么在其后加上"^"符号和增量值，即jakarta^4 apache
- 布尔操作符`AND、||`
- 布尔操作符`OR、&&`
- 布尔操作符`NOT、!、-`（排除操作符不能单独与项使用构成查询）
- `+` 存在操作符，要求符号"+"后的项必须在文档相应的域中存在
- `()` 用于构成子查询
- `[]` 包含范围检索，如检索某时间段记录，包含头尾，date:[200707 TO 200710]
- `{}`不包含范围检索，如检索某时间段记录，不包含头尾，date:{200707 TO 200710}
- `"` 转义操作符，特殊字符包括+ - && || ! ( ) { } [ ] ^ " ~ * ? : "


# 示例

- 1. 查询所有

~~~
http://localhost:8080/solr/primary/select?q=*:*
~~~

- 2. 限定返回字段

~~~
http://localhost:8080/solr/primary/select?q=*:*&fl=productId
~~~

表示：查询所有记录，只返回productId字段

- 3. 分页

~~~
http://localhost:8080/solr/primary/select?q=*:*&fl=productId&rows=6&start=0
~~~

表示：查询前六条记录，只返回productId字段

- 4. 增加限定条件

~~~
http://localhost:8080/solr/primary/select?q=*:*&fl=productId&rows=6&start=0&fq=categories: [2002&fq=namespace:d&fl=productId+category&fq=en_US_city_i:1101
~~~

表示：查询category=2002、`en_US_city_i=110`以及namespace=d的前六条记录，只返回productId和category字段

- 5. 添加排序

~~~
http://localhost:8080/solr/primary/select?q=*:*&fl=productId&rows=6&start=0&fq=categories: [2002&fq=namespace:d&sort=category_2002_sort_i+asc
~~~

表示：查询category=2002以及namespace=d并按`category_2002_sort_i`升序排序的前六条记录，只返回productId字段

- 6. facet查询

现实分组统计结果

~~~
http://localhost:8080/solr/primary/select?q=*:*&fl=productId&fq=categories: [2002&facet=true&facet.field=en_US_county_i&facet.field=en_US_hotelType_s&facet.field=price_p&facet.field=heatRange_i

http://localhost:8080/solr/primary/select?q=*:*&fl=productId&fq=categories: [2002&facet=true&facet.field=en_US_county_i&facet.field=en_US_hotelType_s&facet.field=price_p&facet.field=heatRange_i&facet.query=price_p:[300.00000+TO+*]
~~~

# 高亮

`hl-highlight`，`h1=true`，表示采用高亮。可以用`h1.fl=field1,field2` 来设定高亮显示的字段。

- `hl.fl`:用空格或逗号隔开的字段列表。要启用某个字段的highlight功能，就得保证该字段在schema中是stored。如果该参数未被给出，那么就会高 亮默认字段 standard handler会用df参数，dismax字段用qf参数。你可以使用星号去方便的高亮所有字段。如果你使用了通配符，那么要考虑启用 。
- `hl.requireFieldMatch`:如果置为true，除非该字段的查询结果不为空才会被高亮。它的默认值是false，意味 着它可能匹配某个字段却高亮一个不同的字段。如果hl.fl使用了通配符，那么就要启用该参数。尽管如此，如果你的查询是all字段（可能是使用 copy-field 指令），那么还是把它设为false，这样搜索结果能表明哪个字段的查询文本未被找到
- h`l.usePhraseHighlighter`:如果一个查询中含有短语（引号框起来的）那么会保证一定要完全匹配短语的才会被高亮。
- `hl.highlightMultiTerm`
如果使用通配符和模糊搜索，那么会确保与通配符匹配的term会高亮。默认为false，同时`hl.usePhraseHighlighter`要为true。
- `hl.snippets`：
这是highlighted片段的最大数。默认值为1，也几乎不会修改。如果某个特定的字段的该值被置为0（如`f.allText.hl.snippets=0`），这就表明该字段被禁用高亮了。你可能在hl.fl=*时会这么用。
- `hl.fragsize`:
每个snippet返回的最大字符数。默认是100.如果为0，那么该字段不会被fragmented且整个字段的值会被返回。大字段时不会这么做。
- `hl.mergeContiguous`:
如果被置为true，当snippet重叠时会merge起来。
- `hl.maxAnalyzedChars`:
会搜索高亮的最大字符，默认值为51200，如果你想禁用，设为-1
- `hl.alternateField`:
如果没有生成snippet（没有terms 匹配），那么使用另一个字段值作为返回。
- `hl.maxAlternateFieldLength`:
如果`hl.alternateField`启用，则有时需要制定alternateField的最大字符长度，默认0是即没有限制。所以合理的值是应该为`hl.snippets * hl.fragsize`这样返回结果的大小就能保持一致。
- `hl.formatter`:一个提供可替换的formatting算法的扩展点。默认值是simple，这是目前仅有的选项。显然这不够用，你可以看看`org.apache.solr.highlight.HtmlFormatter.java` 和 solrconfig.xml 中highlighting元素是如何配置的。
注意在不论原文中被高亮了什么值的情况下，如预先已存在的em tags，也不会被转义，所以在有时会导致假的高亮。
-`hl.fragmenter`:这个是solr制定fragment算法的扩展点。gap是默认值。regex是另一种选项，这种选项指明highlight的边界由一个正则表达式确定。这是一种非典型 的高级选项。为了知道默认设置和fragmenters (and formatters)是如何配置的，可以看看 solrconfig.xml 中的highlight段。
- `hl.regex.pattern`:正则表达式的pattern
- `hl.regex.slop`:这是hl.fragsize能变化以适应正则表达式的因子。默认值是0.6，意思是如果 `hlfragsize=100` 那么fragment的大小会从40-160.
