---
layout: post
title: 在Fedora 15 上搭建Eucalyptus
category: devops
tags: [eucalyptus, openNebula]
keywords: eucalyptus, openNebula, openStack, fedora
description: 在Fedora 15 上搭建Eucalyptus
---
<p><div class="pic"><img src="http://open.eucalyptus.com/themes/eucalyptus/img/eucalyptus_logo_awh.png" alt="" /></div>
在Fedora 15 上搭建Eucalyptus平台，在Fedora 15 上搭建Eucalyptus与在Centos上搭建Eucalyptus有什么区别呢？参照这篇文章<a href="http://open.eucalyptus.com/wiki/EucalyptusInstallationFedora_v2.0" target="_blank">Installing Eucalyptus (2.0) on Fedora 12</a>，然后注意一些细节，视乎就能安装成功。不管你信不信，我是在虚拟机中安装fedora15，然后安装Eucalyptus失败了，失败的原因是xen的网络没有配置好，查看资源的时候free / max都为0000.</p>

<p>毕竟是第一次接触云计算，第一次接触XEN，第一次接触Eucalyptus，Eucalyptus改装的都装了，就是XEN的网络没有配置好，当时很是迷糊。在接触了OpenNebula 和OpenStack之后，横向对比，视乎明白了很多千丝万缕的关联与奥秘。在安装OpenNebula，最主要是安装OpenStack成功之后，想到了之前Eucalyptus安装失败的原因。限于现在精力不在云计算上，暂且不去重新安装Eucalyptus，等之后再去尝试。下次尝试，定是醍醐灌顶，行云流水，很是期待。</p>

<p>如果你也在Fedora上安装Eucalyptus平台，咱们可以交流交流，等到时机成熟，会将在Fedora 15 上搭建Eucalyptus的过程及遇到的问题发表在博客上；如果你想研究Eucalyptus平台java部分的代码，咱们也可以彼此分享各自的心得。</p>

<p></p>
