---
layout: post
title: 使用Octopress将博客从wordpress迁移到GitHub
category: web
tags: [github]

---


# Step1 - 在本机安装Octopress

首先，必须先在本机安装配置[Git](http://git-scm.com/)和[Ruby](https://rvm.beginrescueend.com/rvm/install/),Octopress需要Ruby版本至少为1.9.2。你可以使用[RVM](http://rvm.beginrescueend.com/)或[rbenv](https://github.com/sstephenson/rbenv)安装ruby，安装方法见Octopress官方文档：<http://octopress.org/docs/setup/>

我使用rvm安装：
    rvm install 1.9.2 && rvm use 1.9.2
安装完之后可以查看ruby版本：
    ruby --version
结果为：
    ruby 1.9.2p320 (2012-04-20 revision 35421) [x86_64-linux]

然后需要从github下载Octopress：
    git clone git://github.com/imathis/octopress.git octopress

因为我fork了Octopress，并在配置文件上做了一些修改，故我从我的仓库地址下载Octopress，命令如下：
    git clone git@github.com:javachen/octopress.git
运行上面的代码后，你会看到：
	Cloning into 'octopress'...
	remote: Counting objects: 6579, done.
	remote: Compressing objects: 100% (2361/2361), done.
	remote: Total 6579 (delta 3773), reused 6193 (delta 3610)
	Receiving objects: 100% (6579/6579), 1.34 MiB | 35 KiB/s, done.
	Resolving deltas: 100% (3773/3773), done.

接下来进入octopress：
	cd octopress

接下来安装依赖：
	gem install bundler
	rbenv rehash    # If you use rbenv, rehash to be able to run the bundle command
	bundle install

安装Octopress默认的主题：
	rake install

你也可以安装自定义的主题，blog为主题名称：
	rake install['blog']

至此，Octopress所需的环境已经搭建成功。

# Step2 - 连接GitHub Pages
首先，你得有一个GitHub的帐号，并且已经创建了一个新的Repository。如果你准备用自己的域名的话，Repository的名称可以随便取，不过正常人在正常情况下，一般都是以域名取名的。如果你没有自己的域名，GitHub是提供二级域名使用的，但是你得把Repository取名为`你的帐号.github.com`，并且，部署的时候会占用你的master分支。

*Tips：*
如果用自己的一级域名，记得把source/CNAME文件内的域名改成你的一级域名，还有在dns管理中把域名的A Record指向IP：207.97.227.245；
如果用自己的二级域名，记得把source/CNAME文件内的域名改成你的二级域名，还有在dns管理中把域名的CNAME Record指向网址：charlie.github.com；
	echo 'your-domain.com' >> source/CNAME
如果用GitHub提供的二级域名，记得把source/CNAME删掉。

完成上述准备工作后，运行：
	rake setup_github_pages
它会提示你输入有读写权限的Repository Url，这个在GitHub上可以找到。Url形如：https://github.com/javachen/javachen.github.com.git，javachen.github.com是我的Repository的名称。

# Step3 - 配置你的博客
需要配置博客url、名称、作者、rss等信息。
	url: http://javachen.github.com
	title: JavaChen on Java
	subtitle: Just some random thoughts about technology,Java and life.
	author: javachen
	simple_search: http://google.com/search
	description:

	date_format: "%Y年%m月%d日"

	subscribe_rss: /atom.xml
	subscribe_email:
	email:

	# 如果你使用的是一个子目录，如http://site.com/project，则设置为'root: /project'
	root: /
	# 文章标题格式
	permalink: /:year/:month/:day/:title/
	source: source
	destination: public
	plugins: plugins
	code_dir: downloads/code
	# 分类存放路径
	category_dir: categories
	markdown: rdiscount
	pygments: false # default python pygments have been replaced by pygments.rb

# Step4 - 部署

先把整个项目静态化，然后再部署到GitHub：
	rake generate
	rake deploy
当你看到“Github Pages deploy complete”后，就表示你大功已成。Enjoy!

*Tips：*
Octopress提供的所有rake方法，可以运行`rake -T`查看。
如果在执行上述命令中ruby报错，则需要一一修复错误，这一步是没有接触过ruby的人比较苦恼的。

# Step5 - 从Wordpress迁移到Octopress
## 备份
### 备份评论内容
Octopress由于是纯静态，所以没有办法存储用户评论了，我们可以使用DISQUS提供的“云评论”服务。首先安装DISQUS的WordPress插件，在插件设置中我们可以将现有的评论内容导入到DISQUS中。DISQUS处理导入数据的时间比较长，往往需要24小时甚至以上的时间。

### 备份文章内容
在WordPress后台我们可以将整站数据备份成一个.xml文件下载下来。同时，我原先文章中的图片都是直接在Wordpress后台上传的，所以要把服务器上`wp-content/uploads`下的所有文件备份下来。

## 迁移
### 迁移文章
jekyll本身提供了一个从WordPress迁移文章的工具，不过对中文实在是不太友好。这里我使用了YORKXIN的修改版本。将上面备份的wordpress.xml放到Octopress根目录，把脚本放到新建的utils目录中，然后运行：
	ruby -r "./utils/wordpressdotcom.rb" -e "Jekyll::WordpressDotCom.process"
于是转换好的文章都放进source目录了。

### 迁移URL
迁移URL，便是要保证以前的文章链接能够自动重定向到新的链接上。这样既能保证搜索引擎的索引不受影响，也是一项对读者负责任的行为是吧。不过这是一项挺麻烦的事情。

幸好我当初建立WordPress的时候就留下了后路。原先网站的链接是这样的：
	http://XXXXXXXXX.com/[year]/[month]/[the-long-long-title].html
	http://XXXXXXXXX.com/page/xx/
	http://XXXXXXXXX.com/category/[category-name]/
这样的格式是比较容易迁移的。如果原先的文章URL是带有数字ID的话，只能说声抱歉了。到_config.yml里面设置一下新站点的文章链接格式，跟原先的格式保持一致：
	permalink: /:year/:month/:title/
	category_dir: category
	pagination_dir:  # 留空

### 迁移评论
既然做好了301，那么迁移评论就显得非常简单了。登录DISQUS后台，进入站点管理后台的“Migrate Threads”栏目，那里有一个“Redirect Crawler”的功能，便是自动跟随301重定向，将评论指向新的网址。点一下那个按钮就大功告成。

### 迁移图片
可以参考[使用独立图床子域名](http://log4d.com/2012/05/image-host/)

# Step6 - 再次部署
	rake generate
	rake deploy


# 参考文章

- Octopress Setup： http://octopress.org/docs/setup/
- Octopress Deploying：http://octopress.org/docs/deploying/
- Blog = GitHub + Octopress：http://mrzhang.me/blog/blog-equals-github-plus-octopress.html
- 从Wordpress迁移到Octopress：http://blog.dayanjia.com/2012/04/migration-to-octopress-from-wordpress/
- 使用独立图床子域名：http://log4d.com/2012/05/image-host/ http://log4d.com/2012/05/image-host/

