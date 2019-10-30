---
layout: post

title: Python中常见模块
date: 2015-01-05T08:00:00+08:00

categories: [ python ]

tags: [ python ]

description: 主要记录 python 中常见的一些模块的用法和说明。

published: false

---

# 1. 文件管理

使用 glob 模块可以用通配符的方式搜索某个目录下的特定文件，返回结果是一个 list：

~~~python
import glob

flist=glob.glob('*.jpeg')
~~~

使用 `os.getcwd()` 可以得到当前目录，如果想切换到其他目录，可以使用 `os.chdir('str/to/path')`，如果想执行 Shell 脚本，可以使用 `os.system('mkdir newfolder')`。

对于日常文件和目录的管理, shutil 模块提供了更便捷、更高层次的接口

~~~python
import shutil

shutil.copyfile('data.db', 'archive.db')
shutil.move('/build/executables', 'installdir')
~~~

# 2. 集合相关

collections 是 Python 内建的一个集合模块，提供了许多有用的集合类。


## namedtuple类

namedtuple 是一个函数，它用来创建一个自定义的 tuple 对象，并且规定了 tuple 元素的个数，并可以用属性而不是索引来引用 tuple 的某个元素。

~~~python
namedtuple('名称', [属性list]):
~~~

你可以用 namedtuple 来定义坐标：

~~~python
from collections import namedtuple

Point = namedtuple('Point', ['x', 'y'])
p = Point(1, 2)

print p.x
print p.y
~~~

当然也可以用坐标和半径表示一个圆：

~~~python
from collections import namedtuple

Circle = namedtuple('Circle', ['x', 'y', 'r'])
~~~

## deque类

deque是为了高效实现插入和删除操作的双向列表，适合用于队列和栈：

~~~python
>>> from collections import deque
>>> q = deque(['a', 'b', 'c'])
>>> q.append('x')
>>> q.appendleft('y')
>>> q
deque(['y', 'a', 'b', 'c', 'x'])
~~~

deque 除了实现 list 的 append() 和 pop() 外，还支持 appendleft() 和 popleft()，这样就可以非常高效地往头部添加或删除元素。

## defaultdict 类

使用 dict 时，如果引用的 Key 不存在，就会抛出 KeyError。如果希望 key 不存在时，返回一个默认值，就可以用 defaultdict：

~~~python
>>> from collections import defaultdict
>>> dd = defaultdict(lambda: 'N/A')
>>> dd['key1'] = 'abc'
>>> dd['key1'] # key1存在
'abc'
>>> dd['key2'] # key2不存在，返回默认值
'N/A'
~~~

注意默认值是调用函数返回的，而函数在创建 defaultdict 对象时传入。

除了在 Key 不存在时返回默认值，defaultdict 的其他行为跟 dict 是完全一样的。


## OrderedDict 类

使用 dict 时，Key 是无序的。在对 dict 做迭代时，我们无法确定 Key 的顺序。如果要保持 Key 的顺序，可以用 OrderedDict，OrderedDict 的 Key 会按照插入的顺序排列，不是Key本身排序

OrderedDict 可以实现一个 FIFO（先进先出）的 dict，当容量超出限制时，先删除最早添加的 Key。

## Counter 类

Counter 是一个简单的计数器，例如，统计字符出现的个数：

~~~python
>>> from collections import Counter
>>> c = Counter()
>>> for ch in 'programming':
...     c[ch] = c[ch] + 1
...
>>> c
Counter({'g': 2, 'm': 2, 'r': 2, 'a': 1, 'i': 1, 'o': 1, 'n': 1, 'p': 1})
~~~

Counter 实际上也是 dict 的一个子类。


# 3. 参考文章

- [廖雪峰的Python教程-collections](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/001411031239400f7181f65f33a4623bc42276a605debf6000)
