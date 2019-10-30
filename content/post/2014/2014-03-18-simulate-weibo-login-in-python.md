---
layout: post
title: Python模拟新浪微博登录
date: 2014-03-18T08:00:00+08:00
description: Python模拟新浪微博登录
categories: [ python ]
tags: [python]
---

看到一篇[Python模拟新浪微博登录](http://qinxuye.me/article/simulate-weibo-login-in-python/)的文章，想熟悉一下其中实现方式，并且顺便掌握python相关知识点。


# 代码

下面的代码是来自上面这篇文章，并稍作修改添加了一些注释。

~~~python
# -*- coding: utf-8 -*

import urllib2
import urllib
import cookielib
 
import lxml.html as HTML
 
class Fetcher(object):
    def __init__(self, username=None, pwd=None, cookie_filename=None):
		#获取一个保存cookie的对象
        self.cj = cookielib.LWPCookieJar()
        if cookie_filename is not None:
            self.cj.load(cookie_filename)
		#将一个保存cookie对象，和一个HTTP的cookie的处理器绑定
        self.cookie_processor = urllib2.HTTPCookieProcessor(self.cj)
		#创建一个opener，将保存了cookie的http处理器，还有设置一个handler用于处理http的URL的打开
        self.opener = urllib2.build_opener(self.cookie_processor, urllib2.HTTPHandler)
		#将包含了cookie、http处理器、http的handler的资源和urllib2对象绑定在一起
        urllib2.install_opener(self.opener)
         
        self.username = username
        self.pwd = pwd
        self.headers = {'User-Agent':'Mozilla/5.0 (Windows NT 6.1; rv:14.0) Gecko/20100101 Firefox/14.0.1',
                        'Referer':'','Content-Type':'application/x-www-form-urlencoded'}
     
    def get_rand(self, url):
        headers = {'User-Agent':'Mozilla/5.0 (Windows;U;Windows NT 5.1;zh-CN;rv:1.9.2.9)Gecko/20100824 Firefox/3.6.9',
                   'Referer':''}
        req = urllib2.Request(url ,"", headers)
        login_page = urllib2.urlopen(req).read()
        rand = HTML.fromstring(login_page).xpath("//form/@action")[0]
        passwd = HTML.fromstring(login_page).xpath("//input[@type='password']/@name")[0]
        vk = HTML.fromstring(login_page).xpath("//input[@name='vk']/@value")[0]
        return rand, passwd, vk
     
    def login(self, username=None, pwd=None, cookie_filename=None):
        if self.username is None or self.pwd is None:
            self.username = username
            self.pwd = pwd
        assert self.username is not None and self.pwd is not None
         
        url = 'http://3g.sina.com.cn/prog/wapsite/sso/login.php?ns=1&revalid=2&backURL=http%3A%2F%2Fweibo.cn%2F&backTitle=%D0%C2%C0%CB%CE%A2%B2%A9&vt='
		# 获取随机数rand、password的name和vk
        rand, passwd, vk = self.get_rand(url)
        data = urllib.urlencode({'mobile': self.username,
                                 passwd: self.pwd,
                                 'remember': 'on',
                                 'backURL': 'http://weibo.cn/',
                                 'backTitle': '新浪微博',
                                 'vk': vk,
                                 'submit': '登录',
                                 'encoding': 'utf-8'})
        url = 'http://3g.sina.com.cn/prog/wapsite/sso/' + rand
		
		# 模拟提交登陆
        page =self.fetch(url,data)
        link = HTML.fromstring(page).xpath("//a/@href")[0]
        if not link.startswith('http://'): link = 'http://weibo.cn/%s' % link

		# 手动跳转到微薄页面
        self.fetch(link,"")
		
		# 保存cookie
        if cookie_filename is not None:
            self.cj.save(filename=cookie_filename)
        elif self.cj.filename is not None:
            self.cj.save()
        print 'login success!',data
         
    def fetch(self, url,data):
        print 'fetch url: ', url
        req = urllib2.Request(url,data, headers=self.headers)
        return urllib2.urlopen(req).read()

# 开始运行
fet=Fetcher();
fet.login("huaiyu2006","XXXXXX")
~~~

以上代码引入了一些python的模块，然后创建了一个class封装了login方法。

以上代码的登录逻辑：

- 1、进入到登陆页面，获取一些关键参数，包括随机数rand、password的name和vk。
- 2、模拟提交登陆，登陆之后跳到微薄页面。
- 3、手动跳转到微薄页面。

**总结：**

以上代码是模拟手机版微博的登陆，如果你想**模拟登陆网页版的微博**，你可以参考下面两个项目中的代码：

- [cola](https://github.com/chineking/cola/blob/master/contrib/weibo/login.py)
- [WeiboMsgBackupGUI](https://github.com/CnPaMeng/WeiboMsgBackupGUI/blob/master/sina/loginsinacom.py)

# Python模块
## Python urllib模块

Python urllib模块提供了一个从指定的URL地址获取网页数据，然后对其进行分析处理，获取想要的数据。

1、urllib模块提供的urlopen函数

~~~python
➜  py-test  python
Python 2.7.5+ (default, Feb 27 2014, 19:37:08) 
[GCC 4.8.1] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> import urllib
>>> help(urllib.urlopen)

Help on function urlopen in module urllib:

urlopen(url, data=None, proxies=None)
    Create a file-like object for the specified URL to read from.
(END)
~~~
urllib.urlopen创建一个类文件对象为指定的url来读取：

- 参数url表示远程数据的路径，一般是http或者ftp路径。
- 参数data表示以get或者post方式提交到url的数据。
- 参数proxies表示用于代理的设置。

示例：

~~~python
import urllib

print urllib.urlopen('http://www.baidu.com').read()
~~~

urlopen返回一个类文件对象，它提供了如下方法：

- 1）read() , readline() , readlines()，fileno()和close()： 这些方法的使用与文件对象完全一样。
- 2）info()：返回一个httplib.HTTPMessage 对象，表示远程服务器返回的头信息。
- 3）getcode()：返回Http状态码，如果是http请求，200表示请求成功完成;404表示网址未找到。
- 4）geturl()：返回请求的url地址。

2.urllibe模块提供的urlretrieve函数。

urlretrieve方法直接将远程数据下载到本地。

- 参数finename指定了保存本地路径（如果参数未指定，urllib会生成一个临时文件保存数据。）
- 参数reporthook是一个回调函数，当连接上服务器、以及相应的数据块传输完毕时会触发该回调，我们可以利用这个回调函数来显示当前的下载进度。
- 参数data指post到服务器的数据，该方法返回一个包含两个元素的(filename, headers)元组，filename表示保存到本地的路径，header表示服务器的响应头。

**示例：**urlretrieve方法下载文件实例，可以显示下载进度。

~~~python
#!/usr/bin/python
#encoding:utf-8
import urllib
import os
def Schedule(a,b,c):
    '''''
    a:已经下载的数据块
    b:数据块的大小
    c:远程文件的大小
   '''
    per = 100.0 * a * b / c
    if per > 100 :
        per = 100
    print '%.2f%%' % per
url = 'http://www.python.org/ftp/python/2.7.5/Python-2.7.5.tar.bz2'
#local = url.split('/')[-1]
local = os.path.join('/data/software','Python-2.7.5.tar.bz2')
urllib.urlretrieve(url,local,Schedule)
~~~

3.辅助方法

urllib中还提供了一些辅助方法，用于对url进行编码、解码。

- urllib.quote(string[, safe])：对字符串进行编码。参数safe指定了不需要编码的字符;
- urllib.unquote(string) ：对字符串进行解码；
- urllib.quote_plus(string [ , safe ] ) ：与urllib.quote类似，但这个方法用'+'来替换' '，而quote用'%20'来代替' '
- urllib.unquote_plus(string ) ：对字符串进行解码；
- urllib.urlencode(query[, doseq])：将dict或者包含两个元素的元组列表转换成url参数。例如 字典{'name': 'dark-bull', 'age': 200}将被转换为"name=dark-bull&age=200"
- urllib.pathname2url(path)：将本地路径转换成url路径；
- urllib.url2pathname(path)：将url路径转换成本地路径；

通过上面的练习可以知道，urlopen可以轻松获取远端html页面信息，然后通过python正则对所需要的数据进行分析，匹配出想要用的数据，在利用urlretrieve将数据下载到本地。对于访问受限或者对连接数有限制的远程url地址可以采用proxies（代理的方式）连接，如果远程数据量过大，单线程下载太慢的话可以采用多线程下载，这个就是传说中的爬虫。

## Python urllib2模块

客户端与服务器端通过request与response来沟通，客户端先向服务端发送request，然后接收服务端返回的response

urllib2提供了request的类，可以让用户在发送请求前先构造一个request的对象，然后通过urllib2.urlopen方法来发送请求

更详细的说明请参考：[http://zhuoqiang.me/python-urllib2-usage.html](http://zhuoqiang.me/python-urllib2-usage.html)

## Python  cookielib模块

cookielib模块的主要作用是提供可存储cookie的对象，以便于与urllib2模块配合使用来访问Internet资源。例如可以利用本模块的CookieJar类的对象来捕获cookie并在后续连接请求时重新发送。coiokielib模块用到的对象主要有下面几个：CookieJar、FileCookieJar、MozillaCookieJar、LWPCookieJar。

- CookieJar管理HTTP cookie值、存储HTTP请求生成的cookie、向传出的HTTP请求添加cookie的对象。整个cookie都存储在内存中，对CookieJar实例进行垃圾回收后cookie也将丢失。
- FileCookieJar检索cookie信息并将cookie存储到文件中。filename是存储cookie的文件名。delayload为True时支持延迟访问访问文件，即只有在需要时才读取文件或在文件中存储数据。
- MozillaCookieJar创建与Mozilla浏览器cookies.txt兼容的FileCookieJar实例。
- LWPCookieJar创建与libwww-perl的Set-Cookie3文件格式兼容的FileCookieJar实例。

cookielib模块一般与urllib2模块配合使用，主要用在urllib2.build_oper()函数中作为urllib2.HTTPCookieProcessor()的参数。

使用方法如下面登录人人网的代码:

~~~python
#! /usr/bin/env python
#coding=utf-8
import urllib2
import urllib
import cookielib
data={"email":"用户名","password":"密码"}  #登陆用户名和密码
post_data=urllib.urlencode(data)
cj=cookielib.CookieJar()
opener=urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
headers ={"User-agent":"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1"}
req=urllib2.Request("http://www.renren.com/PLogin.do",post_data,headers)
content=opener.open(req)
print content2.read().decode("utf-8").encode("gbk")
~~~

## Python lxml模块

具体用法可以参考 [使用由 Python 编写的 lxml 实现高性能 XML 解析](http://www.ibm.com/developerworks/cn/xml/x-hiperfparse/)

上面python脚本主要是使用了lxml的xpath语法进行快速查找。
