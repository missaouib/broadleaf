---
layout: post

title: Django中的模型
date: 2015-01-14T08:00:00+08:00

categories: [ python ]

tags: [ python,django ]

description:  Django 中的模型主要用于定义数据的来源信息，其包括一些必要的字段和一些对存储的数据的操作。通常，一个模型对应着数据库中的一个表。

published: true

---

Django 中的模型主要用于定义数据的来源信息，其包括一些必要的字段和一些对存储的数据的操作。通常，一个模型对应着数据库中的一个表。

简单的概念：

- Django 中每一个 Model 都继承自 `django.db.models.Model`。
- 在 Model 当中每一个属性 attribute 都代表一个数据库字段。
- 通过 Django Model API 可以执行数据库的增删改查, 而不需要写一些数据库的查询语句。

# 1. 模型

## 1.1 一个示例

下面在 myapp 应用种定义了一个 Person 模型，包括两个字段：first_name 和 last_name。

~~~python
from django.db import models

class Person(models.Model):
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
~~~

first_name 和 last_name 是模型的字段，每一个字段对应着一个类的属性，并且每一个属性对应数据库表中的一个列。

上面的 Person 模型对应数据库中的表如下：

~~~sql
CREATE TABLE myapp_person (
    "id" serial NOT NULL PRIMARY KEY,
    "first_name" varchar(30) NOT NULL,
    "last_name" varchar(30) NOT NULL
);
~~~

说明：

- 表名 `myapp_person` 是由模型的元数据自动生成的，格式为 `应用_模型`，你可以设置元数据覆盖该值。
- id 字段在模型中是自动添加的，同样该字段名称也可以通过元数据覆盖。
- 上面的 sql 语法是 PostgreSQL 中的语法，你可以通过设置数据库类型，生成不同数据库对应的 sql。

## 1.2 使用模型

使用模型之前，你需要先创建应用，然后将其加入 `INSTALLED_APPS`，然后编写该应用中的 models.py 文件，最后运行 `manage.py makemigrations` 和 `manage.py migrate` 在数据库中创建该实体对应的表。

~~~python
INSTALLED_APPS = (
    #...
    'myapp',
    #...
)
~~~

manage.py 参数列表

- `syncdb`：创建所有应用所需的数据表
- `sql `：显示CREATETABLE调用
- `sqlall` 如同上面的sql一样，从sql文件中初始化数据载入语句
- `sqlindexs`：显示对主键创建索引的调用
- `sqlclear`：显示DROP TABLE的调用
- `sqlcustom`：显示指定.sql文件里的自定义SQL语句
- `loaddata`：载入初始数据
- `dumpdata`：把原有的数据库里的数据输出伟JSON，XML等格式

sql、sqlall、sql、sqlindexs、sqlclear、sqlcustom 不更新数据库，只打印SQL语句以作检验之用。

## 1.3 模型属性

每个模型有一个默认的属性  `Manager`，他是模型访问数据库的接口。如果没有自定义的 Manager，则其默认名称为 `objects`。

## 1.4 模型字段

字段名称不能和 clean、save 或者 delete 冲突。一个示例：

~~~python
from django.db import models

class Musician(models.Model):
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    instrument = models.CharField(max_length=100)

class Album(models.Model):
    artist = models.ForeignKey(Musician)
    name = models.CharField(max_length=100)
    release_date = models.DateField()
    num_stars = models.IntegerField()
~~~

模型中的每一个字段都必须为  `Field` 类的一个实例，Django 使用该类型来决定数据库中对应的列的类型，并且每一个字段都有一些可选的参数。

模型的字段可能的类型及参数如下：

|字段名| 参数|  意义|
|:---|:---|:---|
|AutoField   |   | 一个能够根据可用ID自增的 IntegerField |
|BooleanField   |     |一个真/假字段 |
|CharField    |(max_length)  | 适用于中小长度的字符串。对于长段的文字，请使用 TextField|
|CommaSeparatedIntegerField |  (max_length)  | 一个用逗号分隔开的整数字段 |
|DateField |  ([auto_now], [auto_now_add])  |  日期字段|
|DateTimeField   | |    时间日期字段,接受跟 DateField 一样的额外选项|
|EmailField    | |  一个能检查值是否是有效的电子邮件地址的 CharField  |
|FileField  | (upload_to) |一个文件上传字段|
|FilePathField  | (path,[match],[recursive])  |一个拥有若干可选项的字段，选项被限定为文件系统中某个目录下的文件名|
|FloatField | (max_digits,decimal_places) |一个浮点数，对应 Python 中的 float 实例|
ImageField | (upload_to, [height_field] ,[width_field])  | 像 FileField 一样，只不过要验证上传的对象是一个有效的图片。|
IntegerField    | |    一个整数。|
IPAddressField   | |   一个IP地址，以字符串格式表示（例如： "24.124.1.30" ）。|
|NullBooleanField   | |     就像一个 BooleanField ，但它支持 None /Null 。|
|PhoneNumberField   ||     它是一个 CharField ，并且会检查值是否是一个合法的美式电话格式|
|PositiveIntegerField     ||   和 IntegerField 类似，但必须是正值。|
|PositiveSmallIntegerField    ||      与 PositiveIntegerField 类似，但只允许小于一定值的值,最大值取决于数据库 |
|SlugField   ||     嵌条 就是一段内容的简短标签，这段内容只能包含字母、数字、下划线或连字符。通常用于 URL 中 |
|SmallIntegerField    | |   和 IntegerField 类似，但是只允许在一个数据库相关的范围内的数值（通常是-32,768到 |+32,767）|
|TextField    ||   一个不限长度的文字字段|
|TimeField   ||    时分秒的时间显示。它接受的可指定参数与 DateField 和 DateTimeField 相同。|
|URLField   |  |   用来存储 URL 的字段。|
|USStateField    ||    美国州名称缩写，两个字母。|
|XMLField |   (schema_path)   |它就是一个 TextField ，只不过要检查值是匹配指定schema的合法XML。|

通用字段参数列表如下（所有的字段类型都可以使用下面的参数，所有的都是可选的。）：

|参数名| 意义|
|:---|:---|
|null   | 如果设置为 True 的话，Django将在数据库中存储空值为 NULL 。默认False 。 |
|blank |  如果是 True ，该字段允许留空，默认为 False 。|
|choices |一个包含双元素元组的可迭代的对象，用于给字段提供选项。|
|db_column |  当前字段在数据库中对应的列的名字。|
|db_index   | 如果为 True ，Django会在创建表时对这一列创建数据库索引。|
|default |字段的默认值|
|editable |   如果为 False ，这个字段在管理界面或表单里将不能编辑。默认为 True 。|
|help_text  | 在管理界面表单对象里显示在字段下面的额外帮助文本。|
|primary_key| 如果为 True ，这个字段就会成为模型的主键。|
|radio_admin  |   如果 radio_admin 设置为 True 的话，Django 就会使用单选按钮界面。 |
|unique | 如果是 True ，这个字段的值在整个表中必须是唯一的。|
|unique_for_date  |   把它的值设成一个 DataField 或者 DateTimeField 的字段的名称，可以确保字段在这个日期内不会出现重复值。|
|unique_for_month  |  和 unique_for_date 类似，只是要求字段在指定字段的月份内唯一。|
|unique_for_year |和 unique_for_date 及 unique_for_month 类似，只是时间范围变成了一年。|
|verbose_name  |  除 ForeignKey 、 ManyToManyField 和 OneToOneField 之外的字段都接受一个详细名称作为第一个位置参数。|

举例1，一个 choices 类型的例子如下：

~~~python
from django.db import models

class Person(models.Model):
    SHIRT_SIZES = (
        ('S', 'Small'),
        ('M', 'Medium'),
        ('L', 'Large'),
    )
    name = models.CharField(max_length=60)
    shirt_size = models.CharField(max_length=1, choices=SHIRT_SIZES)
~~~

你可以通过 `get_FOO_display` 来访问 choices 字段显示的名称：

~~~python
>>> p = Person(name="Fred Flintstone", shirt_size="L")
>>> p.save()
>>> p.shirt_size
u'L'
>>> p.get_shirt_size_display()
u'Large'
~~~

举例2，自定义主键：

~~~python
from django.db import models

class Fruit(models.Model):
    name = models.CharField(max_length=100, primary_key=True)
~~~

使用 primary_key 可以指定某一个字段为主键。

~~~python
>>> fruit = Fruit.objects.create(name='Apple')
>>> fruit.name = 'Pear'
>>> fruit.save()
>>> Fruit.objects.values_list('name', flat=True)
['Apple', 'Pear']
~~~

>说明：
> values_list 函数

## 1.5 Meta 元数据类

模型里定义的变量 fields 和关系 relationships 提供了数据库的布局以及稍后查询模型时要用的变量名--经常你还需要添加__unicode__ 和 get_absolute_url 方法或是重写 内置的 save 和 delete方法。

然而，模型的定义还有第三个方面--告知Django关于这个模型的各种元数据信息的嵌套类 Meta，Meta 类处理的是模型的各种元数据的使用和显示：

- 比如在一个对象对多个对象是，它的名字应该怎么显示
- 查询数据表示默认的排序顺序是什么
- 数据表的名字是什么
- 多变量唯一性 （这种限制没有办法在每个单独的变量声明上定义）

Meta类有以下属性：

- `abstract`：定义当前的模型类是不是一个抽象类。
- `app_label`：这个选项只在一种情况下使用，就是你的模型类不在默认的应用程序包下的 models.py 文件中，这时候你需要指定你这个模型类是那个应用程序的
- `db_table`：指定自定义数据库表名
- `db_tablespace`：指定这个模型对应的数据库表放在哪个数据库表空间
- `get_latest_by`：由于 Django 的管理方法中有个 `lastest()`方法，就是得到最近一行记录。如果你的数据模型中有 DateField 或 DateTimeField 类型的字段，你可以通过这个选项来指定 `lastest()` 是按照哪个字段进行选取的。
- `managed`：由于 Django 会自动根据模型类生成映射的数据库表，如果你不希望 Django 这么做，可以把 managed 的值设置为 False。
- `order_with_respect_to`：这个选项一般用于多对多的关系中，它指向一个关联对象。就是说关联对象找到这个对象后它是经过排序的。指定这个属性后你会得到一个 `get_XXX_order()` 和 `set_XXX_order()` 的方法,通过它们你可以设置或者返回排序的对象。
- `ordering`：定义排序字段
- `permissions`：为了在 Django Admin 管理模块下使用的，如果你设置了这个属性可以让指定的方法权限描述更清晰可读
- `proxy`：为了实现代理模型使用的
- `unique_together`：定义多个字段保证数据的唯一性
- `verbose_name`：给你的模型类起一个更可读的名字
- `verbose_name_plural`：这个选项是指定模型的复数形式是什么

## 1.6 模型方法

Manager 提供的是表级别的方法，模型中还可以定义字段级别的方法。例如：

~~~python
from django.db import models

class Person(models.Model):
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    birth_date = models.DateField()

    def baby_boomer_status(self):
        "Returns the person's baby-boomer status."
        import datetime
        if self.birth_date < datetime.date(1945, 8, 1):
            return "Pre-boomer"
        elif self.birth_date < datetime.date(1965, 1, 1):
            return "Baby boomer"
        else:
            return "Post-boomer"

    def _get_full_name(self):
        "Returns the person's full name."
        return '%s %s' % (self.first_name, self.last_name)
    full_name = property(_get_full_name)
~~~

最后一个方法是 `property` 的一个示例。

每一个模型有一些 Django 自动添加的方法，你也可以在模型的定义中覆盖这些方法：

- `__str__()` (Python 3)
- `__unicode__()` (Python 2)
- `get_absolute_url()`

你也可以覆盖模型中和数据库相关的方法，通常是  `save()` 和 `delete()` 两个方法。例如：

~~~python
from django.db import models

class Blog(models.Model):
    name = models.CharField(max_length=100)
    tagline = models.TextField()

    def save(self, *args, **kwargs):
        do_something()
        super(Blog, self).save(*args, **kwargs) # Call the "real" save() method.
        do_something_else()
~~~

## 1.7 执行自定义的 sql

这部分内容请参考：[Django中SQL查询](/2015-01-30-raw-sql-query-in-django.html)

# 2. 模型之间的关系

Django 提供了三种模型之间的关联关系： `many-to-one`、`many-to-many` 和 `one-to-one`。

## 2.1 多对一

定义多对一的关系，需要使用 `django.db.models.ForeignKey` 来引用被关联的模型。

例如，一本书有多个作者：

~~~python
class Author(models.Model):
    name = models.CharField(max_length=100)

class Book(models.Model):
    title = models.CharField(max_length=100)
    author = models.ForeignKey(Author)
~~~

Django 的外键表现很直观，其主要参数就是它要引用的模型类；但是注意要把被引用的模型放在前面。不过，如果不想留意顺序，也可以用字符串代替。

~~~python
class Book(models.Model):
  title = models.CharField(max_length=100)
  author = models.ForeignKey("Author")
  #if Author class is defined in another file myapp/models.py
  #author = models.ForeignKey("myapp.Author")

class Author(models.Model):
   name = models.CharField(max_length=100)
~~~

如果要引用自己为外键，可以设置 `models.ForeignKey("self")` ，这在定义层次结构等类似场景很常用，比如 Employee 类可以具有类似 supervisor 或是 hired_by 这样的属性。

外键 ForeignKey 只定义了关系的一端，但是另一端可以根据关系追溯回来，因为这是一种多对一的关系，多个子对象可以引用同一个父对象，而父对象可以访问到一组子对象。看下面的例子：

~~~python
#取一本书“Moby Dick”
book = Book.objects.get(title="Moby Dick")

#取作者名字
author = Book.author

#获取这个作者所有的书
books = author.book_set.all()
~~~

这里从 Author 到 Book 的反向关系式通过 `Author.book_set` 属性来表示的（这是一个manager对象），是由 ORM 自动添加的，可以通过在 ForeignKey 里指定 `related_name` 参数来改变它的名字。比如：

~~~python
class Book(models.Model):
  author = models.ForeignKey("Author", related_name = "books")

#获取这个作者所有的书
books = author.books.all()
~~~

对简单的对象层次来说， `related_name` 不是必需的，但是更复杂的关系里，比如当有多个 ForeignKey 的时候就一定要指定了。

## 2.2 多对多

上面的例子假设的是一本书只有一个作者，一个作者有多本书，所以是多对一的关系；但是如果一本书也有多个作者呢？这就是多对多的关系；由于SQL没有定义这种关系，必须通过外键用它能理解的方式实现多对多

这里 Django 提供了第二种关系对象映射变量 `ManyToManyField`，语法上来讲， 这和 ForeignKey 是一模一样的，你在关系的一端定义，把要关联的类传递进来，ORM 会自动为另一端生成使用这个关系必要的方法和属性。

不过由于 ManyToManyField 的特性，在哪一端定义它通常都没有关系，因为这个关系是对称的。

~~~python
class Author(models.Model):
  name = models.CharField(max_length=100)

class Book(models.Model):
  title = models.CharField(max_length=100)
  authors = models.ManyToManyField(Author)

#获取一本书
book = Book.objects.get(title="Python Web Dev Django")

#获取该书所有的作者
authors = Book.author_set.all()

#获取第三个作者出版过的所有的书
books = authors[2].book_set.all()
~~~

ManyToManyField 的秘密在于它在背后创建了一张新的表来满足这类关系的查询的需要，而这张表用的则是 SQL 外键，其中每一行都代表了两个对象的一个关系，同时包含了两端的外键

这张查询表在 Django ORM 中一般是隐藏的，不可以单独查询，只能通过关系的某一端查询；不过可以在 ManyToManyField 上指定一个特殊的选项 through 来指向一个显式的中间模型类，更方便你的手动管理关系的两端

~~~python
class Author(models.Model):
  name = models.CharField(max_length=100)

class Book(models.Model):
  title = models.CharField(max_length=100)
  authors = models.ManyToManyField(Author, through = "Authoring")

class Authoring(models.Model):
  collaboration_type = models.CharField(max_length=100)
  book = model.ForeignKey(Book)
  author = model.ForeignKey(Author)
~~~

查询 Author 和 Book 的方法和之前完全一样，另外还能构造对 authoring 的查询：

~~~python
chan_essay_compilations = Book.objects.filter(
    author__name__endswith = 'Chun'
    authoring__collaboration_type = 'essays'
)
~~~

## 2.3 一对一

定义一个一对一的关系，需要使用 `OneToOneField` 类。

例如，Restaurant 和 Place 为一对一：

~~~python
from django.db import models

class Place(models.Model):
    name = models.CharField(max_length=50)
    address = models.CharField(max_length=80)

    def __str__(self):              # __unicode__ on Python 2
        return "%s the place" % self.name

class Restaurant(models.Model):
    place = models.OneToOneField(Place, primary_key=True)
    serves_hot_dogs = models.BooleanField(default=False)
    serves_pizza = models.BooleanField(default=False)

    def __str__(self):              # __unicode__ on Python 2
        return "%s the restaurant" % self.place.name

class Waiter(models.Model):
    restaurant = models.ForeignKey(Restaurant)
    name = models.CharField(max_length=50)

    def __str__(self):              # __unicode__ on Python 2
        return "%s the waiter at %s" % (self.name, self.restaurant)
~~~

一个 Restaurant 都会有一个 Place，实际上你也可以使用继承的方式来定义。

下面是一些操作的例子。

创建 Place：

~~~python
>>> p1 = Place(name='Demon Dogs', address='944 W. Fullerton')
>>> p1.save()
>>> p2 = Place(name='Ace Hardware', address='1013 N. Ashland')
>>> p2.save()
~~~

创建 Restaurant 并关联到 Place：

~~~python
>>> r = Restaurant(place=p1, serves_hot_dogs=True, serves_pizza=False)
>>> r.save()
~~~

然后，可以这样访问：

~~~python
>>> r.place
<Place: Demon Dogs the place>
>>> p1.restaurant
<Restaurant: Demon Dogs the restaurant>
~~~

这时候，p2 没有与之关联的 Restaurant，如果通过 p2 访问 Restaurant 就会提示异常：

~~~python
>>> from django.core.exceptions import ObjectDoesNotExist
>>> try:
>>>     p2.restaurant
>>> except ObjectDoesNotExist:
>>>     print("There is no restaurant here.")
There is no restaurant here.
~~~

你可以通过下面的方式来避免出现异常：

~~~python
>>> hasattr(p2, 'restaurant')
False
~~~

下面可以做一些赋值操作：

~~~python
>>> r.place = p2
>>> r.save()
>>> p2.restaurant
<Restaurant: Ace Hardware the restaurant>
>>> r.place
<Place: Ace Hardware the place>
~~~

也可以反向赋值：

~~~python
>>> p1.restaurant = r
>>> p1.restaurant
<Restaurant: Demon Dogs the restaurant>
~~~

查询所有的 Restaurant 和 Place：

~~~python
>>> Restaurant.objects.all()
[<Restaurant: Demon Dogs the restaurant>, <Restaurant: Ace Hardware the restaurant>]
>>> Place.objects.order_by('name')
[<Place: Ace Hardware the place>, <Place: Demon Dogs the place>]
~~~

当然，也可以使用跨关系查找：

~~~python
>>> Restaurant.objects.get(place=p1)
<Restaurant: Demon Dogs the restaurant>
>>> Restaurant.objects.get(place__pk=1)
<Restaurant: Demon Dogs the restaurant>
>>> Restaurant.objects.filter(place__name__startswith="Demon")
[<Restaurant: Demon Dogs the restaurant>]
>>> Restaurant.objects.exclude(place__address__contains="Ashland")
[<Restaurant: Demon Dogs the restaurant>]
~~~

反向查找：

~~~python
>>> Place.objects.get(pk=1)
<Place: Demon Dogs the place>
>>> Place.objects.get(restaurant__place=p1)
<Place: Demon Dogs the place>
>>> Place.objects.get(restaurant=r)
<Place: Demon Dogs the place>
>>> Place.objects.get(restaurant__place__name__startswith="Demon")
<Place: Demon Dogs the place>
~~~

创建一个 Waiter：

~~~python
>>> w = r.waiter_set.create(name='Joe')
>>> w.save()
>>> w
<Waiter: Joe the waiter at Demon Dogs the restaurant>
~~~

然后，查询：

~~~python
>>> Waiter.objects.filter(restaurant__place=p1)
[<Waiter: Joe the waiter at Demon Dogs the restaurant>]
>>> Waiter.objects.filter(restaurant__place__name__startswith="Demon")
[<Waiter: Joe the waiter at Demon Dogs the restaurant>]
~~~

# 3. 模型继承

Django目前支持几种不同的继承方式：

- 使用单个表。整个继承树共用一张表。使用唯一的表，包含所有基类和子类的字段。
- 每个具体类一张表，这种方式下，每张表都包含具体类和继承树上所有父类的字段。因为多个表中有重复字段，从整个继承树上来说，字段是冗余的。
- 每个类一张表，继承关系通过表的JOIN操作来表示。这种方式下，每个表只包含类中定义的字段，不存在字段冗余，但是要同时操作子类和所有父类所对应的表。

方式一：每个类一张表

~~~python
from django.db import models
 
class Person(models.Model):
  name = models.CharField(max_length=20)
  sex = models.BooleanField(default=True)
 
class teacher(Person):
  subject = models.CharField(max_length=20)
 
class student(Person):
  course = models.CharField(max_length=20)
~~~

执行 `python manage.py sqlall`：

~~~sql
BEGIN;
CREATE TABLE "blog_person" (
    "id" integer NOT NULL PRIMARY KEY,
    "name" varchar(20) NOT NULL,
    "sex" bool NOT NULL
)
;
CREATE TABLE "blog_teacher" (
    "person_ptr_id" integer NOT NULL PRIMARY KEY REFERENCES "blog_person" ("id"),
    "subject" varchar(20) NOT NULL
)
;
CREATE TABLE "blog_student" (
    "person_ptr_id" integer NOT NULL PRIMARY KEY REFERENCES "blog_person" ("id"),
    "course" varchar(20) NOT NULL
)
;
 
COMMIT;
~~~

方式二：每个具体类一张表，父类不需要创建表

~~~python
from django.db import models
 
class Person(models.Model):
  name = models.CharField(max_length=20)
  sex = models.BooleanField(default=True)
 
  class Meta:
    abstract = True
 
class teacher(Person):
  subject = models.CharField(max_length=20)
 
class student(Person):
  course = models.CharField(max_length=20)
~~~

执行 `python manage.py sqlall`：

~~~sql
BEGIN;
CREATE TABLE "blog_teacher" (
    "id" integer NOT NULL PRIMARY KEY,
    "name" varchar(20) NOT NULL,
    "sex" bool NOT NULL,
    "subject" varchar(20) NOT NULL
)
;
CREATE TABLE "blog_student" (
    "id" integer NOT NULL PRIMARY KEY,
    "name" varchar(20) NOT NULL,
    "sex" bool NOT NULL,
    "course" varchar(20) NOT NULL
)
;
 
COMMIT;
~~~

可以通过 Meta 嵌套类自定义每个子类的表名：

~~~python
from django.db import models
 
class Person(models.Model):
  name = models.CharField(max_length=20)
  sex = models.BooleanField(default=True)
 
  class Meta:
    abstract = True
 
class teacher(Person):
  subject = models.CharField(max_length=20)
 
  class Meta:
    db_table = "Teacher"
 
class student(Person):
  course = models.CharField(max_length=20)
 
  class Meta:
    db_table = "Student"
~~~

方式三：代理模型，为子类增加方法，但不能增加属性

~~~ python  
from django.db import models
 
class Person(User):
  class Meta:
    proxy = True
 
  def some_function(self):
    pass
~~~

这样的方式不会改变数据存储结构，但可以纵向的扩展子类Person的方法，并且基础User父类的所有属性和方法。

# 4. 参考文章

- [Django 数据模型的字段列表整理](http://www.c77cc.cn/article-64.html)
- [跟我一起Django - 04 定义和使用模型](http://www.tuicool.com/articles/vU7vIz)
- [django的模型总结](http://iluoxuan.iteye.com/blog/1703061)
- [django ORM数据模型的定义](http://blog.coocla.org/414.html)
