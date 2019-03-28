---
layout: post
title: 我的jekyll配置和修改
description: 主要记录使用jekyll搭建博客时的一些配置和修改。
category: devops
tags: [jekyll]
---


主要记录使用jekyll搭建博客时的一些配置和修改。

注意：
>使用时请删除{和%以及{和{之间的空格。

# 预览文章

	source ~/.bash_profile
	jekyll server

# 添加about me 边栏

参考[the5fire的技术博客](http://www.the5fire.com/)在index.html页面加入如下代码：

~~~
<section>
<h4>About me</h4>
<div>
 一个Java方案架构师，主要从事hadoop相关工作。<a href="/about.html">更多信息</a> 
<br/>
<br/>
<strong><font color="red"><a href="/atom.xml" target="_blank">订阅本站</a></font></strong>
<br/><br/>
联系博主：javachen.june[a]gmail.com
</div>
</section>
~~~

# 添加about页面

在根目录创建about.md并修改，注意：文件开头几行内容如下

	title: About
	layout: page
	group: navigation

# 设置固定链接

在 _config.yml 里，找到 permalink，设置如下：

	permalink: /:categories/:year/:month/:day/:title 

# 修改，markdown实现为redcarpet

首先通过gem安装redcarpet，然后修改_config.yml：

~~~
redcarpet:
  extensions: ["no_intra_emphasis", "fenced_code_blocks", "autolink", "tables", "strikethrough", "superscript", "with_toc_data", "highlight", "prettify"]
~~~

# 首页添加最近文章

在index.html页面

~~~
<section>
<h4>Recent Posts</h4>
<ul id="recent_posts">{ % for rpost in site.posts limit: 15 %}
<li class="post">
<a href="{{ BASE_PATH }}{{ rpost.url }}">{{ rpost.title }}</a>
</li>{ % endfor %}
</ul>
</section>
~~~

# 首页为每篇文章添加分类、标签、发表日期以及评论连接

在index.html页面找到`<h3><a href="{ { BASE_PATH }}{ { post.url }}">{ { post.title }}</a></h3>`，在下面添加：


~~~
 <div class="c9">
	Categories：
		{ %for cg in post.categories % }
		<a href="/categories.html#{{cg}}-ref">{{cg}}</a>
		{ %if forloop.index < forloop.length % }
		,
		{ %endif%}
		{ %endfor%}
	|
	Tags：
		{ %for cg in post.tags %}
		<a href="/tags.html#{{cg}}-ref">{{cg}}</a>
		{ %if forloop.index < forloop.length %}
		,
		{ %endif%}
		{ %endfor%}
	|
	Time：<time date="{ { post.date|date: '%Y-%m-%d' }}">{{ post.date|date: "%Y-%m-%d"}}</time>
	<a href='{{post.url}}#comments' title='分享文章、查看评论' style="float:right;margin-right:.5em;">Comments</a>
</div>
~~~

# 修改h1、h2等标题字体

主要是参考[图灵社区](http://www.ituring.com.cn/)的css，在`assets/themes/twitter/css/style.css`中添加如下css代码：

	h1,h2,h3,h4,h5,h6{margin:18px 0 9px;font-family:inherit;font-weight:normal;color:inherit;text-rendering:optimizelegibility;}h1 small,h2 small,h3 small,h4 small,h5 small,h6 small{font-weight:normal;color:#999999;}
	h1{font-size:30px;line-height:36px;}h1 small{font-size:18px;}
	h2{font-size:24px;line-height:36px;}h2 small{font-size:18px;}
	h3{font-size:18px;line-height:27px;}h3 small{font-size:14px;}
	h4,h5,h6{line-height:18px;}
	h4{font-size:14px;}h4 small{font-size:12px;}
	h5{font-size:12px;}
	h6{font-size:11px;color:#999999;text-transform:uppercase;}

# 添加返回顶部功能

同样是参考了[图灵社区](http://www.ituring.com.cn/)的css和网上的一篇js实现。在`assets/themes/twitter/css/style.css`：

	.backToTop {
	    display: block;
	    width: 40px;
	    height: 32px;
	    font-size: 26px;
	    line-height: 32px;
	    font-family: verdana, arial;
	    padding: 5px 0;
	    background-color: #000;
	    color: #fff;
	    text-align: center;
	    position: fixed;
	    _position: absolute;
	    right: 10px;
	    bottom: 100px;
	    _bottom: "auto";
	    cursor: pointer;
	    opacity: .6;
	    filter: Alpha(opacity=60);
	}

在`assets/themes/twitter/js`添加jquery和main.js，main.js内容如下：

	jQuery.noConflict();
	jQuery(document).ready(function(){
		var backToTopTxt = "▲", backToTopEle = jQuery('<div class="backToTop"></div>').appendTo(jQuery("body")).text(backToTopTxt).attr("title","Back top top").click(function() {
		    jQuery("html, body").animate({ scrollTop: 0 }, 120);
		}), backToTopFun = function() {
			var st = jQuery(document).scrollTop(), winh = jQuery(window).height();
			(st > 200)? backToTopEle.show(): backToTopEle.hide();    
			//IE6下的定位
			if (!window.XMLHttpRequest) {
			    backToTopEle.css("top", st + winh - 166); 
			}
		};

		backToTopEle.hide(); 
	    	jQuery(window).bind("scroll", backToTopFun);
		jQuery('div.main a,div.pic a').attr('target', '_blank');
	});


# 添加文章版权说明

在`_includes/themes/twitter/post.html`中文章主体下面添加如下代码：

	<div class="well">
	  本文基于<a target="_blank" title="Creative Commons Attribution 2.5 China Mainland License" href="http://creativecommons.org/licenses/by/2.5/cn/">署名2.5中国大陆许可协议</a>发布，转载请注明：<br/>
	    作者：<a href="{{site.url}}/about.html">{{ site.author.name }}</a><br/>
	    链接：<a href="{{page.url}}">{{site.url}}{{page.url}}</a><br/>
	    欢迎转载、演绎或用于商业目的，但是必须保留本文署名和文章链接。如您有任何疑问或者授权方面的协商，请邮件联系我</a>。
	</div>

# 添加read more功能

参考[Jekyll - Read More without plugin](http://truongtx.me/2013/05/01/jekyll-read-more-feature-without-any-plugin/)，在index.html找到 {{ post.content }}，然后修改为：

	{ % if post.content contains "<!-- more -->" %}
	{ { post.content | split:"<!-- more -->" | first % }}
	<h4><a href='{ {post.url}}' title='Read more...'>Read more...</a></h4>
	{ % else %}
	{ { post.content}}
	{ % endif %}

然后，在文章中添加`<!-- more -->`即可。

# 添加搜索栏

参考[Jekyll Bootstrap - Create Simple Search box](http://truongtx.me/2012/12/28/jekyll-create-simple-search-box/)，在`_includes/themes/twitter/default.html`导航菜单下面添加：

	<form class="navbar-search pull-left" id="search-form">
	  <input type="text" id="google-search" class="search-query" placeholder="Search">
	</form

添加js：

	jQuery("#search-form").submit(function(){
		var query = document.getElementById("google-search").value;
		window.open("http://google.com/search?q=" + query+ "%20site:" + "http://blog.javachen.com");
	});

# 添加文章访问量功能

在`_includes`目录下的head.html中添加

	<script async src="//busuanzi.ibruce.info/busuanzi/2.3/busuanzi.pure.mini.js"></script>

在`_includes`目录下的footer.html中添加如下代码，这样文章底部有了统计访问量功能

	<span id="busuanzi_container_site_pv">本站总访问量：<span id="busuanzi_value_site_pv"></span>次</span>


在`_layouts`目录下的post.html中添加如下代码，这样每篇文章有了统计访问量功能

	<span id="busuanzi_container_page_pv"> | 访问量：<span id="busuanzi_value_page_pv"></span> 次</span>

# 其他

- 添加404页面
- 修改博客主体为宽屏模式

# TODO

- 添加语法高亮，参考[Jekyll - Syntax highlighting](http://truongtx.me/2012/12/28/jekyll-bootstrap-syntax-highlighting/)
