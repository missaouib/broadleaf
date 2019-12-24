---
layout: post
title: Kubernetes容器编排示例
date: 2019-11-13T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes]
draft: true
---

# 部署 nginx 服务

![ConfigMap](https://tva1.sinaimg.cn/large/006y8mN6ly1g8wh52tgv3j31fq0ca0uv.jpg)

nginx配置文件 hello.conf

```
server {
    listen 80;
    server_name nginx.example.com;
    location / {
        include uwsgi_params;
        uwsgi_pass unix:///tmp/uwsgi.sock;
    }
}
```

创建：

```bash
kubectl create configmap nginx-conf --from-file=hello.conf
```

在部署我们的 Flask 应用之前，我先部署一个 Nginx 服务。因为这个 Flask 应用是用 uwsgi 启动的，为了应对大流量访问，通常需要在前面部署一个 Nginx 代理服务。

```bash
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.12
      ports:
        - name: http
          containerPort: 80
EOF

kubectl get pods
```

可以看到我们的 nginx pod 已经启动了，但是如果 Nginx 占用大量的内存或CPU，会影响到这台物理机上启动的其他容器，所有我们要对这个 Nginx 容器做资源限制。

```bash
cat << EOF | kubectl replace --force -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.12
      ports:
        - name: http
          containerPort: 80
      resources:
        limits:
          cpu: 1
          memory: 2Gi
        requests:
          cpu: 0
          memory: 2Gi
EOF


kubectl edit pods
```

我们给 Nginx 服务加了资源限制，但是当这个服务出现问题时，我们怎么检测到这个故障，并给他自动恢复呢？这时候就需要对这个服务进行监控了。

```bash
cat << EOF | kubectl replace --force -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.12
      ports:
        - name: http
          containerPort: 80
      resources:
        limits:
          cpu: 1
          memory: 2Gi
        requests:
          cpu: 0
          memory: 2Gi
      livenessProbe:
        tcpSocket:
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 15
        timeoutSeconds: 5
      readinessProbe:
        httpGet:
          path: /
          port: 80
          scheme: HTTP
        initialDelaySeconds: 5
        periodSeconds: 15
        timeoutSeconds: 1
EOF

kubectl edit pods
```

我们可以通过 kubectl describe 看到 pod 的具体状态。

```
kubectl describe pod nginx
```

Pod的状态Status：

- Pending：Pod 的配置已经被 API Server 存储到 etcd 中，但是此Pod因为某种原因不能被创建
- Running：Pod 已经被调度成功并且绑定到了某个节点上，容器创建成功并开始运行
- Succeeded：Pod 都正常运行完毕并已退出，这种状态一般在一次性任务中比较常见
- Faild：Pod 里至少有一个容器运行不正常（非0状态退出），需要查找Pod失败原因
- Unknown：Pod 的状态不能持续的被 kubelet 汇报给 API Server，可能是主节点也 kubelet通信问题

细分状态 Conditions：

- PodScheduled Pod 是否已经被调度，即给他分配了物理节点
- ContainersReady 容器是否已经处于 Ready 状态
- Ready Pod 是否应 Running 并且能够对外提供服务
- Initialized 是否完成了容器初始化操作
- Unschedulable 可能资源不足导致调度失败

我们对 Nginx 容器做资源限制，并且进行了监控检查，我们的 Nginx 服务就配置完成了，那我们改如何让他代理我们的 Flask 应用容器呢？答案就是讲 Nginx 容器和 Flask 应用容器运行在同一个Pod 中，两个容器通过 socket 文件进行交互。

# 部署 Flask 应用

```yaml
cat << EOF | kubectl replace --force -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.12
      ports:
        - name: http
          containerPort: 80
      resources:
        limits:
          cpu: 500m
          memory: 0.5Gi
        requests:
          cpu: 0
          memory: 0.5Gi
      livenessProbe:
        httpGet:
          path: /
          port: 80
          scheme: HTTP
        initialDelaySeconds: 5
        periodSeconds: 15
        timeoutSeconds: 5
      readinessProbe:
        httpGet:
          path: /
          port: 80
          scheme: HTTP
        initialDelaySeconds: 5
        periodSeconds: 15
        timeoutSeconds: 1
      volumeMounts:
        - name: "nginx-conf"
          mountPath: "/etc/nginx/conf.d"
        - name: "uwsgi-sock"
          mountPath: "/tmp"
    - name: flask
      image: findsec/hello:v1
      ports:
        - name: http-stats
          containerPort: 9191
      resources:
        limits:
          cpu: 500m
          memory: 100Mi
        requests:
          cpu: 0
          memory: 100Mi
      volumeMounts:
        - name: "uwsgi-sock"
          mountPath: "/tmp"
  volumes:
    - name: "uwsgi-sock"
      emptyDir: {}
    - name: "nginx-conf"
      configMap:
        name: "nginx-conf"
        items:
          - key: "hello.conf"
            path: "hello.conf"
EOF
kubectl get pods nginx
```

## 访问测试

将端口进行转发：

```
kubectl port-forward nginx 10080:80
curl http://127.0.0.1:10080
```

## 查看容器日志

```
kubectl logs -c nginx nginx
kubectl logs -c flask nginx
```

## 登录容器

```
kubectl exec -ti flask -c nginx bash
```

至此，我们运行了一个 Flask 应用，并在前面给他加个一个 Nginx 代理。但你有没有想过，当我们部署的这个 pod 挂了或者突然访问量加大了，会出现什么问题？如果 pod 挂了，那么服务就不能正常访问了，那怎么解决这个问题？多起几个pod，某一个挂了，其他仍有可以提供访问；如果访问量加大，同样也可以启动多个 pod 进行分流。

那我们应该如何启动多个 pod 呢? 答案就是 ReplicationController 和 ReplicaSet。

# ReplicationController

Replication Controller 保证了在所有时间内，都有特定数量的Pod副本正在运行，如果太多了，Replication Controller就杀死几个，如果太少了，Replication Controller会新建几个，和直接创建的pod不同的是，Replication Controller会替换掉那些删除的或者被终止的pod，不管删除的原因是什么。基于这个理由，我们建议即使是只创建一个pod，我们也要使用Replication Controller。Replication Controller 就像一个进程管理器，监管着不同node上的多个pod，而不是单单监控一个node上的pod，Replication Controller 会委派本地容器来启动一些节点上服务。

Replication Controller只会对那些RestartPolicy = Always的Pod的生效，（RestartPolicy的默认值就是Always），Replication Controller 不会去管理那些有不同启动策略pod。

在部署前，我们可以先把原先部署的 Pod 清理掉。

```
kubectl delete pod nginx
```

然后通过 ReplicationController 重新部署这个 Flask 应用。

```yaml
cat << EOF | kubectl apply -f
apiVersion: apps/v1
kind: ReplicationController
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.12
          ports:
            - name: http
              containerPort: 80
          resources:
            limits:
              cpu: 500m
              memory: 0.5Gi
            requests:
              cpu: 0
              memory: 0.5Gi
          livenessProbe:
            httpGet:
              path: /
              port: 80
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 15
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /
              port: 80
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 15
            timeoutSeconds: 1
          volumeMounts:
            - name: "nginx-conf"
              mountPath: "/etc/nginx/conf.d"
            - name: "uwsgi-sock"
              mountPath: "/tmp"
        - name: flask
          image: findsec/hello:v1
          ports:
            - name: http-stats
              containerPort: 9191
          resources:
            limits:
              cpu: 500m
              memory: 100Mi
            requests:
              cpu: 0
              memory: 100Mi
          volumeMounts:
            - name: "uwsgi-sock"
              mountPath: "/tmp"
      volumes:
        - name: "uwsgi-sock"
          emptyDir: {}
        - name: "nginx-conf"
          configMap:
            name: "nginx-conf"
            items:
              - key: "hello.conf"
                path: "hello.conf"
EOF


kubectl get rc

kubectl describe rc nginx
```

## 修改副本

然后我们通过`RC`来修改下`Pod`的副本数量为2：

```
kubectl edit rc nginx
```

## 删除一个容器

通过delete pods 的方式删除一个容器，立刻就有一个新的容器起来：

```bash
kubectl get  rc
kubectl get pod
kubectl delete pods nginx-h2qbt
kubectl get pods
kubectl get  rc
```

## scale 伸缩

```bash
kubectl scale rc nginx --replicas=2
kubectl get  rc
kubectl scale rc nginx --replicas=5
kubectl get pods -o wide
```

## 滚动升级

而且我们还可以用`RC`来进行滚动升级，比如我们将镜像地址更改为`nginx:1.15`：

```hello.yaml
kubectl rolling-update nginx --image=nginx:1.15
```

但是如果我们的`Pod`中多个容器的话，就需要通过修改`YAML`文件来进行修改了:

```bash
kubectl rolling-update nginx -f hello.yaml
```

如果升级完成后出现了新的问题，想要一键回滚到上一个版本的话，使用`RC`只能用同样的方法把镜像地址替换成之前的，然后重新滚动升级。

# ReplicaSet

随着`Kubernetes`的高速发展，官方已经推荐我们使用`RS`和`Deployment`来代替`RC`了，实际上`RS`和`RC`的功能基本一致，目前唯一的一个区别就是`RC`只支持基于等式的`selector`（env=dev或environment!=qa），但`RS`还支持基于集合的`selector`（version in (v1.0, v2.0)），这对复杂的运维管理就非常方便了。

我们通过 ReplicaSet 重新部署这个应用。

[![ReplicaSet](https://github.com/findsec-cn/k101/raw/master/docs/replicaset.jpg)](https://github.com/findsec-cn/k101/raw/master/docs/replicaset.jpg)

在部署前，我们可以先把原先部署的 Pod 清理掉。

```
kubectl delete pod nginx
```

然后通过 ReplicaSet 重新部署这个 Flask 应用。

```yaml
cat << EOF | kubectl apply -f
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.12
          ports:
            - name: http
              containerPort: 80
          resources:
            limits:
              cpu: 500m
              memory: 0.5Gi
            requests:
              cpu: 0
              memory: 0.5Gi
          livenessProbe:
            httpGet:
              path: /
              port: 80
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 15
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /
              port: 80
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 15
            timeoutSeconds: 1
          volumeMounts:
            - name: "nginx-conf"
              mountPath: "/etc/nginx/conf.d"
            - name: "uwsgi-sock"
              mountPath: "/tmp"
        - name: flask
          image: findsec/hello:v1
          ports:
            - name: http-stats
              containerPort: 9191
          resources:
            limits:
              cpu: 500m
              memory: 100Mi
            requests:
              cpu: 0
              memory: 100Mi
          volumeMounts:
            - name: "uwsgi-sock"
              mountPath: "/tmp"
      volumes:
        - name: "uwsgi-sock"
          emptyDir: {}
        - name: "nginx-conf"
          configMap:
            name: "nginx-conf"
            items:
              - key: "hello.conf"
                path: "hello.conf"
EOF


kubectl get rs

kubectl describe rs nginx
```

通过 ReplicaSet 我们实现了启动多个 Pod 副本的目的。现在我们的 Flask 应用有了新版本，我想升级它，但又不能影响用户的访问，我该怎么做？滚动升级这个特性我们改如何实现？答案就是 Deployment。

我们可以先删除rs资源，然后用 Deployment 重新部署这个应用。

```
kubectl delete ReplicaSet nginx
```

# Deployment

一个 ReplicaSet 对象，其实就是由副本数目的定义和一个 Pod 模板组成的。不难发现，它的定义其实是 Deployment 的一个子集。Deployment 控制器实际操纵的正是这样的 ReplicaSet 对象，而不是 Pod 对象。

[![Deployment](https://github.com/findsec-cn/k101/raw/master/docs/deployment.jpg)](https://github.com/findsec-cn/k101/raw/master/docs/deployment.jpg)

Deployment 与 ReplicaSet 以及 Pod 的关系是怎样的呢？ Deployment 与它的 ReplicaSet 以及 Pod 的关系，实际上是一种“层层控制”的关系。ReplicaSet 负责通过“控制器模式”，保证系统中 Pod 的个数永远等于指定的个数（比如，3 个）。这也正是 Deployment 只允许容器的 restartPolicy=Always 的主要原因：只有在容器能保证自己始终是 Running 状态的前提下，ReplicaSet 调整 Pod 的个数才有意义。而在此基础上，Deployment 同样通过“控制器模式”，来操作 ReplicaSet 的个数和属性，进而实现“水平扩展 / 收缩”和“滚动更新”这两个编排动作。

[![Rollout](https://github.com/findsec-cn/k101/raw/master/docs/rollout.jpg)](https://github.com/findsec-cn/k101/raw/master/docs/rollout.jpg)

## 创建deployment

Kubernetes支持两张方式创建资源：

- 通过kubect命令直接创建
- 通过配置文件和kubect 创建

通过 Deployment 重新部署 Flask 应用：

```yaml
cat << EOF | kubectl apply -f
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.12
          ports:
            - name: http
              containerPort: 80
          resources:
            limits:
              cpu: 500m
              memory: 0.5Gi
            requests:
              cpu: 0
              memory: 0.5Gi
          livenessProbe:
            httpGet:
              path: /
              port: 80
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 15
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /
              port: 80
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 15
            timeoutSeconds: 1
          volumeMounts:
            - name: "nginx-conf"
              mountPath: "/etc/nginx/conf.d"
            - name: "uwsgi-sock"
              mountPath: "/tmp"
        - name: flask
          image: findsec/hello:v1
          ports:
            - name: http-stats
              containerPort: 9191
          resources:
            limits:
              cpu: 500m
              memory: 100Mi
            requests:
              cpu: 0
              memory: 100Mi
          volumeMounts:
            - name: "uwsgi-sock"
              mountPath: "/tmp"
      volumes:
        - name: "uwsgi-sock"
          emptyDir: {}
        - name: "nginx-conf"
          configMap:
            name: "nginx-conf"
            items:
              - key: "hello.conf"
                path: "hello.conf"
EOF
```

## 查看deployment信息

```bash
kubectl get deployment
kubectl describe deployment/nginx
```

## scale 伸缩

修改副本数：

```
kubectl scale deploy nginx --replicas=2
kubectl get deploy
kubectl scale deploy nginx --replicas=5
kubectl get pods -o wide
```

## Failover



## 滚动升级

升级Flask 应用，查看滚动升级的过程：

```yaml
cat << EOF | kubectl apply -f
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.12
          ports:
            - name: http
              containerPort: 80
          resources:
            limits:
              cpu: 500m
              memory: 0.5Gi
            requests:
              cpu: 0
              memory: 0.5Gi
          livenessProbe:
            httpGet:
              path: /
              port: 80
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 15
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /
              port: 80
              scheme: HTTP
            initialDelaySeconds: 5
            periodSeconds: 15
            timeoutSeconds: 1
          volumeMounts:
            - name: "nginx-conf"
              mountPath: "/etc/nginx/conf.d"
        - name: flask
          image: findsec/hello:v2
          env:
            - name: UWSGI_CHEAPER
              value: "5"
          ports:
            - name: tcp
              containerPort: 8000
              protocol: TCP
            - name: http-stats
              containerPort: 9191
          resources:
            limits:
              cpu: 500m
              memory: 100Mi
            requests:
              cpu: 0
              memory: 100Mi
      volumes:
        - name: "nginx-conf"
          configMap:
            name: "nginx-conf-v2"
            items:
              - key: "hello-v2.conf"
                path: "hello.conf"
EOF

kubectl get deployment
```

hello-v2.conf

```
server {
    listen 80;
    server_name nginx.example.com;
    location / {
        include uwsgi_params;
        uwsgi_pass 127.0.0.1:8000;
    }
}
```

- 针对目前的nginx1.12升级成1.15的命令，老的下面自动移除了，全部都在新的下面。

```
kubectl set image deploy nginx nginx=nginx:1.15
kubectl get deploy
kubectl get deploy -o wide
kubectl get pods
```

- deployment查看历史版本

```
kubectl rollout history deploy nginx
```

- deployment 回滚到之前的版本
  \>又变成了nginx 1.12

```
kubectl rollout undo deploy nginx
```

## 用label控制pod的位置

默认情况下，调度 pod 时会用到所有可用的 node，但有些情况我们希望将 pod 部署到指定的 node，例如部署到 SSD 磁盘的 node，可以通过 label 实现这个功能。

任何资源都可以设置 label，我们可以给 node 设置 label，在部署 pod 时指定 label，就实现了在特定 node 上的部署。

给 node 添加 label：

```undefined
kubectl label node n1 disktype=ssd
```

查看 node 的 label 信息：

```csharp
kubectl get node --show-labels
```

配置文件中指定 label 选择器：

```cpp
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: web_server
    spec:
      containers:
        - name: nginx
          image: nginx:1.15
      nodeSelector:
        disktype: ssd
```

删除 label disktype：

```undefined
kubectl label node n1 disktype-
```

`-` 即删除。

不过Pod此时并不会重新部署，除非删掉nodeSelector，然后通过kubectl apply重新部署。

# DaemonSet

Deployment部署的副本Pod会分布在各个Node节点上，每个Node都可能会运行好几个副本。DaemonSet的不同之处在于：每个Node上最多只能运行一个副本。

Deployment的典型应用场景：

- 在集群每个节点上运行存储 Daemon，比如：ceph
- 每个节点上运行日志收集 Daemon，比如：flunentd或者 logstash
- 每个节点上运行监控  Daemon，比如 clllectd

其实，Kubernetes自己就在用 DaemonSet运行系统组件：

```
kubectl get daemonset -n kube-system

kubectl get daemonset calico-node -o yaml -n kube-system
```

# StatefulSet

StatefulSet能够保证Pod的每个副本在整个生命周期中名称是不变的。

# Service

## 为什么需要 Service

集群中的每一个 Pod 都可以通过 Pod IP 直接访问，但是正如我们所看到的，Kubernetes 中的 Pod 是有生命周期的，尤其是被 ReplicaSet、Deployment 等对象管理的 Pod，随时都有可能被销毁和重建。这就会出现一个问题，当 Kuberentes 集群中的一些 Pod 需要为另外的一些 Pod 提供服务时，我们如何为这组 Pod 建立一个抽象让另一组 Pod 找到它。这个抽象在 Kubernetes 中其实就是 Service，每一个 Service 都是一组 Pod 的逻辑集合和访问方式的抽象。即 Service 至少帮我们解决了如下问题：

- 对外暴露部署的应用
- 为一组 Pod 提供负载均衡功能
- 监控 Pod 中启动容器的健康状况，不健康则踢除
- 将服务名注册到 DNS 中去

[![Pods to Pods](https://github.com/findsec-cn/k101/raw/master/docs/pods-to-pods.jpg)](https://github.com/findsec-cn/k101/raw/master/docs/pods-to-pods.jpg)

## 如何暴露 Service

### 内部访问方式

Kubernetes 中的 Service 对象将一组 Pod 以统一的形式对外暴露成一个服务，它利用运行在内核空间的 iptables 或 ipvs 高效地转发来自节点内部和外部的流量。

[![Pods to Service](https://github.com/findsec-cn/k101/raw/master/docs/pods-to-service.jpg)](https://github.com/findsec-cn/k101/raw/master/docs/pods-to-service.jpg)

对于每一个 Service，会在节点上添加 iptables 规则，通过 iptables 或 ipvs 将流量转发到后端的 Pod 进行处理。

[![Service](https://github.com/findsec-cn/k101/raw/master/docs/service.jpg)](https://github.com/findsec-cn/k101/raw/master/docs/service.jpg)

在集群的内部我们可以通过这个 ClusterIP 访问这组 Pod 提供的服务，集群外部无法访问它。在某些场景下我们可以使用 Kubernetes 的 Proxy 模式来访问服务，比如调试服务时。

![img](https://tva1.sinaimg.cn/large/006y8mN6ly1g8u3jd815ij30ec0fc3ym.jpg)

那如何在集群外部访问这个服务呢？

### 外部访问方式

kubectl expoese命令，会给我们的pod创建一个Service，供外部访问。Service 主要有三种类型：

1. NodePort
2. LoadBalancer
3. Ingress

#### NodePort

这里最常用的一种方式就是：NodePort。在这个 Service 的定义里，通过声明它的类型为 type=NodePort。当我们配置了 NodePort 这种服务类型后，Kubernetes 会在每个物理节点上生成 iptables 规则，将相应端口的流量导入到集群内部，这样我们就可以在集群外部访问到这个服务了。

另外一种类型叫 LoadBalancer，这个适用于公有云上的 Kubernetes 对外暴露服务。

![NodePort](https://github.com/findsec-cn/k101/raw/master/docs/service-nodeport.jpg)

NodePort 服务特征如下：

- 每个端口只能是一种服务
- 端口范围只能是 30000-32767（可调）
- 不在 YAML 配置文件中指定则会分配一个默认端口

> **建议：** 不要在生产环境中使用这种方式暴露服务，大多数时候我们应该让 Kubernetes 来选择端口

![img](https://tva1.sinaimg.cn/large/006y8mN6ly1g8u3ly6s2zj30ec0hbwer.jpg)

#### LoadBalancer

LoadBalancer 服务是暴露服务到 Internet 的标准方式。所有通往你指定的端口的流量都会被转发到对应的服务。它没有过滤条件，没有路由等。这意味着你几乎可以发送任何种类的流量到该服务，像 HTTP，TCP，UDP，WebSocket，gRPC 或其它任意种类。

![img](https://cdn.nlark.com/yuque/0/2019/png/462325/1568266637350-1969467a-7f35-4fb5-baac-4c9b0a3c2e3d.png)

#### Ingress

Ingress 事实上不是一种服务类型。相反，它处于多个服务的前端，扮演着 “智能路由” 或者集群入口的角色。你可以用 Ingress 来做许多不同的事情，各种不同类型的 Ingress 控制器也有不同的能力。它允许你基于路径或者子域名来路由流量到后端服务。

Ingress 可能是暴露服务的最强大方式，但同时也是最复杂的。Ingress 控制器有各种类型，包括 Google Cloud Load Balancer， Nginx，Contour，Istio，等等。它还有各种插件，比如 cert-manager (它可以为你的服务自动提供 SSL 证书)/

如果你想要使用同一个 IP 暴露多个服务，这些服务都是使用相同的七层协议（典型如 HTTP），你还可以获取各种开箱即用的特性（比如 SSL、认证、路由等等）

![img](https://cdn.nlark.com/yuque/0/2019/png/462325/1568266637023-d81c0741-7469-47fa-9a74-71f0d5061c05.png)

通常情况下，Service 和 Pod 的 IP 仅可在集群内部访问。集群外部的请求需要通过负载均衡转发到 Service 在 Node 上暴露的 NodePort 上，然后再由 kube-proxy 通过边缘路由器 (edge router) 将其转发给相关的 Pod 或者丢弃。而 Ingress 就是为进入集群的请求提供路由规则的集合

Ingress 可以给 Service 提供集群外部访问的 URL、负载均衡、SSL 终止、HTTP 路由等。为了配置这些 Ingress 规则，集群管理员需要部署一个 Ingress Controller，它监听 Ingress 和 Service 的变化，并根据规则配置负载均衡并提供访问入口。

## 服务发现

我们通过 Service 这个抽象对外暴露服务，但还有一个问题，在 Kubernetes 集群中，A 服务访问 B 服务，如果 B 服务是一个还未部署的服务，这时，我们是不知道 B 服务的 ClusterIP 是什么的？那我在编写 A 服务的代码时，如何描述 B 服务呢？其实，我们可以给这个服务定义一个名字，当 B 服务部署时自动解析这个名字就可以了。这就是 Kubernetes 内部的服务发现机制。Service 被分配了 ClusterIP 后，还会将自己的服务名注册到 DNS 中，这样其他服务就可以通过这个服务名访问到这个服务了。如果 A、B 两个服务在相同的命名空间，那么他们通过 svc_name 就可以相互访问了（如上例：hello），如果是在不同的命名空间还需要加上命名空间的名字，如 svc_name.namespace（如上例：hello.default），或者使用完整域名去访问，一般是 svc_name.namespace.svc.cluster.local（如上例：hello.default.svc.cluster.local）。

## 如何配置 Service

### deployment 端口暴露

可以使用端口暴露的方式，部署service

```bash
kubectl get node
kubectl get node -o wide
kubectl expose deploy nginx --type=NodePort
#查看node节点暴露的端口30960
kubectl get svc


kubectl expose deploy nginx --port=80 --type=LoadBalancer

kubectl port-forward nginx 8080:80
```

### 部署 Service

也可以直接创建：

```yaml
cat << EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
EOF
```

### 获取 Service 的 Endpoint

```
kubectl get endpoints nginx
```

### 获取 Service

```
kubectl get svc nginx
```

### 访问 Service

```
minikube ssh
curl https://127.0.0.1:30080
```

# Ingress

## 安装 Nginx Ingress Controller

Ingress Controller 有许多种，我们选择最熟悉的 Nginx 来处理请求，其它可以参考 [官方文档](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

- 下载 Nginx Ingress Controller 配置文件

```
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
```

- 修改配置文件，找到配置如下位置 (搜索 `serviceAccountName`) 在下面增加一句 `hostNetwork: true`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  # 可以部署多个实例
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      serviceAccountName: nginx-ingress-serviceaccount
      # 增加 hostNetwork: true，意思是开启主机网络模式，暴露 Nginx 服务端口 80
      hostNetwork: true
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.24.1
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
// 以下代码省略...
```

部署：

```bash
kubectl create -f mandatory.yaml
```

## 部署 Ingress

```bash
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: nginx-web
  annotations:
    # 指定 Ingress Controller 的类型
    kubernetes.io/ingress.class: "nginx"
    # 指定我们的 rules 的 path 可以使用正则表达式
    nginx.ingress.kubernetes.io/use-regex: "true"
    # 连接超时时间，默认为 5s
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "600"
    # 后端服务器回转数据超时时间，默认为 60s
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    # 后端服务器响应超时时间，默认为 60s
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    # 客户端上传文件，最大大小，默认为 20m
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    # URL 重写
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  # 路由规则
  rules:
  # 主机名，只能是域名，修改为你自己的
  - host: k8s.example.com
    http:
      paths:
      - path:
        backend:
          # 后台部署的 Service Name，与上面部署的 Tomcat 对应
          serviceName: tomcat-http
          # 后台部署的 Service Port，与上面部署的 Tomcat 对应
          servicePort: 8080
```

## 查看 Ingress

## 查看 Nginx Ingress Controller

## 测试访问

成功代理到 Tomcat 即表示成功

```bash
# 不设置 Hosts 的方式请求地址，下面的 IP 和 Host 均在上面有配置
curl -v http://192.168.56.111 -H 'host: k8s.example.com'
```

# 总结

Controller一个有以下几种：

- ReplicationController
- ReplicaSet
- DaemonSet
- Deployment
- StatefulSet
- Job
