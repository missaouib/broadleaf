---
layout: post

title: Scala集合

category: scala

tags: [ scala ]

description: Scala有一个非常通用，丰富，强大，可组合的集合库，本文主要是整理Scala集合相关知识点。

published: true

---

Scala有一个非常通用，丰富，强大，可组合的集合库；集合是高阶的(high level)并暴露了一大套操作方法。很多集合的处理和转换可以被表达的简洁又可读，但不审慎地用它们的功能也会导致相反的结果。每个Scala程序员应该阅读 集合设计文档；通过它可以很好地洞察集合库，并了解设计动机。

scala集合API：<http://www.scala-lang.org/docu/files/collections-api/collections.html>。

怎样使用集合，请参考 [Effective Scala](http://twitter.github.io/effectivescala/index-cn.html#集合)。

# 架构

Scala的所有的集合类都可以在包 `scala.collection` 包中找到，其中的集合类都是高级抽象类或特性。

![](/static/images/images/scala.collection.png)

Scala 集合类系统地区分了可变的和不可变的集合。可变集合可以在适当的地方被更新或扩展。这意味着你可以修改，添加，移除一个集合的元素。而不可变集合类，相比之下，永远不会改变。不过，你仍然可以模拟添加，移除或更新操作。但是这些操作将在每一种情况下都返回一个新的集合，同时使原来的集合不发生改变。

可变的集合类位于 `scala.collection.mutable` 包中，而不可变的集合位于 `scala.collection.immutable` 。`scala.collection` 包中的集合，既可以是可变的，也可以是不可变的。例如：[collection.IndexedSeq[T]](http://www.scala-lang.org/api/current/scala/collection/IndexedSeq.html) 就是 [collection.immutable.IndexedSeq[T]](http://www.scala-lang.org/api/current/scala/collection/immutable/IndexedSeq.html) 和 [collection.mutable.IndexedSeq[T]](http://www.scala-lang.org/api/current/scala/collection/mutable/IndexedSeq.html) 这两类的超类。`scala.collection` 包中的根集合类中定义了相同的接口作为不可变集合类，同时，`scala.collection.mutable` 包中的可变集合类代表性的添加了一些有辅助作用的修改操作到这个 immutable 接口。


下面的图表显示 `scala.collection.immutable` 中的所有集合类。

![](/images/scala.collection.immutable.jpg)

下面的图表显示 `scala.collection.mutable` 中的所有集合类。

![](/images/scala.collection.mutable.png)

`默认情况下，Scala 一直采用不可变集合类`。例如，如果你仅写了 `Set` 而没有任何加前缀也没有从其它地方导入 `Set`，你会得到一个不可变的 set，另外如果你写迭代，你也会得到一个不可变的迭代集合类，这是由于这些类在从 scala 中导入的时候都是默认绑定的。为了得到可变的默认版本，你需要显式的声明`collection.mutable.Set`或`collection.mutable.Iterable`。

一个有用的约定，如果你想要同时使用可变和不可变集合类，只导入 `collection.mutable` 包即可。

~~~scala
import scala.collection.mutable  //导入包scala.collection.mutable 
~~~

然而，像没有前缀的 `Set` 这样的关键字， 仍然指的是一个不可变集合，然而 `mutable.Set` 指的是可变的副本（可变集合）。

为了方便和向后兼容性，一些导入类型在包 scala 中有别名，所以你能通过简单的名字使用它们而不需要 import。这有一个例子是 `List`类型，它可以用以下两种方法使用，如下：

~~~scala
scala.collection.immutable.List // 这是它的定义位置
scala.List //通过scala 包中的别名
List // 因为scala._ 总是是被自动导入。
~~~

其它类型的别名有： Traversable, Iterable, Seq, IndexedSeq, Iterator, Stream, Vector, StringBuilder, Range。

|不可变（collection.immutable._）| 可变（collection.mutable._）|
|:---|:----|
|Array | ArrayBuffer |
|List  | ListBuffer |
|String | StringBuilder |
|/ | LinkedList, DoubleLinkedList |
|List |  MutableList |
|/ |  Queue |
|Array | ArraySeq |
|Stack | ArrayStack |
|HashMap HashSet | HashMap HashSet |

# Traversable

Traversable 是容器类的最高级别特性，它唯一的抽象操作是 foreach：

~~~scala
def foreach[U](f: Elem => U) 
~~~

Traversable 同时定义的很多具体方法：

- 相加操作++
- Map 操作有 map，flatMap 和 collect
  - `xs map f`  通过函数xs中的每一个元素调用函数f来生成一个容器。
  - `xs flatMap f`  通过对容器xs中的每一个元素调用作为容器的值函数f，在把所得的结果连接起来作为一个新的容器。
  - `xs collect f`  通过对每个xs中的符合定义的元素调用偏函数f，并把结果收集起来生成一个集合。
- 转换操作包括 toArray，toList，toIterable，toSeq，toIndexedSeq，toStream，toSet，和 toMap
  - `xs.toArray`  把容器转换为一个数组
  - `xs.toList` 把容器转换为一个list
  - `xs.toIterable` 把容器转换为一个迭代器。
  - `xs.toSeq`  把容器转换为一个序列
  - `xs.toIndexedSeq` 把容器转换为一个索引序列
  - `xs.toStream` 把容器转换为一个延迟计算的流。
  - `xs.toSet`  把容器转换为一个Set。
  - `xs.toMap`  把由键/值对组成的容器转换为一个映射表。如果该容器并不是以键/值对作为元素的，那么调用这个操作将会导致一个静态类型的错误。 
- 拷贝操作有 copyToBuffer 和 copyToArray
  - `xs copyToBuffer buf` 把容器的所有元素拷贝到buf缓冲区。
  - `xs copyToArray(arr, s, n)` 拷贝最多n个元素到数组arr的坐标s处。参数s，n是可选项。 
- Size 操作包括有 isEmpty，nonEmpty，size 和 hasDefiniteSize
  - `xs.isEmpty`  测试容器是否为空。
  - `xs.nonEmpty` 测试容器是否包含元素。
  - `xs.size` 计算容器内元素的个数。
  - `xs.hasDefiniteSize`  如果xs的大小是有限的，则为true。 
- 元素检索操作有 head，last，headOption，lastOption 和 find
  - `xs.head` 返回容器内第一个元素（或其他元素，若当前的容器无序）。
  - `xs.headOption` xs选项值中的第一个元素，若xs为空则为None。
  - `xs.last` 返回容器的最后一个元素（或某个元素，如果当前的容器无序的话）。
  - `xs.lastOption` xs选项值中的最后一个元素，如果xs为空则为None。
  - `xs find p` 查找xs中满足p条件的元素，若存在则返回第一个元素；若不存在，则为空。
- 子容器检索操作有 tail，init，slice，take，drop，takeWhilte，dropWhile，filter，filteNot 和 withFilter
  - `xs.tail` 返回由除了xs.head外的其余部分。
  - `xs.init` 返回除xs.last外的其余部分。
  - `xs slice (from, to)` 返回由xs的一个片段索引中的元素组成的容器（从from到to，但不包括to）。
  - `xs take n` 由xs的第一个到第n个元素（或当xs无序时任意的n个元素）组成的容器。
  - `xs drop n` 由除了xs take n以外的元素组成的容器。
  - `xs takeWhile p`  容器xs中最长能够满足断言p的前缀。
  - `xs dropWhile p`  容器xs中除了xs takeWhile p以外的全部元素。
  - `xs filter p` 由xs中满足条件p的元素组成的容器。
  - `xs withFilter p` 这个容器是一个不太严格的过滤器。子容器调用map，flatMap，foreach和withFilter只适用于xs中那些的满足条件p的元素。
  - `xs filterNot p`  由xs中不满足条件p的元素组成的容器。
- 拆分操作有 splitAt，span，partition 和 groupBy
  - `xs splitAt n`  把xs从指定位置的拆分成两个容器（`xs take n`和`xs drop n`）。
  - `xs span p` 根据一个断言p将xs拆分为两个容器（`xs takeWhile p`, `xs.dropWhile p`）。
  - `xs partition p`  把xs分割为两个容器，符合断言p的元素赋给一个容器，其余的赋给另一个(`xs filter p`, `xs.filterNot p`)。
  - `xs groupBy f`  根据判别函数f把xs拆分一个到容器的map中。
- 元素测试包括有 exists，forall 和 count
  - `xs forall p` 返回一个布尔值表示用于表示断言p是否适用xs中的所有元素。
  - `xs exists p` 返回一个布尔值判断xs中是否有部分元素满足断言p。
  - `xs count p`  返回xs中符合断言p条件的元素个数。
- 折叠操作有 foldLeft，foldRight，/:，:\，reduceLeft 和 reduceRight
  - `(z /: xs)(op)` 在xs中，对由z开始从左到右的连续元素应用二进制运算op。
  - `(xs :\ z)(op)` 在xs中，对由z开始从右到左的连续元素应用二进制运算op
  - `xs.foldLeft(z)(op)` 与 `(z /: xs)(op)`相同。
  - `xs.foldRight(z)(op)` 与 `(xs :\ z)(op)`相同。
  - `xs reduceLeft op`  非空容器xs中的连续元素从左至右调用二进制运算op。
  - `xs reduceRight op` 非空容器xs中的连续元素从右至左调用二进制运算op。
- 特殊折叠包括 sum, product, min, max
  - `xs.sum`  返回容器xs中数字元素的和。
  - `xs.product`  xs返回容器xs中数字元素的积。
  - `xs.min`  容器xs中有序元素值中的最小值。
  - `xs.max`  容器xs中有序元素值中的最大值。
- 字符串操作有 mkString，addString 和 stringPrefix
  - `xs addString (b, start, sep, end)` 把一个字符串加到StringBuilder对象b中，该字符串显示为将xs中所有元素用分隔符sep连接起来并封装在start和end之间。其中start，end和sep都是可选的。
  - `xs mkString (start, sep, end)` 把容器xs转换为一个字符串，该字符串显示为将xs中所有元素用分隔符sep连接起来并封装在start和end之间。其中start，end和sep都是可选的。
  - `xs.stringPrefix` 返回一个字符串，该字符串是以容器名开头的 xs.toString。
- 视图操作包含两个view方法的重载体
  - `xs.view` 通过容器xs生成一个视图。
  - `xs view (from, to)`  生成一个表示在指定索引范围内的xs元素的视图。

# Iterable

继承 Traversable 的特性是 Iterable，该类实现了 foreach 方法，定义了一个迭代器。

~~~scala
def foreach[U](f: Elem => U): Unit = {
  val it = iterator
  while (it.hasNext) f(it.next())
} 
~~~

Iterable 有两个方法返回迭代器：grouped 和 sliding。grouped 方法返回元素的增量分块，sliding 方法生成一个滑动元素的窗口。两者的差异见下面代码：

~~~scala
scala> val xs = List(1, 2, 3, 4, 5)
xs: List[Int] = List(1, 2, 3, 4, 5)
scala> val git = xs grouped 3
git: Iterator[List[Int]] = non-empty iterator
scala> git.next()
res3: List[Int] = List(1, 2, 3)
scala> git.next()
res4: List[Int] = List(4, 5)
scala> val sit = xs sliding 3
sit: Iterator[List[Int]] = non-empty iterator
scala> sit.next()
res5: List[Int] = List(1, 2, 3)
scala> sit.next()
res6: List[Int] = List(2, 3, 4)
scala> sit.next()
res7: List[Int] = List(3, 4, 5)
~~~

Iterable 增加了一些其他方法：

- `xs takeRight n`  一个容器由xs的最后n个元素组成（若定义的元素是无序，则由任意的n个元素组成）。
- `xs dropRight n`  一个容器由除了xs 被取走的（执行过takeRight方法）n个元素外的其余元素组成。
- `xs zip ys` 把一对容器 xs和ys的包含的元素合成到一个iterabale。
- `xs zipAll (ys, x, y)`  一对容器 xs 和ys的相应的元素合并到一个iterable ，实现方式是通过附加的元素x或y，把短的序列被延展到相对更长的一个上。
- `xs.zip WithIndex`  把一对容器xs和它的序列，所包含的元素组成一个iterable 。
- `xs sameElements ys`  测试 xs 和 ys 是否以相同的顺序包含相同的元素。

# Seq

序列，指的是一类具有一定长度的可迭代访问的对象，其中每个元素均带有一个从0开始计数的固定索引位置。

序列的操作有以下几种，如下表所示：

- 索引和长度 
  - `xs(i)` (或者为`xs apply i`)。xs的第i个元素
  - `xs isDefinedAt i`  测试xs.indices中是否包含i。
  - `xs.length` 序列的长度（同size）。
  - `xs.lengthCompare ys` 如果xs的长度小于ys的长度，则返回-1。如果xs的长度大于ys的长度，则返回+1，如果它们长度相等，则返回0。即使其中一个序列是无限的，也可以使用此方法。
  - `xs.indices`  xs的索引范围，从0到xs.length - 1。
- 索引搜索  
  - `xs indexOf x`  返回序列xs中等于x的第一个元素的索引（存在多种变体）。
  - `xs lastIndexOf x`  返回序列xs中等于x的最后一个元素的索引（存在多种变体）。
  - `xs indexOfSlice ys`  查找子序列ys，返回xs中匹配的第一个索引。
  - `xs indexOfSlice ys`  查找子序列ys，返回xs中匹配的倒数一个索引。
  - `xs indexWhere p` xs序列中满足p的第一个元素。（有多种形式）
  - `xs segmentLength (p, i)` xs中，从xs(i)开始并满足条件p的元素的最长连续片段的长度。
  - `xs prefixLength p` xs序列中满足p条件的先头元素的最大个数。
- 加法 
  - `x +: xs` 由序列xs的前方添加x所得的新序列。
  - `xs :+ x` 由序列xs的后方追加x所得的新序列。
  - `xs padTo (len, x)` 在xs后方追加x，直到长度达到len后得到的序列。
- 更新  
  - `xs patch (i, ys, r)` 将xs中第i个元素开始的r个元素，替换为ys所得的序列。
  - `xs updated (i, x)` 将xs中第i个元素替换为x后所得的xs的副本。
  - `xs(i) = x` （或写作 `xs.update(i, x)`，仅适用于可变序列）将xs序列中第i个元素修改为x。
- 排序  
  - `xs.sorted` 通过使用xs中元素类型的标准顺序，将xs元素进行排序后得到的新序列。
  - `xs sortWith lt ` 将lt作为比较操作，并以此将xs中的元素进行排序后得到的新序列。
  - `xs sortBy f` 将序列xs的元素进行排序后得到的新序列。参与比较的两个元素各自经f函数映射后得到一个结果，通过比较它们的结果来进行排序。
- 反转  
  - `xs.reverse`  与xs序列元素顺序相反的一个新序列。
  - `xs.reverseIterator`  产生序列xs中元素的反序迭代器。
  - `xs reverseMap f` 以xs的相反顺序，通过f映射xs序列中的元素得到的新序列。
- 比较  
  - `xs startsWith ys`  测试序列xs是否以序列ys开头（存在多种形式）。
  - `xs endsWith ys`  测试序列xs是否以序列ys结束（存在多种形式）。
  - `xs contains x` 测试xs序列中是否存在一个与x相等的元素。
  - `xs containsSlice ys` 测试xs序列中是否存在一个与ys相同的连续子序列。
  - `(xs corresponds ys)(p)`  测试序列xs与序列ys中对应的元素是否满足二元的判断式p。
- 多集操作  
  - `xs intersect ys` 序列xs和ys的交集，并保留序列xs中的顺序。
  - `xs diff ys`  序列xs和ys的差集，并保留序列xs中的顺序。
  - `xs union ys` 并集；同xs ++ ys。
  - `xs.distinct `不含重复元素的xs的子序列。

 Seq 具有两个子特征 [LinearSeq](http://www.scala-lang.org/api/current/scala/collection/IndexedSeq.html) 和 [IndexedSeq](http://www.scala-lang.org/api/current/scala/collection/IndexedSeq.html)。它们不添加任何新的操作，但都提供不同的性能特点：线性序列具有高效的 head 和 tail 操作，而索引序列具有高效的apply, length, 和 (如果可变) update操作。

## 缓冲器

`Buffers是可变序列一个重要的种类`。它们不仅允许更新现有的元素，而且允许元素的插入、移除和在buffer尾部高效地添加新元素。buffer 支持的主要新方法有：用于在尾部添加元素的 `+=` 和 `++=`；用于在前方添加元素的 `+=:` 和 `++=:`；用于插入元素的 insert 和 insertAll；以及用于删除元素的 remove 和 `-=`。

Buffer类的操作：

- 加法
  - `buf += x ` 将元素x追加到buffer，并将buf自身作为结果返回。
  - `buf += (x, y, z)`  将给定的元素追加到buffer。
  - `buf ++= xs`  将xs中的所有元素追加到buffer。
  - `x +=: buf` 将元素x添加到buffer的前方。
  - `xs ++=: buf` 将xs中的所有元素都添加到buffer的前方。
  - `buf insert (i, x)` 将元素x插入到buffer中索引为i的位置。
  - `buf insertAll (i, xs)` 将xs的所有元素都插入到buffer中索引为i的位置。
- 移除
  - `buf -= x`  将元素x从buffer中移除。
  - `buf remove i`  将buffer中索引为i的元素移除。
  - `buf remove (i, n)` 将buffer中从索引i开始的n个元素移除。
  - `buf trimStart n` 移除buffer中的前n个元素。
  - `buf trimEnd n` 移除buffer中的后n个元素。
  - `buf.clear()` 移除buffer中的所有元素。
- 克隆 
  - `buf.clone` 与buf具有相同元素的新buffer。

ListBuffer 和 ArrayBuffer 是常用的 buffer 实现 。顾名思义，ListBuffe r依赖列表，支持高效地将它的元素转换成列表。而ArrayBuffer依赖数组，能快速地转换成数组。

# Set

Set 是不包含重复元素的可迭代对象。

不可变 Set 类的操作：

- 测试 
  - `xs contains x` 测试x是否是xs的元素。
  - `xs(x)` 与`xs contains x`相同。
  - `xs subsetOf ys`  测试xs是否是ys的子集。
- 加法： 
  - `xs + x`  包含xs中所有元素以及x的集合。
  - `xs + (x, y, z)`  包含xs中所有元素及附加元素的集合
  - `xs ++ ys`  包含xs中所有元素及ys中所有元素的集合
- 减法： 
  - `xs - x`  包含xs中除x以外的所有元素的集合。
  - `xs - x`  包含xs中除去给定元素以外的所有元素的集合。
  - `xs -- ys`  集合内容为：xs中所有元素，去掉ys中所有元素后剩下的部分。
  - `xs.empty`  与xs同类的空集合。
- 二进制操作：  
  - `xs & ys` 集合xs和ys的交集。
  - `xs intersect ys` 等同于 xs & ys。
  - `xs union ys` 等同于xs
  - `xs &~ ys`  集合xs和ys的差集。
  - `xs diff ys`  等同于 `xs &~ ys`。

可变 Set 类的操作

- 加法： 
  - `xs += x` 把元素x添加到集合xs中。该操作有副作用，它会返回左操作符，这里是xs自身。
  - `xs += (x, y, z)` 添加指定的元素到集合xs中，并返回xs本身。（同样有副作用）
  - `xs ++= ys` 添加集合ys中的所有元素到集合xs中，并返回xs本身。（表达式有副作用）
  - `xs add x`  把元素x添加到集合xs中，如集合xs之前没有包含x，该操作返回true，否则返回false。
- 移除： 
  - `xs -= x` 从集合xs中删除元素x，并返回xs本身。（表达式有副作用）
  - `xs -= (x, y, z)` 从集合xs中删除指定的元素，并返回xs本身。（表达式有副作用）
  - `xs --= ys` 从集合xs中删除所有属于集合ys的元素，并返回xs本身。（表达式有副作用）
  - `xs remove x` 从集合xs中删除元素x。如之前xs中包含了x元素，返回true，否则返回false。
  - `xs retain p` 只保留集合xs中满足条件p的元素。
  - `xs.clear()`  删除集合xs中的所有元素。
- 更新：
  - `xs(x) = b` （ 同 `xs.update(x, b)` ）参数b为布尔类型，如果值为true就把元素x加入集合xs，否则从集合xs中删除x。
- 克隆： 
  - `xs.clone`  产生一个与xs具有相同元素的可变集合。

与不变集合一样，可变集合也提供了`+`和`++`操作符来添加元素，`-`和`--`用来删除元素。但是这些操作在可变集合中通常很少使用，因为这些操作都要通过集合的拷贝来实现。可变集合提供了更有效率的更新方法，`+=`和`-=`。

`s += elem`，添加元素elem到集合s中，并返回产生变化后的集合作为运算结果。同样的，`s -= elem`执行从集合s中删除元素elem的操作，并返回产生变化后的集合作为运算结果。除了`+=`和`-=`之外还有从可遍历对象集合或迭代器集合中添加和删除所有元素的批量操作符`++=`和`--=`。

Set集合的两个特质是SortedSet和 BitSet。

## SortedSet

SortedSet 是指以特定的顺序（这一顺序可以在创建集合之初自由的选定）排列其元素（使用iterator或foreach）的集合。 SortedSet 的默认表示是有序二叉树，即左子树上的元素小于所有右子树上的元素。这样，一次简单的顺序遍历能按增序返回集合中的所有元素。Scala的类 `immutable.TreeSet` 使用红黑树实现，它在维护元素顺序的同时，也会保证二叉树的平衡，即叶节点的深度差最多为1。

创建一个空的 TreeSet ，可以先定义排序规则：

~~~scala
scala> val myOrdering = Ordering.fromLessThan[String](_ > _)
myOrdering: scala.math.Ordering[String] = scala.math.Ordering$$anon$9@6bd5a0fa
~~~

然后，用这一排序规则创建一个空的树集：

~~~scala
scala> TreeSet.empty(myOrdering)
res1: scala.collection.immutable.TreeSet[String] = TreeSet()
~~~

或者，你也可以不指定排序规则参数，只需要给定一个元素类型或空集合。在这种情况下，将使用此元素类型默认的排序规则。

~~~scala
scala> TreeSet.empty[String]
res2: scala.collection.immutable.TreeSet[String] = TreeSet()
~~~

如果通过已有的TreeSet来创建新的集合（例如，通过串联或过滤操作），这些集合将和原集合保持相同的排序规则。例如，

~~~scala
scala> res2 + ("one", "two", "three", "four")
res3: scala.collection.immutable.TreeSet[String] = TreeSet(four, one, three, two)
~~~

有序集合同样支持元素的范围操作。例如，range方法返回从指定起始位置到结束位置（不含结束元素）的所有元素，from方法返回大于等于某个元素的所有元素。调用这两种方法的返回值依然是有序集合。例如：

~~~scala
scala> res3 range ("one", "two")
res4: scala.collection.immutable.TreeSet[String] = TreeSet(one, three)
scala> res3 from "three"
res5: scala.collection.immutable.TreeSet[String] = TreeSet(three, two)
~~~

## Bitset

位集合是由单字或多字的紧凑位实现的非负整数的集合。其内部使用Long型数组来表示。第一个Long元素表示的范围为0到63，第二个范围为64到127，以此类推（值为0到127的非可变位集合通过直接将值存储到第一个或第两个Long字段的方式，优化掉了数组处理的消耗）。对于每个Long，如果有相应的值包含于集合中则它对应的位设置为1，否则该位为0。这里遵循的规律是，位集合的大小取决于存储在该集合的最大整数的值的大小。假如N是为集合所要表示的最大整数，则集合的大小就是N/64个长整形字，或者N/8个字节，再加上少量额外的状态信息字节。

因此当位集合包含的元素值都比较小时，它比其他的集合类型更紧凑。位集合的另一个优点是它的contains方法（成员测试）、+=运算（添加元素）、-=运算（删除元素）都非常的高效。

~~~scala
val bs = collection.mutable.BitSet()
bs += (1,3,5) // BitSet(1, 5, 3)
bs ++= List(7,9) // BitSet(1, 9, 7, 5, 3)
bs.clear // BitSet()
~~~

# Map

Map是一种可迭代的键值对结构（也称映射或关联）。Scala的Predef类提供了隐式转换，允许使用另一种语法：`key -> value`，来代替`(key, value)`。如：`Map("x" -> 24, "y" -> 25, "z" -> 26)` 等同于 `Map(("x", 24), ("y", 25), ("z", 26))`，却更易于阅读。

不可变Map类的操作:

- 查询： 
  - `ms get k`  返回一个Option，其中包含和键k关联的值。若k不存在，则返回None。
  - `ms(k)` （完整写法是`ms apply k`）返回和键k关联的值。若k不存在，则抛出异常。
  - `ms getOrElse (k, d) `返回和键k关联的值。若k不存在，则返回默认值d。
  - `ms contains k` 检查ms是否包含与键k相关联的映射。
  - `ms isDefinedAt k`  同contains。
- 添加及更新:  
  - `ms + (k -> v)` 返回一个同时包含ms中所有键值对及从k到v的键值对k -> v的新映射。
  - `ms + (k -> v, l -> w)` 返回一个同时包含ms中所有键值对及所有给定的键值对的新映射。
  - `ms ++ kvs` 返回一个同时包含ms中所有键值对及kvs中的所有键值对的新映射。
  - `ms updated (k, v)` 同`ms + (k -> v)`。
- 移除： 
  - `ms - k`  返回一个包含ms中除键k以外的所有映射关系的映射。
  - `ms - (k, 1, m)`  返回一个滤除了ms中与所有给定的键相关联的映射关系的新映射。
  - `ms -- ks`  返回一个滤除了ms中与ks中给出的键相关联的映射关系的新映射。
- 子容器： 
  - `ms.keys` 返回一个用于包含ms中所有键的iterable对象
  - `ms.keySet` 返回一个包含ms中所有的键的集合。
  - `ms.keyIterator`  返回一个用于遍历ms中所有键的迭代器。
  - `ms.values` 返回一个包含ms中所有值的iterable对象。
  - `ms.valuesIterator` 返回一个用于遍历ms中所有值的迭代器。
- 变换： 
  - `ms filterKeys p` 一个映射视图，其包含一些ms中的映射，且这些映射的键满足条件p。用条件谓词p过滤ms中所有的键，返回一个仅包含与过滤出的键值对的映射视图。
  - `ms mapValues f`  用f将ms中每一个键值对的值转换成一个新的值，进而返回一个包含所有新键值对的映射视图。

可变Map类中的操作：

- 添加及更新：
  - `ms(k) = v` （完整形式为`ms.update(x, v)`）。向映射ms中新增一个以k为键、以v为值的映射关系，ms先前包含的以k为值的映射关系将被覆盖。
  - `ms += (k -> v)`  向映射ms增加一个以k为键、以v为值的映射关系，并返回ms自身。
  - `ms += (k -> v, l -> w) ` 向映射ms中增加给定的多个映射关系，并返回ms自身。
  - `ms ++= kvs`  向映射ms增加kvs中的所有映射关系，并返回ms自身。
  - `ms put (k, v)` 向映射ms增加一个以k为键、以v为值的映射，并返回一个Option，其中可能包含此前与k相关联的值。
  - `ms getOrElseUpdate (k, d)` 如果ms中存在键k，则返回键k的值。否则向ms中新增映射关系`k -> v`并返回d。
- 移除： 
  - `ms -= k` 从映射ms中删除以k为键的映射关系，并返回ms自身。
  - `ms -= (k, l, m)` 从映射ms中删除与给定的各个键相关联的映射关系，并返回ms自身。
  - `ms --= ks` 从映射ms中删除与ks给定的各个键相关联的映射关系，并返回ms自身。
  - `ms remove k` 从ms中移除以k为键的映射关系，并返回一个Option，其可能包含之前与k相关联的值。
  - `ms retain p` 仅保留ms中键满足条件谓词p的映射关系。
  - `ms.clear()`  删除ms中的所有映射关系
- 变换： 
  - `ms transform f`  以函数f转换ms中所有键值对，transform中参数f的类型是`(A, B) => B`，即对ms中的所有键值对调用f，得到一个新的值，并用该值替换原键值对中的值。
- 克隆： 
  - `ms.clone`  返回一个新的可变映射，其中包含与ms相同的映射关系。
  
 Map的添加和删除操作与Set的相关操作相同。同Set操作一样，可变映射也支持非破坏性修改操作`+`、`-`、和 `updated`。但是这些操作涉及到可变映射的复制，因此较少被使用。而利用两种变形`m(key) = value`和`m += (key -> value)`， 我们可以“原地”修改可变映射m。此外，存还有一种变形`m put (key, value)`，该调用返回一个Option值，其中包含此前与键相关联的值，如果不存在这样的值，则返回None。

 同步的Map，使用SychronizedMap，同步Set，使用SynchronizedSet。

`不可变Map`的定义：

~~~scala
//创建map并指定类型
scala> var m1 = Map[Int, Int]()
m: scala.collection.immutable.Map[Int,Int] = Map()  //缺醒是不可变map

//创建map并初始化
scala> var m2 = Map(1->100, 2->200)
m: scala.collection.immutable.Map[Int,Int] = Map(1 -> 100, 2 -> 200)

scala> var m3 = Map((1,100), (2,200))
m: scala.collection.immutable.Map[Int,Int] = Map(1 -> 100, 2 -> 200)

//创建map并指定类型、初始化
scala> val m4:Map[Int,String] = Map(1->"a",2->"b")
m4: Map[Int,String] = Map(1 -> a, 2 -> b)
~~~

读取元素：

~~~scala
scala> m3(1)
res0: Int = 100

scala> m3.get(1)
res1: Option[Int] = Some(100)

scala> m3.getOrElse(4, -1)
res2: Int = -1

//读取所有元素
scala> for(e<-m3) println(e._1 + ": " + e._2)
1: 100
2: 200
3: 300

scala> m3.foreach(e=>println(e._1 + ": " + e._2))
1: 100
2: 200
3: 300

scala> for ((k,v)<-m3) println(k + ": " + v)
1: 100
2: 200
3: 300
~~~

也可以进行filter、map操作：

~~~scala
scala> m3 filter (e=>e._1>1)
res46: scala.collection.immutable.Map[Int,Int] = Map(2 -> 200, 3 -> 300)

scala> m3 filterKeys (_>1)
res47: scala.collection.immutable.Map[Int,Int] = Map(2 -> 200, 3 -> 300)

scala> m3.map(e=>(e._1*10, e._2))
res48: scala.collection.immutable.Map[Int,Int] = Map(10 -> 100, 20 -> 200, 30 -> 300)

scala> m3 map (e=>e._2)
res49: scala.collection.immutable.Iterable[Int] = List(100, 200, 300)

//相当于：
scala> m3.values.toList
res50: List[Int] = List(100, 200, 300)

//按照key来取对应的value值：
scala> 2 to 100 flatMap m3.get
res52: scala.collection.immutable.IndexedSeq[Int] = Vector(200, 300)
~~~

增加、删除、更新：

~~~scala
//Map本身不可改变，即使定义为var，更新操作也是返回一个新的不可变Map
scala> var m4 = Map(1->100)
m4: scala.collection.immutable.Map[Int,Int] = Map(1 -> 100)

scala> m4 += (2->200)  // m4指向新的(1->100,2->200), (1->100)应该被回收

//另一种更新方式
scala> m4.updated(1,1000)
res7: scala.collection.immutable.Map[Int,Int] = Map(1 -> 1000, 2 -> 200)

//增加多个元素：
scala> Map(1->100,2->200) + (3->300, 4->400)
res8: scala.collection.immutable.Map[Int,Int] = Map(1 -> 100, 2 -> 200, 3 -> 300, 4 -> 400)

//删除元素：
scala> Map(1->100,2->200,3->300) - (2,3) 
res9: scala.collection.immutable.Map[Int,Int] = Map(1 -> 100)

scala> Map(1->100,2->200,3->300) -- List(2,3) 
res10: scala.collection.immutable.Map[Int,Int] = Map(1 -> 100)

//合并Map：
scala> Map(1->100,2->200) ++ Map(3->300) 
res11: scala.collection.immutable.Map[Int,Int] = Map(1 -> 100, 2 -> 200, 3 -> 300)
~~~

`对于可变Map`的定义和操作：

~~~scala
scala> val map = scala.collection.mutable.Map[String, Any]()
map: scala.collection.mutable.Map[String,Any] = Map()

// 增加元素
scala> map("k1")=100

// 增加元素
scala> map += "k2"->"v2"
res13: map.type = Map(k2 -> v2, k1 -> 100)

//判断元素值
scala> map("k2")=="v2"
res14: Boolean = true

scala> map.get("k2")==Some("v2")
res15: Boolean = true

scala> map.get("k3")==None
res16: Boolean = true

scala> val mm = collection.mutable.Map(1->100,2->200,3->300)
mm: scala.collection.mutable.Map[Int,Int] = Map(2 -> 200, 1 -> 100, 3 -> 300)

//有则取之，无则加之
scala> mm getOrElseUpdate (3,-1)
res17: Int = 300

scala> mm getOrElseUpdate (4,-1)
res18: Int = -1

//删除元素
scala> mm -= 1
res19: mm.type = Map(2 -> 200, 4 -> -1, 3 -> 300)

//删除元素
scala> mm -= (2,3)
res20: mm.type = Map(4 -> -1)

//添加一个Map
scala> mm += (1->100,2->200,3->300)
res21: mm.type = Map(2 -> 200, 4 -> -1, 1 -> 100, 3 -> 300)

//删除元素
scala> mm --= List(1,2)
res22: mm.type = Map(4 -> -1, 3 -> 300)

//删除元素
scala> mm remove 1
res23: Option[Int] = None

scala> mm += (1->100,2->200,3->300)
res24: mm.type = Map(2 -> 200, 4 -> -1, 1 -> 100, 3 -> 300)

scala> mm.retain((x,y) => x>1)
res25: mm.type = Map(2 -> 200, 4 -> -1, 3 -> 300)

//转换操作
scala> mm transform ((x,y)=> 0)
res26: mm.type = Map(2 -> 0, 4 -> 0, 3 -> 0)

scala> mm transform ((x,y)=> x*10)
res27: mm.type = Map(2 -> 20, 4 -> 40, 3 -> 30)

scala> mm transform ((x,y)=> y+3)
res28: mm.type = Map(2 -> 23, 4 -> 43, 3 -> 33)
~~~

## ListMap

`ListMap被用来表示一个保存键-值映射的链表`。一般情况下，ListMap操作都**需要遍历整个列表**，所以操作的运行时间也同列表长度成线性关系。实际上ListMap在Scala中很少使用，因为标准的不可变映射通常速度会更快。唯一的例外是，在构造映射时由于某种原因，链表中靠前的元素被访问的频率大大高于其他的元素。

~~~scala
scala> val map = scala.collection.immutable.ListMap(1->"one", 2->"two")
map: scala.collection.immutable.ListMap[Int,java.lang.String] = 
   Map(1 -> one, 2 -> two)
scala> map(2)
res30: String = "two"
~~~

# 不可变Seq实体类

## List

列表List是一种有限的不可变序列式。

列表定义：

~~~scala
val list:List[Int] = List(1,3,4,5,6) // 或者 List(1 to 6:_*)
val list1 = List("a","b","c","d") // 或者 List('a' to 'd':_*) map (_.toString)
~~~

合并：

~~~scala
val list2 = "a"::"b"::"c"::Nil // Nil是必须的
val list3 = "begin" :: list2 // list2不变，只能加在头，不能加在尾

//多个List合并用++，也可以用:::(不如++)
val list4 = list2 ++ "end" ++ Nil
val list4 = list2 ::: "end" :: Nil // 相当于 list2 ::: List("end")
~~~

建议定义方式：

~~~scala
val head::body = List(4,"a","b","c","d")
// head: Any = 4
// body: List[Any] = List(a, b, c, d)
val a::b::c = List(1,2,3)
// a: Int = 1
// b: Int = 2
// c: List[Int] = List(3)
~~~

ListBuffer是可变的：

~~~scala
val lb = collection.mutable.ListBuffer[Int]()
lb += (1,3,5,7)
lb ++= List(9,11) // ListBuffer(1, 3, 5, 7, 9, 11)
lb.toList // List(1, 3, 5, 7, 9, 11)
lb.clear // ListBuffer()
~~~

## Stream

流Stream与List很相似，只不过其中的每一个元素都经过了一些简单的计算处理。也正是因为如此，stream结构可以无限长。只有那些被要求的元素才会经过计算处理，除此以外stream结构的性能特性与List基本相同。

鉴于List通常使用`::`运算符来进行构造，stream使用外观上很相像的`#::`。这里用一个包含整数1，2和3的stream来做一个简单的例子：

~~~scala
scala> val str = 1 #:: 2 #:: 3 #:: Stream.empty   //同List的构造，最后一个必须为空
str: scala.collection.immutable.Stream[Int] = Stream(1, ?)
~~~

该stream的头结点是1，尾是2和3，尾部并没有被打印出来，因为还没有被计算。stream被特别定义为懒惰计算，并且**stream的toString方法很谨慎的设计为不去做任何额外的计算**。

下面给出一个稍复杂些的例子。这里讲一个以两个给定的数字为起始的斐波那契数列转换成stream。斐波那契数列的定义是，序列中的每个元素等于序列中在它之前的两个元素之和。

~~~scala
scala> def fibFrom(a: Int, b: Int): Stream[Int] = a #:: fibFrom(b, a + b)
fibFrom: (a: Int,b: Int)Stream[Int]
~~~

这个函数看起来比较简单。序列中的第一个元素显然是a，其余部分是以b和位于其后的a+b为开始斐波那契数列。这段程序最大的亮点是在对序列进行计算的时候避免了无限递归。如果函数中使用`::`来替换`#::`，那么之后的每次调用都会产生另一次新的调用，从而导致无限递归。在此例中，由于使用了`#::`，等式右值中的调用在需要求值之前都不会被展开。这里尝试着打印出以1，1开头的斐波那契数列的前几个元素：

~~~scala
scala> val fibs = fibFrom(1, 1).take(7)
fibs: scala.collection.immutable.Stream[Int] = Stream(1, ?)
scala> fibs.toList
res9: List[Int] = List(1, 1, 2, 3, 5, 8, 13)
~~~

Stream相当于lazy List，避免在中间过程中生成不必要的集合。

例子1：

~~~scala
Range(1,50000000).filter (_ % 13==0)(1) // 26, 但很慢，需要大量内存
Stream.range(1,50000000).filter(_%13==0)(1) // 26，很快，只计算最终结果需要的内容
~~~

**注意：**第一个版本在filter后生成一个中间集合，大小为50000000/13；而后者不生成此中间集合，只计算到26即可。
 
例子2：

~~~scala
(1 to 100).map(i=> i*3+7).filter(i=> (i%10)==0).sum // map和filter生成两个中间collection
(1 to 100).toStream.map(i=> i*3+7).filter(i=> (i%10)==0).sum
~~~

## Vector

`向量Vector是用来解决列表不能高效的随机访问的一种结构`。Vector结构能够在“更高效”的固定时间内**访问到列表中的任意元素**。虽然这个时间会比访问头结点或者访问某数组元素所需的时间长一些，但至少这个时间也是个常量。因此，使用Vector的算法不必仅是小心的处理数据结构的头结点。由于可以快速修改和访问任意位置的元素，所以对Vector结构做写操作很方便。

Seq的缺省实现是List：

~~~scala
scala> Seq(1,2,3)
res84: Seq[Int] = List(1, 2, 3)
~~~

IndexSeq的缺省实现是Vector:

~~~scala
scala> IndexedSeq(1,2,3)
res85: IndexedSeq[Int] = Vector(1, 2, 3)
~~~

Vector类型的构建和修改与其他的序列结构基本一样。

~~~scala
scala> val vec = scala.collection.immutable.Vector.empty
vec: scala.collection.immutable.Vector[Nothing] = Vector()
scala> val vec2 = vec :+ 1 :+ 2
vec2: scala.collection.immutable.Vector[Int] = Vector(1, 2)
scala> val vec3 = 100 +: vec2
vec3: scala.collection.immutable.Vector[Int] = Vector(100, 1, 2)
scala> vec3(0)
res1: Int = 100
~~~

Vector结构通常被表示成具有高分支因子的树（树或者图的分支因子是指数据结构中每个节点的子节点数目）。每一个树节点包含最多32个vector元素或者至多32个子树节点。包含最多32个元素的vector可以表示为一个单一节点，而一个间接引用则可以用来表示一个包含至多32*32=1024个元素的vector。从树的根节点经过两跳到达叶节点足够存下有2的15次方个元素的vector结构，经过3跳可以存2的20次方个，4跳2的25次方个，5跳2的30次方个。所以对于一般大小的vector数据结构，一般经过至多5次数组访问就可以访问到指定的元素。这也就是我们之前所提及的随机数据访问时“运行时间的相对高效”。

由于Vectors结构是不可变的，所以您不能通过修改vector中元素的方法来返回一个新的vector。尽管如此，您仍可以通过update方法从一个单独的元素中创建出区别于给定数据结构的新vector结构：

~~~scala
scala> val vec = Vector(1, 2, 3)
vec: scala.collection.immutable.Vector[Int] = Vector(1, 2, 3)
scala> vec updated (2, 4)
res0: scala.collection.immutable.Vector[Int] = Vector(1, 2, 4)
scala> vec
res1: scala.collection.immutable.Vector[Int] = Vector(1, 2, 3)
~~~

从上面例子的最后一行我们可以看出，update方法的调用并不会改变vec的原始值。与元素访问类似，vector的update方法的运行时间也是“相对高效的固定时间”。对vector中的某一元素进行update操作可以通过从树的根节点开始拷贝该节点以及每一个指向该节点的节点中的元素来实现。这就意味着一次update操作能够创建1到5个包含至多32个元素或者子树的树节点。当然，这样做会比就地更新一个可变数组败家很多，但比起拷贝整个vector结构还是绿色环保了不少。

由于vector在快速随机选择和快速随机更新的性能方面做到很好的平衡，所以**它目前正被用作不可变索引序列的默认实现方式**。

~~~scala
scala> collection.immutable.IndexedSeq(1, 2, 3)
res2: scala.collection.immutable.IndexedSeq[Int] = Vector(1, 2, 3)
~~~

## Stack

如果您想要实现一个后入先出的序列，那您可以使用Stack。您可以使用push向栈中压入一个元素，用pop从栈中弹出一个元素，用top查看栈顶元素而不用删除它。所有的这些操作都仅仅耗费固定的运行时间。

这里提供几个简单的stack操作的例子：

~~~scala
scala> val stack = scala.collection.immutable.Stack.empty
stack: scala.collection.immutable.Stack[Nothing] = Stack()
scala> val hasOne = stack.push(1)
hasOne: scala.collection.immutable.Stack[Int] = Stack(1)
scala> stack
stack: scala.collection.immutable.Stack[Nothing] = Stack()
scala> hasOne.top
res20: Int = 1
scala> hasOne.pop
res21: scala.collection.immutable.Stack[Int] = Stack()
~~~

不可变stack一般很少用在Scala编程中，因为List结构已经能够覆盖到它的功能：push操作同List中的`::`基本相同，pop则对应着tail。

## Queue

Queue是一种与stack很相似的数据结构，除了与stack的后入先出不同，Queue结构的是先入先出的。

## Range

Range表示的是一个有序的等差整数数列。

创建 Range：

~~~scala
scala> Range(0, 5)
res58: scala.collection.immutable.Range = Range(0, 1, 2, 3, 4)

//等同于：
scala> 0 until 5
res59: scala.collection.immutable.Range = Range(0, 1, 2, 3, 4)

//等同于：
scala> 0 to 4
res60: scala.collection.immutable.Range.Inclusive = Range(0, 1, 2, 3, 4)
~~~

两个Range相加：

~~~scala
scala> ('0' to '9') ++ ('A' to 'Z')
res61: scala.collection.immutable.IndexedSeq[Char] = Vector(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z)
~~~

Range和List、Vector转换：

~~~scala
scala> 1 to 5 toList
warning: there were 1 feature warning(s); re-run with -feature for details
res62: List[Int] = List(1, 2, 3, 4, 5)

//相当与：
scala> List(1 to 5:_*)
res63: List[Int] = List(1, 2, 3, 4, 5)

//或者：
scala> Vector(1 to 5: _*)
res64: scala.collection.immutable.Vector[Int] = Vector(1, 2, 3, 4, 5)
~~~

# Array

数组定义：

~~~scala
val list1 = new Array[String](0) // Array()
val list2 = new Array[String](3) // Array(null, null, null)
val list3:Array[String] = new Array(3) // // Array(null, null, null)
val list1 = Array("a","b","c","d") // 相当于Array.apply("a","b","c","d")

//定义一个类型为Any的Array：
val aa = Array[Any](1, 2)
val aa: Array[Any] = Array(1, 2)
val aa: Array[_] = Array(1, 2)
 
Array (1,3,5,7,9,11)
Array[Int](1 to 11 by 2:_*)
~~~

与Array对应的可变ArrayBuffer：

~~~scala
val ab = collection.mutable.ArrayBuffer[Int]()
ab += (1,3,5,7)
ab ++= List(9,11) // ArrayBuffer(1, 3, 5, 7, 9, 11)
ab toArray // Array (1, 3, 5, 7, 9, 11)
ab clear // ArrayBuffer()
~~~

# Tuple

定义方式：

~~~scala
val t1 = ("a","b","c")
var t2 = ("a", 123, 3.14, new Date())
val (a,b,c) = (2,4,6)
~~~

最简单的Tuple：

~~~scala
1->"hello world"
~~~

和下面的写法是等价的：

~~~scala
(1, "hello world")
~~~

# 参考资料

- [Scala 课堂](http://twitter.github.io/scala_school/zh_cn/index.html)
- [Scala 2.8+ Handbook](http://qiujj.com/static/Scala-Handbook.htm)
- [CSDN CODE翻译的Scala容器库(Scala’s Collections Library)](https://code.csdn.net/DOC_Scala/chinese_scala_offical_document/file/Introduction.md#anchor_0)
