---
layout: post
title: Extjs读取xml文件生成动态表格和表单(续)
category: web
tags: [extjs, xml]
keywords: extjs, xml
description: Extjs读取xml文件生成动态表格和表单
---

很多人向我要【[Extjs读取xml文件生成动态表格和表单](/2009/10/22/ext_readxml_in_bjsasc_wuzi/)】一文的源代码，故花了些时间将源代码整理出来，并重新编写此文，分享当时的技术思路。

需要的文件有：

- 1.html文件，此处以SASC.search.MtrUse.html为例
- 2.Extjs相关文件,见SASC.search.MtrUse.html文件中的引用
- 3.工具类，DomUtils.js
- 4.核心js类:SASC.extjs.search.MtrUse.js
- 5.java代码

详细html和js代码见相关文件，这里先描述思路。

<strong>首先</strong>

通过一个事件打开一个弹出窗口，该窗口的url指向SASC.search.MtrUse.html文件，并附带参数xmlFile，xmlFile的值为xml文件名称，其存于服务器的某一路径下面。如：`../SASC.search.MtrUse.html?xmlFile=PC_MTRREPLACE_IMP.xml` 。`PC_MTRREPLACE_IMP.xml`文件的放置路径见DomUtils.js文件中的说明。

在这里，前台会读取该xml生成ext界面，后天会从xml文件读取sql语句等信息，详细信息见java代码。

进入SASC.search.MtrUse.html页面，执行ext的初始化方法时，会先通过当前页面的url中获取xmlFile参数的值（调用 `getForwardXmlUrl(getQsValue('xmlFile'))）`，得到xml文件的服务器路径，然后通过javascript的解析该xml文件，渲染出ext界面,这部分代码见`SASC.extjs.search.MtrUse.js`文件内的initStoreData(xmlObj) 方法。

需要说明的是，xml文件是按照一定规律编写的，详细的参考xml文件内容，以及解析xml文件的相关方法。你可以重新定义该xml的结构，然后修改解析xml文件的方法。

<strong>然后</strong>

初始化完ext界面之后，会获取表格数据，这部分使用了struts，这不是本文重点，故不做介绍。

<strong>说明</strong>

如果还有什么不懂或者想要源代码，欢迎email我：javachen.june#gmail.com
