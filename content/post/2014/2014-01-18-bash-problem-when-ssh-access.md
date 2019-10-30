---
layout: post
title: SSH远程连接时环境变量问题
date: 2014-01-18T08:00:00+08:00
description: SSH (Secure SHell) 是一个加密的终端程序，用于替代类Unix操作系统上传统的 telnet 工具。SSH已经发展成为一组软件系列，除了提供用于远程终端访问的ssh这个主要的程序，还包括其他的工具如 scp (secure copy) 和 sftp (secure file transfer protocol)。最初，SSH并不是免费的。然而，当今最流行并成为实际标准的SSH实现是 OpenBSD 的OpenSSH，它在Gentoo中已预安装。
categories: [ devops ]
tags: [ssh , linux]
---

# 1. 问题

RHEL服务器A有个启动脚本（普通用户user01运行），里面使用ifconfig获取ip地址如下：

~~~
Localhost_ip=$(ifconfig |awk -F 'addr:|Bcast' '/Bcast/{print $2}')
~~~

由于普通用户user01不能直接识别ifconfig命令，只能使用全路径`/sbin/ifconfig`，目前处理方式为修改`~/.bash_profile`文件添加环境变量如下：

~~~
PATH=$PATH:$HOME/bin
~~~

改成如下：

~~~
PATH=$PATH:$HOME/bin:/sbin
~~~
<!-- more -->

经过如上配置后服务器本机user01用户登录执行XX.sh脚本可以识别ifconfig命令。

出现如下问题：

远程主机B通过ssh远程执行启动脚本XX.sh，报错如下：

~~~
bash: ifconfg: command not found
~~~

# 2. 问题分析

测试前准备，追加调用说明语句，如下：

~~~
/etc/profile
[root@node3 ~]# vim /etc/profile
echo "/etc/profile begin:"
echo "$PATH"
...
 
unset i
unset pathmunge
 
echo "invoke /etc/profile"
echo "$PATH"
echo ""
~~~

~~~
[root@node3 ~]# vim /etc/bashrc
...
# vim:ts=4:sw=4
 
echo "invoke /etc/bashrc"
echo "$PATH"
echo ""
~~~

~~~
[root@node3 ~]# vim /root/.bash_profile
# User specific environment and startup programs
PATH=$PATH:$HOME/bin
export PATH
 
echo "invoke ~/.bash_profile"
echo "$PATH"
echo ""
~~~

~~~
[root@node3 ~]# vim /root/.bashrc
...
# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
 
echo "invoke ~/.bashrc"
echo "$PATH"
echo ""
~~~

~~~
[root@node3 ~]# vim /home/user01/.bash_profile
...
# User specific environment and startup programs
PATH=$PATH:$HOME/bin
export PATH
 
echo "invoke ~/.bashrc"
echo "$PATH"
echo ""
~~~

~~~
[root@node3 ~]# vim /home/user01/.bashrc
...
# User specific aliases and functions
 
echo "invoke ~/.bashrc"
echo "$PATH"
echo ""
~~~ 

分 user 和 root 用户，3 种场景进行测试，如下：

## 普通用户 User

###  场景1：

本机使用 su 命令切换到普通用户 （属于 Login 方式）

结论：

- Login 之前，系统 PATH 为：`/usr/local/bin:/bin:/usr/bin`
- Login 方式，文件调用顺序为： `/etc/profile -> /etc/bashrc -> ~/.bashrc -> ~/.bash_profile`
- Login 之后，系统 PATH 为：`/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/user01/bin`

~~~
su - user
[root@node3 ~]# hostname -i
192.168.122.33
~~~

~~~
[root@node3 ~]# su - user01
/etc/profile begin:
/usr/local/bin:/bin:/usr/bin
invoke /etc/profile
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
 
invoke /etc/bashrc
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
 
invoke ~/.bashrc
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
 
invoke ~/.bash_profile
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/user01/bin
~~~

### 场景2：

远程机使用 ssh 命令以普通用户身份登陆到主机 （属于 Login 方式）

结论：

- 与在本机使用 su 命令切换到普通用户的效果完全一样！

~~~
ssh user@remote_server_ip
[root@node1 ~]# hostname -i
192.168.122.31
~~~

~~~
[root@node1 ~]# ssh user01@192.168.122.33
user01@192.168.122.33's password: 
Last login: Tue Jul  9 16:23:33 2013 from 192.168.122.31
/etc/profile begin:
/usr/local/bin:/bin:/usr/bin
invoke /etc/profile
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
 
invoke /etc/bashrc
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
 
invoke ~/.bashrc
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
 
invoke ~/.bash_profile
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/user01/bin
~~~

## 场景3：

远程机使用 ssh 命令以普通用户身份连接到主机执行获取 PATH 的命令 （属于 NoLogin 方式）

结论：

- NoLogin 方式，命令获取的 PATH 为该远程机的，并未拿到目标主机的 PATH
- NoLogin 方式，文件调用顺序为：`/etc/bashrc -> ~/.bashrc`
- NoLogin 方式，目标主机 User 用户 PATH 为：`/usr/local/bin:/bin:/usr/bin`

~~~
ssh user@remote_server_ip command
[root@node1 ~]# hostname -i
192.168.122.31
~~~

~~~ 
[root@node1 ~]# echo $PATH
/usr/local/rabbitmq/sbin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
 
[root@node1 ~]# ssh user01@192.168.122.33 "echo $PATH"
user01@192.168.122.33's password: 
 
invoke /etc/bashrc
/usr/local/bin:/bin:/usr/bin
 
invoke ~/.bashrc
/usr/local/bin:/bin:/usr/bin
 
/usr/local/rabbitmq/sbin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
~~~

##  对比 root 用户

### 场景1：

本机使用 su 命令切换到 root （属于 Login 方式）

结论：

- Login 之前，系统 PATH 为：`/usr/local/bin:/bin:/usr/bin`
- Login 方式，root 用户，文件调用顺序为：`/etc/profile -> /etc/bashrc -> ~/.bashrc -> ~/.bash_profile`
- Login 之后，系统 PATH 为：`/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin`

~~~
su - root
[root@node3 ~]# hostname -i
192.168.122.33
~~~

~~~ 
[root@node3 ~]# su - root
/etc/profile begin:
/usr/local/bin:/bin:/usr/bin
invoke /etc/profile
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
invoke /etc/bashrc
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
invoke ~/.bashrc
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
invoke ~/.bash_profile
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
~~~

### 场景2：

远程机使用 ssh 命令以 root 用户身份登陆到主机 （属于 Login 方式）

结论：

- 与在本机使用 su 命令切换到 root 用户的效果完全一样！

~~~
ssh root@remote_server_ip
[root@node1 ~]# hostname -i
192.168.122.31
~~~

~~~ 
[root@node1 ~]# ssh root@192.168.122.33
root@192.168.122.33's password: 
Last login: Tue Jul  9 15:54:53 2013 from 192.168.122.1
/etc/profile begin:
/usr/local/bin:/bin:/usr/bin
invoke /etc/profile
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
invoke /etc/bashrc
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
invoke ~/.bashrc
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
invoke ~/.bash_profile
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
~~~

### 场景3

远程机使用 ssh 命令以 root 用户身份连接到主机执行获取 PATH 的命令 （属于 NoLogin 方式）

结论：

- NoLogin 方式，命令获取的 PATH 为该远程机的，并未拿到目标主机的 PATH
- NoLogin 方式，文件调用顺序为：`/etc/bashrc -> ~/.bashrc`
- NoLogin 方式，目标主机 root 用户 PATH 为：`/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin`

~~~
ssh root@remote_server_ip command
[root@node1 ~]# hostname -i
192.168.122.31
~~~

~~~
[root@node1 ~]# echo $PATH
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
 
[root@node1 ~]# ssh root@192.168.122.33 "echo $PATH"
root@192.168.122.33's password: 
invoke /etc/bashrc
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
invoke ~/.bashrc
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 
/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
~~~ 

### 关于/etc/profile 文件部分代码分析

结论：

- 无论 root 还是 user ，只有调用此文件，其 PATH 中才会被追加 sbin 相关路径。而由以上测试场景可知，只有 Login 时，`/etc/profile` 文件才会被调用。

~~~
pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}

if [ -x /usr/bin/id ]; then
    if [ -z "$EUID" ]; then
        # ksh workaround
        EUID=`id -u`
        UID=`id -ru`
    fi
    USER="`id -un`"
    LOGNAME=$USER
    MAIL="/var/spool/mail/$USER"
fi


# Path manipulation
if [ "$EUID" = "0" ]; then
    pathmunge /sbin
    pathmunge /usr/sbin
    pathmunge /usr/local/sbin
else
    pathmunge /usr/local/sbin after
    pathmunge /usr/sbin after
    pathmunge /sbin after

fi
~~~

# 3. 总结

综上，如需修改 PATH，建议修改 bashrc 文件，从而保证任何方式访问时 PATH 的正确性。
