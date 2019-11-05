---
layout: post
title: Docker Compose安装Redis集群
date: 2019-08-11T08:00:00+08:00
categories: [ docker ]
tags: [docker,redis]
description:  Docker Compose安装Redis集群
---

拉取镜像：

```
docker pull redis
```

使用host网络进行搭建集群

```bash
docker run -d --name redis-node01 --net host \
-v /data/docker/redis/node01:/data redis --cluster-enabled yes \
--cluster-config-file node01.conf --port 6380 --appendonly yes \
--requirepass "123456"
 
docker run -d --name redis-node02 --net host \
-v /data/docker/redis/node02:/data redis --cluster-enabled yes \
--cluster-config-file node02.conf --port 6381 --appendonly yes \
--requirepass "123456"

docker run -d --name redis-node03 --net host \
-v /data/docker/redis/node03:/data redis --cluster-enabled yes \
--cluster-config-file node03.conf --port 6382 --appendonly yes \
--requirepass "123456"
```

- `--cluster-config-file`：指定生成的文件名称

进入redis-node01容器进行操作

```
docker exec -it redis-node01 /bin/bash
```

创建集群：

```bash
redis-cli --cluster create 192.168.56.100:6380 192.168.56.100:6381 192.168.56.100:6382 --cluster-replicas 0 -a '123456'
```

- 192.168.56.100是宿主机的地址，这样就能被容器外的机器访问。

查看集群信息：

```bash
$ redis-cli -c -h 192.168.56.100 -p 6380 -a '123456'
$ 192.168.56.100:6380> CLUSTER NODES
590c09a 192.168.56.100:6381@16381 master - 0 1565530654386 2 connected 5461-10922
33c3802 192.168.56.100:6382@16382 master - 0 1565530654000 3 connected 10923-16383
d9ab57f 192.168.56.100:6380@16380 myself,master - 0 1565530652000 1 connected 0-5460
```

- `-c` 集群模式

测试：

```
192.168.56.100:6380> set a 1
-> Redirected to slot [15495] located at 192.168.56.100:6382
OK
192.168.56.100:6382> get a
"1"
```

