---
layout: post
title: kettle进行数据迁移遇到的问题
category: pentaho
tags: [pentaho, kettle]
keywords: kettle, oracle, db2, mysql, pentaho
description: 使用kettle进行oracle或db2数据导入到mysql或postgres数据库过程中遇到以下问题，以下只是一个简单描述，详细的说明以及所做的代码修改没有提及。下面所提到的最新的pdi程序是我修改kettle源码并编译之后的版本。
---

使用kettle进行oracle或db2数据导入到mysql或postgres数据库过程中遇到以下问题，以下只是一个简单描述，详细的说明以及所做的代码修改没有提及。下面所提到的最新的pdi程序是我修改kettle源码并编译之后的版本。

#### 同时运行两个pdi程序，例如：一个为oracle到mysql，另一个为oracle到postgres，其中一个停止运行

* 原因：从oracle迁移到mysql创建的作业和转换文件和oracle到postgres的作业和转换保存到一个路径，导致同名称的转换相互之间被覆盖，故在运行时候会出现混乱。
* 解决办法：将新建的作业和转换分别保存在两个不同的路径，最好是新建两个不同路径的仓库，关于如何新建仓库，请参考《kettle使用说明》文档。

#### 关键字的问题。
Oracle初始化到mysql，关键字前面会加上前缀“MY_”。如果在建表的时候出现错误，则需要检查表的字段中是否有关键字。

* 解决办法：出差的表单独进行处理，新建一个转换，实现关键字段该名称然后初始化出错的表。具体操作参见文档。

#### oracle中的字段名从中可以有#号，但是到mysql会报错

* 解决办法：字段改名称，去掉#号

#### Db2初始化到mysql或是postgres出错

* 原因：1）db2数据库连接用户没有权限访问出错的表；2）出错的表名存在小写字母
* 解决办法：使用更新后的pdi程序，更新后的程序会将db2的表名使用双引号括起来。

#### Oracle到mysql和pg时日期类型数据值有偏差

* 原因：从oracle中读取日期类型的数据时候，读取结果与oracle数据库中的数据已经存在偏差。少数记录使用oracle10g的驱动读取数据少一个小时，用oracle11g的驱动会多一个小时，该问题尚待oracle工程师给出解决方案。

####  主键从ORACLE导入不到MYSQL和POSTGRES

* 原因：pdi程序中没有对主键进行处理
* 解决办法：使用更新的pdi程序，执行Tools####Wizzard####Copy Tables Extension...功能添加主键；执行Tools####Wizzard####Copy Tables Data Only...功能可以只复制数据

#### Oracle中存在ascii字符导入到postgres时候报错：ERROR: invalid byte sequence for encoding "UTF8": 0x00

* 原因：PostgreSQL内部采用C语言风格的字符串（以0x00）表示结尾，因而不允许字符串中包括0x00，建议在转换时先对字符串类型的数据进行清洗，也就是增加一个节点用于删除字符串数据中的特殊字符0x00。
* 解决办法:使用新的pdi程序。在kettle的DataBase类中修改PreparedStatement.setString(int index,String value)方法传入的参数，将value的值trim之后在setString

#### 异构数据库之间的类型兼容问题。日期类型和时间类型的数据初始化到mysql或postgres中都为时间类型的数据，导致数据对比时候数据不一致。

* 原因：Pdi程序中的类型转换采用的是向上兼容的方式，故日期和时间类型都转换为时间类型数据。
* 解决办法：针对与db2数据初始化到mysql和postgres，该问题在最新的pdi程序中已经处理。因为oracle中的日期类型字段既可以存日期又可以存时间，故没针对oracle数据做出处理。

#### Db2中没有主键的数据初始化到mysql和postgres需要添加索引

* 解决办法：使用最新的pdi程序，最新的pdi程序会添加主键和索引。

#### Db2中decimal（n,m）类型的数据初始化到postgres数据库被四舍五入。

* 原因：Db2中decimal（n,m）类型的数据初始化到postgres中的类型不对。
* 解决办法：使用最新的pdi程序。

#### 导数据中途时没有报错，直接软件退出

* 原因：1）jvm内存溢出，需要修改jvm参数；2）pdi程序报swt错误
* 解决办法：修改jvm参数

#### 初次使用kettle做db2的初始化会报错

* 原因：kettle中的db2的jdbc驱动与使用的db2版本不对应。
* 解决办法：从db2的安装目录下拷贝jdbc驱动到kettle目录（libext/JDBC）下
