---
layout: post

title: Django中SQL查询

category: python

tags: [ python,django ]

description: 当 Django 中模型提供的查询 API 不能满足要求时，你可能需要使用自定义的 sql 查询，这时候就需要用到  Manager.raw() 方法。

published: true

---

当 Django 中模型提供的查询 API 不能满足要求时，你可能需要使用原始的 sql 查询，这时候就需要用到  `Manager.raw()` 方法。

`Manager` 类提供下面的一个方法，可以用于执行 sql：

~~~python
Manager.raw(raw_query, params=None, translations=None)
~~~

使用方法为：

~~~python
>>> for p in Person.objects.raw('SELECT * FROM myapp_person'):
...     print(p)
John Smith
Jane Jones
~~~

`raw()` 可以通过名称自动将 sql 语句中的字段映射到模型，所以你不必考虑 sql 语句中的字段顺序：

~~~python
>>> Person.objects.raw('SELECT id, first_name, last_name, birth_date FROM myapp_person')
...
>>> Person.objects.raw('SELECT last_name, birth_date, first_name, id FROM myapp_person')
...
~~~

## 字段映射

如果一个表中有和 person 相同的数据，只是字段名称不一致，你可以使用 sql 语句中 的 `as` 关键字给字段取别名：

~~~python
>>> Person.objects.raw('''SELECT first AS first_name,
...                              last AS last_name,
...                              bd AS birth_date,
...                              pk AS id,
...                       FROM some_other_table''')
~~~

另外，你还可以添加 `translations` 参数，手动设置映射关系：

~~~python
>>> name_map = {'first': 'first_name', 'last': 'last_name', 'bd': 'birth_date', 'pk': 'id'}
>>> Person.objects.raw('SELECT * FROM some_other_table', translations=name_map)
~~~

## 延迟获取字段

下面的查询：

~~~python
>>> people = Person.objects.raw('SELECT id, first_name FROM myapp_person')
~~~

sql 语句中只包含两个字段，如果你从 people 中获取不在 sql 语句中的字段的值的时候，**其会从数据库再查询一次**：

~~~python
>>> for p in Person.objects.raw('SELECT id, first_name FROM myapp_person'):
...     print(p.first_name, # This will be retrieved by the original query
...           p.last_name) # This will be retrieved on demand
...
John Smith
Jane Jones
~~~

>但是，需要记住的是 sql 语句中一定要包括主键，因为只有主键才能唯一标识数据库中的一条记录。

## 传递参数

如果你想给 sql 语句传递参数，你可以添加 `raw()` 的 `params` 参数。

~~~python
>>> lname = 'Doe'
>>> Person.objects.raw('SELECT * FROM myapp_person WHERE last_name = %s', [lname])
~~~

>**记住：**上面的 sql 语句一定不要写成下面的方式，因为这样可能会有 sql 注入的问题！
>
>~~~python
>'SELECT * FROM myapp_person WHERE last_name = %s' % lname
>~~~

## 运行自定义的 sql

 `Manager.raw()` 只能执行 sql 查询，确不能运行  `UPDATE`、`INSERT` 或 `DELETE` 查询，在这种情况下，你需要使用 `django.db.connection` 类。

~~~python
 from django.db import connection

def my_custom_sql(self):
    cursor = connection.cursor()

    cursor.execute("UPDATE bar SET foo = 1 WHERE baz = %s", [self.baz])

    cursor.execute("SELECT foo FROM bar WHERE baz = %s", [self.baz])
    row = cursor.fetchone()

    return row
~~~

在 Django 1.6 之后，修改数据之后会自动提交事务，而不用手动调用 `transaction.commit_unless_managed()` 了。

如果 sql 中你想使用 `%` 字符 ，则你需要写两次：

~~~python
cursor.execute("SELECT foo FROM bar WHERE baz = '30%'")
cursor.execute("SELECT foo FROM bar WHERE baz = '30%%' AND id = %s", [self.id])
~~~

如果有多个数据库：

~~~python
from django.db import connections
cursor = connections['my_db_alias'].cursor()
# Your code here...
~~~

默认情况下，Python 的 DB API 返回的结果只包括数据不包括每个字段的名称，你可以牺牲一点性能代价，将查询结果转换为字典：

~~~python
def dictfetchall(cursor):
    "Returns all rows from a cursor as a dict"
    desc = cursor.description
    return [
        dict(zip([col[0] for col in desc], row))
        for row in cursor.fetchall()
    ]
~~~

在 Django 1.7 中，可以使用 `cursor` 作为一个上下文管理器：

~~~python
with connection.cursor() as c:
    c.execute(...)
~~~

其等价于：

~~~python
c = connection.cursor()
try:
    c.execute(...)
finally:
    c.close()
~~~

本文参考：[Performing raw SQL queries](https://docs.djangoproject.com/en/1.7/topics/db/sql/)。
