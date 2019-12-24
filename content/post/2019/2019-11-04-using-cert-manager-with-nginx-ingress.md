---
layout: post
title: 使用Cert Manager配置Let’s Encrypt证书
date: 2019-11-04T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,ingress,SSL]
---

在 Kubernetes 集群中，可以使用Cert-Manager创建 HTTPS 证书并自动续期，支持从 [Let’s Encrypt](https://letsencrypt.org/) 、[HashiCorp Vault](https://www.vaultproject.io/) 、[Venafi](https://www.venafi.com/)、自签名keypair、自签名文件生成证书。

本文主要记录使用 [Let’s Encrypt](https://letsencrypt.org/) 自动生成证书的过程。参考了 [Quick-Start using Cert-Manager with NGINX Ingress](https://docs.cert-manager.io/en/latest/tutorials/acme/quick-start/index.html#) 进行测试，并且对其中的例子做了一些改动。

Cert-Manager官方文档：https://cert-manager.io/

# 版本说明

本文使用Cert Manager最新版本0.12.0，该版本相对于之前的版本，做了一些改动，例如：API从 certmanager.k8s.io/v1alpha1 改为 cert-manager.io/v1alpha2。

- cert-manager：V0.12.0
- helm：V3.0.0

# 安装 Cert Manager

参考 [安装Cert Manager](/2019/11/02/install-cert-manager/) ，进行安装。

# 部署NGINX Ingress Controller

查看集群是否安装了Ingress Controller：

```bash
kubectl get all -A |grep ingress-controller
```

如果没有安装Ingress Controller，则安装nginx-ingress：

```bash
helm repo add stable https://apphub.aliyuncs.com

helm repo update

helm install nginx-ingress --namespace ingress-nginx stable/nginx-ingress
```

查看状态：

```bash
kubectl get svc
```

# 部署一个服务

参考 [deployment.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/deployment.yaml) 我做了一点修改，原镜像 gcr.io/kuar-demo/kuard-amd64:1 下载慢，所以把镜像改成了tomcat：

```yaml
cat << EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard
spec:
  selector:
    matchLabels:
      app: kuard
  replicas: 1
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
      - image: tomcat  #改用tomcat镜像
        imagePullPolicy: Always
        name: kuard
        ports:
        - containerPort: 8080
EOF
```

参考 [service.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/service.yaml)：

```yaml
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: kuard
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: kuard
EOF
```

你可以不用下载，直接指向下面命令修改：

```bash
#修改创建
kubectl create --edit -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/deployment.yaml

#直接创建
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/service.yaml
```

这时候，可以创建一个 ingress，参考 [ingress.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/ingress.yaml) 

```yaml
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"    
spec:
  rules:
  - host: kuard.javachen.space  #修改域名
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
```

当然，也可以修改创建：

```bash
kubectl create --edit -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/ingress.yaml
```

查看状态：

```
kubectl get all

$ kubectl get ingress
NAME    HOSTS                 ADDRESS          PORTS   AGE
kuard   kuard.javachen.space   192.168.56.111   80      91s
```

#DNS解析

需要注册域名并配置DNS解析，让域名映射到外网地址，否则后面的操作无法进行。

浏览器访问 http://kuard.javachen.space/ ，可以看到tomcat主页。

# 配置 ACME 类型的Issuer

Let’s Encrypt目前支持ACME和CA方式的Issuer，而ACME又分DNS/HTTP两种DNS校验方式。下面基于ACME的方式创建issuer。

我们需要先创建一个签发机构，cert-manager 给我们提供了 Issuer 和 ClusterIssuer 这两种用于创建签发机构的自定义资源对象，Issuer 只能用来签发自己所在 namespace 下的证书，ClusterIssuer 可以签发任意 namespace 下的证书，这里以 Issuer 为例创建一个签发机构。

## 使用HTTP校验的ACME证书

http 方式需要在你的网站根目录下放置一个文件，来验证你的域名所有权完成验证，然后就可以生成证书了。

### 创建一个ClusterIssuer

```bash
cat << EOF | kubectl create -f -   
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: junecloud@163.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the HTTP-01 challenge provider
    solvers:
    # An empty 'selector' means that this solver matches all domains
    - selector: {}
      http01:
        ingress:
          class: nginx
EOF
```

查看一下是否创建成功：

```bash
kubectl describe clusterissuer letsencrypt-prod
```

### 测试自动创建证书

先删除直接创建的ingress：

```bash
kubectl delete ing kuard
```

创建 prod 环境下的 ingress tls

> 注意：kubernetes添加了一行 `certmanager.k8s.io/cluster-issuer: "javachen-xyz-letsencrypt-prod"`

```yaml
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod" #添加，用于标注自动创建证书
spec:
  tls:
  - hosts:
    - kuard.javachen.xyz
    secretName: javachen-xyz-cert
  rules:
  - host: kuard.javachen.xyz
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
```

这种方式，需要在服务器上启动一个web服务，并防置文件，再进行校验，比较麻烦，所以本文不作测试。

![image-20191205181122211](https://tva1.sinaimg.cn/large/006tNbRwly1g9m0dxcnxdj31e80f8n0a.jpg)

## 使用DNS校验的ACME证书

我使用的域名是在腾讯云上购买的，对应DNS解析商是NDSPOD，Cert Manager目前支持的DNS01服务商如下：

- [ACME-DNS](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/acme-dns.html)
- [Akamai FastDNS](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/akamai.html)
- [AzureDNS](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/azuredns.html)
- [Cloudflare](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/cloudflare.html)
- [Google CloudDNS](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/google.html)
- [Amazon Route53](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/route53.html)
- [DigitalOcean](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/digitalocean.html)
- [RFC-2136](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/rfc2136.html)

可以看到，上面不包括阿里云、DNSPOD等等，所以只能用webhook的方式，可以查看目前支持的webhookl的提供商：[Webhook](https://github.com/jetstack/cert-manager/blob/37e201244651311f9ec87616a780f76796ac636f/docs/tasks/issuers/setup-acme/dns01/webhook.rst)

- [alidns-webhook](https://github.com/pragkent/alidns-webhook)
- [cert-manager-webhook-dnspod](https://github.com/qqshfox/cert-manager-webhook-dnspod)
- https://github.com/kaelzhang/cert-manager-webhook-dnspod
- [cert-manager-webhook-selectel](https://github.com/selectel/cert-manager-webhook-selectel)
- [cert-manager-webhook-softlayer](https://github.com/cgroschupp/cert-manager-webhook-softlayer)

当然，也可以查看 [cert-manager-webhook-example](https://github.com/jetstack/cert-manager-webhook-example/network/members) 的folk情况，看是否有人已经实现了其他的webhook：

![image-20191123171700433](https://tva1.sinaimg.cn/large/006y8mN6gy1g983dtlq2rj310o0u0n9q.jpg)

### dnspod

#### 安装cert-manager-webhook-dnspod

1、安装cert-manager-webhook-dnspod

下载源代码

```bash
git clone https://github.com/javachen/charts
```

进入目录，helm3安装：

```bash
cd cert-manager-webhook-dnspod

helm install cert-manager-webhook-dnspod -n cert-manager \
	--set groupName=acme.javachen.xyz \
	./deploy/example-webhook
```

> 注意：
>
> 1、必须设置 groupName 参数，其对应一个域名，必须是唯一的
>
> 2、javachen.xyz是我在腾讯云注册的域名

2、获取DNSPOD的id、token

参考 https://support.dnspod.cn/Kb/showarticle/tsid/227/ ，新建密钥页面：https://console.dnspod.cn/account/token#

3、创建一个secret存储token

```bash
#将获取的token填入
kubectl -n cert-manager create secret generic \
    dnspod-credentials --from-literal=api-token='6847f9a4cdba562f574fe55944f689e7'
```

4、创建service-account 

这一步主要是授权cert-manager-webhook-dnspod对dnspod-credentials的访问权限。

```bash
cat << EOF | kubectl create -f -    
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cert-manager-webhook-dnspod:secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["dnspod-credentials"]
  verbs: ["get", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: cert-manager-webhook-dnspod:secret-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cert-manager-webhook-dnspod:secret-reader
subjects:
  - apiGroup: ""
    kind: ServiceAccount
    name: cert-manager-webhook-dnspod 
    namespace: cert-manager
EOF
```

5、查看状态：

```bash
kubectl get all,secret -n cert-manager

helm list -n cert-manager
```

#### 创建签发机构

如果是测试，建议创建staging ClusterIssuer：

```bash
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: javachen-xyz-letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: junecloud@163.com
    privateKeySecretRef:
      name: javachen-xyz-letsencrypt-staging
    solvers:
    - selector:
        dnsNames:
        - '*.javachen.xyz'
      dns01:
        webhook:
          groupName: acme.javachen.xyz 
          solverName: dnspod
          config:
            apiID: 127880 
            apiTokenSecretRef:
              key: api-token
              name: dnspod-credentials
EOF
```

生产环境，创建 production ClusterIssuer: [production-issuer.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/production-issuer.yaml)

```bash
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: javachen-xyz-letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: huaiyu2006@163.com
    privateKeySecretRef:
      name: javachen-xyz-letsencrypt-prod
    solvers:
    - selector:
        dnsNames:
        - '*.javachen.xyz'
      dns01:
        webhook:
          groupName: acme.javachen.xyz 
          solverName: dnspod
          config:
            apiID: 127880 
            apiTokenSecretRef:
              key: api-token
              name: dnspod-credentials
EOF
```

查看状态

```bash
kubectl get ClusterIssuer,secret
kubectl describe ClusterIssuer javachen-xyz-letsencrypt-prod

kubectl describe secret javachen-xyz-letsencrypt-prod -n cert-manager
```

#### 测试手动创建证书

cert-manager 给我们提供了 Certificate 这个用于生成证书的自定义资源对象，它必须局限在某一个 namespace 下，证书最终会在这个 namespace 下以 Secret 的资源对象存储，创建一个 Certificate 对象。

```bash
cat << EOF | kubectl create -f -   
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: javachen-xyz-cert
spec:
  secretName: javachen-xyz-cert
  renewBefore: 240h
  dnsNames:
  - "*.javachen.xyz"
  issuerRef:
    name: javachen-xyz-letsencrypt-prod
    kind: ClusterIssuer
EOF
```

查看secret中tls.crt、tls.key是否有值

```bash
kubectl get secret,certificate
kubectl describe secret javachen-xyz-cert

kubectl describe certificate javachen-xyz-cert

kubectl describe CertificateRequest javachen-xyz-cert-1281933475

kubectl describe order javachen-xyz-cert-1281933475-906180984

kubectl describe Challenge javachen-xyz-cert-1281933475-906180984-4119232875
```

出现异常：

![image-20191204160615341](https://tva1.sinaimg.cn/large/006tNbRwly1g9kr57fpb3j31f40kcdkc.jpg)

> 解决方法：自动生成证书时，不支持泛域名，需要单独将域名加入到letsencrypt-prod的dnsNames中



先删除直接创建的ingress：

```bash
kubectl delete ing kuard
```

创建 prod 环境下的 ingress tls：

```yaml
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"    
spec:
  tls:
  - hosts:
    - kuard.javachen.xyz
    secretName: javachen-xyz-cert
  rules:
  - host: kuard.javachen.xyz
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
```

#### 测试自动创建证书

先删除直接创建的ingress：

```bash
kubectl delete ing kuard
```

创建 prod 环境下的 ingress tls

> 注意：kubernetes添加了一行 `certmanager.k8s.io/cluster-issuer: "javachen-xyz-letsencrypt-prod"`

```yaml
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"    
    cert-manager.io/cluster-issuer: "javachen-xyz-letsencrypt-prod" #添加，用于标注自动创建证书
spec:
  tls:
  - hosts:
    - kuard.javachen.xyz
    secretName: javachen-xyz-cert
  rules:
  - host: kuard.javachen.xyz
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
```

#### 访问浏览器

浏览器访问 https://kuard.javachen.xyz/ ，查看证书是否被信任。



#### 卸载

```bash
helm del cert-manager-webhook-dnspod -n cert-manager

kubectl delete ClusterRole,ClusterRoleBinding,RoleBinding cert-manager-webhook-dnspod:secret-reader cert-manager-webhook-dnspod:auth-delegator cert-manager-webhook-dnspod:domain-solver cert-manager-webhook-dnspod:webhook-authentication-reader -n kube-system

kubectl delete ServiceAccount,Service,Deployment cert-manager-webhook-dnspod -n cert-manager

kubectl delete Certificate,secret,Issuer -n cert-manager cert-manager-webhook-dnspod-ca cert-manager-webhook-dnspod-webhook-tls cert-manager-webhook-dnspod-selfsign

kubectl delete secret dnspod-credentials  -n cert-manager

kubectl delete ClusterIssuer,secret javachen-xyz-letsencrypt-prod javachen-xyz-letsencrypt-staging -n cert-manager
kubectl delete Certificate,secret javachen-xyz-cert 
```

### godaddy

#### 安装cert-manager-webhook-godaddy

1、安装cert-manager-webhook-godaddy

下载源代码

```bash
git clone https://github.com/inspectorioinc/cert-manager-webhook-godaddy.git
```

进入目录，使用helm3安装：

```bash
cd cert-manager-webhook-godaddy

helm install cert-manager-webhook-godaddy --namespace cert-manager \
	--set groupName=acme.javachen.space \
	./deploy/example-webhook
```

> 注意：必须设置 groupName 参数，其对应一个域名，必须是唯一的

2、获取godaddy的API key和secret

在 https://developer.godaddy.com/keys/ 页面创建一个API Key

3、查看状态：

```
kubectl get all,secret -n cert-manager
```

#### 创建签发机构

创建 production issuer: [production-issuer.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/production-issuer.yaml)

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
        - kuard.javachen.space 
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

查看状态

```bash
kubectl get ClusterIssuer,secret
kubectl describe ClusterIssuer javachen-space-letsencrypt-prod

kubectl describe secret javachen-space-letsencrypt-prod -n cert-manager
```

#### 测试手动创建证书

cert-manager 给我们提供了 Certificate 这个用于生成证书的自定义资源对象，它必须局限在某一个 namespace 下，证书最终会在这个 namespace 下以 Secret 的资源对象存储，创建一个 Certificate 对象。

```yaml
cat << EOF | kubectl create -f -   
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: javachen-space-cert
spec:
  secretName: javachen-space-cert
  renewBefore: 240h
  dnsNames:
  - "*.javachen.space"
  issuerRef:
    name: javachen-space-letsencrypt-prod
    kind: ClusterIssuer
EOF
```

查看secret中tls.crt、tls.key是否有值

```bash
kubectl get secret,certificate
kubectl describe secret javachen-space-cert

kubectl describe certificate javachen-space-cert

kubectl describe CertificateRequest javachen-space-cert-3747773282

kubectl describe order javachen-space-cert-3747773282-2036746768

kubectl describe Challenge javachen-space-cert-3747773282-2036746768-1798832172
```



先删除直接创建的ingress：

```bash
kubectl delete ing kuard
```

创建 prod 环境下的 ingress tls：

```yaml
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"    
spec:
  tls:
  - hosts:
    - kuard.javachen.space
    secretName: javachen-space-cert
  rules:
  - host: kuard.javachen.space
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
```

#### 访问浏览器

浏览器访问 https://kuard.javachen.space/ ，查看证书是否被信任。

![image-20191204160403540](https://tva1.sinaimg.cn/large/006tNbRwly1g9kr2znnkuj31cg0p4k7m.jpg)

#### 卸载

```bash
helm del cert-manager-webhook-godaddy -n cert-manager

kubectl delete ClusterRole,ClusterRoleBinding,RoleBinding cert-manager-webhook-godaddy:secret-reader cert-manager-webhook-godaddy:auth-delegator cert-manager-webhook-godaddy:domain-solver cert-manager-webhook-godaddy:webhook-authentication-reader -n kube-system

kubectl delete ServiceAccount,Service,Deployment cert-manager-webhook-godaddy -n cert-manager

kubectl delete Certificate,secret,Issuer -n cert-manager cert-manager-webhook-godaddy-ca cert-manager-webhook-godaddy-webhook-tls cert-manager-webhook-godaddy-selfsign

kubectl delete ClusterIssuer,secret javachen-space-letsencrypt-prod -n cert-manager
kubectl delete Certificate,secret javachen-space-cert
```

# 总结

本文主要是基于Cert Manager v0.12.0版本对Ingress创建Let’s Encrypt免费证书，请注意修改 API：API从 `certmanager.k8s.io/v1alpha1` 改为 `cert-manager.io/v1alpha2`。

# 参考文章

- [使用 LetsEncrypt配置kubernetes ingress-nginx免费HTTPS证书]([http://idcsec.com/2019/07/11/%E4%BD%BF%E7%94%A8-letsencrypt%E9%85%8D%E7%BD%AEkubernetes-ingress-nginx%E5%85%8D%E8%B4%B9https%E8%AF%81%E4%B9%A6/](http://idcsec.com/2019/07/11/使用-letsencrypt配置kubernetes-ingress-nginx免费https证书/))
-  [cert-manager管理k8s集群证书](https://www.cnblogs.com/blackmood/p/11425366.html)
-  [ACME-DNS](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/acme-dns.html)
- https://blog.csdn.net/xichenguan/article/details/100709830
- [阿里云DNS配置Cert Manager Webhook]([https://github.com/findsec-cn/k201/tree/master/4.Kubernetes%E5%AE%B9%E5%99%A8%E7%BD%91%E7%BB%9C/config/cert-manager](https://github.com/findsec-cn/k201/tree/master/4.Kubernetes容器网络/config/cert-manager))

