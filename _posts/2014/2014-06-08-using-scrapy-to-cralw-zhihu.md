---
layout: post

title: 使用Scrapy爬取知乎网站

description: 本文主要记录使用使用Scrapy登录并爬取知乎网站的思路。

keywords: scrapy,python

category: python

tags: [scrapy,python]

published: true

---

本文主要记录使用使用 Scrapy 登录并爬取知乎网站的思路。Scrapy的相关介绍请参考 [使用Scrapy抓取数据](/2014/05/24/using-scrapy-to-cralw-data.html)。

相关代码，见 <https://github.com/javachen/scrapy-zhihu-github> ，在阅读这部分代码之前，请先了解 Scrapy 的一些基本用法。

# 使用cookie模拟登陆

关于 cookie 的介绍和如何使用 python 实现模拟登陆，请参考[python爬虫实践之模拟登录](http://blog.csdn.net/figo829/article/details/18728381)。

从这篇文章你可以学习到如何获取一个网站的 cookie 信息。下面所讲述的方法就是使用 cookie 来模拟登陆知乎网站并爬取用户信息。

一个模拟登陆知乎网站的示例代码如下：

~~~python
# -*- coding:utf-8 -*-

from scrapy.selector import Selector
from scrapy.contrib.linkextractors.sgml import SgmlLinkExtractor
from scrapy.contrib.spiders import CrawlSpider, Rule
from scrapy.http import Request,FormRequest

from zhihu.settings import *

class ZhihuLoginSpider(CrawlSpider):
    name = 'zhihulogin1'
    allowed_domains = ['zhihu.com']
    start_urls = ['http://www.zhihu.com/lookup/class/']

    rules = (
        Rule(SgmlLinkExtractor(allow=r'search/')),
        Rule(SgmlLinkExtractor(allow=r'')),
    )

    def __init__(self):
        self.headers =HEADER
        self.cookies =COOKIES

    def start_requests(self):
        for i, url in enumerate(self.start_urls):
            yield FormRequest(url, meta = {'cookiejar': i}, \
                              headers = self.headers, \
                              cookies =self.cookies,
                              callback = self.parse_item)#jump to login page

    def parse_item(self, response):
        selector = Selector(response)

        urls = []
        for ele in selector.xpath('//ul/li[@class="suggest-item"]/div/a/@href').extract():
           urls.append(ele)
        print urls
~~~

上面是一个简单的示例，重写了 `start_requests` 方法，针对 `start_urls` 中的每一个url，这里为 <http://www.zhihu.com/lookup/class/>，重新创建 FormRequest 请求该 url，并设置 headers 和 cookies 两个参数，这样可以通过 cookies 伪造登陆。

FormRequest 请求中有一个回调函数 parse_item 用于解析页面内容。

HEADER 和 COOKIES 在 settings.py 中定义如下：

~~~
HEADER={
    "Host": "www.zhihu.com",
    "Connection": "keep-alive",
    "Cache-Control": "max-age=0",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36",
    "Referer": "http://www.zhihu.com/people/raymond-wang",
    "Accept-Encoding": "gzip,deflate,sdch",
    "Accept-Language": "zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4,zh-TW;q=0.2",
    }

COOKIES={
    'checkcode':r'"$2a$10$9FVE.1nXJKq/F.nH62OhCevrCqs4skby2bC4IO6VPJITlc7Sh.NZa"',
    'c_c':r'a153f80493f411e3801452540a3121f7',
    '_ga':r'GA1.2.1063404131.1384259893',
    'zata':r'zhihu.com.021715f934634a988abbd3f1f7f31f37.470330',
    'q_c1':r'59c45c60a48d4a5f9a12a52028a9aee7|1400081868000|1400081868000',
    '_xsrf':r'2a7cf7208bf24dbda3f70d953e948135',
    'q_c0':r'"NmE0NzBjZTdmZGI4Yzg3ZWE0NjhkNjkwZGNiZTNiN2F8V2FhRTQ1QklrRjNjNGhMdQ==|1400082425|a801fc83ab07cb92236a75c87de58dcf3fa15cff"',
    '__utma':r'51854390.1063404131.1384259893.1400518549.1400522270.5',
    '__utmb':r'51854390.4.10.1400522270',
    '__utmc':r'51854390',
    '__utmz':r'51854390.1400513283.3.3.utmcsr=zhihu.com|utmccn=(referral)|utmcmd=referral|utmcct=/people/hallson',
    '__utmv':r'51854390.100-1|2=registration_date=20121016=1^3=entry_date=20121016=1'
}
~~~

这两个参数你都可以通过浏览器的一些开发工具查看到，特别是 COOKIES 中的信息。

# 通过账号登陆

使用账户和密码进行登陆代码如下：

~~~python
# -*- coding:utf-8 -*-
from scrapy.selector import Selector
from scrapy.contrib.linkextractors.sgml import SgmlLinkExtractor
from scrapy.contrib.spiders import CrawlSpider, Rule
from scrapy.http import Request,FormRequest

import sys

reload(sys)
sys.setdefaultencoding('utf-8')

host='http://www.zhihu.com'

class ZhihuUserSpider(CrawlSpider):
    name = 'zhihu_user'
    allowed_domains = ['zhihu.com']
    start_urls = ["http://www.zhihu.com/lookup/people",]

    #使用rule时候，不要定义parse方法
    rules = (
        Rule(SgmlLinkExtractor(allow=("/lookup/class/[^/]+/?$", )), follow=True,callback='parse_item'),
        Rule(SgmlLinkExtractor(allow=("/lookup/class/$", )), follow=True,callback='parse_item'),
        Rule(SgmlLinkExtractor(allow=("/lookup/people", )),  callback='parse_item'),
   )

    def __init__(self,  *a,  **kwargs):
        super(ZhihuLoginSpider, self).__init__(*a, **kwargs)

    def start_requests(self):
        return [FormRequest(
            "http://www.zhihu.com/login",
            formdata = {'email':'XXXXXX',
                        'password':'XXXXXX'
            },
            callback = self.after_login
        )]

    def after_login(self, response):
        for url in self.start_urls:
            yield self.make_requests_from_url(url)

    def parse_item(self, response):
        selector = Selector(response)
        for link in selector.xpath('//div[@id="suggest-list-wrap"]/ul/li/div/a/@href').extract():
            #link  ===> /people/javachen
            yield Request(host+link+"/about", callback=self.parse_user)

    def parse_user(self, response):
        selector = Selector(response)
        user = ZhihuUserItem()
        user['_id']=user['username']=response.url.split('/')[-2]
        user['url']= response.url
        user['nickname'] = ''.join(selector.xpath("//div[@class='title-section ellipsis']/a[@class='name']/text()").extract())
        user['location'] = ''.join(selector.xpath("//span[@class='location item']/@title").extract())
        user['industry'] = ''.join(selector.xpath("//span[@class='business item']/@title").extract())
        user['sex'] = ''.join(selector.xpath('//div[@class="item editable-group"]/span/span[@class="item"]/i/@class').extract()).replace("zg-icon gender ","")
        user['description'] = ''.join(selector.xpath("//span[@class='description unfold-item']/span/text()").extract()).strip().replace("\n",'')
        user['view_num'] = ''.join(selector.xpath("//span[@class='zg-gray-normal']/strong/text()").extract())
        user['update_time'] = str(datetime.now())
        #抓取用户信息，此处省略代码
~~~

该代码逻辑如下：

- 重写 `start_requests` 方法，通过设置 FormRequest 的 formdata 参数，这里是 email 和 password，然后提交请求到 `http://www.zhihu.com/login`进行登陆，如果登陆成功之后，调用 `after_login` 回调方法。
- 在 `after_login` 方法中，一个个访问 `start_urls` 中的 url
- rules 中定义了一些正则匹配的 url 所对应的回调函数

在 `parse_user` 方法里，你可以通过 xpath 获取到用户的相关信息，也可以去获取关注和粉丝列表的数据。

例如，先获取到用户的关注数 `followee_num`，就可以通过下面一段代码去获取该用户所有的关注列表。代码如下

~~~python
_xsrf = ''.join(selector.xpath('//input[@name="_xsrf"]/@value').extract())
hash_id = ''.join(selector.xpath('//div[@class="zm-profile-header-op-btns clearfix"]/button/@data-id').extract())

num = int(followee_num) if followee_num else 0
page_num = num/20
page_num += 1 if num%20 else 0
for i in xrange(page_num):
    params = json.dumps({"hash_id":hash_id,"order_by":"created","offset":i*20})
    payload = {"method":"next", "params": params, "_xsrf":_xsrf}
    yield Request("http://www.zhihu.com/node/ProfileFolloweesListV2?"+urlencode(payload), callback=self.parse_follow_url)
~~~

然后，你需要增加一个处理关注列表的回调方法 `parse_follow_url`，这部分代码如下：

~~~python
def parse_follow_url(self, response):
        selector = Selector(response)

        for link in selector.xpath('//div[@class="zm-list-content-medium"]/h2/a/@href').extract():
            #link  ===> http://www.zhihu.com/people/peng-leslie-97
            username_tmp = link.split('/')[-1]
            if username_tmp in self.user_names:
                print 'GET:' + '%s' % username_tmp
                continue

            yield Request(link+"/about", callback=self.parse_user)
~~~

获取粉丝列表的代码和上面代码类似。

有了用户数据之后，你可以再编写一个爬虫根据用户去爬取问题和答案了，这部分代码略去，详细内容请参考 <https://github.com/javachen/scrapy-zhihu-github>。其中，还有抓取 github 用户等的相关代码。

# 其他一些技巧

在使用 xpath 过程中，你可以下载浏览器插件 [XPath Helper](https://chrome.google.com/webstore/detail/hgimnogjllphhhkhlmebbmlgjoejdpjl)来快速定位元素并获取到 xpath 表达式，关于该插件用法，请自行 google 之。

由于隐私设置的缘故，有些用户可能没有显示一些数据，故针对某些用户 xpath 表达式可能会抛出一些异常，如下面代码获取用户的名称：

~~~python
user['nickname'] = selector.xpath("//div[@class='title-section ellipsis']/a[@class='name']/text()").extract()[0]
~~~

你可以将上面代码修改如下，以避免出现一个异常：

~~~python
user['nickname'] = ''.join(selector.xpath("//div[@class='title-section ellipsis']/a[@class='name']/text()").extract())
~~~
