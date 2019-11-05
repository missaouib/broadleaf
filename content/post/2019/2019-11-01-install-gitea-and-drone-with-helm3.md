---
layout: post
title: 使用Helm3安装Gitea和Drone
date: 2019-11-01T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,helm,gitea]
---

Drone是一种基于容器技术的持续交付系统。Drone使用简单的YAML配置文件来定义和执行Docker容器中的Pipelines。Drone与流行的源代码管理系统无缝集成，包括GitHub、Gitlab、Gog、Gitea、Bitbucket等。

Gitea 是一个开源社区驱动的 [Gogs](http://gogs.io/) [克隆](https://blog.gitea.io/2016/12/welcome-to-gitea/), 是一个轻量级的代码托管解决方案，后端采用 [Go](https://golang.org/) 编写，采用 [MIT](https://github.com/go-gitea/gitea/blob/master/LICENSE) 许可证。

> 注意：本文使用的Helm版本是3，不是2，所以有些命令和helm2不一样。

# 安装Gitea

## 查找Chart

```bash
helm search repo gitea
No results found
```

## 添加chart

添加阿里巴巴的chart仓库：

```bash
helm repo add alibaba https://apphub.aliyuncs.com
```

再次查找

```bash
helm search repo gitea
NAME         	CHART VERSION	APP VERSION	DESCRIPTION
alibaba/gitea	1.9.1        	1.9.1      	A Helm chart for gitea
```

## 查看Chart说明

```bash
helm repo update

helm show readme alibaba/gitea
```

可以看到有两种安装方式，我这里选择ingress方式安装，并给ingress配置TLS证书。

## 创建证书



## 安装

```bash
helm install --generate-name --namespace gitea\
  --set expose.ingress.host=gitea.javachen.com \
  --set expose.type=ingress \
  --set expose.tls.enabled=true \
  --set expose.ingress.enabled=true \
  --set expose.tls.secretName=gitea-secret-tls \
  --set resources.limits.memory=512Mi \
  alibaba/gitea
```

出错日志：

```
Error: unable to build kubernetes objects from release manifest: \
	unable to recognize "": no matches for kind "Deployment" in version "apps/v1beta2"
```

这是因为我使用的是k8s 1.16.2的版本，API做了变动，Deployment的API修改为apps/v1。

## 修改Gitea Chart

找到 https://apphub.aliyuncs.com 仓库对应的源码仓库 https://github.com/cloudnativeapp/charts ，克隆代码：

```bash
git clone https://github.com/cloudnativeapp/charts
```

修改Deployment文件

```bash
cd charts
sed -i 's/apps\/v1beta2/apps\/v1/g' submitted/gitea/templates/deployment.yaml
```

我fork了一份 https://github.com/cloudnativeapp/charts  代码，然后做了修改 https://github.com/javachen/charts ，除了修改API版本，还添加了存储类的支持，详细请查看values.yaml

```yaml
## Enable persistence using Persistent Volume Claims
## ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
##
persistence:
  enabled: false

  ## A manually managed Persistent Volume and Claim
  ## Requires persistence.enabled: true
  ## If defined, PVC must be created manually before volume will be bound
  # existingClaim:

  ## rabbitmq data Persistent Volume Storage Class
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  # storageClass: "-"
  accessMode: ReadWriteOnce
  size: 1Gi

extraContainers: |

## additional volumes, e. g. for secrets used in an extraContainers.
##
extraVolumes: |
```



## 从本地Chart源码安装

```bash
helm install --generate-name --namespace gitea\
  --set expose.ingress.host=gitea.javachen.com \
  --set expose.type=ingress \
  --set expose.tls.enabled=true \
  --set expose.ingress.enabled=true \
  --set expose.tls.secretName=gitea-secret-tls \
  --set resources.limits.memory=512Mi \
  --set persistence.enabled=true \
  --set persistence.storageClass=ceph-rbd \
  --set persistence.size=5Gi \
  submitted/gitea #submitted目录下的gitea
```

## 测试

访问 https://gitea.javachen.com ，并填入数据库：

![image-20191101141225857](https://tva1.sinaimg.cn/large/006y8mN6gy1g8iiesm31hj31da0s6gpd.jpg)

填入域名：

![image-20191101141306181](https://tva1.sinaimg.cn/large/006y8mN6gy1g8iifho2cdj31d80o841i.jpg)

修改服务器和第三方设置：

![image-20191101141441592](https://tva1.sinaimg.cn/large/006y8mN6ly1g8iih58nsgj31d00nqad3.jpg)

## 卸载

```bash
kubectl delete pod,service,deploy,ingress,secret,pvc --all -n gitea
```



# 安装Drone

Drone 是用 Go 语言编写的基于 Docker 构建的开源轻量级 CI/CD 工具，可以通过 SaaS 服务和自托管服务两种方式使用，Drone 使用简单的 YAML 配置文件来定义和执行 Docker 容器中定义的 Pipeline，Drone 由两个部分组成：

- **Server**端负责身份认证，仓库配置，用户、Secrets 以及 Webhook 相关的配置。
- **Agent**端用于接受构建的作业和真正用于运行的 Pipeline 工作流。

Server 和 Agent 都是非常轻量级的服务，大概只使用 10~15MB 内存，所以我们也可以很轻松的运行在笔记本、台式机甚至是 Raspberry PI 上面。

要安装 Drone 是非常简单的，[官方文档 ](https://docs.drone.io/installation/)中提供了 Drone 集成 GitHub、GitLab、Gogs 等等的文档，可以直接部署在单节点、多个节点和 Kubernetes 集群当中。

## 查找chart

参考上面

```bash
helm search repo drone

helm show readme alibaba/drone
```

## 创建配置文件 

drone-gitea-values.yaml

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - drone.javachen.com
  tls:
    - secretName: drone-secret-tls
      hosts:
        - drone.javachen.com

sourceControl:
  provider: gitea
  gitea:
    server: https://gitea.javachen.com

server:
  host: drone.javachen.com
  adminUser: admin
  protocol: https
  kubernetes:
    enabled: true
persistence:
  enabled: true
  storageClass: ceph-rbd
  size: 5Gi
```

注意：上面配置了ceph的存储类ceph-rbd，需要提前创建。

## 安装

```bash
#使用固定名称
helm install gitea \
     --namespace gitea -f drone-gitea-values.yaml \
     alibaba/drone

#使用随机名称
helm install --generate-name  \
     --namespace gitea -f drone-gitea-values.yaml \
     alibaba/drone
```

出错日志：

```
Error: unable to build kubernetes objects from release manifest: \
	unable to recognize "": no matches for kind "Deployment" in version "apps/v1beta2"
```

这是因为我使用的是k8s 1.16.2的版本，API做了变动，Deployment的API修改为apps/v1。

## 测试

如果上一步没问题，则浏览器访问 https://drone.javachen.com。

![image-20191101111334474](https://tva1.sinaimg.cn/large/006y8mN6ly1g8id8p2p2zj30lw09maas.jpg)

发现授权失败，说明Gitea 1.5.1版本是需要传递ClientID进行授权，而当前Drone的chart是通过access token进行授权的。查看Drone官方文档 https://docs.drone.io/installation/providers/gitea/ 发现必须先在Gitea中创建一个OAuth应用：

![Application Create](https://tva1.sinaimg.cn/large/006y8mN6gy1g8idmks05dj31j20rcwht.jpg)

所以需要在Drone的Chart设置OAuth相关参数。

## 修改Drone Chart

我fork了一份 https://github.com/cloudnativeapp/charts 代码，然后做了修改 https://github.com/javachen/charts

- 修改Deployment的API为apps/v1

- 如果是gitea添加OAuth参数：

  ```yaml
    gitea:
      clientID:
      clientSecretKey: clientSecret
      clientSecretValue:
      server:
  ```

## 从本地Chart源码安装

```bash
$ git clone https://github.com/javachen/charts

$ cd charts/curated/drone

$ pwd
#后面安装drone时需要用到这个绝对路径
/home/chenzj/code/charts/curated/drone
```

## Gitea创建OAuth应用

![image-20191101121525490](https://tva1.sinaimg.cn/large/006y8mN6ly1g8if11xslij312y0sumzm.jpg)

## 修改配置文件

修改drone-gitea-values.yaml，添加gitea的OAuth参数

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - drone.javachen.com
  tls:
    - secretName: drone-secret-tls
      hosts:
        - drone.javachen.com

sourceControl:
  provider: gitea
  gitea:
    clientID: 76eb1d51-7e5f-4616-b812-3649a64cecda
    clientSecretKey: clientSecret
    clientSecretValue: 0xDAtjq6b5Pk5HJQEzDBKU6JvXqQaA1XwjKj6QEKX10=
    server: https://gitea.javachen.com

server:
  host: drone.javachen.com
  adminUser: admin
  protocol: https
  kubernetes:
    enabled: true
persistence:
  enabled: true
  storageClass: ceph-rbd
  size: 5Gi
```

从本地/home/chenzj/code/charts/curated/drone目录安装：

```bash
helm install --generate-name  \
     --namespace gitea -f drone-gitea-values.yaml \
     /home/chenzj/code/charts/curated/drone
```

## 卸载

```bash
kubectl delete pod,service,deploy,ingress,secret,pvc --all -n drone
```

其他ClusterRole、Role、ClusterRoleBinding根据提示，手动删除。

## 测试

浏览器访问 https://drone.javachen.com ，跳到授权页面。

# Drone集成Gitea实现CI

在Gitea中创建项目，设置.drone.yaml，然后修改代码，提交触发Drone构建，会出现异常，找不到Git仓库用户名的异常，所以必须设置登陆Gitea的用户名和密码。

修改方式：在drone-gitea-values.yaml文件中添加：

```yaml
  alwaysAuth: true
  envSecrets:
    drone-gitea-login-secrets:
    	- DRONE_GIT_USERNAME
    	- DRONE_GIT_PASSWORD   
```

完整代码如下：

```yaml
cat <<EOF > drone-gitea-values.yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 10m
  hosts:
    - drone.javachen.com
  tls:
    - secretName: drone-secret-tls
      hosts:
        - drone.javachen.com

sourceControl:
  provider: gitea
  gitea:
    clientID: fdd12331-363a-4422-a2c0-a9ab87650132
    clientSecretKey: clientSecret
    clientSecretValue: tjEOSt3V48w845yb9SKPSC25IGGTht5TdVntS6tHPNg=
    server: https://gitea.javachen.com

server:
  host: drone.javachen.com
  adminUser: admin
  protocol: https
  alwaysAuth: true
  envSecrets:
    drone-gitea-login-secrets:
    	- DRONE_GIT_USERNAME
    	- DRONE_GIT_PASSWORD      
  kubernetes:
    enabled: true
    
persistence:
  enabled: true
  storageClass: ceph-rbd
  size: 5Gi
EOF
```

> 注意：
>
> 在rancher上先把drone命名空间移动到某一个项目，例如devops，然后在devops里面创建一个secret，名称为 drone-gitea-login-secrets，并指定作用域为 `此项目所有命名空间`，包含两个键值对：DRONE_GIT_USERNAME、DRONE_GIT_PASSWORD。然后在安装Drone，如果遇到异常，请describe pod查看日志，排查问题。

再一次运行，出现异常：

![image-20191101194520318](https://tva1.sinaimg.cn/large/006y8mN6ly1g8is16k9gtj31hs0ga77x.jpg)

这个是由于Nginx的上传文件限制在1m引起，直接修改yml文件，在指定位置加上最下面一行：

```bash
nginx.ingress.kubernetes.io/proxy-body-size: 10m
```

因为我这里是使用Helm方式安装，所以要配置drone-gitea-values.yaml文件：

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 10m
```

延伸：如果要支持websocket，则添加：

```yaml
nginx.ingress.kubernetes.io/configuration-snippet: |
  	proxy_set_header Upgrade "websocket";
  	proxy_set_header Connection "Upgrade";
```

当然，可以直接用kubectl修改：

```bash
kubectl get ingress  -n drone

kubectl edit ing drone-drone -n drone
```



# 总结

本文主要记录安装Gitea和Drone的过程，主要遇到以下几点：

- 因为k8s版本升级到1.16.2，导致仓库的yaml不能使用，所以需要手动修改chart再本地安装。
- 最新版本的Drone集成Gitea，必须配置OAuth参数，所以本文修改了Drone和Gitea的chart源码：https://github.com/javachen/charts
- 使用Ingress方式安装的Gitea，所以提交代码不能用ssh方式。使用HTTPS方式，必须设置用户名和密码，所以在k8s集群创建了 drone-gitea-login-secrets