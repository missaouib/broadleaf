---
layout: post
title: SiteMesh介绍
description: SiteMesh是由一个基于Web页面布局、装饰以及与现存Web应用整合的框架。它能帮助我们在由大量页面构成的项目中创建一致的页面布局和外观，如一致的导航条，一致的banner，一致的版权等等。它不仅仅能处理动态的内容，如jsp，php，asp等产生的内容，它也能处理静态的内容，如htm的内容，使得它的内容也符合你的页面结构的要求。甚至于它能将HTML文件象include那样将该文件作为一个面板的形式嵌入到别的文件中去。所有的这些，都是GOF的Decorator模式的最生动的实现。尽管它是由java语言来实现的，但它能与其他Web应用很好地集成
category: java
tags: [java]
---

# 1. SiteMesh简介

SiteMesh是由一个基于Web页面布局、装饰以及与现存Web应用整合的框架。它能帮助我们在由大量页面构成的项目中创建一致的页面布局和外观，如一致的导航条，一致的banner，一致的版权等等。它不仅仅能处理动态的内容，如jsp，php，asp等产生的内容，它也能处理静态的内容，如htm的内容，使得它的内容也符合你的页面结构的要求。甚至于它能将HTML文件象include那样将该文件作为一个面板的形式嵌入到别的文件中去。所有的这些，都是GOF的Decorator模式的最生动的实现。尽管它是由java语言来实现的，但它能与其他Web应用很好地集成。

# 2. SiteMesh原理

SiteMesh框架是OpenSymphony团队开发的一个非常优秀的页面装饰器框架，它通过对用户请求进行过滤，并对服务器向客户端响应也进行过滤，然后给原始页面加入一定的装饰(header,footer等)，然后把结果返回给客户端。通过SiteMesh的页面装饰，可以提供更好的代码复用，所有的页面装饰效果耦合在目标页面中，无需再使用include指令来包含装饰效果，目标页与装饰页完全分离，如果所有页面使用相同的装饰器，可以是整个Web应用具有统一的风格。

# 3. SiteMesh3

[SiteMesh3](https://github.com/sitemesh/sitemesh3)只有Alpha2版本而且很久没更新了,它号称性能快3倍内存少1倍。

另外，Atlassian公司因为在自己的产品中使用了SiteMesh2，所以后来也一直有维护，出到了2.5-atlassian-9版，不过不在maven中央库中，可以在[这里](https://maven-us.nuxeo.org/nexus/content/groups/public/opensymphony/sitemesh/2.5-atlassian-9/)下载。

<!-- more -->

# 4. SiteMesh2的使用

## 引入SiteMesh的依赖

在pom.xml中添加如下：

~~~xml
<dependency>
	<groupId>opensymphony</groupId>
	<artifactId>sitemesh</artifactId>
	<version>2.4.2</version>
	<scope>runtime</scope>
</dependency>
~~~

## 添加过滤器

在web.xml中添加过滤器：

~~~xml
<filter>
	<filter-name>sitemesh</filter-name>
	<filter-class>com.opensymphony.module.sitemesh.filter.PageFilter</filter-class>
</filter>
<filter-mapping>
	<filter-name>sitemesh</filter-name>
	<url-pattern>/*</url-pattern>
</filter-mapping>
~~~

## 新建decorators.xml文件

在WEB-INF下新建decorators.xml文件：

~~~xml
<?xml version="1.0" encoding="utf-8"?>
<decorators defaultdir="/WEB-INF/layouts/">
    <!-- 此处用来定义不需要过滤的页面 -->
    <excludes>
        <pattern>/static/*</pattern>
    </excludes>

    <!-- 用来定义装饰器要过滤的页面 -->
    <decorator name="default" page="default.jsp">
        <pattern>/*</pattern>
    </decorator>
</decorators>
~~~

理论上SiteMesh只会搞那些MIME type为html的页面，但在配置里先exclude掉一些静态内容和API的路径会更省心。



## 创建装饰器页面default.jsp

在decorators.xml中定义了一个装饰页面default.jsp：

~~~html
< %@ taglib uri="http://www.opensymphony.com/sitemesh/decorator" prefix="decorator" %>
<html>
<head>
    <title>My Site - <decorator:title default="Welcome!" /></title>
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
    <meta http-equiv="Cache-Control" content="no-store" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <decorator:head />
</head>
<body>
    <div id="content">
    	<decorator:body />
    </div>
</body>
</html>
~~~

装饰模板中可以使用的Sitemesh标签有：

- 取出被装饰页面的head标签中的内容。

~~~
<decorator:head />
~~~

- 取出被装饰页面的body标签中的内容。

~~~
<decorator:body />
~~~

- 取出被装饰页面的title标签中的内容。default为默认值

~~~
<decorator:title default=""  />
~~~

- 取出被装饰页面相关标签的属性值。

~~~
<decorator:getProperty property="" default=""  writeEntireProperty=""/>
~~~

- 将被装饰页面构造为一个对象，可以在装饰页面的JSP中直接引用。

~~~
<decorator:usePage id="" />
~~~

## 创建被装饰页面test.jsp

创建test.jsp如下：

~~~html
<html>
<head>
    <title>Hello world</title>
</head>
<body>
    <p>hello world.</p>
</body>
</html>
~~~

## 测试

访问test.jsp页面，查看源代码会显示如下：

~~~html
<html>
<head>
    <title>My Site - Hello world</title>
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
    <meta http-equiv="Cache-Control" content="no-store" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
</head>
<body>
	<div id="content">
   		<p>hello world.</p>
	</div>
</body>
</html>
~~~

# 5. 参考文章

- [1] [OpenSymphony SiteMesh Readme](https://github.com/sitemesh/sitemesh2#readme)
- [2] [springside4 wiki:SiteMesh](https://github.com/springside/springside4/wiki/SiteMesh)
