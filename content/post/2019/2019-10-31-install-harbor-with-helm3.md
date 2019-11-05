---
layout: post
title: 使用Helm3安装Harbor
date: 2019-10-31T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,helm,harbor]
---

Harbor是构建企业级私有docker镜像的仓库的开源解决方案，它是Docker Registry的更高级封装，它除了提供友好的Web UI界面，角色和用户权限管理，用户操作审计等功能外，它还整合了K8s的插件(Add-ons)仓库。

> 注意：本文使用的Helm版本是3，不是2，所以有些命令和helm2不一样。

# 添加仓库

```
helm repo add harbor https://helm.goharbor.io
```

# 初始化

详细配置参数，参考：https://github.com/goharbor/harbor-helm

# 使用存储安装

这里使用storageClass，则需要先创建storageClass，请参考ceph。

## 创建存储池

```bash
cmd.sh "sudo modprobe rbd"
ceph osd pool create k8s 256
```

创建秘钥：

```bash
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: ceph-admin-secret
type: "kubernetes.io/rbd"
data:
  key: $(grep key /etc/ceph/ceph.client.admin.keyring |awk '{printf "%s", $NF}'|base64)
EOF
```

创建存储类：

```bash
cat << EOF | kubectl create -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd
provisioner: kubernetes.io/rbd
parameters:
   monitors: 192.168.56.111:6789
   adminId: admin
   adminSecretName: ceph-admin-secret
   adminSecretNamespace: default
   pool: k8s
   userId: admin
   userSecretName: ceph-admin-secret
   userSecretNamespace: default
EOF
```

将存储类设置为默认：

```bash
kubectl patch storageclass ceph-rbd -p \	
	'{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## 创建pvc

如果要使用pvc，创建存储卷配置文件harbor-pvc.yaml：

```yaml
cat << EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: harbor-pvc
  namespace: harbor
spec:
  storageClassName: ceph-rbd
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
EOF

kubectl get pvc -n devops
```

## 安装Harbor

这里直接使用存储类，不创建pvc。

使用helm3安装：

```bash
helm install harbor harbor/harbor --namespace harbor --debug\
	--set externalURL=https://harbor.javachen.com  \
  --set expose.ingress.hosts.core=harbor.javachen.com \
  --set expose.ingress.hosts.notary=harbor.javachen.com \
  --set persistence.persistentVolumeClaim.registry.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --set persistence.persistentVolumeClaim.chartmuseum.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.jobservice.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.size=5Gi \
  --set persistence.persistentVolumeClaim.redis.storageClass=ceph-rbd \
  --set harborAdminPassword=admin123456 
```

# 不使用存储安装

使用helm3安装：

```bash
  helm install harbor harbor/harbor --namespace harbor --debug\
  --set externalURL=https://harbor.javachen.com  \
  --set expose.ingress.hosts.core=harbor.javachen.com \
  --set expose.ingress.hosts.notary=harbor.javachen.com \
  --set persistence.enabled=false \
  --set harborAdminPassword=admin123456
```

# 配置证书

## 使用Harbor自带的证书

使用helm3安装：

```bash
helm install harbor harbor/harbor --namespace harbor --debug\
	--set externalURL=https://harbor.javachen.com  \
  --set expose.ingress.hosts.core=harbor.javachen.com \
  --set expose.ingress.hosts.notary=harbor.javachen.com \
  --set persistence.persistentVolumeClaim.registry.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --set persistence.persistentVolumeClaim.chartmuseum.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.jobservice.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.size=2Gi \
  --set persistence.persistentVolumeClaim.redis.storageClass=ceph-rbd \
  --set harborAdminPassword=admin123456 
```

查看证书：

```bash
kubectl get secret -n harbor

kubectl get secret -n harbor harbor-secret-tls \
    -o jsonpath="{.data.ca\.crt}" | base64 --decode
```

可以将证书导入到docker证书目录下面，这样docker就会信任该镜像仓库

```bash
kubectl get secret -n harbor harbor-harbor-ingress \
    -o jsonpath="{.data.ca\.crt}" | base64 --decode | \
    sudo tee /etc/docker/certs.d/harbor.javachen.com/ca.crt
```

可以查看harbor密码：

```bash
kubectl get secret -n harbor harbor-harbor-core -o \
	jsonpath="{.data.HARBOR_ADMIN_PASSWORD}" | base64 --decode
```

## 使用证书文件

可以用权威证书，或者是自签名证书，然后创建harbor-secret-tls。

helm3安装：

```bash
helm install harbor harbor/harbor --namespace harbor --debug\
	--set externalURL=https://harbor.javachen.com  \
  --set expose.tls.secretName="harbor-secret-tls" \
  --set expose.ingress.hosts.core=harbor.javachen.com \
  --set expose.ingress.hosts.notary=harbor.javachen.com \
  --set persistence.persistentVolumeClaim.registry.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --set persistence.persistentVolumeClaim.chartmuseum.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.jobservice.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.size=2Gi \
  --set persistence.persistentVolumeClaim.redis.storageClass=ceph-rbd \
  --set harborAdminPassword=admin123456 
```

# 查看状态

```bash
kubectl get pod -o wide -n harbor

#如果pod初始化很慢，可以查看具体日志：
kubectl describe pod harbor-harbor-database-0 -n harbor

kubectl get pod,pv,pvc,sc,ingress,deployment,ingress -n harbor
```

查看rbd上创建的块：

```bash
$ rbd list k8s
kubernetes-dynamic-pvc-44f0325a-ec2e-414c-bc93-34503050fa1d
kubernetes-dynamic-pvc-76dedc13-a83d-485e-a4cb-41280cd0e7d0
kubernetes-dynamic-pvc-99414704-8eac-4adc-aa65-9a458fe859ec
kubernetes-dynamic-pvc-c8dd8c01-07b1-4d31-9b82-0aecf9f76f3c
kubernetes-dynamic-pvc-f9b96d83-3859-4942-8c25-c72c515bb997
```

查看Rancher上创建的pvc：

![image-20191101182137146](https://tva1.sinaimg.cn/large/006y8mN6ly1g8ipm4dhmuj318w0fogp7.jpg)

在ceph节点上查看挂载信息

```bash
cmd.sh "mount |grep rbd|grep /var/lib/kubelet/pods"
```

![image-20191101182311225](https://tva1.sinaimg.cn/large/006y8mN6ly1g8ipnpnmxuj316a0gmgoc.jpg)



helm list查不到结果，可能是helm3的bug？

```bash
helm list
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION
```

# 浏览器访问服务

在本地配置hosts文件到ingress对应的任意一个节点：

```
192.168.56.111 harbor.javachen.com
```

浏览器访问harbor：https://harbor.javachen.com/ ，用户名和密码：admin/admin123

**docker login登陆验证**

docker登陆：

```bash
$ docker login harbor.javachen.com
Username: admin
Password:
```

**在kubernetes中使用harbor，为了避免输入账号密码，需要创建secret**。以下操作在master上执行：

创建secret

```
kubectl create secret docker-registry harbor-registry-secret \
	--docker-server=harbor.javachen.com -n harbor --docker-username=admin \
	--docker-password=admin123
```

创建完成后，可以用以下命令查看：

```
kubectl get secret  -n harbor
```

出现异常：

```
x509: certificate is valid for ingress.local, not drone.javachen.com
```

参考：[解决harbor+cert-manager出现ingress-nginx x509: certificate is valid for ingress.local](https://lusyoe.github.io/2019/06/22/解决harbor-cert-manager出现ingress-nginx-x509-certificate-is-valid-for-ingress-local/)

原因：在于证书不对，检查一遍，重新创建证书和TLS。

# 上传下载测试

```bash
$ docker images
rancher/pause     3.1       da86e6ba6ca1        21 months ago       742kB

docker tag rancher/pause:3.1 harbor.javachen.com/soft/pause:3.2

docker push harbor.javachen.com/soft/pause:3.2 
```

然后，在harbor管理界面中查看上传的镜像。

# 卸载

```bash
helm del harbor

kubectl delete secret harbor-secret-tls -n harbor
kubectl delete pvc -n harbor harbor-harbor-chartmuseum \
	data-harbor-harbor-redis-0 \
	database-data-harbor-harbor-database-0 \
  harbor-harbor-jobservice \
  harbor-harbor-registry

#还要删除rbd上的块
rbd list k8s
  
```

