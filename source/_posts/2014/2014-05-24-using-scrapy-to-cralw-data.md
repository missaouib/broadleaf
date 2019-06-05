---
layout: post

title: 使用Scrapy抓取数据

description: Scrapy是Python开发的一个快速、高层次的屏幕抓取和web抓取框架，用于抓取web站点并从页面中提取结构化的数据。Scrapy用途广泛，可以用于数据挖掘、监测和自动化测试。

keywords: scrapy,python

category: python

tags: [scrapy]

published: true

---

Scrapy是Python开发的一个快速,高层次的屏幕抓取和web抓取框架，用于抓取web站点并从页面中提取结构化的数据。Scrapy用途广泛，可以用于数据挖掘、监测和自动化测试。

- 官方主页： <http://www.scrapy.org/>
- 中文文档：[Scrapy 0.22 文档](http://scrapy-chs.readthedocs.org/zh_CN/latest/index.html)
- GitHub项目主页：<https://github.com/scrapy/scrapy>

Scrapy 使用了 Twisted 异步网络库来处理网络通讯。整体架构大致如下（注：图片来自互联网）：

![scrapy](http://blog.pluskid.org/wp-content/uploads/2009/08/scrapy_architecture.png)

Scrapy主要包括了以下组件：

- 引擎，用来处理整个系统的数据流处理，触发事务。
- 调度器，用来接受引擎发过来的请求，压入队列中，并在引擎再次请求的时候返回。
- 下载器，用于下载网页内容，并将网页内容返回给蜘蛛。
- 蜘蛛，蜘蛛是主要干活的，用它来制订特定域名或网页的解析规则。
- 项目管道，负责处理有蜘蛛从网页中抽取的项目，他的主要任务是清晰、验证和存储数据。当页面被蜘蛛解析后，将被发送到项目管道，并经过几个特定的次序处理数据。
- 下载器中间件，位于Scrapy引擎和下载器之间的钩子框架，主要是处理Scrapy引擎与下载器之间的请求及响应。
- 蜘蛛中间件，介于Scrapy引擎和蜘蛛之间的钩子框架，主要工作是处理蜘蛛的响应输入和请求输出。
- 调度中间件，介于Scrapy引擎和调度之间的中间件，从Scrapy引擎发送到调度的请求和响应。

使用Scrapy可以很方便的完成网上数据的采集工作，它为我们完成了大量的工作，而不需要自己费大力气去开发。

# 1. 安装

## 安装 python

Scrapy 目前最新版本为0.22.2，该版本需要 python 2.7，故需要先安装 python 2.7。这里我使用 centos 服务器来做测试，因为系统自带了 python ，需要先检查 python 版本。

查看python版本：

~~~bash
$ python -V
Python 2.6.6
~~~

升级版本到2.7：

~~~bash
$ wget http://python.org/ftp/python/2.7.6/Python-2.7.6.tar.xz
$ tar xf Python-2.7.6.tar.xz
$ cd Python-2.7.6
$ ./configure --prefix=/usr/local --enable-unicode=ucs4 --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib"
$ make && make altinstall
~~~

建立软连接，使系统默认的 python指向 python2.7

~~~bash
$ mv /usr/bin/python /usr/bin/python2.6.6 
$ ln -s /usr/local/bin/python2.7 /usr/bin/python 
~~~

再次查看python版本：

~~~bash
$ python -V
Python 2.7.6
~~~

## 安装 

这里使用 wget 的方式来安装 [setuptools](http://pypi.python.org/pypi/setuptools) :

~~~bash
$ wget https://bootstrap.pypa.io/ez_setup.py -O - | python
~~~

## 安装 zope.interface

~~~bash
$ easy_install zope.interface
~~~

## 安装 twisted

Scrapy 使用了 Twisted 异步网络库来处理网络通讯，故需要安装 twisted。

安装 twisted 前，需要先安装 gcc：

~~~bash
$ yum install gcc -y
~~~

然后，再通过 easy_install 安装 twisted：

~~~bash
$ easy_install twisted
~~~

如果出现下面错误：

~~~bash
$ easy_install twisted
Searching for twisted
Reading https://pypi.python.org/simple/twisted/
Best match: Twisted 14.0.0
Downloading https://pypi.python.org/packages/source/T/Twisted/Twisted-14.0.0.tar.bz2#md5=9625c094e0a18da77faa4627b98c9815
Processing Twisted-14.0.0.tar.bz2
Writing /tmp/easy_install-kYHKjn/Twisted-14.0.0/setup.cfg
Running Twisted-14.0.0/setup.py -q bdist_egg --dist-dir /tmp/easy_install-kYHKjn/Twisted-14.0.0/egg-dist-tmp-vu1n6Y
twisted/runner/portmap.c:10:20: error: Python.h: No such file or directory
twisted/runner/portmap.c:14: error: expected ‘=’, ‘,’, ‘;’, ‘asm’ or ‘__attribute__’ before ‘*’ token
twisted/runner/portmap.c:31: error: expected ‘=’, ‘,’, ‘;’, ‘asm’ or ‘__attribute__’ before ‘*’ token
twisted/runner/portmap.c:45: error: expected ‘=’, ‘,’, ‘;’, ‘asm’ or ‘__attribute__’ before ‘PortmapMethods’
twisted/runner/portmap.c: In function ‘initportmap’:
twisted/runner/portmap.c:55: warning: implicit declaration of function ‘Py_InitModule’
twisted/runner/portmap.c:55: error: ‘PortmapMethods’ undeclared (first use in this function)
twisted/runner/portmap.c:55: error: (Each undeclared identifier is reported only once
twisted/runner/portmap.c:55: error: for each function it appears in.)
~~~

请安装 python-devel 然后再次运行：

~~~bash
$ yum install python-devel -y
$ easy_install twisted
~~~

如果出现下面异常：

~~~
error: Not a recognized archive type: /tmp/easy_install-tVwC5O/Twisted-14.0.0.tar.bz2
~~~

请手动下载然后安装，下载地址在[这里](http://pypi.python.org/pypi/Twisted)

~~~bash
$ wget https://pypi.python.org/packages/source/T/Twisted/Twisted-14.0.0.tar.bz2#md5=9625c094e0a18da77faa4627b98c9815
$ tar -vxjf Twisted-14.0.0.tar.bz2
$ cd Twisted-14.0.0
$ python setup.py install
~~~

## 安装 pyOpenSSL

先安装一些依赖：

~~~bash
$ yum install libffi libffi-devel openssl-devel -y
~~~
然后，再通过 easy_install 安装 pyOpenSSL：

~~~bash
$ easy_install pyOpenSSL
~~~


## 安装 Scrapy

先安装一些依赖：

~~~bash
$ yum install libxml2 libxslt libxslt-devel -y
~~~

最后再来安装 Scrapy ：

~~~bash
$ easy_install scrapy
~~~

# 2. 使用 Scrapy

在安装成功之后，你可以了解一些 Scrapy 的基本概念和使用方法，并学习 Scrapy 项目的例子 dirbot 。

Dirbot 项目位于 <https://github.com/scrapy/dirbot>，该项目包含一个 README 文件，它详细描述了项目的内容。如果你熟悉 git，你可以 checkout 它的源代码。或者你可以通过点击 Downloads 下载 tarball 或 zip 格式的文件。

下面以该例子来描述如何使用 Scrapy 创建一个爬虫项目。

## 新建工程

在抓取之前，你需要新建一个 Scrapy 工程。进入一个你想用来保存代码的目录，然后执行：

~~~bash
$ scrapy startproject tutorial
~~~

这个命令会在当前目录下创建一个新目录 tutorial，它的结构如下：

~~~
.
├── scrapy.cfg
└── tutorial
    ├── __init__.py
    ├── items.py
    ├── pipelines.py
    ├── settings.py
    └── spiders
        └── __init__.py
~~~

这些文件主要是：

- scrapy.cfg: 项目配置文件
- tutorial/: 项目python模块, 呆会代码将从这里导入
- tutorial/items.py: 项目items文件
- tutorial/pipelines.py: 项目管道文件
- tutorial/settings.py: 项目配置文件
- tutorial/spiders: 放置spider的目录

## 定义Item

Items是将要装载抓取的数据的容器，它工作方式像 python 里面的字典，但它提供更多的保护，比如对未定义的字段填充以防止拼写错误。

它通过创建一个 `scrapy.item.Item` 类来声明，定义它的属性为 `scrpy.item.Field` 对象，就像是一个对象关系映射(ORM). 
我们通过将需要的item模型化，来控制从 dmoz.org 获得的站点数据，比如我们要获得站点的名字，url 和网站描述，我们定义这三种属性的域。要做到这点，我们编辑在 tutorial 目录下的 items.py 文件，我们的 Item 类将会是这样

~~~python
from scrapy.item import Item, Field 
class DmozItem(Item):
    title = Field()
    link = Field()
    desc = Field()
~~~

刚开始看起来可能会有些困惑，但是定义这些 item 能让你用其他 Scrapy 组件的时候知道你的 items 到底是什么。

## 编写爬虫(Spider)

Spider 是用户编写的类，用于从一个域（或域组）中抓取信息。们定义了用于下载的URL的初步列表，如何跟踪链接，以及如何来解析这些网页的内容用于提取items。

要建立一个 Spider，你可以为 `scrapy.spider.BaseSpider` 创建一个子类，并确定三个主要的、强制的属性：

- `name`：爬虫的识别名，它必须是唯一的，在不同的爬虫中你必须定义不同的名字.
- `start_urls`：爬虫开始爬的一个 URL 列表。爬虫从这里开始抓取数据，所以，第一次下载的数据将会从这些 URLS 开始。其他子 URL 将会从这些起始 URL 中继承性生成。
- `parse()`：爬虫的方法，调用时候传入从每一个 URL 传回的 Response 对象作为参数，response 将会是 parse 方法的唯一的一个参数,

这个方法负责解析返回的数据、匹配抓取的数据(解析为 item )并跟踪更多的 URL。

在 tutorial/spiders 目录下创建 DmozSpider.py

~~~python
from scrapy.spider import BaseSpider

class DmozSpider(BaseSpider):
    name = "dmoz"
    allowed_domains = ["dmoz.org"]
    start_urls = [
        "http://www.dmoz.org/Computers/Programming/Languages/Python/Books/",
        "http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/"
    ]

    def parse(self, response):
        filename = response.url.split("/")[-2]
        open(filename, 'wb').write(response.body)
~~~

## 运行项目

~~~bash
$ scrapy crawl dmoz
~~~

该命令从 dmoz.org 域启动爬虫，第三个参数为 DmozSpider.py 中的 name 属性值。

## xpath选择器

Scrapy 使用一种叫做 XPath selectors 的机制，它基于 XPath 表达式。如果你想了解更多selectors和其他机制你可以查阅[资料](http://doc.scrapy.org/topics/selectors.html#topics-selectors)。

这是一些XPath表达式的例子和他们的含义：

- `/html/head/title`: 选择HTML文档 `<head>` 元素下面的 `<title>` 标签。
- `/html/head/title/text()`: 选择前面提到的` <title>` 元素下面的文本内容
- `//td`: 选择所有 `<td>` 元素
- `//div[@class="mine"]`: 选择所有包含 `class="mine"` 属性的div 标签元素

这只是几个使用 XPath 的简单例子，但是实际上 XPath 非常强大。如果你想了解更多 XPATH 的内容，我们向你推荐这个 [XPath 教程](http://www.w3schools.com/XPath/default.asp)

为了方便使用 XPaths，Scrapy 提供 Selector 类， 有三种方法

- `xpath()`：返回selectors列表, 每一个select表示一个xpath参数表达式选择的节点.
- `extract()`：返回一个unicode字符串，该字符串为XPath选择器返回的数据
- `re()`： 返回unicode字符串列表，字符串作为参数由正则表达式提取出来
- `css()`

## 提取数据

我们可以通过如下命令选择每个在网站中的 `<li>` 元素:

~~~python
sel.xpath('//ul/li') 
~~~

然后是网站描述:

~~~python
sel.xpath('//ul/li/text()').extract()
~~~

网站标题:

~~~python
sel.xpath('//ul/li/a/text()').extract()
~~~

网站链接:

~~~python
sel.xpath('//ul/li/a/@href').extract()
~~~

如前所述，每个 `xpath()` 调用返回一个 selectors 列表，所以我们可以结合 `xpath()` 去挖掘更深的节点。我们将会用到这些特性，所以:

~~~python
sites = sel.xpath('//ul/li')
for site in sites:
    title = site.xpath('a/text()').extract()
    link = site.xpath('a/@href').extract()
    desc = site.xpath('text()').extract()
    print title, link, desc
~~~

## 使用Item

`scrapy.item.Item` 的调用接口类似于 python 的 dict ，Item 包含多个 `scrapy.item.Field`。这跟 django 的 Model 与  

Item 通常是在 Spider 的 parse 方法里使用，它用来保存解析到的数据。

最后修改爬虫类，使用 Item 来保存数据，代码如下：

~~~python
from scrapy.spider import Spider
from scrapy.selector import Selector

from dirbot.items import Website


class DmozSpider(Spider):
    name = "dmoz"
    allowed_domains = ["dmoz.org"]
    start_urls = [
        "http://www.dmoz.org/Computers/Programming/Languages/Python/Books/",
        "http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/",
    ]

    def parse(self, response):
        """
        The lines below is a spider contract. For more info see:
        http://doc.scrapy.org/en/latest/topics/contracts.html

        @url http://www.dmoz.org/Computers/Programming/Languages/Python/Resources/
        @scrapes name
        """
        sel = Selector(response)
        sites = sel.xpath('//ul[@class="directory-url"]/li')
        items = []

        for site in sites:
            item = Website()
            item['name'] = site.xpath('a/text()').extract()
            item['url'] = site.xpath('a/@href').extract()
            item['description'] = site.xpath('text()').re('-\s([^\n]*?)\\n')
            items.append(item)

        return items
~~~

现在，可以再次运行该项目查看运行结果：

~~~bash
$ scrapy crawl dmoz
~~~

## 使用Item Pipeline

在 settings.py 中设置 `ITEM_PIPELINES`，其默认为`[]`，与 django 的 `MIDDLEWARE_CLASSES` 等相似。
从 Spider 的 parse 返回的 Item 数据将依次被 `ITEM_PIPELINES` 列表中的 Pipeline 类处理。

一个 Item Pipeline 类必须实现以下方法：

- `process_item(item, spider)` 为每个 item pipeline 组件调用，并且需要返回一个 `scrapy.item.Item` 实例对象或者抛出一个 `scrapy.exceptions.DropItem` 异常。当抛出异常后该 item 将不会被之后的 pipeline 处理。参数:
  - `item (Item object)` – 由 parse 方法返回的 Item 对象
  - `spider (BaseSpider object)` – 抓取到这个 Item 对象对应的爬虫对象

也可额外的实现以下两个方法：

- `open_spider(spider)` 当爬虫打开之后被调用。参数: `spider (BaseSpider object)` – 已经运行的爬虫
- `close_spider(spider)` 当爬虫关闭之后被调用。参数: `spider (BaseSpider object)` – 已经关闭的爬虫

## 保存抓取的数据

保存信息的最简单的方法是通过 [Feed exports](http://doc.scrapy.org/en/0.22/topics/feed-exports.html#topics-feed-exports)，命令如下：

~~~bash
$ scrapy crawl dmoz -o items.json -t json
~~~

除了 json 格式之外，还支持 JSON lines、CSV、XML格式，你也可以通过接口扩展一些格式。

对于小项目用这种方法也足够了。如果是比较复杂的数据的话可能就需要编写一个 Item Pipeline 进行处理了。

所有抓取的 items 将以 JSON 格式被保存在新生成的 items.json 文件中

## 总结

上面描述了如何创建一个爬虫项目的过程，你可以参照上面过程联系一遍。作为学习的例子，你还可以参考这篇文章：[scrapy 中文教程（爬cnbeta实例）](http://wsky.org/archives/191.html) 。

这篇文章中的爬虫类代码如下：

~~~python
from scrapy.contrib.spiders import CrawlSpider, Rule
from scrapy.contrib.linkextractors.sgml import SgmlLinkExtractor
from scrapy.selector import Selector
 
from cnbeta.items import CnbetaItem
 
class CBSpider(CrawlSpider):
    name = 'cnbeta'
    allowed_domains = ['cnbeta.com']
    start_urls = ['http://www.cnbeta.com']
 
    rules = (
        Rule(SgmlLinkExtractor(allow=('/articles/.*\.htm', )),
             callback='parse_page', follow=True),
    )
 
    def parse_page(self, response):
        item = CnbetaItem()
        sel = Selector(response)
        item['title'] = sel.xpath('//title/text()').extract()
        item['url'] = response.url
        return item
~~~

需要说明的是：

- 该爬虫类继承的是 `CrawlSpider` 类，并且定义规则，rules指定了含有 `/articles/.*\.htm` 的链接都会被匹配。
- 该类并没有实现parse方法，并且规则中定义了回调函数 `parse_page`，你可以参考更多资料了解 CrawlSpider 的用法


# 3. 学习资料

接触 Scrapy，是因为想爬取一些知乎的数据，最开始的时候搜索了一些相关的资料和别人的实现方式。

Github 上已经有人或多或少的实现了对知乎数据的爬取，我搜索到的有以下几个仓库：

- <https://github.com/KeithYue/Zhihu_Spider> 实现先通过用户名和密码登陆再爬取数据，代码见 [zhihu_spider.py](https://github.com/KeithYue/Zhihu_Spider/blob/master/zhihu/zhihu/spiders/zhihu_spider.py)。
- <https://github.com/immzz/zhihu-scrapy> 使用 selenium 下载和执行 javascript 代码。
- <https://github.com/tangerinewhite32/zhihu-stat-py>
- <https://github.com/Zcc/zhihu> 主要是爬指定话题的topanswers，还有用户个人资料，添加了登录代码。
- <https://github.com/pelick/VerticleSearchEngine> 基于爬取的学术资源，提供搜索、推荐、可视化、分享四块。使用了 Scrapy、MongoDB、Apache Lucene/Solr、Apache Tika等技术。
- <https://github.com/geekan/scrapy-examples> scrapy的一些例子，包括获取豆瓣数据、linkedin、腾讯招聘数据等例子。
- <https://github.com/owengbs/deeplearning> 实现分页获取话题。
- <https://github.com/gnemoug/distribute_crawler> 使用scrapy、redis、mongodb、graphite实现的一个分布式网络爬虫,底层存储mongodb集群,分布式使用redis实现,爬虫状态显示使用graphite实现
- <https://github.com/weizetao/spider-roach> 一个分布式定向抓取集群的简单实现。
- <https://github.com/scrapinghub/portia> 这是一个可视化爬虫，基于Scrapy。它提供了可视化操作的Web页面，你只需点击页面上你要抽取的数据就行
- <https://github.com/binux/pyspider> 你如果不喜欢 Scrapy，可以试试 pyspider ，他让你在 WEB 界面编写调试脚本，监控执行状态，查看历史和结果 ，你可以在线试下 demo：[Dashboard - pyspider](http://demo.pyspider.org/)

其他资料：

- <http://www.52ml.net/tags/Scrapy> 收集了很多关于 Scrapy 的文章，**推荐阅读**
- [用Python Requests抓取知乎用户信息](http://zihaolucky.github.io/using-python-to-build-zhihu-cralwer/)
- [使用scrapy框架爬取自己的博文](http://www.it165.net/pro/html/201405/13112.html)
- [Scrapy 深入一点点](http://github.windwild.net/2013/03/scrapy002/)
- [使用python，scrapy写（定制）爬虫的经验，资料，杂。](http://www.kankanews.com/ICkengine/archives/94817.shtml)
- [Scrapy 轻松定制网络爬虫](http://blog.pluskid.org/?p=366&cpage=1)
- [在scrapy中怎么让Spider自动去抓取豆瓣小组页面](http://my.oschina.net/chengye/blog/124162)

scrapy 和 javascript 交互例子：

- [用scrapy框架爬取js交互式表格数据](http://www.xuebuyuan.com/2017949.html)
- [scrapy + selenium 解析javascript 实例](http://wsky.org/archives/211.html)

还有一些待整理的知识点：

- _如何先登陆再爬数据_
- _如何使用规则做过滤_
- _如何递归爬取数据_
- _scrapy的参数设置和优化_
- _如何实现分布式爬取_

# 4. 总结

以上就是最近几天学习 Scrapy 的一个笔记和知识整理，参考了一些网上的文章才写成此文，对此表示感谢，也希望这篇文章能够对你有所帮助。如果你有什么想法，欢迎留言；如果喜欢此文，请帮忙分享，谢谢!
