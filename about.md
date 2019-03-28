---
title: About
layout: page
group: navigation
comment: true
---

### Who am I

网名{{ site.author.name }}，86后，湖北武汉人，曾就职于拉手网、阿里巴巴，目前在武汉；

资深开发工程师，平时以Mac OSX为日常操作系统，主要关注Java、Hadoop、Spark、Pentaho、Python、搜索引擎等开源项目。

### Contact me

- 你可以通过以下方式找到我：{% if site.author.email %}<i class="fa fa-envelope"></i>[Email](mailto:{{ site.author.email }}){% endif %}、{% if site.author.weibo %}<i class="fa fa-weibo"></i>[Weibo](http://weibo.com/{{ site.author.weibo }}){% endif %}、{% if site.author.github %}<i class="fa fa-github"></i>[Github](https://github.com/{{ site.author.github }}){% endif %}{% if site.author.twitter %}、<i class="fa fa-twitter"></i>[Twitter](https://twitter.com/{{ site.author.twitter }}){% endif %}。

- 你可以通过下面方式订阅本博客文章：{% if site.url %}<i class="fa fa-rss"></i>[RSS](/rss.xml){% endif %}。

- 另外，我还创建了一个分享、交流大数据相关技术的QQ群：<i class="fa fa-qq"></i>142824963，欢迎大家加入。

### ChangeLog

本博客更新记录：

- 2019-03-26: 添加打赏功能，压缩静态文件，修改回到顶部功能（参考[Theme H2O](https://github.com/kaeyleo/jekyll-theme-H2O)）。
- 2019-03-22: 去掉评论系统。
- 2016-02-22: 升级到Jekyll3版本。
- 2015-06-15: 参考[Yeolar](http://www.yeolar.com)修改博客主题为现在这个样式，主要改变有：增加自适应布局、文章添加二维码、文章版权说明。
- 2015-03-03: 博客源代码托管在[Coding](https://coding.net/u/javachen)私有仓库，生成的静态页面托管在[Github](https://github.com/javachen/javachen.github.io)。
- 2014-10-31: 使用cnzz统计代码。
- 2012-06-28: 使用51la统计代码。
- 2009-05-12: 基于asp建立博客。

 {% include reward.html %}
 
{% include comments.html %}
