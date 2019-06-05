---
layout: post

title: Java笔记：IO

description: Java库的IO分为输入/输出两部分。

keywords: Java库的IO分为输入/输出两部分。

category: java

tags: [java,io]

published: true

---

说明，本文内容来源于[java io系列01之 "目录"](http://www.cnblogs.com/skywang12345/p/io_01.html)，做了一些删减。

Java库的IO分为输入/输出两部分。

早期的Java 1.0版本的输入系统是InputStream及其子类，输出系统是OutputStream及其子类。

后来的Java 1.1版本对IO系统进行了重新设计。输入系统是Reader及其子类，输出系统是Writer及其子类。

Java1.1之所以要重新设计，主要是为了添加国际化支持(即添加了对16位Unicode码的支持)。具体表现为Java 1.0的IO系统是字节流，而Java 1.1的IO系统是字符流。

字节流，就是数据流中最小的数据单元是8位的字节。

字符流，就是数据流中最小的数据单元是16位的字符。

字节流在操作的时候，不会用到缓冲；而字符流会用到缓冲。所以，字符流的效率会更高一些。

至于为什么用到缓冲会效率更高一些呢？那是因为，缓冲本质上是一段内存区域；而文件大多是存储在硬盘或者Nand Flash上面。读写内存的速度比读写硬盘或Nand Flash上文件的速度快很多！

目前，文件大多以字节的方式存储的。所以在开发中，字节流使用较为广泛。

# Java 1.0和Java 1.1 的IO类的比较

基本类对比表

|Java 1.0 IO基本类(字节流)|Java 1.1 IO基本类(字符流)|
|---|:---|
|InputStream|Reader|  
|OutputStream|Writer| 
|FileInputStream|FileReader|
|FileOutputStream|FileWriter|
|StringBufferInputStream|StringReader|
|无|StringWriter|
|ByteArrayInputStream|CharArrayReader|
|ByteArrayOutputStream|CharArrayWriter|
|PipedInputStream|PipedReader|
|PipedOutputStream|PipedWriter|

装饰器对比表

|Java 1.0 IO装饰器(字节流)|Java 1.1 IO装饰器(字符流)|
|---|:---|
|FilterInputStream|FilterReader|
|FilterOutputStream|FilterWriter（没有子类的抽象类|
|BufferedInputStream|BufferedReader（也有 readLine()）|
|BufferedOutputStream|BufferedWriter|
|DataInputStream|无|
|PrintStream|PrintWriter|
|LineNumberInputStream|LineNumberReader|
|StreamTokenizer|无|
|PushBackInputStream|PushBackReader|


# io框架

以字节为单位的输入流的框架图：

<img src="http://images.cnitblog.com/blog/497634/201310/20234201-95f7519c9a174cbbb8b3c6e0a076a56d.jpg" width="500"/>

是以字节为单位的输出流的框架图：

<img src="http://images.cnitblog.com/blog/497634/201310/20234231-929b2961bb604a05922c9a6ce1348110.jpg" width="500"/>

以字节为单位的输入流和输出流关联的框架图：

<img src="http://images.cnitblog.com/blog/497634/201310/20234245-b708d62c6397495db7915d8fee6616f7.jpg" alt="" width="740"/>

以字符为单位的输入流的框架图：

<img src="http://images.cnitblog.com/blog/497634/201310/20234317-f9f030ae18904626b08b8d464e87eed1.jpg" alt="" width="500"/>

以字符为单位的输出流的框架图：

<img src="http://images.cnitblog.com/blog/497634/201310/20234330-d18eb674e6ba44beb6d65b05c602f065.jpg" alt="" width="500"/>

以字符为单位的输入流和输出流关联的框架图：

<img src="http://images.cnitblog.com/blog/497634/201310/20234410-c986ccb259594865ae75f14f19e1179f.jpg" alt="" width="500"/>

字节转换为字符流的框架图：

<img src="http://images.cnitblog.com/blog/497634/201310/20234430-bb419718ff01462c8d94fc2ac3e1aeb6.jpg" alt="" width="500"/>

字节和字符的输入流对应关系：

<img src="http://images.cnitblog.com/blog/497634/201310/20234451-97f7312056a642ccb58ca02a2803dbb4.jpg" alt="" width="740"/>

字节和字符的输出流对应关系：

<img src="http://images.cnitblog.com/blog/497634/201310/20234541-d488f6a75e524979acfe8a77ff14ec78.jpg" alt="" width="740"/>
