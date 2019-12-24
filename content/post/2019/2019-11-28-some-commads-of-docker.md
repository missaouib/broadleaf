---
layout: post
title: Docker常用命令
date: 2019-11-28T08:00:00+08:00
categories: [ docker ]
tags: [docker]
---



## 获取docker容器的主机虚拟网卡

```bash
#首先得到容器进程的pid
CON_PID=$(docker inspect '--format={{ .State.Pid }}' test)
#首先得到容器的命名空间目录
CON_NET_SANDBOX=$(docker inspect '--format={{ .NetworkSettings.SandboxKey }}' test)
#在netns目录下创建至容器网络名字空间的链接，方便下面在docker主机上执行ip netns命令对容器的网络名字空间进行操作
rm -f /var/run/netns/$CON_PID
mkdir -p /var/run/netns
ln -s $CON_NET_SANDBOX /var/run/netns/$CON_PID
#获取主机虚拟网卡ID
VETH_ID=$(ip netns exec $CON_PID ip link show eth0|head -n 1|awk -F: '{print $1}')
#获取主机虚拟网卡名称
VETH_NAME=$(ip link|grep "if${VETH_ID}:"|awk '{print $2}'|awk -F@ '{print $1}')
#最后删除在netns目录下创建的链接
rm -f /var/run/netns/$CON_PID
```

pipework扩展docker的网络 [https://jeremyxu2010.github.io/2016/09/%E7%A0%94%E7%A9%B6pipework/](https://jeremyxu2010.github.io/2016/09/研究pipework/)

## 查看已经安装的镜像

```bash
docker images --format '{{.Repository}}:{{.Tag}}'
```

## 删除停止或已创建状态的实例

```bash
docker rm $(docker ps -a -q --filter status=exited)

docker ps --filter status=exited|sed -n -e '2,$p'|awk '{print $1}'|xargs docker rm
docker ps --filter status=created|sed -n -e '2,$p'|awk '{print $1}'|xargs docker rm
```

## 删除虚悬镜像

```bash
docker image prune --force
```

## 删除REPOSITORY是长uuid的镜像

```bash
# 删除REPOSITORY是长uuid的镜像
docker images | sed -n -e '2,$p'|awk '{if($1 ~ /[0-9a-f]{32}/) print $1":"$2}'|xargs docker rmi
# 删除TAG是长长uuid的镜像
docker images | sed -n -e '2,$p'|awk '{if($2 ~ /[0-9a-f]{64}/) print $1":"$2}'|xargs docker rmi
```

## 列出registry中的镜像

官方的docker registry虽然提供了一系列操作镜像的Restful API，但查看镜像列表并不直观，于是可以使用以下脚本查看registry中的镜像列表：

```bash
DOCKER_REGISTRY_ADDR=127.0.0.1:5000
for img in `curl -s ${DOCKER_REGISTRY_ADDR}/v2/_catalog | python -m json.tool | jq ".repositories[]" | tr -d '"'`; do
  for tag in `curl -s ${DOCKER_REGISTRY_ADDR}/v2/${img}/tags/list|jq ".tags[]" | tr -d '"'`; do
    echo $img:$tag
  done
done
```

## 删除registry中的某个镜像

docker registry上的镜像默认是不允许删除的，如要删除，需要在启动docker registry时指定环境变量`REGISTRY_STORAGE_DELETE_ENABLED=true`，然后可以利用以下脚本删除镜像：

```bash
DOCKER_REGISTRY_ADDR=127.0.0.1:5000
function delete_image {
    imgFullName=$1
    img=`echo $imgFullName | awk -F ':' '{print $1}'`
    tag=`echo $imgFullName | awk -F ':' '{print $2}'`
    
    # delete image's blobs
    for digest in `curl -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -s ${DOCKER_REGISTRY_ADDR}/v2/${img}/manifests/${tag} | jq ".layers[].digest" | tr -d '"'`; do
      curl -X DELETE ${DOCKER_REGISTRY_ADDR}/v2/${img}/blobs/${digest}      
    done
    
    # delete image's manifest
    imgDigest=`curl -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -s ${DOCKER_REGISTRY_ADDR}/v2/${img}/manifests/${tag} | jq ".config.digest" | tr -d '"'`
    curl -X DELETE ${DOCKER_REGISTRY_ADDR}/v2/${img}//manifests/${imgDigest}
}
```

## 列出k8s中使用到的镜像

有时需要列出Kubernetes中目前使用到的所有镜像，可以用以下脚本：

```bash
for img in `kubectl get pod -o yaml --all-namespaces | grep 'image:' | cut -c14- | sort | uniq`; do
   echo $img
   # save image to tar file
   save_dir=${img%/*}
   mkdir -p $save_dir
   docker save -o ${img}.tar ${img}
done
```