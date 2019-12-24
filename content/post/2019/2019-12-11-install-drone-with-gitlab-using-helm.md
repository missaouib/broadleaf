---
layout: post
title: 使用Helm安装Drone集成Gitlab
date: 2019-12-11T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,drone,gitlab]
---

Drone 是用 Go 语言编写的基于 Docker 构建的开源轻量级 CI/CD 工具，可以和 Gitlab 集成使用。本文主要记录安装 Drone 的过程，并集成 Gitlab。

# 创建证书

参考 [使用Cert Manager配置Let’s Encrypt证书](http://blog.javachen.space/2019/11/04/using-cert-manager-with-nginx-ingress/) 这篇完整，创建一个godaddy证书的签发机构：

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

创建一个命名空间：

```bash
kubectl create namespace drone
```

创建一个证书：

```bash
cat << EOF | kubectl create -f -   
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: drone-javachen-space-cert
  namespace: drone
spec:
  secretName: drone-javachen-space-cert
  renewBefore: 240h
  dnsNames:
  - "*.javachen.space"
  issuerRef:
    name: javachen-space-letsencrypt-prod
    kind: ClusterIssuer
EOF
```

查看证书状态：

```bash
kubectl get secret,Certificate -n drone
kubectl describe secret drone-javachen-space-cert -n drone
kubectl describe certificate drone-javachen-space-cert -n drone
kubectl describe order drone-javachen-space-cert-2742582754 -n drone
kubectl describe Challenge drone-javachen-space-cert-695846883-0 -n drone
```



# 安装Drone

查找chart

这里使用我修改过的chart：

```bash
git clone https://github.com/javachen/charts
cd charts
```

根据chart中 values.yaml文件创建drone-gitlab-values.yaml：

```bash
cat <<EOF > drone-gitlab-values.yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: 10m
  hosts:
    - drone.javachen.space
  tls:
    - secretName: drone-javachen-space-cert
      hosts:
        - drone.javachen.space

sourceControl:
  provider: gitlab
  gitlab:
    clientID: 3a3c6b5d37b6557168759389080d331fed992218b9b8cac8b2bc6516b292429b
    clientSecretKey: clientSecret
    clientSecretValue: eb60347cffd7614eef2dba4abbd5783779647be2aed4a3fd78eae31ee1480138
    server: http://gitlab.javachen.space

server:
  host: drone.javachen.space
  protocol: https
  adminUser: admin
  alwaysAuth: true
  envSecrets:
    drone-gitlab-login-secrets:
      - DRONE_GIT_USERNAME
      - DRONE_GIT_PASSWORD
  kubernetes:
    enabled: true

#env:
#  DRONE_LOGS_DEBUG: "false"
#  DRONE_DATABASE_DRIVER: "mysql"
#  DRONE_DATABASE_DATASOURCE: "root:123456@tcp(192.168.1.100:3306)/drone?parseTime=true"
  
persistence:
  enabled: true
  storageClass: ceph-rbd
  size: 5Gi
EOF
```

注意：

1、`nginx.ingress.kubernetes.io/proxy-body-size: 10m` 设置上传文件大小

2、drone-gitlab-login-secrets 是设置获取gitlab仓库代码的用户名和密码的secret。创建过程如下：

```bash
#假设登陆用户名和密码都为admin
echo -n "admin" | base64

cat << EOF | kubectl create -f -  
apiVersion: v1
kind: Secret
metadata:
  name: drone-gitlab-login-secrets
  namespace: drone
type: Opaque
data:
  DRONE_GIT_USERNAME: YWRtaW4=
  DRONE_GIT_PASSWORD: YWRtaW4=
EOF
```

3、http://gitlab.javachen.space 是gitlab服务的地址，clientID 和 clientSecretValue 是在gitlab中创建一个应用,设置重定向地址：https://drone.javachen.space/hook ，得到的clientID 和 clientSecretValue

4、这里设置了persistence为启用，并且存储类为 ceph-rbd ，这个需要提前创建，可以参考我安装harbor的文章。

5、你也可以去掉上面的注释，设置drone使用mysql数据库。



使用helm3安装drone：

```bash
helm install drone \
     --namespace drone \
     -f drone-gitlab-values.yaml \
     ./drone
```



查看状态：

```bash
kubectl get all -n drone
```



浏览器输入  https://drone.javachen.space/ ，会跳转到 Gitlab 进行授权，接下来就可以同步仓库。

# 安装Drone CLI

安装drone cli：

```bash
curl -L https://github.com/drone/drone-cli/releases/latest/download/drone_linux_amd64.tar.gz | tar zx
sudo install -t /usr/local/bin drone
```

# 卸载Drone

```bash
helm del drone -n drone
kubectl delete pod,service,deploy,ingress,secret,pvc --all -n drone  

kubectl delete secret,certificate drone-javachen-space-cert -n drone
```

drone安装成功后，在 https://drone.javachen.space/account 上获取 Drone 的TOKEN，查看drone信息：

```bash
export DRONE_SERVER= https://drone.javachen.space/account 
export DRONE_TOKEN=0FJZSq9dYtAnOvyXlL3Os6aIoBPtxRaa
drone info
```

上面会输出登陆gitlab的用户名和密码。



drone 还提供了一些方法，例如可以创建 secret，参考 https://github.com/hectorqin/drone-kubectl 这个插件，假设 drone 从gitlab同步了一个仓库 叫做 chenzj/test，则可以通过下面命令创建几个Secret：

```bash
DEFAULT_SECRET=`kubectl get secret -n drone|grep drone-deploy-token|awk '{print $1}'`

KUBERNETES_SERVER=`kubectl config view|grep server|awk '{print $2}'`

KUBERNETES_CERT=`kubectl get secret -n drone ${DEFAULT_SECRET} -o jsonpath="{.data.ca\.crt}"` 

KUBERNETES_TOKEN=`kubectl get secret -n drone ${DEFAULT_SECRET} -o jsonpath="{.data.token}" | base64 --decode` 


export DRONE_SERVER= https://drone.javachen.space/account 
export DRONE_TOKEN=0FJZSq9dYtAnOvyXlL3Os6aIoBPtxRaa
drone info

drone secret add chenzj/test --name KUBERNETES_SERVER --data ${KUBERNETES_SERVER} --allow-pull-request
drone secret add chenzj/test --name KUBERNETES_CERT --data ${KUBERNETES_CERT} --allow-pull-request
drone secret add chenzj/test --name KUBERNETES_TOKEN --data ${KUBERNETES_TOKEN} --allow-pull-request

```

执行完成之后，在drone页面的 chenzj/test 仓库 SETTINGS 里面可以看到上面创建的三个 secret。

然后，就可以在.drone.yaml中使用插件：

```yaml
 - name: deploy
   image: quay.io/hectorqin/drone-kubectl
   settings:
     kubernetes_template: k8s/test/deployment.yaml
     kubernetes_namespace: test
   environment:
     KUBERNETES_SERVER:
       from_secret: KUBERNETES_SERVER
     KUBERNETES_CERT:
       from_secret: KUBERNETES_CERT
     KUBERNETES_TOKEN:
       from_secret: KUBERNETES_TOKEN
   depends_on:
     - build
   when:
     event:
       - push
       - tag
```

当然，还需要创建 RBAC ：

```yaml
cat << EOF | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: drone-deploy
  namespace: drone
---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: drone-deploy
rules:
  - apiGroups: ["","*"]
    resources: ["*"]
    verbs: ["*"]

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: drone-deploy
subjects:
  - kind: ServiceAccount
    name: drone-deploy
    namespace: drone
roleRef:
  kind: ClusterRole
  name: drone-deploy
  apiGroup: rbac.authorization.k8s.io
EOF
```

