---
layout: post
title: 接触云服务环境Eucalyptus
category: cloud
tags: [eucalyptus]
keywords: eucalyptus
description: 最近在接触云计算平台，熟悉了[Eucalyptus](http://www.eucalyptus.com/)，并用其搭建云环境。通过网上的一些例子，逐渐的摸索出用Eucalyptus搭建云计算平台的方法。我所用的Eucalyptus是免费版，缺少很多企业版的功能。
---

最近在接触云计算平台，熟悉了[Eucalyptus](http://www.eucalyptus.com/)，并用其搭建云环境。通过网上的一些例子，逐渐的摸索出用Eucalyptus搭建云计算平台的方法。我所用的Eucalyptus是免费版，缺少很多企业版的功能。

# Eucalyptus

Elastic Utility Computing Architecture for Linking Your Programs To Useful Systems （Eucalyptus） 是一种开源的软件基础结构，用来通过计算集群或工作站群实现弹性的、实用的云计算。它最初是美国加利福尼亚大学 Santa Barbara 计算机科学学院的一个研究项目，现在已经商业化，发展成为了 Eucalyptus Systems Inc。不过，Eucalyptus 仍然按开源项目那样维护和开发。Eucalyptus Systems 还在基于开源的 Eucalyptus 构建额外的产品；它还提供支持服务。 它提供了如下这些高级特性：

- 与 EC2 和 S3 的接口兼容性（SOAP 接口和 REST 接口）。使用这些接口的几乎所有现有工具都将可以与基于 Eucalyptus 的云协作。
- 支持运行在 Xen hypervisor 或 KVM 之上的 VM 的运行。未来版本还有望支持其他类型的 VM，比如 VMware。
- 用来进行系统管理和用户结算的云管理工具。
- 能够将多个分别具有各自私有的内部网络地址的集群配置到一个云内。

# 架构

Eucalyptus 包含五个主要组件，它们能相互协作共同提供所需的云服务。这些组件使用具有 WS-Security 的 SOAP 消息传递安全地相互通信。

Cloud Controller (CLC) 在 Eucalyptus 云内，这是主要的控制器组件，负责管理整个系统。它是所有用户和管理员进入 Eucalyptus 云的主要入口。所有客户机通过基于 SOAP 或 REST 的 API 只与 CLC 通信。由 CLC 负责将请求传递给正确的组件、收集它们并将来自这些组件的响应发送回至该客户机。这是 Eucalyptus 云的对外 “窗口”。 

Cluster Controller (CC) Eucalyptus 内的这个控制器组件负责管理整个虚拟实例网络。请求通过基于 SOAP 或 REST 的接口被送至 CC。CC 维护有关运行在系统内的 Node Controller 的全部信息，并负责控制这些实例的生命周期。它将开启虚拟实例的请求路由到具有可用资源的 Node Controller。 

Node Controller (NC) 它控制主机操作系统及相应的 hypervisor（Xen 或最近的 KVM，很快就会支持 VMWare）。必须在托管了实际的虚拟实例（根据来自 CC 的请求实例化）的每个机器上运行 NC 的一个实例。 Walrus (W) 这个控制器组件管理对 Eucalyptus 内的存储服务的访问。请求通过基于 SOAP 或 REST 的接口传递至 Walrus。 

Storage Controller (SC) Eucalyptus 内的这个存储服务实现 Amazon 的 S3 接口。SC 与 Walrus 联合工作，用于存储和访问虚拟机映像、内核映像、RAM 磁盘映像和用户数据。其中，VM 映像可以是公共的，也可以是私有的，并最初以压缩和加密的格式存储。这些映像只有在某个节点需要启动一个新的实例并请求访问此映像时才会被解密。

一个 Eucalyptus 云安装可以聚合和管理来自一个或多个集群的资源。一个集群 是连接到相同 LAN 的一组机器。在一个集群中，可以有一个或多个 NC 实例，每个实例管理虚拟实例的实例化和终止。

# Eucalyptus java源代码

在安装过程中，我把Eucalyptus的java源代码（eucalyptus-2.0.3-src-offline.tar.gz）下下来了，并按照[官方文档](http://open.eucalyptus.com/participate/sourcecode)的说明好不容易把java代码通过ant编译然后手动复制粘贴导入eclipse了，现在这些代码能够通过编译了，并能够清楚的看到Eucalyptus的java代码部分的实现方式

# 参考文章

- [1][Eucalyptus 开启云端](http://blog.163.com/firstsko@126/blog/static/132168891201022935737810/)
- [2][Installing Eucalyptus (2.0) on Fedora 12 ](http://open.eucalyptus.com/wiki/EucalyptusInstallationFedora_v2.0)
- [3][在Fedora 13 上搭建Eucalyptus](http://blog.csdn.net/hispania/archive/2010/09/24/5902926.aspx)
- [4][ubuntu 9.04 (server)下 eucalyptus 安装（推荐）](http://bbs.chinacloud.cn/archiver/showtopic-230.aspx)

