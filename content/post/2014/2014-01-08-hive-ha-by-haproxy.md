---
layout: post

title: Hive使用HAProxy配置HA
date: 2014-01-08T08:00:00+08:00

description: HAProxy是一款提供高可用性、负载均衡以及基于TCP（第四层）和HTTP（第七层）应用的代理软件，HAProxy是完全免费的、借助HAProxy可以快速并且可靠的提供基于TCP和HTTP应用的代理解决方案。

categories: [hive] 

tags: [hive]

---

HAProxy是一款提供高可用性、负载均衡以及基于TCP（第四层）和HTTP（第七层）应用的代理软件，HAProxy是完全免费的、借助HAProxy可以快速并且可靠的提供基于TCP和HTTP应用的代理解决方案。

- 免费开源，稳定性也是非常好，这个可通过我做的一些小项目可以看出来，单Haproxy也跑得不错，稳定性可以与硬件级的F5相媲美。
根据官方文档，HAProxy可以跑满10Gbps-New benchmark of HAProxy at 10 Gbps using Myricom's 10GbE NICs （Myri-10G PCI-Express），这个数值作为软件级负载均衡器是相当惊人的。
- HAProxy 支持连接拒绝 : 因为维护一个连接的打开的开销是很低的，有时我们很需要限制攻击蠕虫（attack bots），也就是说限制它们的连接打开从而限制它们的危害。 这个已经为一个陷于小型DDoS攻击的网站开发了而且已经拯救了很多站点，这个优点也是其它负载均衡器没有的。
- HAProxy 支持全透明代理（已具备硬件防火墙的典型特点）: 可以用客户端IP地址或者任何其他地址来连接后端服务器. 这个特性仅在Linux 2.4/2.6内核打了cttproxy补丁后才可以使用. 这个特性也使得为某特殊服务器处理部分流量同时又不修改服务器的地址成为可能。
- HAProxy现多于线上的Mysql集群环境，我们常用于它作为MySQL（读）负载均衡；
- 自带强大的监控服务器状态的页面，实际环境中我们结合Nagios进行邮件或短信报警，这个也是我非常喜欢它的原因之一；
- HAProxy支持虚拟主机，许多朋友说它不支持虚拟主机是错误的，通过测试我们知道，HAProxy是支持虚拟主机的。

HAProxy特别适用于那些负载特大的web站点， 这些站点通常又需要会话保持或七层处理。HAProxy运行在当前的硬件上，完全可以支持数以万计的并发连接。并且它的运行模式使得它可以很简单安全的整合进您当前的架构中， 同时可以保护你的web服务器不被暴露到网络上。


# 安装配置

在[HAProxy](http://haproxy.1wt.eu/)官网下载安装包并编译

~~~
wget http://haproxy.1wt.eu/download/1.4/src/haproxy-1.4.24.tar.gz|tar zxvf
mv haproxy-1.4.24 /opt/haproxy-1.4.24
cd /opt/haproxy-1.4.24
make TARGET=linux26
~~~

# 添加配置文件

在/opt/haproxy-1.4.24目录下创建一个config.cfg文件，添加如下内容：

~~~
global
        daemon
        nbproc 1
        pidfile /var/run/haproxy.pid
        ulimit-n 65535

defaults
        mode tcp                        #mode { tcp|http|health }，tcp 表示4层，http表示7层，health仅作为健康检查使用
        retries 2                       #尝试2次失败则从集群摘除
        option redispatch               #如果失效则强制转换其他服务器
        option abortonclose          	#连接数过大自动关闭
        maxconn 1024                  	#最大连接数
        timeout connect 1d           	#连接超时时间，重要，hive查询数据能返回结果的保证
        timeout client 1d               #同上
        timeout server 1d              	#同上
        timeout check 2000           	#健康检查时间
        log 127.0.0.1 local0 err #[err warning info debug]

listen  admin_stats                     #定义管理界面
        bind 0.0.0.0:1090               #管理界面访问IP和端口
        mode http                       #管理界面所使用的协议
        maxconn 10			#最大连接数
        stats refresh 30s               #30秒自动刷新
        stats uri /                     #访问url
        stats realm Hive\ Haproxy    	#验证窗口提示
        stats auth admin:123456     	#401验证用户名密码

listen hive				#hive后端定义
        bind 0.0.0.0:10001              #ha作为proxy所绑定的IP和端口
        mode tcp                        #以4层方式代理，重要
        balance leastconn               #调度算法 'leastconn' 最少连接数分配，或者 'roundrobin'，轮询分配
        maxconn 1024                    #最大连接数
        server hive_1 192.168.1.1:10000 check inter 180000 rise 1 fall 2
        server hive_2 192.168.1.2:10000 check inter 180000 rise 1 fall 2
	#释义：server 主机代名(你自己能看懂就行)，IP:端口 每180000毫秒检查一次。也就是三分钟。
	#hive每有10000端口的请求就会创建一个log，设置短了，/tmp下面会有无数个log文件，删不完。
~~~

# 如何启动

在HAProxy目录下执行如下命令：

~~~
haproxy -f conf.cfg
~~~

# 如何使用

在hive-server或者hive-server2中jdbc的连接信息修改url和port，如hive-server2:

~~~
jdbc:hive2://${haproxy.hostname}:${haproxy.hive.bind.port}/${hive.database}
~~~

上面`haproxy.hostname`为你安装haproxy的机器名；`haproxy.hive.bind.port`为`conf.cfg`中定义的监听hive的端口（上面中定义的为10001）

# 参考资料

- [1] [HAProxy---HAProxy简介](http://blog.csdn.net/xiyf2046/article/details/11686873)
- [2] [HAProxy+Hive构建高可用数据挖掘集群](http://slaytanic.blog.51cto.com/2057708/803626)




