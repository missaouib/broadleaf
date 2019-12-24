---
layout: post
title: RHEL系统安装PostgreSQL
date: 2014-04-07T08:00:00+08:00
description: PostgreSQL 是一个开放源码的免费数据库系统。Postgres 最初由加州大学伯克利分校计算机科学系开发，倡导了很多关系对象的观念，这些观念现在已经用在一些商业数据库系统中。它提供了 SQL92/SQL99 语言支持，事务处理，引用集成，存储过程以及类型扩展。PostgreSQL 则是 Postgres 的一个开放源代码的后代。
categories: [ database ]
tags: 
 - postgresql
---

PostgreSQL 是一个开放源码的免费数据库系统。Postgres 最初由加州大学伯克利分校计算机科学系开发，倡导了很多关系对象的观念，这些观念现在已经用在一些商业数据库系统中。它提供了 SQL92/SQL99 语言支持，事务处理，引用集成，存储过程以及类型扩展。PostgreSQL 则是 Postgres 的一个开放源代码的后代。

# 系统环境

操作系统： Centos7

# 通过Centos Yum源安装

## 安装postgresql 9.2

**CentOS7**默认包含了postgresql9.2的yum：

```bash
yum install postgresql-server
```

## 初始化数据

安装成功之后，初始化数据库：

```bash
postgresql-setup initdb
```

数据库安装目录在：/var/lib/pgsql

## 开机启动

启动数据库并设置开机启动：

```bash
systemctl enable postgresql.service
systemctl start postgresql.service
```

## 配置数据库

查找路径：

```bash
find / -name pg_hba.conf
/var/lib/pgsql/data/pg_hba.conf
/usr/share/pgsql/pg_hba.conf
```

修改 `pg_hba.conf`，设置远程用户访问权限：

```bash
sudo sed -i "s/127.0.0.1\/32/0.0.0.0\/0/" /var/lib/pgsql/data/pg_hba.conf
sudo sed -i "s/ident/trust/" /var/lib/pgsql/data/pg_hba.conf
sudo sed -i "s/peer/trust/" /var/lib/pgsql/data/pg_hba.conf
```

- md5并提供加密的密码验证
- trust意思不用密码验证

修改postgresql.conf，配置监听地址：

```bash
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf
```

重启数据库：

```bash
systemctl restart postgresql.service
```



## 登陆数据库

使用postgres用户登陆，并修改密码：

```bash
$ sudo -u postgres psql
psql (9.2.24)
Type "help" for help.

postgres=# ALTER USER postgres with encrypted password '123456';
ALTER ROLE
```

接下来可以指定用户名和密码登陆：

```bash
sudo -u postgres psql -U postgres -W 
```



# 通过PostgreSQL Yum安装

参考 https://www.postgresql.org/download/linux/redhat/ ，可以选择最新版本安装



## 安装PostgreSQL 12

```bash
sudo yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

sudo yum install postgresql12 postgresql12-server -y
```

安装路径在 /usr/pgsql-12/

安装完之后，初始化数据库并设置开机启动：

```bash
sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
sudo systemctl enable postgresql-12
sudo systemctl start postgresql-12
```

## 安装PostgreSQL 9.6

```bash
sudo yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

sudo yum install postgresql96 postgresql96-server -y
```

安装路径在 /usr/pgsql-9/

安装完之后，初始化数据库并设置开机启动：

```bash
sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb
sudo systemctl enable postgresql-9.6
sudo systemctl start postgresql-9.6
```

## 配置数据库

查找路径：

```bash
find / -name pg_hba.conf
/var/lib/pgsql/12/data/pg_hba.conf
```

修改 `pg_hba.conf`，设置远程用户访问权限：

```bash
sudo sed -i "s/127.0.0.1\/32/0.0.0.0\/0/" /var/lib/pgsql/12/data/pg_hba.conf
sudo sed -i "s/ident/trust/" /var/lib/pgsql/12/data/pg_hba.conf
sudo sed -i "s/peer/trust/" /var/lib/pgsql/12/data/pg_hba.conf
```

- md5并提供加密的密码验证
- trust意思不用密码验证

修改postgresql.conf，配置监听地址：

```bash
CONF_FILE=/var/lib/pgsql/12/data/postgresql.conf

sudo sed -i "s/#port = 5432/port = 5432/" $CONF_FILE
sudo sed -i "s/max_connections = 100/max_connections = 600/" $CONF_FILE
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $CONF_FILE
sudo sed -i "s/shared_buffers = 32MB/shared_buffers = 256MB/" $CONF_FILE
```

重启数据库：

```bash
sudo systemctl restart postgresql-12
```

## 创建数据库

```bash
CREATE USER test WITH PASSWORD 'test';
CREATE DATABASE dataware owner=test;

GRANT ALL privileges ON DATABASE dataware TO test;
```

# 自动化运行脚本

以下是按照hive时，配置hive元数据的数据库时的自动化安装脚本，仅供参考：

```bash
#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

if [ `id -u` -ne 0 ]; then
    echo "must run as root"
    exit 1
fi

get_postgresql_major_version(){
    local psql_output=`psql --version`
    local regex="^psql \(PostgreSQL\) ([[:digit:]]+)\..*"

    if [[ $psql_output =~ $regex ]]; then
      echo ${BASH_REMATCH[1]}
    fi
}

get_standard_conforming_strings(){
    local psql_version=$(get_postgresql_major_version)
    if [[ $psql_version -gt 8 ]]; then
        echo "# This is needed to make Hive work with Postgresql 9.1 and above"
        echo "# See OPSAPS-11795"
        echo "standard_conforming_strings=off"
    fi
}

check_postgresql_installed(){
  echo -e "Install postgresql-server"
	if ! rpm -q postgresql-server >/dev/null ; then
	    yum install postgresql-server postgresql-jdbc -y >/dev/null 2>&1
        ln -s /usr/share/java/postgresql-jdbc.jar /usr/lib/hive/lib/postgresql-jdbc.jar
		chkconfig postgresql on
	fi

	pkill -9 postgres
	rm -rf /var/lib/pgsql/data /var/run/postgresql/.s.PGSQL.$DB_PORT

  echo -e "Init postgresql database"
	postgresql-setup initdb
}

configure_postgresql_conf(){
  echo -e "Configure postgresql conf"

	sed -i "s/#port = 5432/port = $DB_PORT/" $CONF_FILE
	sed -i "s/max_connections = 100/max_connections = 600/" $CONF_FILE
	sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $CONF_FILE
	sed -i "s/shared_buffers = 32MB/shared_buffers = 256MB/" $CONF_FILE

	local SCS=$(get_standard_conforming_strings)
	if [ "$SCS" != "" ]; then
		echo -e $SCS
		sed -i "s/#standard_conforming_strings = on/standard_conforming_strings = off/" $CONF_FILE
	fi
}

enable_remote_connections(){
  echo -e "Enable remote connections"

	sed -i "s/127.0.0.1\/32/0.0.0.0\/0/" /var/lib/pgsql/data/pg_hba.conf
	sed -i "s/ident/trust/" /var/lib/pgsql/data/pg_hba.conf
  sed -i "s/peer/trust/" /var/lib/pgsql/data/pg_hba.conf
}

create_db(){
	DB_NAME=$1
	DB_USER=$2
	DB_PASSWORD=$3

  echo -e "Create database $DB_NAME"

  cd /var/lib/pgsql/data
	su -c "/usr/bin/pg_ctl start -w -m fast -D /var/lib/pgsql/data" postgres
	su -c "/usr/bin/psql --command \"CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD'; \" " postgres
	su -c "/usr/bin/psql --command \"CREATE DATABASE $DB_NAME owner=$DB_USER;\" " postgres
	su -c "/usr/bin/psql --command \"GRANT ALL privileges ON DATABASE $DB_NAME TO $DB_USER;\" " postgres
}

init_hive_metastore(){
	DB_NAME=$1
	DB_USER=$2
	DB_FILE=$3

  echo -e "Init hive metastore using $DB_FILE"
	su -c "/usr/bin/psql -U $DB_USER -d $DB_NAME -f $DB_FILE" postgres
}

manager_db(){
  echo -e "$1 postgres"
	su -c "/usr/bin/pg_ctl $1 -w -m fast -D /var/lib/pgsql/data" postgres
}

readonly DB_HOST=$(hostname -f)
readonly DB_PORT=${DB_PORT:-5432}
readonly DB_HOSTPORT="$DB_HOST:$DB_PORT"
CONF_FILE="/var/lib/pgsql/data/postgresql.conf"

check_postgresql_installed
configure_postgresql_conf
enable_remote_connections
create_db metastore hive hive

manager_db restart
init_hive_metastore metastore hive `ls /usr/lib/hive/scripts/metastore/upgrade/postgres/hive-schema-* |tail -n 1`
```



# 参考文章

- [Linux downloads (Red Hat family) ](https://www.postgresql.org/download/linux/redhat/)

