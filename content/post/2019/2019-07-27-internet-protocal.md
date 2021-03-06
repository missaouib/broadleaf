---
layout: post
title: 网络通信协议
date: 2019-07-27T08:00:00+08:00
categories: [ devops ]
tags: [http,tcp,udp]
description:  Spring Boot中Tomcat调优

---

# 1 网络通信

## 1.1 协议

- TCP/IP

- UDP/IP

- Multcast
  - 单播.每次只有两个实体相互通信，发送端和接收端都是唯一确定的
    IP4中，0.0.0.0到223.255.255.255属于单播地址
  - 广播
  - 组播。IP4中，224.0.0.0到239.255.255.255

## 2 IO

- BIO
- NIO
- AIO

## 3 通信接口

**a、基于Java Api**

TCP/IP

- Socket/ServerSocket。
  - Socket是应用层与传输层的中间软件抽象层，它是一组接口。门面模式
  - Socket原理机制
    - 通信的两端都有Socket
    - 网络通信其实就是Socket间的通信
    - 数据在两个Socket间通过IO传输    
  - Socket通信的步骤
    - ① 创建ServerSocket和Socket
    - ② 打开连接到Socket的输入/输出流
    - ③ 按照协议对Socket进行读/写操作
    - ④ 关闭输入输出流、关闭Socket
  - 服务器端
    - ① 创建ServerSocket对象，绑定监听端口
    - ② 通过accept()方法监听客户端请求
    - ③ 连接建立后，通过输入流读取客户端发送的请求信息
    - ④ 通过输出流向客户端发送响应信息
    - ⑤ 关闭相关资源
  - 客户端
    - ① 创建Socket对象，指明需要连接的服务器的地址和端口号
    - ② 连接建立后，通过输出流向服务器端发送请求信息
    - ③ 通过输入流获取服务器响应的信息
    - ④ 关闭响应资源
- SocketChannel
- MultcastSocket

UDP

- DatagramSocket
- DatagramChannel

  

**b、基于框架**

- Mina
- Netty
- Dubbo
- 考虑性能：长链接/链接池


**c、基于远程通信技术**

- RMI
- WebService
- EJB
- Spring RMI/Apache CXF
- Dubbo
- hessian
- thrift
- http

# 2 HTTP协议

## 2.1 概述

协议：约束规则

网络协议：数据在网络上传输规则

Http协议：Hyper text transform protocal 如何在互联网传输文本。它是一种应用层协议（OSI七层模型的最顶层），它基于TCP/IP通信协议来传递数据（HTML 文件， 图片文件，查询结果等）。

Http协议格式：请求响应模型：

- 请求部分
- 响应部分



## 2.2 发展历史

| 版本     | 产生时间 | 内容                                                         | 发展现状           |
| -------- | -------- | ------------------------------------------------------------ | ------------------ |
| HTTP/0.9 | 1991年   | 不涉及数据包传输，规定客户端和服务器之间通信格式，只能GET请求 | 没有作为正式的标准 |
| HTTP/1.0 | 1996年   | 传输内容格式不限制，增加PUT、PATCH、HEAD、 OPTIONS、DELETE命令 | 正式作为标准       |
| HTTP/1.1 | 1997年   | 长连接、节约带宽、HOST域、管道机制、分块传输编码             | 2015年前使用最广泛 |
| HTTP/2   | 2015年   | 多路复用、服务器推送、头信息压缩、二进制协议等               | 逐渐覆盖市场       |

在HTTP协议的初始版本中，每进行一次HTTP通信就要断开一次TCP连接。
假设这样的一个应用场景：使用浏览器请求一个包含多张图片的HTML页面时，在发送请求访问HTML页面资源的同时，也会请求该HTML里面包含的其他资源。因此，每次的请求都会造成无谓的TCP连接建立和断开，增加通信量的开销。

为了解决上述TCP连接的问题，HTTP想出了持久连接（HTTP **keep-alive**）的方法。持久连接的特点是：只要任意一端没有明确提出断开连接，则保持TCP连接状态。
管线化持久连接使得多数请求以管线化方式发送成为可能。从前发送请求后需要等待并收到响应后，才能发送下一个请求。管线化技术出现后，不用等待响应亦可直接发送下一个请求，这样就能够同时并行发送多个请求，而不需要一个接一个地等待响应了。

## 2.3 HTTP特点

1、HTTP是无连接
无连接的含义是限制每次连接只处理一个请求。服务器处理完客户的请求，并收到客户的应答后，即断开连接。采用这种方式可以节省传输时间

2、HTTP是媒体独立的
只要客户端和服务器知道如何处理的数据内容，任何类型的数据都可以通过HTTP发送。客户端以及服务器指定使用适合的MIME-type内容类型

3、HTTP是无状态
无状态是指协议对于事务处理没有记忆能力。缺少状态意味着如果后续处理需要前面的信息，则它必须重传，这样可能导致每次连接传送的数据量增大。另一方面，在服务器不需要先前信息时它的应答就较快

4、简单快速、灵活

5、通信使用明文、请求和响应不会对通信方进行确认、无法保护数据的完整性

## 2.4 **HTTP请求**

HTTP请求是客户端往服务端发送请求动作，告知服务器自己的要求。

HTTP请求由状态行、请求头、请求正文三部分组成：

- 状态行：包括请求方式Method、资源路径URL、协议版本Version；

- 请求头：包括一些访问的域名、用户代理、Cookie等信息；

- 请求正文：就是HTTP请求的数据。	

![img](http://ww4.sinaimg.cn/large/006tNc79gy1g5do9mffr0j30ox0eptb9.jpg)

### **请求行**

- 请求方法
  - GET。请求指定的页面信息，并返回实体主体
  - POST。向指定资源提交数据进行处理请求（例如提交表单或者上传文件）。数据被包含在请求体中。POST请求可能会导致新的资源的建立和/或已有资源的修改
  - HEAD。类似于get请求，只不过返回的响应中没有具体的内容，用于获取报头
  - PUT。从客户端向服务器传送的数据取代指定的文档的内容
  - DELETE。请求服务器删除指定的页面
  - OPTIONS。允许客户端查看服务器的性能
  - TRACE。回显服务器收到的请求，主要用于测试或诊断
  - CONNECT。HTTP/1.1协议中预留给能够将连接改为管道方式的代理服务器
- 请求URL
- http协议及版本
  - 1.1
  - 2



### 请求头

首部的信息主要以键值对key-value的方式存在。
示例

```
content-type：text/html 表示返回的文本类型
Connetcion：keep-alive  保持连接
Accept-CharSet：utf-8 客户端接收的文本编码为utf-8
Cache-Controller：控制缓存
Accept：告诉服务端客户端接受什么类型的响应
Cookie：cookie
Referer：表示这个请求是从哪个URL过来的
```

### **请求数据**

约定用户的表单数据向服务端传递格式。

## 2.5 HTTP响应

HTTP的响应报文也由三部分组成：**响应行+响应头+响应体**。

![img](http://ww1.sinaimg.cn/large/006tNc79gy1g5do9wnalij30hh087q3g.jpg)

### 响应行

- 1.http协议及版本
  - 1.1
  - 2
- 2.状态码及状态描述
  - 1：信息性状态码
    告诉客户端，请求收到，正在处理
  - **2**：成功状态码
    200：OK 请求正常处理
    204：No Content请求处理成功，但没有资源可返回
    206：Partial Content对资源的某一部分的请求
  - 3：重定向状态码
    301：Moved Permanently 永久重定向
    302：Found 临时性重定向
    304：Not Modified 缓存中读取**
  - **4**：客户端错误状态码
    400：Bad Request 请求报文中存在语法错误
    401：Unauthorized需要有通过Http认证的认证信息
    403：Forbidden访问被拒绝
    404：Not Found无法找到请求资源
  - 5：服务器错误状态码
    500：Internal Server Error 服务器端在执行时发生错误
    503：Service Unavailable 服务器处于超负载或者正在进行停机维护



### 响应头

- 服务器告诉浏览器服务器信息
- 对本次响应的表述
- 常见响应头
  - Date
  - content-Type
  - content-Encoding
  - content-Lenght

### 响应体

请求的响应数据。



## 2.6 HTTP请求流程

1、域名解析：什么是DNS？DNS查询过程？

  - 在浏览器DNS中搜索
  - 在操作系统DNS中搜索
  - 读取系统hosts文件，查找其中是否有对应的ip
  - 向本地配置的首选DNS服务器发起域名解析请求

2、建立TCP连接

3、发起http请求

4、响应http请求

5、浏览器解析html

按顺序解析html文件，构建DOM树

- 若是下载css文件，则解析器会在下载的同时继续解析后面的html来构建DOM树
- 若是下载js文件，则在下载js文件和执行它时，解析器会停止对html的解析
- 解析到外部的css和js文件时，向服务器发起请求下载资源
- 构建渲染树

6、断开TCP连接

![](http://ww1.sinaimg.cn/large/006tNc79gy1g5doa3pq5ij30en0hy0v7.jpg)

客户端输入URL回车，DNS解析域名得到服务器的IP地址，服务器在80端口监听客户端请求，端口通过TCP/IP协议（可以通过Socket实现）建立连接。HTTP属于TCP/IP模型中的运用层协议，所以通信的过程其实是对应数据的入栈和出栈。 

![img](http://ww3.sinaimg.cn/large/006tNc79gy1g5doa6o9csj30jn0gtwfx.jpg)

报文从运用层传送到运输层，运输层通过TCP三次握手和服务器建立连接，四次挥手释放连接。

![](http://ww1.sinaimg.cn/large/006tNc79gy1g5doa8rhl1j30i80cimx4.jpg)

为什么需要三次握手呢？为了防止已失效的连接请求报文段突然又传送到了服务端，因而产生错误。

比如：client发出的第一个连接请求报文段并没有丢失，而是在某个网络结点长时间的滞留了，以致延误到连接释放以后的某个时间才到达server。本来这是一个早已失效的报文段，但是server收到此失效的连接请求报文段后，就误认为是client再次发出的一个新的连接请求，于是就向client发出确认报文段，同意建立连接。假设不采用“三次握手”，那么只要server发出确认，新的连接就建立了，由于client并没有发出建立连接的请求，因此不会理睬server的确认，也不会向server发送数据，但server却以为新的运输连接已经建立，并一直等待client发来数据。所以没有采用“三次握手”，这种情况下server的很多资源就白白浪费掉了。

![](http://ww2.sinaimg.cn/large/006tNc79gy1g5doac5kg7j30j70czjui.jpg)

为什么需要四次挥手呢？TCP是全双工模式，当client发出FIN报文段时，只是表示client已经没有数据要发送了，client告诉server，它的数据已经全部发送完毕了；但是，这个时候client还是可以接受来server的数据；当server返回ACK报文段时，表示它已经知道client没有数据发送了，但是server还是可以发送数据到client的；当server也发送了FIN报文段时，这个时候就表示server也没有数据要发送了，就会告诉client，我也没有数据要发送了，如果收到client确认报文段，之后彼此就会愉快的中断这次TCP连接。



# 3 HTTPS协议

## 3.1 HTTPS概述

《图解HTTP》这本书中曾提过HTTPS是身披SSL外壳的HTTP。HTTPS是一种通过计算机网络进行安全通信的传输协议，经由HTTP进行通信，利用SSL/TLS建立全信道，加密数据包。HTTPS使用的主要目的是提供对网站服务器的身份认证，同时保护交换数据的隐私与完整性。

> PS:TLS是传输层加密协议，前身是SSL协议，由网景公司1995年发布，有时候两者不区分。


**HTTP＋加密＋认证＋完整性保护＝HTTPS**
HTTPS并非是应用层的一种新协议。只是HTTP通信接口部分用SSL和TSL协议代替而已，通常，HTTP直接和TCP通信，当使用SSL时，则演变成先和SSL通信，再由SSL和TCP通信了。简言之，所谓HTTPS其实就是身披SSL协议这层外壳的HTTP。
当采用SSL后，HTTP就拥有了HTTPS的加密、证书和完整性保护这些功能。而且SSL协议是独立于HTTP的协议，所以不光是HTTP协议，其他运行在应用层的SMTP和Telnet等协议均可配合SSL协议使用。可以说SSL是当今世界上应用最为广泛的网络安全技术。

## 3.2 HTTPS特点

基于HTTP协议，通过SSL或TLS提供加密处理数据、验证对方身份以及数据完整性保护。

HTTPS有如下特点：

1. 内容加密：采用混合加密技术，中间者无法直接查看明文内容
2. 验证身份：通过证书认证客户端访问的是自己的服务器
3. 保护数据完整性：防止传输的内容被中间人冒充或者篡改



> 混合加密：结合非对称加密和对称加密技术。客户端使用对称加密生成密钥对传输数据进行加密，然后使用非对称加密的公钥再对秘钥进行加密，所以网络上传输的数据是被秘钥加密的密文和用公钥加密后的秘密秘钥，因此即使被黑客截取，由于没有私钥，无法获取到加密明文的秘钥，便无法获取到明文数据。 

> 数字摘要：通过单向hash函数对原文进行哈希，将需加密的明文“摘要”成一串固定长度(如128bit)的密文，不同的明文摘要成的密文其结果总是不相同，同样的明文其摘要必定一致，并且即使知道了摘要也不能反推出明文。 

> 数字签名技术：数字签名建立在公钥加密体制基础上，是公钥加密技术的另一类应用。它把公钥加密技术和数字摘要结合起来，形成了实用的数字签名技术。
>
> - 收方能够证实发送方的真实身份；
> - 发送方事后不能否认所发送过的报文；
> - 收方或非法者不能伪造、篡改报文。

![](http://ww4.sinaimg.cn/large/006tNc79gy1g5doair1a8j315p0tjk0k.jpg)



## 3.3 HTTPS实现原理

![](http://ww2.sinaimg.cn/large/006tNc79gy1g5doal544sj30m80kadgz.jpg)

- client向server发送请求https://baidu.com ，然后连接到server的443端口。

- 服务端必须要有一套数字证书，可以自己制作，也可以向组织申请。区别就是自己颁发的证书需要客户端验证通过，才可以继续访问，而使用受信任的公司申请的证书则不会弹出提示页面，这套证书其实就是一对公钥和私钥。

- 传送证书 
  这个证书其实就是公钥，只是包含了很多信息，如证书的颁发机构，过期时间、服务端的公钥，第三方证书认证机构(CA)的签名，服务端的域名信息等内容。

- 客户端解析证书 
  这部分工作是由客户端的TLS来完成的，首先会验证公钥是否有效，比如颁发机构，过期时间等等，如果发现异常，则会弹出一个警告框，提示证书存在问题。如果证书没有问题，那么就生成一个随即值（秘钥）。然后用证书对该随机值进行加密。

- 传送加密信息 
  这部分传送的是用证书加密后的秘钥，目的就是让服务端得到这个秘钥，以后客户端和服务端的通信就可以通过这个随机值来进行加密解密了。

- 服务段加密信息 
  服务端用私钥解密秘密秘钥，得到了客户端传过来的私钥，然后把内容通过该值进行对称加密。

- 传输加密后的信息 
  这部分信息是服务端用私钥加密后的信息，可以在客户端被还原。

- 客户端解密信息 

  客户端用之前生成的私钥解密服务端传过来的信息，于是获取了解密后的内容。



HTTP／1.1使用的认证方式如下：

- BASIC认证（基本认证）
- DIGEST认证（摘要认证）
- SSL客户端认证
- FormBase认证（基于表单认证）

**问题：** 
1.怎么保证保证服务器给客户端下发的公钥是真正的公钥，而不是中间人伪造的公钥呢？

![](http://ww2.sinaimg.cn/large/006tNc79gy1g5doaoasrlj30jf0ds0tf.jpg)

![](http://ww4.sinaimg.cn/large/006tNc79gy1g5doaqo3dvj30pq0ev41p.jpg)

2.证书如何安全传输，被掉包了怎么办？

数字证书包括了加密后服务器的公钥、权威机构的信息、服务器域名，还有经过CA私钥签名之后的证书内容（经过先通过Hash函数计算得到证书数字摘要，然后用权威机构私钥加密数字摘要得到数字签名)，签名计算方法以及证书对应的域名。当客户端收到这个证书之后，使用本地配置的权威机构的公钥对证书进行解密得到服务端的公钥和证书的数字签名，数字签名经过CA公钥解密得到证书信息摘要，然后根据证书上描述的计算证书的方法计算一下当前证书的信息摘要，与收到的信息摘要作对比，如果一样，表示证书一定是服务器下发的，没有被中间人篡改过。因为中间人虽然有权威机构的公钥，能够解析证书内容并篡改，但是篡改完成之后中间人需要将证书重新加密，但是中间人没有权威机构的私钥，无法加密，强行加密只会导致客户端无法解密，如果中间人强行乱修改证书，就会导致证书内容和证书签名不匹配。
那第三方攻击者能否让自己的证书显示出来的信息也是服务端呢？（伪装服务端一样的配置）显然这个是不行的，因为当第三方攻击者去CA那边寻求认证的时候CA会要求其提供例如域名的whois信息、域名管理邮箱等证明你是服务端域名的拥有者，而第三方攻击者是无法提供这些信息所以他就是无法骗CA他拥有属于服务端的域名



# 4 TCP/IP协议

## 4.1 概述

TCP/IP（Transmission Control Protocol/Internet Protocol）是一种可靠的网络数据传输控制协议。定义了主机如何连入因特网以及数据如何在他们之间传输的标准。

## 4.2 特点

- 面向连接
- 可靠的数据流
- 全双工通信
  - 单工：数据传输只支持数据在一个方向上传输
  - 半双工：数据传输允许数据在两个方向上传输，但是在某一时刻，只允许在一个方向上传输，实际上有点像切换方向的单工通信
  - 全双工：数据通信允许数据同时在两个方向上传图片输，因此全双工是两个单工通信方式的结合，它要求发送设备和接收设备都有独立的接

## 4.3 四层模型

TCP/IP协议参考模型把所有TCP/IP系列协议归类到四个抽象层中，每一个抽象层建立在低一层提供的服务上，并且为高一层提供服务。

![img](http://ww1.sinaimg.cn/large/006tNc79gy1g5doatf6azj30fi05raa2.jpg)



### 网络接口层

**这一块主要主要涉及到一些物理传输，比如以太网，无线局域网**。

### 网络层

前面有提到，网络层主要就是做物理地址与逻辑地址之间的转换．

目前市场上应用的最多的是 32 位二进制的 IPv4，因为 IPv4 的地址已经不够用了，所以 128 位二进制的 IPv6 应用越来越广泛了(但是下面的介绍都是基于 IPv4 进行的)。

#### 1) IP

TCP/IP 协议网络上的每一个网络适配器都有一个唯一的 IP 地址.

IP 地址是一个 32 位的地址,这个地址通常分成 4 端，每 8 个二进制为一段，但是为了方便阅读，通常会将每段都转换为十进制来显示，比如大家非常熟悉的 192.168.0.1

IP 地址分为两个部分：

- 网络 ID
- 主机 ID

但是具体哪部分属于网络 ID，哪些属于主机 ID 并没有规定。

因为有些网络是需要很多主机的，这样的话代表主机 ID 的部分就要更多，但是有些网络需要的主机很少，这样主机 ID 的部分就应该少一些.

绝大部分 IP 地址属于以下几类

- A 类地址：IP 地址的前 8 位代表网络 ID ，后 24 位代表主机 ID。
- B 类地址：IP 地址的前 16 位代表网络 ID ，后 16 位代表主机  ID。
- C 类地址：IP 地址的前 24 位代表网络 ID ，后 8 位代表主机  ID。

这里能够很明显的看出 A 类地址能够提供出的网络 ID 较少，但是每个网络可以拥有非常多的主机

但是我们怎么才能看出一个 IP 地址到底是哪类地址呢？

- 如果 32 位的 IP 地址以 0 开头，那么它就是一个 A 类地址。
- 如果 32 位的 IP 地址以 10 开头，那么它就是一个 B 类地址。
- 如果 32 位的 IP 地址以 110 开头，那么它就是一个 C 类地址。

那么转化为十进制（四段）的话，我们就能以第一段中的十进制数来区分 IP 地址到底是哪类地址了。

![img](http://ww3.sinaimg.cn/large/006tNc79gy1g5doruv92hj30m009gwee.jpg)

注意：

- 十进制第一段大于 223 的属于 D 类和 E 类地址，这两类比较特殊也不常见，这里就不做详解介绍了。
- 每一类都有一些排除地址，这些地址并不属于该类，他们是在一些特殊情况使用地址（后面会介绍）
- 除了这样的方式来划分网络，我们还可以把每个网络划分为更小的网络块，称之为子网（后面会介绍）

**全是 0 的主机 ID 代表广播**，比如说 IP 地址为 130.100.0.0 指的是网络 ID 为130.100 的 B 类地址。

**全是 1 的主机 ID 代表广播**，是用于向该网络中的全部主机方法消息的。 IP 地址为 130.100.255.255 就是网络 ID 为 130.100 网络的广播地址（二进制 IP 地址中全是 1 ，转换为十进制就是 255 ）。

**以十进制 127 开头的地址都是环回地址**。目的地址是环回地址的消息，其实是由本地发送和接收的。主要是用于测试 TCP/IP 软件是否正常工作。我们用 ping 功能的时候，一般用的环回地址是 127.0.0.1。

#### **2) ARP**

**地址解析协议，简单的来说 ARP 的作用就是把 IP 地址映射为物理地址，而与之相反的 RARP（逆向 ARP）就是将物理地址映射为 IP 地址。**

#### **3) 子网**

前面提到了 IP 地址的分类，但是对于 A 类和 B 类地址来说，每个网络下的主机数量太多了，那么网络的传输会变得很低效，并且很不灵活。比如说 IP地址为 100.0.0.0 的 A 类地址，这个网络下的主机数量超过了 1600 万台，所以**子网掩码**的出现就是为了解决这样的问题。

我们先回顾一下之前如何区分主机 IP 和网络 IP 的，以 A 类地址 99.10.10.10 为例，前 8 位是网络 IP ，后 24 位是主机 IP 。

![img](http://ww1.sinaimg.cn/large/006tNc79gy1g5doopv7j4j30x90633yc.jpg)

子网掩码也是一个 32 为的二进制数，也可以用四个十进制数来分段，他的每一位对应着 IP 地址的相应位置，数值为 1 时代表的是非主机位，数值为 0 时代表是主机位。

![img](http://ww3.sinaimg.cn/large/006tNc79gy1g5doome0nwj315c08q74f.jpg)

**由表格可以很清晰的看出，网络 IP 仍是由之前的分类来决定到底是多少位，主机 IP 则是由子网掩码值为 0 的位数来决定，剩下的则是子网 IP**



**3、TCP三次握手和四次挥手的全过程**

三次握手：

第一次握手：客户端发送syn包(syn=x)到服务器，并进入SYN_SEND状态，等待服务器确认；

第二次握手：服务器收到syn包，必须确认客户的SYN（ack=x+1），同时自己也发送一个SYN包（syn=y），即SYN+ACK包，此时服务器进入SYN_RECV状态；

第三次握手：客户端收到服务器的SYN＋ACK包，向服务器发送确认包ACK(ack=y+1)，此包发送完毕，客户端和服务器进入ESTABLISHED状态，完成三次握手。

握手过程中传送的包里不包含数据，三次握手完毕后，客户端与服务器才正式开始传送数据。理想状态下，TCP连接一旦建立，在通信双方中的任何一方主动关闭连接之前，TCP 连接都将被一直保持下去。

四次握手

与建立连接的“三次握手”类似，断开一个TCP连接则需要“四次握手”。

第一次挥手：主动关闭方发送一个FIN，用来关闭主动方到被动关闭方的数据传送，也就是主动关闭方告诉被动关闭方：我已经不 会再给你发数据了(当然，在fin包之前发送出去的数据，如果没有收到对应的ack确认报文，主动关闭方依然会重发这些数据)，但是，此时主动关闭方还可 以接受数据。

第二次挥手：被动关闭方收到FIN包后，发送一个ACK给对方，确认序号为收到序号+1（与SYN相同，一个FIN占用一个序号）。
第三次挥手：被动关闭方发送一个FIN，用来关闭被动关闭方到主动关闭方的数据传送，也就是告诉主动关闭方，我的数据也发送完了，不会再给你发数据了。
第四次挥手：主动关闭方收到FIN后，发送一个ACK给被动关闭方，确认序号为收到序号+1，至此，完成四次挥手。

**4、各种协议**

ICMP协议： 因特网控制报文协议。它是TCP/IP协议族的一个子协议，用于在IP主机、路由器之间传递控制消息。

TFTP协议： 是TCP/IP协议族中的一个用来在客户机与服务器之间进行简单文件传输的协议，提供不复杂、开销不大的文件传输服务。

HTTP协议： 超文本传输协议，是一个属于应用层的面向对象的协议，由于其简捷、快速的方式，适用于分布式超媒体信息系统。

DHCP协议： 动态主机配置协议，是一种让系统得以连接到网络上，并获取所需要的配置参数手段。

NAT协议：网络地址转换属接入广域网(WAN)技术，是一种将私有（保留）地址转化为合法IP地址的转换技术，

DHCP协议：一个局域网的网络协议，使用UDP协议工作，用途：给内部网络或网络服务供应商自动分配IP地址，给用户或者内部网络管理员作为对所有计算机作中央管理的手段。

### 传输层

传输层提供了两种到达目标网络的方式

- 传输控制协议（TCP）：提供了完善的错误控制和流量控制，能够确保数据正常传输，是一个面向连接的协议。
- 用户数据报协议（UDP）：只提供了基本的错误检测，是一个无连接的协议。

**TCP和UDP的区别**

- TCP提供面向连接的、可靠的数据流传输（TCP 协议使用 **超时重传、数据确认**等方式来确保数据包被正确地发送至目的端）；而UDP提供的是非面向连接的、不可靠的数据流传输。

- TCP传输单位称为TCP报文段，数据大小无限制；UDP传输单位称为用户数据报，数据大小有限制（64k），接收端必须以该长度为最小单位将其所有内容一次性读出。

- TCP注重数据安全性，速度慢，但是可靠性高；UDP数据传输快，因为不需要连接等待，少了许多操作，但是其安全性却一般。
-  TCP 的连接是一对一的，所以如果是基于广播或者多播的的应用程序不能使用 TCP，而 UDP 则非常适合广播和多播。

总结一句定义：

> TCP 协议（Transmission Control Protocal，传输控制协议）为**应用层**提供**可靠的、面向连接的、基于流**的服务。而 UDP 协议（User Datagram Protocal，用户数据报协议）则与 TCP 协议完全相反，它为**应用层**提供**不可靠、无连接和基于数据报的服务**。



**TCP对应的协议和UDP对应的协议**

TCP对应的协议：

（1） FTP：定义了文件传输协议，使用21端口。

（2） Telnet：一种用于远程登陆的端口，使用23端口，用户可以以自己的身份远程连接到计算机上，可提供基于DOS模式下的通信服务。

（3） SMTP：邮件传送协议，用于发送邮件。服务器开放的是25号端口。

（4） POP3：它是和SMTP对应，POP3用于接收邮件。POP3协议所用的是110端口。

（5）HTTP：是从Web服务器传输超文本到本地浏览器的传送协议。

UDP对应的协议：

（1） DNS：用于域名解析服务，将域名地址转换为IP地址。DNS用的是53号端口。

（2） SNMP：简单网络管理协议，使用161号端口，是用来管理网络设备的。由于网络设备很多，无连接的服务就体现出其优势。

（3） TFTP(Trival File Tran敏感词er Protocal)，简单文件传输协议，该协议在熟知端口69上使用UDP服务。

### 应用层

应用层运行在TCP协议上的协议：

- HTTP（Hypertext Transfer Protocol，超文本传输协议），主要用于普通浏览。
- HTTPS（Hypertext Transfer Protocol over Secure Socket Layer，or HTTP over SSL，安全超文本传输协议）,HTTP协议的安全版本。
- FTP（File Transfer Protocol，文件传输协议），由名知义，用于文件传输。
- POP3（Post Office Protocol，version 3，邮局协议），收邮件用。
- SMTP（Simple Mail Transfer Protocol，简单邮件传输协议），用来发送电子邮件。
- TELNET（Teletype over the Network，网络电传），通过一个终端（terminal）登陆到网络。
- SSH（Secure Shell，用于替代安全性差的TELNET），用于加密安全登陆用。

运行在UDP协议上的协议：

- BOOTP（Boot Protocol，启动协议），应用于无盘设备。
- NTP（Network Time Protocol，网络时间协议），用于网络同步。
- DHCP（Dynamic Host Configuration Protocol，动态主机配置协议），动态配置IP地址。

其他：

- DNS（Domain Name Service，域名服务），用于完成地址查找，邮件转发等工作（运行在TCP和UDP协议上）。
- ECHO（Echo Protocol，回绕协议），用于查错及测量应答时间（运行在TCP和UDP协议上）。
- SNMP（Simple Network Management Protocol，简单网络管理协议），用于网络信息的收集和网络管理。
- ARP（Address Resolution Protocol，地址解析协议），用于动态解析以太网硬件的地址。

**DNS工作原理**

DNS是应用层协议，事实上他是为其他应用层协议工作的，包括不限于HTTP和SMTP以及FTP，用于将用户提供的主机名解析为IP地址。

DNS服务的作用：把域名解析为IP地址，将IP地址解析为域名。

当DNS客户机需要在程序中使用名称时，它会查询DNS服务器来解析该名称。客户机发送的每条查询信息包括三条信息：包括：指定的DNS域名，指定的查询类型，DNS域名的指定类别。基于UDP服务，端口53

DNS的查询过程如下所示：

![img](http://ww3.sinaimg.cn/large/006tNc79gy1g5dobbi3t4j30or0dfn5z.jpg)

1、在浏览器中输入 www.qq.com 域名，操作系统会先检查自己**本地的hosts文件**是否有这个网址映射关系，如果有，就先调用这个IP地址映射，完成域名解析。

2、查找**本地DNS解析器缓存**是否有这个网址映射关系，如果有，直接返回，完成域名解析。

3、查找TCP/IP参数中设置的**首选DNS服务器**，在此我们叫它本地DNS服务器。

4、如果要查询的域名，不由本地DNS服务器区域解析，但该服务器已缓存了此网址映射关系，则调用这个IP地址映射，完成域名解析，此解析不具有权威性。

5、根据本地DNS服务器的设置（**是否设置转发器**）进行查询，**如果未用转发模式**，本地DNS就把请求发至13台根DNS，根DNS服务器收到请求后会判断这个域名(.com)是谁来授权管理，并会返回一个负责该顶级域名服务器的一个IP。本地DNS服务器收到IP信息后，将会联系负责.com域的这台服务器。这台负责.com域的服务器收到请求后，如果自己无法解析，它就会找一个管理.com域的下一级DNS服务器地址(http://qq.com)给本地DNS服务器。当本地DNS服务器收到这个地址后，就会找 http://qq.com 域服务器，重复上面的动作，进行查询，直至找到 www.qq.com 主机。

6、**如果用的是转发模式**，此DNS服务器就会把请求转发至上一级DNS服务器，由上一级服务器进行解析，上一级服务器如果不能解析，或找根DNS或把转请求转至上上级，以此循环。

不管是本地DNS服务器用是是转发，还是根提示，最后都是把结果返回给本地DNS服务器，由此DNS服务器再返回给客户机。
从客户端到本地DNS服务器是属于递归查询，而DNS服务器之间就是的交互查询就是迭代查询。

## 4.4 TCP协议

### TCP报文头

![Alt text](http://ww4.sinaimg.cn/large/006tNc79gy1g5dobdo0nfj30yk0mrmxn.jpg)

我们来分析分析每部分的含义和作用

- 源端口号/目的端口号: 表示数据从哪个进程来，到哪个进程去.
- 32位序号:
- 4位首部长度: 表示该tcp报头有多少个4字节(32个bit)
- 6位保留: 顾名思义，先保留着，以防万一
- 6位标志位

16位源端口号与16位目的端口号。

32位序号：在建立连接（或者关闭）的过程，这个序号是用来做占位，当 A 发送连接请求到 B，这个时候会带上一个序号（随机值，称为 ISN），而 B 确认连接后，会把这个序号 +1 返回，同时带上自己的充号。当建立连接后，该序号为生成的随机值 ISN 加上该段报文段所携带的数据的第一个字节在整个字节流中的偏移量。比如，某个 TCP 报文段发送的数据是字节流中的第 100 ~ 200 字节，那该序号为 ISN + 100。所以总结起来说明建立连接（或者关闭）时，序号的作用是为了占位，而连接后，是为了标记当前数据流的第一个字节。

4位头部长度：标识 TCP 头部有多少个 32 bit 字，因为是 4位，即 TCP 头部最大能表示 15，即最长是 60 字节。即它是用来记录头部的最大长度。

6位标志位，包括：
URG 标志：表示紧急指针是否有效。
**ACK 标志：确认标志。通常称携带 ACK 标志的 TCP 报文段为确认报文段。**
PSH 标志：提示接收端应该程序应该立即从 TCP 接收缓冲区中读走数据，为接收后续数据腾出空间（如果不读走，数据就会一直在缓冲区内）。
RST 标志：表示要求对方重新建立连接。**通常称携带 RST 标志的 TCP 报文段为复位报文段**。
**SYN 标志：表示请求建立一个连接。通常称携带 SYN 标志的 TCP 报文段称为同步报文段**。
**FIN 标志：关闭标志，通常称携带 FIN 标志的 TCP 报文段为结束报文段**。
**这些标志位说明了当前请求的目的，即要干什么。**

16 位窗口大小：表示当前 TCP 接收缓冲区还能容纳多少字节的数据，这样发送方就可以控制发送数据的速度，**它是 TCP 流量控制的一个手段。**

16 位校验和：验证数据是否损坏，通过 CRC 算法检验。**这个校验不仅包括 TCP 头部，也包括数据部分。**

16 位紧急指针：正的偏移量，它和序号字段的值相加表示最后一个紧急数据的下一字节的序号。TCP 的紧急指针是发送端向接收端发送紧急数据的方法。

TCP 头部选项：可变长的可选信息，这部分最多包含 40 字节，因为 TCP 头部最长是 60 字节，所以固定部分占 20 字节。

### 三次握手

先来解释三次握手过程：

1、发送端发送连接请求，6位标志为 SYN，同时带上自己的序号（此时由于不传输数据，所以不表示字节的偏移量，只是占位），比如是 223。

2、接收端接到请求，表示同意连接，发送同意响应，带上 SYN + ACK 标志位，同时将确认序号为 224（发送端序号加1），并带上自己的序号（此时同样由于不传输数据，所以不表示字节的偏移量，只是占位），比如是 521。

3、发送端接收到确认信息，再发回给接收端，表示我已接受到你的确认信息，此时标志仍为 ACK，确认序号为 522。

涉及到的问题：为什么是三次握手，而不是四次或者两次？

首先解释为什么不是四次。四次的过程是这样的：

发送方：我要连你了。
接收方：好的。
接收方：我准备好了，你连吧。
发送方：好的。

显然接收方准备好连接并同意连接是可以合并的，这样可以提高连接的效率。

再来，我们解释为什么不是两次。其实也比较好理解，我们知道 TCP 是全双工通信的，同时也是可靠的，连接和关闭都是两边都要执行才算真正的完成，同时还需要确保两端都已经执行了连接或者关闭。如果只有两次，过程是这样的：

发送方：我要连你了。
接收方：好的。

很明显，接收方并不知道也不能保证发送方一定接收到 “好的” 这条信息，一旦接收方真的没有收到这条信息，就会出现接收收“单方面连接”的情况，这个时候发送方就会一直重试发送连接请求，直到真正收到 “好的” 这条信息之后才算连接完成。而对于三次，如果发送方没有等待到你回复确认，它是不会真正处于连接状态的，它会重试确认请求。

### 四次挥手

接着我们来看看四次挥手过程：

1、发送方发送关闭请求，标志位为：FIN，同时也会带上自己的序号（此时同样由于不传输数据，所以不表示字节的偏移量，只是占位）。

2、接收方接到请求后，回复确认：ACK，同时确认序号为请求序号加1。

3、接收方也决定关闭连接，发送关闭通知，标志位为 FIN，同时还会带上第2步中的确认信息，即 ACK，以及确认序号和自己的序号。

4、发送方回复确认信息：ACK，接收方序号加1。

**涉及到的问题：**为什么需要四次握手，不是三次？

三次的过程是这样的：

发送方：我不再给你发送数据了。
接收方：好的，我也不给你发了。
发送方：好的，拜拜。

这是因为当接收方收到关闭请求后，它能立马响应的就是确认关闭，它这里确认的是接收方的关闭，即发送方不再发数据给接收方了，但他还是可以接收接收方发给他的数据。而接收方是否需要关闭“发送数据给发送方”这条通道，取决于操作系统。操作系统也有可能 sleep 个几秒再关闭，如果合并成三次，就可能造成接收方不能及时收到确认请求，可能造成超时重试等情况。因此需要四次。

### 什么是 TIME_WAIT 状态

当一方断开连接后，它并没有直接进入 CLOSED 状态，而是转移到 TIME_WAIT 状态，在这个状态，需要等待 2MSL（Maximum Segment Life，报文段最大生存时间）的时间，才能完全关闭。

涉及问题：
**1、为什么需要有 TIME_WAIT 状态存在？**

简单来说有两点原因如下：

a. 当最后发送方发出确认信息后，仍然不能保证接收方能收到信息，万一没收到，那接收方就会重试，而此时发送方已经真正关闭了，就接受不到请求了。

b. 如果发送方在发出确认信息后就关闭了，在接收方接到确认信息的过程中，发送方是有可能再次发出连接请求的，那这个时候就乱套了。刚连接完，又收到确认关闭的信息。

**2、为什么时长是 2MSL 呢？**

这个其实也比较好理解，所以我发送确认信息，到达最长时间是 MSL，而你如果没接受到，再重试，时间最长也是 MSL，那我等 2MSL，如果还没收到请求，证明你真的已经正常收到了。

正因为我们有这个 TIME_WAIT 状态，所以通常我们说是客户端先关闭，一般不会让服务器端先关闭，可以设置关闭时端口可复用。

> 使用setsockopt()设置socket描述符的选项SO_REUSEADDR为1，表示允许创建端口号相同但IP地址不同的多个socket描述符.

### 确认应答机制(ACK机制)

![](http://ww1.sinaimg.cn/large/006tNc79gy1g5dobgvijgj30kp0kg77q.jpg)

TCP将每个字节的数据都进行了编号， 即为序列号。
![](http://ww3.sinaimg.cn/large/006tNc79gy1g5dobjqb9wj30vz0b6dk3.jpg)

每一个ACK都带有对应的确认序列号，意思是告诉发送者，我已经收到了哪些数据；下一次你要从哪里开始发。
比如，客户端向服务器发送了1005字节的数据，服务器返回给客户端的确认序号是1003，那么说明服务器只收到了1-1002的数据，1003、1004、1005都没收到，此时客户端就会从1003开始重发。

### 超时重传机制

![](http://ww4.sinaimg.cn/large/006tNc79gy1g5dobm5g1aj30mw0kgdji.jpg)

主机A发送数据给B之后，可能因为网络拥堵等原因，数据无法到达主机B。如果主机A在一个特定时间间隔内没有收到B发来的确认应答，就会进行重发，但是主机A没收到确认应答也可能是ACK丢失了。

![](http://ww1.sinaimg.cn/large/006tNc79gy1g5dobod07xj30n80k8adv.jpg)

这种情况下，主机B会收到很多重复数据，那么TCP协议需要识别出哪些包是重复的，并且把重复的丢弃. 
这时候利用前面提到的序列号，就可以很容易做到去重。

**超时时间如何确定?** 

最理想的情况下， 找到一个最小的时间，保证 “确认应答一定能在这个时间内返回”。
但是这个时间的长短，随着网络环境的不同，是有差异的。
如果超时时间设的太长，会影响整体的重传效率；如果超时时间设的太短，有可能会频繁发送重复的包。

TCP为了保证任何环境下都能保持较高性能的通信，因此会动态计算这个最大超时时间。

- Linux中(BSD Unix和Windows也是如此)， 超时以500ms为一个单位进行控制，每次判定超时重发的超时时间都是500ms的整数倍。
- 如果重发一次之后，仍然得不到应答，等待 2\*500ms 后再进行重传。如果仍然得不到应答，等待 4\*500ms 进行重传。
- 依次类推，以指数形式递增，累计到一定的重传次数，TCP认为网络异常或者对端主机出现异常，强制关闭连接。

### 滑动窗口

刚才我们讨论了确认应答机制，对每一个发送的数据段，都要给一个ACK确认应答，收到ACK后再发送下一个数据段。
这样做有一个比较大的缺点，就是性能较差，尤其是数据往返时间较长的时候。
那么我们可不可以一次发送多个数据段呢？例如这样: 

![](http://ww4.sinaimg.cn/large/006tNc79gy1g5dobrcwnkj30pr0hnwkp.jpg)

 窗口大小指的是无需等待确认应答就可以继续发送数据的最大值。上图的窗口大小就是4000个字节 (四个段)。

发送前四个段的时候，不需要等待任何ACK，直接发送。收到第一个ACK确认应答后，窗口向后移动，继续发送第五六七八段的数据…

因为这个窗口不断向后滑动，所以叫做滑动窗口。
操作系统内核为了维护这个滑动窗口，需要开辟发送缓冲区来记录当前还有哪些数据没有应答，只有ACK确认应答过的数据，才能从缓冲区删掉。

![](http://ww4.sinaimg.cn/large/006tNc79gy1g5dobwv9s7j30rt0i5jzj.jpg)


如果出现了丢包，那么该如何进行重传呢?

此时分两种情况讨论:

1，数据包已经收到，但确认应答ACK丢了。

![](http://ww1.sinaimg.cn/large/006tNc79gy1g5doc0q0azj30qt0fuwka.jpg)

这种情况下，部分ACK丢失并无大碍，因为还可以通过后续的ACK来确认对方已经收到了哪些数据包。

2，数据包丢失 

![](http://ww3.sinaimg.cn/large/006tNc79gy1g5doc3tvsjj30rz0htwgm.jpg)

当某一段报文丢失之后，发送端会一直收到 1001 这样的ACK，就像是在提醒发送端 “我想要的是 1001” 。
如果发送端主机连续三次收到了同样一个 “1001” 这样的应答，就会将对应的数据 1001 - 2000 重新发送，
这个时候接收端收到了 1001 之后，再次返回的ACK就是7001了。
因为2001 - 7000接收端其实之前就已经收到了，被放到了接收端操作系统内核的接收缓冲区中。

**这种机制被称为 “高速重发控制” ( 也叫 “快重传” )**

### 流量控制

接收端处理数据的速度是有限的。如果发送端发的太快，导致接收端的缓冲区被填满，这个时候如果发送端继续发送，就会造成丢包，进而引起丢包重传等一系列连锁反应。
因此TCP支持根据接收端的处理能力，来决定发送端的发送速度，这个机制就叫做 流量控制(Flow Control)。

接收端将自己可以接收的缓冲区大小放入 TCP 首部中的 “窗口大小” 字段，通过ACK通知发送端；窗口大小越大，说明网络的吞吐量越高；接收端一旦发现自己的缓冲区快满了，就会将窗口大小设置成一个更小的值通知给发送端；发送端接受到这个窗口大小的通知之后，就会减慢自己的发送速度；如果接收端缓冲区满， 就会将窗口置为0；
这时发送方不再发送数据，但是需要定期发送一个窗口探测数据段，让接收端把窗口大小再告诉发送端。

![](http://ww2.sinaimg.cn/large/006tNc79gy1g5doc6o19vj30ri0ljgte.jpg)

那么接收端如何把窗口大小告诉发送端呢? 
我们的TCP首部中，有一个16位窗口大小字段，就存放了窗口大小的信息；
16位数字最大表示65536，那么TCP窗口最大就是65536字节么? 
实际上，TCP首部40字节选项中还包含了一个窗口扩大因子M，实际窗口大小是窗口字段的值左移 M 位(左移一位相当于乘以2)。

### 拥塞控制

虽然TCP有了滑动窗口这个大杀器，能够高效可靠地发送大量数据。但是如果在刚开始就发送大量的数据，仍然可能引发一些问题。
因为网络上有很多计算机，可能当前的网络状态已经比较拥堵. 
在不清楚当前网络状态的情况下，贸然发送大量数据，很有可能雪上加霜.

因此，TCP引入 **慢启动** 机制，先发少量的数据，探探路，摸清当前的网络拥堵状态以后，再决定按照多大的速度传输数据.

![](http://ww2.sinaimg.cn/large/006tNc79gy1g5docafhirj30ol0mhjzv.jpg)

在此引入一个概念 **拥塞窗口**

发送开始的时候，定义拥塞窗口大小为1；每次收到一个ACK应答，拥塞窗口加1；每次发送数据包的时候，将拥塞窗口和接收端主机反馈的窗口大小做比较，取较小的值作为实际发送的窗口。
像上面这样的拥塞窗口增长速度，是指数级别的。
“慢启动” 只是指初使时慢，但是增长速度非常快。为了不增长得那么快，此处引入一个名词叫做慢启动的阈值，当拥塞窗口的大小超过这个阈值的时候，不再按照指数方式增长，而是按照线性方式增长。

![](http://ww1.sinaimg.cn/large/006tNc79gy1g5docglocmj30p30c2djo.jpg)

当TCP开始启动的时候，慢启动阈值等于窗口最大值。
在每次超时重发的时候，慢启动阈值会变成原来的一半，同时拥塞窗口置回1。
少量的丢包，我们仅仅是触发超时重传； 大量的丢包，我们就认为是网络拥塞； 当TCP通信开始后，网络吞吐量会逐渐上升； 随着网络发生拥堵，吞吐量会立刻下降。

拥塞控制，归根结底是TCP协议想尽可能快的把数据传输给对方，但是又要避免给网络造成太大压力的折中方案。



### 延迟应答

如果接收数据的主机立刻返回ACK应答，这时候返回的窗口可能比较小。
假设接收端缓冲区为1M. 一次收到了500K的数据； 如果立刻应答，返回的窗口大小就是500K； 但实际上可能处理端处理的速度很快，10ms之内就把500K数据从缓冲区消费掉了； 在这种情况下，接收端处理还远没有达到自己的极限，即使窗口再放大一些，也能处理过来； 如果接收端稍微等一会儿再应答，比如等待200ms再应答，那么这个时候返回的窗口大小就是1M

窗口越大，网络吞吐量就越大，传输效率就越高。TCP的目标是在保证网络不拥堵的情况下尽量提高传输效率；那么所有的数据包都可以延迟应答么? 肯定也不是，有两个限制：

- 数量限制: 每隔N个包就应答一次
- 时间限制: 超过最大延迟时间就应答一次。具体的数量N和最大延迟时间，依操作系统不同也有差异，一般 N 取2，最大延迟时间取200ms。

### 捎带应答

在延迟应答的基础上，我们发现，很多情况下，客户端和服务器在应用层也是 “一发一收” 的，意味着客户端给服务器说了 “How are you”，服务器也会给客户端回一个 “Fine，thank you” ，那么这个时候ACK就可以搭顺风车，和服务器回应的 “Fine，thank you” 一起发送给客户端。

![](http://ww3.sinaimg.cn/large/006tNc79gy1g5docje6x1j30rc0jxwk5.jpg)

### 面向字节流

创建一个TCP的socket，同时在内核中创建一个 发送缓冲区 和一个 接收缓冲区； 调用write时，数据会先写入发送缓冲区中； 如果发送的字节数太大，会被拆分成多个TCP的数据包发出； 如果发送的字节数太小，就会先在缓冲区里等待，等到缓冲区大小差不多了，或者到了其他合适的时机再发送出去； 接收数据的时候，数据也是从网卡驱动程序到达内核的接收缓冲区； 然后应用程序可以调用read从接收缓冲区拿数据； 另一方面，TCP的一个连接，既有发送缓冲区，也有接收缓冲区，那么对于这一个连接，既可以读数据，也可以写数据，这个概念叫做 **全双工**

由于缓冲区的存在，所以TCP程序的读和写不需要一一匹配 
例如:

- 写100个字节的数据，可以调用一次write写100个字节，也可以调用100次write，每次写一个字节；

- 读100个字节数据时，也完全不需要考虑写的时候是怎么写的，既可以一次read 100个字节，也可以一次read一个字节，重复100次；

  

### 粘包问题

首先要明确，粘包问题中的 “包”，是指应用层的数据包。在TCP的协议头中，没有如同UDP一样的 “报文长度” 字段，但是有一个序号字段。
站在传输层的角度，TCP是一个一个报文传过来的. 按照序号排好序放在缓冲区中。
站在应用层的角度，看到的只是一串连续的字节数据。那么应用程序看到了这一连串的字节数据，就不知道从哪个部分开始到哪个部分是一个完整的应用层数据包。此时数据之间就没有了边界，就产生了**粘包问题**。

那么如何避免粘包问题呢? 归根结底就是一句话，明确两个包之间的边界。

对于定长的包 
- 保证每次都按固定大小读取即可 
例如上面的Request结构，是固定大小的，那么就从缓冲区从头开始按sizeof(Request)依次读取即可

对于变长的包 
- 可以在数据包的头部，约定一个数据包总长度的字段，从而就知道了包的结束位置 
还可以在包和包之间使用明确的分隔符来作为边界(应用层协议，是程序员自己来定的，只要保证分隔符不和正文冲突即可)

对于UDP协议来说，是否也存在 “粘包问题” 呢?

> 对于UDP，如果还没有向上层交付数据，UDP的报文长度仍然存在. 
> 同时，UDP是一个一个把数据交付给应用层的，就有很明确的数据边界. 
> 站在应用层的角度，使用UDP的时候，要么收到完整的UDP报文，要么不收. 
> 不会出现收到 “半个” 的情况.

### TCP 异常情况

进程终止: 进程终止会释放文件描述符，仍然可以发送FIN，和正常关闭没有什么区别。

机器重启: 和进程终止的情况相同。

机器掉电/网线断开: 接收端认为连接还在，一旦接收端有写入操作，接收端发现连接已经不在了，就会进行 reset. 即使没有写入操作，TCP自己也内置了一个保活定时器，会定期询问对方是否还在. 如果对方不在，也会把连接释放。

另外，应用层的某些协议，也有一些这样的检测机制。

例如：HTTP长连接中，也会定期检测对方的状态。

例如QQ，在QQ断线之后，也会定期尝试重新连接.

### TCP 小结

为什么TCP这么复杂？因为既要保证可靠性，同时又要尽可能提高性能。

保证可靠性的机制：

- 校验和
- 序列号(按序到达)
- 确认应答
- 超时重传
- 连接管理
- 流量控制
- 拥塞控制

提高性能的机制：

- 滑动窗口
- 快速重传
- 延迟应答
- 捎带应答

定时器：

- 超时重传定时器
- 保活定时器
- TIME_WAIT定时器

# 5 DHCP

# 6 参考文章

- [Spring Boot开启HTTPS)](https://blog.csdn.net/zuozewei/article/details/84727095)
- [TCP 协议中的三次握手与四次挥手及相关概念详解](http://www.imooc.com/article/288582)
- [TCP 详解](https://blog.csdn.net/sinat_36629696/article/details/80740678)
