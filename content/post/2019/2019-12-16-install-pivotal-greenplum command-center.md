---
layout: post
title: 安装Greenplum Command Center Console
date: 2019-12-16T08:00:00+08:00
categories: [ database ]
tags: [greenplum]
---

# 安装greenplum-cc-web

1、下载安装文件

从 https://network.pivotal.io/products/pivotal-gpdb 下载，目前最新版本为 greenplum-cc-web-6.0.0-rhel7_x86_64.zip。

2、解压安装文件

```bash
unzip greenplum-cc-web-6.0.0-rhel7_x86_64.zip
```

3、进入安装目录

```bash
cd greenplum-cc-web-6.0.0-rhel7_x86_64
```

4、修改目录权限：

```bash
gpssh -f hostfile_all 'sudo chmod 777 /usr/local'
```

5、创建配置文件 install.conf，用于设置安装参数

```bash
path = /usr/local
# Set the display_name param to the string to display in the GPCC UI.
# The default is "gpcc"
# display_name = gpcc

master_port = 5432
web_port = 28080
rpc_port = 8899
enable_ssl = false
# Uncomment and set the ssl_cert_file if you set enable_ssl to true.
# ssl_cert_file = /etc/certs/mycert
enable_kerberos = false
# Uncomment and set the following parameters if you set enable_kerberos to true.
# webserver_url = <webserver_service_url>
# krb_mode = 1
# keytab = <path_to_keytab>
# krb_service_name = postgres
# User interface language: 1=English, 2=Chinese, 3=Korean, 4=Russian, 5=Japanese
language = 1
```

6、执行安装命令

通过配置文件安装：

```bash
./gpccinstall-6.0.0 -c install.conf
```

安装默认配置自动安装：

```bash
# -W 设置密码，输入gpmon
./gpccinstall-6.0.0 -auto -W
```

执行完之后，会发现创建了gpperfmon数据库：

```bash
CREATING SUPERUSER 'gpmon'...
CREATING COMMAND CENTER DATABASE 'gpperfmon'...
RELOADING pg_hba.conf. PLEASE WAIT ...
```



7、设置环境变量

```bash
source /usr/local/greenplum-cc-web-6.0.0/gpcc_path.sh

echo "source /usr/local/greenplum-cc-web-6.0.0/gpcc_path.sh" >> ~/.bashrc

source  ~/.bashrc
```

8、同步配置文件

查看生成的文件.pgpass

```bash
cat ~/.pgpass
*:5432:gpperfmon:gpmon:gpmon
```

> 可以看到创建了gpmon用户，密码为changeme。

可以修改该文件中密码为gpmon，或者通过环境变量设置：

```bash
PGPASSWORD=gpmon
```

也可以修改数据库中密码和~/.pgpass一致：

```bash
alter user gpmon encrypted password 'gpmon'
```



将该文件同步到Standby Master节点：

```bash
ssh gpadmin@gp-node002
scp gpadmin@gp-node001:~/.pgpass ~
chmod 600 ~/.pgpass
```

9、查看配置文件

- `$MASTER_DATA_DIRECTORY/gpperfmon/conf/gpperfmon.conf`
- `$GPCC_HOME/conf/app.conf`
- `$MASTER_DATA_DIRECTORY/gpmetrics/gpcc.conf`
- `$MASTER_DATA_DIRECTORY/postgresql.conf`

查看$GPCC_HOME/conf/app.conf

```bash
cat $GPCC_HOME/conf/app.conf
appname         = gpccws
listentcp4      = true
runmode         = prod
session         = true
enablexsrf      = true
xsrfexpire      = 2592000
xsrfkey         = 61oETzKXQAGaYdkL5gEmGeJJFuYh7EQnp2XdTP1o
rendertype      = json
printallsqls    = false
master_port     = 5432
path            = /usr/local
display_name    = gpcc
enable_kerberos = false
EnableHTTPS     = false
EnableHTTP      = true
httpport        = 28080
rpc_port        = 8899
language        = English
log_level       = INFO
master_host     = gp-node001
```

修改pg_hba.conf：

```bash
local   gpperfmon     gpmon                        md5
host    gpperfmon     gpmon          0.0.0.0/0     md5
host    gpperfmon     gpmon          ::1/128       md5
```

登陆测试：

```bash
psql -d gpperfmon -U gpmon -W
```

10、启动

```bash
$ PGPASSWORD=gpmon gpcc start

# 输入密码登陆
$ gpcc start -W

$ gpcc start

2019-12-17 12:00:59 Starting the gpcc agents and webserver...
2019-12-17 12:01:05 Agent successfully started on 3/3 hosts
2019-12-17 12:01:05 View Greenplum Command Center at http://gp-node001:28080
```

查看状态：

```bash
$ gpcc status
2019-12-16 18:37:19 GPCC webserver: running
2019-12-16 18:37:19 GPCC agents: 3/3 agents running
```



11、访问浏览器 http://gp-node001:28080 ，用户名和密码为 gpmon

![image-20191217120230168](https://tva1.sinaimg.cn/large/006tNbRwgy1g9zl5upkvbj316u0u00xe.jpg)

12、查看配置参数

```bash
$ gpcc --settings
Install path:   /usr/local
Display Name:   gpcc
GPCC port:      28080
Kerberos:       disabled
SSL:            disabled
```

13、查看日志

```bash
tailf $GPCC_HOME/logs/gpccws.log
```

# 禁用gpperfmon

1、安装

使用gpperfmon_install命令可以创建名称为gpperfmon的数据库，默认使用gpmon用户。

```bash
gpperfmon_install --enable --password gpmon --port 5432
```

当然，在前面运行gpccinstall-6.0.0的时候，已经创建了该数据库。

2、查看gpperfmon是否开启

```bash
gpconfig -s gp_enable_gpperfmon
```

3、 Greenplum Command Center不再需要gpperfmon agent搜集的历史数据，所以需要禁用gp_enable_gpperfmon

```bash
gpconfig -c gp_enable_perform -v off
```

4、然后重启数据库

```bash
gpstop -ar 

#强制重启
gpstop -Ma immediate
```

# 设置gpmon角色日志参数

连接gpperfmon数据库：

```bash
psql -d gpperfmon -p 5432 -U gpadmin
```

修改角色：

```bash
psql -d gpperfmon -U gpmon
psql (9.4.24)
Type "help" for help.

gpperfmon=# ALTER ROLE gpmon SET log_statement TO DDL;
ALTER ROLE
gpperfmon=# ALTER ROLE gpmon SET log_min_messages to FATAL;
ALTER ROLE
```



# 卸载

1、停止

```bash
gpcc stop
```

2、删除安装目录

```bash
rm -rf /usr/local/greenplum-cc-web-6.0.0
```

3、禁用采集数据agent

```bash
su - gpadmin
gpconfig -c gp_enable_gpperfmon -v off
```

4、删除pg_hba.conf中gpmon条目

```bash
#local     gpperfmon     gpmon     md5  
#host      gpperfmon     gpmon    0.0.0.0/0    md5
```

5、删除角色

```bash
psql template1 -c 'DROP ROLE gpmon;'
```

6、重启数据库

```bash
gpstop -r
```

7、删除未提交的的数据和日志

```bash
rm -rf $MASTER_DATA_DIRECTORY/gpperfmon/data/* 
rm -rf $MASTER_DATA_DIRECTORY/gpperfmon/logs/*
```

8、删除数据库

```bash
dropdb gpperfmon
```

