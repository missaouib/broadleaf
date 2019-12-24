---
layout: post
title: 安装Cert Manager
date: 2019-11-02T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes]
---

本文主要记录kubernetes中安装Cert-Manager组件的过程。

本文使用Cert Manager最新版本0.12.0，该版本相对于之前的版本，做了一些改动，例如：API从 certmanager.k8s.io/v1alpha1 改为 cert-manager.io/v1alpha2。

官方文档：https://cert-manager.io/

# 安装 Cert Manager

## 使用kubectl安装

创建命名空间：

```bash
kubectl create namespace cert-manager
```

安装：

```bash
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml
```

## 使用helm安装

使用helm3安装0.12版本：

```bash
# Install the CustomResourceDefinition resources separately.
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml

# Create the namespace for cert-manager
kubectl create namespace cert-manager

kubectl label namespace cert-manager cert-manager.io/disable-validation=true

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install cert-manager \
  --namespace cert-manager \
  --version v0.12.0 \
  jetstack/cert-manager
```

更多详细的配置参数可以参考：https://github.com/jetstack/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml

例如：可以配置一个缺省的 [cluster issuer](http://docs.cert-manager.io/en/latest/reference/clusterissuers.html)，当部署Cert manager的时候，用于支持Ingress中 `kubernetes.io/tls-acme: "true"` annotation来自动化TLS：

```bash
helm install cert-manager \
  --namespace cert-manager \
  --version v0.12.0 \
  --set ingressShim.defaultIssuerName=letsencrypt-prod \
	--set ingressShim.defaultIssuerKind=ClusterIssuer \
  jetstack/cert-manager
```

关于Ingress-shim，参考 https://docs.cert-manager.io/en/latest/reference/ingress-shim.html



还可以设置下面参数，用于设置certificate删除时自动删除secret：

```bash
extraArgs:
  - --enable-certificate-owner-ref=true
```



## 查看状态

```bash
$ kubectl -n cert-manager rollout status deploy/cert-manager
deployment "cert-manager" successfully rolled out

$ kubectl get pods,secret -n cert-manager
NAME                                           READY   STATUS              RESTARTS   AGE
pod/cert-manager-5c47f46f57-k78l6              1/1     Running             0          91s
pod/cert-manager-cainjector-6659d6844d-tr8rf   1/1     Running             0          91s
pod/cert-manager-webhook-547567b88f-8lthd      1/1     Running   					 0          91s

NAME                                         TYPE                                  DATA   AGE
secret/cert-manager-cainjector-token-jqmfc   kubernetes.io/service-account-token   3      94s
secret/cert-manager-token-bj7qg              kubernetes.io/service-account-token   3      94s
secret/cert-manager-webhook-ca               kubernetes.io/tls                     3      5s
secret/cert-manager-webhook-tls              kubernetes.io/tls                     3      5s
secret/cert-manager-webhook-token-nvtrp      kubernetes.io/service-account-token   3      94s
secret/default-token-6g2lx                   kubernetes.io/service-account-token   3      103s
```

等待pods状态都变为Running

使用helm3查看：

```bash
$ helm list -n cert-manager
NAME        	NAMESPACE   	REVISION	UPDATED                                	STATUS  	CHART               	APP VERSION
cert-manager	cert-manager	1       	2019-12-09 15:55:03.245917473 +0800 CST	deployed	cert-manager-v0.12.0	v0.12.0
```



# 验证证书

## 验证自签名的CA证书

### 创建自签名的Issuer

```bash
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-test
  
---
# Create a selfsigned Issuer
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: selfsigning-issuer
  namespace: cert-manager-test
spec:
  selfSigned: {}
EOF
```

### 创建CA

创建自签名的CA

```yaml
cat << EOF | kubectl create -f -
# Generate a CA Certificate 
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: ca-cert
  namespace: cert-manager-test
spec:
  commonName: acme.javachen.space
  secretName: ca-cert-tls
  duration: 43800h # 5y
  issuerRef:
    name: selfsigning-issuer
  isCA: true 
---
# Create an Issuer that uses the above generated CA certificate to issue certs
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: ca-issuer
  namespace: cert-manager-test
spec:
  ca:
    secretName: ca-cert-tls
EOF
```

当然，也可以这样创建CA签发机构：

```yaml
# Generate a CA private key
openssl genrsa -out tls.key 2048
openssl req -x509 -new -nodes -key tls.key -subj "/CN=kuard.javachen.space" -days 3650 -reqexts v3_req -extensions v3_ca -out tls.crt

kubectl create secret tls ca-key-pair \
   --cert=tls.crt \
   --key=tls.key 
   
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: ca-issuer
  namespace: cert-manager-test
spec:
  ca:
    secretName: ca-key-pair 
EOF
```

或者使用权威机构生成tls.crt、tls.key。

查看状态：

```bash
kubectl get issuers ca-issuer -n cert-manager-test -o wide
```

### 为域名创建证书

为*.javachen.space创建泛域名证书：

```yaml
cat << EOF | kubectl create -f -
# Finally, generate a serving certificate for *.javachen.space
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: javachen-cert
  namespace: cert-manager-test
spec:
  commonName: acme.javachen.space
  secretName: javachen-cert-tls
  duration: 43800h # 5y
  issuerRef:
    name: ca-issuer
    kind: Issuer
  organization:
  - CA
  dnsNames:
  - "*.javachen.space"
EOF
```

查看状态 

```bash
kubectl get Certificate,ing,Issuer,secret -n cert-manager-test
kubectl describe Certificate

#检查 ca.crt、tls.crt、tls.key是否有值
$ kubectl get secret javachen-cert-tls -o yaml
```

可以看到状态都是True的，如果状态不正常，可以查看状态。

我们来查看test-cert-ca证书生成证书的过程：

```bash
kubectl describe certificate test-cert-ca -n cert-manager-test
kubectl describe CertificateRequest test-cert-ca-1862708136 -n cert-manager-test
```

### 通过Ingress测试

```yaml
cat << EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard
  namespace: cert-manager-test
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
      - image: tomcat 
        imagePullPolicy: Always
        name: kuard
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: kuard
  namespace: cert-manager-test
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: kuard
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  namespace: cert-manager-test
  annotations:
    kubernetes.io/ingress.class: "nginx"    
spec:
  tls:
  - hosts:
    - kuard.javachen.space
    secretName: javachen-cert-tls
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

访问浏览器，可以看到证书不被chrome浏览器信任。在系统里，手动设置信任证书，然后可以看到证书签发者是cert-manager，常用名词是 acme.javachen.space，过期时间是5年。

## 验证letsencrypt的HTTP01校验生成证书

### 创建ClusterIssuer

我们需要先创建一个签发机构，cert-manager 给我们提供了 Issuer 和 ClusterIssuer 这两种用于创建签发机构的自定义资源对象，Issuer 只能用来签发自己所在 namespace 下的证书，ClusterIssuer 可以签发任意 namespace 下的证书，这里以 ClusterIssuer 为例创建一个签发机构：

```yaml
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: junecloud@163.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - selector: {}
      http01:
        ingress:
          class: nginx
EOF
```

说明：

- metadata.name 是我们创建的签发机构的名称，后面我们创建证书的时候会引用它
- spec.acme.email 是你自己的邮箱，证书快过期的时候会有邮件提醒，不过 cert-manager 会利用 acme 协议自动给我们重新颁发证书来续期
- spec.acme.server 是 acme 协议的服务端，我们这里用 Let’s Encrypt，这个地址就写死成这样就行
- spec.acme.privateKeySecretRef 指示此签发机构的私钥将要存储到哪个 Secret 对象中，名称不重要
- spec.acme.solvers下面的http01 这里指示签发机构使用 HTTP-01 的方式进行 acme 协议 (还可以用 DNS 方式，acme 协议的目的是证明这台机器和域名都是属于你的，然后才准许给你颁发证书)

查看状态：

```bash
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod
```

### 使用Ingress自动创建证书

```bash
cat << EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard
  namespace: cert-manager-test
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
      - image: tomcat 
        imagePullPolicy: Always
        name: kuard
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: kuard
  namespace: cert-manager-test
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: kuard
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  namespace: cert-manager-test
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - kuard.javachen.space
    secretName: javachen-cert-tls
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

**注意：**

1、前面创建的是ClusterIssuer，所以这里annotations添加的是：cert-manager.io/cluster-issuer: "letsencrypt-prod"

2、这里使用的是HTTP01验证，则必须保证kuard.javachen.space能够被DNS解析，所以需要在域名提供商配置一条A记录，指向一个外网IP地址。

```bash
curl -kivL -H 'Host: kuard.javachen.space' 'http://X.X.X.X'
```



查看证书：

```bash
kubectl get certificate -n cert-manager-test

kubectl describe CertificateRequest javachen-cert-tls -n cert-manager-test
kubectl describe Order javachen-cert-tls-2608726807-1509158854 -n cert-manager-test
kubectl describe Challenge javachen-cert-tls-2608726807-1509158854-114790480 -n cert-manager-test
```



## 验证letsencrypt的DNS01校验生成证书

参考 [使用Cert Manager配置Let’s Encrypt证书](/2019/11/04/using-cert-manager-with-nginx-ingress/)

# 卸载

```bash
#删除测试用的
kubectl delete all,Certificate,Issuer,secret --all -n cert-manager-test
kubectl delete ClusterIssuer letsencrypt-prod
kubectl delete ns cert-manager-test

#通过kubectl删除
kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml

#通过helm3删除
helm del cert-manager -n cert-manager
```

