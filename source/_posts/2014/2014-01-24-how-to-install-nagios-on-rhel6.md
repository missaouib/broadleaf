---
layout: post
title: 在RHEL系统上安装Nagios
description: Nagios全名为（Nagios Ain’t Goona Insist on Saintood），最初项目名字是 NetSaint。它是一款免费的开源IT 基础设施监控系统，其功能强大，灵活性强，能有效监控主机状态、交换机、路由器等网络设置等。一旦主机或服务状态出现异常时，会发出邮件或短信报警第一时间通知运营人员，在状态恢复后发出正常的邮件或短信通知。
category: devops
tags: [nagios]
---

# 在管理机上安装rpm包

~~~
$ rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
$ rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
$ yum -y install nagios nagios-plugins-all nagios-plugins-nrpe nrpe php httpd
$ chkconfig httpd on && chkconfig nagios on
$ service httpd start && service nagios start
~~~

# 设置管理界面密码

~~~
$ htpasswd -c /etc/nagios/passwd nagiosadmin
~~~

<!-- more -->

密码和用户名保持一致（都设置为nagiosadmin），否则你需要修改`/etc/nagios/cgi.cfg`

# 访问Nagios

打开`http://ip/nagios`，输入用户名和密码即可访问

# 在客户端上安装NRPE

~~~
$ rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
$ rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
$ yum -y install nagios nagios-plugins-all nrpe
$ chkconfig nrpe on
~~~

修改配置`/etc/nagios/nrpe.cfg`，例如：

~~~
log_facility=daemon
pid_file=/var/run/nrpe/nrpe.pid
server_port=5666
nrpe_user=nrpe
nrpe_group=nrpe
allowed_hosts=198.211.117.251
dont_blame_nrpe=1
debug=0
command_timeout=60
connection_timeout=300
include_dir=/etc/nrpe.d/
command[check_users]=/usr/lib64/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib64/nagios/plugins/check_load -w 15,10,5 -c 30,25,20
command[check_disk]=/usr/lib64/nagios/plugins/check_disk -w 20% -c 10% -p /dev/vda
command[check_zombie_procs]=/usr/lib64/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/lib64/nagios/plugins/check_procs -w 150 -c 200
command[check_procs]=/usr/lib64/nagios/plugins/check_procs -w $ARG1$ -c $ARG2$ -s $ARG3$
~~~

请注意修改`allowed_hosts`值为你的nagios监控机ip

设置iptables：

~~~
$ iptables -N NRPE
$ iptables -I INPUT -s 0/0 -p tcp --dport 5666 -j NRPE
$ iptables -I NRPE -s 198.211.117.251 -j ACCEPT
$ iptables -A NRPE -s 0/0 -j DROP
$ /etc/init.d/iptables save
~~~

或者，关闭iptables：

~~~
$ /etc/init.d/iptables stop
~~~

启动NRPE：

~~~
$ service nrpe start
~~~

# 在管理机上添加配置文件

~~~
$ echo "cfg_dir=/etc/nagios/servers" >> /etc/nagios/nagios.cfg
$ cd /etc/nagios/servers
$ touch hadoop.tk.cfg
$ touch hbase.tk.cfg
~~~

然后修改每一个配置文件：

~~~
$ vim /etc/nagios/servers/hadoop.tk.cfg
~~~

添加内容如下，你也可以稍作修改：

~~~
define host {
        use                     linux-server
        host_name               cloudmail.tk
        alias                   cloudmail.tk
        address                 192.168.56.122
        }

define service {
        use                             generic-service
        host_name                       cloudmail.tk
        service_description             PING
        check_command                   check_ping!100.0,20%!500.0,60%
        }

define service {
        use                             generic-service
        host_name                       cloudmail.tk
        service_description             SSH
        check_command                   check_ssh
        notifications_enabled           0
        }

define service {
        use                             generic-service
        host_name                       cloudmail.tk
        service_description             Current Load
        check_command                   check_local_load!5.0,4.0,3.0!10.0,6.0,4.0
        }
~~~

重启nagios：

~~~
$ chown -R nagios. /etc/nagios
$ service nagios restart
~~~

# 其他资源

nagios客户端：

- [nagioschecker](https://code.google.com/p/nagioschecker/) Firefox extension made as the statusbar indicator of the events from the network monitoring system Nagios.
- [nagstamon Nagios status monitor](http://sourceforge.net/projects/nagstamon/files/latest/download) Nagstamon is a Nagios status monitor which resides in systray or desktop (GNOME, KDE, Windows) as floating statusbar to inform you in realtime about the status of your hosts and services.
- [Nagios Monitor for Android](https://code.google.com/p/nagmondroid/) NagMonDroid retrieves the current problems from your Nagios install and displays them. It has a variable update frequency and can be set to vibrate on new update.

资料：

- [CentOS下nagios报警飞信部署四步走](http://www.elain.org/?p=467)

