---
layout: post
title: Kubernetes常用命令
date: 2019-11-29T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes]
---



# 查找K8S中高磁盘占用

在节点上执行：

```bash
$ sudo du -h --max-depth 1 /var/lib/docker/
187M	/var/lib/docker/containers
0	/var/lib/docker/plugins
15G	/var/lib/docker/overlay2
17M	/var/lib/docker/image
242M	/var/lib/docker/volumes
0	/var/lib/docker/trust
108K	/var/lib/docker/network
0	/var/lib/docker/swarm
16K	/var/lib/docker/builder
56K	/var/lib/docker/buildkit
0	/var/lib/docker/tmp
0	/var/lib/docker/runtimes
15G	/var/lib/docker/
```

得到的确是Docker占用的磁盘。

在节点上执行：

```bash
$ docker system df
TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              17                  13                  4.99GB              947.2MB (18%)
Containers          20                  15                  163.8MB             0B (0%)
Local Volumes       9                   7                   252.8MB             50.52MB (19%)
Build Cache         0                   0                   0B                  0B
```

得到Images占用磁盘特别高

在节点上执行：

```bash
docker ps -a --format "table {{.Size}}\t{{.Names}}"
```

得到容器的磁盘占用。

进入`kubelet`查看占用情况：

```bash
docker exec -it kubelet /bin/bash
du -h --max-depth 1
```

# 删除命名空间

```bash
NAMESPACE=cert-manager
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
```

将finalizer的value删除，这里将其设置为[]

```bash
kubectl edit namespaces cert-manager
```

