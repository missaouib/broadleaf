---
layout: post
title: 使用Helm3安装Rancher HA集群
date: 2019-11-03T23:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,helm,rancher]
---



本文主要记录是由Helm来安装Rancher的过程。Rancher是一个企业级多集群Kubernetes管理平台；用户可以在Rancher上配置和管理公有云(如GKE、EKS、AKS、阿里云、华为云等)上托管的Kubernetes服务，亦可向Rancher中导入已有集群。



> 注意：
>
> Rancher HA安装属于高级安装，部署前先了解以下基本技能：
>
> 1. 了解域名与DNS解析基本概念
> 2. 了解http七层代理和tcp四层代理基本概念
> 3. 了解反向代理的基本原理
> 4. 了解SSL证书与域名的关系
> 5. 了解Helm的安装使用
> 6. 了解kubectl的使用
> 7. 熟悉Linux基本操作命令
> 8. 熟悉Docker基本操作命令

# 集群规划

k8s集群各个组件版本：

| 软件       | 版本                          | 说明           |
| ---------- | ----------------------------- | -------------- |
| OS         | CentOS Linux release 7.7.1908 | linux内核为4.4 |
| RKE        | v0.3.2                        |                |
| Docker     | v19.03.4                      |                |
| Kubernetes | v1.16.2                       |                |
| Helm       | 3                             |                |
| Ceph       | v14.2.4                       |                |

集群规划：

| 主机            | IP             | 角色                    | 说明        |
| --------------- | -------------- | ----------------------- | ----------- |
| k8s-rke-node001 | 192.168.56.111 | rke、controlplane、etcd | rke安装节点 |
| k8s-rke-node002 | 192.168.56.112 | etcd、worker            |             |
| k8s-rke-node003 | 192.168.56.113 | etcd、worker            |             |

- 安装用户：chenzj，注意不是root用户，但具有sudo权限
- 端口需求：https://www.rancher.cn/docs/rancher/v2.x/cn/install-prepare/requirements
- **以下所有命令在 k8s-rke-node001节点操作。**

参考文章：https://www.rancher.cn/docs/rancher/v2.x/cn/installation/ha-install/rke-ha-install/tcp-l4/

# 添加Chart仓库地址

chart对应的源码地址：https://github.com/rancher/rancher/tree/master/chart

添加仓库：

```
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
```

检查rancher chart仓库可用

```
helm search rancher
```

# SSL证书配置

Rancher Server设计默认需要开启SSL/TLS配置来保证安全，将ssl证书以Kubernetes Secret卷的形式传递给Rancher Server或Ingress Controller。首先创建证书密文，以便Rancher和Ingress Controller可以使用。

根据ingress.tls.source的值，默认有三种方式：

| 配置                                                         | CHART参数     | 描述                                                    | 是否需要CERT-MANAGER |
| ------------------------------------------------------------ | ------------- | ------------------------------------------------------- | -------------------- |
| [Rancher Generated Certificates](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/#rancher-generated-certificates) | `rancher`     | 默认值，使用Rancher自签名的证书                         | 是                   |
| [Let’s Encrypt](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/#let-s-encrypt) | `letsEncrypt` | 使用 [Let’s Encrypt](https://letsencrypt.org/) 签名证书 | 是                   |
| [Certificates from Files](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/#certificates-from-files) | `secret`      | 私有自己签名的证书                                      | 否                   |

## 安装cert-manager

当ingress.tls.source值为rancher或者letsEncrypt时，需要安装cert-manager

### 使用kubectl安装

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.11.0/cert-manager.yaml
```

### 使用helm安装

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

### 查看状态

```bash
kubectl get pods --namespace cert-manager
```

## 使用Rancher生成证书

```bash
helm install rancher-stable/rancher \
  --name rancher \
  --version v2.3.2  \
  --namespace cattle-system \
  --set hostname=rancher.javachen.com
```

默认，tls=ingress，当ingress.tls.source=rancher，就会创建一个CA类型的Issuer，一个Secret tls-rancher。

## Let’s Encrypt生成证书

```bash
helm install rancher-stable/rancher \
  --name rancher \
  --version v2.3.2  \
  --namespace cattle-system \
  --set hostname=rancher.javachen.com\
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=junecloud@163.com
```

默认，tls=ingress，当ingress.tls.source=letsEncrypt，就会创建一个ACME类型的Issuer，并且采用http-01校验。

## 从文件生成证书

### 使用权威证书安装

1、获取权威证书：

- 购买付费的
- 在云服务商创建的免费的证书，数量有限，不支持泛域名
- 使用 Let’s Encrypt 创建证书，可以使用 [acme.sh 脚本](https://github.com/Neilpang/acme.sh/wiki/dns-manual-mode) 。

得到证书之后，将服务证书和 CA 中间证书链合并到 tls.crt，将私钥复制到或者重命名为 tls.key；在证书所在目录执行下面命令，以acme.sh生成的证书为例：

```bash
cd ~/.acme.sh/javachen.com

#将服务证书和 CA 中间证书链合并到 tls.crt
cp fullchain.cer tls.crt

#将私钥复制到或者重命名为 tls.key
cp javachen.com.key tls.key

#验证证书 
openssl verify -CAfile ca.cer tls.crt  

openssl x509 -in  wesine.com.cn.cer -noout -text
openssl x509 -in  ca.cer -noout -text
#不加CA证书验证
openssl s_client -connect rancher.test.wesine.com.cn:443 -servername rancher.test.wesine.com.cn

#加CA证书验证
openssl s_client -connect rancher.test.wesine.com.cn:443 -servername rancher.test.wesine.com.cn -CAfile fullchain.cer
```

2、使用`kubectl`创建`tls`类型的`secrets`；

>注意：证书、私钥名称必须是tls.crt、tls.key。

```bash
kubectl create namespace cattle-system

kubectl -n cattle-system create \
    secret tls tls-rancher-ingress \
    --cert=./tls.crt \
    --key=./tls.key
```

3、安装rancher

创建证书对应的域名需要与hostname选项匹配，否则ingress将无法代理访问Rancher

```bash
helm install rancher-stable/rancher \
  --name rancher \
  --version v2.3.2  \
  --namespace cattle-system \
  --set hostname=rancher.javachen.com\
  --set ingress.tls.source=secret 
```

### 使用自签名证书安装

1、如果没有自签名ssl证书，可以参考 https://www.yuque.com/javachen/micoservice/mtfme4，一键生成ssl证书；


2、一键生成ssl自签名证书脚本将自动生成tls.crt、tls.key、cacerts.pem三个文件，文件名称不能修改。如果使用您自己生成的自签名ssl证书，则需要将服务证书和CA中间证书链合并到tls.crt文件中,将私钥复制到或者重命名为tls.key文件，将CA证书复制到或者重命名为cacerts.pem。

```bash
cp server.pem tls.crt
cp server-key.pem tls.key
cp ca.pem cacerts.pem
```

3、使用kubectl在命名空间cattle-system中创建tls-ca和tls-rancher-ingress两个secret

```bash
# 创建命名空间
kubectl  create namespace cattle-system
# 服务证书和私钥密文
kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=./tls.crt --key=./tls.key
# ca证书密文
kubectl -n cattle-system create secret generic tls-ca --from-file=cacerts.pem
```

4、安装rancher

创建证书对应的域名需要与hostname选项匹配，否则ingress将无法代理访问Rancher

```bash
helm install rancher-stable/rancher \
  --name rancher \
  --version v2.3.2  \
  --namespace cattle-system \
  --set hostname=rancher.javachen.com\
  --set ingress.tls.source=secret \
  --set privateCA=true 
```

- ingress.tls.source 默认值为rancher，还可以为secret 、`letsEncrypt`

- privateCA=true 设置使用私有证书 

# Rancher HA安装部署

## 四层代理与七层代理的区别

| OSI中的层  | 功能                                     | TCP/IP协议族                                                 |
| ---------- | ---------------------------------------- | ------------------------------------------------------------ |
| 应用层     | 文件传输，电子邮件，文件服务，虚拟终端   | 例如：TFTP、HTTP、HTTPS、SNMP、FTP、SMTP、DNS、RIP、Telnet、SIP、SSH、NFS、RTSP、XMPP、Whois、ENRP |
| 表示层     | 数据格式化，代码转换，数据加密           | 例如：ASCII、ASN.1、JPEG、MPEG                               |
| 会话层     | 解除或建立与别的接点的联系               | 例如：ASAP、TLS、SSH、ISO 8327 / CCITT X.225、RPC、NetBIOS、ASP、Winsock、BSD sockets |
| 传输层     | 位**数据段**提供端对端的接口             | 例如：TCP，UDP，SPX                                          |
| 网络层     | 为**数据包**选择路由，拥塞控制、网际互连 | 例如：IP，ICMP，OSPF，BGP，IGMP，ARP，RARP，IPX、RIP、OSPF   |
| 数据链路层 | 传输有地址的**帧**以及错误检测功能       | 例如：SLIP，CSLIP，PPP，MTU，ARP，RARP，SDLC、HDLC、PPP、STP、帧中继 |
| 物理层     | 以**二进制**数据形式在物理媒体上传输数据 | 例如：ISO2110，IEEE802，IEEE802.2，EIA/TIA RS-232、EIA/TIA RS-449、V.35、RJ-45 |

如图，平时我们说的4层和7层其实就是OSI网络模型中的第四层和第七层。4层代理中主要是TCP协议代理，TCP代理主要基于IP+端口来通信。7层代理中主要是http协议, http协议主要基于URL来通信。

## 安装Nginx

这里选择在master节点上安装nginx。

添加nginx源 /etc/yum.repos.d/nginx.repo

```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
```

安装nginx

```
sudo yum install nginx-mod-stream.x86_64 nginx.x86_64 -y
```

## 四层负载均衡部署

![image.png](https://tva1.sinaimg.cn/large/006y8mN6ly1g8ls3rnky4j30yc0elwgf.jpg)

我们将使用NGINX作为第4层负载均衡器(TCP)，NGINX会将所有连接转发到您的Rancher节点之一。

本方案中，所有的流量都通过外部负载均衡转发到后端ingress服务上。因为外部负载均衡为四层TCP模式，无法设置域名转发，所以需要把域名转发的功能设置在后端的ingress服务上，让ingress作为ssl终止后，ingress到后端的Rancher Server将采用非加密的http模式。此方案中，Rancher Server无法与外部直接通信，需通过ingress代理进入。因为ingress采用了ssl加密，所以此部署架构的安全性相对较高，但多次转发也将会导致网络性能减弱。

### 配置Nginx

1、选一台不是集群的机器，安装nginx

2、创建配置文件/etc/nginx/nginx.conf

```
user  nginx;
worker_processes 4;
worker_rlimit_nofile 40000;

events {
    worker_connections 8192;
}

stream {
    upstream rancher_servers_http {
        least_conn;
        server 192.168.56.111:80 max_fails=3 fail_timeout=5s;
        server 192.168.56.121:80 max_fails=3 fail_timeout=5s;
        server 192.168.56.113:80 max_fails=3 fail_timeout=5s;
    }
    server {
        listen     80;
        proxy_pass rancher_servers_http;
    }

    upstream rancher_servers_https {
        least_conn;
				server 192.168.56.111:443 max_fails=3 fail_timeout=5s;
        server 192.168.56.112:443 max_fails=3 fail_timeout=5s;
        server 192.168.56.113:443 max_fails=3 fail_timeout=5s;
    }
    server {
        listen     443;
        proxy_pass rancher_servers_https;
    }
}
```

3、重新加载nginx

```
nginx -s reload
```

4、将域名解析到nginx机器IP，然后浏览器访问 https://rancher.javachen.com 即可访问管理平台，稍等片刻就好了。

### 安装Rancher

主要是设置使用外部的负载均衡：

```bash
`helm install rancher-latest/rancher \  --name rancher \  --version v2.3.1  \  --namespace cattle-system \  --set hostname=rancher.javachen.com\  --set tls=external\  --set privateCA=true`
```

## 七层负载均衡部署`

![image.png](https://tva1.sinaimg.cn/large/006y8mN6ly1g8ls3vv8jcj30yc0elmyy.jpg)

默认情况下，rancher容器会将80端口上的请求重定向到443端口上。如果Rancher Server通过负载均衡器来代理，这个时候请求是通过负载均衡器发送给Rancher Server，而并非客户端直接访问Rancher Server。在非全局`https`的环境中，如果以外部负载均衡器作为ssl终止，这个时候通过负载均衡器的`https`请求将需要被反向代理到Rancher Server http(80)上。在负载均衡器上配置`X-Forwarded-Proto: https`参数，Rancher Server http(80)上收到负载均衡器的请求后，就不会再重定向到https(443)上。

### 配置Nginx

负载均衡器或代理必须支持以下参数:

- **WebSocket** 连接
- **SPDY**/**HTTP/2**协议
- 传递/设置以下headers:

| Header              | Value                        | 描述                                                         |
| ------------------- | ---------------------------- | ------------------------------------------------------------ |
| `Host`              | 传递给Rancher的主机名        | 识别客户端请求的主机名。                                     |
| `X-Forwarded-Proto` | `https`                      | 识别客户端用于连接负载均衡器的协议。**注意：**如果存在此标头，`rancher/rancher`不会将HTTP重定向到HTTPS。 |
| `X-Forwarded-Port`  | Port used to reach Rancher.  | 识别客户端用于连接负载均衡器的端口。                         |
| `X-Forwarded-For`   | IP of the client connection. | 识别客户端的原始IP地址                                       |

nginx配置示例

```
worker_processes 4;
worker_rlimit_nofile 40000;
events {
    worker_connections 8192;
}
http {
    upstream rancher {
        server 192.168.56.111:80;
        server 192.168.56.112:80;
        server 192.168.56.113:80;
    }
    map $http_upgrade $connection_upgrade {
        default Upgrade;
        ''      close;
    }
    server {
        listen 443 ssl http2; # 如果是升级或者全新安装v2.2.2,需要禁止http2，其他版本不需修改。
        server_name rancher.javachen.com;
        ssl_certificate <更换证书>;
        ssl_certificate_key <更换证书私钥>;
        location / {
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Port $server_port;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://rancher;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            # This allows the ability for the execute shell window to remain open for up to 15 minutes. 
            ## Without this parameter, the default is 1 minute and will automatically close.
            proxy_read_timeout 900s;
            proxy_buffering off;
        }
    }
    server {
        listen 80;
        server_name rancher.javachen.com;
        return 301 https://$server_name$request_uri;
    }
}
```

> 如果没有自己的ssl证书，可访问[自签名ssl证书](https://www.rancher.cn/docs/rancher/v2.x/cn/install-prepare/self-signed-ssl/)一键生成自签名ssl证书。
>
> 为了减少网络传输的数据量，可以在七层代理的`http`定义中添加`GZIP`功能。

```
# Gzip Settings
gzip on;
gzip_disable "msie6";
gzip_disable "MSIE [1-6]\.(?!.*SV1)";
gzip_vary on;
gzip_static on;
gzip_proxied any;
gzip_min_length 0;
gzip_comp_level 8;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types
  text/xml application/xml application/atom+xml application/rss+xml application/xhtml+xml image/svg+xml application/font-woff
  text/javascript application/javascript application/x-javascript
  text/x-json application/json application/x-web-app-manifest+json
  text/css text/plain text/x-component
  font/opentype application/x-font-ttf application/vnd.ms-fontobject font/woff2
  image/x-icon image/png image/jpeg;
```

### 安装Rancher

主要是设置使用Ingress，默认 tls=ingress。

```bash
helm install rancher-stable/rancher \
  --name rancher \
  --version v2.3.2  \
  --namespace cattle-system \
  --set hostname=rancher.javachen.com\
  --set tls=ingress
```

# 查看状态

```bash
kubectl -n cattle-system rollout status deploy/rancher

kubectl -n cattle-system get deploy rancher

kubectl get all -n cattle-system

kubectl get secret,ingress -n cattle-system
```

# 添加主机映射

由于我们通过hosts文件来添加映射，所以需要为Agent Pod添加主机别名(/etc/hosts)：

```bash
kubectl -n cattle-system patch deployments cattle-cluster-agent --patch '{
 "spec": {
  "template": {
  "spec": {
       "hostAliases": [
          {
            "hostnames":[ "rancher.javachen.com"],
          	"ip": "192.168.56.111"
          }
       ]
    }
   }
   }
}'

kubectl -n cattle-system patch daemonsets cattle-node-agent --patch '{
 "spec": {
  "template": {
  "spec": {
       "hostAliases": [
          {
            "hostnames":[ "rancher.javachen.com"],
          	"ip": "192.168.56.111"
          }
      ]
    }
   }
   }
}'
```

> 注意：这里的192.168.56.111是下文中配置的负载均衡地址，也可以换成一个node的ip

# 卸载重装

```bash
helm del --purge cert-manager
helm del --purge rancher

kubectl delete pod,service,deploy,ingress,secret,pvc,replicaset,daemonset --all -n cattle-system

kubectl delete ServiceAccount,ClusterRoleBinding,Role rancher -n cattle-system
```

# 升级版本

```bash
#使用rancher-latest镜像仓库
helm upgrade rancher rancher-stable/rancher \
 --version v2.3.2 \
 --namespace cattle-system \
 --set hostname=rancher.javachen.com
```

> 通过`--version`指定升级版本，`镜像tag`不需要指定，会自动根据chart版本获取。

查看状态：

```bash
kubectl -n cattle-system rollout status deploy/rancher

kubectl -n cattle-system get deploy rancher
```

