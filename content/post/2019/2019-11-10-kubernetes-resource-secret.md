---
layout: post
title: Kubernetes资源对象之Secret
date: 2019-11-10T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes]
---

Secret 对象类型用来保存敏感信息，例如密码、OAuth 令牌和 ssh key。将这些信息放在 secret 中比放在 pod 的定义中或者 docker 镜像中来说更加安全和灵活。

# Secret类型

Secret可以以Volume或者环境变量的方式使用。

Secret有三种类型：

- **Service Account** ：用来访问Kubernetes API，由Kubernetes自动创建，并且会自动挂载到Pod的`/run/secrets/kubernetes.io/serviceaccount`目录中；
- **Opaque** ：base64编码格式的Secret，用来存储密码、密钥等；
- **kubernetes.io/dockerconfigjson** ：用来存储私有docker registry的认证信息。

## Service Account Secret

Service Account概念的引入是基于这样的使用场景：运行在pod里的进程需要调用Kubernetes API以及非Kubernetes API的其它服务。Service Account它并不是给kubernetes集群的用户使用的，而是给pod里面的进程使用的，它为pod提供必要的身份认证。

为了能从Pod内部访问Kubernetes API，Kubernetes提供了Service Account资源。 Service Account会自动创建和挂载访问Kubernetes API的Secret，会挂载到Pod的 /var/run/secrets/kubernetes.io/serviceaccount目录中。

```bash
$ kubectl get sa
NAME      SECRETS   AGE
default   1         2d2h
```

如果kubernetes开启了ServiceAccount（–admission_control=…,ServiceAccount,… ）那么会在每个namespace下面都会创建一个默认的default的sa。
如下，其中最重要的就是secrets，它是每个sa下面都会拥有的一个加密的token。

```bash
$ kubectl get sa  default  -o yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2019-11-06T03:19:38Z"
  name: default
  namespace: default
  resourceVersion: "266"
  selfLink: /api/v1/namespaces/default/serviceaccounts/default
  uid: d7760016-acf9-4e4a-8c01-360abd5f9bc7
secrets:
- name: default-token-n768c
```

查看secret：

```bash
$ kubectl get secret default-token-n768c -o yaml
apiVersion: v1
data:
  ca.crt: LS0tLS1CRUdJTiBDRV
  namespace: ZGVmYXVsdA==
  token: ZXlKaGJHY2lPaUpTVXpQ1RB
kind: Secret
metadata:
  annotations:
    kubernetes.io/service-account.name: default
    kubernetes.io/service-account.uid: d7760016-acf9-4e4a-8c01-360abd5f9bc7
  creationTimestamp: "2019-11-06T03:19:38Z"
  name: default-token-n768c
  namespace: default
  resourceVersion: "265"
  selfLink: /api/v1/namespaces/default/secrets/default-token-n768c
  uid: 2a4680de-636a-456f-98ca-c9426e9fd722
type: kubernetes.io/service-account-token
```

上面的内容是经过base64加密过后的，我们直接进入容器内：



当用户在该namespace下创建pod的时候都会默认使用这个sa，下面是get pod 截取的部分，可以看到kubernetes会把默认的sa挂载到容器内。

```bash
$ kubectl get pod
NAME      READY   STATUS    RESTARTS   AGE
example   1/1     Running   0          40m
```

查看描述：

```bash
$ kubectl get pod example -o yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    cni.projectcalico.org/podIP: 10.42.8.160/32
  creationTimestamp: "2019-11-08T04:52:44Z"
  labels:
    app: example
  name: example
  namespace: default
  resourceVersion: "140553"
  selfLink: /api/v1/namespaces/default/pods/example
  uid: 85c3f9b7-210e-4d38-a9bf-7faae11af273
spec:
  containers:
  - env:
    - name: SECRET_USERNAME
      valueFrom:
        secretKeyRef:
          key: username
          name: db-user-pass
    - name: SECRET_PASSWORD
      valueFrom:
        secretKeyRef:
          key: password
          name: db-user-pass
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    name: nginx
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-n768c
      readOnly: true
```

我们之间进入容器，查看挂载：

```bash
$ kubectl exec -it example sh
# ls -l /var/run/secrets/kubernetes.io/serviceaccount
total 0
lrwxrwxrwx 1 root root 13 Nov  8 04:52 ca.crt -> ..data/ca.crt
lrwxrwxrwx 1 root root 16 Nov  8 04:52 namespace -> ..data/namespace
lrwxrwxrwx 1 root root 12 Nov  8 04:52 token -> ..data/token
```

可以看到已将ca.crt 、namespace和token放到容器内了，那么这个容器就可以通过https的请求访问apiserver了。

## Opaque

Opaue类型的Secret是一个map结构，用来存储密码、密钥等，其中vlaue要求以base64格式编码。

创建Opaue类型的Secret有以下几种方式：

### 通过`--from-literal`

```bash
kubectl create secret generic db-user-pass --from-literal=username=admin --from-literal=password=123456
```

- 每个--from-literal对应一个条目

- `$, \, *,  !` 这些字符需要转义，可以用单引号括起来，例如，对于密码 `S!B\*d$zDsb`

  ```bash
  kubectl create secret generic dev-db-secret --from-literal=username=devuser --from-literal=password='S!B\*d$zDsb'
  ```

  

查看描述：

```bash
$ kubectl describe secret db-user-pass
Name:         db-user-pass
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
password:  6 bytes
username:  5 bytes
```

- 注意：观察Data的key

### 通过`--from-file`

分别创建两个名为username.txt和password.txt的文件：

```bash
echo -n "admin" > ./username.txt
echo -n "123456" > ./password.txt

kubectl create secret generic db-user-pass --from-file=./username.txt --from-file=./password.txt
```

- 每个文件内容对应一个条目

查看描述：

```bash
kubectl describe secret db-user-pass
Name:         db-user-pass
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
username.txt:  5 bytes
password.txt:  6 bytes
```

- 注意：观察Data的key

### 通过`--from-env-file`

```bash
cat << EOF > env.txt
username=admin
password=123456
EOF

kubectl create secret generic db-user-pass --from-env-file=env.txt
```

- env.txt文件的每行Key=Value对应一个条目

​	查看描述：

```bash
kubectl describe secret db-user-pass
Name:         db-user-pass
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
password:  6 bytes
username:  5 bytes
```

### 通过Yaml配置文件

Yaml文件中的数据必须是通过Base64编码的内容：

```bash
echo -n "admin" | base64
YWRtaW4=

echo -n "123456" | base64
MTIzNDU2
```

创建secret：

```yaml
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

查看描述：

```bash
$ kubectl describe secret db-user-pass
Name:         db-user-pass
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
password:  6 bytes
username:  5 bytes
```



一个特别的例子，是保存一个配置文件：

```
apiUrl: "https://my.api.com/api/v1"
username: "user"
password: "password"
```

你可以将配置文件这样保存在secret：

```yaml
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
stringData:
  config.yaml: |-
    apiUrl: "https://my.api.com/api/v1"
    username: {{username}}
    password: {{password}}
EOF
```

{{username}} 和 {{password}} 模板里的变量在运行kubectl apply时会被替换

查看Secret：

```bash
$ kubectl get secret mysecret -o yaml
apiVersion: v1
data:
  config.yaml: YXBpVXJsOiAiaHR0cHM6Ly9teS5hcGkuY29tL2FwaS92MSIKdXNlcm5hbWU6IHt7dXNlcm5hbWV9fQpwYXNzd29yZDoge3twYXNzd29yZH19
kind: Secret
metadata:
  creationTimestamp: "2019-11-08T05:56:44Z"
  name: mysecret
  namespace: default
  resourceVersion: "153340"
  selfLink: /api/v1/namespaces/default/secrets/mysecret
  uid: 63c6d1ac-6d4c-4e2d-b6c7-b93b96dffa70
type: Opaque
```

如果同时定义data和stringData，则stringData里面的值会被使用：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  username: YWRtaW4=
stringData:
  username: administrator
```

结果：

```yaml
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: 2018-11-15T20:46:46Z
  name: mysecret
  namespace: default
  resourceVersion: "7579"
  uid: 91460ecb-e917-11e8-98f2-025000000001
type: Opaque
data:
  username: YWRtaW5pc3RyYXRvcg==
```

`YWRtaW5pc3RyYXRvcg==` 解码后的值为 `administrator`

### 通过Kustomize Generator创建

kubernetes v1.14之后支持[managing objects using Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)

在一个目录，创建kustomization.yaml：

```bash
mkdir kustomization && cd kustomization
echo -n "admin" > ./username.txt
echo -n "123456" > ./password.txt

# Create a kustomization.yaml file with SecretGenerator
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: db-user-pass
  files:
  - username.txt
  - password.txt
EOF
```

在kustomization目录创建Secret：

```bash
$ kubectl apply -k .
secret/db-user-pass-hh9ft6h8f9 created
```

查看：

```bash
$ kubectl get secrets
NAME                      TYPE                                  DATA   AGE
db-user-pass-hh9ft6h8f9   Opaque                                2      16s

$ kubectl describe secrets/db-user-pass-hh9ft6h8f9
Name:         db-user-pass-hh9ft6h8f9
Namespace:    default
Labels:       <none>
Annotations:
Type:         Opaque

Data
====
password.txt:  6 bytes
username.txt:  5 bytes
```

也可以改为literals的方式：

```yaml
# Create a kustomization.yaml file with SecretGenerator
$ cat <<EOF >./kustomization.yaml
secretGenerator:
- name: db-user-pass
  literals:
  - username=admin
  - password=123456
EOF
```



## kubernetes.io/dockercfg Secret

kubernetes.io/dockercfg类型的Secret用于存放私有Docker Registry的认证信息。 当Kubernetes在创建Pod并且需要从私有Docker Registry pull镜像时，需要使用认证信息，就会用到kubernetes.io/dockercfg类型的Secret。

创建Harbor访问Secret：

```bash
kubectl create secret docker-registry harbor-registry-secret \
   -n harbor \
	--docker-server=harbor.javachen.space  \
	--docker-username=admin \
	--docker-password=admin123
```

查看描述：

```bash
$ kubectl describe secret harbor-registry-secre -n harbor
Name:         harbor-registry-secret
Namespace:    harbor
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/dockerconfigjson

Data
====
.dockerconfigjson:  112 bytes
```



在创建Pod时需要在Pod的spec设置imagePullSecrets，指定访问Docker Registry的登录信息：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tomcat
spec:
  containers:
    - name: tomcat
      image: harbor.javachen.space/soft/tomcat
  imagePullSecrets:
    - name: harbor-registry-secret
```

或者是在Deployment中指定：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tomcat
  template:
    metadata:
      labels:
        app: tomcat
    spec:
      imagePullSecrets:
        #登陆秘钥
        - name: harbor-registry-secret
      containers:
        - name: tomcat
          image: harbor.javachen.space/soft/tomcat
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 80
```

# 查看Secret

通过kubectl get secret查看：

```bash
$ kubectl get secret db-user-pass
NAME           TYPE     DATA   AGE
db-user-pass   Opaque   2      2s
```

查看描述信息：

```bash
kubectl describe  secret db-user-pass
Name:         db-user-pass
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
password:  6 bytes
username:  5 bytes
```

以yaml方式查看：

```bash
$ kubectl get secret db-user-pass -o yaml
apiVersion: v1
data:
  password: MTIzNDU2
  username: YWRtaW4=
kind: Secret
metadata:
  creationTimestamp: "2019-11-08T03:51:15Z"
  name: db-user-pass
  namespace: default
  resourceVersion: "131293"
  selfLink: /api/v1/namespaces/default/secrets/db-user-pass
  uid: fec15a8d-9d2d-46ff-abc9-1709d013a8da
type: Opaque
```

通过Base64将数据反编码：

```bash
$ echo -n "MTIzNDU2" | base64 --decode
123456
```

也可以修改：

```bash
kubectl edit secret db-user-pass
```

# 使用Secret

Secret 可以作为数据卷被挂载，或作为环境变量暴露出来以供 pod 中的容器使用。它们也可以被系统的其他部分使用，而不直接暴露在 pod 内。例如，它们可以保存凭据，系统的其他部分应该用它来代表您与外部系统进行交互。

## 在Pod中使用

### Volume方式

在 Pod 中的 volume 里使用 Secret：

1. 创建一个 secret 或者使用已有的 secret。多个 pod 可以引用同一个 secret。
2. 修改您的 pod 的定义在 `spec.volumes[]` 下增加一个 volume。可以给这个 volume 随意命名，它的 `spec.volumes[].secret.secretName` 必须等于 secret 对象的名字。
3. 将 `spec.containers[].volumeMounts[]` 加到需要用到该 secret 的容器中。指定 `spec.containers[].volumeMounts[].readOnly = true` 和 `spec.containers[].volumeMounts[].mountPath` 为您想要该 secret 出现的尚未使用的目录。
4. 修改您的镜像并且／或者命令行让程序从该目录下寻找文件。Secret 的 `data` 映射中的每一个键都成为了 `mountPath` 下的一个文件名。

```yaml
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: example
  namespace: default
  labels:
    app: example
spec:
  containers:
  - name: nginx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: foo
      mountPath: /etc/foo
      readOnly: true
  volumes:
  - name: foo
    secret:
      secretName: db-user-pass
EOF
```

您想要用的每个 secret 都需要在 `spec.volumes` 中指明。

如果 pod 中有多个容器，每个容器都需要自己的 `volumeMounts` 配置块，但是每个 secret 只需要一个 `spec.volumes`。

您可以打包多个文件到一个 secret 中，或者使用的多个 secret，怎样方便就怎样来。



进入容器，查看：

```bash
kubectl exec -it example sh
# ls /etc/foo
password  username
# cat /etc/foo/username
admin
# cat /etc/foo/password
123456
```

可以看到，Kubernetes会在指定的路径/etc/foo下为每条敏感数据创建一个文件，文件名就是数据条目的key，这里是/etc/foo/username和/etc/foo/password，value则以明文存放在文件中。

我们也可以自定义存放数据的文件名，比如：

```bash
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: example
  namespace: default
  labels:
    app: example
spec:
  containers:
  - name: nginx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: foo
      mountPath: /etc/foo
      readOnly: true
  volumes:
  - name: foo
    secret: db-user-pass
    items:
    - key: username
      path: my-group/my-username
    - key: password
      path: my-group/my-password 
EOF
```

这时候数据分别存放在/etc/foo/my-group/my-username和/etc/foo/my-group/my-password。



定义**Secret**文件的权限：

您还可以指定 secret 将拥有的权限模式位文件。如果不指定，默认使用 `0644`。您可以为整个保密卷指定默认模式，如果需要，可以覆盖每个密钥。

```yaml
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: example
  namespace: default
  labels:
    app: example
spec:
  containers:
  - name: nginx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: foo
      mountPath: /etc/foo
      readOnly: true
  volumes:
  - name: foo
    secret:
      secretName: db-user-pass
      defaultMode: 256
EOF
```

然后，secret 将被挂载到 `/etc/foo` 目录，所有通过该 secret volume 挂载创建的文件的权限都是 `0400`。

请注意，JSON 规范不支持八进制符号，因此使用 256 值作为 0400 权限。如果您使用 yaml 而不是 json 作为 pod，则可以使用八进制符号以更自然的方式指定权限。

您还可以是用映射，如上一个示例，并为不同的文件指定不同的权限，如下所示：

```bash
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: example
  namespace: default
  labels:
    app: example
spec:
  containers:
  - name: nginx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: foo
      mountPath: /etc/foo
      readOnly: true
  volumes:
  - name: foo
    secret: db-user-pass
    items:
    - key: username
      path: my-group/my-username
      mode: 511
    - key: password
      path: my-group/my-password 
EOF
```

在这种情况下，导致 `/etc/foo/my-group/my-username` 的文件的权限值为 `0777`。由于 JSON 限制，必须以十进制格式指定模式。



**挂载的 secret 被自动更新**

以Volume方式使用的Secret支持动态更新：Secret更新后，容器中的数据也会更新。将password更新为abcdef，base64编码为 YWJjZGVm：

```bash
$ kubectl edit secret db-user-pass
apiVersion: v1
data:
  password: YWJjZGVm
  username: YWRtaW4=
kind: Secret
metadata:
  creationTimestamp: "2019-11-08T03:51:15Z"
  name: db-user-pass
  namespace: default
  resourceVersion: "138726"
  selfLink: /api/v1/namespaces/default/secrets/db-user-pass
  uid: fec15a8d-9d2d-46ff-abc9-1709d013a8da
type: Opaque
```

几分钟后，新的password会同步到容器：

```bash
$ kubectl exec -it example sh
# cat /etc/foo/password
abcde
```

### 环境变量方式

将 secret 作为 pod 中的环境变量使用：

1. 创建一个 secret 或者使用一个已存在的 secret。多个 pod 可以引用同一个 secret。
2. 在每个容器中修改您想要使用 secret key 的 Pod 定义，为要使用的每个 secret key 添加一个环境变量。消费secret key 的环境变量应填充 secret 的名称，并键入 `env[x].valueFrom.secretKeyRef`。
3. 修改镜像并／或者命令行，以便程序在指定的环境变量中查找值。

```bash
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: example
  namespace: default
  labels:
    app: example
spec:
  containers:
  - name: nginx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    env:
  	  - name: SECRET_USERNAME
  	    valueFrom:
  	      secretKeyRef:
  	        name: db-user-pass
  	        key: username
  	  - name: SECRET_PASSWORD
  	    valueFrom:
  	      secretKeyRef:
  	        name: db-user-pass
  	        key: password
EOF
```

进入容器查看：

```bash
$ kubectl exec -it example sh
# echo $SECRET_USERNAME
admin
# echo $SECRET_PASSWORD
abcdef
```

注意：环境变量读取Secret很方便，但不支持动态更新。

# 使用案例

## Pod with ssh keys

```
kubectl create secret generic ssh-key-secret --from-file=ssh-privatekey=/path/to/.ssh/id_rsa --from-file=ssh-publickey=/path/to/.ssh/id_rsa.pub
```

创建一个pod：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-test-pod
  labels:
    name: secret-test
spec:
  volumes:
  - name: secret-volume
    secret:
      secretName: ssh-key-secret
  containers:
  - name: ssh-test-container
    image: mySshImage
    volumeMounts:
    - name: secret-volume
      readOnly: true
      mountPath: "/etc/secret-volume"
```

当容器运行成功之后，就会生成两个文件：

```
/etc/secret-volume/ssh-publickey
/etc/secret-volume/ssh-privatekey
```

这样，容器就可以使用Secret和宿主机建立SSH连接。注意：这样是由风险的，建议使用 service account。

## Pods with prod / test credentials

创建生产和测试环境Secret：

```
kubectl create secret generic prod-db-secret --from-literal=username=produser --from-literal=password=Y4nys7f11

kubectl create secret generic test-db-secret --from-literal=username=testuser --from-literal=password=iluvtests
```

创建pod.yaml：

```bash
$ cat <<EOF > pod.yaml
apiVersion: v1
kind: List
items:
- kind: Pod
  apiVersion: v1
  metadata:
    name: prod-db-client-pod
    labels:
      name: prod-db-client
  spec:
    volumes:
    - name: secret-volume
      secret:
        secretName: prod-db-secret
    containers:
    - name: db-client-container
      image: myClientImage
      volumeMounts:
      - name: secret-volume
        readOnly: true
        mountPath: "/etc/secret-volume"
- kind: Pod
  apiVersion: v1
  metadata:
    name: test-db-client-pod
    labels:
      name: test-db-client
  spec:
    volumes:
    - name: secret-volume
      secret:
        secretName: test-db-secret
    containers:
    - name: db-client-container
      image: myClientImage
      volumeMounts:
      - name: secret-volume
        readOnly: true
        mountPath: "/etc/secret-volume"
EOF
```

创建Pod：

```bash
kubectl apply -f pod.yaml
```

执行成功后，每个容器都会挂载 ：

```
/etc/secret-volume/username
/etc/secret-volume/password
```

进一步，可以在pod里面定义两个Service Accounts：prod-user使用prod-db-secret；test-user使用test-db-secret，然后配置文件可以简写为：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: prod-db-client-pod
  labels:
    name: prod-db-client
spec:
  serviceAccount: prod-db-client
  containers:
  - name: db-client-container
    image: myClientImage
```

## Dotfiles in secret volume

```bash
apiVersion: v1
kind: Secret
metadata:
  name: dotfile-secret
data:
  .secret-file: dmFsdWUtMg0KDQo=
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-dotfiles-pod
spec:
  volumes:
  - name: secret-volume
    secret:
      secretName: dotfile-secret
  containers:
  - name: dotfile-test-container
    image: k8s.gcr.io/busybox
    command:
    - ls
    - "-l"
    - "/etc/secret-volume"
    volumeMounts:
    - name: secret-volume
      readOnly: true
      mountPath: "/etc/secret-volume"
```

# 总结

清理文件：

```
kubectl delete secret mysecret db-user-pass db-user-pass-hh9ft6h8f9
```

# 参考文章

- [kubernetes的Service Account和secret](https://www.cnblogs.com/tylerzhou/p/11027584.html)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
