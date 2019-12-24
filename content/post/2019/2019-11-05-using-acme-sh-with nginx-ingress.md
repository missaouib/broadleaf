---
layout: post
title: kubernetes使用acme.sh生成letsencrypt证书
date: 2019-11-05T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,ingress,SSL]
---

kubernetes中很多地方都要配置SSL证书，权威的证书要钱，免费的证书数量有限，而 [acme.sh](https://github.com/Neilpang/acme.sh) 实现了 `acme` 协议，可以从 letsencrypt 生成免费的证书，而且还支持泛域名的证书。

#安装acme.sh

```bash
curl  https://get.acme.sh | sh
source /home/~/.bashrc
```

执行成功后，脚本会安装在~/.acme.sh目录下，并且设置了一个定时任务：

```bash
47 0 * * * "/home/~/.acme.sh"/acme.sh --cron --home "/home/~/.acme.sh" > /dev/null
```

# 创建证书

参考 acme.sh 文档：https://github.com/Neilpang/acme.sh/wiki/dnsapi

## dnspod

如果使用的是dnspod域名托管商，在https://console.dnspod.cn/account/token 页面创建一个token：

```bash
#注意替换 XXXXX
export DP_Id="123438"
export DP_Key="XXXXX"
```

可以通过下面命令，检查：

```bash
curl https://dnsapi.cn/Domain.List -d "login_token=123438,XXXXX&format=json"
```

创建泛域名证书：

```bash
acme.sh --issue --dns dns_dp -d javachen.space -d *.javachen.space --debug
```

要求javachen.space必须是可以解析的域名、有外网地址，并且dns托管商提供了api，如果没有，就要改为手动方式。

查看生成的文件：

```bash
$ cd ~/.acme.sh/javachen.space/

$ ll
总用量 36
-rw-r--r-- 1 chenzj docker 1648 11月  5 10:51 ca.cer
-rw-r--r-- 1 chenzj docker 3575 11月  5 10:51 fullchain.cer
-rw-r--r-- 1 chenzj docker 1927 11月  5 10:51 javachen.space.cer
-rw-r--r-- 1 chenzj docker  829 11月  5 16:47 javachen.space.conf
-rw-r--r-- 1 chenzj docker  997 11月  5 10:50 javachen.space.csr
-rw-r--r-- 1 chenzj docker  228 11月  5 10:50 javachen.space.csr.conf
-rw-r--r-- 1 chenzj docker 1679 11月  4 17:31 javachen.space.key
```

## **godaddy**

如果使用的是godaddy域名托管商，在 https://developer.godaddy.com/keys/ 页面创建一个API Key：

![image-20191120125243081](https://tva1.sinaimg.cn/large/006y8mN6ly1g94evuptx2j312a0u0jts.jpg)

创建证书：

```bash
export GD_Key="XXXXXXXXXXXXXXXXXXX"
export GD_Secret="XXXXXXXXXXXXXXXXXXX"

acme.sh --issue --dns dns_gd -d javachen.space -d *.javachen.space --debug
```

执行过程中，会在dns上创建两条txt记录：

![image-20191120125734413](https://tva1.sinaimg.cn/large/006y8mN6ly1g94f0rmj06j31i80t8gpq.jpg)

等执行结束，就会生成证书：

![image-20191120125918364](https://tva1.sinaimg.cn/large/006y8mN6ly1g94f2ke84pj31bc0d0jvv.jpg)

并删除txt记录：

![image-20191120130008126](https://tva1.sinaimg.cn/large/006y8mN6gy1g94f3fotoxj31jw0jetbg.jpg)

# 通过Nginx验证证书

将证书和密钥拷贝到nginx的目录下面：

```bash
sudo yum install nginx -y
sudo mkdir /etc/nginx/ssl

cd ~/.acme.sh/javachen.space/
sudo cp javachen.space.key /etc/nginx/ssl/javachen.space.key
sudo cp fullchain.cer /etc/nginx/ssl/fullchain.cer
```

在nginx配置文件中添加SSL的配置：

```bash
cat << EOF > test.conf
server {
    listen 8443 ssl;
    server_name localhost;
    root html;
    index index.html index.htm;
    ssl_certificate   /etc/nginx/ssl/fullchain.cer;
    ssl_certificate_key  /etc/nginx/ssl/javachen.space.key;
    ssl_session_timeout 5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    location / {
        root html;
        index index.html index.htm;
    }
}
EOF

sudo mv test.conf /etc/nginx/conf.d/
```

重启服务：

```bash
sudo systemctl restart nginx
```

在本地配置hosts文件：

```bash
192.168.56.111 javachen.space
```

访问浏览器 https://javachen.space:8443/ ，可以看到证书是被浏览器可信任的：

![image-20191120134452084](https://tva1.sinaimg.cn/large/006y8mN6gy1g94gdz5subj30vw0lyn3m.jpg)

也能看到签发组织：

![image-20191120134523523](https://tva1.sinaimg.cn/large/006y8mN6gy1g94geit3naj31au0nk4b0.jpg)

# 配置Ingress自签名证书

## 创建服务

参考 [使用Cert Manager配置Let’s Encrypt证书](http://blog.javachen.space/2019/11/04/using-cert-manager-with-nginx-ingress/) 中的例子，创建服务：

```bash
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

---
apiVersion: v1
kind: Service
metadata:
  name: kuard
spec:
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443 
    targetPort: 443
    protocol: TCP  
  selector:
    app: kuard
EOF
```

## 创建secret

按照k8s的要求，**将证书和密钥重命名**：

```bash
#将服务证书和 CA 中间证书链合并到 tls.crt
cp fullchain.cer tls.crt

#将私钥复制到或者重命名为 tls.key
cp javachen.space.key tls.key
```

创建secret：

```bash
#一定要是tls.crt、tls.crt
kubectl create secret tls kuard-secret-tls --cert=tls.crt  --key=tls.key
```

## 创建Ingress

```bash
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
    secretName: kuard-secret-tls
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

## 查看状态

```bash
kubectl get all 

kubectl get secret kuard-secret-tls

#检查tls.key、tls.crt
kubectl get secret kuard-secret-tls -o yaml

$ kubectl get ing 
NAME    HOSTS                  ADDRESS   PORTS     AGE
kuard   kuard.javachen.space             80, 443   11s
```

在本地配置hosts文件：

```bash
192.168.56.111 kuard.javachen.space
```

浏览器访问 https://kuard.javachen.space/ 可以看到tomcat主页，并且证书是被信任度的。

![image-20191120135147708](https://tva1.sinaimg.cn/large/006y8mN6ly1g94gl6hq7uj31120kitdy.jpg)

# 参考文章

- https://github.com/Neilpang/acme.sh
- https://docs.cert-manager.io/en/latest/tutorials/acme/quick-start/index.html#
- [使用Cert Manager配置Let’s Encrypt证书](/2019-11-04-using-cert-manager-with-nginx-ingress)
