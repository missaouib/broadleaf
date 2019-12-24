---
layout: post
title: Kubernetes资源对象之ConfigMap
date: 2019-11-08T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes]
---

在实际的应用部署中，经常需要为各种应用/中间件配置各种参数，如数据库地址、用 户名、密码等， 而且大多数生产环境中的应用程序配置较为复杂，可能是多个 Config 文件、 命令行参数和环境变量的组合。 要完成这样的任务有很多种方案， 比如: 

- 1 )可以直接在打包镜像的时候写在应用配置文件里面， 但这种方式的坏处显而易见， 因为在应用部署中往往需要修改这些配置参数， 或者说制作镜像时并不知道具体的参数配置， 一旦打包到镜像中将无法更改配置。 另外， 部分配置信息涉及安全信息(如用户名、密码等)， 打包人镜像容易导致安全隐患。 

- 2)可以在配置文件里面通过ENV环境变量传入，但是如若修改ENV就意味着要修改 yaml文件， 而且需要重启所有的容器才行。 

- 3 )可以在应用启动时在数据库或者某个特定的地方取配置文件。 

显然， 前两种方案不是最佳方案， 而第三种方案实现起来又比较麻烦。 为了解决这个难题，kubernetes 引人 ConfigMap 这个API 资源来满足这一需求。 

对于配置中心， Kubernetes 提供了 ConfigMap， 可以在容器启动的时候将配置注入环境变量或者 Volume 里面。但是唯一的缺点是，注人环境变量中的配置不能动态改变， 而在 Volume 里面的可以，只要容器中的进程有 Reload 机制，就可以实现配置的动态下发。 

ConfigMap 包含了一系列键值对， 用于存储被 Pod 或者系统组件(如 Controller)访问 的信息。 这与 Secret 的设计理念有异曲同工之妙， 它们的主要区别在于 ConfigMap 通常不用于存储敏感信息， 而只存储简单的文本信息。 

# 创建 ConfigMap 的步骤

创建 ConfigMap 的步骤如下：

- 编写 ConfigMap 配置
- 通过 kubectl 客户端提交给 Kubernetes 集群
- Kubernetes API Server 收到请求后将 配置存储到 etcd 中
- 容器启动时，kubelet 发请求给 API Server，将 ConfigMap 挂在到容器里

# 创建 ConfigMap 的方式

与Secret一样，创建ConfigMap有以下几种方式：

### 通过`--from-literal`

```bash
kubectl create secret generic db-user-pass --from-literal=username=admin --from-literal=password=123456
```

- 每个–from-literal对应一个条目

### 通过`--from-file`

分别创建两个名为username.txt和password.txt的文件：

```bash
echo -n "admin" > ./username.txt 
echo -n "123456" > ./password.txt 
kubectl create secret generic db-user-pass --from-file=./username.txt --from-file=./password.txt
```

- 每个文件内容对应一个条目

### 通过`--from-env-file`

```bash
cat << EOF > env.txt 
username=admin 
password=123456 
EOF 

kubectl create secret generic db-user-pass --from-env-file=env.txt
```

- env.txt文件的每行Key=Value对应一个条目

### 通过Yaml配置文件

Yaml文件中的数据明文输入

```bash
cat << EOF | kubectl create -f - 
apiVersion: v1 
kind: Secret 
metadata:  
  name: db-user-pass 
type: Opaque 
data:  
  username: YWRtaW4=  
  password: MTIzNDU2 
EOF
```

保存文件的方式：

```bash
cat << EOF | kubectl create -f - 
apiVersion: v1 
kind: ConfigMap 
metadata:  
  name: myconfigmap
data:  
  env.txt: |
    config1: xxx
    config2: yyy
EOF
```

查看：

```bash
$ kubectl describe configmap myconfigmap
Name:         myconfigmap
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
env.txt:
----
config1: xxx
config2: yyy

Events:  <none>


$ kubectl get configmap myconfigmap -o yaml
apiVersion: v1
data:
  env.txt: |
    config1: xxx
    config2: yyy
kind: ConfigMap
metadata:
  creationTimestamp: "2019-11-11T01:59:13Z"
  name: myconfigmap
  namespace: default
  resourceVersion: "2149503"
  selfLink: /api/v1/namespaces/default/configmaps/myconfigmap
  uid: 9f9eb942-578e-41cd-9409-7044c78cce02
```

# 使用ConfigMap

## 环境变量方式

ConfigMap可以被用来填入环境变量。看下下面的ConfigMap。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: special-config
  namespace: default
data:
  special.how: very
  special.type: charm

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: env-config
  namespace: default
data:
  log_level: INFO
```

我们可以在Pod中这样使用ConfigMap：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: gcr.io/google_containers/busybox
      command: [ "/bin/sh", "-c", "env" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: special.how
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: special.type
      envFrom:
        - configMapRef:
            name: env-config
  restartPolicy: Never
```

这个Pod运行后会输出如下几行：

```bash
SPECIAL_LEVEL_KEY=very
SPECIAL_TYPE_KEY=charm
log_level=INFO
```

## 命令行参数方式

ConfigMap也可以被使用来设置容器中的命令或者参数值。它使用的是Kubernetes的$(VAR_NAME)替换语法。我们看下下面这个ConfigMap。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: special-config
  namespace: default
data:
  special.how: very
  special.type: charm
```

为了将ConfigMap中的值注入到命令行的参数里面，我们还要像前面那个例子一样使用环境变量替换语法`${VAR_NAME)`。（其实这个东西就是给Docker容器设置环境变量，以前我创建镜像的时候经常这么玩，通过docker run的时候指定-e参数修改镜像里的环境变量，然后docker的CMD命令再利用该$(VAR_NAME)通过sed来修改配置文件或者作为命令行启动参数。）

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: gcr.io/google_containers/busybox
      command: [ "/bin/sh", "-c", "echo $(SPECIAL_LEVEL_KEY) $(SPECIAL_TYPE_KEY)" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: special.how
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: special.type
  restartPolicy: Never
```

运行这个Pod后会输出：

```bash
very charm
```

## volume方式

ConfigMap也可以在数据卷里面被使用。还是这个ConfigMap。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: special-config
  namespace: default
data:
  special.how: very
  special.type: charm
```

在数据卷里面使用这个ConfigMap，有不同的选项。最基本的就是将文件填入数据卷，在这个文件中，键就是文件名，键值就是文件内容：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: gcr.io/google_containers/busybox
      command: [ "/bin/sh", "-c", "cat /etc/config/special.how" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: special-config
  restartPolicy: Never
```

运行这个Pod的输出是`very`。

我们也可以在ConfigMap值被映射的数据卷里控制路径。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: gcr.io/google_containers/busybox
      command: [ "/bin/sh","-c","cat /etc/config/path/to/special-key" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: special-config
        items:
        - key: special.how
          path: path/to/special-key
  restartPolicy: Never
```

运行这个Pod后的结果是`very`。

# ConfigMap的热更新

ConfigMap是用来存储配置文件的kubernetes资源对象，所有的配置内容都存储在etcd中，下文主要是探究 ConfigMap 的创建和更新流程，以及对 ConfigMap 更新后容器内挂载的内容是否同步更新的测试。

## 测试示例

假设我们在 `default` namespace 下有一个名为 `nginx-config` 的 ConfigMap，可以使用 `kubectl`命令来获取：

```bash
$ kubectl get configmap nginx-config
NAME           DATA      AGE
nginx-config   1         99d
```

获取该ConfigMap的内容。

```bash
$ kubectl get configmap nginx-config -o yaml
apiVersion: v1
data:
  nginx.conf: |-
    worker_processes 1;
    events { worker_connections 1024; }
    http {
        sendfile on;
        server {
            listen 80;
            # a test endpoint that returns http 200s
            location / {
                proxy_pass http://httpstat.us/200;
                proxy_set_header  X-Real-IP  $remote_addr;
            }
        }
        server {
            listen 80;
            server_name api.hello.world;
            location / {
                proxy_pass http://l5d.default.svc.cluster.local;
                proxy_set_header Host $host;
                proxy_set_header Connection "";
                proxy_http_version 1.1;
                more_clear_input_headers 'l5d-ctx-*' 'l5d-dtab' 'l5d-sample';
            }
        }
        server {
            listen 80;
            server_name www.hello.world;
            location / {
                # allow 'employees' to perform dtab overrides
                if ($cookie_special_employee_cookie != "letmein") {
                  more_clear_input_headers 'l5d-ctx-*' 'l5d-dtab' 'l5d-sample';
                }
                # add a dtab override to get people to our beta, world-v2
                set $xheader "";
                if ($cookie_special_employee_cookie ~* "dogfood") {
                  set $xheader "/host/world => /srv/world-v2;";
                }
                proxy_set_header 'l5d-dtab' $xheader;
                proxy_pass http://l5d.default.svc.cluster.local;
                proxy_set_header Host $host;
                proxy_set_header Connection "";
                proxy_http_version 1.1;
            }
        }
    }
kind: ConfigMap
metadata:
  creationTimestamp: 2017-08-01T06:53:17Z
  name: nginx-config
  namespace: default
  resourceVersion: "14925806"
  selfLink: /api/v1/namespaces/default/configmaps/nginx-config
  uid: 18d70527-7686-11e7-bfbd-8af1e3a7c5bd
```

ConfigMap中的内容是存储到etcd中的，然后查询etcd：

```bash
ETCDCTL_API=3 etcdctl get /registry/configmaps/default/nginx-config -w json|python -m json.tool
```

注意使用 v3 版本的 etcdctl API，下面是输出结果：

```bash
{
    "count": 1,
    "header": {
        "cluster_id": 12091028579527406772,
        "member_id": 16557816780141026208,
        "raft_term": 36,
        "revision": 29258723
    },
    "kvs": [
        {
            "create_revision": 14925806,
            "key": "L3JlZ2lzdHJ5L2NvbmZpZ21hcHMvZGVmYXVsdC9uZ2lueC1jb25maWc=",
            "mod_revision": 14925806,
            "value": "azhzAAoPCgJ2MRIJQ29uZmlnTWFwEqQMClQKDG5naW54LWNvbmZpZxIAGgdkZWZhdWx0IgAqJDE4ZDcwNTI3LTc2ODYtMTFlNy1iZmJkLThhZjFlM2E3YzViZDIAOABCCwjdyoDMBRC5ss54egASywsKCm5naW54LmNvbmYSvAt3b3JrZXJfcHJvY2Vzc2VzIDE7CgpldmVudHMgeyB3b3JrZXJfY29ubmVjdGlvbnMgMTAyNDsgfQoKaHR0cCB7CiAgICBzZW5kZmlsZSBvbjsKCiAgICBzZXJ2ZXIgewogICAgICAgIGxpc3RlbiA4MDsKCiAgICAgICAgIyBhIHRlc3QgZW5kcG9pbnQgdGhhdCByZXR1cm5zIGh0dHAgMjAwcwogICAgICAgIGxvY2F0aW9uIC8gewogICAgICAgICAgICBwcm94eV9wYXNzIGh0dHA6Ly9odHRwc3RhdC51cy8yMDA7CiAgICAgICAgICAgIHByb3h5X3NldF9oZWFkZXIgIFgtUmVhbC1JUCAgJHJlbW90ZV9hZGRyOwogICAgICAgIH0KICAgIH0KCiAgICBzZXJ2ZXIgewoKICAgICAgICBsaXN0ZW4gODA7CiAgICAgICAgc2VydmVyX25hbWUgYXBpLmhlbGxvLndvcmxkOwoKICAgICAgICBsb2NhdGlvbiAvIHsKICAgICAgICAgICAgcHJveHlfcGFzcyBodHRwOi8vbDVkLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWw7CiAgICAgICAgICAgIHByb3h5X3NldF9oZWFkZXIgSG9zdCAkaG9zdDsKICAgICAgICAgICAgcHJveHlfc2V0X2hlYWRlciBDb25uZWN0aW9uICIiOwogICAgICAgICAgICBwcm94eV9odHRwX3ZlcnNpb24gMS4xOwoKICAgICAgICAgICAgbW9yZV9jbGVhcl9pbnB1dF9oZWFkZXJzICdsNWQtY3R4LSonICdsNWQtZHRhYicgJ2w1ZC1zYW1wbGUnOwogICAgICAgIH0KICAgIH0KCiAgICBzZXJ2ZXIgewoKICAgICAgICBsaXN0ZW4gODA7CiAgICAgICAgc2VydmVyX25hbWUgd3d3LmhlbGxvLndvcmxkOwoKICAgICAgICBsb2NhdGlvbiAvIHsKCgogICAgICAgICAgICAjIGFsbG93ICdlbXBsb3llZXMnIHRvIHBlcmZvcm0gZHRhYiBvdmVycmlkZXMKICAgICAgICAgICAgaWYgKCRjb29raWVfc3BlY2lhbF9lbXBsb3llZV9jb29raWUgIT0gImxldG1laW4iKSB7CiAgICAgICAgICAgICAgbW9yZV9jbGVhcl9pbnB1dF9oZWFkZXJzICdsNWQtY3R4LSonICdsNWQtZHRhYicgJ2w1ZC1zYW1wbGUnOwogICAgICAgICAgICB9CgogICAgICAgICAgICAjIGFkZCBhIGR0YWIgb3ZlcnJpZGUgdG8gZ2V0IHBlb3BsZSB0byBvdXIgYmV0YSwgd29ybGQtdjIKICAgICAgICAgICAgc2V0ICR4aGVhZGVyICIiOwoKICAgICAgICAgICAgaWYgKCRjb29raWVfc3BlY2lhbF9lbXBsb3llZV9jb29raWUgfiogImRvZ2Zvb2QiKSB7CiAgICAgICAgICAgICAgc2V0ICR4aGVhZGVyICIvaG9zdC93b3JsZCA9PiAvc3J2L3dvcmxkLXYyOyI7CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIHByb3h5X3NldF9oZWFkZXIgJ2w1ZC1kdGFiJyAkeGhlYWRlcjsKCgogICAgICAgICAgICBwcm94eV9wYXNzIGh0dHA6Ly9sNWQuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbDsKICAgICAgICAgICAgcHJveHlfc2V0X2hlYWRlciBIb3N0ICRob3N0OwogICAgICAgICAgICBwcm94eV9zZXRfaGVhZGVyIENvbm5lY3Rpb24gIiI7CiAgICAgICAgICAgIHByb3h5X2h0dHBfdmVyc2lvbiAxLjE7CiAgICAgICAgfQogICAgfQp9GgAiAA==",
            "version": 1
        }
    ]
}
```

其中的value就是 `nginx.conf` 配置文件的内容。

可以使用base64解码查看具体值，关于etcdctl的使用请参考[使用etcdctl访问kuberentes数据](https://jimmysong.io/kubernetes-handbook/guide/using-etcdctl-to-access-kubernetes-data.html)。

## 测试

分别测试使用 ConfigMap 挂载 Env 和 Volume 的情况。

### 更新使用ConfigMap挂载的Env

使用下面的配置创建 nginx 容器测试更新 ConfigMap 后容器内的环境变量是否也跟着更新。

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: harbor-001.jimmysong.io/library/nginx:1.9
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: env-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: env-config
  namespace: default
data:
  log_level: INFO
```

获取环境变量的值

```
$ kubectl exec `kubectl get pods -l run=my-nginx  -o=name|cut -d "/" -f2` env|grep log_level
log_level=INFO
```

修改 ConfigMap

```
$ kubectl edit configmap env-config
```

修改 `log_level` 的值为 `DEBUG`。

再次查看环境变量的值。

```
$ kubectl exec `kubectl get pods -l run=my-nginx  -o=name|cut -d "/" -f2` env|grep log_level
log_level=INFO
```

实践证明修改 ConfigMap 无法更新容器中已注入的环境变量信息。

### 更新使用ConfigMap挂载的Volume

使用下面的配置创建 nginx 容器测试更新 ConfigMap 后容器内挂载的文件是否也跟着更新。

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 1
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: harbor-001.jimmysong.io/library/nginx:1.9
        ports:
        - containerPort: 80
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
        - name: config-volume
          configMap:
            name: special-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: special-config
  namespace: default
data:
  log_level: INFO
$ kubectl exec `kubectl get pods -l run=my-nginx  -o=name|cut -d "/" -f2` cat /etc/config/log_level
INFO
```

修改 ConfigMap

```
$ kubectl edit configmap special-config
```

修改 `log_level` 的值为 `DEBUG`。

等待大概10秒钟时间，再次查看环境变量的值。

```
$ kubectl exec `kubectl get pods -l run=my-nginx  -o=name|cut -d "/" -f2` cat /tmp/log_level
DEBUG
```

我们可以看到使用 ConfigMap 方式挂载的 Volume 的文件中的内容已经变成了 `DEBUG`。

Known Issue： 如果使用ConfigMap的**subPath**挂载为Container的Volume，Kubernetes不会做自动热更新: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#mounted-configmaps-are-updated-automatically

## ConfigMap 更新后滚动更新 Pod

更新 ConfigMap 目前并不会触发相关 Pod 的滚动更新，可以通过修改 pod annotations 的方式强制触发滚动更新。

```
$ kubectl patch deployment my-nginx --patch '{"spec": {"template": {"metadata": {"annotations": {"version/config": "20180411" }}}}}'
```

这个例子里我们在 `.spec.template.metadata.annotations` 中添加 `version/config`，每次通过修改 `version/config` 来触发滚动更新。

# 总结

更新 ConfigMap 后：

- 使用该 ConfigMap 挂载的 Env **不会**同步更新
- 使用该 ConfigMap 挂载的 Volume 中的数据需要一段时间（实测大概10秒）才能同步更新

ENV 是在容器启动的时候注入的，启动之后 kubernetes 就不会再改变环境变量的值，且同一个 namespace 中的 pod 的环境变量是不断累加的，参考 [Kubernetes中的服务发现与docker容器间的环境变量传递源码探究](https://jimmysong.io/posts/exploring-kubernetes-env-with-docker/)。为了更新容器中使用 ConfigMap 挂载的配置，需要通过滚动更新 pod 的方式来强制重新挂载 ConfigMap。

# 参考

- [resources-reference ConfigMap v1](https://kubernetes.io/docs/resources-reference/v1.5/#configmap-v1)
- [user-guide Using ConfigMap](https://kubernetes.io/docs/user-guide/configmap/)
- [Kubernetes资源对象之ConfigMap](https://blog.frognew.com/2017/01/kubernetes-configmap.html)
- [Kubernetes 1.7 security in practice](https://acotten.com/post/kube17-security)
- [ConfigMap | kubernetes handbook - jimmysong.io](https://jimmysong.io/kubernetes-handbook/concepts/configmap.html)
- [创建高可用ectd集群 | Kubernetes handbook - jimmysong.io](https://jimmysong.io/kubernetes-handbook/practice/etcd-cluster-installation.html)
- [Kubernetes中的服务发现与docker容器间的环境变量传递源码探究](https://jimmysong.io/posts/exploring-kubernetes-env-with-docker/)
- [Automatically Roll Deployments When ConfigMaps or Secrets change](https://github.com/kubernetes/helm/blob/master/docs/charts_tips_and_tricks.md#automatically-roll-deployments-when-configmaps-or-secrets-change)

