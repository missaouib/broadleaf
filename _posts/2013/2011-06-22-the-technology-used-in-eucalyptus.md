---
layout: post
title: Eucalyptus使用的技术
category: cloud
tags: [eucalyptus]
keywords: eucalyptus
description: Eucalyptus使用的技术

---

- [libvirt](http://libvirt.org/)

Libvirt 库是一种实现 Linux 虚拟化功能的 Linux® API，它支持各种虚拟机监控程序，包括 Xen 和 KVM，以及 QEMU 和用于其他操作系统的一些虚拟产品。

- [Netty](http://www.jboss.org/netty/)

Netty 提供异步的、事件驱动的网络应用程序框架和工具，用以快速开发高性能、高可靠性的网络服务器和客户端程序。

- [Axis2](http://ws.apache.org/axis2/)

Axis2是下一代 Apache Axis。Axis2 虽然由 Axis 1.x 处理程序模型提供支持，但它具有更强的灵活性并可扩展到新的体系结构。Axis2 基于新的体系结构进行了全新编写，而且没有采用 Axis 1.x 的常用代码。支持开发 Axis2 的动力是探寻模块化更强、灵活性更高和更有效的体系结构，这种体系结构可以很容易地插入到其他相关 Web 服务标准和协议（如 WS-Security、WS-ReliableMessaging 等）的实现中。

- [Axis2c](http://ws.apache.org/axis2/c/)

Apache Axis2/C is a Web services engine implemented in the C programming language. It is based on the extensible and flexible Axis2 architecture.

- [Rampart/C](http://ws.apache.org/rampart/c/)

Apache Axis2/C的安全模块

- [JiBX](http://jibx.sourceforge.net/)

JiBX是一款非常优秀的XML（Extensible Markup Language）数据绑定框架。它提供灵活的绑定映射文件实现数据对象与XML文件之间的转换；并不需要你修改既有的Java类。另外，另外，它的转换效率是目前很多开源项目都无法比拟的。

- [Bouncy Castle](http://www.bouncycastle.org/java.html)

Bouncy Castle 是一种用于 Java 平台的开放源码的轻量级密码术包。它支持大量的密码术算法，并提供 JCE 1.2.1 的实现。因为 Bouncy Castle 被设计成轻量级的，所以从 J2SE 1.4 到 J2ME（包括 MIDP）平台，它都可以运行。它是在 MIDP 上运行的唯一完整的密码术包。

- [Mule](http://mule.mulesource.org/display/MULE/Home)

它是一个轻量级的消息框架和整合平台，基于EIP（Enterprise Integeration Patterns,由Hohpe和Woolf编写的一本书）而实现的。Mule的核心组件是UMO(Universal Message Objects，从Mule2.0开始UMO这一概念已经被组件Componse所代替)，UMO实现整合逻辑。UMO可以是POJO,JavaBean等等。它支持20多种传输协议(file,FTP,UDP,SMTP,POP,HTTP,SOAP,JMS等)，并整合了许多流行的开源项目，比如Spring,ActiveMQ,CXF,Axis,Drools等。虽然Mule没有基于JBI来构建其架构，但是它为JBI容器提供了JBI适配器，应此可以很好地与JBI容器整合在一起。而 Mule更关注其灵活性，高效性以及易开发性。从2005年发表1.0版本以来，Mule吸引了越来越多的关注者，成为开源ESB中的一支独秀。目前许多公司都使用了Mule，比如Walmart,HP,Sony,Deutsche Bank 以及 CitiBank等公司。

- [Hibernate](http://www.hibernate.org/)

Hibernate是一个开放源代码的对象关系映射框架，它对JDBC进行了非常轻量级的对象封装，使得Java程序员可以随心所欲的使用对象编程思维来操纵数据库。 Hibernate可以应用在任何使用JDBC的场合，既可以在Java的客户端程序使用，也可以在Servlet/JSP的Web应用中使用，最具革命意义的是，Hibernate可以在应用EJB的J2EE架构中取代CMP，完成数据持久化的重任。

- [HSQLDB](http://www.hsqldb.org/)

Hsqldb是一个开放源代码的JAVA数据库，其具有标准的SQL语法和JAVA接口，它可以自由使用和分发，非常简洁和快速的。在其官网可以获得最新的程序源代码及jar包文件

- [Xen](http://xen.org/)

Xen 是一个开放源代码[虚拟机](http://baike.baidu.com/view/1132.htm)监视器，由剑桥大学开发。它打算在单个计算机上运行多达100个满特征的操作系统。操作系统必须进行显式地修改（“移植”）以在Xen上运行（但是提供对用户应用的兼容性）。这使得Xen无需特殊硬件支持，就能达到高性能的虚拟化。

- [KVM}(http://www.linux-kvm.org/page/Main_Page)
基于内核的虚拟机(或简称为KVM)是一个由Qumrannet开发和赞助的开源项目.

- [Google Web Toolkit](http://code.google.com/webtoolkit/)

Google Web Toolkit (GWT) 允许开发人员使用Java 编程语言快速构建和维护复杂而又高性能的JavaScript 前端应用程序，从而降低了开发难度

- [LVM2](http://sourceware.org/lvm2/)

LVM是 Logical Volume Manager(逻辑卷管理)的简写，它是Linux环境下对磁盘分区进行管理的一种机制，它由Heinz Mauelshagen在Linux 2.4内核上实现，目前最新版本为：稳定版1.0.5，开发版 1.1.0-rc2，以及LVM2开发版。

- [Jetty](http://jetty.codehaus.org/jetty/)

Jetty 是一个开源的servlet容器，它为基于Java的web内容，例如JSP和servlet提供运行环境。Jetty是使用Java语言编写的，它的API以一组JAR包的形式发布。开发人员可以将Jetty容器实例化成一个对象，可以迅速为一些独立运行（stand-alone）的Java应用提供网络和web连接。
