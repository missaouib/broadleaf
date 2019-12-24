---
layout: post
title: RHEL系统安装MySql5.7
date: 2014-04-06T08:00:00+08:00
description: 
categories: [ database ]
tags: 
 - mysql
published: true
---

使用yum方式在RHEL系统下安装MySql 5.7数据库

# 环境说明

- 操作系统：Centos7
- MySql版本：percona 5.7

  

# 安装Repo文件

下载地址：https://dev.mysql.com/downloads/repo/yum/

```bash
wget https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
yum localinstall mysql80-community-release-el7-1.noarch.rpm
```

查看 YUM 仓库关于 MySQL 的所有仓库列表

```cpp
yum repolist all | grep mysql
```

只查看启用的

```cpp
yum repolist enabled | grep mysql
```

安装 YUM 管理工具包，此包提供了 yum-config-manager 命令工具

```cpp
yum install yum-utils
```

禁用 8.0

```cpp
yum-config-manager --disable mysql80-community
```

启用 5.7

```cpp
yum-config-manager --enable mysql57-community
```

再次确认启用的 MySQL 仓库

```undefined
yum repolist enabled | grep mysql
```

# 安装 MySQL

```bash
yum install -y  mysql-community-server
```

# 管理 MySQL 服务

```bash
# 启动
systemctl start mysqld

# 查看状态
systemctl status mysqld

#开机自启动
systemctl enable mysqld
```

# 初始化 Mysql

在 MySQL 服务器初始启动时，如果服务器的数据目录为空，则会发生以下情况：

- MySQL 服务器已初始化。
- 在数据目录中生成SSL证书和密钥文件。
- 该[validate_password插件](https://dev.mysql.com/doc/refman/8.0/en/validate-password.html)安装并启用。
- 将创建一个超级用户 帐户`'root'@'localhost'`。并会设置超级用户的密码，将其存储在错误日志文件中。要显示它，请使用以下命令

```bash
$ grep 'temporary password' /var/log/mysqld.log
2019-11-21T06:26:36.414908Z 1 [Note] A temporary password is generated for root@localhost: -*mN,epg4N)F
```

## 取消密码复杂度

编辑 /etc/my.cnf配置文件, 在 [mysqld]配置块儿中添加如下内容

```undefined
plugin-load=validate_password.so 
validate-password=OFF
```

保存退出后，重启服务。

##  修改密码

通过上面日志中的临时密码登录并为超级用户帐户设置自定义密码：

```bash
mysqladmin -u root -p'-*mN,epg4N)F' password '1q2w3e4r'
```

> 注意:
> MySQL的 validate_password 插件默认安装。这将要求密码包含至少一个大写字母，一个小写字母，一个数字和一个特殊字符，并且密码总长度至少为8个字符。

如果不行的话，则先修改配置文件设置不使用密码，登陆进去之后再修改密码。

```
mysql -u root -p
mysql> update mysql.user set authentication_string=PASSWORD('123456') where user='root';
```

退出mysql，注释掉/etc/my.cnf中的 skip-grant-tables=true 这一行后，保存并重启mysql，使用新密码登录即可

## 不使用密码

 修改 /etc/my.cnf 文件，添加如下内容，之后重启服务

```bash
skip-grant-tables=true
```

