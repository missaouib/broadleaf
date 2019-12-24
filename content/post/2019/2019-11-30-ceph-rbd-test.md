---
layout: post
title: Ceph块设备测试
date: 2019-11-30T08:00:00+08:00
categories: [ ceph ]
tags: [ceph]
---



在搭建了一个Ceph多节点的集群之后，你可以在客户端上连接集群使用Ceph存储上的设备，比如块设备。



# 配置客户端

1、在管理节点上，通过 `ceph-deploy` 把 Ceph 安装到客户端节点。

```bash
ssh-copy-id k8s-rke-node005

ceph-deploy install k8s-rke-node005
```

2、在管理节点上，用 `ceph-deploy` 把 Ceph 配置文件和 `ceph.client.admin.keyring` 拷贝到客户端：

```bash
ceph-deploy admin k8s-rke-node005
```

`ceph-deploy` 工具会把密钥环复制到 `/etc/ceph` 目录，要确保此密钥环文件有读权限（如 `sudo chmod +r /etc/ceph/ceph.client.admin.keyring` ）。

3、客户机需要 ceph 秘钥去访问 ceph 集群。ceph创建了一个默认的用户client.admin，它有足够的权限去访问ceph集群。但是不建议把 client.admin 共享到所有其他的客户端节点。这里我用分开的秘钥新建一个用户k8s去访问特定的存储池。

```bash
ceph auth get-or-create client.k8s mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=rbd'
```

为 k8s-rke-node005 上的 client.rbd 用户添加秘钥：

```bash
ceph auth get-or-create client.k8s | k8s-rke-node005 tee /etc/ceph/ceph.client.k8s.keyring
```

到客户端 k8s-rke-node005  检查集群健康状态：

```bash
cat /etc/ceph/ceph.client.k8s.keyring >> /etc/ceph/keyring
ceph -s --name client.k8s
```

# 创建块设备

1、要想把块设备加入某节点，你得先在Ceph 存储集群中创建一个映像，使用下列命令：

```bash
rbd create --size {megabytes} {pool-name}/{image-name}
```

例如，要在 `swimmingpool` 这个存储池中创建一个名为 `foo` 、大小为 1GB 的映像，执行：

```
rbd create --size 1024 swimmingpool/foo
```

如果创建映像时不指定存储池，它将使用默认的 `rbd` 存储池。例如，下面的命令将默认在 `rbd` 存储池中创建一个大小为 1GB 、名为 `foo` 的映像：

```bash
$ rbd create --size 1024 foo
rbd: error opening default pool 'rbd'
Ensure that the default pool has been created or specify an alternate pool name.
```

提示默认存储池rbd不存在。

2、查看存储池

```bash
$ ceph osd lspools
1 .rgw.root
2 default.rgw.control
3 default.rgw.meta
4 default.rgw.log
```

3、创建一个rbd存储池

```bash
ceph osd pool create rbd 96 32
```

再次创建块设备：

```bash
rbd create --size 1024 rbd/foo
```

4、在客户端节点上，把 image 映射为块设备。

用 `rbd` 把映像名映射为内核模块。必须指定映像名、存储池名、和用户名。若 RBD 内核模块尚未加载， `rbd` 命令会自动加载。

```bash
sudo rbd map {pool-name}/{image-name} --id {user-name}
```

如果你启用了 [cephx](http://docs.ceph.org.cn/rados/configuration/auth-config-ref/) 认证，还必须提供密钥，可以用密钥环或密钥文件指定密钥。

```bash
sudo rbd map rbd/myimage --id admin --keyring /path/to/keyring
sudo rbd map rbd/myimage --id admin --keyfile /path/to/file
```

例如：

```
sudo rbd map rbd/foo 
```

出现异常：

```bash
feature set mismatch, my 106b84a842a42 < server's 40106b84a842a42, missing 400000000000000
missing required protocol features
```

解决办法参考：http://cephnotes.ksperis.com/blog/2014/01/21/feature-set-mismatch-error-on-ceph-kernel-client

```bash
ceph osd crush tunables legacy
```



如果出现异常：

```
RBD image feature set mismatch. You can disable features unsupported by the kernel with "rbd feature disable rbd/foo object-map fast-diff deep-flatten".
```

查看系统日志可以看到如下输出：

```bash
$ dmesg | tail
[ 3871.736182] libceph: client34162 fsid cee3f3a5-9e7b-428b-84f0-bac001ba2f84
[ 3871.755745] rbd: image foo: image uses unsupported features: 0x38
```

> 问题原因: 在 Ceph 高版本进行 map image 时，默认 Ceph 在创建 image(上文 data)时会增加许多 features，这些 features 需要内核支持，在 Centos7 的内核上支持有限，所以需要手动关掉一些 features

首先使用 `rbd info data` 命令列出创建的 image 的 features：

```bash
$ rbd info rbd/foo  
rbd image 'foo':
    size 1 GiB in 256 objects
    order 22 (4 MiB objects)
    snapshot_count: 0
    id: 856ecc3de788
    block_name_prefix: rbd_data.856ecc3de788
    format: 2
    features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
    op_features:
    flags:
    create_timestamp: Fri Sep 27 09:45:58 2019
    access_timestamp: Fri Sep 27 09:45:58 2019
    modify_timestamp: Fri Sep 27 09:45:58 2019
```

在 features 中我们可以看到默认开启了很多：layering, exclusive-lock, object-map, fast-diff, deep-flatten



RBD支持的特性，及具体BIT值的计算如下：

| 属性           | 功能                                 | BIT码 |
| -------------- | ------------------------------------ | ----- |
| layering       | 支持分层                             | 1     |
| striping       | 支持条带化v2                         | 2     |
| exclusive-lock | 支持独占锁                           | 4     |
| object-map     | 支持对象映射（依赖 exclusive-lock ） | 8     |
| fast-diff      | 快速计算差异（依赖 object-map ）     | 16    |
| deep-flatten   | 支持快照扁平化操作                   | 32    |
| journaling     | 支持记录 IO 操作（依赖独占锁）       | 64    |

而实际上 Centos 7 的 3.10 内核只支持 layering… 所以我们要手动关闭一些 features，然后重新 map；如果想要一劳永逸，可以在 ceph.conf 中加入 rbd_default_features = 1 来设置默认 features(数值仅是 layering 对应的 bit 码所对应的整数值)。

方法一：

直接diable这个rbd镜像的不支持的特性：

```
rbd feature disable rbd/foo exclusive-lock object-map fast-diff deep-flatten
```

方法二：

创建rbd镜像时就指明需要的特性，如：

```
rbd create rbd/foo --size 1024 --image-feature layering
```

方法三：

如果还想一劳永逸，那么就在执行创建rbd镜像命令的服务器中，修改Ceph配置文件/etc/ceph/ceph.conf，在global section下，增加

```
rbd_default_features = 1
```

# 查看块设备

要列出 `rbd` 存储池中的块设备，可以用下列命令（即 `rbd` 是默认存储池名字）：

```
rbd ls
```

用下列命令罗列某个特定存储池中的块设备，用存储池的名字替换 `{poolname}` ：

```
rbd ls {poolname}
```

例如：

```
rbd ls swimmingpool
```

查看系统中已经映射的块设备

```bash
$ rbd showmapped
id pool namespace image snap device
0  rbd            foo   -    /dev/rbd0
```

# 检索镜像信息

用下列命令检索某个特定映像的信息，用映像名字替换 `{image-name}` ：

```
rbd info {image-name}
```

例如：

```
rbd info foo
```

用下列命令检索某存储池内的映像的信息，用映像名字替换 `{image-name}` 、用存储池名字替换 `{pool-name}` ：

```
rbd info {pool-name}/{image-name}
```

例如：

```
rbd info rbd/foo
```

# 调整块设备映像大小

Ceph 块设备镜像是精简配置，只有在你开始写入数据时它们才会占用物理空间。然而，它们都有最大容量，就是你设置的 `--size` 选项。如果你想增加（或减小） Ceph 块设备映像的最大尺寸，执行下列命令：

```
rbd resize --size 2048 foo 
rbd resize --size 512 foo --allow-shrink
```

# 使用块设备

1、在客户端节点上，创建文件系统后就可以使用块设备了。格式化块设备：

```bash
sudo mkfs.xfs /dev/rbd0
```

此命令可能耗时较长。

2、在客户端节点上挂载此文件系统。

```bash
sudo mkdir /mnt/ceph-block-device
sudo mount /dev/rbd0 /mnt/ceph-block-device
```

3、查看挂载情况

```bash
$ df -h /mnt/ceph-block-device
Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd0      1014M   33M  982M   4% /mnt/ceph-block-device
```

4、我们测试一下生成一个 500M 大文件，看是否自动同步到各个节点：

```bash
cd /mnt/ceph-block-device
sudo dd if=/dev/zero of=/mnt/ceph-block-device/test-file bs=500M count=1
```

查看文件有没有生成：

```bash
$ ls /mnt/ceph-block-device
test-file
```

查看目录大小：

```bash
$ df -h /mnt/ceph-block-device
Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd0      1014M  533M  482M  53% /mnt/ceph-block-device
```

说明文件写入成功。

5、查看ceph集群中存储使用情况

在ceph集群某一个节点上执行：

```bash
$ ceph -s
  cluster:
    id:     9114557d-8096-4b4d-ad74-622d68903aea
    health: HEALTH_WARN
            crush map has straw_calc_version=0

  services:
    mon: 1 daemons, quorum k8s-rke-node001 (age 7h)
    mgr: k8s-rke-node001(active, since 16h)
    osd: 1 osds: 1 up (since 136y), 1 in (since 5d)
    rgw: 1 daemon active (k8s-rke-node001)

  data:
    pools:   4 pools, 32 pgs
    objects: 219 objects, 1.2 KiB
    usage:   1.0 GiB used, 6.0 GiB / 7 GiB avail
    pgs:     32 active+clean
```

可以看到有1.0 GB被使用了。

# 取消掉块设备的映射

```bash
sudo umount /mnt/ceph-block-device
sudo rbd unmap /dev/rbd0 
```

# 删除块设备镜像

可用下列命令删除块设备，用映像名字替换 `{image-name}` ：

```
rbd rm {image-name}
```

例如：

```
rbd rm foo
```

用下列命令从某存储池中删除一个块设备，用要删除的映像名字替换 `{image-name}` 、用存储池名字替换 `{pool-name}` ：

```
rbd rm {pool-name}/{image-name}
```

例如：

```
rbd rm rbd/foo
```

# 参考文章

- [使用内核态的RBD](https://blog.csdn.net/ygtlovezf/article/details/79107755)
- [Feature Set Mismatch Error on Ceph Kernel Client](http://cephnotes.ksperis.com/blog/2014/01/21/feature-set-mismatch-error-on-ceph-kernel-client)
- [块设备命令](http://docs.ceph.org.cn/rbd/rados-rbd-cmds/)