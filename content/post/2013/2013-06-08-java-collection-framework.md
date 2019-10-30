---
layout: post

title: Java笔记：集合框架实现原理
date: 2013-06-08T00:00:00+08:00

description: Java集合是java提供的工具包，包含了常用的数据结构：集合、链表、队列、栈、数组、映射等。Java集合主要可以划分为4个部分：List列表、Set集合、Map映射、工具类(Iterator迭代器、Enumeration枚举类、Arrays和Collections)。

keywords: java

categories: [java]

tags: [java,collection]

---

> 这篇文章是对<http://www.cnblogs.com/skywang12345/category/455711.html>中java集合框架相关文章的一个总结，在此对[原作者](http://www.cnblogs.com/skywang12345)的辛勤整理表示感谢。

Java集合是java提供的工具包，包含了常用的数据结构：集合、链表、队列、栈、数组、映射等。Java集合工具包位置是`java.util.*`

Java集合主要可以划分为4个部分：List列表、Set集合、Map映射、工具类(Iterator迭代器、Enumeration枚举类、Arrays和Collections)。

Java集合工具包框架图(如下)：

<a href="http://images.cnitblog.com/blog/497634/images09/08171028-a5e372741b18431591bb577b1e1c95e6.jpg"><img style="display: block; margin-left: auto; margin-right: auto;" src="http://images.cnitblog.com/blog/497634/images09/08171028-a5e372741b18431591bb577b1e1c95e6.jpg" alt="" width="900" height="360"></a>

Collection是一个接口，是以对象为单位来管理元素的。有两个子接口：List接口和Set接口：

- List接口：元素是有顺序（下标），可以重复。有点像数组，可以用迭代器（Iterator）和数组遍历集合。List的实现类有LinkedList、ArrayList、Vector、Stack。
- Set接口：无顺序，不可以重复（内容不重复，而非地址不重复）。只能用迭代器（Iterator）遍历集合。Set接口里本身无方法，方法都是从父接口Collection里继承的。Set的实现类有HastSet和TreeSet。HashSet依赖于HashMap，它实际上是通过HashMap实现的；TreeSet依赖于TreeMap，它实际上是通过TreeMap实现的。

Map:对应一个键对象和一个值对象，可以根据key找value。AbstractMap是个抽象类，它实现了Map接口中的大部分API。而HashMap，TreeMap，WeakHashMap都是继承于AbstractMap。Hashtable虽然继承于Dictionary，但它实现了Map接口。

Iterator用于遍历集合，Enumeration是JDK 1.0引入的抽象类，只能在Hashtable、Vector、Stack中使用。

Arrays和Collections是两个操作数组和集合的工具类，提供一些静态方法。

# 1. List
## 1.1 ArrayList

ArrayList 是一个数组列表，相当于动态数组。与Java中的数组相比，它的容量能动态增长。它继承于AbstractList，实现了List、RandomAccess、Cloneable、java.io.Serializable这些接口。

### 数据结构

通过数组保存数据，数组初始大小为10，也可以通过构造函数修改数组初始大小。

当ArrayList容量不足以容纳全部元素时，ArrayList会重新设置容量：新的容量=“(原始容量x3)/2 + 1”。

### 访问数据

当添加和删除元素时，需要移动数组中得元素；当获取元素时，只需要通过数组的索引返回元素，故`查询快，增删慢`。

ArrayList中的方法没有加同步锁，故`线程不安全`。

### 遍历方式

1）通过Iterator去遍历

~~~java
Integer value = null;
Iterator iter = list.iterator();
while (iter.hasNext()) {
    value = (Integer)iter.next();
}
~~~

2）随机访问，通过索引值去遍历

~~~java
Integer value = null;
int size = list.size();
for(int i=0; i<size; i++){
 value = (Integer)list.get(i);        
}
~~~

3）for循环遍历

~~~java
Integer value = null;
for (Integer integ:list) {
    value = integ;
}
~~~

性能比较：


## 1.2 Vector

Vector 是矢量列表，它是JDK1.0版本添加的类。继承于AbstractList，实现了List, RandomAccess, Cloneable这些接口。

### 数据结构

通过数组保存数据，数组初始大小为10，容量增加系数为0，也可以通过构造函数修改数组初始大小。

当容量不足以容纳全部元素时，若容量增加系数大于0，则将容量的值增加“容量增加系数”；否则，将容量大小增加一倍。

### 访问数据

当添加和删除元素时，需要移动数组中得元素；当获取元素时，只需要通过数组的索引返回元素，故`查询快，增删慢`。

方法没有加同步锁，故`线程不安全`。

### 遍历方式

- 1）通过Iterator去遍历
- 2）随机访问，通过索引值去遍历
- 3）foreach循环遍历
- 4）Enumeration遍历

性能比较：


## 1.3 Stack

Stack是栈。它的特性是：先进后出(FILO, First In Last Out)。

java工具包中的Stack是继承于Vector的，由于Vector是通过数组实现的，这就意味着，Stack也是通过数组实现的，而非链表。

### 数据结构

和 Vector 一致，Stack的push、peek、和pull方法都是对数组末尾的元素进行操作。

## 1.4 LinkedList

LinkedList 是一个继承于AbstractSequentialList的双向链表。它也可以被当作堆栈、队列或双端队列进行操作。它实现了List、Deque、Cloneable、java.io.Serializable接口。

### 数据结构

LinkedList的本质是双向链表。

- LinkedList继承于AbstractSequentialList，并且实现了Dequeue接口。 
- LinkedList包含两个重要的成员：header 和 size。
 - header是双向链表的表头，它是双向链表节点所对应的类Entry的实例。Entry中包含成员变量： previous, next, element。其中，previous是该节点的上一个节点，next是该节点的下一个节点，element是该节点所包含的值。 
 - size是双向链表中节点的个数。

 LinkedList不存在容量不足的问题。

### 访问数据

当添加和删除元素时，只需要将新的元素插入指定位置之前，然后修改链表的指向；当获取元素时（`get(int location)`），会比较“location”和“双向链表长度的1/2”；若前者大，则从链表头开始往后查找，直到location位置；否则，从链表末尾开始先前查找，直到location位置。故`查询慢，增删快`。

方法没有加同步锁，故`线程不安全`。

### 遍历方式

LinkedList支持多种遍历方式。建议不要采用随机访问的方式去遍历LinkedList，而采用foreach逐个遍历的方式。

## 1.5 总结

### 应用场景

如果涉及到“栈”、“队列”、“链表”等操作，应该考虑用List，具体的选择哪个List，根据下面的标准来取舍。

- 对于需要快速插入，删除元素，应该使用LinkedList。
- 对于需要快速随机访问元素，应该使用ArrayList。
- 对于“单线程环境” 或者 “多线程环境，但List仅仅只会被单个线程操作”，此时应该使用非同步的类(如ArrayList)；对于“多线程环境，且List可能同时被多个线程操作”，此时，应该使用同步的类(如Vector)。

### Vector和ArrayList

相同点：

- 都继承于AbstractList，并且实现List接口
- 都实现了RandomAccess和Cloneable接口
- 都是通过数组实现的，本质上都是动态数组，默认数组容量是10
- 都支持Iterator和listIterator遍历

不同点：

- ArrayList是非线程安全，而Vector是线程安全的
- ArrayList支持序列化，而Vector不支持
- 容量增加方式不同，Vector默认增长为原来一培，而ArrayList却是原来的一半+1
- Vector支持通过Enumeration去遍历，而List不支持

# 2. Map

Map 是映射接口，Map中存储的内容是键值对(key-value)。 

AbstractMap 是继承于Map的抽象类，它实现了Map中的大部分API。其它Map的实现类可以通过继承AbstractMap来减少重复编码。 

SortedMap 是继承于Map的接口。SortedMap中的内容是排序的键值对，排序的方法是通过比较器(Comparator)。 

NavigableMap 是继承于SortedMap的接口。相比于SortedMap，NavigableMap有一系列的导航方法；如"获取大于/等于某对象的键值对"、“获取小于/等于某对象的键值对”等等。  

TreeMap 继承于AbstractMap，且实现了NavigableMap接口；因此，TreeMap中的内容是“有序的键值对” 

HashMap 继承于AbstractMap，但没实现NavigableMap接口；因此，HashMap的内容是“键值对，但不保证次序” 

Hashtable 虽然不是继承于AbstractMap，但它继承于Dictionary(Dictionary也是键值对的接口)，而且也实现Map接口；因此，Hashtable的内容也是“键值对，也不保证次序”。但和HashMap相比，Hashtable是线程安全的，而且它支持通过Enumeration去遍历。

WeakHashMap 继承于AbstractMap。它和HashMap的键类型不同，WeakHashMap的键是“弱键”。 

## 2.1 HashMap

HashMap 是一个散列表，它存储的内容是键值对(key-value)映射。

HashMap 继承于AbstractMap，实现了Map、Cloneable、java.io.Serializable接口。

HashMap 的实现不是同步的，这意味着它不是线程安全的。它的key、value都可以为null。此外，HashMap中的映射不是有序的。

### 数据结构

HashMap是通过"拉链法"实现的哈希表。它包括几个重要的成员变量：table、size、threshold、loadFactor、modCount。

- table是一个Entry[]数组类型，而Entry实际上就是一个单向链表。哈希表的"key-value键值对"都是存储在Entry数组中的。 
- size是HashMap的大小，它是HashMap保存的键值对的数量。 
- threshold是HashMap的阈值，用于判断是否需要调整HashMap的容量。threshold的值="容量*加载因子"，当HashMap中存储数据的数量达到threshold时，就需要将HashMap的容量加倍。
-loadFactor就是加载因子。 
- modCount是用来实现fail-fast机制的。

HashMap中的key-value都是存储在 Entry ç数组中的，而 Entry 实际上就是一个单向链表。

影响HashMap性能的有两个参数：初始容量(initialCapacity) 和加载因子(loadFactor)。

容量是哈希表中桶的数量，初始容量只是哈希表在创建时的容量，默认值为16。

加载因子是哈希表在其容量自动增加之前可以达到多满的一种尺度。当哈希表中的条目数超出了加载因子与当前容量的乘积时，则要对该哈希表进行 rehash 操作（即重建内部数据结构），从而哈希表将具有大约两倍的桶数。

通常，默认加载因子是 0.75, 这是在时间和空间成本上寻求一种折衷。加载因子过高虽然减少了空间开销，但同时也增加了查询成本（在大多数 HashMap 类的操作中，包括 get 和 put 操作，都反映了这一点）。在设置初始容量时应该考虑到映射中所需的条目数及其加载因子，以便最大限度地减少 rehash 操作次数。如果初始容量大于最大条目数除以加载因子，则不会发生 rehash 操作。

### 访问数据

当get（`get(Object key)`）数据时，先通过key得到一个hash值，然后调用`indexFor(hash, table.length)`方法得到table数组中得索引值，其次再通过索引得到数组中得 Entry 对象，最后遍历 Entry 对象，判断key和hash是否相等，如果相等则返回该Entry的value属性值。

当put（`put(K key, V value)`）数据时，若“key为null”，则将该键值对添加到table[0]中；若“key不为null”，则计算该key的哈希值，然后将其添加到该哈希值对应的链表中； 若“该key”对应的键值对已经存在，则用新的value取代旧的value。然后退出；若“该key”对应的键值对不存在，则将“key-value”添加到table中


### 遍历方式

- 遍历HashMap的键值对
- 遍历HashMap的键
- 遍历HashMap的值

## 2.2 Hashtable

和HashMap一样，Hashtable 也是一个散列表，它存储的内容是键值对(key-value)映射。
Hashtable 继承于Dictionary，实现了Map、Cloneable、java.io.Serializable接口。
Hashtable 的函数都是同步的，这意味着它是线程安全的。它的key、value都不可以为null。此外，Hashtable中的映射不是有序的。

Hashtable 的实例有两个参数影响其性能：初始容量 和 加载因子。

容量是哈希表中桶 的数量，初始容量就是哈希表创建时的容量，默认值为11。、

加载因子 是对哈希表在其容量自动增加之前可以达到多满的一个尺度。初始容量和加载因子这两个参数只是对该实现的提示。关于何时以及是否调用 rehash 方法的具体细节则依赖于该实现。

通常，默认加载因子是 0.75,这是在时间和空间成本上寻求一种折衷。加载因子过高虽然减少了空间开销，但同时也增加了查找某个条目的时间（在大多数 Hashtable 操作中，包括 get 和 put 操作，都反映了这一点）。

### 数据结构

和HashMap一样，Hashtable也是一个散列表，它也是通过“拉链法”解决哈希冲突的。

Hashtable里的方法是同步的，故其是线程安全的。

## 2.3 TreeMap

TreeMap 是一个有序的key-value集合，基于红黑树（Red-Black tree）实现。该映射根据其键的自然顺序进行排序，或者根据创建映射时提供的 Comparator 进行排序，具体取决于使用的构造方法。

TreeMap的基本操作 containsKey、get、put 和 remove 的时间复杂度是 log(n) 。

另外，TreeMap是非同步的。 它的iterator 方法返回的迭代器是fail-fastl的。

### 数据结构

TreeMap的本质是R-B Tree(红黑树)，它包含几个重要的成员变量：root、size、comparator。

- root 是红黑数的根节点。它是Entry类型，Entry是红黑数的节点，它包含了红黑数的6个基本组成成分：key(键)、value(值)、left(左孩子)、right(右孩子)、parent(父节点)、color(颜色)。Entry节点根据key进行排序，Entry节点包含的内容为value。 
- 红黑数排序时，根据Entry中的key进行排序；Entry中的key比较大小是根据比较器comparator来进行判断的。
- size是红黑数中节点的个数。

要彻底理解TreeMap，需要先理解红黑树。参考文章：[红黑树(一)之 原理和算法详细介绍](http://www.cnblogs.com/skywang12345/p/3245399.html)

### 遍历方式

- 遍历HashMap的键值对
- 遍历HashMap的键
- 遍历HashMap的值

## 2.4 WeakHashMap

WeakHashMap 继承于AbstractMap，实现了Map接口。和HashMap一样，WeakHashMap 也是一个散列表，它存储的内容也是键值对(key-value)映射，而且键和值都可以是null。

不过WeakHashMap的键是“弱键”。在 WeakHashMap 中，当某个键不再正常使用时，会被从WeakHashMap中被自动移除。更精确地说，对于一个给定的键，其映射的存在并不阻止垃圾回收器对该键的丢弃，这就使该键成为可终止的，被终止，然后被回收。某个键被终止时，它对应的键值对也就从映射中有效地移除了。

这个“弱键”的原理呢？大致上就是，通过WeakReference和ReferenceQueue实现的。 WeakHashMap的key是“弱键”，即是WeakReference类型的；ReferenceQueue是一个队列，它会保存被GC回收的“弱键”。实现步骤是：

- (01) 新建WeakHashMap，将“键值对”添加到WeakHashMap中。实际上，WeakHashMap是通过数组table保存Entry(键值对)；每一个Entry实际上是一个单向链表，即Entry是键值对链表。
- (02) 当某“弱键”不再被其它对象引用，并被GC回收时。在GC回收该“弱键”时，这个“弱键”也同时会被添加到ReferenceQueue(queue)队列中。
- (03) 当下一次我们需要操作WeakHashMap时，会先同步table和queue。table中保存了全部的键值对，而queue中保存被GC回收的键值对；同步它们，就是删除table中被GC回收的键值对。

这就是“弱键”如何被自动从WeakHashMap中删除的步骤了。

### 数据结构

WeakHashMap和HashMap都是通过”拉链法“实现的散列表。它们的源码绝大部分内容都一样，这里就只是对它们不同的部分就是说明。

WeakReference是“弱键”实现的哈希表。它这个“弱键”的目的就是：实现对“键值对”的动态回收。当“弱键”不再被使用到时，GC会回收它，WeakReference也会将“弱键”对应的键值对删除。

“弱键”是一个“弱引用(WeakReference)”，在Java中，WeakReference和ReferenceQueue 是联合使用的。在WeakHashMap中亦是如此：如果弱引用所引用的对象被垃圾回收，Java虚拟机就会把这个弱引用加入到与之关联的引用队列中。 接着，WeakHashMap会根据“引用队列”，来删除“WeakHashMap中已被GC回收的‘弱键’对应的键值对”。

## 2.5 总结

- HashMap 是基于“拉链法”实现的散列表。一般用于单线程程序中。
- Hashtable 也是基于“拉链法”实现的散列表。它一般用于多线程程序中。
- WeakHashMap 也是基于“拉链法”实现的散列表，它一般也用于单线程程序中。相比HashMap，WeakHashMap中的键是“弱键”，当“弱键”被GC回收时，它对应的键值对也会被从WeakHashMap中删除；而HashMap中的键是强键。
- TreeMap 是有序的散列表，它是通过红黑树实现的。它一般用于单线程中存储有序的映射。

### HashMap和Hashtable异同

相同点：

- 都是存储“键值对(key-value)”的散列表，而且都是采用拉链法实现的。存储的思想都是：通过table数组存储，数组的每一个元素都是一个Entry；而一个Entry就是一个单向链表，Entry链表中的每一个节点就保存了key-value键值对数据。
- 添加key-value键值对：首先，根据key值计算出哈希值，再计算出数组索引(即，该key-value在table中的索引)。然后，根据数组索引找到Entry(即，单向链表)，再遍历单向链表，将key和链表中的每一个节点的key进行对比。若key已经存在Entry链表中，则用该value值取代旧的value值；若key不存在Entry链表中，则新建一个key-value节点，并将该节点插入Entry链表的表头位置。
- 删除key-value键值对：删除键值对，相比于“添加键值对”来说，简单很多。首先，还是根据key计算出哈希值，再计算出数组索引(即，该key-value在table中的索引)。然后，根据索引找出Entry(即，单向链表)。若节点key-value存在与链表Entry中，则删除链表中的节点即可。

不同点：

- 继承和实现方式不同。HashMap 继承于AbstractMap，实现了Map、Cloneable、java.io.Serializable接口；Hashtable 继承于Dictionary，实现了Map、Cloneable、java.io.Serializable接口。
- 线程安全不同。Hashtable的几乎所有函数都是同步的，即它是线程安全的，支持多线程，而HashMap的函数则是非同步的，它不是线程安全的。
- 对null值的处理不同。HashMap的key、value都可以为null，Hashtable的key、value都不可以为null。
- 支持的遍历方式不同。HashMap只支持Iterator(迭代器)遍历，而Hashtable支持Iterator(迭代器)和Enumeration(枚举器)两种方式遍历。
- 通过Iterator迭代器遍历时，遍历的顺序不同。HashMap是“从前向后”的遍历数组；再对数组具体某一项对应的链表，从表头开始进行遍历，Hashtabl是“从后往前”的遍历数组；再对数组具体某一项对应的链表，从表头开始进行遍历。
- 容量的初始值 和 增加方式都不一样。HashMap默认的容量大小是16；增加容量时，每次将容量变为“原始容量x2”，Hashtable默认的容量大小是11；增加容量时，每次将容量变为“原始容量x2 + 1”。
- 添加key-value时的hash值算法不同。HashMap添加元素时，是使用自定义的哈希算法，Hashtable没有自定义哈希算法，而直接采用的key的hashCode()。

# 3. Set

## 3.1 HashSet

HashSet 是一个没有重复元素的集合。它是由HashMap实现的，不保证元素的顺序，而且HashSet允许使用 null 元素。HashSet是非同步的。
HashSet通过iterator()返回的迭代器是fail-fast的。

### 数据结构

HashSet中含有一个HashMap类型的成员变量map，HashSet的操作函数，实际上都是通过map实现的。

## 3.2 TreeSet

TreeSet 是一个有序的集合，它的作用是提供有序的Set集合。它继承于AbstractSet抽象类，实现了NavigableSet<E>, Cloneable, java.io.Serializable接口。

### 数据结构

TreeSet的本质是一个"有序的，并且没有重复元素"的集合，它是通过TreeMap实现的。TreeSet中含有一个"NavigableMap类型的成员变量"m，而m实际上是"TreeMap的实例"。

# 4. 参考资料

- [1] [Java 集合系列01之 总体框架](http://www.cnblogs.com/skywang12345/p/3308498.html)
- [2] [Java里多个Map的性能比较（TreeMap、HashMap、ConcurrentSkipListMap）](http://blog.hongtium.com/java-map-skiplist/)
