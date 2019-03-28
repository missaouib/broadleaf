---
layout: post

title: Django中的模板

category: python

tags: [python,django]

description: 主要介绍 Django 中模板相关的知识点，包括模板标签、模板过滤器，以及如何在试图中使用模板等等。
---


通过《[如何创建一个Django网站](/2014/01/11/how-to-create-a-django-site.html)》大概清楚了如何创建一个简单的 Django 网站，这篇文章主要是在此基础上介绍 Django 中模板相关的用法。

# 视图中使用模板

在《[如何创建一个Django网站](/2014/01/11/how-to-create-a-django-site.html)》中使用模板的方式如下：

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

在 settings.py 中有一个 TEMPLATE_LOADERS 属性，并且有一个默认值 django.template.loaders.app_directories.Loader，该值定义了从每一个安装的 app 的 templates 目录下寻找模板。当然，你也可以编辑 settings.py 文件中的 TEMPLATE_DIRS属性手动指定模板路径：

~~~python
TEMPLATE_DIRS = (
    # Put strings here, like "/home/html/django_templates" or "C:/www/django/templates".
    # Always use forward slashes, even on Windows.
    # Don't forget to use absolute paths, not relative paths.
    '/home/django/mysite/templates',
)
~~~

上面配置的是系统绝对路径，最好的方式是使用代码动态构建这个路径，例如：

~~~python
import os

BASE_DIR = os.path.dirname(os.path.dirname(__file__))

TEMPLATE_DIRS = (
    os.path.join(BASE_DIR,'templates').replace('\\','/'),
)
~~~

> 这个例子使用了神奇的 Python 内部变量 `__file__` ，该变量被自动设置为代码所在的 Python 模块文件名。 `os.path.dirname(__file__)`将会获取自身所在的文件，然后由 `os.path.join` 这个方法将这目录与 templates 进行连接。如果在 windows下，它会智能地选择正确的后向斜杠'/'进行连接，而不是前向斜杠'/'。

完成 `TEMPLATE_DIRS` 设置后，下一步就是修改视图代码，让它使用 Django 模板加载功能而不是对模板路径硬编码。 

举例如下：

~~~python
from django.template.loader import get_template
from django.template import Context
from django.http import HttpResponse
import datetime

def current_datetime(request):
    now = datetime.datetime.now()
    t = get_template('current_datetime.html')
    html = t.render(Context({'current_date': now}))
    return HttpResponse(html)
~~~

一种更加简洁的编码方式是使用 `render_to_response()`：

~~~python
from django.shortcuts import render_to_response
import datetime

def current_datetime(request):
    now = datetime.datetime.now()
    return render_to_response('current_datetime.html', {'current_date': now})
~~~

上面两个方法都会传入 Context 上下文，将页面需要的变量传到前台去，如果变量很多，需要一一输入。还有一种更加简单的方式，那就是可以利用 Python 的内建函数 `locals()` 。它返回的字典对所有局部变量的名称与值进行映射。 因此，前面的视图可以重写成下面这个样子：

~~~python
def current_datetime(request):
    current_date = datetime.datetime.now()
    return render_to_response('current_datetime.html', locals())
~~~

使用 `locals()` 时要注意是它将包括所有的局部变量，它们可能比你想让模板访问的要多。 在前例中，`locals()` 还包含了 request。

# 模板标签

上面的例子中提到了模板 `current_datetime.html` ，其中的内容如何定义呢？这个就要使用模板标签了。Django 的模板系统带有内置的标签和过滤器。

## if/else

if 标签检查一个变量，如果这个变量为真（即，变量存在，非空，不是布尔值假），系统会显示在 if 和 endif 之间的任何内容，例如：

{% highlight html %}
{% raw %}
{% if today_is_weekend %}
    <p>Welcome to the weekend</p>
{% endif %}
{% endraw %}
{% endhighlight %}

else 标签是可选的：

{% highlight html %}
{% raw %}
{% if today_is_weekend %}
    <p>Welcome to the weekend</p>
{% else %}
    <p>Get back to work.</p>
{% endif %}
{% endraw %}
{% endhighlight %}

一些注意事项：

> 1. if 标签接受 and ，or 或者 not 关键字来对多个变量做判断，或者对变量取反。
> 
> 2. if 标签不允许在同一个标签中同时使用 and 和 or ，因为逻辑上可能模糊的。
> 
> 3. 系统不支持用圆括号来组合比较操作。
> 
> 4. 多次使用同一个逻辑操作符是没有问题的，但是我们不能把不同的操作符组合起来。
> 
> 5. 并没有 elif 标签， 请使用嵌套的 if 标签来达成同样的效果。
> 
> 6. 一定要用 endif 关闭每一个 if 标签。

## for

允许我们在一个序列上迭代。 与 Python 的 for 语句的情形类似，循环语法是 `for X in Y `，Y 是要迭代的序列而X是在每一个特定的循环中使用的变量名称。 每一次循环中，模板系统会渲染在 for 和 endfor 之间的所有内容。

给定一个运动员列表 `athlete_list` 变量，我们可以使用下面的代码来显示这个列表：

{% highlight html %}
{% raw %}
<ul>
{% for athlete in athlete_list %}
    <li>{{ athlete.name }}</li>
{% endfor %}
</ul>
{% endraw %}
{% endhighlight %}

给标签增加一个 `reversed` 使得该列表被反向迭代：

{% highlight html %}
{% raw %}
{% for athlete in athlete_list reversed %}
        <li>{{ athlete.name }}</li>
{% endfor %}
{% endraw %}
{% endhighlight %}

在执行循环之前先检测列表的大小是一个通常的做法，当列表为空时输出一些特别的提示。

{% highlight html %}
{% raw %}
{% if athlete_list %}
    {% for athlete in athlete_list %}
        <p>{{ athlete.name }}</p>
    {% endfor %}
{% else %}
    <p>There are no athletes. Only computer programmers.</p>
{% endif %}
{% endraw %}
{% endhighlight %}

因为这种做法十分常见，所以 `for` 标签支持一个可选的 empty 分句，通过它我们可以定义当列表为空时的输出内容 下面的例子与之前那个等价：

{% highlight html %}
{% raw %}
{% for athlete in athlete_list %}
    <p>{{ athlete.name }}</p>
{% empty %}
    <p>There are no athletes. Only computer programmers.</p>
{% endfor %}
{% endraw %}
{% endhighlight %}

Django不支持退出循环操作。

在每个 for 循环里有一个称为`forloop` 的模板变量。这个变量有一些提示循环进度信息的属性。

> forloop.counter 总是一个表示当前循环的执行次数的整数计数器。 这个计数器是从1开始的，所以在第一次循环时 forloop.counter 将会被设置为1。

{% highlight html %}
{% raw %}
{% for item in todo_list %}
    <p>{{ forloop.counter }}: {{ item }}</p>
{% endfor %}
{% endraw %}
{% endhighlight %}

> forloop.counter0 类似于 forloop.counter ，但是它是从0计数的。 第一次执行循环时这个变量会被设置为0。
> 
> forloop.revcounter 是表示循环中剩余项的整型变量。 在循环初次执行时 forloop.revcounter 将被设置为序列中项的总数。 最后一次循环执行中，这个变量将被置1。
> 
> forloop.revcounter0 类似于 forloop.revcounter ，但它以0做为结束索引。 在第一次执行循环时，该变量会被置为序列的项的个数减1。
> 
> forloop.first 是一个布尔值，如果该迭代是第一次执行，那么它被置为 True
> 
> forloop.last 是一个布尔值；在最后一次执行循环时被置为True
> 
> forloop.parentloop 是一个指向当前循环的上一级循环的 forloop 对象的引用（在嵌套循环的情况下）

## ifequal/ifnotequal

ifequal 标签比较两个值，当他们相等时，显示在 ifequal 和 endifequal 之中所有的值。参数可以是硬编码的字符串，随便用单引号或者双引号引起来。

{% highlight html %}
{% raw %}
{% ifequal user currentuser %}
    <h1>Welcome</h1>
{% endifequal %}

{% ifequal section "community" %}
    <h1>Community</h1>
{% endifequal %}
{% endraw %}
{% endhighlight %}

和 if 类似，ifequal 支持可选的 else 标签。

只有模板变量、字符串、整数和小数可以作为 ifequal 标签的参数。

## cycle

每当我们使用一次这个标签后，标签中的值就会变化，如上，每使用一次下面的 cycle 标签，输出的就会在 row1 和 row2 之间切换。

{% highlight html %}
{% raw %}
{% for o in some_list %}  
    <tr class="{% cycle 'row1' 'row2' %}">  
        ...  
    </tr>  
{% endfor %} 
{% endraw %}
{% endhighlight %}

一些情况下，我们希望将cycle当做一个变量一样来使用，那么我们可以这样：


{% highlight html %}
{% raw %}
<tr>  
    <td class="{% cycle 'row1' 'row2' as rowcolors %}">...</td>  
    <td class="{{ rowcolors }}">...</td>  
</tr>  
<tr>  
    <td class="{% cycle rowcolors %}">...</td>  
    <td class="{{ rowcolors }}">...</td>  
</tr> 
{% endraw %}
{% endhighlight %}

最后，当出现我们不希望 cycle 主动输出的时候，也就是我么只希望它作为一个变量的时候，我们可以这样设置。

{% highlight python %}
{% raw %}
{% cycle 'row1' 'row2' as rowcolors silent %}  
{% endraw %}
{% endhighlight %}

## url

Django 中的 url 标签是用来简化 url 的定义，其可以通过唯一的名称引用 urls.py 中定义的 url。

例如：

~~~python
urlpatterns = patterns('',    
    url(r'^hello/$', hello,name='hello'),
)
~~~

对于上面的定义，可以在模板里通过 hello 名称来应用 `hello/` 这个 url。

{% highlight html %}
{% raw %}
<a href="{% url 'hello' %}">Hello World</a>
{% endraw %}
{% endhighlight %}

这样使用的好处是，无论你怎么修改 urlpatterns 的地址，Template 都会随着改变，省事了不少。**在模版中调用url标签的时候，需要添加下面代码：**

{% highlight python %}
{% raw %}
{% load url from future %}
{% endraw %}
{% endhighlight %}

需要注意的是：name是全局的，你整个 urlpatterns 里只能一个唯一的name。

如果想在试图中使用该名称，可以使用项目代码（关键在于 `reverse` 函数）：

~~~python
from django.core.urlresolvers import reverse

HttpResponseRedirect(reverse("news_index"))
~~~

当遇到urlpatterns的地址包含有参数的时候，如：

~~~python
(r'^(?P<year>\d{4})/(?P<month>\d{1,2})/$','news_list',name='news_archive' ),
~~~

有两个参数，最终的地址如归档的地址 http://blog.javachen.com/2014/10 ，这时候的标签使用如下：

{% highlight html %}
{% raw %}
<a href="{%url 'news_archive' 2014  10%}">2014年10月</a> 
<a href="{%url 'news_archive' year=2014  month=10%}">2014年10月</a> 
{% endraw %}
{% endhighlight %}

当然，在你后台的 views.py 中的方法上也必须有这两个参数。

~~~python
def news_list(request,year,month):
    print 'year:',year
    print 'monty:',month
    
~~~

而在试图里写法如下：

~~~python
from django.core.urlresolvers import reverse
......
reverse("news_archive",kwargs={"year":2014,"month":10})
~~~

## autoescape

控制HTML转义，参数是：on 或 off。效果和使用 safe 或 escape 过滤器相同。

{% highlight python %}
{% raw %}
{% autoescape on %}
    {{ body }}
{% endautoescape %}
{% endraw %}
{% endhighlight %}

## csrf_token

防止跨站请求伪造。

{% highlight html %}
{% raw %}
<form action="." method="post">{% csrf_token %}
{% endraw %}
{% endhighlight %}

## debug

输出完整的调试信息，包括当前的上下文及导入的模块信息。

## filter

通过可变过滤器过滤变量的内容。

过滤器也可以相互传输，它们也可以有参数，就像变量的语法一样。

例：

{% highlight python %}
{% raw %}
{% filter force_escape|lower %}
    This text will be HTML-escaped, and will appear in all lowercase.
{% endfilter %}
{% endraw %}
{% endhighlight %}

> 注意： 
> escape 和safe 过滤器不能接受参数，而使用 autoescape 标签用来管理模板代码块的自动转移。

## firstof

输出传入的第一个不是 False 的变量，如果被传递变量都是 False ，则什么也不输出。例：

{% highlight python %}
{% raw %}
{% firstof var1 var2 var3 %}
{% endraw %}
{% endhighlight %}

等价于:

{% highlight python %}
{% raw %}
{% if var1 %}
    {{ var1|safe }}
{% else %}{% if var2 %}
    {{ var2|safe }}
{% else %}{% if var3 %}
    {{ var3|safe }}
{% endif %}{% endif %}{% endif %}
{% endraw %}
{% endhighlight %}

## extends

extends 标签声明这个模板继承的父模板。

例如：

{% highlight html %}
{% raw %}
{% extends "base.html" %}
{% load staticfiles %}

{% block css %} 
{{ block.super }}
<link href="{% static 'css/page/index.css' %}" rel="stylesheet" type="text/css"/>
{% endblock %}

{% block content %}
<p>Hello world</p>
{% include "partial/index/product_list.html" %}
{% endblock %}
{% endraw %}
{% endhighlight %}

上面代码中，首先用extends标签声明这个模板继承的父模板（必须保证其为模板中的第一个模板标记）。接着重定义 css 这个 block，在包含了父模板的基础上（block.super）引入了新的 CSS 文件；替换了 content 这个 block。这就是子模板所做的全部工作。

## block

所有的 block 标签告诉模板引擎，子模板可以重载这些部分，如果子模板不重载这些部分，则将按默认的内容显示。例如：

{% highlight html %}
{% raw %}
{% load staticfiles %}
<!DOCTYPE html>
<head>
    <title>
        {% block title %} The Default Title {% endblock %}
    </title>

    {% block css %} 
    <link href="{% static 'css/base.css' %}" rel="stylesheet" type="text/css"/>
    {% endblock %}
</head>
<body>
    <div id="wrapper">
        {% block header %}
        {% include 'partial/header.html' %}
        {% endblock %}

        {% block content %} {% endblock %}

        {% block footer %}
        {% include 'partial/footer.html' %}
        {% endblock %}
    </div>

    {% block js %} 
    <script type="text/javascript" src="{% static 'js/jquery.min.js' %}"></script>
    {% endblock %}
</body>
{% endraw %}
{% endhighlight %}

顺便提一下，模板中的 `load staticfiles` 表示加载静态资源，这个一般用于加载 CSS、JS 等静态文件时用到

## include

该标签允许在（模板中）包含其它的模板的内容。标签的参数是所要包含的模板名称，可以是一个变量，也可以是用单/双引号硬编码的字符串。每当在多个模板中出现相同的代码时，就应该考虑是否要使用 `include` 来减少重复，这也是为了提高代码的可重用性。

## 注释

注释使用：

{% highlight python %}
{% raw %}
{# This is a comment #}
{% endraw %}
{% endhighlight %}

如果要实现多行注释，可以使用 comment 模板标签。

# 过滤器

模板过滤器是在变量被显示前修改它的值的一个简单方法，过滤器使用管道字符，例如：

{% highlight python %}
{% raw %}
{{ name|lower }}
{% endraw %}
{% endhighlight %}

显示的内容是变量 {{ name }} 被过滤器 lower 处理后的结果，它功能是转换文本为小写。

过滤管道可以 *套接* ：

{% highlight python %}
{% raw %}
{{ my_list|first|upper }}
{% endraw %}
{% endhighlight %}

有些过滤器有参数。 过滤器的参数跟随冒号之后并且总是以双引号包含。 例如：

{% highlight python %}
{% raw %}
{{ bio|truncatewords:"30" }}
{% endraw %}
{% endhighlight %}

这个将显示变量 bio 的前30个词。

当我们使用了网页编辑器的时候，我们通过编辑器得到的是一串 HTML 代码，如果字节输出，那么 django 会将它默认输出为字符串，从而不能显示出样式。这时候，我们可以使用过滤器来实现我们想要的。

{% highlight python %}
{% raw %}
{{myHtml|safe}}
{% endraw %}
{% endhighlight %}

这样，我们的字符串就被当做 HTML 代码来输出了。safe 表示这段代码是安全的。


一些常见的过滤器：

- addslashes：添加反斜杠到任何反斜杠、单引号或者双引号前面。 这在处理包含 JavaScript 的文本时是非常有用的。

- date：按指定的格式字符串参数格式化 date 或者 datetime 对象，范例：

{% highlight python %}
{% raw %}
{{ pub_date|date:"F j, Y" }} 
{% endraw %}
{% endhighlight %}

# 参考文章

- [The Django Book-第四章 模板](http://djangobook.py3k.cn/2.0/chapter04/)
- [Django url 标签的使用](http://www.yihaomen.com/article/python/355.htm)
- [Django学习笔记（3）——Django的模板](http://raytaylorlin.com/Tech/Script/Python/django-note-3/)
