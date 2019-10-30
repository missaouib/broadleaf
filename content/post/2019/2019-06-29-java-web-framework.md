---
layout: post

title: Java Web框架发展历程
date: 2019-06-29T08:00:00+08:00
categories: [ java ]
tags: [java]
description:   在 Web 早期的开发中，通常采用的都是 Model1 模式，就是使用 JSP+JavaBean 技术，将页面显示和业务逻辑处理分开，由JSP页面来接收客户端请求，用JavaBean或其他服务完成业务逻辑、数据库操作和返回页面。
---

# Model1

​在 Web 早期的开发中，通常采用的都是 Model1 模式，就是使用 JSP+JavaBean 技术，将页面显示和业务逻辑处理分开，由JSP页面来接收客户端请求，用JavaBean或其他服务完成业务逻辑、数据库操作和返回页面。大概可以用下图来反映：

![img](/images/java-web-1.png)

- 优点：架构简单，比较适合小型项目开发      

- 缺点：JSP职责不单一，职责过重，不便于维护

# **Model2**

​Model1 虽然在一定程度上解耦了，但 JSP 既要负责页面控制，又要负责逻辑处理，职责不单一。此时Model2应运而生，使得各个部分各司其职。 

Model2 设计模式，实际上就是 mvc 模式的开发，把一个 Web 软件项目分成三层，包括视图层、控制层、模型层。

- Controller：应用程序中用户交互部分（Servlet）

- Model：应用程序数据逻辑部分（JavaBeans）

- View：数据显示部分（JSP）

![img](/images/java-web-2.png)

- 优点：职责清晰，较适合于大型项目架构。    

- 缺点：分层较多，不适合小型项目开发。

# XWork

​XWork 是一个标准的 Command 模式实现，并且完全从 Web 层脱离出来。Xwork 提供了很多核心功能：前端拦截器，运行时表单属性验证，类型转换，强大的表达式语言，IoC容器等。

![img](/images/java-web-3.jpg)

​       其目的是：创建一个泛化的、可重用且可扩展的命令模式框架，而不是一个特定在某个领域使用的框架。

　　其特点是：

　　1、基于一个简单的接口就可以进行灵活且可自定义的配置；

　　2、核心命令模式框架可以通过定制和扩展拦截器来适应任何请求/响应环境；

　　3、整个框架通过类型转换和使用OGNL的action属性验证来构建；

　　4、包含一个基于运行时Attribute和验证拦截器的强大的验证框架。

# WebWork

​WebWork 是由 OpenSymphony 组织开发的，是建立在称为 XWork 的 Command 模式框架之上的强大的基于 Web 的 MVC 框架。WebWork 目前最新版本是2.2.2，现在的 WebWork2.x 前身是 Rickard Oberg 开发的 WebWork，但现在 WebWork 已经被拆分成了 Xwork1 和 WebWork2 两个项目。

![img](/images/java-web-4.jpg)

​此架构图一共分为五个部分，其中五个部分分别由五种不同颜色表示。

1．浅灰色方框。分别代表了客户端的一次Http请求，和服务器端运算结束之后的一次响应。

2．浅红色方框。表示一次Action请求所要经过的Servlet filters（Servlet 过滤器）。我们可以看到最后一个filter就是我们前面介绍的WebWork的前端控制器。

3．蓝色方框。这是WebWork框架的核心部分。

1）一次请求到了WebWork的前端控制器，它首先会根据请求的URL解析出对应的action 名称，然后去咨询ActionMapper这个action是否需要被执行。

2）如果ActionMapper决定这个action需要被执行，前端控制器就把工作委派给ActionProxy。接着她们会咨询WebWork的配置管理器，并读取在web.xml文件中定义的配置信息。接下来ActionProxy会创建ActionInvocation对象。

3）ActionInvocation是Xwork原理的（Command模式）实现部分。它会调用这个Action已定义的拦截器(before方法)，Action方法，Result方法。

4）最后，看上面流程的图的方向，它会再执行拦截器（after方法），再回到Servlet Filter部分，最后结束并传给用户一个结果响应。

4．靛色方框。这是拦截器部分，在上面的拦截器章节我们已经有了详细的介绍。

5．黄色方框。这是我们在开发Web应用时，需要自己开发的程序。其中包括：Action类，页面模板，配置文件xwork.xml。

WebWork的三个关键部分

1．Actions。一般一个Action代表一次请求或调用。在WebWork中，一般Action类需要实现Action接口，或者直接继承基础类ActionSupport。这是，它要实现默认的execute方法，并返回一个在配置文件中定义的Result（也就是一个自定义的字符串而已）。当然，Action也可以只是一个POJO（普通Java对象），不用继承任何类也不用实现任何接口。Action是一次请求的控制器，同时也充当数据模型的角色，我们强烈建议不要将业务逻辑放在Action中。

2．Results。它是一个结果页面的定义。它用来指示Action执行之后，如何显示执行的结果。Result Type表示如何以及用哪种视图技术展现结果。通过Result Type，WebWork可以方便的支持多种视图技术；而且这些视图技术可以互相切换，Action部分不需做任何改动。

3．Interceptors。WebWork的拦截器，WebWork截获Action请求，在Action执行之前或之后调用拦截器方法。这样，可以用插拔的方式将功能注入到Action中。WebWork框架的很多功能都是以拦截器的形式提供出来。例如：参数组装，验证，国际化，文件上传等等。

# Struts

​Struts是一个基于Sun J2EE平台的MVC框架，主要是采用Servlet和JSP技术来实现的。

​在Struts中，已经由一个名为ActionServlet的Servlet充当控制器（Controller）的角色，根据描述模型、视图、控制器对应关系的struts-config.xml的配置文件，转发视图（View）的请求，组装响应数据模型（Model）。在MVC的模型（Model）部分，经常划分为两个主要子系统（系统的内部数据状态与改变数据状态的逻辑动作），这两个概念子系统分别具体对应Struts里的ActionForm与Action两个需要继承实现超类。

# Struts2

​Struts2 是一个基于 MVC 设计模式的 Web 应用框架，它本质上相当于一个 Servlet，在 MVC 设计模式中，Struts2 作为控制器来建立模型与视图的数据交互。Struts2 是 Struts 的下一代产品，是在 struts 和 WebWork 的技术基础上进行了合并的全新的 Struts2 框架。

Struts2 以 WebWork 为核心，采用拦截器的机制来处理用户的请求，这样的设计也使得业务逻辑控制器能够与 Servlet API 完全脱离开。

![img](/images/java-web-5.png)



## Struts2与Struts1的对比

​1，在Action实现类方面：

​Struts1要求Action类继承一个抽象基类，Struts2 Action类可以实现一个Action接口，也可以实现其他接口，使可选和定制服务成为可能。
​
Struts2 提供一个ActionSupport基类去实现常用的接口。即使Action接口不是必须实现的，只有一个包含execute方法的POJO类都可以用作Struts2的Action。

​2，线程模式方面：
​
Struts1 Action是单例模式并且必须是线程安全的，因为仅有Action的一个实例来处理所有的请求。单例策略限制了Struts1 Action能做的事，并且要在开发时特别小心。Action资源必须是线程安全的或同步的；Struts2 Action对象为每一个请求产生一个实例，因此没有线程安全问题。

​3，Servlet依赖方面：

​Struts1 Action依赖于Servlet API，因为Struts1 Action的execute方法中有HttpServletRequest和HttpServletResponse方法。
​Struts2 Action 不再依赖于ServletAPI，从而允许Action脱离Web容器运行，从而降低了测试Action的难度。当然，如果Action 需要直接访问HttpServletRequest和HttpServletResponse参数，Struts2 Action仍然可以访问它们。但是，大部分时候，Action都无需直接访问。

# JSF

​Java Server Faces 简称 JSF，是一种面向组件和事件驱动模型的WEB开发技术，是实现传统的 Model-View-Controller (MVC) 架构的一种 Web 框架。不同之处在于，它采用该模式的一种特别丰富的实现。与 Model 2 或者 Struts、WebWork 和 Spring MVC 之类的框架中使用的 “push-MVC” 方法相比，JSF 中的 MVC 实现更接近于传统的 GUI 应用程序。前面那些框架被归类为*基于动作的（action-based）*，而 JSF 则属于基于*组件模型* 的新的框架家族中的一员。

![img](/images/java-web-6.jpg)

## JSF与Struts区别
Struts使用Action来接受浏览器表单提交的事件，这里使用了Command模式，每个继承Action的子类都必须实现一个方法execute。

​在struts中，实际是一个表单Form对应一个Action类(或DispatchAction)，换一句话说：在Struts中实际是一个表单只能对应一个事件，struts这种事件方式称为application event，application event和component event相比是一种粗粒度的事件。

struts重要的表单对象ActionForm是一种对象，它代表了一种应用，这个对象中至少包含几个字段，这些字段是Jsp页面表单中的input字段，因为一个表单对应一个事件，所以，当我们需要将事件粒度细化到表单中这些字段时，也就是说，一个字段对应一个事件时，单纯使用Struts就不太可能，当然通过结合JavaScript也是可以转弯实现的。

# Shale 

[Shale](http://shale.apache.org/) 是在 Struts 之后，发展起来基于 JSF 的 Web 开发框架，在2009年5月20日已经退休。它是由 Struts 的创始人、JSF 专家组成员 Craig McClanahan 发起的。 Shale 的意思是“页岩”。简而言之，Shale 出自这样的思想：Web 框架如果以按功能划分的、松散连接的 “层” 的形式存在，则最为有效。每一层基本独立于其他层，并且关注于一个专门的方面。这一点类似于海岸附近基本上由页岩组成的地质沉积，因此这种新框架就被命名为 Shale！

​Shale 重用了大量的 Struts 基础代码，因此可以称 Struts 为它的"父"框架，但 Shale 是面向服务架构，它与 Struts 最大不同之处在于：Struts 与 JSF 集成，而 Shale 则是建立在 JSF 之上。 Struts 实质上是一个巨大的、复杂的请求处理器；而 Shale 则是一组可以以任何方式进行组合的服务。

总之，Shale 不是 Struts 的补充，而是一个全新的 Web 框架。

# Spring MVC

​SpringMVC 是一种 web 层 mvc 框架，用于替代 servlet（处理、响应请求，获取表单参数，表单校验等）。


## 参考文章

- [表现层框架Struts/Tapestry/JSF架构比较](https://www.jdon.com/artichect/sjt.htm)

- [JSF与Struts的异同](https://www.jdon.com/idea/jsf-struts.htm)
- [struts2请求过程源码分析](https://www.cnblogs.com/duanxz/p/5441342.html)

