---
layout: post

title: Django中的ORM

category: python

tags: [ python,django ]

description: 这篇文章主要介绍 Django 中 ORM 相关知识。

published: true

---

通过《[如何创建一个Django网站](/2014/01/11/how-to-create-a-django-site.html)》大概清楚了如何创建一个简单的 Django 网站，并了解了Django 中[模板](/2014/10/30/django-template.html)和[模型](/2015/01/14/django-model.html)使用方法。本篇文章主要在此基础上，了解 Django 中 ORM 相关的用法。

一个 blog 的应用中 mysite/blog/models.py 有以下实体：

~~~python
from django.db import models

class Blog(models.Model):
    name = models.CharField(max_length=100)
    tagline = models.TextField()

    def __str__(self):              # __unicode__ on Python 2
        return self.name

class Author(models.Model):
    name = models.CharField(max_length=50)
    email = models.EmailField()

    def __str__(self):              # __unicode__ on Python 2
        return self.name

class Entry(models.Model):
    blog = models.ForeignKey(Blog)
    headline = models.CharField(max_length=255)
    body_text = models.TextField()
    pub_date = models.DateField()
    mod_date = models.DateField()
    authors = models.ManyToManyField(Author)
    n_comments = models.IntegerField()
    n_pingbacks = models.IntegerField()
    rating = models.IntegerField()

    def __str__(self):              # __unicode__ on Python 2
        return self.headline
~~~ 

## 创建对象

~~~python
>>> from blog.models import Blog
>>> b = Blog(name='Beatles Blog', tagline='All the latest Beatles news.')
>>> b.save()
~~~   

你也可以修改实体，然后保存：

~~~python
>>> b5.name = 'New name'
>>> b5.save()    
~~~ 

## 保存外键信息

下面例子更新 entry 实例的 blog 属性：

~~~python
>>> from blog.models import Entry
>>> entry = Entry.objects.get(pk=1)
>>> cheese_blog = Blog.objects.get(name="Cheddar Talk")
>>> entry.blog = cheese_blog
>>> entry.save()
~~~ 

下面是更新一个 ManyToManyField 字段：

~~~python
>>> from blog.models import Author
>>> joe = Author.objects.create(name="Joe")
>>> entry.authors.add(joe)
>>> 
>>> john = Author.objects.create(name="John")
>>> paul = Author.objects.create(name="Paul")
>>> george = Author.objects.create(name="George")
>>> ringo = Author.objects.create(name="Ringo")
>>> entry.authors.add(john, paul, george, ringo)
~~~

## 查询对象

Django 中查询数据库需要 Manager 和 QuerySet 两个对象。从数据库里检索对象，可以通过模型的 Manage 来建立 QuerySet,一个 QuerySet 表现为一个数据库中对象的结合，他可以有0个一个或多个过滤条件，在 SQL里 QuerySet 相当于 select 语句用 where 或 limit 过滤。你通过模型的 Manage 来获取 QuerySet。

### Manager

Manager 对象附在模型类里，如果没有特指定，每个模型类都会有一个 objects 属性，它构成了这个模型在数据库所有基本查询。

Manager 的几个常用方法：

- `all`：返回一个包含模式里所有数据库记录的 QuerySet
- `filter`：返回一个包含符合指定条件的模型记录的 QuerySet
- `exclude`：和 filter 相反，查找不符合条件的那些记录
- `get`：获取单个符合条件的记录（没有找到或者又超过一个结果都会抛出异常）
- `order_by`：改变 QuerySet 默认的排序

你可以通过模型的 Manager 对象获取 QuerySet 对象：

~~~python
>>> Blog.objects
<django.db.models.manager.Manager object at ...>
>>> b = Blog(name='Foo', tagline='Bar')
>>> b.objects
Traceback:
    ...
AttributeError: "Manager isn't accessible via Blog instances."
~~~

获取所有的 blog 内容:

~~~python
>>> all_entries = Entry.objects.all()

#正向排序
Entry.objects.all().order_by("headline")
#反向排序
Entry.objects.all().order_by("-headline")
~~~

获取 headline 为 Python 开头的 blog :

~~~python
Entry.objects.filter(headline__startswith="Python")

#支持链式操作
Entry.objects.filter(headline__startswith="Python").exclude(pub_date__gte=datetime.now()).filter(pub_date__gte=datetime(2014, 1, 1))
~~~

### QuerySet 类

QuerySet 接受动态的关键字参数，然后转换成合适的 SQL 语句在数据库上执行。

QuerySet 的几个常用方法：

- `distinct`
- `values`
- `values_list`
- `select_related`
- `filter`：返回一个包含符合指定条件的模型记录的 QuerySet
- `extra`：增加结果集以外的字段

#### 延时查询

每次你完成一个 QuerySet，你获得一个全新的结果集，不包括前面的。每次完成的结果集是可以贮存，使用或复用：

~~~python
>>> q1 = Entry.objects.filter(headline__startswith="What")
>>> q2 = q1.exclude(pub_date__gte=datetime.date.today())
>>> q3 = q1.filter(pub_date__gte=datetime.date.today())
~~~

三个 QuerySets 是分开的，第一个是 headline 以 "What" 单词开头的结果集，第二个是第一个的子集，即 pub_date 不大于现在的，第三个是第一个的子集 ，pub_date 大于现在的。

QuerySets 是延迟的，创建 QuerySets 不会触及到数据库操作，你可以多个过滤合并到一起，直到求值的时候 django才会开始查询。如：

~~~python
>>> q = Entry.objects.filter(headline__startswith="What")
>>> q = q.filter(pub_date__lte=datetime.date.today())
>>> q = q.exclude(body_text__icontains="food")
>>> print(q)
~~~

虽然看起来执行了三个过滤条件，实际上最后执行 `print q` 的时候，django 才开始查询执行 SQL 到数据库。

可以使用 python 的数组限制语法限定 QuerySet，如：

~~~python
>>> Entry.objects.all()[:5]
>>> Entry.objects.all()[5:10]

>>> Entry.objects.all().order_by("headline")[:4]
>>> Entry.objects.all().order_by("headline")[4:8]
~~~

一般的，限制 QuerySet 返回新的 QuerySet，不会立即求值查询，除非你使用了 "step" 参数

~~~python
>>> Entry.objects.all()[:10:2]
>>> Entry.objects.order_by('headline')[0]
>>> Entry.objects.order_by('headline')[0:1].get()
~~~

#### 字段过滤

字段查找是指定 SQL 语句的 WHERE 条件从句，通过 QuerySet 的方法 `filter()`, `exclude()` 和 `get()` 指定查询关键字。

格式为：`field__lookuptype=value`。

lookuptype 有以下几种：

- `gt` ： 大于 
- `gte` : 大于等于 
- `in` : 包含
- `lt` : 小于
- `lte` : 小于等于 
- `exact`：
- `iexact`：
- `contains`：包含查询，区分大小写
- `icontains`：不区分大小写
- `startswith`：匹配开头
- `endswith`：匹配结尾
- `istartswith`：匹配开头，不区分大小写
- `iendswith`：匹配结尾，不区分大小写


~~~python
>>> Entry.objects.filter(pub_date__lte='2006-01-01')
~~~

等价于:

~~~sql
SELECT * FROM blog_entry WHERE pub_date <= '2006-01-01';
~~~

当实体中存在  ForeignKey 时，其外键字段名称为模型名称加上 '_id'：

~~~python
>>> Entry.objects.filter(blog_id=4)
~~~

下面是一些举例：

a、exact

~~~python
>>> Entry.objects.get(headline__exact="Man bites dog")
~~~

相当于：

~~~sql
SELECT ... WHERE headline = 'Man bites dog';
~~~

如果查询没有提供双下划线，那么会默认 `__exact`:

~~~python
Entry.objects.get(id__exact=14) # Explicit form
Entry.objects.get(id=14) # __exact is implied

#主键查询
Entry.objects.get(pk=14) # pk implies id__exact
~~~

b、iexact——忽略大小写

~~~python
>>> Blog.objects.get(name__iexact="beatles blog")
~~~

将要匹配 blog 名称为 "Beatles Blog", "beatles blog", 甚至是 "BeAtlES blOG"。

c、contains——包含查询，区分大小写

~~~python
Entry.objects.get(headline__contains='Lennon')
~~~

转化为 SQL:

~~~sql
SELECT ... WHERE headline LIKE '%Lennon%';
~~~

如果有百分号，则会进行转义：

~~~python
Entry.objects.filter(headline__contains='%')
~~~

转义为：

~~~sql
SELECT ... WHERE headline LIKE '%\%%';
~~~

d、in 查询

~~~python
# Get blogs  with id 1, 4 and 7
Entry.objects.filter(pk__in=[1,4,7])
~~~

#### 跨关系查询

跨关系查询是针对有主外键依赖关系的对象而言的，例如上面的 Author 和 Entry 对象是多对多的映射，可以通过 Entry 对象来过滤 Author的 name：

获取所有 blog 名称为 Beatles Blog 的 Entry 列表：

~~~python
>>> Entry.objects.filter(blog__name='Beatles Blog')
~~~

也可以反向查询：

~~~python
>>> Blog.objects.filter(entry__headline__contains='Lennon')
~~~

如果跨越多层关系查询，中间模型没有值，django会作为空对待不会发生异常。

~~~python
Blog.objects.filter(entry__authors__name='Lennon')
Blog.objects.filter(entry__authors__name__isnull=True)
Blog.objects.filter(entry__authors__isnull=False,
        entry__authors__name__isnull=True)
~~~

也支持多条件跨关系查询：

~~~python
Blog.objects.filter(entry__headline__contains='Lennon',
        entry__pub_date__year=2008)
~~~

或者：

~~~python
Blog.objects.filter(entry__headline__contains='Lennon').filter(
        entry__pub_date__year=2008)        
~~~

#### 使用 Extra 调整 SQL

用extra可以修复QuerySet生成的原始SQL的各个部分，它接受四个关键字参数。如下：

- `select`：修改select语句
- `where`：提供额外的where子句
- `tables`：提供额外的表
- `params`：安全的替换动态参数

增加结果集以外的字段：

~~~python
queryset.extra(select={'成年':'age>18'}) 
~~~

提供额外的 where 条件：

~~~python
queryset.extra(where=["first like '%小明%' "])
~~~

提供额外的表：

~~~python
queryset.extra(tables=['myapp_person'])
~~~

安全的替换动态参数：

~~~python
##'%s' is not replaced with normal string 
matches = Author.objects.all().extra(where=["first = '%s' "], params= [unknown-input ( ) ])
~~~

#### F 关键字参数

前面给的例子里，我们建立了过滤，比照模型字段值和一个固定的值，但是如果我们想比较同一个模型里的一个字段和另一个字段的值，django 提供 `F()`——专门取对象中某列值的操作。

~~~python
>>> from django.db.models import F
>>> Entry.objects.filter(n_comments__gt=F('n_pingbacks'))
~~~

当然，还支持加减乘除和模计算：

~~~python
>>> Entry.objects.filter(n_comments__gt=F('n_pingbacks') * 2)
>>> Entry.objects.filter(rating__lt=F('n_comments') + F('n_pingbacks'))
>>> 
>>> Entry.objects.filter(authors__name=F('blog__name'))
~~~

对于日期类型字段，可以使用 timedelta 方法：

~~~python
>>> from datetime import timedelta
>>> Entry.objects.filter(mod_date__gt=F('pub_date') + timedelta(days=3))
~~~

还支持位操作 `.bitand()` 和 `.bitor()`：

~~~python
>>> F('somefield').bitand(16)
~~~

#### 主键查找

Django 支持使用 pk 代替主键：

~~~python
>>> Blog.objects.get(id__exact=14) # Explicit form
>>> Blog.objects.get(id=14) # __exact is implied
>>> Blog.objects.get(pk=14) # pk implies id__exact
~~~

pk 还可以用于其他的查找类型：

~~~python
# Get blogs entries with id 1, 4 and 7
>>> Blog.objects.filter(pk__in=[1,4,7])

# Get all blog entries with id > 14
>>> Blog.objects.filter(pk__gt=14)

>>> Entry.objects.filter(blog__id__exact=3) # Explicit form
>>> Entry.objects.filter(blog__id=3)        # __exact is implied
>>> Entry.objects.filter(blog__pk=3)        # __pk implies __id__exact
~~~

#### Q 关键字参数

QuerySet 可以通过一个叫 Q 的关键字参数封装类进一步参数化，允许使用更复杂的逻辑查询。其结果 Q对 象可以作为 filter 或 exclude 方法的关键字参数。

例子：

~~~python
from django.db.models import Q
Q(question__startswith='What')
~~~

支持 & 和 | 操作符：

~~~python
Q(question__startswith='Who') | Q(question__startswith='What')
~~~

上面的查询翻译成 sql 语句：

~~~sql
WHERE question LIKE 'Who%' OR question LIKE 'What%'
~~~

取反操作：

~~~python
Q(question__startswith='Who') | ~Q(pub_date__year=2005)
~~~

也可以用在 `filter()`、`exclude()`、`get()` 中：

~~~python
Poll.objects.get(
    Q(question__startswith='Who'),
    Q(pub_date=date(2005, 5, 2)) | Q(pub_date=date(2005, 5, 6))
)
~~~

翻译成 sql 语句为：

~~~sql
SELECT * from polls WHERE question LIKE 'Who%'
    AND (pub_date = '2005-05-02' OR pub_date = '2005-05-06')
~~~

## 删除对象

~~~python
>>>entry = Entry.objects.get(pk=1)
>>>entry.delete()
>>>Blog.objects.all().delete()

>>>Entry.objects.filter(pub_date__year=2005).delete()
~~~

## 关系对象

当对象之间存在映射关系或者关联时，该如何查询呢？

当你在模型里定义一个关系时，模型实例会有一个方便的 API 来访问关系对象。以下分几种映射关系分别描述。

### One-to-many关系

如果一个对象有ForeignKey，这个模型实例访问关系对象通过简单的属性:

~~~python
>>> e = Entry.objects.get(id=2)
>>> e.blog # Returns the related Blog object.
~~~

你可以凭借外键属性获取和赋值，修改外键值知道执行 `save()` 方法才会保存到数据库:

~~~python
>>> e = Entry.objects.get(id=2)
>>> e.blog = some_blog
>>> e.save()
~~~

如果关联的对象可以为空，则可以将关联对象职位 None，删除关联：

~~~python
>>> e = Entry.objects.get(id=2)
>>> e.blog = None
>>> e.save() # "UPDATE blog_entry SET blog_id = NULL ...;"
~~~

子查询：

~~~python
>>> e = Entry.objects.get(id=2)
>>> print(e.blog)  # Hits the database to retrieve the associated Blog.
>>> print(e.blog)  # Doesn't hit the database; uses cached version.
~~~

也可以使用 select_related() 方法，该方法会提前将关联对象查询出来：

~~~python
>>> e = Entry.objects.select_related().get(id=2)
>>> print(e.blog)  # Doesn't hit the database; uses cached version.
>>> print(e.blog)  # Doesn't hit the database; uses cached version.
~~~

你也可以通过 `模型_set` 来访问关系对象的另一边，在 Blog 对象并没有维护 Entry 列表，但是你可以通过下面方式从 Blog 对象访问 Entry 列表：

~~~python
>>> b = Blog.objects.get(id=1)
>>> b.entry_set.all() # Returns all Entry objects related to Blog.

# b.entry_set is a Manager that returns QuerySets.
>>> b.entry_set.filter(headline__contains='Lennon')
>>> b.entry_set.count()
~~~

 `模型_set` 可以通过 `related_name` 属性来修改，例如将 Entry 模型中的定义修改为：

~~~python
 blog = ForeignKey(Blog, related_name='entries')
~~~

上面的查询就会变成：

~~~python
>>> b = Blog.objects.get(id=1)
>>> b.entries.all() # Returns all Entry objects related to Blog.

# b.entries is a Manager that returns QuerySets.
>>> b.entries.filter(headline__contains='Lennon')
>>> b.entries.count()
~~~

### Many-to-many关系

~~~python
e = Entry.objects.get(id=3)
e.authors.all() # Returns all Author objects for this Entry.
e.authors.count()
e.authors.filter(name__contains='John')

a = Author.objects.get(id=5)
a.entry_set.all() # Returns all Entry objects for this Author.
~~~

### One-to-one关系

~~~python
class EntryDetail(models.Model):
    entry = models.OneToOneField(Entry)
    details = models.TextField()

ed = EntryDetail.objects.get(id=2)
ed.entry # Returns the related Entry object.
~~~

当反向查询时：

~~~python
e = Entry.objects.get(id=2)
e.entrydetail # returns the related EntryDetail object
~~~

这时候如果没有关联对象，则会抛出 `DoesNotExist` 异常。

并且还可以修改：

~~~python
e.entrydetail = ed
~~~

## 参考资料

- [Making queries](https://docs.djangoproject.com/en/1.7/topics/db/queries/)
- [Eclipse的django开发学习笔记（2）--模型（M）](http://my.oschina.net/u/877170/blog/288334)
- [Django：模型的使用](http://www.pythontip.com/blog/post/6358/)
- [django orm总结](http://www.cnblogs.com/linjiqin/archive/2014/07/01/3817954.html)
