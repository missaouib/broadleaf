---
layout: post
title: Mondrian and OLAP
category: pentaho
tags: [mondrian]
description: Mondrian是一个用Java编写的OLAP引擎。他执行用MDX语言编写的查询，从关系数据库（RDBMS）中读取数据并且通过Java API以多维度的格式展示查询结果。
---
<p>Mondrian是一个用Java编写的OLAP引擎。他执行用MDX语言编写的查询，从关系数据库（RDBMS）中读取数据并且通过Java API以多维度的格式展示查询结果。</p>

<p><strong><span style="color: #00ff00;">Online Analytical Processing</span></strong>
联机分析处理（OLAP）指在线实时的分析大量数据。与联机事务处理系统（On-<wbr>Line Transaction Processing，简称OLTP）不同，OLTP中典型的操作如读和修改单个的少量的记录，而OLAP批量处理数据并且所有操作都是只读的。“online”意味着即使是处理大量的数据----百万条数据记录，占有几个GB内存----系统必须足够快的反回查询结果以允许数据的交互式响应。正如我们将看到，数据展示面临相当大的技术挑战。</wbr></p>

<p>OLAP引入了一种多维度查询的技术。鉴于一个关系数据库以行和列的形式存储所有数据，一个多维数据集包括轴和列。考虑下面的数据集：</p>

<p><img src="http://7xnrdo.com1.z0.glb.clouddn.com/2011/12/olap_examples20111217.jpg" /></p>

<p>行轴包括"All products", "Books","Fiction"等等，并且列轴包括生产年份"2000"”和"2001"、"Growth"的计算值以及"Unit sales"和"Dollar sales"的测量值。每个单元代表在某一年的一个产品类别的销售额，例如2001年Magazines的$销售额是2426美元。</p>

<p>这是一个比关系型数据库展现出来的更加丰富的视图。多维数据集的只不是永远都来自于一个关系数据库的列。 'Total', 'Books' and 'Fiction' 是一个具有层次结构连续的成员，每一个成员都包括其下一层的成员。即使是在"2000"和"2001"一行，"Growth"是一个计算出来的值，它引入一个公式从其他列计算当前列的值。</p>

<p>该例中使用的维度有：产品、生产线和测量值，仅仅是这个数据集可以分类和过滤的许多维度中的三个。维度，层次结构和测量值的集合被称为一个立方体。</p>

<p><strong><span style="color: #00ff00;">结论</span></strong>
我希望我已经证明垛位是一个首选的数据显示方式。虽然一些多维数据库以多维度的格式存储数据库，我仍然认为这比以关系的格式存储数据要简单。<br />
现在，你可以看看OLAP系统的架构。查看Mondrian architecture。http://mondrian.pentaho.com/documentation/architecture.php</p>

<p><strong><span style="color: #00ff00;">说明</span></strong>
<div class="note">
这是一篇翻译，原文来自http://mondrian.pentaho.com/documentation/olap.php。翻译水平有限，难免翻译不当，请见谅。</div></p>
