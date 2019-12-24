---
layout: post
title: 使用Helm安装Harbor
date: 2019-10-31T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,helm,harbor]
---

Harbor是构建企业级私有docker镜像的仓库的开源解决方案，它是Docker Registry的更高级封装，它除了提供友好的Web UI界面，角色和用户权限管理，用户操作审计等功能外，它还整合了K8s的插件(Add-ons)仓库。

# 准备工作

详细配置参数，参考：https://github.com/goharbor/harbor-helm

## 创建存储池

这里使用storageClass，则需要先创建storageClass，请参考ceph。

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
# 设置回收策略默认为：Retain
reclaimPolicy: Retain
# 添加动态扩容
allowVolumeExpansion: true
EOF
```

将存储类设置为默认：

```bash
kubectl patch storageclass ceph-rbd -p \
	'{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## 创建命名空间

```bash
kubectl create namespace harbor
```

## 添加仓库

```bash
helm repo add harbor https://helm.goharbor.io
```

## 创建证书

### 使用letsencrypt生成证书文件

参考 [使用Cert Manager配置Let’s Encrypt证书](/2019/11/04/using-cert-manager-with-nginx-ingress/) ，先要创建一个ClusterIssuer：javachen-space-letsencrypt-prod。

```yaml
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: javachen-space-letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: junecloud@163.com
    privateKeySecretRef:
      name: javachen-space-letsencrypt-prod
    solvers:
    - selector:
        dnsNames:
        - '*.javachen.space'
      dns01:
        webhook:
          groupName: acme.javachen.space 
          solverName: godaddy
          config:
            authApiKey: e4hN4QrFgzdo_RHXe1ef2qpBPmiJPD2ZUcW
            authApiSecret: QsHuDdnnCbzp5DmEQzq4ts
            production: true
            ttl: 600
EOF
```



因为证书是有命名空间的，所以需要在harbor命名空间创建证书：

```yaml
cat << EOF | kubectl create -f -   
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: harbor-cert-prod
  namespace: harbor
spec:
  secretName: harbor-javachen-space-cert
  renewBefore: 240h
  groupName: acme.javachen.space 
  dnsNames:
  - "*.javachen.space"
  issuerRef:
    name: javachen-space-letsencrypt-prod
    kind: ClusterIssuer
EOF
```



# 安装Harbor

不配置存储，使用默认的证书，禁用clair、notary、chartmuseum，通过helm3安装：

```bash
helm install harbor harbor/harbor --namespace harbor --debug \
  --set externalURL=https://harbor.javachen.space  \
  --set expose.ingress.hosts.core=harbor.javachen.space \
  --set expose.ingress.hosts.notary=harbor.javachen.space \
  --set persistence.enabled=false \
  --set clair.enabled=false \
  --set notary.enabled=false \
  --set chartmuseum.enabled=false \
  --set harborAdminPassword=admin123
```

配置存储，使用默认的证书，通过helm3安装：

```bash
helm install harbor harbor/harbor --namespace harbor --debug \
  --set externalURL=https://harbor.javachen.space  \
  --set expose.ingress.hosts.core=harbor.javachen.space \
  --set expose.ingress.hosts.notary=harbor.javachen.space \
  --set persistence.persistentVolumeClaim.registry.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --set persistence.persistentVolumeClaim.chartmuseum.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.jobservice.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.size=5Gi \
  --set persistence.persistentVolumeClaim.redis.storageClass=ceph-rbd \
  --set harborAdminPassword=admin123
```

配置存储，使用前面letsencrypt生成的harbor-javachen-space-cert证书，通过helm3安装：

```bash
helm install harbor harbor/harbor --namespace harbor --debug \
  --set externalURL=https://harbor.javachen.space  \
  --set expose.tls.secretName="harbor-javachen-space-cert" \
  --set expose.tls.notarySecretName="notary-javachen-space-cert" \
  --set expose.ingress.hosts.core=harbor.javachen.space \
  --set expose.ingress.hosts.notary=notary.javachen.space \
  --set persistence.persistentVolumeClaim.registry.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --set persistence.persistentVolumeClaim.chartmuseum.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.jobservice.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.storageClass=ceph-rbd \
  --set persistence.persistentVolumeClaim.database.size=5Gi \
  --set persistence.persistentVolumeClaim.redis.storageClass=ceph-rbd \
  --set harborAdminPassword=admin123
```

配置存储，使用ingress自动生成证书（参考 [结合Cert-Manager完成Harbor的Https证书自动签发](https://lusyoe.github.io/2019/06/22/结合Cert-Manager完成Harbor的Https证书自动签发/)），通过helm3安装：

创建harbor-values.yaml

```yaml
expose:
  type: ingress
  tls:
    enabled: true
   # 这里可以随意填写一个，cert-manager会自动创建并挂载
    secretName: "harbor-javachen-space-cert"
    notarySecretName: "notary-javachen-space-cert"
    commonName: ""
  ingress:
    hosts:
      core: harbor.javachen.space
      notary: notary.javachen.space
    annotations:
      ingress.kubernetes.io/ssl-redirect: "true"
      cert-manager.io/issuer: javachen-space-letsencrypt-prod
externalURL: https://harbor.javachen.space
harborAdminPassword: admin123
persistence:
  persistentVolumeClaim:
    registry:
      storageClass: ceph-rbd
      size: 50Gi
    chartmuseum:
      storageClass: ceph-rbd
    jobservice:
      storageClass: ceph-rbd
    database:
      storageClass: ceph-rbd
      size: 5Gi
    redis:
      storageClass: ceph-rbd
```

运行安装：

```bash
helm install harbor harbor/harbor --namespace harbor -f harbor-values.yaml
```

# 查看状态

```bash
kubectl get pod -o wide -n harbor

#如果pod初始化很慢，可以查看具体日志：
kubectl describe pod harbor-harbor-database-0 -n harbor

kubectl get pod,pv,pvc,sc,ingress,deployment,ingress -n harbor
```

如果下载镜像慢，则手动下载：

```bash
docker pull busybox:latest
docker pull goharbor/harbor-db:v1.9.3
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



# 查看证书

```bash
kubectl get secret -n harbor

kubectl get secret -n harbor harbor-harbor-ingress \
    -o jsonpath="{.data.ca\.crt}" | base64 --decode
```

可以将证书导入到docker证书目录下面，这样docker就会信任该镜像仓库

```bash
kubectl get secret -n harbor harbor-harbor-ingress \
    -o jsonpath="{.data.ca\.crt}" | base64 --decode | \
    sudo tee /etc/docker/certs.d/harbor.javachen.space/ca.crt
```

可以查看harbor密码：

```bash
kubectl get secret -n harbor harbor-harbor-core -o \
	jsonpath="{.data.HARBOR_ADMIN_PASSWORD}" | base64 --decode
```



# 浏览器访问服务

浏览器访问harbor：https://harbor.javachen.space/ ，用户名和密码：admin/admin123，可以看到证书是被浏览器信任的。

# **docker 登陆验证**

docker登陆：

```bash
$ docker login harbor.javachen.space
Username: admin
Password:
```

**在kubernetes中使用harbor，为了避免输入账号密码，需要创建secret**。以下操作在master上执行：

创建secret

```
kubectl create secret docker-registry harbor-registry-secret \
	--docker-server=harbor.javachen.space -n harbor --docker-username=admin \
	--docker-password=admin123
```

创建完成后，可以用以下命令查看：

```
kubectl get secret  -n harbor
```

出现异常：

```
x509: certificate is valid for ingress.local, not harbor.javachen.space
```

参考：[解决harbor+cert-manager出现ingress-nginx x509: certificate is valid for ingress.local](https://lusyoe.github.io/2019/06/22/解决harbor-cert-manager出现ingress-nginx-x509-certificate-is-valid-for-ingress-local/)

原因：在于证书的CA签发组织不对，使用Helm生成的证书默认域名是ingress.local，不是harbor.javachen.space。

出现异常：

```bash
Error response from daemon: Get https://harbor.javachen.space/v2/: x509: certificate signed by unknown authority
```

参考前面，将harbor证书导入到docker证书目录下面，这样docker就会信任该镜像仓库

```bash
sudo mkdir -p /etc/docker/certs.d/harbor.javachen.space/

kubectl get secret -n harbor harbor-harbor-ingress \
    -o jsonpath="{.data.ca\.crt}" | base64 --decode | \
    sudo tee /etc/docker/certs.d/harbor.javachen.space/ca.crt
```



# 上传下载测试

在harbor管理界面，创建一个soft项目



上传镜像：

```bash
$ docker images
rancher/pause     3.1       da86e6ba6ca1        21 months ago       742kB


docker tag rancher/pause:3.1 harbor.javachen.space/soft/pause:3.2
docker push harbor.javachen.space/soft/pause:3.2

docker tag rancher/pause:3.1 harbor.javachen.space/soft/pause:latest
docker push harbor.javachen.space/soft/pause:latest
```

然后，在harbor管理界面中查看上传的镜像。

# 卸载

```bash
#删除release
helm del --purge harbor

#删除pvc
kubectl delete pvc -n harbor data-harbor-harbor-redis-0 \
	database-data-harbor-harbor-database-0 \
  harbor-harbor-chartmuseum \
  harbor-harbor-jobservice \
  harbor-harbor-registry


kubectl delete pod,service,deploy,statefulset,ingress,secret,pvc,replicaset,\
	daemonset,ConfigMap --all -n harbor

#删除证书
kubectl delete Certificate,secret harbor-javachen-space-cert -n harbor

#还要删除rbd上的块
rbd list k8s
```
