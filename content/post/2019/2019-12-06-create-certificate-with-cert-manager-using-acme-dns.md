---
layout: post
title: Cert Manager使用ACME-DNS生成证书
date: 2019-12-06T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes]
---



之前使用cert-manager-webhook-dnspod来生成DNSPOD的泛域名的证书，但是遇到 [一个问题](/2019/11/04/using-cert-manager-with-nginx-ingress/#%E6%B5%8B%E8%AF%95%E6%89%8B%E5%8A%A8%E5%88%9B%E5%BB%BA%E8%AF%81%E4%B9%A6) 导致证书生成失败，所以，需要使用其他方式自动生成泛域名的证书。

Cert Manager默认支持ACME-DNS的方式，详情见[文档](https://cert-manager.io/docs/configuration/acme/dns01/acme-dns/)。文本结合 https://github.com/joohoi/acme-dns ，整理出Cert Manager使用ACME-DNS的方式生成证书的过程。

# 注册

1、先在 [https://auth.acme-dns.io](https://auth.acme-dns.io/) 注册

```bash
$ curl -s -X POST https://auth.acme-dns.io/register | python -m json.tool
{
		"allowfrom": [],
    "fulldomain": "0d790c39-3b62-4285-a20e-ec7d15bca014.auth.acme-dns.io",
    "password": "0fwKMjRbhWc-la3Lvnl4W607q179KO4PVRx6LFA-",
    "subdomain": "0d790c39-3b62-4285-a20e-ec7d15bca014",
    "username": "7af0e48d-1678-4475-8a92-343dc64f0cf1"
}
```

当然，也可以设置allowfrom:

```bash
$ curl -s -X POST https://auth.acme-dns.io/register -H "Content-Type: application/json" \
	--data '{"allowfrom": ["58.19.0.0/16","10.43.0.0/16","192.168.0.0/16"]}' | python -m json.tool
```

- 58.19.0.0是外网地址网段
- 10.43.0.0是k8s容器IP网段

2、将返回值保持到acmedns.json，并设置域名，可以设置多个。

```json
cat << EOF > acmedns.json
{
    "javachen.xyz": {
        "allowfrom": [],
        "fulldomain": "0d790c39-3b62-4285-a20e-ec7d15bca014.auth.acme-dns.io",
        "password": "0fwKMjRbhWc-la3Lvnl4W607q179KO4PVRx6LFA-",
        "subdomain": "0d790c39-3b62-4285-a20e-ec7d15bca014",
        "username": "7af0e48d-1678-4475-8a92-343dc64f0cf1"
    }
}
EOF
```

这里设置的是javachen.xyz域名。

# 添加CNAME记录

在DNS上为javachen.xyz添加一个CNAME记录

```
_acme-challenge CNAME 0d790c39-3b62-4285-a20e-ec7d15bca014.auth.acme-dns.io
```

查看DNS解析是否生效：

```bash
dig _acme-challenge.javachen.xyz
```

# 使用API验证

参考 https://github.com/joohoi/acme-dns

1、查找DNS

```bash
dig auth.acme-dns.io
```

2、调用API设置一条测试txt记录

```bash
$ curl -s -X POST \
  -H "X-Api-User: 7af0e48d-1678-4475-8a92-343dc64f0cf1" \
  -H "X-Api-Key: 0fwKMjRbhWc-la3Lvnl4W607q179KO4PVRx6LFA-" \
  -d '{"subdomain": "0d790c39-3b62-4285-a20e-ec7d15bca014", "txt": "___validation_token_received_from_the_ca___"}' \
  https://auth.acme-dns.io/update
  
{"txt": "___validation_token_received_from_the_ca___"}
```

如果返回 {"error": "forbidden"} ，可能是DNS缓存、用户名和密码不正确。

3、DNS查找，查看测试txt记录的值

```bash
dig -t txt @auth.acme-dns.io 0d790c39-3b62-4285-a20e-ec7d15bca014.auth.acme-dns.io
```



# 使用Cert-manager来验证

## 创建一个secret

```bash
kubectl create secret generic acme-dns -n cert-manager --from-file acmedns.json
```

这里指定命名空间为cert-manager，否则后面创建的ClusterIssuer找不到该Secret。

## 创建Issuer

```yaml
cat << EOF | kubectl create -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: javachen-xyz-letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
         name: javachen-xyz-letsencrypt-prod
    solvers:
    - dns01:
        acmedns:
          host: https://auth.acme-dns.io
          accountSecretRef:
            name: acme-dns
            key: acmedns.json
EOF
```

查看状态：

```bash
kubectl get ClusterIssuer 
kubectl describe ClusterIssuer javachen-xyz-letsencrypt-prod
```



## 创建证书

```yaml
cat << EOF | kubectl create -f -   
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: javachen-xyz-cert
  namespace: cert-manager
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

 查看状态

```bash
kubectl get secret,certificate -n cert-manager
kubectl describe secret javachen-xyz-cert -n cert-manager

kubectl describe certificate javachen-xyz-cert -n cert-manager

kubectl describe CertificateRequest javachen-xyz-cert-542546277 -n cert-manager

kubectl describe order javachen-xyz-cert-542546277-2766464876 -n cert-manager

kubectl describe Challenge javachen-xyz-cert-542546277-2766464876-2618792437 -n cert-manager
```

等待一段时间，直到证书状态变为True

```bash
$ kubectl get certificate
NAME                                            READY   SECRET              AGE
certificate.cert-manager.io/javachen-xyz-cert   True    javachen-xyz-cert   2m43s
```

接下来就是测试证书是否可以被使用。

## 卸载

```bash
kubectl delete secret acme-dns -n cert-manager

kubectl delete ClusterIssuer javachen-xyz-letsencrypt-prod
kubectl delete Certificate,secret javachen-xyz-cert -n cert-manager
```



# 参考文章

- [ACME-DNS](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/acme-dns.html)
- https://blog.csdn.net/xichenguan/article/details/100709830