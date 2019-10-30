---
layout: post

title: Java笔记：Java内存模型
date: 2014-04-09T08:00:00+08:00

description: 关于Java内存模型和垃圾回收的过程

keywords: Java内容模型

categories: [ java ]

tags: [java,jvm]

published: true

---

# 1. 基本概念

《深入理解Java内存模型》详细讲解了java的内存模型，这里对其中的一些基本概念做个简单的笔记。以下内容摘自 [《深入理解Java内存模型》读书总结](http://www.cnblogs.com/skywang12345/p/3447546.html)

## 并发

定义：即，并发(同时)发生。在操作系统中，是指一个时间段中有几个程序都处于已启动运行到运行完毕之间，且这几个程序都是在同一个处理机上运行，但任一个时刻点上只有一个程序在处理机上运行。

并发需要处理两个关键问题：`线程之间如何通信`及`线程之间如何同步`。

- `通信`：是指线程之间如何交换信息。在命令式编程中，线程之间的通信机制有两种：`共享内存`和`消息传递`。
- `同步`：是指程序用于控制不同线程之间操作发生相对顺序的机制。在Java中，可以通过`volatile`、`synchronized`、`锁`等方式实现同步。


## 主内存和本地内存

`主内存`：即 main memory。在java中，实例域、静态域和数组元素是线程之间共享的数据，它们存储在主内存中。

`本地内存`：即 local memory。 局部变量，方法定义参数 和 异常处理器参数是不会在线程之间共享的，它们存储在线程的本地内存中。


## 重排序

定义：`重排序`是指“编译器和处理器”为了提高性能，而在程序执行时会对程序进行的重排序。

说明：重排序分为“编译器”和“处理器”两个方面，而“处理器”重排序又包括“指令级重排序”和“内存的重排序”。

>关于重排序，我们需要理解它的思想：
>为了提高程序的并发度，从而提高性能！但是对于多线程程序，重排序可能会导致程序执行的结果不是我们需要的结果！因此，就需要我们通过volatile、synchronize、锁等方式实现同步。

## 内存屏障

定义：包括LoadLoad, LoadStore, StoreLoad, StoreStore共4种内存屏障。内存屏障是与相应的内存重排序相对应的。

作用：通过内存屏障可以禁止特定类型处理器的重排序，从而让程序按我们预想的流程去执行。

## happens-before

定义：JDK5(JSR-133)提供的概念，用于描述多线程操作之间的内存可见性。如果一个操作执行的结果需要对另一个操作可见，那么这两个操作之间必须存在 `happens-before` 关系。

作用：描述多线程操作之间的内存可见性。

## 数据依赖性

定义：如果两个操作访问同一个变量，且这两个操作中有一个为写操作，此时这两个操作之间就存在`数据依赖性`。

作用：编译器和处理器不会对“存在数据依赖关系的两个操作”执行重排序。

## as-if-serial

定义：不管怎么重排序，程序的执行结果不能被改变。

## 顺序一致性内存模型

定义：它是理想化的内存模型。有以下规则：

- 一个线程中的所有操作必须按照程序的顺序来执行。
- 所有线程都只能看到一个单一的操作执行顺序。在顺序一致性内存模型中，每个操作都必须原子执行且立刻对所有线程可见。

## Java内存模型

定义：Java Memory Mode，它是Java线程之间通信的控制机制。

说明：JMM 对 Java 程序作出保证，如果程序是正确同步的，程序的执行将具有顺序一致性。即，程序的执行结果与该程序在顺序一致性内存模型中的执行结果相同。

## 可见性

可见性一般用于指不同线程之间的数据是否可见。

在 java 中， 实例域、静态域和数组元素这些数据是线程之间共享的数据，它们存储在主内存中；主内存中的所有数据对该内存中的线程都是可见的。而局部变量，方法定义参数和异常处理器参数这些数据是不会在线程之间共享的，它们存储在线程的本地内存中；它们对其它线程是不可见的。

此外，对于主内存中的数据，在本地内存中会对应的创建该数据的副本(相当于缓冲)；这些副本对于其它线程也是不可见的。

## 原子性

是指一个操作是按原子的方式执行的。要么该操作不被执行；要么以原子方式执行，即执行过程中不会被其它线程中断。

# 2. JVM内存模型

虽然平时我们用的大多是 Sun JDK 提供的 JVM，但是 JVM 本身是一个 [规范](http://java.sun.com/docs/books/jvms/second_edition/html/VMSpecTOC.doc.html)，所以可以有多种实现，除了 [Hotspot](http://www.oracle.com/technetwork/java/javase/tech/index-jsp-136373.html) 外，还有诸如 Oracle 的 [JRockit](http://www.oracle.com/technetwork/middleware/jrockit/overview/index.html)、IBM 的 [J9](http://en.wikipedia.org/wiki/IBM_J9)也都是非常有名的 JVM。

Java 虚拟机在执行 Java 程序的过程中会把它所管理的内存划分为若干个不同的数据区域，这些区域都有各自的用途，以及创建和销毁的时间。有的区域随着虚拟机进程的启动就存在了， 有的区域则是依赖用户线程。根据《Java虚拟机规范（第二版）》，Java 虚拟机所管理的内存包含如下图的几个区域。

![Java-Memory.png](/images/Java-Memory.png)

 由上图可以看出 JVM 组成如下：

 - 运行时数据区（内存空间）
    - 方法区
    - 堆
    - 虚拟机栈
    - 程序计数器
    - 本地方法栈
    - 直接内存
 - 执行引擎
 - 本地库接口

从上图中还可以看出，在内存空间中方法区和堆是所有Java线程共享的，称之为`线程共享数据区`，而虚拟机栈、程序计数器、本地方法栈则由每个线程私有，称之为`线程隔离数据区`。

**关于本地方法：**

> 众所周知，Java 语言具有跨平台的特性，这也是由 JVM 来实现的。更准确地说，是 Sun 利用 JVM 在不同平台上的实现帮我们把平台相关性的问题给解决了，这就好比是 HTML 语言可以在不同厂商的浏览器上呈现元素（虽然某些浏览器在对W3C标准的支持上还有一些问题）。同时，Java 语言支持通过 JNI（Java Native Interface）来实现本地方法的调用，但是需要注意到，如果你在 Java 程序用调用了本地方法，那么你的程序就很可能不再具有跨平台性，即本地方法会破坏平台无关性。

下面分别就线程共享数据区和线程共享数据区进行说明。

## 2.1 线程共享数据区

所谓线程共享数据区，是指在多线程环境下，该部分区域数据可以被所有线程所共享，主要有方法区和堆。

### 方法区

`方法区`用于存储已被虚拟机加载的类信息、常量、静态变量、即时编译器编译后的代码等等。方法区中对于每个类存储了以下数据：

- 类及其父类的全限定名（java.lang.Object没有父类）
- 类的类型（Class or Interface）
- 访问修饰符（public, abstract, final）
- 实现的接口的全限定名的列表
- 常量池
- 字段信息
- 方法信息
- 静态变量
- ClassLoader 引用
- Class 引用

可见类的所有信息都存储在方法区中。由于方法区是所有线程共享的，所以必须保证`线程安全`，举例来说：如果两个类同时要加载一个尚未被加载的类，那么一个类会请求它的 ClassLoader 去加载需要的类，另一个类只能等待而不会重复加载。

>**注意事项：**
>
>- 在 HotSpot 虚拟机中，很多人都把方法区成为`永久代`，默认最小值为16MB，最大值为64MB。其实只在 HotSpot 才存在方法区，在其他的虚拟机没有方法区这一个说法的。本文是采用 Hotspot，所以把方法区介绍了。
>
>- 如果方法区无法满足内存分配需求时候就会抛出 OutOfMemoryError 异常。

### 堆

堆是被所有线程共享的一块内存区域，在虚拟机启动时创建。此内存区域的唯一目的就是存放对象实例及数组内容，几乎所有的对象实例都在这里分配内存。堆中有指向类数据的指针，该指针指向了方法区中对应的类型信息，堆中还可能存放了指向方法表的指针。堆是所有线程共享的，所以在进行实例化对象等操作时，需要解决同步问题。此外，堆中的实例数据中还包含了对象锁，并且针对不同的垃圾收集策略，可能存放了引用计数或清扫标记等数据。

在 Java 中，堆被划分成两个不同的区域：新生代 ( Young )、老年代 ( Old )。新生代 ( Young ) 又被划分为三个区域：Eden、From Survivor、To Survivor。

![jvm-heap.png](/images/jvm-heap.png)

​从图中可以看出： `堆大小 = 新生代 + 老年代`，其中，堆的大小可以通过参数 `-Xms`、`-Xmx` 来指定。本人使用的是 JDK1.6，以下涉及的 JVM 默认值均以该版本为准。

- 默认的，`Young : Old = 1 : m` ，该比例值 m 可以通过参数 `-XX:NewRatio` 来指定，默认值为2，即新生代 ( Young ) = 1/3 的堆空间大小，老年代 ( Old ) = 2/3 的堆空间大小。

- 默认的，`Edem : from : to = n : 1 : 1` ，该比例值 n 可以参数 `-XX:SurvivorRatio` 来设定，默认值为8 ，即 Eden = 8/10 的新生代空间大小，from = to = 1/10 的新生代空间大小。

- JVM 每次只会使用 Eden 和其中的一块 Survivor 区域来为对象服务，所以无论什么时候，总是有一块 Survivor 区域是空闲着的，因此，新生代实际可用的内存空间为 9/10 ( 即90% )的新生代空间。

根据 Java 虚拟机规范的规定，Java 堆可以处于物理上不连续的内存空间中，只要逻辑上是连续的即可，就像我们的磁盘空间一样。在实现时，既可以实现成固定大小的，也可以是可扩展的，不过当前主流的虚拟机都是按照可扩展来实现的。如果在堆中没有内存完成实例分配，并且堆也无法再扩展时，将会抛出 OutOfMemoryError 异常。

## 2.2 线程隔离数据区

所谓线程隔离数据区是指在多线程环境下，每个线程所独享的数据区域。主要有程序计数器、Java虚拟机栈、本地方法栈三个数据区。

### 程序计数器

[程序计数器](http://baike.baidu.com/view/178145.htm?fr=aladdin) ，计算机处理器中的寄存器，它包含当前正在执行的指令的地址（位置）。当每个指令被获取，程序计数器的存储地址加一。在每个指令被获取之后，程序计数器指向顺序中的下一个指令。当计算机重启或复位时，程序计数器通常恢复到零。

在Java中程序计数器是一块较小的内存空间，充当当前线程所执行的字节码的行号指示器的角色。

在多线程环境下，当某个线程失去处理器执行权时，需要记录该线程被切换出去时所执行的程序位置。从而方便该线程被切换回来(重新被处理器处理)时能恢复到当初的执行位置，因此每个线程都需要有一个独立的程序计数器。各个线程的程序计数器互不影响，并且独立存储。

  - 当线程正在执行一个 java 方法时，这个程序计数器记录的时正在执行的虚拟机字节码指令的地址。
  - 当线程执行的是 [Native方法](http://www.enet.com.cn/article/2007/1029/A20071029886398.shtml)，这个计数器值为空。
  - 此内存区域是唯一一个在 java 虚拟机规范中没有规定任何 OutOfMemoryError 情况的区域。

### Java 虚拟机栈

与程序计数器一样，Java 虚拟机栈（Java Virtual Machine Stacks）也是线程私有的，它的生命周期与线程相同。Java 虚拟机栈描述的是 Java 方法执行的内存模型，每个方法在执行的同时都会创建一个[栈帧](http://baike.baidu.com/view/8128123.htm?fr=aladdin)用于存储[局部变量表](http://blog.csdn.net/kevin_luan/article/details/22986081)、[操作数栈](http://denverj.iteye.com/blog/1218359)、[动态链接](http://jnn.iteye.com/blog/83105)、方法出口等信息。每个方法从调用直至执行完成的过程，对应着一个栈帧在虚拟机中入栈到进栈的过程。

在 Hot Spot 虚拟机中，可以使用 `-Xss` 参数来设置栈的大小。栈的大小直接决定了函数调用的深度。

某个线程正在执行的方法被称为该线程的当前方法，当前方法使用的栈帧成为当前帧，当前方法所属的类成为当前类，当前类的常量池成为当前常量池。在线程执行一个方法时，它会跟踪当前类和当前常量池。此外，当虚拟机遇到栈内操作指令时，它对当前帧内数据执行操作。

它分为三部分：`局部变量区`、`操作数栈`、`帧数据区`。

1、局部变量区

局部变量区是以字长为单位的数组，在这里，byte、short、char 类型会被转换成 int 类型存储，除了 long 和 double 类型占两个字长以外，其余类型都只占用一个字长。特别地，boolean 类型在编译时会被转换成 int 或 byte 类型，boolean 数组会被当做 byte 类型数组来处理。局部变量区也会包含对象的引用，包括类引用、接口引用以及数组引用。

局部变量区包含了方法参数和局部变量，此外，实例方法隐含第一个局部变量 this，它指向调用该方法的对象引用。对于对象，局部变量区中永远只有指向堆的引用。

 >注意：
 >
 >局部变量表中的字可能会影响 GC 回收。如果这个字没有被后续代码复用，那么它所引用的对象不会被 GC 释放，手工对要释放的变量赋值为 null，是一种有效的做法。

2、操作数栈

操作数栈也是以字长为单位的数组，但是正如其名，它只能进行入栈出栈的基本操作。在进行计算时，操作数被弹出栈，计算完毕后再入栈。

每当线程调用一个Java方法时，虚拟机都会在该线程的Java栈中压入一个新帧。而这个新帧自然就成为了当前帧。在执行这个方法时，它使用这个帧来存储参数、局部变量、中间运算结果等等数据。

Java 方法可以以两种方式完成。一种通过 return 返回的，称为正常返回；一种是通过抛出异常而异常中止的。不管以哪种方式返回，虚拟机都会将当前帧弹出Java栈然后释放掉，这样上一个方法的帧就成为当前帧了。

Java 栈上的所有数据都是此线程私有的。任何线程都不能访问另一个线程的栈数据，因此我们不需要考虑多线程情况下栈数据的访问同步问题。当一个线程调用一个方法时，方法的局部变量保存在调用线程 Java 栈的帧中。只有一个线程总是访问哪些局部变量，即调用方法的线程。

3、帧数据区

帧数据区的任务主要有：

- a.记录指向类的常量池的指针，以便于解析。

- b.帮助方法的正常返回，包括恢复调用该方法的栈帧，设置PC寄存器指向调用方法对应的下一条指令，把返回值压入调用栈帧的操作数栈中。

- c.记录异常表，发生异常时将控制权交由对应异常的catch子句，如果没有找到对应的catch子句，会恢复调用方法的栈帧并重新抛出异常。

局部变量区和操作数栈的大小依照具体方法在编译时就已经确定。调用方法时会从方法区中找到对应类的类型信息，从中得到具体方法的局部变量区和操作数栈的大小，依此分配栈帧内存，压入Java栈。

在 Java 虚拟机规范中，对这个区域规定了**两种异常状况**：

- 如果线程请求的栈深度大于虚拟机所允许的深度，将抛出 StackOverflowError 异常；
- 如果虚拟机栈可以动态扩展（当前大部分的Java虚拟机都可动态扩展，只不过Java虚拟机规范中也允许固定长度的虚拟机栈），当扩展时无法申请到足够的内存时会抛出 OutOfMemoryError 异常。

### 本地方法栈

本地方法栈（Native Method Stacks）与虚拟机栈所发挥的作用是非常相似的，其区别不过是虚拟机栈为虚拟机执行 Java方法（也就是字节码）服务，而本地方法栈则是为虚拟机使用到的 Native 方法服务。虚拟机规范中对本地方法栈中的方法使用的语言、使用方式与数据结构并没有强制规定，因此具体的虚拟机可以自由实现它。甚至有的虚拟机（譬如 Sun HotSpot 虚拟机）直接就把本地方法栈和虚拟机栈合二为一。与虚拟机栈一样，本地方法栈区域也会抛出 StackOverflowError 和 OutOfMemoryError 异常。

## 2.3 直接内存

直接内存并不是虚拟机运行时数据区的一部分，也不是 Java 虚拟机规范中定义的内存区域。

JDK1.4 中出现了 NIO，其引入了一种基于通道与缓冲区的 I/O 方式，它可以使用 Native 函数库直接分配堆外内存，然后通过一个存储在 Java 堆中得 DirectoryByteBuffer 对象作为这块内存的引用进行操作。这样可以避免 Java 堆和 Native 堆之间的来回复制数据。

当机器直接内存去除 JVM 内存之后的内存不能满足直接内存大小要求其，将会抛出 OutOfMemoryError 异常。

# 3. 垃圾回收过程

![jvm-heap.png](/images/jvm-heap.png)

JVM 采用一种`分代回收` (generational collection) 的策略，用较高的频率对年轻的对象进行扫描和回收，这种叫做 `minor collection` ，而对老对象的检查回收频率要低很多，称为 `major collection`。这样就不需要每次 GC 都将内存中所有对象都检查一遍。

- 新生代被划分为三部分，Eden 区和两个大小严格相同的 Survivor 区，其中 Survivor 区间，`某一时刻只有其中一个是被使用的，另外一个留做垃圾收集时复制对象用`，在 Young 区间变满的时候，minor GC 就会将存活的对象移到空闲的 Survivor 区间中，根据 JVM 的策略，`在经过几次垃圾收集后，仍然存活于 Survivor 的对象将被移动到老年代`。

- 老年代主要保存生命周期长的对象，一般是一些老的对象，`当一些对象在 Young 复制转移一定的次数以后，对象就会被转移到老年区`，一般如果系统中用了 application 级别的缓存，缓存中的对象往往会被转移到这一区间。

>Minor collection 的过程就是将 eden 和在用survivor space中的活对象 copy 到空闲survivor space中。所谓 survivor，也就是大部分对象在 eden 出生后，根本活不过一次 GC。对象在新生代里经历了一定次数的 minor collection 后，年纪大了，就会被移到老年代中，称为 tenuring。
>
>剩余内存空间不足会触发 GC，如 eden 空间不够了就要进行 minor collection，老年代空间不够要进行 major collection，永久代(Permanent Space)空间不足会引发full GC。

举例：当一个 URL 被访问时，内存申请过程如下：

- A. JVM 会试图为相关 Java 对象在 Eden 中初始化一块内存区域
- B. 当 Eden 空间足够时，内存申请结束。否则到下一步
- C. JVM 试图释放在 Eden 中所有不活跃的对象，释放后若 Eden 空间仍然不足以放入新对象，则试图将部分 Eden 中活跃对象放入 Survivor 区
- D. Survivor 区被用来作为 Eden 及 Old 的中间交换区域，当 Old 区空间足够时，Survivor 区的对象会被移到 Old 区，否则会被保留在 Survivor区
- E. 当 Old 区空间不够时，JVM 会在 Old 区进行完全的垃圾收集
- F. 完全垃圾收集后，若 Survivor 及 Old 区仍然无法存放从 Eden 复制过来的部分对象，导致 JVM 无法在 Eden 区为新对象创建内存区域，则出现 `out of memory` 错误

**HotSpot jvm 都给我们提供了下面参数来对内存进行配置：**

- 配置总内存
 - `-Xms` ：指定了 JVM 初始启动以后初始化内存
 - `-Xmx`：指定 JVM 堆得最大内存，在JVM启动以后，会分配 `-Xmx` 参数指定大小的内存给 JVM，但是不一定全部使用，JVM 会根据 `-Xms` 参数来调节真正用于JVM的内存，`-Xmx-Xms` 之差就是三个 Virtual 空间的大小

- 配置新生代 
 - `-Xmn`: 参数设置了年轻代的大小 
 - `-XX:SurvivorRatio`: 表示 eden 和一个 surivivor 的比例，缺省值为8
 - `-XX:NewSize` 和 `-XX:MaxNewSize`：直接指定了年轻代的缺省大小和最大大小

- 配置老年代 
 - `-XX:NewRatio`: 表示年老年代和新生代内存的比例，缺省值为2

- 配置持久代
 - `-XX:MaxPermSize`：表示持久代的最大值
 - `-XX:PermSize`：设置最小分配空间

- 配置虚拟机栈
 - `-Xss`：参数来设置栈的大小，默认值为128 kb。栈的大小直接决定了函数调用的深度

# 4. 常见的垃圾收集策略

垃圾收集提供了内存管理的机制，使得应用程序不需要在关注内存如何释放，内存用完后，垃圾收集会进行收集，这样就减轻了因为人为的管理内存而造成的错误，比如在 C++ 语言里，出现内存泄露时很常见的。Java 语言是目前使用最多的依赖于垃圾收集器的语言，但是垃圾收集器策略从20世纪60年代就已经流行起来了，比如 Smalltalk,Eiffel 等编程语言也集成了垃圾收集器的机制。

所有的垃圾收集算法都面临同一个问题，那就是找出应用程序不可到达的内存块，将其释放，这里面得不可到达主要是指应用程序已经没有内存块的引用了，而在 JAVA中，某个对象对应用程序是可到达的是指：这个对象被根（根主要是指类的静态变量，常量或者活跃在所有线程栈的对象的引用）引用或者对象被另一个可到达的对象引用。

下面我们介绍一下几种常见的垃圾收集策略：

## 4.1 Reference Counting(引用计数）

引用计数是最简单直接的一种方式，这种方式在每一个对象中增加一个引用的计数，这个计数代表当前程序有多少个引用引用了此对象，如果此对象的引用计数变为0，那么此对象就可以作为垃圾收集器的目标对象来收集。

优点：简单，直接，不需要暂停整个应用

缺点：需要编译器的配合，编译器要生成特殊的指令来进行引用计数的操作，比如每次将对象赋值给新的引用，或者者对象的引用超出了作用域等。
不能处理循环引用的问题

## 4.2 跟踪收集器

跟踪收集器首先要暂停整个应用程序，然后开始从根对象扫描整个堆，判断扫描的对象是否有对象引用。 

如果每次扫描整个堆，那么势必让 GC 的时间变长，从而影响了应用本身的执行。因此在 JVM 里面采用了分代收集，在新生代收集的时候 minor gc 只需要扫描新生代，而不需要扫描老生代。minor gc 怎么判断是否有老生代的对象引用了新生代的对象，JVM 采用了卡片标记的策略，卡片标记将老生代分成了一块一块的，划分以后的每一个块就叫做一个卡片，JVM 采用卡表维护了每一个块的状态，当 JAVA 程序运行的时候，如果发现老生代对象引用或者释放了新生代对象的引用，那么就 JVM 就将卡表的状态设置为脏状态，这样每次 minor gc 的时候就会只扫描被标记为脏状态的卡片，而不需要扫描整个堆。

上面说了 Jvm 需要判断对象是否有引用存在，而 Java 中的引用又分为了如下几种，不同种类的引用对垃圾收集有不同的影响，下面我们分开描述一下：

- 1）Strong Reference(强引用)

强引用是 JAVA 中默认采用的一种方式，我们平时创建的引用都属于强引用。如果一个对象没有强引用，那么对象就会被回收。

~~~java
public void testStrongReference(){
    Object referent = new Object();
    Object strongReference = referent;
    referent = null;
    System.gc();
    assertNotNull(strongReference);
}
~~~

- 2）Soft Reference(软引用) 

软引用的对象在 GC 的时候不会被回收，只有当内存不够用的时候才会真正的回收，因此软引用适合缓存的场合，这样使得缓存中的对象可以尽量的再内存中待长久一点。 

~~~java
Public void testSoftReference(){
    String  str =  "test";
    SoftReference<String> softreference = new SoftReference<String>(str);
    str=null;
    System.gc();
    assertNotNull(softreference.get());
}
~~~

- 3）Weak Reference(弱引用)

弱引用有利于对象更快的被回收，假如一个对象没有强引用只有弱引用，那么在 GC 后，这个对象肯定会被回收。

~~~java
Public void testWeakReference(){
    String  str =  "test";
    WeakReference<String> weakReference = new WeakReference<String>(str);
    str=null;
    System.gc();
    assertNull(weakReference.get());
}
~~~

- 4）Phantom reference(幽灵引用) 

幽灵引用说是引用，但是你不能通过幽灵引用来获取对象实例，它主要目的是为了当设置了幽灵引用的对象在被回收的时候可以收到通知。 

跟踪收集器常见的有如下几种：

### 4.2.1 Mark-Sweep Collector(标记-清除收集器）

标记清除收集器最早由Lisp的发明人于1960年提出，标记清除收集器停止所有的工作，从根扫描每个活跃的对象，然后标记扫描过的对象，标记完成以后，清除那些没有被标记的对象。

优点：

- 解决循环引用的问题
- 不需要编译器的配合，从而就不执行额外的指令

缺点： 

- 每个活跃的对象都要进行扫描，收集暂停的时间比较长。

### 4.2.2 Copying Collector(复制收集器）

复制收集器将内存分为两块一样大小空间，某一个时刻，只有一个空间处于活跃的状态，当活跃的空间满的时候，GC就会将活跃的对象复制到未使用的空间中去，原来不活跃的空间就变为了活跃的空间。

优点： 

- 只扫描可以到达的对象，不需要扫描所有的对象，从而减少了应用暂停的时间

缺点：

- 需要额外的空间消耗，某一个时刻，总是有一块内存处于未使用状态
- 复制对象需要一定的开销

### 4.2.3 Mark-Compact Collector(标记-整理收集器）

标记整理收集器汲取了标记清除和复制收集器的优点，它分两个阶段执行，在第一个阶段，首先扫描所有活跃的对象，并标记所有活跃的对象，第二个阶段首先清除未标记的对象，然后将活跃的的对象复制到堆得底部。

Mark-compact 策略极大的减少了内存碎片，并且不需要像 Copy Collector 一样需要两倍的空间。

# 5. HotSpot JVM 垃圾收集策略

GC 的执行时要耗费一定的 CPU 资源和时间的，因此在 JDK1.2 以后，JVM 引入了分代收集的策略，其中对新生代采用 ”Mark-Compact” 策略，而对老生代采用了 “Mark-Sweep” 的策略。其中新生代的垃圾收集器命名为 “minor gc”，老生代的 GC 命名为 ”Full Gc 或者Major GC”。其中用 `System.gc()` 强制执行的是 Full GC。

HotSpot JVM 的垃圾收集器按照并发性可以分为如下三种类型：

## 5.1 串行收集器（Serial Collector）

Serial Collector 是指任何时刻都只有一个线程进行垃圾收集，这种策略有一个名字 `stop the whole world`，它需要停止整个应用的执行。这种类型的收集器适合于单CPU的机器。 

Serial Collector 有如下两个：

- 1）Serial Copying Collector

此种 GC 用 `-XX:UseSerialGC` 选项配置，它只用于新生代对象的收集。

JDK 1.5.0 以后 `-XX:MaxTenuringThreshold` 用来设置对象复制的次数。当 eden 空间不够的时候，GC 会将 eden 的活跃对象和一个名叫 From survivor 空间中尚不够资格放入 Old 代的对象复制到另外一个名字叫 To Survivor 的空间。而此参数就是用来说明到底 From survivor 中的哪些对象不够资格，假如这个参数设置为31，那么也就是说只有对象复制31次以后才算是有资格的对象。

**这里需要注意几个个问题：**

>- From Survivor 和 To survivor的角色是不断的变化的，同一时间只有一块空间处于使用状态，这个空间就叫做 From Survivor 区，当复制一次后角色就发生了变化。
>- 如果复制的过程中发现 To survivor 空间已经满了，那么就直接复制到 old generation。
>- 比较大的对象也会直接复制到Old generation，在开发中，我们应该尽量避免这种情况的发生。

- 2）Serial Mark-Compact Collector

串行的标记-整理收集器是 JDK5 update6 之前默认的老生代的垃圾收集器，此收集使得内存碎片最少化，但是它需要暂停的时间比较长

## 5.2 并行收集器（Parallel Collector）

Parallel Collector 主要是为了应对多 CPU，大数据量的环境。Parallel Collector又可以分为以下三种：

- 1）Parallel Copying Collector

此种 GC 用 `-XX:UseParNewGC` 参数配置，它主要用于新生代的收集，此 GC 可以配合CMS一起使用，适用于1.4.1以后。

- 2）Parallel Mark-Compact Collector

此种 GC 用 `-XX:UseParallelOldGC` 参数配置，此 GC 主要用于老生代对象的收集。适用于1.6.0以后。

- 3）Parallel scavenging Collector

此种 GC 用 `-XX:UseParallelGC` 参数配置，它是对新生代对象的垃圾收集器，但是它不能和CMS配合使用，它适合于比较大新生代的情况，此收集器起始于 jdk 1.4.0。它比较适合于对吞吐量高于暂停时间的场合。

## 5.3 并发收集器 (Concurrent Collector)

Concurrent Collector 通过并行的方式进行垃圾收集，这样就减少了垃圾收集器收集一次的时间，在 HotSpot JVM 中，我们称之为 `CMS GC`，这种 GC 在实时性要求高于吞吐量的时候比较有用。此种 GC 可以用参数 `-XX:UseConcMarkSweepGC` 配置，此 GC 主要用于老生代和 Perm 代的收集。

CMS GC有可能出现并发模型失败：

>CMS GC 在运行的时候，用户线程也在运行，当 GC 的速度比新增对象的速度慢的时候，或者说当正在 GC 的时候，老年代的空间不能满足用户线程内存分配的需求的时候，就会出现并发模型失败，出现并发模型失败的时候，JVM 会触发一次 `stop-the-world` 的 Full GC 这将导致暂停时间过长。不过 CMS GC 提供了一个参数 `-XX:CMSInitiatingOccupancyFraction` 来指定当老年代的空间超过某个值的时候即触发 GC，因此如果此参数设置的过高，可能会导致更多的并发模型失败。

并发和并行收集器区别：

> 并发收集器是指垃圾收集器线程和应用线程可以并发的执行，也就是清除的时候不需要 `stop the world`，但是并行收集器指的的是可以多个线程并行的进行垃圾收集，并行收集器还是要暂停应用的

# 6. HotSpot Jvm 垃圾收集器的配置策略

下面我们分两种情况来分别描述一下不同情况下的垃圾收集配置策略。

## 6.1 吞吐量优先

吞吐量是指 GC 的时间与运行总时间的比值，比如系统运行了100 分钟，而 GC 占用了一分钟，那么吞吐量就是 99%，吞吐量优先一般运用于对响应性要求不高的场合，比如 web 应用，因为网络传输本来就有延迟的问题，GC 造成的短暂的暂停使得用户以为是网络阻塞所致。

吞吐量优先可以通过 `-XX:GCTimeRatio` 来指定。当通过 `-XX:GCTimeRatio` 不能满足系统的要求以后，我们可以更加细致的来对 JVM 进行调优。

首先因为要求高吞吐量，这样就需要一个较大的 Young generation，此时就需要引入 `Parallel scavenging Collector` ，可以通过参数：`-XX:UseParallelGC`来配置。

~~~
java -server -Xms3072m -Xmx3072m -XX:NewSize=2560m -XX:MaxNewSize=2560 -XX:SurvivorRatio=2 -XX:+UseParallelGC
~~~

当年轻代使用了 `Parallel scavenge collector` 后，老生代就不能使用 `CMS GC` 了，在 JDK1.6 之前，此时老生代只能采用串行收集，而 JDK1.6 引入了并行版本的老生代收集器，可以用参数 `-XX:UseParallelOldGC` 来配置。

1.控制并行的线程数 

缺省情况下，`Parallel scavenging Collector` 会开启与 cpu 数量相同的线程进行并行的收集，但是也可以调节并行的线程数。假如你想用4个并行的线程去收集 Young generation 的话，那么就可以配置 `-XX:ParallelGCThreads=4`，此时JVM的配置参数如下：

~~~
java -server -Xms3072m -Xmx3072m -XX:NewSize=2560m -XX:MaxNewSize=2560 -XX:SurvivorRatio=2 -XX:+UseParallelGC -XX:ParallelGCThreads=4
~~~

2.自动调节新生代 

在采用了 `Parallel scavenge collector` 后，此 GC 会根据运行时的情况自动调节 survivor ratio 来使得性能最优，因此 `Parallel scavenge collector` 应该总是开启 `-XX:+UseAdaptiveSizePolicy` 参数。此时JVM的参数配置如下：

~~~
java -server -Xms3072m -Xmx3072m -XX:+UseParallelGC -XX:ParallelGCThreads=4 -XX:+UseAdaptiveSizePolicy
~~~

## 6.2 响应时间优先

响应时间优先是指 GC 每次运行的时间不能太久，这种情况一般使用与对及时性要求很高的系统，比如股票系统等。

响应时间优先可以通过参数 `-XX:MaxGCPauseMillis `来配置，配置以后 JVM 将会自动调节年轻代，老生代的内存分配来满足参数设置。

在一般情况下，JVM 的默认配置就可以满足要求，只有默认配置不能满足系统的要求时候，才会根据具体的情况来对 JVM 进行性能调优。如果采用默认的配置不能满足系统的要求，那么此时就可以自己动手来调节。此时 Young generation 可以采用 `Parallel copying collector`，而 Old generation 则可以采用 `Concurrent Collector`。

举个例子来说，以下参数设置了新生代用 Parallel Copying Collector，老生代采用 CMS 收集器。

~~~
java -server -Xms512m -Xmx512m -XX:NewSize=64m -XX:MaxNewSize=64m -XX:SurvivorRatio=2 -XX:+UseConcMarkSweepGC -XX:+UseParNewGC
~~~

此时需要注意两个问题：

- 1.如果没有指定 `-XX:+UseParNewGC`，则采用默认的非并行版本的 copy collector
- 2.如果在一个单 CPU 的系统上设置了 `-XX:+UseParNewGC`，则默认还是采用缺省的copy collector

1.控制并行的线程数

默认情况下，Parallel copy collector 启动和 CPU 数量一样的线程，也可以通过参数 `-XX:ParallelGCThreads` 来指定，比如你想用 4 个线程去进行并发的复制收集，那么可以改变上述参数如下：

~~~
java -server -Xms512m -Xmx512m -XX:NewSize=64m -XX:MaxNewSize=64m -XX:SurvivorRatio=2 -XX:ParallelGCThreads=4 -XX:+UseConcMarkSweepGC -XX:+UseParNewGC
~~~

2.控制并发收集的临界值 

默认情况下，CMS GC在 old generation 空间占用率高于 68% 的时候，就会进行垃圾收集，而如果想控制收集的临界值，可以通过参数：`-XX:CMSInitiatingOccupancyFraction` 来控制，比如改变上述的JVM配置如下：

~~~
java -server -Xms512m -Xmx512m -XX:NewSize=64m -XX:MaxNewSize=64m -XX:SurvivorRatio=2 -XX:ParallelGCThreads=4 -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:CMSInitiatingOccupancyFraction=35
~~~

此外顺便说一个参数：`-XX:+PrintCommandLineFlags` 通过此参数可以知道在没有显示指定内存配置和垃圾收集算法的情况下，JVM 采用的默认配置。

比如我在自己的机器上面通过如下命令 `java -XX:+PrintCommandLineFlags -version` 得到的结果如下所示：

~~~
-XX:InitialHeapSize=1055308032 -XX:MaxHeapSize=16884928512 -XX:ParallelGCThreads=8 -XX:+PrintCommandLineFlags -XX:+UseCompressedOops -XX:+UseParallelGC
java version "1.6.0_45"
Java(TM) SE Runtime Environment (build 1.6.0_45-b06)
Java HotSpot(TM) 64-Bit Server VM (build 20.45-b01, mixed mode)
You have new mail in /var/spool/mail/root
~~~

从输出可以清楚的看到JVM通过自己检测硬件配置而给出的缺省配置。

# 参考资料

- [Jvm内存模型以及垃圾收集策略解析系列(一)](http://imtiger.net/blog/2010/02/21/jvm-memory-and-gc/)
- [Jvm内存模型以及垃圾收集策略解析系列(二)](http://imtiger.net/blog/2010/02/21/jvm-memory-and-gc-2/)
- [Java theory and practice: A brief history of garbage collection](http://www.ibm.com/developerworks/library/j-jtp10283/index.html?S_TACT=105AGX52&S_CMP=cn-a-j)
- [Java theory and practice: Garbage collection in the HotSpot JVM](http://www.ibm.com/developerworks/library/j-jtp11253/index.html?S_TACT=105AGX52&S_CMP=cn-a-j)
- [Understanding CMS GC Logs](https://blogs.oracle.com/poonam/entry/understanding_cms_gc_logs) 
- [Java HotSpot VM Options Server-Class Machine Detection](http://docs.oracle.com/javase/6/docs/technotes/guides/vm/server-class.html)
