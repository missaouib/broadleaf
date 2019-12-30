---
layout: post

title: 使用Docker安装MySql
date: 2019-07-16T08:00:00+08:00
categories: [ docker ]
tags: [mysql,docker]
description:  使用Docker安装MySql
---

Docker的Mysql镜像说明请参考 https://hub.docker.com/_/mysql 

# 使用Docker安装

下载镜像：

```
docker pull mysql:5.7
```

启动命令：

```bash
docker run --name mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:5.7
```

添加挂载，运行容器：

```bash
docker run -d -p 3306:3306  \
  -v /data/docker/mysql/conf:/etc/mysql \
  -v /data/docker/mysql/logs:/var/log/mysql \
  -v /data/docker/mysql/data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=123456 \
  --name mysql mysql:5.7
```

命令参数：

- `-p 3306:3306`：将容器的3306端口映射到主机的3306端口
- `-v /data/docker/mysql/conf:/etc/mysql`：将主机当前目录下的 conf 挂载到容器的 /etc/mysql
- `-v /data/docker/mysql/logs:/var/log/mysql`：将主机当前目录下的 logs 目录挂载到容器的 /var/log/mysql
- `-v /data/docker/mysql/data:/var/lib/mysql`：将主机当前目录下的 data 目录挂载到容器的 /var/lib/mysql
- `-e MYSQL_ROOT_PASSWORD=123456`：初始化root用户的密码

/data/docker/mysql/conf下创建my.cnf

```
[client]
default-character-set=utf8mb4

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci


[mysql]
default-character-set=utf8mb4
```



查看容器启动情况：

```
docker ps
```

防火墙开启3306端口

```bash
firewall-cmd --add-port=3306/tcp

firewall-cmd --zone=public --add-port=3306/tcp --permanent
```

重新启动容器

```bash
docker restart mysql
```

进入容器：

```bash
docker exec -it mysql bash
```

在宿主机上登陆mysql：

```bash
#登录mysql
mysql -h192.168.56.100 -p3306 -uroot -p123456
ALTER USER 'root'@'localhost' IDENTIFIED BY '123456';

#添加远程登录用户
CREATE USER 'test'@'%' IDENTIFIED WITH mysql_native_password BY '123456';
GRANT ALL PRIVILEGES ON *.* TO 'test'@'%';

#查看编码
showvariables like "%char%";

flush privileges;
```

# 使用docker-compose安装

docker-compose.yml配置文件如下：

```yml
version: '3.1'
services:
  db:
    image: mysql
    container_name: mysql 
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: test
      MYSQL_USER: test
      MYSQL_PASSWORD: test
    command:
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_general_ci
      --explicit_defaults_for_timestamp=true
      --lower_case_table_names=1
    ports:
      - 3306:3306
    volumes:
      - /data/docker/mysql/conf:/etc/mysql
      - /data/docker/mysql/logs:/var/log/mysql 
      - /data/docker/mysql/data:/var/lib/mysql
```

也可以使用 MYSQL_ROOT_PASSWORD_FILE 环境变量：

```bash
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root -d mysql:tag
```

> 说明：MYSQL_ROOT_PASSWORD_FILE 对应的文件里可以包含：MYSQL_ROOT_PASSWORD、MYSQL_ROOT_HOST、MYSQL_DATABASE、MYSQL_USER、MYSQL_PASSWORD。

进入到上面编写的docker-compose.yml文件的目录，运行命令：

```bash
# 启动所有服务
docker-compose up -d
# 单启动 mysql
docker-compose up -d mysql
# 暂停 mysql
docker-compose stop mysql
# 重新启动容器
docker-compose restart mysql
# 登录到容器中
docker-compose exec mysql bash
# 删除所有容器和镜像
docker-compose down
# 显示所有容器
docker-compose ps
# 查看mysql的日志
docker-compose logs mysql
# 查看mysql的实时日志
docker-compose logs -f mysql
```
