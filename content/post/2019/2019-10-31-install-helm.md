---
layout: post
title: 安装Helm
date: 2019-10-31T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,helm]
---

Helm 是由 Deis 发起的一个开源工具，有助于简化部署和管理 Kubernetes 应用。本文主要是记录Helm 2的安装过程。

# Helm镜像

- Helm官方镜像：[https://kubernetes-charts.storage.googleapis.com](https://kubernetes-charts.storage.googleapis.com/)，对应国内镜像仓库：[https://kubernetes-charts.proxy.ustclug.org](https://kubernetes-charts.proxy.ustclug.org/)
- 阿里云Helm仓库：https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts

# 安装Helm2

## 安装 Helm 客户端

在Helm3发布之前，下载最新的Helm2版本：

```bash
helm_version=`curl -s  "https://api.github.com/repos/helm/helm/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'`
curl -s https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz| tar zxvf -
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo rm -rf linux-amd64
```

但是，在Helm3发布之后，上面的脚本实际上安装的是V3版本，所以用官方脚本：

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash
```

查看版本，会提示无法连接到服务端Tiller

```bash
$ helm version
Client: &version.Version{SemVer:"v2.16.1", GitCommit:"8dce272473e5f2a7bf58ce79bb5c3691db54c96b", GitTreeState:"clean"}
Error: could not find tiller
```

## 安装服务器端 Tiller

要安装 Helm 的服务端程序，我们需要使用到kubectl工具，所以先确保kubectl工具能够正常的访问 kubernetes 集群的apiserver哦。

### 配置RBAC访问权限

因为 Helm 的服务端 Tiller 是一个部署在 Kubernetes 中 Kube-System Namespace 下 的 Deployment，它会去连接 Kube-Api 在 Kubernetes 里创建和删除应用。

而从 Kubernetes 1.6 版本开始，API Server 启用了 RBAC 授权。目前的 Tiller 部署时默认没有定义授权的 ServiceAccount，这会导致访问 API Server 时被拒绝。所以我们需要明确为 Tiller 部署添加授权。

创建 Kubernetes 的服务帐号和绑定角色

```bash
#创建tiller serviceaccount
kubectl -n kube-system create serviceaccount tiller

#创建tiller clusterrolebinding
kubectl create clusterrolebinding tiller \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller
```

或者使用ymal创建rbac.yaml文件：

```yaml
cat >>EOF | kubectl create -f
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF    
```

### 安装tiller

```bash
#安装tiller
helm_version=`helm version |grep Client | awk -F""\" '{print $2}'`

helm init --skip-refresh --service-account=tiller \
	--tiller-image registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:${helm_version} \
  --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
```

## 配置TLS

安全性更高的安装tiller(tls)：https://helm.sh/docs/using_helm/#using-ssl-between-helm-and-tiller

为了安全，在helm客户端和tiller服务器间建立安全的SSL/TLS认证机制；tiller服务器和helm客户端都是使用同一CA签发的client cert，然后互相识别对方身份。

创建证书：

```bash
# CA
openssl genrsa -out ca.key 4096
openssl req -key ca.key -new -x509 -days 7300 -sha256 -out ca.cert \
	-extensions v3_ca -subj /C=CN/ST=HuBei/L=Wuhan/O=DevOps/CN=helm.javachen.space

#为helm客户端生成证书
openssl genrsa -out ./helm.key 4096
openssl req -key helm.key -new -sha256 -out helm.csr -subj \
	/C=CN/ST=HuBei/L=Wuhan/O=DevOps/CN=helm.javachen.space

#为tiller生成证书
openssl genrsa -out tiller.key 4096
openssl req -key tiller.key -new -sha256 -out tiller.csr -subj \
	/C=CN/ST=HuBei/L=Wuhan/O=DevOps/CN=helm.javachen.space

openssl x509 -req -CA ca.cert -CAkey ca.key -CAcreateserial -in tiller.csr \
	-out tiller.cert -days 3650
openssl x509 -req -CA ca.cert -CAkey ca.key -CAcreateserial -in helm.csr -out helm.cert -days 3650
```

更新：

```bash
helm init --debug --upgrade\
	--tiller-image registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.15.2 \
  --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts \
  --tiller-tls \
  --tiller-tls-verify \
  --tiller-tls-cert=tiller.cert \
  --tiller-tls-key=tiller.key \
  --tls-ca-cert=ca.cert \
  --service-account=tiller
```

## 检查tiller安装状态

```
kubectl -n kube-system rollout status deploy/tiller-deploy

kubectl get pods -n kube-system |grep tiller-deploy
```

## 检查版本

```
helm version
```

## 卸载

如果你需要在 Kubernetes 中卸载已部署的 Tiller，可使用以下命令完成卸载。

```
helm reset


rm -rf ~/.helm/ ~/.cache/ ~/.config
```

# Helm2升级到Helm3

## 下载Helm3

```bash
curl -s https://get.helm.sh/helm-v3.0.0-linux-amd64.tar.gz| tar zxvf -
sudo mv linux-amd64/helm /usr/local/bin/helm3
sudo rm -rf linux-amd64

helm3 repo list
```

## 安装迁移插件

```
helm3 plugin install https://github.com/helm/helm-2to3
```

## 迁移配置

```
#模拟执行
helm3 2to3 move config --dry-run

helm3 2to3 move config

helm3 repo list
```

## 迁移应用

```
helm list

helm3 2to3 convert
```

## 删除helm2数据

```
helm3 2to3 cleanup

sudo mv /usr/local/bin/helm3 /usr/local/bin/helm
```

# 安装Helm3

直接下载helm3并安装：

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

查看版本：

```bash
helm version
version.BuildInfo{Version:"v3.0.0", GitCommit:"e29ce2a54e96cd02ccfce88bee4f58bb6e2a28b6", GitTreeState:"clean", GoVersion:"go1.13.4"}
```

查看仓库：

```bash
helm repo list
```

发现没有仓库，需要手动添加：

```bash
#添加 https://apphub.aliyuncs.com
helm repo add stable https://apphub.aliyuncs.com
```

更新镜像：

```bash
helm repo update
```

# Helm3变动

参考：https://github.com/helm/helm/releases/tag/v3.0.0

1、没有客户端和服务端之分，不需要 helm init

2、Chart.yam里面api变成v2，否则通过helm安装的应用，helm list看不到



# Helm 3 使用 harbor 作为仓库存储

## 创建项目

在harbor仓库里创建一个项目，例如chart

```bash
#chart为项目名称
helm repo add chart https://harbor.javachen.space/chartrepo/chart
```

## 安装插件

```bash
helm plugin install https://github.com/chartmuseum/helm-push
```

## 打包镜像

以打包gitea为例

```bash
git clone https://github.com/javachen/charts
cd charts/submitted

#当前目录生成 gitea-1.6.5.tgz
helm package ./gitea 
```

## 推送镜像

推送到chart仓库：

```bash
helm push gitea-1.6.5.tgz chart
```

如果执行失败，可以在harbor界面手动上传到harbor，或者调用api执行：

```bash
curl -i -u "admin:admin123" -k -X POST "https://harbor.javachen.space/api/chartrepo/chart/charts" \
        -H "accept: application/json" \
        -H "Content-Type: multipart/form-data" \
        -F "chart=@gitea-1.10.0-rc2.tgz;type=application/x-compressed" 2>/dev/null
```

## 安装镜像

```bash
helm install --generate-name --namespace devops \
  --version 1.6.5 \
  --set expose.type=LoadBalancer \
  chart/gitea  #这里的chart对应前面的 
```

