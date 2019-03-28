---
layout: post
title: All Things Jekyll
description: Jekyll是一个静态站点生成器，它会根据网页源码生成静态文件。它提供了模板、变量、插件等功能，所以实际上可以用来编写整个网站
category: devops
tags: [jekyll]
---

Jekyll是一个简洁的、特别针对博客平台的静态网站生成器。它使用一个模板目录作为网站布局的基础框架，并在其上运行Textile、Markdown或Liquid标记语言的转换器，最终生成一个完整的静态Web站点，可以被放置在Apache或者你喜欢的其他任何Web服务器上。它同时也是GitHub Pages、一个由GitHub提供的用于托管项目主页或博客的服务，在后台所运行的引擎。

# 1. 安装
Jekyll使用动态脚本语言Ruby写成。请首先下载并安装Ruby，目前需要的ruby版本为`1.9.1`。


在使用Jekyll之前，你可能想要对Ruby语言有一些初步了解（非必需）。

安装Jekyll的最好方式是通过`RubyGems`：

~~~
gem install jekyll
~~~

Jekyll依赖以下的gems模块：liquid、fast-stemmer、classifier、directory_watcher、syntax、maruku、kramdown、posix-spawn和albino。它们会被`gem install`命令自动安装。

# 2. 模板引擎

## 2.1 RDiscount
如果你想用 RDiscount 取代 Maruku 作为你的Markdown标记语言转换引擎，只需确认安装：

~~~
gem install rdiscount
~~~

在你站点下的`_config.yml`文件中加入以下配置：

~~~
markdown: rdiscount
~~~

## 2.2 RedCloth

若要使用Textile标记语言，需要安装相应的转换引擎[RedCloth](http://redcloth.org/)。

~~~
gem install RedCloth
~~~

## 2.3 Redcarpet

Redcarpet是由GitHub自己人开发的，一直以来它被用于在GitHub上渲染Markdown格式文本（也就是[GitHub Flavored Markdown](http://github.github.com/github-flavored-markdown/)）。由于API兼容性的原因，Jekyll以前的版本并不支持Redcarpet。现在，Jekyll 0.12.0终于增加了对Redcarpet 2引擎的支持，只需安装：

~~~
$ gem install redcarpet
~~~

把`_config.yml`中的Markdown引擎设置从：

~~~
markdown: rdiscount
~~~

改为：

~~~
markdown: redcarpet
~~~

就可以迁移到Redcarpet上了。

Redcarpet所支持的GitHub Flavored Markdown比起标准的Markdown语法来增加了不少便利之处，诸如围栏式代码块（Fenced code blocks）。

redcarpet 有很多很多的options可以设置，见：[https://github.com/vmg/redcarpet](https://github.com/vmg/redcarpet)

edcarpet 只和 markdown parser有关，如果需要设置高亮，可以使用[pygments](http://pygments.org/)

你可能会用到的标记语言和模板引擎：

- [Textile](http://en.wikipedia.org/wiki/Textile_(markup_language) 可读性好的轻量级标记语言，可以被转换成XHTML格式。
 - [Textile Home Page](http://www.textism.com/tools/textile/)
 - [A Textile Reference](http://redcloth.org/hobix.com/textile/)
- [RedCloth](http://redcloth.org/) Ruby的Textile实现引擎。
- [Markdown](http://en.wikipedia.org/wiki/Markdown) 另一种Jekyll所支持的轻量级标记语言。
 - [Markdown Home Page](http://daringfireball.net/projects/markdown/)
 - [BlueCloth](http://deveiate.org/projects/BlueCloth) Ruby的Markdown实现引擎。
- [Maruku](http://maruku.rubyforge.org/) Ruby的另一个Markdown实现引擎，效率较高。
- [RDiscount](http://github.com/rtomayko/rdiscount/) Ruby的另一个Markdown实现引擎，效率比Maruku更高。
- [Liquid](http://liquidmarkup.org/) Ruby的模板渲染引擎。它也是Jekyll所使用的模板引擎。
 - [Liquid for Designers](https://github.com/Shopify/liquid/wiki/Liquid-for-Designers)
 - [Liquid for Programmers](https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers)

# 3. 基本结构

Jekyll从核心上来说是一个文本转换引擎。该系统内部的工作原理是：你输入一些用自己喜爱的标记语言格式书写的文本，可以是Markdown、Textile或纯粹的HTML，它将这些文本混合后放入一个或一整套页面布局当中。在整个过程中，你可以自行决定你的站点URL的模式、以及哪些数据将被显示在页面中，等等。这一切都将通过严格的文本编辑完成，而生成的Web界面则是最终的产品。

一个典型的Jekyll站点通常具有如下结构：

~~~
.
|-- _config.yml
|-- _includes
|-- _layouts
|   |-- default.html
|   `-- post.html
|-- _posts
|-- _site
`-- index.html
~~~

以下是每部分功能的简述：

- `_config.yml`。保存Jekyll配置的文件。虽然绝大部分选项可以通过命令行参数指定，但将它们写入配置文件可以使你在每次执行时不必记住它们。
- `_includes`。该目录存放可以与`_layouts`和`_posts`混合、匹配并重用的文件。Liquid标签`{ % include % }`可以用于嵌入文件`_includes/file.ext`。
- `_layouts`。该目录存放用来插入帖子的网页布局模板。页面布局基于类似博客平台的一个帖子接一个帖子的原则，通过YAML前置数据定义。Liquid标签用于在页面上插入帖子的文本内容。
- `_posts`。该目录下存放的可以说成是你的"动态内容"。这些文件的格式很重要，它们的命名模式必须遵循 `YEAR-MONTH-DATE-title.MARKUP` 。每一个帖子的固定链接URL可以作弹性的调整，但帖子的发布日期和转换所使用的标记语言会根据且仅根据文件名中的相应部分来识别。
- `_site`。这里是Jekyll用以存放最终生成站点的根路径位置。也许把它加到你的 `.gitignore` 列表中会是个不错的主意。


# 4. 运行、部署
通常直接在命令行下使用可执行的Ruby脚本 jekyll ，它可以从gem安装。如果要启动一个临时的Web服务器并测试你的Jekyll站点，执行：

~~~
jekyll --server
~~~

然后在浏览器中访问 `http://localhost:4000` 或 `http://0.0.0.0:4000` 。当然这里还有其他许多参数选项可以使用。

由于Jekyll所做的仅仅是生成一个包含HTML等静态网站文件的目录（_site），它可以通过简单的拷贝（scp）、远程同步（rsync）、ftp上传或git等方式部署到任何Web服务器上，例如github、gitcafe、qiniu。

# 5. 一些技巧

## 使用表格

使用redcarpet模板引擎，通过gem安装redcarpet并修改`_config.yml`

~~~
markdown: redcarpet
redcarpet: 
    extensions: ["tables"]
~~~

在 Markdwon 文件中可以依据以下语法进行书写

~~~
|head1 head1 head1|head2 head2 head2|head3 head3 head3|head4 head4 head4|
|---|:---|:---:|---:|
|row1text1|row1text3|row1text3|row1text4|
|row2text1|row2text3|row2text3|row2text4|
~~~
然后添加如下样式：

~~~css
table {
margin-bottom: 20px;
max-width: 100%;
border-collapse: collapse;
transition: all 0.3s;
border: 1px solid rgba(0,0,0,0.167);
}
table {
border-collapse: collapse;
}
table thead>tr {
background-color: rgba(249,249,249,0.9);
}
table thead tr th {
border: 1px solid rgba(0,0,0,0.167);
border-top: 0px none;
border-bottom-width: 2px;
vertical-align: bottom;
padding: 8px;
}
table tbody tr td {
border: 1px solid rgba(0,0,0,0.167);
vertical-align: top;
padding: 8px;
}
~~~

# 6. 其他静态网站生成器
如果想要尝试一些其他的静态网页生成器，这里是一个简略的列表：

- Ruby
 - [Jekyll](http://jekyllrb.com/)
 - [Bonsai](http://tinytree.info/) 一个非常简单（但实用）的小脚本
 - [Webgen](http://webgen.rubyforge.org/) 一个较复杂的生成器
- Python
 - [Hyde](http://ringce.com/hyde) Jekyll的Python语言实现版本
 - [Cyrax](http://pypi.python.org/pypi/cyrax) 使用Jinja2模板引擎的生成器
- PHP
 - [Phrozn](http://www.phrozn.info/) PHP语言实现的静态网站生成器
- nodejs
 - [hexo](https://github.com/tommy351/hexo)一个台湾人实现的生成器
 - [papery](https://github.com/ericzhang-cn/papery) 纯nodejs编写
 - [DocPad](http://docpad.org/)  static web sites generator using Node.js

更详细的列表和介绍请参见：

- [Static Blog Generators](http://www.subspacefield.org/~travis/static_blog_generators.html)
- [32 Static Website Generators For Your Site, Blog Or Wiki](http://iwantmyname.com/blog/2011/02/list-static-website-generators.html)

# 7. 资源

- [jekyll官网](http://jekyllrb.com/)
- [Jekyll Bootstrap](http://jekyllbootstrap.com/‎)

- [搭建一个免费的，无限流量的Blog----github Pages和Jekyll入门](http://www.ruanyifeng.com/blog/2012/08/blogging_with_jekyll.html)
- [告别wordpress，拥抱jekyll](http://www.yangzhiping.com/tech/wordpress-to-jekyll.html)
- [像黑客一样写博客——Jekyll入门](http://www.soimort.org/posts/101/)
- [用 Jekyll 和 Octopress 搭建博客，哪个更合适？](http://www.zhihu.com/question/19996679)
- [Play with Jekyll](http://blog.skydark.info/programming/2012/03/23/play-with-jekyll/)

- [创造者](http://blog.zhuoqun.net/)
- [非常规思维研究所](http://blog.liulantao.com/)
- [Keep on Fighting!](http://yihui.name/cn/)
- [Havee's Space](http://havee.me/)
- [闭门造轮子](http://mytharcher.github.io/)
