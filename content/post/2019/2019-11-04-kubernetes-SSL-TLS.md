---
layout: post
title: Kubernetes SSL证书管理
date: 2019-11-04T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,SSL]
draft: false
---

# HTTP over SSL

要保证Web浏览器到服务器的安全连接，HTTPS几乎是唯一选择。HTTPS其实就是HTTP over SSL，也就是让HTTP连接建立在SSL安全连接之上。

SSL使用证书来创建安全连接。有两种验证模式:

1. 仅客户端验证服务器的证书，客户端自己不提供证书；
2. 客户端和服务器都互相验证对方的证书。

一般第二种方式用于网上银行等安全性要求较高的网站，普通的Web网站只采用第一种方式。



客户端如何验证服务器的证书呢？

服务器自己的证书必须经过某“权威”证书的签名，而这个“权威”证书又可能经过更权威的证书签名，这么一级一级追溯上去，最顶层那个最权威的证书就称为根证书。根证书直接内置在浏览器中，这样，浏览器就可以利用自己自带的根证书去验证某个服务器的证书是否有效。如果要提供一个有效的证书，服务器的证书必须从`VeriSign`这样的证书颁发机构签名。这样，浏览器就可以验证通过，否则，浏览器给出一个证书无效的警告。一般安全要求较高的内网环境，可以通过创建自签名SSL证书来加密通信。

# 数字证书

在HTTPS的传输过程中，有一个非常关键的角色–`数字证书`，那什么是数字证书？又有什么作用呢？

所谓数字证书，是一种用于电脑的身份识别机制。由数字证书颁发机构(CA)对使用私钥创建的签名请求文件做的签名(盖章)，表示CA结构对证书持有者的认可。

## 优点

- 使用数字证书能够提高用户的可信度；
- 数字证书中的公钥，能够与服务端的私钥配对使用，实现数据传输过程中的加密和解密；
- 在证认使用者身份期间，使用者的敏感个人数据并不会被传输至证书持有者的网络系统上。

## 证书类型

x509的证书编码格式有两种：

1. PEM(Privacy-enhanced Electronic Mail)是明文格式的，以 `—–BEGIN CERTIFICATE—–`开头，已`—–END CERTIFICATE`—–结尾。中间是经过base64编码的内容，apache需要的证书就是这类编码的证书。查看这类证书的信息的命令为： `openssl x509 -noout -text -in server.pem`。其实PEM就是把DER的内容进行了一次base64编码。
2. DER是二进制格式的证书，查看这类证书的信息的命令为：`openssl x509 -noout -text -inform der -in server.der`

## 扩展名

- .crt证书文件，可以是DER(二进制)编码的，也可以是PEM(ASCII (Base64))编码的)，在类unix系统中比较常见；
- .cer也是证书，常见于Windows系统。编码类型同样可以是DER或者PEM的，windows下有工具可以转换crt到cer；
- .csr证书签名请求文件，一般是生成请求以后发送给CA，然后CA会给您签名并发回证书；
- .key一般公钥或者密钥都会用这种扩展名，可以是DER编码的或者是PEM编码的。查看DER编码的(公钥或者密钥)的文件的命令为：`openssl rsa -inform DER -noout -text -in xxx.key`。查看PEM编码的(公钥或者密钥)的文件的命令为: `openssl rsa -inform PEM -noout -text -in xxx.key`;
- .p12证书文件，包含一个X509证书和一个被密码保护的私钥。

# 自签名证书及自签名类型

当由于某种原因(如：不想通过CA购买证书，或者仅是用于测试等情况)，无法正常获取CA签发的证书。这时可以生成一个自签名证书。使用这个自签名证书的时候，会在客户端浏览器报一个错误，签名证书授权未知或不可信(signing certificate authority is unknown and not trusted.)。



自签名类型：

- 自签名证书
- 私有CA签名证书

> 自签名证书的`Issuer`和`Subject`是相同的。

- 区别:
  - 自签名的证书无法被吊销，私有CA签名的证书可以被吊销。
  - 如果您的规划需要创建多个证书，那么使用私有CA签名的方法比较合适，因为只要给所有的客户端都安装相同的CA证书，那么以该CA证书签名过的证书，客户端都是信任的，也就只需要安装一次就够了。
  - 如果您使用用自签名证书，您需要给所有的客户端安装该证书才会被信任。如果您需要第二个证书，则需要给所有客户端安装第二个CA证书才会被信任。



# 集群相关证书类型

**client certificate**：用于服务端认证客户端,例如etcdctl、etcd proxy、fleetctl、docker客户端

**server certificate**: 服务端使用，客户端以此验证服务端身份,例如docker服务端、kube-apiserver

**peer certificate**: 双向证书，用于etcd集群成员间通信



根据认证对象可以将证书分成三类：服务器证书`server cert`，客户端证书`client cert`，对等证书`peer cert`(表示既是`server cert`又是`client cert`)



在kubernetes 集群中需要的证书种类如下：

- `etcd` 节点需要标识自己服务的server cert，也需要client cert与etcd集群其他节点交互，当然可以分别指定2个证书，也可以使用一个对等证书
- `master` 节点需要标识 apiserver服务的server cert，也需要client cert连接etcd集群，这里也使用一个对等证书
- `kubectl` `calico` `kube-proxy` 只需要`client cert`，因此证书请求中 hosts 字段可以为空
- `kubelet`证书比较特殊，不是手动生成，它由node节点`TLS BootStrap`向`apiserver`请求，由`master`节点的`controller-manager` 自动签发，包含一个`client cert` 和一个`server cert`



# 生成自签名证书

## Openssl

参考[生成自签名证书](https://www.rancher.cn/docs/rancher/v2.x/cn/install-prepare/self-signed-ssl/#四-生成自签名证书) ，使用脚 本create_self-signed-cert.sh 一键生成ssl自签名证书：

```bash
#!/bin/bash -e

help ()
{
    echo  ' ================================================================ '
    echo  ' --ssl-domain: 生成ssl证书需要的主域名，如不指定则默认为www.rancher.local，如果是ip访问服务，则可忽略；'
    echo  ' --ssl-trusted-ip: 一般ssl证书只信任域名的访问请求，有时候需要使用ip去访问server，那么需要给ssl证书添加扩展IP，多个IP用逗号隔开；'
    echo  ' --ssl-trusted-domain: 如果想多个域名访问，则添加扩展域名（SSL_TRUSTED_DOMAIN）,多个扩展域名用逗号隔开；'
    echo  ' --ssl-size: ssl加密位数，默认2048；'
    echo  ' --ssl-date: ssl有效期，默认10年；'
    echo  ' --ca-date: ca有效期，默认10年；'
    echo  ' --ssl-cn: 国家代码(2个字母的代号),默认CN;'
    echo  ' 使用示例:'
    echo  ' ./create_self-signed-cert.sh --ssl-domain=www.test.com --ssl-trusted-domain=www.test2.com \ '
    echo  ' --ssl-trusted-ip=1.1.1.1,2.2.2.2,3.3.3.3 --ssl-size=2048 --ssl-date=3650'
    echo  ' ================================================================'
}

case "$1" in
    -h|--help) help; exit;;
esac

if [[ $1 == '' ]];then
    help;
    exit;
fi

CMDOPTS="$*"
for OPTS in $CMDOPTS;
do
    key=$(echo ${OPTS} | awk -F"=" '{print $1}' )
    value=$(echo ${OPTS} | awk -F"=" '{print $2}' )
    case "$key" in
        --ssl-domain) SSL_DOMAIN=$value ;;
        --ssl-trusted-ip) SSL_TRUSTED_IP=$value ;;
        --ssl-trusted-domain) SSL_TRUSTED_DOMAIN=$value ;;
        --ssl-size) SSL_SIZE=$value ;;
        --ssl-date) SSL_DATE=$value ;;
        --ca-date) CA_DATE=$value ;;
        --ssl-cn) CN=$value ;;
    esac
done

# CA相关配置
CA_DATE=${CA_DATE:-3650}
CA_KEY=${CA_KEY:-cakey.pem}
CA_CERT=${CA_CERT:-cacerts.pem}
CA_DOMAIN=cattle-ca

# ssl相关配置
SSL_CONFIG=${SSL_CONFIG:-$PWD/openssl.cnf}
SSL_DOMAIN=${SSL_DOMAIN:-'www.rancher.local'}
SSL_DATE=${SSL_DATE:-3650}
SSL_SIZE=${SSL_SIZE:-2048}

## 国家代码(2个字母的代号),默认CN;
CN=${CN:-CN}

SSL_KEY=$SSL_DOMAIN.key
SSL_CSR=$SSL_DOMAIN.csr
SSL_CERT=$SSL_DOMAIN.crt

echo -e "\033[32m ---------------------------- \033[0m"
echo -e "\033[32m       | 生成 SSL Cert |       \033[0m"
echo -e "\033[32m ---------------------------- \033[0m"

if [[ -e ./${CA_KEY} ]]; then
    echo -e "\033[32m ====> 1. 发现已存在CA私钥，备份"${CA_KEY}"为"${CA_KEY}"-bak，然后重新创建 \033[0m"
    mv ${CA_KEY} "${CA_KEY}"-bak
    openssl genrsa -out ${CA_KEY} ${SSL_SIZE}
else
    echo -e "\033[32m ====> 1. 生成新的CA私钥 ${CA_KEY} \033[0m"
    openssl genrsa -out ${CA_KEY} ${SSL_SIZE}
fi

if [[ -e ./${CA_CERT} ]]; then
    echo -e "\033[32m ====> 2. 发现已存在CA证书，先备份"${CA_CERT}"为"${CA_CERT}"-bak，然后重新创建 \033[0m"
    mv ${CA_CERT} "${CA_CERT}"-bak
    openssl req -x509 -sha256 -new -nodes -key ${CA_KEY} -days ${CA_DATE} \
    	-out ${CA_CERT} -subj "/C=${CN}/CN=${CA_DOMAIN}"
else
    echo -e "\033[32m ====> 2. 生成新的CA证书 ${CA_CERT} \033[0m"
    openssl req -x509 -sha256 -new -nodes -key ${CA_KEY} -days ${CA_DATE} \
    	-out ${CA_CERT} -subj "/C=${CN}/CN=${CA_DOMAIN}"
fi

echo -e "\033[32m ====> 3. 生成Openssl配置文件 ${SSL_CONFIG} \033[0m"
cat > ${SSL_CONFIG} <<EOM
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOM

if [[ -n ${SSL_TRUSTED_IP} || -n ${SSL_TRUSTED_DOMAIN} ]]; then
    cat >> ${SSL_CONFIG} <<EOM
subjectAltName = @alt_names
[alt_names]
EOM
    IFS=","
    dns=(${SSL_TRUSTED_DOMAIN})
    dns+=(${SSL_DOMAIN})
    for i in "${!dns[@]}"; do
      echo DNS.$((i+1)) = ${dns[$i]} >> ${SSL_CONFIG}
    done

    if [[ -n ${SSL_TRUSTED_IP} ]]; then
        ip=(${SSL_TRUSTED_IP})
        for i in "${!ip[@]}"; do
          echo IP.$((i+1)) = ${ip[$i]} >> ${SSL_CONFIG}
        done
    fi
fi

echo -e "\033[32m ====> 4. 生成服务SSL KEY ${SSL_KEY} \033[0m"
openssl genrsa -out ${SSL_KEY} ${SSL_SIZE}

echo -e "\033[32m ====> 5. 生成服务SSL CSR ${SSL_CSR} \033[0m"
openssl req -sha256 -new -key ${SSL_KEY} -out ${SSL_CSR} -subj \
	"/C=${CN}/CN=${SSL_DOMAIN}" -config ${SSL_CONFIG}

echo -e "\033[32m ====> 6. 生成服务SSL CERT ${SSL_CERT} \033[0m"
openssl x509 -sha256 -req -in ${SSL_CSR} -CA ${CA_CERT} \
    -CAkey ${CA_KEY} -CAcreateserial -out ${SSL_CERT} \
    -days ${SSL_DATE} -extensions v3_req \
    -extfile ${SSL_CONFIG}

echo -e "\033[32m ====> 7. 证书制作完成 \033[0m"
echo
echo -e "\033[32m ====> 8. 以YAML格式输出结果 \033[0m"
echo "----------------------------------------------------------"
echo "ca_key: |"
cat $CA_KEY | sed 's/^/  /'
echo
echo "ca_cert: |"
cat $CA_CERT | sed 's/^/  /'
echo
echo "ssl_key: |"
cat $SSL_KEY | sed 's/^/  /'
echo
echo "ssl_csr: |"
cat $SSL_CSR | sed 's/^/  /'
echo
echo "ssl_cert: |"
cat $SSL_CERT | sed 's/^/  /'
echo

echo -e "\033[32m ====> 9. 附加CA证书到Cert文件 \033[0m"
cat ${CA_CERT} >> ${SSL_CERT}
echo "ssl_cert: |"
cat $SSL_CERT | sed 's/^/  /'
echo

echo -e "\033[32m ====> 10. 重命名服务证书 \033[0m"
echo "cp ${SSL_DOMAIN}.key tls.key"
cp ${SSL_DOMAIN}.key tls.key
echo "cp ${SSL_DOMAIN}.crt tls.crt"
cp ${SSL_DOMAIN}.crt tls.crt
```

生成证书：

```bash
./create_self-signed-cert.sh --ssl-domain=javachen.com \
--ssl-trusted-domain=javachen.com,*.javachen.com --ssl-size=2048 --ssl-date=3650
```

校验证书：

```bash
#验证证书 
openssl verify -CAfile cacerts.pem tls.crt  

#查看证书细节
openssl x509 -in cacerts.pem -noout -text
openssl x509 -in tls.crt -noout -text

#不加CA证书验证
openssl s_client -connect rancher.javachen.com:443 -servername rancher.javachen.com

#加CA证书验证
openssl s_client -connect rancher.javachen.com:443 -servername rancher.javachen.com -CAfile server-ca.crt
```



## CFSSL

CFSSL是CloudFlare开源的一款PKI/TLS工具。 CFSSL 包含一个命令行工具 和一个用于 签名，验证并且捆绑TLS证书的 HTTP API 服务。 使用Go语言编写。


Github 地址： https://github.com/cloudflare/cfssl

官网地址： https://pkg.cfssl.org/

参考地址：[liuzhengwei521](http://blog.51cto.com/liuzhengwei521/2120535?utm_source=oschina-app)



### 安装

```
sudo curl -s -L -o /usr/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
sudo curl -s -L -o /usr/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
sudo curl -s -L -o /usr/bin/cfssl-certinfo https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
sudo chmod +x /usr/bin/cfssl*
```

### 创建CA配置文件

配置证书生成策略，规定CA可以颁发那种类型的证书

```bash
cat << EOF > ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "javachen.com": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
```

### 创建CA证书签名请求

```bash
cat << EOF > ca-csr.json
{
	"CN": "Self Signed Ca",
	"key": {
    	"algo": "rsa",
    	"size": 2048
	},
	"names": [
	{
        	"C": "CN",
        	"ST": "HuBei",    
        	"L": "WuHan",
        	"O": "my self signed certificate",
        	"OU": "ops"
    }]
}
EOF
```

### 生成CA和私钥

生成CA所必需的文件ca-key.pem（私钥）和ca.pem（证书），还会生成ca.csr（证书签名请求），用于交叉签名或重新签名。

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

### 生成服务器证书

编辑server-csr.json，内容如下：

```bash
cat << EOF > server-csr.json
{
    "CN": "javachen.com",
    "hosts": [
        "127.0.0.1",
        "*.javachen.com"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "HuBei",
            "L": "WuHan",
            "O": "my self signed certificate",
            "OU": "self signed"
        }
    ]
}
EOF
```

执行以下命令，生成服务器证书：

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem --config=ca-config.json -profile=javachen.com 
 server-csr.json | cfssljson -bare server
```

这样就得到`ca.pem`，`server-key.pem`，`server.pem`三个证书文件，其中`ca.pem`是ca的证书，`server-key.pem`是服务器证书的密钥，`server.pem`是服务器证书。


用Keychain Access打开ca.pem文件，然后修改设置，信任该CA



![image.png](https://cdn.nlark.com/yuque/0/2019/png/462325/1572161434190-395f5223-8fcf-48b1-8382-2c736992338e.png)



## Cert-Manager

用cfssl之类的工具手动生成TLS证书，主要有以下几点缺陷：

1. 如果k8s集群上部署的应用较多，要为每个应用的不同域名生成https证书，操作太麻烦。
2. 上述这些手动操作没有跟k8s的deployment描述文件放在一起记录下来，很容易遗忘。
3. 证书过期后，又得手动执行命令重新生成证书。

### 架构

![img](https://cdn.nlark.com/yuque/0/2019/png/462325/1572161992146-735d1889-3e18-42de-9213-085dad062c4c.png)

上面是官方给出的架构图，可以看到cert-manager在k8s中定义了两个自定义类型资源：`Issuer`和`Certificate`。

其中`Issuer`代表的是证书颁发者，可以定义各种提供者的证书颁发者，当前支持基于`Letsencrypt`、`vault`和`CA`的证书颁发者，还可以定义不同环境下的证书颁发者。

而`Certificate`代表的是生成证书的请求，一般其中存入生成证书的元信息，如域名等等。

一旦在k8s中定义了上述两类资源，部署的`cert-manager`则会根据`Issuer`和`Certificate`生成TLS证书，并将证书保存进k8s的`Secret`资源中，然后在`Ingress`资源中就可以引用到这些生成的`Secret`资源。对于已经生成的证书，还是定期检查证书的有效期，如即将超过有效期，还会自动续期。

### 部署

参考 https://docs.cert-manager.io/en/release-0.11/

部署cert-manager还是比较简单的，直接用kubectl部署就可以了：

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.11.0/cert-manager.yaml
```

查看状态：

```bash
kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces
```

卸载：

```bash
kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v0.11.0/cert-manager.yaml
```



### `Letsencrypt`证书颁发者

k8s中使用cert-manager玩转证书 [https://jeremy-xu.oschina.io/2018/08/k8s%E4%B8%AD%E4%BD%BF%E7%94%A8cert-manager%E7%8E%A9%E8%BD%AC%E8%AF%81%E4%B9%A6/](https://jeremy-xu.oschina.io/2018/08/k8s中使用cert-manager玩转证书/)

### `CA`证书颁发者

#### 创建Issuer资源

由于我试验环境是个人电脑，不能被外网访问，因此无法试验`Letsencrypt`类型的证书颁发者，而`vault`貌似部署起来很是麻烦，所以还是创建一个简单的CA类型Issuer资源。

我们需要先创建一个签发机构，cert-manager 给我们提供了 Issuer 和 ClusterIssuer 这两种用于创建签发机构的自定义资源对象，Issuer 只能用来签发自己所在 namespace 下的证书，ClusterIssuer 可以签发任意 namespace 下的证书，这里以 `ClusterIssuer` 为例。关于`ClusterIssuer`与`Issuer`的区别可以查阅[这里](https://cert-manager.readthedocs.io/en/latest/getting-started/3-configuring-first-issuer.html)。

首先将根CA的key及证书文件存入一个secret中：

```bash
kubectl create secret tls ca-secret-tls \
   --cert=ca.pem \
   --key=ca-key.pem 
```

上述操作中的ca.pem、ca-key.pem文件还是用`cfssl`命令生成的。

然后创建Issuer资源：

```bash
cat << EOF | kubectl create -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: ca-secret-tls
EOF
```

#### 创建Certificate资源

有了签发机构，接下来我们就可以生成免费证书了，cert-manager 给我们提供了 Certificate 这个用于生成证书的自定义资源对象，它必须局限在某一个 namespace 下，证书最终会在这个 namespace 下以 Secret 的资源对象存储，创建一个 Certificate 对象：

```bash
cat << EOF | kubectl create -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: javachen-com
spec:
  secretName: javachen-secret-tls
  issuerRef:
    name: ca-issuer
    # We can reference ClusterIssuers by changing the kind here.
    # The default value is Issuer (i.e. a locally namespaced Issuer)
    kind: ClusterIssuer
  commonName: javachen.com
  organization:
  - CA
  dnsNames:
  - javachen.com
  - www.javachen.com
  - *.javachen.com
EOF
```

稍等一会儿，就可以查询到cert-manager生成的证书secret：

```
kubectl describe secret javachen-secret-tls -n cert-manager 
```

#### 使用建议

实际生产环境中使用cert-manager可以考虑以下建议：

1. 将CA的`Secret`及`Issuer`放在某个独立的命名空间中，与其它业务的命名空间隔离起来。
2. 如果是CA类型的`Issuer`，要记得定期更新根CA证书。
3. 如果服务可被公网访问，同时又不想花钱买域名证书，可以采用`Letsencrypt`类型的`Issuer`，目前支持两种方式验证域名的所有权，基于[DNS记录的验证方案](https://cert-manager.readthedocs.io/en/latest/tutorials/acme/dns-validation.html)和基于[文件的HTTP验证方案](https://cert-manager.readthedocs.io/en/latest/tutorials/acme/http-validation.html)。
4. `cert-manager`还提供`ingress-shim`方式，自动为`Ingress`资源生成证书，只需要在`Ingress`资源上打上一些标签即可，很方便有木有，详细可参考[这里](https://cert-manager.readthedocs.io/en/latest/reference/ingress-shim.html)。
