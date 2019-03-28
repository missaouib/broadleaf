---
layout: post
title: JSF中EL表达式之this扩展
category: java
tags: jsf
keywords: jsf
description: 本篇文章来自以前公司的一套jsf+seam+Hibernate的一套框架，其对jsf进行了一些改进，其中包括:EL表达式中添加this，通过jsf的渲染实现权限控制到按钮等等。JSF表达式中添加this，主要是为了在facelets页面使用this关键字引用（JSF自动查找）到当前页面对应的pojo类，详细说明见下午。因为，本文的文章是公司同事整理的，本文作者仅仅是将其分享出来，供大家参考思路，如果有什么不妥的话，请告知。
---
本篇文章来自以前公司的一套jsf+seam+Hibernate的一套框架，其对jsf进行了一些改进，其中包括:EL表达式中添加this，通过jsf的渲染实现权限控制到按钮等等。JSF表达式中添加this，主要是为了在facelets页面使用this关键字引用（JSF自动查找）到当前页面对应的pojo类，详细说明见下午。因为，本文的文章是公司同事整理的，本文作者仅仅是将其分享出来，供大家参考思路，如果有什么不妥的话，请告知。

<strong>EL表达式this扩展</strong>
在业务系统中，大量页面具有大量区域是相似或者相同的，或者可能根据某些局部特征的变化具有一定的变化，jsf中通过facelet模板功能可以达到一定程度的页面重用，从而减轻开发人员编辑和拷贝一些页面代码，达到重用的目的。然而，她们具有如下限制：
1.Java语言作为一种典型的OO语言，通过抽象、继承等功能，可以大量重用已经实现或者在父类中已经存在的属性和方法等。模板技术作为一种静态加载和内容替换，无法充分利用面向对象的继承功能
2.由于Jsf/jsp框架采用视图和动作分离的模型，多个相似功能在不同的页面实现中由于页面对应点动作类不同因而必须使用复制的方法；
3.模板中使用EL表达式与后台动作类交互，这种交互是基于绝对名称的，不同的网页对应的动作类是完全不同的，因此很难重用和利用面向对象的特征。

我们需要一种新的功能，实现：
1.模板的应用特种可以参照OO的继承特种，即模板的对模板的引用可以看成一种继承，这种继承可以和java的OO是一致的
2.多个页面和多个独立java后台程序相同部分完全可以抽离出来，不依赖它们是否继承关系、只需保证他们具有相同的属性或者方法
3.动态映射功能，即在满足上述基础上可以实现页面和后台实现类的属性和方法的自动映射
4.兼容标准的EL表达式

我们将上述功能处理为“this”表达式。其功能模型为：
<div class="pic">
<img src="http://7xnrdo.com1.z0.glb.clouddn.com/2012/02/this-expression-of-el.jpg" alt="" title="this expression of el"/>
</div>
页面A和页面B分别引用了通用功能T,内含this相关的El表达式，通过分析处理，分别映射到对应的页面动作类的属性A.name和B.name。A和B可以从相同的基类C派生而来，只需C类实现了name属性即可，A类和B类也可以毫不相关，但是它们具有相同的属性name。


<strong>动作类和页面的一致性保证</strong>
为了有效实现this表达式，我们实现如下映射规则：
1.名称为小写方式，不管页面如何命名，对应的后台类的jsf标识符都转换为小写
2.页面和相应的后台类以相同命名方式，页面的目录转化为后台类的包名，名称通过点分隔包名，如根目录的a.xhtml对应的后台类名称为A.java，其唯一jsf标识名称为“a”，test/b.xhtml的后台类为test/B.java，其唯一jsf标识为“test.b”

<strong>“this”EL表达式算法</strong>
算法流程如下图：
<div class="pic">
<img src="http://7xnrdo.com1.z0.glb.clouddn.com/2012/02/this-expression-flow-of-el.jpg" alt="" title="this expression flow of el"/>
</div>
