---
layout: post
title: Kubernetes存储之Volume
date: 2019-11-12T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes]
---

容器和Pod生命周期可能很短，会被频繁销毁和创建。容器销毁时，保存在容器的内部文件系统中的数据都会被清楚。

为了持久化保存容器的数据，可以使用 Kubernetes Volume。

Volume 的生命周期独立于容器，Pod中的容器可能会销毁和重建，但Volume会被保留。



使用卷时，Pod 声明中需要提供卷的类型 (`.spec.volumes` 字段)和卷挂载的位置 (`.spec.containers.volumeMounts` 字段)。

# Volume 类型

本质上，Kubernetes Volume是一个目录，这一点与Docker Volume类似。当Volume被mount到Pod，Pod中的所有容器都可以访问这个Volume。

Kubernetes提供了许多Volume类型：

- [awsElasticBlockStore](https://kubernetes.io/zh/docs/concepts/storage/volumes/#awselasticblockstore)
- [azureDisk](https://kubernetes.io/zh/docs/concepts/storage/volumes/#azuredisk)
- [azureFile](https://kubernetes.io/zh/docs/concepts/storage/volumes/#azurefile)
- [cephfs](https://kubernetes.io/zh/docs/concepts/storage/volumes/#cephfs)
- [cinder](https://kubernetes.io/zh/docs/concepts/storage/volumes/#cinder)
- [configMap](https://kubernetes.io/zh/docs/concepts/storage/volumes/#configmap)
- [csi](https://kubernetes.io/zh/docs/concepts/storage/volumes/#csi)
- [downwardAPI](https://kubernetes.io/zh/docs/concepts/storage/volumes/#downwardapi)
- [emptyDir](https://kubernetes.io/zh/docs/concepts/storage/volumes/#emptydir)
- [fc (fibre channel)](https://kubernetes.io/zh/docs/concepts/storage/volumes/#fc)
- [flexVolume](https://kubernetes.io/zh/docs/concepts/storage/volumes/#flexVolume)
- [flocker](https://kubernetes.io/zh/docs/concepts/storage/volumes/#flocker)
- [gcePersistentDisk](https://kubernetes.io/zh/docs/concepts/storage/volumes/#gcepersistentdisk)
- [gitRepo (deprecated)](https://kubernetes.io/zh/docs/concepts/storage/volumes/#gitrepo)
- [glusterfs](https://kubernetes.io/zh/docs/concepts/storage/volumes/#glusterfs)
- [hostPath](https://kubernetes.io/zh/docs/concepts/storage/volumes/#hostpath)
- [iscsi](https://kubernetes.io/zh/docs/concepts/storage/volumes/#iscsi)
- [local](https://kubernetes.io/zh/docs/concepts/storage/volumes/#local)
- [nfs](https://kubernetes.io/zh/docs/concepts/storage/volumes/#nfs)
- [persistentVolumeClaim](https://kubernetes.io/zh/docs/concepts/storage/volumes/#persistentvolumeclaim)
- [projected](https://kubernetes.io/zh/docs/concepts/storage/volumes/#projected)
- [portworxVolume](https://kubernetes.io/zh/docs/concepts/storage/volumes/#portworxvolume)
- [quobyte](https://kubernetes.io/zh/docs/concepts/storage/volumes/#quobyte)
- [rbd](https://kubernetes.io/zh/docs/concepts/storage/volumes/#rbd)
- [scaleIO](https://kubernetes.io/zh/docs/concepts/storage/volumes/#scaleio)
- [secret](https://kubernetes.io/zh/docs/concepts/storage/volumes/#secret)
- [storageos](https://kubernetes.io/zh/docs/concepts/storage/volumes/#storageos)
- [vsphereVolume](https://kubernetes.io/zh/docs/concepts/storage/volumes/#vspherevolume)

##  emptyDir

emptyDir类型的Volume在Pod分配到Node上时被创建，Kubernetes会在Node上自动分配一个目录，因此无需指定宿主机Node上对应的目录文件。 这个目录的初始内容为空，当Pod从Node上移除时，emptyDir中的数据会被永久删除。

emptyDir类型的volume适合于以下场景：

- 临时空间。例如某些程序运行时所需的临时目录，无需永久保存。
- 一个容器需要从另一容器中获取数据的目录（多容器共享目录）

emptyDir.yml：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: producer-consumer
spec:
  containers:
  - image: busybox
    name: producer
    volumeMounts:
    - mountPath: /producer_dir
      name: shared-volume
    args:
    - /bin/sh
    - -c
    - echo "hello " > /producer_dir/hello ; sleep 30000

  - image: busybox
    name: consumer
    volumeMounts:
    - mountPath: /consumer_dir
      name: shared-volume
    args:
    - /bin/sh
    - -c
    - cat /consumer_dir/hello ; sleep 30000

  volumes:
  - name: shared-volume
    emptyDir: {}
```

- `volumes` 定义了一个 `emptyDir` 类型的 volume，名字为 *shared-volume*。

- producer 容器把 *shared-volume* 挂载到自己的 */producer_dir*。

- producer 向 */producer_dir/hello* 写数据。

- consumer 容器把 *shared-volume* 挂载到自己的 */consumer_dir*。

- consumer 读取 */consumer_dir/hello* 内容。

创建Pod查看日志：

```
kubectl apply -f emptyDir.yml

kubectl logs producer-consumer consumer
```

输出了 producer 写入的内容，验证了 pod 中2个容器共享 emptyDir volume。

因为 emptyDir 是Docker Volume里面的目录，其效果相当于执行了 docker run -v /producer_dir 和 docker run -v /consumer_dir ，通过docker inspect查看两个容器的详细信息，可以发现两个容器mount了同一个目录。

## hostPath

hostPath类型的volume允许用户挂在Node上的文件系统到Pod中，如果 Pod 需要使用 Node 上的文件，可以使用 hostPath。

hostPath.yaml：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostPath-volume
spec: 
  containers:
  - image: busybox
    name: busybox
    args:
    - /bin/sh
    - -c
    - echo "hello " > /data/hello ; sleep 30000
    volumeMounts:
    - mountPath: /data
      name: hostPath-volume
  volumes:
  - name: hostPath-volume
    hostPath: 
      path: /data
      type: Directory
```

hostPath支持type属性，它的可选值如下：

| 值                  | 行为                                                         |
| :------------------ | :----------------------------------------------------------- |
|                     | 空字符串（默认）是用于向后兼容，这意味着在挂接主机路径存储卷之前不执行任何检查。 |
| `DirectoryOrCreate` | 如果path指定目录不存在，则会在宿主机上创建一个新的目录，并设置目录权限为0755，此目录与kubelet拥有一样的组和拥有者。 |
| `Directory`         | path指定的目标必需存在                                       |
| `FileOrCreate`      | 如果path指定的文件不存在，则会在宿主机上创建一个空的文件，设置权限为0644，此文件与kubelet拥有一样的组和拥有者。 |
| `File`              | path指定的文件必需存在                                       |
| `Socket`            | path指定的UNIX socket必需存在                                |
| `CharDevice`        | path指定的字符设备必需存在                                   |
| `BlockDevice`       | 在path给定路径上必须存在块设备。                             |

hostPath volume通常用于以下场景：

- 容器中的应用程序产生的日志文件需要永久保存，可以使用宿主机的文件系统进行存储。
- 需要访问宿主机上Docker引擎内部数据结构的容器应用，通过定义hostPath为/var/lib/docker目录，使容器内应用可以直接访问Docker的文件系统。

在使用hostPath volume时，需要注意：

- 在不同的Node上具有相同配置的Pod，可能会因为宿主机上的目录和文件不同，而导致对Volume上目录和文件的访问结果不一致。

## local

`local` 卷指的是所挂载的某个本地存储设备，例如磁盘、分区或者目录。

`local` 卷只能用作静态创建的持久卷。尚不支持动态配置。

相比 `hostPath` 卷，`local` 卷可以以持久和可移植的方式使用，而无需手动将 Pod 调度到节点，因为系统通过查看 PersistentVolume 所属节点的亲和性配置，就能了解卷的节点约束。

然而，`local` 卷仍然取决于底层节点的可用性，并不是适合所有应用程序。 如果节点变得不健康，那么`local` 卷也将变得不可访问，并且使用它的 Pod 将不能运行。 使用 `local` 卷的应用程序必须能够容忍这种可用性的降低，以及因底层磁盘的耐用性特征而带来的潜在的数据丢失风险。

下面是一个使用 `local` 卷和 `nodeAffinity` 的持久卷示例：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-pv
spec:
  capacity:
    storage: 100Gi
  # volumeMode field requires BlockVolume Alpha feature gate to be enabled.
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - example-node
```

使用 `local` 卷时，需要使用 PersistentVolume 对象的 `nodeAffinity` 字段。 它使 Kubernetes 调度器能够将使用 `local` 卷的 Pod 正确地调度到合适的节点。

现在，可以将 PersistentVolume 对象的 `volumeMode` 字段设置为 “Block”（而不是默认值 “Filesystem”），以将 `local` 卷作为原始块设备暴露出来。 `volumeMode` 字段需要启用 Alpha 功能 `BlockVolume`。

当使用 `local` 卷时，建议创建一个 StorageClass，将 `volumeBindingMode` 设置为 `WaitForFirstConsumer`。 请参考 [示例](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)。 延迟卷绑定操作可以确保 Kubernetes 在为 PersistentVolumeClaim 作出绑定决策时，会评估 Pod 可能具有的其他节点约束，例如：如节点资源需求、节点选择器、Pod 亲和性和 Pod 反亲和性。

您可以在 Kubernetes 之外单独运行静态驱动以改进对 local 卷的生命周期管理。 请注意，此驱动不支持动态配置。 有关如何运行外部 `local` 卷驱动的示例，请参考 [local 卷驱动用户指南](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner)。

## nfs

在Kubernetes中，可以通过nfs类型的存储卷将现有的NFS（网络文件系统）到的挂接到Pod中。在移除Pod时，NFS存储卷中的内容被不会被删除，只是将存储卷卸载而已。这意味着在NFS存储卷总可以预先填充数据，并且可以在Pod之间共享数据。NFS可以被同时挂接到多个Pod中，并能同时进行写入。需要注意的是：在使用nfs存储卷之前，必须已正确部署和运行NFS服务器，并已经设置了共享目录。

nfs.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nfs-web
spec:
  containers:
    - name: web
      image: nginx
      imagePullPolicy: Never        #如果已经有镜像，就不需要再拉取镜像
      ports:
        - name: web
          containerPort: 80
          hostPort: 80        #将容器的80端口映射到宿主机的80端口
      volumeMounts:
        - name : nfs        #指定名称必须与下面一致
          mountPath: "/usr/share/nginx/html"        #容器内的挂载点
  volumes:
    - name: nfs            #指定名称必须与上面一致
      nfs:            #nfs存储
        server: 192.168.66.50        #nfs服务器ip或是域名
        path: "/test"                #nfs服务器共享的目录
```

## gitRepo (已弃用)

> **警告：**
>
> gitRepo 卷类型已经被废弃。如果需要在容器中提供 git 仓库，请将一个 [EmptyDir](https://kubernetes.io/zh/docs/concepts/storage/volumes/#emptydir) 卷挂载到 InitContainer 中，使用 git 命令完成仓库的克隆操作，然后将 [EmptyDir](https://kubernetes.io/zh/docs/concepts/storage/volumes/#emptydir) 卷挂载到 Pod 的容器中。

`gitRepo` 卷是一个卷插件的例子。 该卷类型挂载了一个空目录，并将一个 Git 代码仓库克隆到这个目录中供您使用。 将来，这种卷可能被移动到一个更加解耦的模型中，而不是针对每个应用案例扩展 Kubernetes API。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: server
spec:
  containers:
  - image: nginx
    name: nginx
    volumeMounts:
    - mountPath: /mypath
      name: git-volume
  volumes:
  - name: git-volume
    gitRepo:
      repository: "git@somewhere:me/my-git-repository.git"
      revision: "22f1d8406d464b0c0874075539c1f2e96c253775"
```

## Project

除了hostPath、emptyDir还有一种Volume叫作Projected Volume（投射数据卷）。在Kubernetes中，有几种特殊的Volume，它们存在的意义不是为了存放容器里的数据，也不是用来进行容器间的数据共享。这些特殊Volume的作用是为容器提供预先定义好的数据。所以，从容器的角度来看，这些 Volume里的信息就是仿佛是被Kubernetes“投射”（Project）进入容器当中的。这正是 Projected Volume的含义。

到目前为止，Kubernetes支持的Projected Volume一共有四种：

- **Secret**
- **ConfigMap**
- **Downward API**
- **ServiceAccountToken**

### Secret

Secret最典型的使用场景，莫过于存放用户名密码等敏感信息，比如下面这个例子：

示例（8.pod-projected-secret.yaml）：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: projected-volume
spec:
  containers:
  - name: secret-volume
    image: busybox
    args:
    - sleep
    - "86400"
    volumeMounts:
    - name: cred
      mountPath: "/projected-volume"
      readOnly: true
  volumes:
  - name: cred
    projected:
      sources:
      - secret:
          name: user
      - secret:
          name: pass
```

在这个Pod中，它声明挂载的Volume，并不是常见的emptyDir或者hostPath类型，而是projected类型。而这个Volume的数据来源Secret对象，分别对应的是用户名和密码。

这里用到的数据库的用户名、密码，正是以Secret对象的方式交给Kubernetes保存的。完成这个操作的指令，如下所示：

```bash
$ cat ./user.txt
admin
$ cat ./pass.txt
password

$ kubectl create secret generic user --from-file=./user.txt
$ kubectl create secret generic pass --from-file=./pass.txt
```

其中user.txt和pass.txt文件里，存放的就是用户名和密码；而user和pass，则是我为Secret对象指定的名字。我们可以通过kubectl get命令来查看Secret对象：

```bash
$ kubectl get secrets
NAME           TYPE                                DATA      AGE
user          Opaque                                1         31s
pass          Opaque                                1         31s
```

当然，除了使用`kubectl create secret`命令外，我也可以直接通过编写YAML文件的方式来创建这个Secret对象，比如：

```yaml
apiVersion: v1 
kind: Secret 
metadata: 
  name: mysecret 
type: Opaque 
data: 
  user: YWRtaW4= 
  pass: cGFzc3dvcmQK
```

> 注意: Secret对象要求这些数据必须是经过Base64转码的，以免出现明文密码的安全隐患。

转码操作也很简单，比如：

```bash
$ echo -n 'admin' | base64
YWRtaW4=
$ echo -n 'password' | base64
cGFzc3dvcmQK
```

这里需要注意的是，像这样创建的Secret对象，它里面的内容仅仅是经过了转码，而并没有被加密。在真正的生产环境中，你需要在Kubernetes中开启 Secret的加密插件，增强数据的安全性。

### ConfigMap

与Secret类似的是ConfigMap，它与Secret的区别在于，ConfigMap保存的是不需要加密的的配置信息。而ConfigMap的用法几乎与Secret完全相同：你可以使用`kubectl create configmap`从文件或者目录创建ConfigMap，也可以直接编写ConfigMap对象的YAML文件。

### Downward

接下介绍Downward API，它的作用是：让Pod里的容器能够直接获取到这个Pod API对象本身的信息。

示例（9.pod-projected-downwardapi.yaml）：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downwardapi
  labels:
    zone: cn-beijing
    cluster: k8s
spec:
  containers:
    - name: client-container
      image: busybox
      command: ["sh", "-c"]
      args:
      - while true; do
          if [[ -e /etc/podinfo/labels ]]; then
            echo -en '\n\n'; cat /etc/podinfo/labels; fi;
          sleep 5;
        done;
      volumeMounts:
      - name: podinfo
        mountPath: /etc/podinfo
        readOnly: false
  volumes:
    - name: podinfo
      projected:
        sources:
        - downwardAPI:
            items:
            - path: "labels"
              fieldRef:
                fieldPath: metadata.labels
```

在这个Pod的YAML文件中，我定义了一个简单的容器，声明了一个projected类型的Volume。只不过这次Volume的数据来源，变成了Downward API。而这个Downward API Volume，则声明了要暴露Pod的metadata.labels信息给容器。

容器启动后，Pod的Labels字段的值就会被Kubernetes自动挂载成为容器里的/etc/podinfo/labels文件。然后/etc/podinfo/labels里的内容会被不断打印出来。

目前，Downward API支持的字段已经非常丰富了，比如：

使用fieldRef可以获取:

```
spec.nodeName - 宿主机名字
status.hostIP - 宿主机IP
metadata.name - Pod的名字
metadata.namespace - Pod Namespace
status.podIP - Pod的IP
spec.serviceAccountName - Pod的ServiceAccount的名字
metadata.uid - Pod的UID
metadata.labels['<KEY>'] - 指定<KEY>的Label值
metadata.annotations['<KEY>'] - 指定<KEY>的Annotation值
metadata.labels - Pod的所有Label
metadata.annotations - Pod的所有Annotation
```

使用resourceFieldRef可以获取:

```
CPU limit
CPU request
memory limit
memory request
```

> 注意：Downward API只能够获取到Pod容器进程启动之前就能够确定下来的信息。

## rbd

## cephfs

`cephfs` 允许您将现存的 CephFS 卷挂载到 Pod 中。不像 `emptyDir` 那样会在删除 Pod 的同时也会被删除，`cephfs` 卷的内容在删除 Pod 时会被保留，卷只是被卸载掉了。 这意味着 CephFS 卷可以被预先填充数据，并且这些数据可以在 Pod 之间”传递”。CephFS 卷可同时被多个写者挂载。

# 使用 subPath

Pod 的多个容器使用同一个 Volume 时，volumeMounts 下的 subPath 非常有用。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-lamp-site
spec:
    containers:
    - name: mysql
      image: mysql
      volumeMounts:
      - mountPath: /var/lib/mysql
        name: site-data
        subPath: mysql
    - name: php
      image: php
      volumeMounts:
      - mountPath: /var/www/html
        name: site-data
        subPath: html
    volumes:
    - name: site-data
      hostPath:
        path: /data
```

# 使用 `subPathExpr`

Kubernetes v1.15使用 `subPathExpr` 字段从 Downward API 环境变量构造 `subPath` 目录名。 在使用此特性之前，必须启用 `VolumeSubpathEnvExpansion` 功能开关。 `subPath` 和 `subPathExpr` 属性是互斥的。

在这个示例中，Pod 基于 Downward API 中的 Pod 名称，使用 `subPathExpr` 在 hostPath 卷 `/var/log/pods` 中创建目录 `pod1`。 主机目录 `/var/log/pods/pod1` 挂载到了容器的 `/logs` 中。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod1
spec:
  containers:
  - name: container1
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.name
    image: busybox
    command: [ "sh", "-c", "while [ true ]; do echo 'Hello'; sleep 10; done | tee -a /logs/hello.txt" ]
    volumeMounts:
    - name: workdir1
      mountPath: /logs
      subPathExpr: $(POD_NAME)
  restartPolicy: Never
  volumes:
  - name: workdir1
    hostPath:
      path: /var/log/pods
```

# 资源

`emptyDir` 卷的存储介质（磁盘、SSD 等）是由保存 kubelet 根目录（通常是 `/var/lib/kubelet`）的文件系统的介质确定。 `emptyDir` 卷或者 `hostPath` 卷可以消耗的空间没有限制，容器之间或 Pod 之间也没有隔离。

将来，我们希望 `emptyDir` 卷和 `hostPath` 卷能够使用 [resource](https://kubernetes.io/docs/user-guide/computeresources) 规范来请求一定量的空间，并且能够为具有多种介质类型的集群选择要使用的介质类型。
