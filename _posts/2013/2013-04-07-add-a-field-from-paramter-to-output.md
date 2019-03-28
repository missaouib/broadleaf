---
layout: post
title:  Kettle中添加一个参数字段到输出
description: kettle可以将输入流中的字段输出到输出流中，输入输出流可以为数据库、文件或其他，通常情况下输入流中字段为已知确定的，如果我想在输出流中添加一个来自转换的命令行参数的一个字段，该如何操作？
category: pentaho
tags: [kettle,pentaho]
---

kettle可以将输入流中的字段输出到输出流中，输入输出流可以为数据库、文件或其他，通常情况下输入流中字段为已知确定的，如果我想在输出流中添加一个来自转换的命令行参数的一个字段，该如何操作？


上述问题可以拆分为两个问题：

1. 从命令行接受一个参数作为一个字段
2. 合并输入流和这个字段

## 问题1

第一个问题可以使用kettle中`获取系统信息`组件，定义一个变量，该值来自命令行参数，见下图：

![get-a-field-from-paramter](http://7xnrdo.com1.z0.glb.clouddn.com/2013/get-a-field-from-paramter.png)


## 问题2
第二个问题可以使用kettle中`记录关联 (笛卡尔输出)`组件将两个组件关联起来，输出一个笛卡尔结果集，关联条件设定恒为true，在运行前设置第一个参数的值，然后运行即可。

![run-kettle-for-join-two-inputs](http://7xnrdo.com1.z0.glb.clouddn.com/2013/run-kettle-for-join-two-inputs.png)


## 下载脚本
最后，kettle转换文件下载地址：[在这里](http://7xnrdo.com1.z0.glb.clouddn.com/2013/join-a-paramter-to-input-in-kettle.zip)。


