---
layout: post
title: XUL 用户界面语言介绍
category: java
tags: [xml]
keywords: xml, xul
description: XUL 用户界面语言介绍
---
<p>XUL[1]是英文“<span style="color: #339966;">XML User Interface Language</span>”的首字母缩写。它是为了支持Mozilla系列的应用程序（如Mozilla Firefox和Mozilla Thunderbird）而开发的用户界面标示语言。顾名思义，它是一种应用XML来描述用户界面的标示语言。<br />
XUL是开放标准，重用了许多现有的标准和技术[2]，包括CSS、JavaScript、DTD和RDF等。所以对于有网络编程和设计经验的人士来说，学习XUL比学习其他用户界面标示语言相对简单。<br />
使用XUL的主要好处在于它提供了一套简易和跨平台的widget定义。这节省了编程人员在开发软件时所付出的努力。</p>

<p><span style="color: #339966;"><strong>XUL元素</strong></span>
XUL定义了一套丰富的元素。它们大致上可分为以下几种：<br />
基层元素：例如视窗、page、对话框、向导<br />
Widget:例如标签、按钮、文字方块、条列式菜单、组合方块、选择钮、复选框、树、菜单、工具栏、分组框、标签页、色彩选择器、spacer、splitter<br />
排版:例如方框、网格、堆栈、叠<br />
事件和脚本:例如脚本、命令、key、broadcaster、observer<br />
数据源:例如template、rule<br />
其他:例如overlay（类似SSI，但在客户端运作，而且更为强大）、iframe、浏览器、编辑器<br />
一个XUL文件中也可以包含其他XML命名空间的元素，例如XHTML、SVG和MathML。<br />
现时的XUL还未在提供一些普遍的widget，例如spinbox、slider和canvas。XUL 2.0[3]计划中将会包括这些缺乏的控件。</p>

<p><span style="color: #339966;"><strong>XUL是如何处理的</strong></span>[4]<br />
Mozilla浏览器内部使用跟HTML的处理非常相似的方法来处理XUL：当你在浏览器的地址栏里面输入HTML页面的URL以后，浏览器就定位这个网址并下载页面内容，然后Mozilla将页面内容转换成树的数据结构，最后再将树转换成对象集合，集合中的对象最终被展现在屏幕上就成了我们所见的网页。CSS, 图片以及其他技术被用来控制页面的展现。XUL的处理过程与此非常类似。</p>

<p><span style="color: #339966;"><strong>XUL应用</strong></span>
虽然XUL的设计原意是为了创作Mozilla程序及其扩展，但事实上人们也能利用它来编写基于HTTP的网络应用程序和基于swt/swing/gwt的客户端程序。一些开源的架构使用了XUL，例如Pentaho XUL Framework[5]。Pentaho XUL使用XUl跨多种技术（Swing, SWT, GWT）渲染用户界面，来实现业务逻辑的可重用性。shandor-xul[6]项目也是基于XUl开发的,项目地址见参考资料[6]。<br />
Firefox里内置的一些XUL 地址见：<a href="http://www.cnblogs.com/jxsoft/archive/2011/04/07/2008202.html" target="_blank">http://www.cnblogs.com/jxsoft/archive/2011/04/07/2008202.html</a></p>

<p><span style="color: #339966;"><strong>运行XUL应用程序</strong></span>
可以选择 3 种方式来运行 XUL 应用程序：<br />
1.使用基于 Mozilla 的浏览器进行简单测试<br />
2.使用XULRunner<br />
3.使用Firefox 3.0作为XUL运行时，它的功能和 XULRunner很相似</p>

<p><strong><span style="color: #339966;">总结</span></strong>
XUL用户界面语言是一种可用于开发Mozilla独立应用程序和浏览器扩展的通用语言，还可以用来实现跨多种UI技术的用户接口，提高业务逻辑代码的重用性，第二点视乎是更值得推荐使用的。关于XUl的教程见参考资料。</p>

<p><span style="color: #339966;"><strong>参考资料</strong></span></p>
<li>
1.XUL Wiki :<a href="http://zh.wikipedia.org/wiki/XUL" target="_blank">http://zh.wikipedia.org/wiki/XUL</a>
</li>
<li>2.XML 用户界面语言（XUL）开发简介：<a href="http://www.ibm.com/developerworks/cn/education/xml/x-xulintro/section2.html" target="_blank">http://www.ibm.com/developerworks/cn/education/xml/x-xulintro/section2.html</a>
</li>
<li>3.XUL 2.0: <a href="https://wiki.mozilla.org/XUL:Home_Page" target="_blank">https://wiki.mozilla.org/XUL:Home_Page</a>
</li>
<li>4.[XUL结构](https://developer.mozilla.org/cn/XUL_%E6%95%99%E7%A8%8B/1-2_XUL%E7%9A%84%E7%BB%93%E6%9E%84)</li>
<li>5.Pentaho XUL ramework: <a href="http://wiki.pentaho.com/display/ServerDoc2x/The+Pentaho+XUL+Framework+Developer's+Guide" target="_blank">http://wiki.pentaho.com/display/ServerDoc2x/The+Pentaho+XUL+Framework+Developer's+Guide</a>
</li>
<li>6.shandor-xul:<a href="http://code.google.com/p/shandor-xul/" target="_blank">http://code.google.com/p/shandor-xul/</a>
</li>
<li>7.Mozilla XUL教程: <a href="https://developer.mozilla.org/index.php?title=cn/XUL_%E6%95%99%E7%A8%8B" target="_blank">https://developer.mozilla.org/index.php</a>
</li>

