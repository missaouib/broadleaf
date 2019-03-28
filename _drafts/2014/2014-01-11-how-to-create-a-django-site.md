---
layout: post
title: 如何创建一个Django网站
category: python
tags: [python,django]
description: 本文官方文档演示如何创建一个简单的 django 网站，使用的 django 版本为1.7。
---

本文参考[官方文档](https://docs.djangoproject.com/en/1.7/intro/)演示如何创建一个简单的 django 网站，使用的 django 版本为1.7。

# 1. 创建项目

运行下面命令就可以创建一个 django 项目，项目名称叫 mysite ：

~~~bash
$ django-admin.py startproject mysite
~~~

创建后的项目目录如下：

~~~
mysite
├── manage.py
└── mysite
    ├── __init__.py
    ├── settings.py
    ├── urls.py
    └── wsgi.py

1 directory, 5 files
~~~

说明：

- `__init__.py` ：让 Python 把该目录当成一个开发包 (即一组模块)所需的文件。 这是一个空文件，一般你不需要修改它。
- `manage.py` ：一种命令行工具，允许你以多种方式与该 Django 项目进行交互。 键入`python manage.py help`，看一下它能做什么。 你应当不需要编辑这个文件；在这个目录下生成它纯是为了方便。
- `settings.py` ：该 Django 项目的设置或配置。
- `urls.py`：Django项目的URL路由设置。目前，它是空的。
- `wsgi.py`：WSGI web 应用服务器的配置文件。更多细节，查看 [How to deploy with WSGI](https://docs.djangoproject.com/en/1.7/howto/deployment/wsgi/)

接下来，你可以修改 settings.py 文件，例如：修改 `LANGUAGE_CODE`、设置时区 `TIME_ZONE`

~~~python
SITE_ID = 1

LANGUAGE_CODE = 'zh_CN'

TIME_ZONE = 'Asia/Shanghai'

USE_TZ = True 
~~~

上面开启了 [Time zone](https://docs.djangoproject.com/en/1.7/topics/i18n/timezones/) 特性，需要安装 pytz：

~~~bash
$ sudo pip install pytz
~~~

# 2. 运行项目

在运行项目之前，我们需要创建数据库和表结构，这里我使用的默认数据库：

~~~bash
$ python manage.py migrate
Operations to perform:
  Apply all migrations: admin, contenttypes, auth, sessions
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying admin.0001_initial... OK
  Applying sessions.0001_initial... OK
~~~

然后启动服务：

~~~bash
$ python manage.py runserver
~~~

你会看到下面的输出：

~~~
Performing system checks...

System check identified no issues (0 silenced).
January 28, 2015 - 02:08:33
Django version 1.7.1, using settings 'mysite.settings'
Starting development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.
~~~

这将会在端口8000启动一个本地服务器, 并且只能从你的这台电脑连接和访问。 既然服务器已经运行起来了，现在用网页浏览器访问 <http://127.0.0.1:8000/>。你应该可以看到一个令人赏心悦目的淡蓝色 Django 欢迎页面它开始工作了。

你也可以指定启动端口:

~~~bash
$ python manage.py runserver 8080
~~~

以及指定 ip：

~~~bash	
$ python manage.py runserver 0.0.0.0:8000
~~~

# 3. 创建 app

前面创建了一个项目并且成功运行，现在来创建一个 app，一个 app 相当于项目的一个子模块。

在项目目录下创建一个 app：

~~~bash	
$ python manage.py startapp polls
~~~

如果操作成功，你会在 mysite 文件夹下看到已经多了一个叫 polls 的文件夹，目录结构如下：

~~~
polls
├── __init__.py
├── admin.py
├── migrations
│   └── __init__.py
├── models.py
├── tests.py
└── views.py

1 directory, 6 files
~~~

# 4. 创建模型

- 每一个 Django Model 都继承自 django.db.models.Model
- 在 Model 当中每一个属性 attribute 都代表一个 database field
- 通过 Django Model API 可以执行数据库的增删改查, 而不需要写一些数据库的查询语句

打开 polls 文件夹下的 models.py 文件。创建两个模型：

~~~python
import datetime
from django.db import models
from django.utils import timezone

class Question(models.Model):
    question_text = models.CharField(max_length=200)
    pub_date = models.DateTimeField('date published')

    def was_published_recently(self):
        return self.pub_date >= timezone.now() - datetime.timedelta(days=1)


class Choice(models.Model):
    question = models.ForeignKey(Question)
    choice_text = models.CharField(max_length=200)
    votes = models.IntegerField(default=0)
~~~

然后在 mysite/settings.py 中修改 ` INSTALLED_APPS` 添加 polls：

~~~python
INSTALLED_APPS = (
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'polls',
)
~~~

在添加了新的 app 之后，我们需要运行下面命令告诉 Django 你的模型做了改变，需要迁移数据库：

~~~bash
$ python manage.py makemigrations polls
~~~

你会看到下面的输出日志：

~~~bash
Migrations for 'polls':
  0001_initial.py:
    - Create model Choice
    - Create model Question
    - Add field question to choice
~~~

你可以从 polls/migrations/0001_initial.py 查看迁移语句。

运行下面语句，你可以查看迁移的 sql 语句：

~~~bash
$ python manage.py sqlmigrate polls 0001
~~~

输出结果：

~~~sql
BEGIN;
CREATE TABLE "polls_choice" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "choice_text" varchar(200) NOT NULL, "votes" integer NOT NULL);
CREATE TABLE "polls_question" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "question_text" varchar(200) NOT NULL, "pub_date" datetime NOT NULL);
CREATE TABLE "polls_choice__new" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "choice_text" varchar(200) NOT NULL, "votes" integer NOT NULL, "question_id" integer NOT NULL REFERENCES "polls_question" ("id"));
INSERT INTO "polls_choice__new" ("choice_text", "votes", "id") SELECT "choice_text", "votes", "id" FROM "polls_choice";
DROP TABLE "polls_choice";
ALTER TABLE "polls_choice__new" RENAME TO "polls_choice";
CREATE INDEX polls_choice_7aa0f6ee ON "polls_choice" ("question_id");

COMMIT;
~~~

你可以运行下面命令，来检查数据库是否有问题：

~~~bash
$ python manage.py check
~~~

再次运行下面的命令，来创建新添加的模型：

~~~bash
$ python manage.py migrate
Operations to perform:
  Apply all migrations: admin, contenttypes, polls, auth, sessions
Running migrations:
  Applying polls.0001_initial... OK
~~~

总结一下，当修改一个模型时，需要做以下几个步骤：

- 修改 models.py 文件
- 运行 `python manage.py makemigrations` 创建迁移语句
- 运行 `python manage.py migrate`，将模型的改变迁移到数据库中

你可以阅读 [django-admin.py documentation](https://docs.djangoproject.com/en/1.7/ref/django-admin/)，查看更多 manage.py 的用法。

创建了模型之后，我们可以通过 Django 提供的 API 来做测试。运行下面命令可以进入到 python shell 的交互模式：

~~~bash
$ python manage.py shell
~~~

下面是一些测试：

~~~python
>>> from polls.models import Question, Choice   # Import the model classes we just wrote.

# No questions are in the system yet.
>>> Question.objects.all()
[]

# Create a new Question.
# Support for time zones is enabled in the default settings file, so
# Django expects a datetime with tzinfo for pub_date. Use timezone.now()
# instead of datetime.datetime.now() and it will do the right thing.
>>> from django.utils import timezone
>>> q = Question(question_text="What's new?", pub_date=timezone.now())

# Save the object into the database. You have to call save() explicitly.
>>> q.save()

# Now it has an ID. Note that this might say "1L" instead of "1", depending
# on which database you're using. That's no biggie; it just means your
# database backend prefers to return integers as Python long integer
# objects.
>>> q.id
1

# Access model field values via Python attributes.
>>> q.question_text
"What's new?"
>>> q.pub_date
datetime.datetime(2012, 2, 26, 13, 0, 0, 775217, tzinfo=<UTC>)

# Change values by changing the attributes, then calling save().
>>> q.question_text = "What's up?"
>>> q.save()

# objects.all() displays all the questions in the database.
>>> Question.objects.all()
[<Question: Question object>]
~~~

打印所有的 Question 时，输出的结果是 `[<Question: Question object>]`，我们可以修改模型类，使其输出更为易懂的描述。修改模型类：

~~~
from django.db import models

class Question(models.Model):
    # ...
    def __str__(self):              # __unicode__ on Python 2
        return self.question_text

class Choice(models.Model):
    # ...
    def __str__(self):              # __unicode__ on Python 2
        return self.choice_text
~~~

接下来继续测试：

~~~bash
>>> from polls.models import Question, Choice

# Make sure our __str__() addition worked.
>>> Question.objects.all()
[<Question: What's up?>]

# Django provides a rich database lookup API that's entirely driven by
# keyword arguments.
>>> Question.objects.filter(id=1)
[<Question: What's up?>]
>>> Question.objects.filter(question_text__startswith='What')
[<Question: What's up?>]

# Get the question that was published this year.
>>> from django.utils import timezone
>>> current_year = timezone.now().year
>>> Question.objects.get(pub_date__year=current_year)
<Question: What's up?>

# Request an ID that doesn't exist, this will raise an exception.
>>> Question.objects.get(id=2)
Traceback (most recent call last):
    ...
DoesNotExist: Question matching query does not exist.

# Lookup by a primary key is the most common case, so Django provides a
# shortcut for primary-key exact lookups.
# The following is identical to Question.objects.get(id=1).
>>> Question.objects.get(pk=1)
<Question: What's up?>

# Make sure our custom method worked.
>>> q = Question.objects.get(pk=1)

# Give the Question a couple of Choices. The create call constructs a new
# Choice object, does the INSERT statement, adds the choice to the set
# of available choices and returns the new Choice object. Django creates
# a set to hold the "other side" of a ForeignKey relation
# (e.g. a question's choice) which can be accessed via the API.
>>> q = Question.objects.get(pk=1)

# Display any choices from the related object set -- none so far.
>>> q.choice_set.all()
[]

# Create three choices.
>>> q.choice_set.create(choice_text='Not much', votes=0)
<Choice: Not much>
>>> q.choice_set.create(choice_text='The sky', votes=0)
<Choice: The sky>
>>> c = q.choice_set.create(choice_text='Just hacking again', votes=0)

# Choice objects have API access to their related Question objects.
>>> c.question
<Question: What's up?>

# And vice versa: Question objects get access to Choice objects.
>>> q.choice_set.all()
[<Choice: Not much>, <Choice: The sky>, <Choice: Just hacking again>]
>>> q.choice_set.count()
3

# The API automatically follows relationships as far as you need.
# Use double underscores to separate relationships.
# This works as many levels deep as you want; there's no limit.
# Find all Choices for any question whose pub_date is in this year
# (reusing the 'current_year' variable we created above).
>>> Choice.objects.filter(question__pub_date__year=current_year)
[<Choice: Not much>, <Choice: The sky>, <Choice: Just hacking again>]

# Let's delete one of the choices. Use delete() for that.
>>> c = q.choice_set.filter(choice_text__startswith='Just hacking')
>>> c.delete()
>>> 
~~~

上面这部分测试，涉及到  django orm 相关的知识，详细说明可以参考 [Django中的ORM](/2015/01/15/django-orm.html)。

# 5. 管理 admin


Django有一个优秀的特性, 内置了Django admin后台管理界面, 方便管理者进行添加和删除网站的内容.

新建的项目系统已经为我们设置好了后台管理功能，见 mysite/settings.py：

~~~python
INSTALLED_APPS = (
    'django.contrib.admin', #默认添加后台管理功能
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'polls',
)
~~~

同时也已经添加了进入后台管理的 url, 可以在  mysite/urls.py 中查看：

~~~python
url(r'^admin/', include(admin.site.urls)), #可以使用设置好的url进入网站后台
~~~


接下来我们需要创建一个管理用户来登录 admin 后台管理界面：

~~~
$ python manage.py createsuperuser
Username (leave blank to use 'june'): admin
Email address:
Password:
Password (again):
Superuser created successfully.
~~~

上面创建了一个 admin 的超级用户，密码也为 admin。

再次运行项目：

~~~bash
$ python manage.py runserver
~~~

然后，访问web 页面 <http://127.0.0.1:8000/admin/>，你将会看到：

![](https://docs.djangoproject.com/en/1.7/_images/admin01.png)

输入用户名和密码，你可以看到：

![](https://docs.djangoproject.com/en/1.7/_images/admin02.png)

这时候你可以看到，你可以修改 groups 和 users 两个对象，但是你不能修改你添加的模型。下面来使你添加的模型也能修改，修改 polls/admin.py：

~~~python
from django.contrib import admin
from polls.models import Choice, Question

class ChoiceInline(admin.StackedInline):
    model = Choice
    extra = 3

class QuestionAdmin(admin.ModelAdmin):
    fieldsets = [
        (None,               {'fields': ['question_text']}),
        ('Date information', {'fields': ['pub_date'], 'classes': ['collapse']}),
    ]
    inlines = [ChoiceInline]
    list_filter = ['pub_date']
    list_display = ('question_text', 'pub_date', 'was_published_recently')

admin.site.register(Choice)
admin.site.register(Question, QuestionAdmin)
~~~

你单击表头时，会发现 was_published_recently 这一列无法排序，我们可以修改  polls/models.py 中的 Question 模型，额外添加一些属性：

~~~python
class Question(models.Model):
    # ...
    def was_published_recently(self):
        return self.pub_date >= timezone.now() - datetime.timedelta(days=1)
    was_published_recently.admin_order_field = 'pub_date'
    was_published_recently.boolean = True
    was_published_recently.short_description = 'Published recently?'
~~~

## 定制外观

在项目根路径创建一个 templates 目录，并修改 mysite/settings.py 文件，添加下面设置：

~~~python
TEMPLATE_DIRS = [os.path.join(BASE_DIR, 'templates')]
~~~

在 templates  下面创建一个 admin 目录，并从 Django admin 模板路径下拷贝 admin/base_site.html 文件到 admin 目录下，修改该文件：

{% highlight html %}
{% raw %}
{% block branding %}
<h1 id="site-name"><a href="{% url 'admin:index' %}">Polls Administration</a></h1>
{% endblock %}
{% endraw %}
{% endhighlight %}

同样，你可以参考上面定制 admin/index.html 内容。

## 使用第三方插件

Django现在已经相对成熟，已经有许多不错的可以使用的第三方插件可以使用，这些插件各种各样，现在我们使用一个第三方插件使后台管理界面更加美观，目前大部分第三方插件可以在 [Django Packages](https://www.djangopackages.com/) 中查看，尝试使用 [django-admin-bootstrap](https://github.com/douglasmiranda/django-admin-bootstrap) 美化后台管理界面。

安装：

~~~bash
$ pip install bootstrap-admin
~~~

然后在 mysite/settings.py 中修改 INSTALLED_APPS：

~~~python
INSTALLED_APPS = (
    'bootstrap_admin',  #一定要放在`django.contrib.admin`前面
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'polls',
)

from django.conf import global_settings
TEMPLATE_CONTEXT_PROCESSORS = global_settings.TEMPLATE_CONTEXT_PROCESSORS + (
    'django.core.context_processors.request',
)
BOOTSTRAP_ADMIN_SIDEBAR_MENU = True
~~~

保存后，再次刷新页面，访问 <http://127.0.0.1:8000/admin>。

# 6. 视图和URL配置

Django 中 views 里面的代码就是一个一个函数逻辑，处理客户端(浏览器)发送的 HTTPRequest，然后返回 HTTPResponse。

## 第一个视图

创建 `polls/views.py ` 文件并添加如下内容：

~~~python
from django.http import HttpResponse

def index(request):
    return HttpResponse("Hello, world. You're at the polls index.")
~~~

在 `polls/urls.py` 中添加一个 url 映射：

~~~python
from django.conf.urls import patterns, url
from polls import views

urlpatterns = patterns('',
    url(r'^$', views.index, name='index'),
)
~~~

这时候 polls 目录结构如下：

~~~
polls
├── __init__.py
├── admin.py
├── migrations
│   ├── 0001_initial.py
│   ├── __init__.py
├── models.py
├── tests.py
├── urls.py
└── views.py
~~~

在上面视图文件中，我们只是告诉 Django，所有指向 URL `/index/` 的请求都应由 index 这个视图函数来处理。

Django 在检查 URL 模式前，移除每一个申请的URL开头的斜杠。 这意味着我们为 `/index/` 写URL模式不用包含斜杠。

模式包含了一个尖号(`^`)和一个美元符号(`$`)。这些都是正则表达式符号，并且有特定的含义： ^要求表达式对字符串的头部进行匹配，$符号则要求表达式对字符串的尾部进行匹配。

如果你访问 `/index`，默认会重定向到末尾带有反斜杠的请求上去，这是受配置文件setting中 `APPEND_SLASH` 项控制的。

如果你是喜欢所有URL都以 `/` 结尾的人（Django开发者的偏爱），那么你只需要在每个 URL 后添加斜杠，并且设置 `APPEND_SLASH` 为 "True"。如果不喜欢URL以斜杠结尾或者根据每个 URL 来决定，那么需要设置 `APPEND_SLASH` 为 "False"，并且根据你自己的意愿来添加结尾斜杠/在URL模式后。

接下来配置项目根路径的 URL 映射，修改  mysite/urls.py 如下：

~~~python
from django.conf.urls import patterns, include, url
from django.contrib import admin

urlpatterns = patterns('',
    url(r'^polls/', include('polls.urls')),
    url(r'^admin/', include(admin.site.urls)),
)
~~~

打开浏览器，访问 <http://localhost:8000/polls/>，你将会看到 `Hello, world. You’re at the polls index.`。

## 编写更多视图

修改  polls/views.py 文件，添加：

~~~python
def detail(request, question_id):
    return HttpResponse("You're looking at question %s." % question_id)

def results(request, question_id):
    response = "You're looking at the results of question %s."
    return HttpResponse(response % question_id)

def vote(request, question_id):
    return HttpResponse("You're voting on question %s." % question_id)
~~~

然后，修改 polls/urls.py 添加映射：

~~~python
from django.conf.urls import patterns, url

from polls import views

urlpatterns = patterns('',
    # ex: /polls/
    url(r'^$', views.index, name='index'),
    # ex: /polls/5/
    url(r'^(?P<question_id>\d+)/$', views.detail, name='detail'),
    # ex: /polls/5/results/
    url(r'^(?P<question_id>\d+)/results/$', views.results, name='results'),
    # ex: /polls/5/vote/
    url(r'^(?P<question_id>\d+)/vote/$', views.vote, name='vote'),
)
~~~

## 正则表达式 

正则表达式是通用的文本模式匹配的方法。 Django URLconfs 允许你使用任意的正则表达式来做强有力的 URL 映射，不过通常你实际上可能只需要使用很少的一部分功能。这里是一些基本的语法。

|符号|匹配|
|:---|:---|
|.          |任意单一字符|
|\d         |任意一位数字|
|[A-Z]      |A 到 Z中任意一个字符（大写）|
|[a-z]      |a 到 z中任意一个字符（小写）|
|[A-Za-z]   |a 到 z中任意一个字符（不区分大小写）|
|+      |匹配一个或更多 (例如, \d+ 匹配一个或 多个数字字符)|
|[^/]+      |一个或多个不为‘/’的字符|
|*      |零个或一个之前的表达式（例如：\d? 匹配零个或一个数字）|
|*      |匹配0个或更多 (例如, \d* 匹配0个 或更多数字字符)|
|{1,3}      |介于一个和三个（包含）之前的表达式（例如，\d{1,3}匹配一个或两个或三个数字）|

有关正则表达式的更多内容，请访问[http://www.djangoproject.com/r/python/re-module/](http://www.djangoproject.com/r/python/re-module/)

## 动态内容

接下来使视图返回动态内容，修改 mysite/views.py 内容如下：

~~~python
from django.http import HttpResponse

from polls.models import Question

def index(request):
    latest_question_list = Question.objects.order_by('-pub_date')[:5]
    output = ', '.join([p.question_text for p in latest_question_list])
    return HttpResponse(output)

# Leave the rest of the views (detail, results, vote) unchanged
~~~

这时候访问 <http://127.0.0.1:8000/polls/> 可以看到输出内容为所有的问题通过逗号连接。

## 使用模板

接下来在视图中使用模板，在 settings.py 中有一个 `TEMPLATE_LOADERS` 属性，并且有一个默认值  `django.template.loaders.app_directories.Loader`，该值定义了从每一个安装的 app 的 templates 目录下寻找模板，故我们可以在 polls 目录下创建 templates 目录以及其子目录 polls。

现在创建一个首页页面  polls/templates/polls/index.html：

{% highlight html %}
{% raw %}
{% if latest_question_list %}
    <ul>
    {% for question in latest_question_list %}
        <li><a href="/polls/{{ question.id }}/">{{ question.question_text }}</a></li>
    {% endfor %}
    </ul>
{% else %}
    <p>No polls are available.</p>
{% endif %}
{% endraw %}
{% endhighlight %}

>注意：
> 页面中的 latest_question_list 变量来自视图返回的上下文，见下面 context 变量

然后更新 polls/views.py 视图，来使用模板：

~~~python
from django.http import HttpResponse
from django.template import RequestContext, loader

from polls.models import Question

def index(request):
    latest_question_list = Question.objects.order_by('-pub_date')[:5]
    template = loader.get_template('polls/index.html')
    context = RequestContext(request, {
        'latest_question_list': latest_question_list,
    })
    return HttpResponse(template.render(context))
~~~

代码说明：

- 通过 loader 来加载模板页面，如前面提到的，这里是相对 polls/templates 目录
- 创建上下文，将需要传递到页面的变量放入上下文变量 context
- 使用 template 通过上下文来渲染页面

上面代码，可以使用  `render()` 来简化：

~~~python    
from django.shortcuts import render
from polls.models import Question

def index(request):
    latest_question_list = Question.objects.order_by('-pub_date')[:5]
    context = {'latest_question_list': latest_question_list}
    return render(request, 'polls/index.html', context)
~~~

当查询数据返回错误时，可以抛出异常，让页面重定向到 404 页面：

~~~python
from django.http import Http404
from django.shortcuts import render

from polls.models import Question
# ...
def detail(request, question_id):
    try:
        question = Question.objects.get(pk=question_id)
    except Question.DoesNotExist:
        raise Http404("Question does not exist")
    return render(request, 'polls/detail.html', {'question': question})
~~~

现在，我们可以回过头来修改  polls/index.html 页面中下面代码：

{% highlight html %}
{% raw %}
<li><a href="/polls/{{ question.id }}/">{{ question.question_text }}</a></li>
{% endraw %}
{% endhighlight %}

上面代码中的 url 为硬编码的，我们可以将其修改为：

{% highlight html %}
{% raw %}
<li><a href="{ % url  'detail' question.id  %}">{{ question.question_text }}</a></li>
{% endraw %}
{% endhighlight %}

为了避免多个视图的名称，例如 detail 视图，的冲突，我们可以给 URL 添加命名空间，修改 mysite/urls.py：

~~~python
from django.conf.urls import patterns, include, url
from django.contrib import admin

urlpatterns = patterns('',
    url(r'^polls/', include('polls.urls', namespace="polls")),
    url(r'^admin/', include(admin.site.urls)),
)
~~~

然后，修改 polls/templates/polls/index.html 为：

{% highlight xml %}
{% raw %}
<li><a href="{ % url 'polls:detail' question.id % }">{{ question.question_text }}</a></li>
{% endraw %}
{% endhighlight %}

接下来创建明细页面 polls/templates/polls/detail.html：

{% highlight html %}
{% raw %}

<h1>{{ question.question_text }}</h1>

{% if error_message %}<p><strong>{{ error_message }}</strong></p>{% endif %}

<form action="{% url 'polls:vote' question.id %}" method="post">
{% csrf_token %}
{% for choice in question.choice_set.all %}
    <input type="radio" name="choice" id="choice{{ forloop.counter }}" value="{{ choice.id }}" />
    <label for="choice{{ forloop.counter }}">{{ choice.choice_text }}</label><br />
{% endfor %}
<input type="submit" value="Vote" />
</form>

{% endraw %}
{% endhighlight %}

创建一个显示投票结果页面 polls/templates/polls/results.html ：

{% highlight xml %}
{% raw %}

<h1>{{ question.question_text }}</h1>

<ul>
{% for choice in question.choice_set.all %}
    <li>{{ choice.choice_text }} -- {{ choice.votes }} vote{{ choice.votes|pluralize }}</li>
{% endfor %}
</ul>

<a href="{% url 'polls:detail' question.id %}">Vote again?</a>

{% endraw %}
{% endhighlight %}

接下来修改 polls/views.py 添加 detail 、 vote 和 results 三个函数：

~~~python
from django.shortcuts import get_object_or_404, render
from django.http import HttpResponseRedirect, HttpResponse
from django.core.urlresolvers import reverse

from polls.models import Question,Choice

# ...
def detail(request, question_id):
    question = get_object_or_404(Question, pk=question_id)
    return render(request, 'polls/detail.html', {'question': question})

def vote(request, question_id):
    p = get_object_or_404(Question, pk=question_id)
    try:
        selected_choice = p.choice_set.get(pk=request.POST['choice'])
    except (KeyError, Choice.DoesNotExist):
        # Redisplay the question voting form.
        return render(request, 'polls/detail.html', {
            'question': p,
            'error_message': "You didn't select a choice.",
        })
    else:
        selected_choice.votes += 1
        selected_choice.save()
        # Always return an HttpResponseRedirect after successfully dealing
        # with POST data. This prevents data from being posted twice if a
        # user hits the Back button.
        return HttpResponseRedirect(reverse('polls:results', args=(p.id,)))    

def results(request, question_id):
    question = get_object_or_404(Question, pk=question_id)
    return render(request, 'polls/results.html', {'question': question})        
~~~

重启服务进行测试，检查是否有错误。

## 简化代码

如果我们要针对很多模型编写视图，则有很多代码都是重复的，我们可以使用 Django 中的通用视图来简化代码。首先，我们将  polls/urls.py 改成如下：

~~~python
from django.conf.urls import patterns, url

from polls import views

urlpatterns = patterns('',
    url(r'^$', views.IndexView.as_view(), name='index'),
    url(r'^(?P<pk>\d+)/$', views.DetailView.as_view(), name='detail'),
    url(r'^(?P<pk>\d+)/results/$', views.ResultsView.as_view(), name='results'),
    url(r'^(?P<question_id>\d+)/vote/$', views.vote, name='vote'),
)
~~~

然后，我们删除 polls/views.py 中的 index、detail 和 results 三个函数，vote 函数和之前保持一致，最后改为如下：

~~~python
from django.shortcuts import get_object_or_404, render
from django.http import HttpResponseRedirect
from django.core.urlresolvers import reverse
from django.views import generic

from polls.models import Choice, Question


class IndexView(generic.ListView):
    template_name = 'polls/index.html'
    context_object_name = 'latest_question_list'

    def get_queryset(self):
        """Return the last five published questions."""
        return Question.objects.order_by('-pub_date')[:5]


class DetailView(generic.DetailView):
    model = Question
    template_name = 'polls/detail.html'


class ResultsView(generic.DetailView):
    model = Question
    template_name = 'polls/results.html'


def vote(request, question_id):
    ... # same as above
~~~

代码说明：

- 这里我们使用了两个通用视图 : ListView 和 DetailView，来和模型相关联。
- DetailView 视图需要传递一个名称为 pk 表示模型主键的参数，所以我们需要把 URL 映射中的 question_id  改为 pk。
- 默认情况下， DetailView使用  `<app name>/<model name>_detail.html` 模板，我们可以使用 `template_name` 变量重新定义模板路径；类似的， ListView 默认使用 `<app name>/<model name>_list.html` 模板。
- DetailView 视图中的上下文默认就包含了对模型的引用，如 question 变量；对于 ListView 视图，为 question_list 变量，如果我们想修改该变量名称，可以通过 `context_object_name 变量覆盖默认的名称`，如使用 latest_question_list 代替 question_list。

更多的文档，请参考 [generic views documentation](https://docs.djangoproject.com/en/1.7/topics/class-based-views/)。

# 7. 总结

最后，来看项目目录结构：

~~~
mysite
├── db.sqlite3
├── manage.py
├── mysite
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
├── polls
│   ├── __init__.py
│   ├── admin.py
│   ├── migrations
│   │   ├── 0001_initial.py
│   │   ├── __init__.py
│   ├── models.py
│   ├── templates
│   │   └── polls
│   │       ├── detail.html
│   │       ├── index.html
│   │       └── results.html
│   ├── tests.py
│   ├── urls.py
│   ├── views.py
└── templates
    └── admin
        └── base_site.htm      
~~~

通过上面的介绍，对 django 的安装、运行以及如何创建视图和模型有了一个清晰的认识，接下来就可以深入的学习 django 的自动化测试、持久化、中间件、国际化等知识。

# 8. 参考文章

- [Django1.7官方文档](https://docs.djangoproject.com/en/1.7/intro/)
- [django实例教程–blog(1)](http://markchen.me/django-instance-tutorial-blog-1/)
- [The Django book 2.0](http://djangobook.py3k.cn/2.0/)
- [Django搭建简易博客](http://andrew-liu.gitbooks.io/django-blog/content/)
