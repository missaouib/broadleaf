---
layout: post

title: 使用Docker安装MongoDB
date: 2019-07-16T08:00:00+08:00
categories: [ devops ]
tags: [mongodb,docker]
description:  使用Docker安装MongoDB
---

# 使用Docker安装

下载镜像：

```bash
docker pull mongo 
```

创建目录：

```bash
mkdir -p /data/docker/mongodb/data/

mkdir -p /data/docker/mongo/configdb
```

开启端口：

```
firewall-cmd --zone=public --add-port=27017/tcp --permanent
```

运行容器：

```bash
docker run -d  -p 27017:27017 \
  -v /data/docker/mongodb/data/:/data/db/ \
  -v /data/docker/mongo/configdb:/data/configdb \
  --auth --name=mongo mongo 
```

- `--auth`：开启权限验证模式。默认情况下，mongo 数据库没有添加认证约束，为了增强数据库的安全性，我们需要对数据库添加授权认证。当我不加这个认证约束时，一个数据库的账号可以操作另一个数据库的数据，只有加了这个参数，我们针对某些数据库设置的角色，才仅在这个数据库上生效。

进入容器：

```bash
docker exec -it mongo bash
```

进入mongo:

```bash
mongo
```

也可以直接用下面命令一步到位，并使用admin数据库：

```bash
docker exec -it mongo mongo admin
```

创建一个拥有最高权限的 root 账号，然后退出。

```
use admin

db.createUser(
{
user: "admin",
pwd: "admin",
roles: [ { role: "root", db: "admin" } ]
}
);
```

role 角色参数：

- `Read`：允许用户读取指定数据库
- `readWrite`：允许用户读写指定数据库
- `dbAdmin`：允许用户在指定数据库中执行管理函数，如索引创建、删除，查看统计或访问system.profile
- `userAdmin`：允许用户向system.users集合写入，可以找指定数据库里创建、删除和管理用户
- `clusterAdmin`：只在admin数据库中可用，赋予用户所有分片和复制集相关函数的管理权限
- `readAnyDatabase`：只在admin数据库中可用，赋予用户所有数据库的读权限
- `readWriteAnyDatabase`：只在admin数据库中可用，赋予用户所有数据库的读写权限
- `userAdminAnyDatabase`：只在admin数据库中可用，赋予用户所有数据库的userAdmin权限
- `dbAdminAnyDatabase`：只在admin数据库中可用，赋予用户所有数据库的dbAdmin权限
- `root`：只在admin数据库中可用。超级账号，超级权限

管理员已经创建成功后，我们需要重新连接 mongo 数据库，用管理员进行登录，并为目标数据库创建目标用户：

```bash
# 进入容器，并切换到 admin 数据库
docker exec -it mongo mongo admin
```

```
# 授权 admin
db.auth("admin", "123456");
# 创建访问指定数据库的用户
use beta;
db.createUser({ user: 'test', pwd:'test', roles: [ {role:"readWrite",db:"beta"}]});
db.auth("test","test");
# 尝试插入一条数据
use beta
db.test.insertOne({name:"michael",age:"28"})
# 搜索 test collection 全部记录
db.test.find()
```


也可以这样访问：

```bash
mongo --port 27017 -u admin -p admin --host 192.168.56.100 
```

# docker-compose安装：

```yml
version: "3"
services:
    mongodb:
        image: mongo
        container_name: mongo # 容器名
        ports:
            - "27017:27017"
        volumes:
            - "/data/docker/mongo/configdb:/data/configdb"
            - "/data/docker/mongo/data/db:/data/db"
        command: --auth # 开启授权验证
```


# 安装 mongoclient 镜像

下载镜像：

```
docker pull mongoclient/mongoclient
```

运行容器：

```bash
docker run --name mongoclient -d -p 3001:3000 -e MONGO_URL=mongodb://192.168.56.100:27017/admin --restart=always mongoclient/mongoclient
```

访问 http://192.168.56.100:3001


