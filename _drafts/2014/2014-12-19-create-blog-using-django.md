---
layout: post

title: 使用Django创建Blog

category: python

tags: [ python,django]

description: 本文使用 django、bootstrap3 创建一个支持 markdown 语法的简单 blog，这是一个很好的学习 django 的例子，基本上涉及了 django 的方方面面。

published: true

---

本文参考 [Part 1: Creating a blog system using django + markdown](http://www.yaconiello.com/blog/part-1-creating-blog-system-using-django-markdown/) 使用 django、bootstrap3 创建一个支持 markdown 语法的简单 blog，这是一个很好的学习 django 的例子，基本上涉及了 django 的方方面面，本文中相关的源码见 [github](https://github.com/javachen/django_blog)。

相对于原文做了一些修改：

 - 基于 django1.7，修复了不兼容的配置
 - 前端使用 bootstrap3，并修改了页面的一些内容
 - 【TODO】代码中关键的地方添加注释，帮助理解

# 1. 安装依赖

~~~bash
pip install markdown pygments django-pagedown
~~~

**说明：**我使用的 django 版本为 `1.7`。

# 2. 创建项目

创建项目 django_blog 和 blog app：

~~~
django-admin.py startproject django_blog
python manage.py startapp blog
~~~

### 修改 settings.py

设置 SITE_ID 并修改时区等：

~~~python
SITE_ID = 1

LANGUAGE_CODE = 'zh_CN'

TIME_ZONE = 'Asia/Shanghai'

USE_TZ = True 
~~~

添加 app:

~~~python
INSTALLED_APPS = (
    'django.contrib.admin',
    'django.contrib.sites',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'pagedown', # App for adding markdown preview to the django admin
    'blog', # Blog Module
    'django.contrib.comments', # comments for the blog

)
~~~

设置静态文件目录和模板目录：

~~~python
# Additional locations of static files
STATICFILES_DIRS = (
    os.path.join(BASE_DIR,'static'),
    # Put strings here, like "/home/html/static" or "C:/www/django/static".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
)

# List of finder classes that know how to find static files in
# various locations.
STATICFILES_FINDERS = (
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
#    'django.contrib.staticfiles.finders.DefaultStorageFinder',
)

TEMPLATE_DIRS = (
    os.path.join(BASE_DIR,'templates'),
)
# List of callables that know how to import templates from various sources.
TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.Loader',
    'django.template.loaders.app_directories.Loader',
)
~~~

# 3. 创建模型

在 blog/models.py 中创建模型 Category 和 Article：

~~~python
from django.db import models
from django.utils.translation import ugettext as _
from markdown import markdown

class Category(models.Model) :
    """Category Model"""
    title = models.CharField(
        verbose_name = _(u'Title'),
        help_text = _(u' '),
        max_length = 255
    )
    slug = models.SlugField(
        verbose_name = _(u'Slug'),
        help_text = _(u'Uri identifier.'),
        max_length = 255,
        unique = True
    )

    class Meta:
        app_label = _(u'blog')
        verbose_name = _(u"Category")
        verbose_name_plural = _(u"Categories")
        ordering = ['title',]

    def __unicode__(self):
        return "%s" % (self.title,)

class Article(models.Model) :
    """Article Model"""
    title = models.CharField(
        verbose_name = _(u'Title'),
        help_text = _(u' '),
        max_length = 255
    )
    slug = models.SlugField(
        verbose_name = _(u'Slug'),
        help_text = _(u'Uri identifier.'),
        max_length = 255,
        unique = True
    )
    content_markdown = models.TextField(
        verbose_name = _(u'Content (Markdown)'),
        help_text = _(u' '),
    )
    content_markup = models.TextField(
        verbose_name = _(u'Content (Markup)'),
        help_text = _(u' '),
    )
    categories = models.ManyToManyField(
        Category,
        verbose_name = _(u'Categories'),
        help_text = _(u' '),
        null = True,
        blank = True
    )
    date_publish = models.DateField(
        verbose_name = _(u'Publish Date'),
        help_text = _(u' ')
    )

    class Meta:
        app_label = _(u'blog')
        verbose_name = _(u"Article")
        verbose_name_plural = _(u"Articles")
        ordering = ['-date_publish']

    def save(self):
        self.content_markup = markdown(self.content_markdown, ['codehilite'])
        super(Article, self).save()

    def __unicode__(self):
        return "%s" % (self.title,)
~~~

将模型加入到 django admin，修改 blog/admin.py:

~~~python
from django.contrib import admin
from django import forms
from pagedown.widgets import AdminPagedownWidget
from models import Category, Article

class CategoryAdmin(admin.ModelAdmin):
    prepopulated_fields = {'slug': ('title',)}
    list_display = ('title', )
    search_fields = ('title', )
    fieldsets = (
        (
            None,
            {
                'fields': ('title', 'slug',)
            }
        ),
    )

class ArticleForm(forms.ModelForm):
    class Meta:
        model = Article
        widgets = {
            'content_markdown' : AdminPagedownWidget(),
        }
        exclude = ['content_markup',]

class ArticleAdmin(admin.ModelAdmin):
    form = ArticleForm
    prepopulated_fields = {'slug': ('title',)}
    list_display = ('title', 'date_publish')
    search_fields = ('title', 'content_markdown',)
    list_filter = ('categories',)
    fieldsets = (
        (
            None,
            {
                'fields': ('title', 'slug', 'content_markdown', 'categories', 'date_publish',)
            }
        ),
    )

admin.site.register(Category, CategoryAdmin)
admin.site.register(Article, ArticleAdmin)
~~~

# 4. 创建 url 路由

修改 django_blog/urls.py：

~~~python
from django.conf.urls import patterns, include, url
from django.contrib import admin
from blog.views import index

urlpatterns = patterns('',
    url(r'^admin/', include(admin.site.urls)),
    url(r'^$', index, name='home'),

    url('^blog/archive/(?P<year>[\d]+)/(?P<month>[\d]+)/$', 'blog.views.date_archive', name="blog_date_archive"),
    url('^blog/archive/(?P<slug>[-\w]+)/$', 'blog.views.category_archive', name="blog_category_archive"),
    url('^blog/(?P<slug>[-\w]+)/$', 'blog.views.single', name="blog_article_single"),
    url('^blog/$', 'blog.views.index', name="blog_article_index"),
    url(r'^comments/', include('django.contrib.comments.urls')),
)
~~~

# 5. 创建视图

创建 blog/views.py：

~~~python
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.shortcuts import render, get_object_or_404
from models import Category, Article
from django.shortcuts import render_to_response
import calendar, datetime

# Create your views here.

def index(request) :
    """The news index"""
    archive_dates = Article.objects.dates('date_publish','month', order='DESC')
    categories = Category.objects.all()

    page = request.GET.get('page')
    article_queryset = Article.objects.all()
    paginator = Paginator(article_queryset, 5)

    try:
        articles = paginator.page(page)
    except PageNotAnInteger:
        # If page is not an integer, deliver first page.
        articles = paginator.page(1)
    except EmptyPage:
        # If page is out of range (e.g. 9999), deliver last page of results.
        articles = paginator.page(paginator.num_pages)

    return render(
        request,
        "blog/article/index.html",
        {
            "articles" : articles,
            "archive_dates" : archive_dates,
            "categories" : categories
        }
    )

def single(request, slug) :
    """A single article"""
    article = get_object_or_404(Article, slug=slug)
    archive_dates = Article.objects.dates('date_publish','month', order='DESC')
    categories = Category.objects.all()
    return render(
        request,
        "blog/article/single.html",
        {
            "article" : article,
            "archive_dates" : archive_dates,
            "categories" : categories
        }
    )

def date_archive(request, year, month) :
    """The blog date archive"""
    # this archive pages dates
    year = int(year)
    month = int(month)
    month_range = calendar.monthrange(year, month)
    start = datetime.datetime(year=year, month=month,day=1)#.replace(tzinfo=utc)
    end = datetime.datetime(year=year, month=month, day=month_range[1])#.replace(tzinfo=utc)
    archive_dates = Article.objects.dates('date_publish','month', order='DESC')
    categories = Category.objects.all()

    # Pagination
    page = request.GET.get('page')
    article_queryset = Article.objects.filter(date_publish__range=(start.date(), end.date()))
    paginator = Paginator(article_queryset, 5)

    try:
        articles = paginator.page(page)
    except PageNotAnInteger:
        # If page is not an integer, deliver first page.
        articles = paginator.page(1)
    except EmptyPage:
        # If page is out of range (e.g. 9999), deliver last page of results.
        articles = paginator.page(paginator.num_pages)

    return render(
        request,
        "blog/article/date_archive.html",
        {
            "start" : start,
            "end" : end,
            "articles" : articles,
            "archive_dates" : archive_dates,
            "categories" : categories
        }
    )

def category_archive(request, slug):
    archive_dates = Article.objects.dates('date_publish','month', order='DESC')
    categories = Category.objects.all()
    category = get_object_or_404(Category, slug=slug)

    # Pagination
    page = request.GET.get('page')
    article_queryset = Article.objects.filter(categories=category)
    paginator = Paginator(article_queryset, 5)

    try:
        articles = paginator.page(page)
    except PageNotAnInteger:
        # If page is not an integer, deliver first page.
        articles = paginator.page(1)
    except EmptyPage:
        # If page is out of range (e.g. 9999), deliver last page of results.
        articles = paginator.page(paginator.num_pages)
    return render(
        request,
        "blog/article/category_archive.html",
        {
            "articles" : articles,
            "archive_dates" : archive_dates,
            "categories" : categories,
            "category" : category
        }
    )
~~~

# 6. 创建模板

创建 templates/blog/base.html：

{% highlight html %}
{% raw %}
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">

        <title>{% block title %}{% endblock %}</title>

        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        <!-- CSS -->
        <link href="http://cdn.bootcss.com/bootstrap/3.3.1/css/bootstrap.min.css" rel="stylesheet">
        <link href="http://cdn.bootcss.com/bootstrap/3.3.1/css/bootstrap-theme.min.css" rel="stylesheet">
        <link href="{{ STATIC_URL }}css/style.css" rel="stylesheet">
        <link href="{{ STATIC_URL }}css/pygments.css" rel="stylesheet">

        <!-- HTML5 shim, for IE6-8 support of HTML5 elements -->
        <!--[if lt IE 9]>
        <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
        <![endif]-->
    </head>

    <body>

        <!-- Part 1: Wrap all page content here -->
        <div id="wrap">

            <!-- Begin page content -->
            <div class="container">
                <div class="masthead">
                    <ul class="nav nav-pills pull-right">
                        <li{% if "/" == request.get_full_path %} class="active"{% endif %}><a href="/">Home</a></li>
                        <li {% if "/blog/" == request.get_full_path %} class="active"{% endif %} ><a href="{% url 'blog_article_index' %}">Blog</a></li>
                        <li {% if "/about/" == request.get_full_path %} class="active"{% endif %} ><a href="{% url 'blog_article_index' %}">About</a></li>
                    </ul>
                    <h3 class="text-muted">My Blog</h3>
                </div>
                <div class="page-header">
                    <p class="lead">Simple is beauty!</p>
                </div>
                {% block breadcrumb %}{% endblock %}
                {% block content %}{% endblock%}
            </div>

            <div id="push"></div>

        </div>

        <div id="footer">
            <div class="container">
                <p class="muted credit">©2014<span style="float:right;"><a href="/legal/">Legal</a></span></p>

            </div>
        </div>

        <!-- Le javascript
        ================================================== -->
        <!-- Placed at the end of the document so the pages load faster -->
        <script src="http://cdn.bootcss.com/jquery/1.11.1/jquery.min.js"></script>
        <script src="http://cdn.bootcss.com/bootstrap/3.3.1/js/bootstrap.min.js"></script>
    </body>
</html>
{% endraw %}
{% endhighlight %}

其他 html 文件见[源代码](https://github.com/javachen/django_blog)。

# 7. 运行项目

~~~bash
python manage.py makemigrations
python manage.py migrate
python manage.py syncdb
python manage.py runserver
~~~

打开浏览器访问后台页面 <http://localhost:8000/admin> 添加分类和文章，然后再访问前台页面 <http://localhost:8000/>。


# 8. 参考文章

- [Part 1: Creating a blog system using django + markdown](http://www.yaconiello.com/blog/part-1-creating-blog-system-using-django-markdown/)
- [Part 2: Creating a blog system using django + markdown](http://www.yaconiello.com/blog/part-2-creating-blog-system-using-django-markdown/)
- [Part 3: Creating a blog system using django + markdown](http://www.yaconiello.com/blog/part-3-creating-blog-system-using-django-markdown/)
