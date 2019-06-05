---
layout: post
title: Kettle dependency management
category: pentaho
tags: [kettle, pentaho]
keywords: kettle, ivy, pentaho
---

<p>pentaho的项目使用了ant和ivy解决项目依赖,所以必须编译源码需要ivy工具.直接使用ivy编译pentaho的bi server项目,一直没有编译成功.<br />
使用ivy编译kettle的源代码却是非常容易的事情.</p>

<p>该篇文章翻译并参考了Will Gorman在pentaho的wiki上添加的<a href="http://wiki.pentaho.com/display/EAI/Kettle+dependency+management" target="_blank">Kettle dependency management</a>,文章标题没作修改.<br />
编写此文,是为了记录编译kettle源码的方法和过程.</p>

<p><strong>以下是对原文的一个简单翻译.</strong>
将kettle作为一个产品发行是一个很有趣的事情.有很多来自于pentaho其他项目(其中有一些有依赖于kettle)的jar包被导入到kettle.这些jar包必须在发行的时候构建并且加入到kettle中.如果一个核心的库被更新了,我们必须将其导入到kettle中(如果有必要).bi服务器,pentaho报表以及pentaho元数据编辑器都将kettle作为一个服务/引擎资源而被构建的.自从我们已经将这些jar导入到我们的源码仓库,这些项目必须使用ivy明确列出kettle以及他的依赖.当kettle的依赖变化的时候,我们必须审查libext文件是否需要更新.</p>

<p>pentaho创建了一系列的脚本来自动化的安装ivy,解决jar(或者是artifacts),构建并发行artifacts.kettle已经升级使用subfloor(简单的意味着build.xml继承自subfloor的构建脚本).subfloor使用ivy从pentaho仓库()或者ibiblio maven2仓库来获取跟新jar.ibiblio仓库用于大多数第三方的jar文件(如apache-commons).pentaho仓库用于在线的pentaho项目或者一些比在ibiblio的三方库.为了解决kettle的依赖,我们不得不在ivy.xml里创建一个清单.这个文件明确地列出每一个没有传递依赖的jar文件.这意味着libext文件的映射在ivy.xml中是一对一的.
<!--more-->
<strong>关于Ivy</strong>
<a href="http://ant.apache.org/ivy/" target="_blank">Apache Ivy™</a>是一个流行的致力于灵活性和简单性的依赖管理工具.更多的参考:<a href="http://ant.apache.org/ivy/features.html" target="_blank">enterprise features</a>, <a href="http://ant.apache.org/ivy/testimonials.html" target="_blank">what people say about it</a>, 以及 <a href="http://ant.apache.org/ivy/history/latest-milestone/index.html" target="_blank">how it can improve your build system</a></p>

<p><strong>在kettle中使用ivyIDE</strong>
首先,从svn上下载kettle的源代码:
<pre>
svn://source.pentaho.org/svnkettleroot/Kettle/trunk
</pre>
如果你想在Eclipse上使用<a href="http://ant.apache.org/ivy/ivyde/download.cgi" target="_blank">ivyde plugin</a>.<br />
请参考相关文章安装该插件.</p>

<p>如果你不想使用ivyde,你可以简单快速并且容易的开始并编译代码.<br />
1.执行<code>ant resolve</code>,这个命令将会创建一个叫做resolved-libs的文件夹.<br />
2.使用下面命令更新classpath <br />
  a.手动的添加这些jar文件到你的ide的classpath<br />
  b.执行ant create-dot-classpath,将会修改你的.classpath文件(注意刷新项目以使改变生效)<br />
注意:kettle项目中的构建脚本会自动安装ivy插件.</p>

<p><strong>构建Kettle</strong>
你可以下载kettle源代码然后立即执行<code>ant distrib</code>命令<br />
或者你可以在ide中导入下载的kettle工程,然后按照你的操作系统(默认的是Windows 32-bit)版本修改依赖的swt.jar文件.</p>

<p><strong>ivy中未完成的</strong>
<strong>pentaho-database-</strong>这是一个依赖kettle-db的常用项目,但又被kettle-ui使用.这样会导致循环依赖,将来可能会将其引入到kettle项目或是从该项目中去掉对kettle的依赖.
<strong>swt-</strong>swt文件目前没有包括在ivy.xml文件中
<strong>library configurations-</strong>每一个kettle库(kettle-db,kettle-core等等)应该在ivy.xml中有他自己的依赖.这些库应该继承一些特定的依赖,而取代继承整个kettle依赖.
<strong>checked-in plugins-</strong>当前引入的插件如;DummyJob, DummyPlugin, S3CsvInput, ShapeFileReader3,versioncheck应该都移到ivy的plugin配置中.</p>

<p><strong>参考文章</strong>
<a href="http://wiki.pentaho.com/display/EAI/Kettle+dependency+management" target="_blank">Kettle dependency management</a>
</p>
