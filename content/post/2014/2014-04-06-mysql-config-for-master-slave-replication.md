---
layout: post
title: RHEL系统安装MySQL主备环境
date: 2014-04-06T08:00:00+08:00
description: 本文介绍如何在RHEL系统安装MySQL主备环境
categories: [ database ]
tags: 
 - mysql
published: true
---

# 环境准备

- 操作系统： rhel6.4
- 数据库： percona 5.6.14
- 使用3306端口保证端口未被占用，selinux关闭状态

# 原理说明

mysql的复制（Replication)是一个异步的复制，从一个mysql instance(称之为master)复制到另一个mysql instance(称之为slave).实现整个复制操作主要由三个进程完成的，其中俩个进程在slave(sql进程和io进程），另外一个进程在master（IO进程）上。

要实施复制，首先要打开master端的binary log(bin-log)功能，否则无法实现。因为整个复制过程实际上就是slave从master端获取该日志然后在自己升上完全顺序的执行日志中所记录的各种操作。

# 配置说明

## 1. 配置master并启动

拷贝配置文件：

~~~
cp /usr/share/doc/Percona-Server-server-56-5.6.14/my-default.cnf /etc/my.cnf
~~~

编辑`/etc/my.cnf`：

~~~
[mysqld]
explicit_defaults_for_timestamp=true   ##开启查询缓存
# log_bin
log_bin = mysql-bin
server_id = 36
~~~

启动mysql服务：

~~~
service mysql start 
~~~

## 2. 配置slave并启动

拷贝配置文件：

~~~
cp /usr/share/doc/Percona-Server-server-56-5.6.14/my-default.cnf /etc/my.cnf
~~~

编辑`/etc/my.cnf`：

~~~
[mysqld]
explicit_defaults_for_timestamp=true 
log_bin = mysql-bin
server_id = 37
relay_log=/var/lib/mysql/mysql-relay-bin ##传送过来的日志存放目录
log_slave_updates=1
read_only=1 ##这个参数只对普通用户生效，超级用户和复制用户无效
~~~

启动mysql服务：

~~~
service mysql start 
~~~

## 3. 主从分别授权用户

在master,slave分别执行以下命令：

~~~
#mysql
mysql->grant replication slave,replication client on *.* to repl@'%' identified by  '123456';
mysql->flush priviledges;
~~~

## 4. 主库数据备份到从库 

master上运行：

~~~
# mysqldump -A >all.sql
~~~

slave上运行：

~~~
# mysql <all.sql
~~~

## 5. 根据主状态启动从库

(1) 查询主库状态

~~~
mysql->show master status \G
 *************************** 1. row ***************************
             File: mysql-bin.000001
         Position: 697
     Binlog_Do_DB: 
 Binlog_Ignore_DB: 
Executed_Gtid_Set: 
1 row in set (0.00 sec)
~~~

(2) 从库启动复制

~~~
#mysql
mysql->change master to
        ->master_host="192.168.0.114",master_port=3306,master_user="repl",master_password="123456",master_log_file="mysql-bin.000001",master_log_pos=697;
mysql->start slave;
~~~

(3) 从库状态

~~~
mysql> show slave status \G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.0.114
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000001
          Read_Master_Log_Pos: 697
               Relay_Log_File: mysql-relay-bin.000002
                Relay_Log_Pos: 563
        Relay_Master_Log_File: mysql-bin.000001
         ....Exec_Master_Log_Pos: 697
         ....
~~~

## 6. 主从用于复制的进程

在master上查看进程：

~~~
mysql->show processlist
~~~

1个如下状态的进程:

~~~
Master has sent all binlog to slave; waiting for binlog to be updated
~~~

在slave上查看进程：

~~~
mysql->show processlist
~~~

2个如下状态的进程

~~~
Waiting for master to send event
Slave has read all relay log; waiting for the slave I/O thread to update it
~~~

# 7. 主从状态监控

常规做法是slave上`show slave status\G`中的两个变量的差值（`Read_Master_Log_Pos`，`Exec_Master_Log_Pos`),也可以使用percona提供的工具包`pt-heartbeat`。

## 8. Percona-tookit 安装及pg-heartbeat使用
 
工具集中包含`pt-heartbeat`, 安装依赖perl-DBD-MySQL， perl-IO-Socket-SSL:

~~~
% rpm -ivh percona-toolkit-2.2.6-1.noarch.rpm
~~~

**pg-heartbeat功能介绍：**

- 监控复制延迟
- 测量复制落后时间

*实现机制：*

 - 第一步，pt-heartbeat的--update线程会在指定的时间间隔更新一个时间戳。
 - 第二步，pt-heartbeat的–monitor线程或者–check线程连接到从上检查前面更新的时间戳，和主当地时间做比较，得出时间差。

*使用例子：*

1）初始化环境，创建一个后台进程定期更新主上的test库heartbeat表,默认是一秒可以–interval指定，执行后会生成一个heartbeat表，test为需要监控的同步库

~~~
pt-heartbeat -D test --update -u repl -p 123456 -h 192.168.0.108 --create-table --daemonize
~~~

2）监控并输出slave落后时间

~~~
pt-heartbeat -D test --monitor -u repl -p 123456 -h 192.168.0.115
0.00s [  0.00s,  0.00s,  0.00s ]           ###瞬时延迟 [一分钟平均延迟，五分钟平均延迟，十五分钟平均延迟]
0.00s [  0.00s,  0.00s,  0.00s ]
0.00s [  0.00s,  0.00s,  0.00s ]
~~~

结果如下 会一直输出,断开一下连接得到如下结果，最后同步

~~~
0.00s [  0.34s,  0.07s,  0.02s ]
0.00s [  0.00s,  0.07s,  0.02s ]
~~~

3）只输出瞬时的差值

~~~
#pt-heartbeat -D test --test -u repl -p 123456 -h 192.168.0.115
0.00 ###只代表瞬时延迟
~~~

## 9. mysql主从互换

(1) 停止从库复制,从新设置状态

~~~
mysql->stop slave;
mysql->reset master;
mysql->reset slave;
~~~

(2) 如配置文件相同的情况下，配置文件无需更改。否者主备的配置文件交换。

(3) 原先的主变为备

~~~
mysql->reset master;
mysql->reset slave;
~~~

从新配置change master to参数

(4) 服务器重启

如原先的主中有bin日志在从上为实现同步，可以认为读取bin日志的内容，在新的主中执行
