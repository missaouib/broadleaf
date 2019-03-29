---
layout: post

title: Zabbix安装过程
category: devops
tags: [zabbix]
description:   记录Zabbix安装过程。
---

环境介绍：

- OS：rhel6.2
- 软件版本：zabbix-2.0.6
- serverIP：192.168.56.10
- clientIP：92.168.56.11-13

1、安装相关依赖包

    yum install mysql-libs mysql-server mysql-devel php* net-snmp* openssl httpd libcurl 
    libcurl-devel gcc g++ make

2、创建zabbix用户

    useradd zabbix

`vi sudo`添加如下内容，给予Zabbix用户sudo权限

    zabbix ALL=(ALL) NOPASSWD:ALL

3、下载源码包并解压

    # tar -zxf zabbix-2.0.6.tar.gz

3.1、初始化数据库

    #mysql -u root -proot -e 'create database zabbix;'
    #mysql -u root -proot -e "grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';"
    # mysql -uzabbix -pzabbix -D zabbix< zabbix-2.0.6/database/mysql/schema.sql 
    # mysql -uzabbix -pzabbix -D zabbix< zabbix-2.0.6/database/mysql/images.sql 
    # mysql -uzabbix -pzabbix -D zabbix< zabbix-2.0.6/database/mysql/data.sql

3.2、编译安装

    #cd zabbix-2.0.6
    # ./configure --prefix=/usr/local/zabbix --with-mysql --with-net-snmp --with-libcurl --enable-server --enable-agent
    #make
    #make install

3.3、修改数据库配置文件

    #cd /usr/local/zabbix/etc
    # vim zabbix_server.conf
    DBUser=zabbix
    DBPassword=zabbix

3.4、创建服务管理脚本

    #cd zabbix-2.0.6/misc/init.d/tru64/
    #cp zabbix_* /etc/init.d/
    #ln -s /usr/local/zabbix/sbin/zabbix_server /usr/local/sbin/zabbix_server
    #ln -s /usr/local/zabbix/sbin/zabbix_agentd /usr/local/sbin/zabbix_agentd

3.5、启动服务

    # /etc/init.d/zabbix_server start
    #/etc/init.d/zabbix_agentd start
    #ps aux| grep zabbix

3.6、复制网站代码文件

    #mkdir -p /var/www/html/zabbix/public_html
    #cp -R zabbix-2.0.6/frontends/php/* /var/www/html/zabbix/public_html/

3.7、配置虚拟主机（不用也可以）

    $ sudo vim /etc/apache2/sites-enabled/000-default

    Alias /zabbix /home/zabbix/public_html/
    <Directory /home/zabbix/public_html>
    AllowOverride FileInfo AuthConfig Limit Indexes
    Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
    <Limit GET POST OPTIONS PROPFIND>
    Order allow,deny
    Allow from all
    </Limit>
    <LimitExcept GET POST OPTIONS PROPFIND>
    Order deny,allow
    Deny from all
    </LimitExcept>
    </Directory>

3.8、配置php

    #vim /etc/php.ini 
    max_execution_time = 300
    max_input_time= 600
    post_max_size= 16M
    date.timezone = Asia/Shanghai

3.9、重启httpd

    #/etc/init.d/httpd restart

3.10、添加alert.d目录

    #vim /usr/local/zabbix/etc/zabbix_server.conf
    AlertScriptsPath=/usr/local/zabbix/etc/alert.d

3.11、安装mailutils

    #yum install sendmail mailutils（下载源码包自行安装）

3.12、打开网页安装向导

打开 http://192.168.56.10/zabbix/public_html/setup.php

3.13、下载zabbix.conf.php文件

并将其上传到`/var/www/html/zabbix/public_html/conf/`下，然后点击retry。至此，Zabbix的Server端已经部署完成，接下来我们在client上部署agent。

4、安装部署agent

4.1、安装相关依赖包

    yum install mysql-libs mysql-server mysql-devel php* net-snmp* openssl httpd libcurl 
    libcurl-devel gcc g++ make

4.2、新建用户

    useradd zabbix

4.3、下载源码包

4.4、编译安装

    #tar -zxf zabbix-2.0.6.tar.gz 
    #cd zabbix-2.0.6
    # ./configure --prefix=/usr/local/zabbix --with-net-snmp --with-libcurl --enable-agent
    #make
    #make install

4.4、创建服务管理脚本

    #cp zabbix-2.0.6/misc/init.d/tru64/zabbix_agentd /etc/init.d/
    #ln -s /usr/local/zabbix/sbin/zabbix_agentd /usr/local/sbin/zabbix_agentd
    #chmod 755 /etc/init.d/zabbix_agentd

4.5、启动服务

    #/etc/init.d/zabbix_agent start
    #ps aux| grep zabbix

至此，agent安装完。

5、Zabbix分布式监控系统自定义配置

5.1、在agent节点

    #vim /usr/local/zabbix/etc/zabbix_agentd.conf
    Server=192.168.56.10
    ServerActive=192.168.56.10
    Hostname=node2(这是客户端主机名)

5.2、返回web界面创建Host。

