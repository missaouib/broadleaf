---
layout: post
title: OpenNebula 2.2的特性
category: cloud
tags: [openNebula]
keywords: OpenNebula
description: OpenNebula 2.2的特性

---
<p>以下这篇文章由<a title="OpenNebula 2.2 Features" href="http://opennebula.org/documentation:features">OpenNebula 2.2 Features</a>翻译而来。</p>

<p>OpenNebula是一款为云计算而打造的开源工具箱。它允许你与Xen，KVM或VMware ESX一起建立和管理私有云，同时还提供Deltacloud适配器与Amazon EC2相配合来管理混合云。除了像Amazon一样的商业云服务提供商，在不同OpenNebula实例上运行私有云的Amazon合作伙伴也同样可以作为远程云服务供应商。</p>

<p>目前版本，可支持XEN、KVM和VMware，以及实时存取EC2和 ElasticHosts，它也支持印象档的传输、复制和虚拟网络管理网络。
<h2>主要特点和优势</h2>
<strong>私有云计算</strong><strong> </strong></p>

<p>为私有数据中心或集群（管理功能<strong>私有云计算</strong>）上运行<strong>的</strong><strong>Xen</strong>，<strong>KVM</strong>和<strong>VMware</strong><strong>的</strong>。
<table width="100%">
<tbody>
<tr bgcolor="cornsilk">
<td valign="top" width="107"><strong>模块</strong></td>
<td valign="top" width="453"><strong>功能</strong></td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>用户管理</strong></td>
<td valign="top" width="453">用户管理，认证框架，多个云用户和管理员角色，会计，配额管理，安全的多租户。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>VM</strong><strong>图像管理</strong></td>
<td valign="top" width="453">带目录的镜像仓库和镜像管理，访问控制，以及从正在运行的虚拟机创建镜像。</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>虚拟网络管理</strong></td>
<td valign="top" width="453">对互联的虚拟机;一定范围或固定的网络;虚拟网络共享;相关的第2层虚拟网络和网络隔离的通用属性定义提供虚拟网络管理。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>虚拟机管理</strong></td>
<td valign="top" width="453">虚拟机管理功能，支持在同一物理结构中的多个hypervisors，分布式环境的多个hypervisor管理，虚拟机自动配置，以及脚本在虚拟机的状态变化时的触发管理。</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>服务管理</strong></td>
<td valign="top" width="453">部署由多层次的相互联系的虚拟机组成的群体服务;在启动时自动配置，以及对微软Windows和Linux镜像的支持。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>基础设施管理</strong></td>
<td valign="top" width="453">管理物理主机;创建本地集群，占地面积小，占用空间不到700KB。</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>存储管理</strong></td>
<td valign="top" width="453">虚拟机映像管理，支持多种硬件平台（FibreChannel, iSCSI, NAS shared storage…）和存储后端传输镜像。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>信息管理</strong></td>
<td valign="top" width="453">虚拟机和物理基础设施的监控，并与数据监测工具集成，如</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>调度</strong></td>
<td valign="top" width="453">强大和灵活的竞价/排名调度、工作量和资源分配政策，如包装，分割，负载感知.....</td>
</tr>
<tr>
<td valign="top" width="107"><strong>用户界面</strong></td>
<td valign="top" width="453">Unix类似的云基础设施管理命令行。</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>运营中心</strong></td>
<td valign="top" width="453">图形化管理的云基础设施。</td>
</tr>
</tbody>
</table>
<!--more--></p>

<p><strong>混合云计算</strong></p>

<p>本地基础设施与远程云资源的扩展（<strong>混合云计算</strong>）
<table width="100%">
<tbody>
<tr bgcolor="cornsilk">
<td valign="top" width="111"><strong>模块</strong></td>
<td valign="top" width="449"><strong>功能</strong></td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="111"><strong>Cloudbursting</strong></td>
<td valign="top" width="449">本地的基础设施，可以辅从外部云计算能力，以满足高峰需求，更好地服务用户的访问请求，或者为了实现高可用性策略。支持亚马逊EC2，并同时访问多个云。</td>
</tr>
<tr>
<td valign="top" width="111"><strong>Federation</strong><strong> </strong></td>
<td valign="top" width="449">不同的云实例以构建一个独立的虚拟化集群层次;更高水平的可扩展性。</td>
</tr>
</tbody>
</table>
&nbsp;</p>

<p><strong>公共云计算</strong></p>

<p>暴露云接口给私有的基础设施功能（<strong>公共云计算</strong>）
<table width="100%">
<tbody>
<tr bgcolor="cornsilk">
<td valign="top" width="107"><strong>功能</strong></td>
<td valign="top" width="453"><strong>功能</strong></td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>云接口</strong></td>
<td valign="top" width="453">通过提供给用户的REST接口;实现OGF OCCI和亚马逊EC2接口，使本地的基础架构转变为一个公开云;支持同时公开多种云API，客户端工具，以及安全访问。</td>
</tr>
</tbody>
</table>
<h2>主要特点和集成优势</h2>
<table width="100%">
<tbody>
<tr bgcolor="cornsilk">
<td valign="top" width="107"><strong>功能</strong></td>
<td valign="top" width="453"><strong>功能</strong></td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>基础设施抽象</strong></td>
<td valign="top" width="453">无缝与任何操作平台的验证/授权，虚拟化，网络和存储平台融合，采用模块化结构，以适应任何数据中心。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>适应性和定制</strong></td>
<td valign="top" width="453">启用任何云架构的部署：公共，私有，混合和联合;定制插件来访问虚拟化、存储、信息、认证/授权和远程云服务，新的插件可以很容易地在任何语言编写，配置和改变参数调整云管理实例的行为以满足环境和用例要求;钩机制，当虚拟机的状态改变使触发管理脚本的执行。</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>互操作性和标准</strong></td>
<td valign="top" width="453">开放标准为基础的架构，以避免厂商锁定，提高互操作性​​，以及开放的实施标准。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>开放</strong></td>
<td valign="top" width="453">开源Apache许可下发布协议。</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>编程接口</strong></td>
<td valign="top" width="453">提供Ruby和Java XMLRPC的原生云API创建新的云接口和访问核心功能。</td>
</tr>
</tbody>
</table>
<h2>主要特点和生产效益</h2>
<table width="100%">
<tbody>
<tr bgcolor="cornsilk">
<td valign="top" width="107"><strong>特点</strong></td>
<td valign="top" width="453"><strong>功能</strong></td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>安全</strong></td>
<td valign="top" width="453">验证框架的密码，或基于SSH的RSA密钥对LDAP，外部和内部通信通过SSL，安全的多​​租户;隔离的网络。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>健壮性</strong></td>
<td valign="top" width="453">持久数据库后端存储主机、网络、虚拟机信息。</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>容错</strong></td>
<td valign="top" width="453">配置主机、虚拟机或OpenNebula实例故障事件。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>可扩展性</strong></td>
<td valign="top" width="453">测试在大规模的核心和成千上万的基础设施;高度可扩展的后端，并为MySQL和SQLite支持。</td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>性能</strong></td>
<td valign="top" width="453">非常高效的内核开发C++语言。</td>
</tr>
<tr>
<td valign="top" width="107"><strong>可靠性</strong></td>
<td valign="top" width="453">自动化的功能、可扩展性、性能、可靠性和稳定性测试过程。</td>
</tr>
</tbody>
</table>
<h2>利用充满活力的云生态系统</h2>
<table width="100%">
<tbody>
<tr bgcolor="cornsilk">
<td valign="top" width="107"></td>
<td valign="top" width="453"><strong>功能</strong></td>
</tr>
<tr bgcolor="aliceblue">
<td valign="top" width="107"><strong>OpenNebula Ecosystem</strong></td>
<td valign="top" width="453">充分利用<a title="http://www.opennebula.org/software:ecosystem" href="http://www.opennebula.org/software:ecosystem">OpenNebula开放云生态系统</a>与新元件加强了OpenNebula云工具包提供的功能并能够与其他产品的集成：vCloud的API、OpenNebula块、Haizea调度、 Libcloud、Deltacloud、Web管理控制台，Deltacloud的混合云适配器...</td>
</tr>
<tr>
<td valign="top" width="107"><strong>Other Cloud Ecosystems</strong></td>
<td valign="top" width="453">围绕Amazon AWS, OGC OCCI and VMware vCloud构建的生态系统。</td>
</tr>
</tbody>
</table></p>
