---
layout: post
title: Eucalyptus EE的介绍及功能说明
category: cloud
tags: [eucalyptus]
keywords: eucalyptus
description: Eucalyptus企业版是一个基于Linux的软件架构，在企业现有的IT架构上实现一个可扩展的、提高效率的私有和混合云。Eucalyptus作为基础设施提供IaaS服务。这意味着用户可以通过Eucalyptus自助服务界面提供自己的资源（硬件、存储和网络）。一个Eucalyptus云是部署在企业的内部数据中心，由企业内部用户访问。因此，敏感数据可以在防火墙的保护下防止外部入侵。
---
<p>Eucalyptus企业版2.0是一个基于Linux的软件架构，在企业现有的IT架构上实现一个可扩展的、提高效率的私有和混合云。Eucalyptus作为基础设施提供IaaS服务。这意味着用户可以通过Eucalyptus自助服务界面提供自己的资源（硬件、存储和网络）。一个Eucalyptus云是部署在企业的内部数据中心，由企业内部用户访问。因此，敏感数据可以在防火墙的保护下防止外部入侵。</p>

<p>Eucalyptus的设计目的是从根本上易于安装和尽可能没有侵扰。该软件高度模块化，具有行业标准，和语言无关。它提供了可以与EC2兼容的云计算平台和与S3兼容的云存储平台。<!--more-->
<h1>功能亮点</h1>
<ul>
	<li>无缝管理多个管理程序环境（Xen的，vSphere的，KVM，ESX，ESXi的）下一个管理控制台</li>
	<li>启用跨平台的客户机操作系统包括微软Windows和Linux</li>
	<li>高级存储集成器（iSCSI，SAN，NAS），您可以轻松地连接和管理Eucalyptus云内现有的存储系统</li>
	<li>完善的用户和组管理，允许私有云资源的精确控制</li>
	<li>测试，开发和部署能够顺利过渡到公共云或反之亦然，没有任何修改</li>
	<li>快速，轻松地建立与基于VMware的虚拟化环境和其他公共云混合云</li>
	<li>启用先进设备，最先进的企业，如可扩展的存储整合，监控，审计，报表</li>
	<li>利用充满活力的生态系统围绕亚马逊AWS构建，提供解决方案，无缝地与Eucalyptus兼容</li>
</ul>
<h1>优点</h1>
<ul>
	<li>建立一个私有云，让你接入到亚马逊AWS</li>
	<li>允许云在原有的所有硬件和软件类型很容易的部署</li>
	<li>客户可以利用其全球用户社区</li>
	<li>Eucalyptus是与Linux和多个管理程序兼容</li>
	<li>Eucalyptus还支持商业Linux发行版本：红帽企业Linux（RHEL）和SUSE Linux企业服务器（SLES）</li>
</ul>
<h1>对于IT管理员的好处</h1>
<ul>
	<li>提供自助服务的IT基础设施供应到最终用户需要的IT资源迅速</li>
	<li>没有额外的资金保持现有的基础设施费用，降低运营成本</li>
	<li>保持防火墙后面的关键数据</li>
	<li>技术是对现有的硬件和软件基础设施覆盖，而不是替代</li>
	<li>避免锁定在第三方公共云供应商</li>
	<li>可轻松转换之间来回私人和公共云</li>
</ul>
&nbsp;
<h1>Eucalyptus EE新特性</h1>
<h2><strong><span style="color: #0000ff;">对windows VM的支持</span></strong></h2>
1.  运行windows 虚拟机在Eucalyptus 云环境上运行，目前支持Windows 2003 Server,Windows 2008 Server和Windows 7。<br />
2.  试用Euca2ools管理和控制windows虚拟机。<br />
3.  试用EC2兼容的命令从正在运行的windows虚拟机创建新的虚拟机<br />
4.  在Eucalyptus中通过标准的RDP客户端工具，使用AWS “get-password”访问虚拟机实例<br />
5.  在多个hypervisors环境中部署windows虚拟机，包括Xen、Kvm、VMware（ESX/ESXi）<br />
6.  基于windows 操作系统安装文件（ISO镜像、CD/DVD）创建新的windows虚拟机
<h2><strong><span style="color: #0000ff;">对VMware的支持</span></strong></h2>
1.支持VMware vCenter 4.0,ESX/ESXi 4.0!<br />
2.与VMware vSphere 客户端兼容<br />
3.能够合并VMware(ESX/ESXi)和开源的hypervisors（Xen、Kvm）到一个单独的云环境<br />
4.通过Eucalyptus的软件扩展一些云的基本特性（例如IPs，安全组，S3）到一个VMware基础架构</p>

<p>&nbsp;
<h2><strong><span style="color: #0000ff;">引入SAN的支持</span></strong></h2>
Eucalyptus EE引入对SAN的支持，使你能够整合enterprise-grade SAN(Storage Area Network) 硬件设备到Eucalyptus云环境。SAN扩展SC并在Eucalyptus中运行的虚拟机和SAN设备之间提供高性能的数据通道。Eucalyptus EE的SAN支持为Eucalyptus云环境提供了一个企业级的EBS解决方案。</p>

<p>&nbsp;
<h1>Eucalyptus的功能</h1>
<h2><strong><span style="color: #0000ff;">基本组成部分及功能</span></strong></h2>
<table border="1" cellspacing="0" cellpadding="0" width="614" align="left">
<tbody>
<tr>
<td width="102" valign="top">模块</td>
<td width="279" valign="top">功能</td>
<td width="234" valign="top">说明</td>
</tr>
<tr>
<td width="102" valign="top">云控制器（CLC）</td>
<td width="279" valign="top">1.对外提供EC2和Web接口，管理各类组件中的可用虚拟资源（服务、网络、存储）。<br />
2.资源抽象，决定哪个簇将提供给实例，分发请求给CC。<br />
3.管理运行的实例。</td>
<td width="234" valign="top">CLC是整个云结构的前端。CLC为客户工具提供与EC2/S3兼容的网络接口，与Eucalyptus的组件通信。</td>
</tr>
<tr>
<td width="102" valign="top">存储控制器（SC）</td>
<td width="279" valign="top">1.提供与EBS类似的存储功能，能够与大量的文件存储系统交互。<br />
2.使用AoE或者iSCSI协议为实例提供块存储。<br />
3.允许在存储系统中（如Walrus）建立快照。</td>
<td width="234" valign="top">SC提供实例使用的块存储。<br />
与EBS类似。&nbsp;</td></tr></tbody></table></p>

<p>&nbsp;

<tr>
<td width="102" valign="top">Walrus控制器（WS3）</td>
<td width="279" valign="top">1.允许用户存储持久化的数据。<br />
2.提供REST接口操作数据，设置数据访问策略。<br />
3.使用S3 API存储和获取虚拟镜像和数据。</td>
<td width="234" valign="top">WS3使用与S3 API兼容的REST和SOAP   API提供简单的存储服务</td>
</tr>
<tr>
<td width="102" valign="top">控制簇（CC）</td>
<td width="279" valign="top">1.接收CLC的请求，然后部署实例。<br />
2.收集虚拟机的信息并决定在哪个节点控制上执行虚拟机。<br />
3.为实例提供有效的虚拟网络。<br />
4.收集NCs提交的信息，并报告给CLC。</td>
<td width="234" valign="top">CC管理NC，部署和管理在节点上的实例，在Eucalyptus联网模型的类型下管理在控制节点上运行的实例的联网。<br />
CC连接着云控制器CLC和控制节点NC。</td>
</tr>
<tr>
<td width="102" valign="top">节点控制器（NC）&nbsp;</td></tr></p>

<p>&nbsp;
<td width="279" valign="top">1.托管虚拟机实例<br />
2.收集节点上相关的数据资源的可用性和利用率，并报告给控制簇CC。<br />
3.管理虚拟机的生命周期，能够获取和清除镜像的本地拷贝。<br />
4.维护虚拟网络</td>
<td width="234" valign="top">UEC的节点使用虚拟化技术使KVM能作为管理程序在服务器上运行。当用户安装UEC节点时，UEC将自动安装KVM。UEC的实例就是在管理程序下运行的虚拟机。Eucalyptus支持其他管理程序，如Xen。<br />
节点控制器在每一个节点上运行，控制着节点上实例的生命周期。</td>

<tr>
<td width="102" valign="top">VMware   Broker</td>
<td width="279" valign="top">允许 Eucalyptus直接地或通过 VMware<strong> </strong>Vcenter在   VMware设备部署虚拟机，在CC和 VMware  hypervisors(ESX/ESXi)起一个连接作用<strong> </strong></td>
<td width="234" valign="top">Eucalyptus   EE额外的一个组件，用于对VMware的支持</td>
</tr>


&nbsp;</p>

<p><span style="font-size: 20px; font-weight: bold; color: #0000ff;">管理员拥有的功能</span>
<table border="1" cellspacing="0" cellpadding="0" width="614" align="left">
<tbody>
<tr>
<td width="102" valign="top">模块</td>
<td width="279" valign="top">功能</td>
<td width="234" valign="top">说明</td>
</tr>
<tr>
<td width="102" valign="top">用户管理</td>
<td width="279" valign="top">1.  添加用户（邮件通知，设置管理员）<br />
2.  查看用户，设置账户是否激活<br />
3.  删除用户</td>
<td width="234" valign="top"></td>
</tr>
<tr>
<td width="102" valign="top">组管理</td>
<td width="279" valign="top">1.  添加用户组<br />
2.  查看用户组<br />
3.  删除用户组<br />
4.  添加/删除组员</td>
<td width="234" valign="top"></td>
</tr>
<tr>
<td width="102" valign="top">权限管理</td>
<td width="279" valign="top">1.给组设置权限</td>
<td width="234" valign="top"></td>
</tr>
<tr>
<td width="102" valign="top">Web接口</td>
<td width="279" valign="top">1.  查看、下载证书<br />
2.  查看上传的镜像，并能修改镜像状态<br />
3.  配置管理。可以设置云主机IP、DNS、Walrus、Cluster和SAN<br />
4.  审计报表。查看用户状态、资源使用率、系统日志、已注册的组件</td>
<td width="234" valign="top">这部分是web 管理界面提供的功能</td>
</tr>
<tr>
<td width="102" valign="top">组件管理</td>
<td width="279" valign="top">1.  可以注册Cloud、Walrus、Storage、Node，并可以查看、删除<br />
2.  启动、停止云服务<br />
3.  允许转换卷的实现方式<br />
4.  可以查看、修改配置文件</td>
<td width="234" valign="top">对外以SOAP和REST提供接口</td>
</tr>
</tbody>
</table>
&nbsp;</p>

<p>&nbsp;
<h2><strong><span style="color: #0000ff;">使用者拥有的功能</span></strong></h2>
<table border="1" cellspacing="0" cellpadding="0" width="614" align="left">
<tbody>
<tr>
<td width="102" valign="top">模块</td>
<td width="279" valign="top">功能</td>
<td width="234" valign="top">说明</td>
</tr>
<tr>
<td width="102" valign="top">Web接口</td>
<td width="279" valign="top">1.  用户可以注册帐号，修改信息及密码<br />
2.  查看、下载证书<br />
3.  查看上传的镜像</td>
<td width="234" valign="top">这部分是web 管理界面提供的功能</td>
</tr>
<tr>
<td width="102" valign="top">组件管理</td>
<td width="279" valign="top">1.  启动、停止节点<br />
2.  可以绑定、上传、注册、查看镜像，也可以删除、取消绑定镜像<br />
3.  查看本地可用的资源<br />
4.  可以查看、启动、停止、重启虚拟机<br />
5.  可以登入到一个windows虚拟机实例<br />
6.  创建、附件、脱离、删除快照和卷</td>
<td width="234" valign="top">通过Euca2ools工具完成这些功能</td>
</tr>
</tbody>
</table>
&nbsp;</p>
