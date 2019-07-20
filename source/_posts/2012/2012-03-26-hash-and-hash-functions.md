---
layout: post
title: 哈希表
category: java
tags: [java,map]
keywords: java
description: 一般的线性表、树，数据在结构中的相对位置是**随机**的，即和记录的关键字之间不存在确定的关系，因此，在结构中查找记录时需进行一系列和关键字的比较。这一类查找方法建立在“比较“的基础上，查找的效率依赖于查找过程中所进行的比较次数。 若想能直接找到需要的记录，必须在记录的存储位置和它的关键字之间建立一个确定的对应关系f，使每个关键字和结构中一个唯一的存储位置相对应，这就是哈希表。
---

# 定义 

一般的线性表、树，数据在结构中的相对位置是随机的，即和记录的关键字之间不存在确定的关系，因此，在结构中查找记录时需进行一系列和关键字的比较。这一类查找方法建立在“比较“的基础上，查找的效率依赖于查找过程中所进行的比较次数。 若想能直接找到需要的记录，必须在记录的存储位置和它的关键字之间建立一个确定的对应关系f，使每个关键字和结构中一个唯一的存储位置相对应，这就是哈希表。

`哈希表`又称散列表。*哈希表存储的基本思想是*：以数据表中的每个记录的关键字 k为自变量，通过一种函数H(k)计算出函数值。把这个值解释为一块连续存储空间（即`数组空间`）的单元地址（即`下标`），将该记录存储到这个单元中。在此称该函数H为哈希函数或散列函数。按这种方法建立的表称为`哈希表`或`散列表`。

哈希表是一种数据结构，它可以提供快速的插入操作和查找操作。

哈希表是基于数组结构实现的，所以它也存在一些**缺点**： 数组创建后难于扩展，某些哈希表被基本填满时，性能下降得非常严重。 这个问题是哈希表不可避免的，即冲突现象：对不同的关键字可能得到同一哈希地址。 所以在以下情况下可以优先考虑使用哈希表： **不需要有序遍历数据，并且可以提前预测数据量的大小**。

# 冲突

理想情况下，哈希函数在关键字和地址之间建立了一个一一对应关系，从而使得查找只需一次计算即可完成。由于关键字值的某种随机性，使得这种一一对应关系难以发现或构造。因而可能会出现不同的关键字对应一个存储地址。即k1≠k2，但H(k1)=H(k2)，这种现象称为冲突。
把这种具有不同关键字值而具有相同哈希地址的对象称`同义词`。

在大多数情况下，冲突是不能完全避免的。这是因为所有可能的关键字的集合可能比较大，而对应的地址数则可能比较少。

对于哈希技术，主要研究两个问题：

- （1）如何设计哈希函数以使冲突尽可能少地发生。
- （2）发生冲突后如何解决。

# 哈希函数的构造方法

构造好的哈希函数的方法，应能使冲突尽可能地少，因而应具有较好的随机性。这样可使一组关键字的散列地址均匀地分布在整个地址空间。根据关键字的结构和分布的不同，可构造出许多不同的哈希函数。

## 1）．直接定址法

直接定址法是以关键字k本身或关键字加上某个数值常量c作为哈希地址的方法。

该哈希函数H(k)为：

~~~
H(k)=k+c (c≥0)
~~~

这种哈希函数计算简单，并且不可能有冲突发生。当关键字的分布基本连续时，可使用直接定址法的哈希函数。否则，若关键字分布不连续将造成内存单元的大量浪费

## 2）．除留余数法

取关键字k除以哈希表长度m所得余数作为哈希函数地址的方法。即：

~~~
H(k)=k％m
~~~

这是一种较简单、也是较常见的构造方法。

这种方法的关键是选择好哈希表的长度m。使得数据集合中的每一个关键字通过该函数转化后映射到哈希表的任意地址上的概率相等。
理论研究表明，在m取值为素数（质数）时，冲突可能性相对较少。

## 3）．平方取中法

取关键字平方后的中间几位作为哈希函数地址（若超出范围时，可再取模）。

设有一组关键字ABC，BCD,CDE，DEF，……其对应的机内码如表所示。假定地址空间的大小为1000，编号为0-999。现按平方取中法构造哈希函数，则可取关键字机内码平方后的中间三位作为存储位置。

## 4）．折叠法

这种方法适合在关键字的位数较多，而地址区间较小的情况。

将关键字分隔成位数相同的几部分。然后将这几部分的叠加和作为哈希地址（若超出范围，可再取模）。

例如，假设关键字为某人身份证号码430104681015355，则可以用4位为一组进行叠加。即有5355+8101+1046+430=14932，舍去高位。 则有H(430104681015355)=4932 为该身份证关键字的哈希函数地址。

## 5）．数值分析法

若事先知道所有可能的关键字的取值时，可通过对这些关键字进行分析，发现其变化规律，构造出相应的哈希函数。

例：对如下一组关键字通过分析可知：

每个关键字从左到右的第l，2，3位和第6位取值较集中，不宜作哈希地址。 剩余的第4，5，7和8位取值较分散，可根据实际需要取其中的若干位作为哈希地址。

## 6）. 随机数法

选择一个随机函数，取关键字的随机函数值为它的哈希地址，即`H(key)＝random(key)`，其中random为随机函数。

## 7）. 斐波那契（Fibonacci）散列法

平方散列法的缺点是显而易见的，所以我们能不能找出一个理想的乘数，而不是拿value本身当作乘数呢？答案是肯定的。

- 1，对于16位整数而言，这个乘数是40503
- 2，对于32位整数而言，这个乘数是2654435769
- 3，对于64位整数而言，这个乘数是11400714819323198485

这几个“理想乘数”是如何得出来的呢？这跟一个法则有关，叫黄金分割法则，而描述黄金分割法则的最经典表达式无疑就是著名的斐波那契数列，如果你还有兴趣，就到网上查找一下“斐波那契数列”等关键字，我数学水平有限，不知道怎么描述清楚为什么，另外斐波那契数列的值居然和太阳系八大行星的轨道半径的比例出奇吻合，很神奇，对么？

对我们常见的32位整数而言，公式：

~~~
index = (value * 2654435769) >> 28
~~~
如果用这种斐波那契散列法的话，那我上面的图就变成这样了：

# 冲突的解决方法

假设哈希表的地址范围为`0～m-l`，当对给定的关键字k，由哈希函数`H(k)`算出的哈希地址为`i（0≤i≤m-1）`的位置上已存有记录，这种情况就是冲突现象。 处理冲突就是为该关键字的记录找到另一个“空”的哈希地址。即通过一个新的哈希函数得到一个新的哈希地址。如果仍然发生冲突，则再求下一个，依次类推。直至新的哈希地址不再发生冲突为止。

常用的处理冲突的方法有开放地址法、链地址法两大类

## 1）．开放定址法

用开放定址法处理冲突就是当冲突发生时，形成一个地址序列。沿着这个序列逐个探测，直到找出一个“空”的开放地址。将发生冲突的关键字值存放到该地址中去。
如 Hi=(H(k)+d（i）) % m, i=1，2，…k (k 其中H(k)为哈希函数，m为哈希表长，d为增量函数，d(i)=dl，d2…dn-l。

增量序列的取法不同，可得到不同的开放地址处理冲突探测方法。

### a）线性探测法

线性探测法是从发生冲突的地址（设为d）开始，依次探查d+l，d+2，…m-1（当达到表尾m-1时，又从0开始探查）等地址，直到找到一个空闲位置来存放冲突处的关键字。

若整个地址都找遍仍无空地址，则产生溢出。

线性探查法的数学递推描述公式为：

~~~
d0=H(k)
di=(di-1+1)% m (1≤i≤m-1)
~~~


【例】已知哈希表地址区间为0～10，给定关键字序列（20，30，70，15，8，12，18，63，19）。哈希函数为H(k)=k％ll，采用线性探测法处理冲突，则将以上关键字依次存储到哈希表中。试构造出该哈希表，并求出等概率情况下的平均查找长度。

假设数组为A, 本题中各元素的存放过程如下：

~~~
H(20)=9，可直接存放到A[9]中去。
H(30)=8，可直接存放到A[8]中去。
H(70)=4，可直接存放到A[4]中去。
H(15)=4，冲突；
d0=4
d1=(4+1)%11=5，将15放入到A[5]中。
H(8)=8，冲突；
d0=8
d1=(8+1)%11=9，仍冲突；
d2=(8+2)%11=10，将8放入到A[10]中。
~~~

在等概率情况下成功的平均查找长度为：

~~~
（1*5+2+3+4+6）/9 =20/9
~~~

利用线性探查法处理冲突容易造成关键字的堆积问题。这是因为当连续n个单元被占用后，再散列到这些单元上的关键字和直接散列到后面一个空闲单元上的关键字都要占用这个空闲单元，致使该空闲单元很容易被占用，从而发生非同义冲突。造成平均查找长度的增加。
为了克服堆积现象的发生，可以用下面的方法替代线性探查法。

### b）平方探查法

设发生冲突的地址为d，则平方探查法的探查序列为：d+12，d+22，…直到找到一个空闲位置为止。

平方探查法的数学描述公式为：

~~~
d0=H(k)
di=(d0+i2) % m (1≤i≤m-1)
~~~

在等概率情况下成功的平均查找长度为：

~~~
（1*4+2*2+3+4+6）/9 =21/9
~~~

平方探查法是一种较好的处理冲突的方法，可以避免出现堆积问题。它的缺点是不能探查到哈希表上的所有单元，但至少能探查到一半单元。

例如，若表长m=13，假设在第3个位置发生冲突，则后面探查的位置依次为4、7、12、6、2、0，即可以探查到一半单元。

若解决冲突时，探查到一半单元仍找不到一个空闲单元。则表明此哈希表太满，需重新建立哈希表。

## 2）．链地址法

用链地址法解决冲突的方法是：
把所有关键字为同义词的记录存储在一个线性链表中，这个链表称为同义词链表。并将这些链表的表头指针放在数组中（下标从0到m-1）。这类似于图中的邻接表和树中孩子链表的结构。

由于在各链表中的第一个元素的查找长度为l，第二个元素的查找长度为2，依此类推。因此，在等概率情况下成功的平均查找长度为：

~~~
(1*5+2*2+3*l+4*1)／9=16／9
~~~

虽然链地址法要多费一些存储空间，但是彻底解决了“堆积”问题，大大提高了查找效率。

## 3）. 再哈希法：

`Hi=R Hi(key)`，R和Hi均是不同的哈希函数，即在同义词产生地址冲突时计算另一个哈希函数地址，直到冲突不再发生。这种方法不易产生聚集，但增加了计算的时间。

## 4）.建立一个公共溢出区

这也是处理冲突的一种方法。

假设哈希函数的值域为[0，m-1]，则设向量HashTable[0…m-1]为基本表，每个分量存放一个记录，另设立向量OverTable[0．．v]为溢出表。所有关键字和基本表中关键字为同义词的记录，不管它们由哈希函数得到的哈希地址是什么，一旦发生冲突，都填入溢出表。

# 哈希表的查找及性能分析

哈希法是利用关键字进行计算后直接求出存储地址的。当哈希函数能得到均匀的地址分布时，不需要进行任何比较就可以直接找到所要查的记录。但实际上不可能完全避免冲突，因此查找时还需要进行探测比较。

在哈希表中，虽然冲突很难避免，但发生冲突的可能性却有大有小。这主要与三个因素有关。

- 第一:与装填因子有关

所谓装填因子是指哈希表中己存入的元素个数n与哈希表的大小m的比值，即f=n/m。
当f越小时，发生冲突的可能性越小，越大（最大为1）时，发生冲突的可能性就越大。

- 第二:与所构造的哈希函数有关

若哈希函数选择得当，就可使哈希地址尽可能均匀地分布在哈希地址空间上，从而减少冲突的发生。否则，若哈希函数选择不当，就可能使哈希地址集中于某些区域，从而加大冲突的发生。

- 第三:与解决冲突的哈希冲突函数有关

哈希冲突函数选择的好坏也将减少或增加发生冲突的可能性。

# java 哈希表实现

java中哈希表的实现有多个，比如hashtable，hashmap，currenthashmap，也有其他公司实现的，如apache的FashHashmap,google的mapmarker,high-lib的NonBlockingHashMap,其中差别是：

- hastable:线程同步，比较慢
- hashmap：线程不同步，不同步时候读写最快（但是不能保证读到最新数据），加同步修饰的时候， 读写比较慢
- currenthashmap:线程同步，默认分成16块，写入的时候只锁要写入的快，读取一般不锁块，只有读到空的时候，才锁块，性能比较高，处于hashmap同步和不同步之间。
- fashhashmap:apache collection 将HashMap封装，读取的时候copy一个新的，写入比较慢（尤其是存入比较多对象每写一次都要复制一个对象，超级慢），读取快
- NoBlockingHashMap： high_scale_lib实现写入慢，读取较快
MiltigetHashMap，MapMaker google collection，和CurrentHashMap性能相当，功能比较全，可以设置超时，重复的可以保存成list

# 参考文章

- [哈希表](http://course.onlinesjtu.com/mod/page/view.php?id=423)
- [哈希表（Hash Table）及散列法（Hashing）](http://www.cnblogs.com/bigshuai/articles/2398116.html)
- [Hash碰撞的拒绝式服务攻击](http://blog.jobbole.com/11454/)
- [Berkeley DB Hash、Btree、Queue、Recno选择](http://www.webzone8.com/article/560.html)
- [Java Hashtable ](http://javapapers.com/core-java/java-hashtable/#&amp;slider1=1)
- [Java Hashtable分析](http://kantery.iteye.com/blog/441755)