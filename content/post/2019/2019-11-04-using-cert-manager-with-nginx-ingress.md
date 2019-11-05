---
layout: post
title: 使用Cert Manager配置Let’s Encrypt证书
date: 2019-11-04T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,ingress,SSL]
---

在 Kubernetes 集群中，可以使用Cert-Manager创建 HTTPS 证书并自动续期，支持 Let’s Encrypt、CA、HashiCorp Vault 这些免费证书的签发。

本文主要记录一下使用Cert-Manager创建Let’s Encrypt和CA类型证书的过程。

本文参考：https://docs.cert-manager.io/en/latest/tutorials/acme/quick-start/index.html# ，做了一些精简和改动。

# 安装 Cert Manager

## 使用kubectl安装

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.11.0/cert-manager.yaml
```

## 使用helm安装

```bash
# Install the CustomResourceDefinition resources separately
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml

# Create the namespace for cert-manager
kubectl create namespace cert-manager

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install \
  --name cert-manager \
  --namespace cert-manager \
  --version v0.11.0 \
  jetstack/cert-manager
```

## 查看状态

```bash
kubectl get pods --namespace cert-manager
```

## 验证证书

```bash
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-test
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: test-selfsigned
  namespace: cert-manager-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: selfsigned-cert
  namespace: cert-manager-test
spec:
  commonName: example.com
  secretName: selfsigned-cert-tls
  issuerRef:
    name: test-selfsigned
EOF
```

查看状态：

```bash
kubectl get certificate  -n cert-manager-test
kubectl describe certificate -n cert-manager-test
```

## 卸载

```bash
kubectl delete Certificate,Issuer --all -n cert-manager-test
kubectl delete ns cert-manager-test
```



# 部署NGINX Ingress Controller

如果没有安装Ingress Controller，则安装nginx-ingress：

```bash
helm repo add stable https://apphub.aliyuncs.com

helm repo update

helm install quickstart stable/nginx-ingress
```

查看状态：

```bash
$ kubectl get svc
NAME                                       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
kubernetes                                 ClusterIP      10.43.0.1      <none>        443/TCP                      29h
quickstart-nginx-ingress-controller        LoadBalancer   10.43.233.6    <pending>     80:32174/TCP,443:30023/TCP   25s
quickstart-nginx-ingress-default-backend   ClusterIP      10.43.14.206   <none>        80/TCP                       25s
```

可以看到 quickstart-nginx-ingress-controller 是pending状态



# 部署一个服务

参考 [deployment.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/deployment.yaml) 我做了一点修改，把镜像改成了tomcat：

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
  - host: kuard.javachen.com  #修改域名
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
kuard   kuard.javachen.com   192.168.56.111   80      91s
```

#DNS解析

因为是测试环境，所以没有域名配置不了dns，这里配置本地的hosts文件，添加映射。

```bash
192.168.56.111 kuard.javachen.com
```

测试浏览器：http://kuard.javachen.com/ ，可以看到tomcat主页。

# 配置 Let’s Encrypt 类型的Issuer

我们需要先创建一个签发机构，cert-manager 给我们提供了 Issuer 和 ClusterIssuer 这两种用于创建签发机构的自定义资源对象，Issuer 只能用来签发自己所在 namespace 下的证书，ClusterIssuer 可以签发任意 namespace 下的证书，这里以 Issuer 为例创建一个签发机构。



更新cert-manager你需要配置一个缺缺省的 [cluster issuer](http://docs.cert-manager.io/en/latest/reference/clusterissuers.html)，当部署Cert manager的时候，用于支持 `kubernetes.io/tls-acme: "true"`annotation来自动化TLS。如果你是用helm安装的cert-manager，则只需下面命令进行更新：

```bash
helm upgrade cert-manager jetstack/cert-manager     \
	--namespace cert-manager \
	--set ingressShim.defaultIssuerName=letsencrypt-prod \
	--set ingressShim.defaultIssuerKind=ClusterIssuer
```

目前cert-manager支持ACME跟CA方式，而ACME又分DNS/HTTP两种。下面给予ACME的方式创建issuer。

## 创建 staging issuer

创建 staging issuer: [staging-issuer.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/staging-issuer.yaml) ，修改 email：

```yaml
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
 name: letsencrypt-staging
spec:
 acme:
   # The ACME server URL
   server: https://acme-staging-v02.api.letsencrypt.org/directory
   # Email address used for ACME registration
   email: junecloud@163.com
   # Name of a secret used to store the ACME account private key
   privateKeySecretRef:
     name: letsencrypt-staging
   # Enable the HTTP-01 challenge provider
   solvers:
   - http01:
       ingress:
         class:  nginx
EOF
```

说明：

- metadata.name 是我们创建的签发机构的名称，后面我们创建证书的时候会引用它
- spec.acme.email 是你自己的邮箱，证书快过期的时候会有邮件提醒，不过 cert-manager 会利用 acme 协议自动给我们重新颁发证书来续期
- spec.acme.server 是 acme 协议的服务端，我们这里用 Let’s Encrypt，这个地址就写死成这样就行
- spec.acme.privateKeySecretRef 指示此签发机构的私钥将要存储到哪个 Secret 对象中，名称不重要
- spec.acme.http01 这里指示签发机构使用 HTTP-01 的方式进行 acme 协议 (还可以用 DNS 方式，acme 协议的目的是证明这台机器和域名都是属于你的，然后才准许给你颁发证书)

也可以：

```bash
kubectl create --edit -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/staging-issuer.yaml
```

## 创建 production issuer

创建 production issuer: [production-issuer.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/production-issuer.yaml)

```yaml
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
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
   - http01:
       ingress:
         class: nginx
EOF
```

或者：

```bash
kubectl create --edit -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/production-issuer.yaml
```

查看：

```bash
kubectl describe issuer letsencrypt-staging

kubectl describe issuer letsencrypt-prod


kubectl delete issuer letsencrypt-staging
kubectl delete issuer letsencrypt-prod
```

## 测试 staging ingress自动创建证书

先删除直接创建的ingress：

```bash
kubectl delete ing kuard
```

创建 staging 环境下的 ingress tls: [ingress-tls.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/ingress-tls.yaml)

```yaml
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"    
    cert-manager.io/issuer: "letsencrypt-staging"

spec:
  tls:
  - hosts:
    - kuard.javachen.com
    secretName: quickstart-example-tls
  rules:
  - host: kuard.javachen.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
```

或者：

```
kubectl create --edit -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/ingress-tls.yaml
```

上面的yaml文件配置了 `cert-manager.io/issuer: "letsencrypt-staging"`，cert-manager会自动帮我们生成证书。

查看有没有自动生成证书以及状态：

```bash
$ kubectl get certificate
NAME                     READY   SECRET                   AGE
quickstart-example-tls   False   quickstart-example-tls   7s
```

查看有没有自动生成secret：

```
kubectl describe secret quickstart-example-tls 
kubectl get secret quickstart-example-tls -o yaml
```

查看详细信息：

```bash
kubectl describe certificate quickstart-example-tls

kubectl get certificate quickstart-example-tls -o yaml

kubectl describe CertificateRequest quickstart-example-tls-124376946

kubectl describe order quickstart-example-tls-124376946-2542034024

kubectl describe Challenge quickstart-example-tls-124376946-2542034024-1658523635
```

执行`kubectl describe Challenge quickstart-example-tls-1258807166-37929056-2838376740`可以看到错误日志：

![image-20191105002321990](/Users/chenzj/Library/Application Support/typora-user-images/image-20191105002321990.png)

- 从日志可以看到，这里是使用的http-01进行校验证书。

原因在于域名无法dns解析，所以需要申请一个域名。换成一个可以dns解析的域名，比如 kuard.javachen.com 重新进行上面的操作。

换个域名试试，可以看到下面日志，从日志可以看到是因为http-01验证失败。

![image-20191105094905630](https://tva1.sinaimg.cn/large/006y8mN6ly1g8mxa18xl8j31aa0i6tbp.jpg)

访问上面的链接：https://acme-v02.api.letsencrypt.org/acme/chall-v3/1090081106/pyCOIw ，可以看到：

![image-20191105095210344](https://tva1.sinaimg.cn/large/006y8mN6ly1g8mxd8bnskj30zi0ewacj.jpg)

说明：域名没有配置一个外网IP，那就可以域名配置一个外网IP。

![image-20191105101536495](https://tva1.sinaimg.cn/large/006y8mN6ly1g8my1mfehbj31060eojtz.jpg)

上面的日志，说明需要在域名下面加一个txt记录。



最后，浏览器访问 https://kuard.javachen.com ，可以发现ssl证书还是不够信任，这是因为我们使用的是staging环境的证书，现在可以切换到生产环境的证书。

## 测试 prod ingress自动创建证书

先删除上面创建的ingress：

```bash
kubectl delete ing kuard
```

创建生产环境下的 ingress tls final: [ingress-tls-final.yaml](https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/ingress-tls-final.yaml)

```yaml
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"    
    cert-manager.io/issuer: "letsencrypt-prod"

spec:
  tls:
  - hosts:
    - kuard.javachen.com
    secretName: quickstart-example-tls
  rules:
  - host: kuard.javachen.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
```

```bash
kubectl create --edit -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/docs/tutorials/acme/quick-start/example/ingress-tls-final.yaml

kubectl describe certificate

kubectl describe CertificateRequest quickstart-example-tls-2994180344

kubectl describe order quickstart-example-tls-2994180344-320677042

kubectl describe challenge quickstart-example-tls-2994180344-320677042-1611678472
```

查看日志，检查一下http-01校验是否通过。

## 手动创建 Certificate

cert-manager 给我们提供了 Certificate 这个用于生成证书的自定义资源对象，它必须局限在某一个 namespace 下，证书最终会在这个 namespace 下以 Secret 的资源对象存储，创建一个 Certificate 对象：

```yaml
# cat cert.yaml 
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: quickstart-example-tls
spec:
  secretName: quickstart-example-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - kuard.javachen.com
  acme:
    config:
    - http01:
        ingress:
          class: nginx
      domains:
      - kuard.javachen.com
```

说明：

- spec.secretName 指示证书最终存到哪个 Secret 中
- spec.issuerRef.kind 值为 ClusterIssuer 说明签发机构不在本 namespace 下，而是在全局
- spec.issuerRef.name 我们创建的签发机构的名称 (ClusterIssuer.metadata.name)
- spec.dnsNames 指示该证书的可以用于哪些域名
- spec.acme.config.http01.ingress.class 使用 HTTP-01 方式校验该域名和机器时，cert-manager 会尝试创建Ingress 对象来实现该校验，如果指定该值，会给创建的 Ingress 加上 kubernetes.io/ingress.class 这个 annotation，如果我们的 Ingress Controller 是 traefik Ingress Controller，指定这个字段可以让创建的 Ingress 被 traefik Ingress Controller 处理。
- spec.acme.config.http01.domains 指示该证书的可以用于哪些域名

然后，需要在ingress里面去掉：

```
cert-manager.io/issuer: "letsencrypt-prod"
```



## 卸载

```bash
kubectl delete pod,svc,deploy,ing,secret,replicaset --all
```



# 配置CA类型的Issuer

前面配置了ACME类型的Issuer，接下来创建CA类型的Issuer。

## 生成CA签名密钥对

```bash
# Generate a CA private key
openssl genrsa -out tls.key 2048

openssl req -x509 -new -nodes -key tls.key -subj "/CN=kuard.javachen.com" -days 3650 -reqexts v3_req -extensions v3_ca -out tls.crt
```

## 将CA签名密钥对保存为Secret

> 注意：文件名称一定要是tls.crt、tls.key

```
kubectl create secret tls ca-key-pair \
   --cert=tls.crt \
   --key=tls.key 
```

## 创建一个签发机构

```yaml
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: ca-key-pair
EOF
```

## 测试Ingress自动创建证书

先删除上面创建的ingress：

```bash
kubectl delete ing kuard
```

再创建ingress，cert-manager会自动创建证书

```bash
cat << EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"  
    cert-manager.io/issuer: "ca-issuer"  #区别

spec:
  tls:
  - hosts:
    - kuard.javachen.com
    secretName: example-com-tls
  rules:
  - host: kuard.javachen.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
```

查看：

```bash
kubectl get Certificate,ing,Issuer,secret 

kubectl describe Certificate


#检查 ca.crt、tls.crt、tls.key是否有值
$ kubectl get secret example-com-tls -o yaml
apiVersion: v1
data:
  ca.crt: <.....>
  tls.crt: <.....>
  tls.key: <.....>
kind: Secret
metadata:
  annotations:
    cert-manager.io/alt-names: kuard.javachen.com
    cert-manager.io/certificate-name: example-com-tls
    cert-manager.io/common-name: ""
    cert-manager.io/ip-sans: ""
    cert-manager.io/issuer-kind: Issuer
    cert-manager.io/issuer-name: ca-issuer
    cert-manager.io/uri-sans: ""
  creationTimestamp: "2019-11-05T07:58:48Z"
  name: example-com-tls
  namespace: default
  resourceVersion: "244116"
  selfLink: /api/v1/namespaces/default/secrets/example-com-tls
  uid: 66e5ba7a-0b58-4a89-a2d7-ed86d4cc7cc8
type: kubernetes.io/tls
```

访问浏览器，可以看到证书不被chrome浏览器信任。在系统里，手动设置信任证书，然后可以看到证书签发者是cert-manager：

![image-20191105160948532](https://tva1.sinaimg.cn/large/006y8mN6ly1g8n8a7pmu4j314u0mwds8.jpg)



> 注意：example-com-tls是由cert-manager自动创建的，如果你手动删掉，cert-manager由会创建一个。

## 手动创建Certificate

```yaml
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: example-com
spec:
  secretName: example-com-tls
  issuerRef:
    name: ca-issuer
    kind: Issuer
  commonName: kuard.javachen.com
  organization:
  - CA
  dnsNames:
  - kuard.javachen.com
EOF
```

然后，需要在ingress里面去掉：

```
cert-manager.io/issuer: "ca-issuer"
```

## 卸载

``` 
kubectl delete Issuer ca-issuer
kubectl delete secret example-com-tls ca-key-pair
kubectl delete Certificate example-com
```



# 参考文章

- [使用 LetsEncrypt配置kubernetes ingress-nginx免费HTTPS证书]([http://idcsec.com/2019/07/11/%E4%BD%BF%E7%94%A8-letsencrypt%E9%85%8D%E7%BD%AEkubernetes-ingress-nginx%E5%85%8D%E8%B4%B9https%E8%AF%81%E4%B9%A6/](http://idcsec.com/2019/07/11/使用-letsencrypt配置kubernetes-ingress-nginx免费https证书/))
-  [cert-manager管理k8s集群证书](https://www.cnblogs.com/blackmood/p/11425366.html)