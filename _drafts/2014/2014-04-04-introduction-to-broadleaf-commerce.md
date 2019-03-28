---
layout: post
title: BroadleafCommerce介绍
description: BroadleafCommerce是一个Java开源电子商务网站框架。其目标是开发企业级商务网站，它提供健壮的数据和服务模型、富客户端管理平台、已经一些核心电子商务有关的工具
category: java
tags: 
 - java
published: true
---

# 1. 介绍

[BroadleafCommerce](http://www.broadleafcommerce.org/)是一个Java开源电子商务网站框架。其目标是开发企业级商务网站，它提供健壮的数据和服务模型、富客户端管理平台、已经一些核心电子商务有关的工具。

# 2. 特性

## 2.1	Catalog （目录分类）

提供灵活的产品和类型管理，一个重要的特性是可以继承产品分类来满足特殊的商业需求。管理界面可以管理各种类别和产品。

## 2.2	Promotion System（促销系统）

可通过配置的方式管理促销。以下类促销示无需客制化而通过管理界面即可管理：

- 百分比折扣、金额折扣、固定价格(Percent Off / Dollar Off / Fixed Price)
- 订单、订单项、快递级别促销
- 买一赠一促销
- 基于客户、购物车或类别属性的促销

## 2.3	Content Management System（内容管理系统）

内容管理系统有以下特性：

- 支持用户直接管理静态页面
- 可以配置顾客内容类型（如广告）
- 提供UI界面管理静态页面、结构化内容、图片以及其他内容；
- 结构化内容能够针对性的对某些客户显示（如对满足一定条件的客户显示广告）

# 3. 架构

## 3.1	Spring Framework

Spring提供诸多功能，包括依赖注入和事务管理

## 3.2	Security

Spring Security提供强健的安全认证框架，控制代码和页面级别的认证和授权。

## 3.3	Persistence

使用JPA和hibernate实现ORM基础

## 3.4	Asynchronous Messaging

使用spring JMS和一个现代的JMS代理交互来实现应用消息的异步处理。

## 3.5	Search

通过整合流行的Compass和lucene项目提供可灵活的domain查找功能。

## 3.6	Task Scheduling
使用Quartz提供排程功能。

## 3.7	Email
Email功能分为同步和异步（jms）两种模式。Email内容可以通过velocity模块客制化。支持mail打开和连接点击跟踪。

## 3.8	Modular Design（模块化设计）
提供各种模块，可以和电子商务的一些重要功能进行交互，如信用卡处理、税收服务、快递公司。
比如，USPS快递模块是一个好的案例。 客户模块可以很方便的开发并整合进来。

## 3.9	Configurable Workflows（可配置的工作流）
电子商务生命周期的关键表现在可配置的工作流。系统能够对这些关键的地方进行完全的控制，包括价格和结账，允许对订单、行为和客户执行模块进行操作。支持复杂内嵌行为的合成工作流。

## 3.10	Extensible Design（可扩展性设计）
扩展性是我们设计的核心，几乎broadleaf所有的组件都是可以继承、或添加、或者通过修改增强和改变默认的行为。 这些组件包括所有的service、数据访问对象、实体。

## 3.11	Configuration Merging（配置合并）
我们以扩展模块的附加部分，为客户提供对spring配置文件进行合并的功能。它可以最小化配置，一个实现必须清楚它允许用户只需把精力放在他们自己的配置细节。 Broadleaf在运行时会智能的将实现者的配置信息和自己的配置信息进行合并。

## 3.12	Runtime Configuration Management（运行时配置管理）

services、模块和其他子系统的配置属性通过JMX暴露，这样管理者不用关闭系统就可以改变应用行为。

## 3.13	Presentation Layer Support（表现层支持）

提供很多事先写好的spring MVC控制器来加快表现层的开发。

## 3.14	QoS（服务质量）
提供对客户和默认模块的服务质量监控，同时支持外部日志和email。其他客户Qos处理器可以通过我们的open API添加。

## 3.15	PCI Considerations（PCI注意事项）

我们的架构和设计经过了仔细的分析，帮助你在决定存储和使用敏感的客户金融账号信息的时候实现PCI遵从性。支付账号信息是分别引用的，允许你将机密的数据隔离存储到一个独立的安全的数据库平台。已经添加了API方法来包含PCI遵从性加密schema。另外，提供冗长的日志跟踪交易交互信息。

PCI（Payment Card Industry）(Payment Card Industry (PCI) Data Security Standard).支付卡行业 (PCI) 数据安全标准 (DSS)是一组全面的要求，旨在确保持卡人的信用卡和借记卡信息保持安全，而不管这些信息是在何处以何种方法收集、处理、传输和存储。

PCI DSS 由 PCI 安全标准委员会的创始成员（包括 American Express、Discover Financial Services、JCB、MasterCard Worldwide 和 Visa International）制定，旨在鼓励国际上采用一致的数据安全措施。

PCI DSS 中的要求是针对在日常运营期间需要处理持卡人数据的公司和机构提出的。具体而言，PCI DSS 对在整个营业日中处理持卡人数据的金融机构、贸易商和服务提供商提出了要求。PCI DSS 包括有关安全管理、策略、过程、网络体系结构、软件设计的要求的列表，以及用来保护持卡人数据的其他措施。

## 3.16	Customizable Administration Platform （客制化管理平台）

管理应用基于我们新的开放的管理平台，使用标准面向对象的技术提供一个清晰的客制化方式。管理平台和核心框架一样，都有很好扩展性。表现层是基于有名的可信赖的GWT和SmartGWT技术。

# 4. 源代码介绍

## 4.1 BroadLeaf核心领域对象分析

核心领域对象详见broadleaf-framework模块org.broadleafcommerce.core.*.domain包下的领域类。

## 4.2 BroadLeaf的子系统及其职责

Broadleaf做电子商务网站需要两部分内容。

**第一部分：**Broadleaf框架   Broadleaf电子商务框架由有9大模块组成(不包括第三方模块)

1) broadleaf-common  
各个模块共享的集合类. > 依赖于 broadleaf-instrument

2) broadleaf-framework   
Broadleaf框架的核心类 > 依赖 于broadleaf-common, broadleaf-profile, broadleaf-contentmanagement-module

3) broadleaf-framework-web   
Spring MVC 控制器和相关的项目 > 依赖于 broadleaf-framework, broadleaf-profile, broadleaf-profile-web

4) broadleaf-profile   
客户资料相关的类,工具类, email, 配置合并 > 依赖于 broadleaf-common

5) broadleaf-profile-web   
Spring MVC控制器和 相关项目的 profile 模块> 依赖于on broadleaf-profile

6) broadleaf-instrument   
允许运行时检测到某些 Broadleaf的注解> 无依赖

7) broadleaf-open-admin-platform   
为Hibernate管理的domains 创建可拓展的用户图形管理界面框架> 依赖于 broadleaf-common

8) broadleaf-contentmanagement-module   
通过管理工具管理的一个功能齐全的内容管理系统 > 依赖于 broadleaf-open-admin-platform

9) broadleaf-admin-module 
内容: Broadleaf 电子商务框架特定的管理模块，插入开发的管理平台> 依赖于 broadleaf-framework, broadleaf-open-admin-platform, broadleaf-contentmanagement-module

**第二部分：**需要在框架的基础上做web的开发，其框架已经封装了 已有功能的控制器方法，但是没有增加请求映射。[DemoSite](https://github.com/BroadleafCommerce/DemoSite)就是一个示例工程。

DemoSite 总共三个模块

- core:框架模块 集成了框架
- admin:后台管理页面的封装
- site:前台网站的封装

## 4.3 BroadLeaf的分层及层之间的通讯机制

BroadLeaf的DemoSite 站点通过Maven集成BroadLeaf框架的各个模块，各个模块通过方法调用进行集成。就像添加普通的jar包一样。

BroadLeaf框架采用常见的MVC架构  分为控制层 服务层  DAO层。

## 4.4 BroadLeaf的扩展机制

1) 界面拓展机制

BroadLeaf的界面与框架式分离的（后台管理页面是集成在broadleaf-open-admin-platform模块里面），界面采用thymeleaf模板引擎开发。界面的拓展只需要美工针对于他们的模板修改样式就行。

如果觉得他们的模板实在不好，直接自己开发一套模板 替换到一下就可以了 只需要在applicationContext-servlet.xml中修改替代的模板位置。

2) 用户拓展机制

BroadLeaf提供了 RegisterCustomerForm、CustomerAttributes两个类用户拓展用户属性。添加的属性只需要简单的配置一下就可以了（BroadLeaf采用的Hibernate的数据库字段同步，修改完实体后数据库会自动的修改）

3) 订单处理流程拓展机制

增加或者删除订单流程只需要配置blCheckoutWorkflow bean实体覆盖框架提供的。 然后再自定义Activiti任务  添加到新的blCheckoutWorkflow 的activities属性列表里面就可以了。

4) 付款方式拓展机制

增加新的付款实体 实现其付款接口。

5) 数据库切换方式

- 1.修改pom里面涉及到数据库连接的dependency为要切换的数据库的jdbc连接驱动
- 2.修改properties文件里面的数据库连接信息（用户名、密码、URL、driverClassName、hibernate数据库方言）
- 3.修改jndi连接信息 

# 5. 缺点

目前已知的缺点或缺陷有：

- 实体之间存在双向关联，导致无法直接使用json的工具类序列化和反序列化实体类。如果的确需要序列化实体类，比如说你需要提供api获取一些信息，你可以参考DemoSite中的api，对实体的封装类使用webservice进行序列化。

# 6. 参考文章

- [1] [BroadleafCommerce](http://www.broadleafcommerce.org/)
- [2] [DemoSite](https://github.com/BroadleafCommerce/DemoSite)
- [3] [认识Java电子商务开源框架BroadleafCommerce](http://sisopipo.com/blog/archives/553)
