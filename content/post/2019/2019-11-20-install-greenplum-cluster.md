---
layout: post
title: 安装Greenplum数据库集群
date: 2019-11-20T08:00:00+08:00
categories: [ database ]
tags: [Greenplum]
---

本文主要介绍如何快速安装部署单节点的Greenplum过程，以及Greenplum的一些常用命令及工具。



# 系统环境

操作系统：Centos7

节点环境：

| ip             | hostname   | 角色            |
| -------------- | ---------- | --------------- |
| 192.168.56.141 | gp-node001 | master          |
| 192.168.56.142 | gp-node002 | master、segment |
| 192.168.56.143 | gp-node003 | segment         |

安装用户：root

# 配置系统参数

## 配置hosts文件

在配置/etc/hosts时，使用ping命令确定所有hostname都是通的。

```bash
cat > /etc/hosts <<EOF
192.168.56.141 gp-node001
192.168.56.142 gp-node002
192.168.56.143 gp-node003
EOF
```

## 关闭selinux

```bash
setenforce 0  >/dev/null 2>&1
sed -i -e 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i -e 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

## 关闭防火墙

```bash
systemctl stop firewalld.service && systemctl disable firewalld.service
```

## 设置时钟同步

```bash
cat > /etc/ntp.conf << EOF
#在与上级时间服务器联系时所花费的时间，记录在driftfile参数后面的文件
driftfile /var/lib/ntp/drift
#默认关闭所有的 NTP 联机服务
restrict default ignore
restrict -6 default ignore
#如从loopback网口请求，则允许NTP的所有操作
restrict 127.0.0.1
restrict -6 ::1
#使用指定的时间服务器
server ntp1.aliyun.com
server ntp2.aliyun.com
server ntp3.aliyun.com
#允许指定的时间服务器查询本时间服务器的信息
restrict ntp1.aliyun.com nomodify notrap nopeer noquery
#其它认证信息
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
EOF

systemctl start ntpd && systemctl enable ntpd
echo '* */6 * * * /usr/sbin/ntpdate -u ntp1.aliyun.com && /sbin/hwclock --systohc > /dev/null 2>&1' >> /var/spool/cron/`whoami`
```

## 配置sysctl.conf

参考 https://segmentfault.com/a/1190000020654036?utm_source=tag-newest

```bash
#设置内核参数
cat > greenplum.conf <<EOF
kernel.shmall = 2033299
kernel.shmmax = 8328392704
kernel.shmmni = 4096
kernel.sem = 500 1024000 200 4096
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 31764
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
net.ipv4.ip_local_port_range = 10000 65535
net.core.netdev_max_backlog = 10000
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
vm.overcommit_memory = 2
vm.overcommit_ratio = 95 
vm.swappiness = 0
vm.zone_reclaim_mode = 0
#这个时候，后台进行在脏数据达到3%时就开始异步清理，但在10%之前系统不会强制同步写磁盘。刷脏进程3秒起来一次，脏数据存活超过10秒就会开始刷。
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.dirty_background_ratio = 3
vm.dirty_ratio = 10
EOF

mv greenplum.conf /etc/sysctl.d/greenplum.conf
sysctl -p /etc/sysctl.d/greenplum.conf
```

生产环境的配置，需要详细参考官方文档的说明：https://gpdb.docs.pivotal.io/6-1/install_guide/prep_os.html#topic3__sysctl_file

kernel.shmall（共享内存页总数）
kernel.shmmax (共享内存段的最大值)
一般来讲，这两个参数的值应该是物理内存的一半，可以通过操作系统的值_PHYS_PAGES和PAGE_SIZE计算得出。

```bash
kernel.shmall = ( _PHYS_PAGES / 2)
kernel.shmmax = ( _PHYS_PAGES / 2) * PAGE_SIZE
```

也可以通过以下两个命令得出这两个参数的值：

```bash
echo $(expr $(getconf _PHYS_PAGES) / 2) 
echo $(expr $(getconf _PHYS_PAGES) / 2 \* $(getconf PAGE_SIZE))
```

如果得出的kernel.shmmax值小于系统的默认值，则引用系统默认值即可



对于64G内存的操作系统，建议配置如下值：

```bash
vm.dirty_background_ratio = 0
vm.dirty_ratio = 0
vm.dirty_background_bytes = 1610612736 # 1.5GB
vm.dirty_bytes = 4294967296 # 4GB
```

对于小于64G内存的操作系统，建议配置如下值：

```bash
vm.dirty_background_ratio = 3
vm.dirty_ratio = 10
```



## 设置**limits.conf**

```bash
cat >/etc/security/limits.d/file.conf<<EOF
*       soft    nproc   131072
*       hard    nproc   131072
*       soft    nofile  131072
*       hard    nofile  131072
root    soft    nproc   131072
root    hard    nproc   131072
root    soft    nofile  131072
root    hard    nofile  131072
EOF
```

## 磁盘IO设置

设置磁盘预读

```
fdisk -l

/sbin/blockdev --setra 16384 /dev/sdb
```

调整IO调度算法

```bash
echo deadline > /sys/block/sdb/queue/scheduler
grubby --update-kernel=ALL --args="elevator=deadline"
```

## 设置Transparent Huge Pages

禁止透明大页，Redhat 6以及更高版本默认激活THP，THP会降低GP database性能，通过修改文件/boot/grub/grub.conf添加参数transparent_hugepage=never禁止THP的应用，但需要重新启动系统

```bash
echo "echo never > /sys/kernel/mm/*transparent_hugepage/defrag" >/etc/rc.local
echo "echo never > /sys/kernel/mm/*transparent_hugepage/enabled" >/etc/rc.local
grubby --update-kernel=ALL --args="transparent_hugepage=never"
```

> 需要重启系统

查看是否禁用：

```bash
$ cat /sys/kernel/mm/*transparent_hugepage/enabled
always madvise [never]
```

检查内核参数：

```bash
$ grubby --info=ALL
index=0
kernel=/boot/vmlinuz-4.4.202-1.el7.elrepo.x86_64
args="ro elevator=deadline no_timer_check crashkernel=auto rd.lvm.lv=centos_centos7/root rd.lvm.lv=centos_centos7/swap biosdevname=0 net.ifnames=0 rhgb quiet numa=off transparent_hugepage=never"
root=/dev/mapper/centos_centos7-root
initrd=/boot/initramfs-4.4.202-1.el7.elrepo.x86_64.img
title=CentOS Linux (4.4.202-1.el7.elrepo.x86_64) 7 (Core)
```

## 关闭RemoveIPC

```bash
sed -i 's/#RemoveIPC=no/RemoveIPC=no/g' /etc/systemd/logind.conf
service systemd-logind restart
```

## 设置SSH连接

```bash
sed -i 's/#MaxStartups 10:30:100/MaxStartups 10:30:200/g' /etc/ssh/sshd_config
service sshd restart
```

## 创建Greenplum管理员用户

创建用户gpadmin

```bash
USER=gpadmin

groupadd $USER
useradd $USER -r -m -g $USER
echo $USER|passwd $USER --stdin >/dev/null 2>&1
```

添加sudo权限：

```bash
sudo echo "$USER ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
```

每个节点切换到gpadmin用户，生成ssh密钥：

```bash
[ ! -f ~/.ssh/id_rsa.pub ] && (yes|ssh-keygen -f ~/.ssh/id_rsa -t rsa -N "")
( chmod 600 ~/.ssh/id_rsa.pub ) && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

## 挂载磁盘

先查看磁盘挂载：

```bash
fdisk -l
```

如果没有磁盘，则需要挂载磁盘。官方建议使用XFS磁盘类型，当然其他磁盘类型也是可以。

配置/etc/fstab文件以使Linux系统启动默认挂载磁盘，如下配置添加到文件/etc/fstab：

```bash
mkfs.xfs -f /dev/sdb

mkdir /data

echo "/dev/sdb /data xfs  nodev,noatime,nobarrier,inode64 0 0" >> /etc/fstab

mount -a
```



# 安装Greenplum数据库

## 安装数据库

1、下载页面：https://network.pivotal.io/products/pivotal-gpdb/ ，当前最新版本为6.1，对应的rpm文件 greenplum-db-6.1.0-rhel7-x86_64.rpm。拷贝到每个节点：

```bash
scp greenplum-db-6.1.0-rhel7-x86_64.rpm gpadmin@gp-node001:~
scp greenplum-db-6.1.0-rhel7-x86_64.rpm gpadmin@gp-node002:~
scp greenplum-db-6.1.0-rhel7-x86_64.rpm gpadmin@gp-node003:~
```

2、每个节点安装RPM

```bash
ssh gp-node001 "sudo yum install greenplum-db-6.1.0-rhel7-x86_64.rpm -y"
ssh gp-node002 "sudo yum install greenplum-db-6.1.0-rhel7-x86_64.rpm -y"
ssh gp-node003 "sudo yum install greenplum-db-6.1.0-rhel7-x86_64.rpm -y"
```

3、修改安装目录权限

```bash
ssh gp-node001 "sudo chown -R gpadmin:gpadmin /usr/local/greenplum*"
ssh gp-node002 "sudo chown -R gpadmin:gpadmin /usr/local/greenplum*"
ssh gp-node003 "sudo chown -R gpadmin:gpadmin /usr/local/greenplum*"
```

## 确保无密码登陆

1、gp-node001节点上配置gpadmin用户无密码登陆到其他节点：

```bash
ssh-copy-id gp-node001
ssh-copy-id gp-node002
ssh-copy-id gp-node003
```

2、设置greenplum环境变量使其生效

```bash
source /usr/local/greenplum-db/greenplum_path.sh
```

3、配置hostfile_all文件，将所有的服务器名记录在里面。

```bash
cat > hostfile_all << EOF
gp-node001
gp-node002
gp-node003
EOF
```

hostfile_segment只保存segment节点的hostname

```bash
cat > hostfile_segment << EOF
gp-node002
gp-node003
EOF
```

4、使用gpssh-exkeys打通所有服务器，配置所有GP节点之间ssh互信：

```bash
$ gpssh-exkeys -f hostfile_all 
[STEP 1 of 5] create local ID and authorize on local host
  ... /home/gpadmin/.ssh/id_rsa file exists ... key generation skipped

[STEP 2 of 5] keyscan all hosts and update known_hosts file

[STEP 3 of 5] retrieving credentials from remote hosts
  ... send to gp-node002
  ... send to gp-node003

[STEP 4 of 5] determine common authentication file content

[STEP 5 of 5] copy authentication files to all remote hosts
  ... finished key exchange with gp-node002
  ... finished key exchange with gp-node003

[INFO] completed successfully
```

## 确认安装

1、登陆master节点的gpadmin用户

```bash
 su - gpadmin
```

2、在打通所有机器通道之后，我们就可以使用gpssh命令对所有机器进行批量操作了。

```bash
$ gpssh -f hostfile_all "ls -l /usr/local/greenplum-db"
[gp-node001] lrwxrwxrwx. 1 gpadmin gpadmin 29 Dec  3 09:49 /usr/local/greenplum-db -> /usr/local/greenplum-db-6.1.0
[gp-node002] lrwxrwxrwx. 1 gpadmin gpadmin 29 Dec  3 10:48 /usr/local/greenplum-db -> /usr/local/greenplum-db-6.1.0
[gp-node003] lrwxrwxrwx. 1 gpadmin gpadmin 29 Dec  3 10:56 /usr/local/greenplum-db -> /usr/local/greenplum-db-6.1.0
```

# 创建存储

master上创建目录：

```bash
gpssh -h gp-node001 -e 'sudo mkdir -p /data/greenplum/master && sudo chown gpadmin:gpadmin /data/greenplum/master' 
gpssh -h gp-node002 -e 'sudo mkdir -p /data/greenplum/master && sudo chown gpadmin:gpadmin /data/greenplum/master'
```

数据节点创建目录：

```bash
gpssh -f hostfile_segment -e 'sudo mkdir -p /data/greenplum/{primary,mirror} && sudo chown -R gpadmin:gpadmin /data/greenplum'

gpssh -f hostfile_segment -e 'sudo mkdir -p /data2/greenplum/{primary,mirror} && sudo chown -R gpadmin:gpadmin /data2/greenplum'
```



# 初始化数据库

## 创建模板

配置文件的模板可以在 $GPHOME/docs/cli_help/gpconfigs/ 目录下找到。gpinitsystem_config文件是初始化Greenplum的模板，在这个模板中，Mirror Segment的配置都被注释掉了，模板中基本初始化数据库的参数都是有的。

```bash
cat > gpinitsystem_config <<EOF
#数据库的代号
ARRAY_NAME="Greenplum Data Platform"
#Segment的名称前缀
SEG_PREFIX=gpseg
#Primary Segment起始的端口号
PORT_BASE=40000
#指定Primary Segment的数据目录,配置几次资源目录就是每个子节点有几个实例（推荐4-8个，这里配置了4个，primary与mirror文件夹个数对应）
declare -a DATA_DIRECTORY=(/data2/greenplum/primary /data2/greenplum/primary /data2/greenplum/primary /data2/greenplum/primary)
#Master所在机器的Hostname
MASTER_HOSTNAME=gp-node001 
#指定Master的数据目录
MASTER_DIRECTORY=/data/greenplum/master
#Master的端口
MASTER_PORT=5432
#指定Bash的版本
TRUSTED_SHELL=ssh
#设置的是检查点段的大小，较大的检查点段可以改善大数据量装载的性能，同时会加长灾难事务恢复的时间。
CHECK_POINT_SEGMENTS=8
#字符集
ENCODING=utf-8

#Mirror Segment起始的端口号
MIRROR_PORT_BASE=41000
#Primary Segment主备同步的起始端口号
REPLICATION_PORT_BASE=42000
#Mirror Segment主备同步的起始端口号
MIRROR_REPLICATION_PORT_BASE=43000
#Mirror Segment的数据目录,配置几次资源目录就是每个子节点有几个实例（推荐4-8个，这里配置了4个，primary与mirror文件夹个数对应）
declare -a MIRROR_DATA_DIRECTORY=(/data2/greenplum/mirror /data2/greenplum/mirror /data2/greenplum/mirror /data2/greenplum/mirror)
EOF
```

## 初始化数据库

使用gpinitsystem脚本来初始化数据库，命令如下：

```bash
gpinitsystem -c gpinitsystem_config -h hostfile_segment
```

也可以指定standby master ：

```BASH
gpinitsystem -c gpinitsystem_config -h hostfile_segment -s gp-node002 
```

如果不想手动确认，可以添加 `-a` 参数。

后期添加standby master：

```bash
#在不同机器增加standby master节点
gpinitstandby -S /data/greenplum/master/gpseg-1 -s gp-node002 

#在同一机器增加standby master节点
gpinitstandby -S /data/greenplum/master/gpseg-1 -P 5433 -s gp-node001 
```



## 设置数据库时区

```bash
gpconfig -s TimeZone
gpconfig -c TimeZone -v 'Asia/Shanghai'
```

## 设置环境变量

切换到gpadmin用户：

```bash
su - gpadmin 

cat >>  ~/.bashrc <<EOF
source /usr/local/greenplum-db/greenplum_path.sh
export GPHOME=/usr/local/greenplum-db
export MASTER_DATA_DIRECTORY=/data/greenplum/master/gpseg-1
export LD_PRELOAD=/lib64/libz.so.1 ps
export PGPORT=5432
EOF

source ~/.bashrc
```

拷贝到standby master节点：

```bash
scp ~/.bashrc gp-node002:~
ssh gp-node002 "source ~/.bashrc"
```

## 检查参数设置

1、检查catalog

```bash
gpcheckcat
```

2、检查网络：

```bash
$ gpcheckperf -f hostfile_all -r n -d /tmp 
/usr/local/greenplum-db/./bin/gpcheckperf -f hostfile_all -r n -d /tmp

-------------------
--  NETPERF TEST
-------------------

====================
==  RESULT 2019-12-03T12:01:51.230530
====================
Netperf bisection bandwidth test
gp-node001 -> gp-node002 = 197.700000
gp-node002 -> gp-node001 = 155.900000
gp-node003 -> gp-node001 = 249.850000
gp-node001 -> gp-node003 = 180.010000

Summary:
sum = 783.46 MB/sec
min = 155.90 MB/sec
max = 249.85 MB/sec
avg = 195.87 MB/sec
median = 197.70 MB/sec

[Warning] connection between gp-node001 and gp-node002 is no good
[Warning] connection between gp-node002 and gp-node001 is no good
[Warning] connection between gp-node001 and gp-node003 is no good
```

网络测试选项包括：并行测试(-r N)、串行测试(-r n)、矩阵测试(-r M)。

测试时运行一个网络测试程序从当前主机向远程主机传输5秒钟的数据流。缺省时，数据并行传输到每个远程主机，报告出传输的最小、最大、平均和中值速率，单位为MB/S。如果主体的传输速率低于预期(小于100MB/S)，可以使用-r n参数运行串行的网络测试以得到每个主机的结果。要运行矩阵测试，指定-r M参数，使得每个主机发送接收指定的所有其他主机的数据，这个测试可以验证网络层能否承受全矩阵工作负载。



3、检查io：

```bash
gpcheckperf  -f hostfile_segment -r ds -D -d /data/greenplum/primary/ -d /data/greenplum/primary/ 
```

因为当前环境所有主机都挂载在/data目录，所以直接-d /data即可验证所有主机/data磁盘IO，若主机目录不一样。验证每台需要-d 按hostfile_segment中填写的顺序单独执行路径



4、检查磁盘空间使用

一个数据库管理员最重要的监控任务是确保Master和Segment数据目录所在的文件系统的使用率不会超过 70%的。完全占满的数据磁盘不会导致数据损坏，但是可能会妨碍数据库的正常操作。如果磁盘占用得太满， 可能会导致数据库服务器关闭。

可以使用gp_toolkit管理模式中的gp_disk_free外部表 来检查Segment主机文件系统中的剩余空闲空间（以KB为计量单位）。例如：

```sql
dw_lps=# SELECT * FROM gp_toolkit.gp_disk_free ORDER BY dfsegment;
 dfsegment |    dfhostname    | dfdevice  |  dfspace
-----------+------------------+-----------+-----------
         0 |  dw-test-node001 |  /dev/sdb | 471670156
         1 |  dw-test-node001 |  /dev/sdb | 471670156
(2 rows)
```

5、查看数据库的磁盘空间使用情况

要查看一个数据库的总大小（以字节计），使用*gp_toolkit*管理模式中的*gp_size_of_database* 视图。例如：

```sql
dw_lps=# SELECT * FROM gp_toolkit.gp_size_of_database ORDER BY sodddatname;
 sodddatname | sodddatsize
-------------+-------------
 dw_lps      |  4048421788
 gpperfmon   |    62718612
(2 rows)
```

6、查看一个表的磁盘空间使用情况

*gp_toolkit*管理模式包含几个检查表大小的视图。表大小视图根据对象ID （而不是名称）列出表。要根据一个表的名称检查其尺寸，必须在*pg_class*表中查找关系名称 （relname）。例如：

```sql
dw_lps=# SELECT relname AS name, sotdsize AS size, sotdtoastsize
dw_lps-#    AS toast, sotdadditionalsize AS other
dw_lps-#    FROM gp_toolkit.gp_size_of_table_disk as sotd, pg_class
dw_lps-#    WHERE sotd.sotdoid=pg_class.oid ORDER BY relname;
             name             |    size    | toast | other
------------------------------+------------+-------+--------
 ods_lps_bill                 | 1040342384 | 98304 | 327680
 ods_lps_event                | 1280960368 | 98304 | 327680
(5 rows)
```

查看某个表占用空间：

```sql
dw_lps=# select pg_size_pretty(pg_relation_size('ods_lps_bill'));
 pg_size_pretty
----------------
 804 MB
(1 row)
```



7、查看索引的磁盘空间使用情况

```sql
=> SELECT soisize, relname as indexname
   FROM pg_class, gp_toolkit.gp_size_of_index
   WHERE pg_class.oid=gp_size_of_index.soioid 
   AND pg_class.relkind='i';
```

8、查看表的元数据

要查看一个表中被用作数据分布键的列，可以使用psql中的\d+ 元命令来检查表的定义。例如：

```sql
=# \d+ sales
                Table "retail.sales"
 Column      |     Type     | Modifiers | Description
-------------+--------------+-----------+-------------
 sale_id     | integer      |           |
 amt         | float        |           |
 date        | date         |           |
Has OIDs: no
Distributed by: (sale_id)
```

当我们创建复制表时，Greenplum数据库会在每个Segment上都存储一份完整的表数据。复制表没有分布键。 \d+元命令会展示分布表的分布键，复制表展示状态为Distributed Replicated。

9、查看数据分布

```sql
SELECT gp_segment_id, count(*) 
   FROM ods_lps_bill GROUP BY gp_segment_id;
```

##查看状态

查看状态：

```bash
#查看简短状态
gpstate

#查看详细状态
gpstate -s

#查看standby master的状态
gpstate -f 

#查看mirror的状态
gpstate -e 

#查看镜像状态
gpstate -m 

#查看主Segment到镜像Segment的映射
gpstate -c

#查看GP的版本
gpstate -i 

```

> 可以使用这篇文章的命令查看集群状态：https://blog.51cto.com/michaelkang/2169857

查看进程：

```bash
ps -ef|grep greenplum
gpadmin   1098     1  0 17:00 ?        00:00:00 /usr/local/greenplum-db-6.1.0/bin/postgres -D /data/greenplum/primary1/gpseg0 -p 40000
gpadmin   1099     1  0 17:00 ?        00:00:00 /usr/local/greenplum-db-6.1.0/bin/postgres -D /data/greenplum/primary2/gpseg1 -p 40001
gpadmin   1120     1  0 17:00 ?        00:00:00 /usr/local/greenplum-db-6.1.0/bin/postgres -D /data/greenplum/master/gpseg-1 -p 5432 -E
```

# 修改数据库配置

## 设置远程用户访问

修改 /data/greenplum/master/gpseg-1/pg_hba.conf

```bash
local    all         all         									trust
host     all         all             0.0.0.0/0    trust
local    replication gpadmin         ident
host     replication gpadmin         samenet       trust
```

测试登陆：

```bash
psql -p 5432 -h 192.168.56.141 -U gpadmin -d postgres 
```

## 设置监听IP和Port

```bash
vi /data/greenplum/master/gpseg-1/postgresql.conf

# 设置监听IP (* 生产环境慎用)
listen_addresses = '${ host ip address } '
port = 5432
```

# 测试

## 连接数据库

数据库就初始化成功了，尝试登录Greenplum默认的数据库postgres：

```bash
$ psql -d postgres
psql (9.4.24)
Type "help" for help.

postgres=# \l
                               List of databases
   Name    |  Owner  | Encoding |  Collate   |   Ctype    |  Access privileges
-----------+---------+----------+------------+------------+---------------------
 postgres  | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | =c/gpadmin         +
           |         |          |            |            | gpadmin=CTc/gpadmin
 template1 | gpadmin | UTF8     | en_US.utf8 | en_US.utf8 | =c/gpadmin         +
           |         |          |            |            | gpadmin=CTc/gpadmin
(3 rows)

postgres=# select * from gp_segment_configuration;
 dbid | content | role | preferred_role | mode | status | port  |  hostname  |  address   |            datadir
------+---------+------+----------------+------+--------+-------+------------+------------+--------------------------------
    1 |      -1 | p    | p              | n    | u      |  5432 | gp-node001 | gp-node001 | /data/greenplum/master/gpseg-1
    4 |       2 | p    | p              | s    | u      | 40000 | gp-node003 | gp-node003 | /data/greenplum/primary/gpseg2
    8 |       2 | m    | m              | s    | u      | 41000 | gp-node002 | gp-node002 | /data/greenplum/mirror/gpseg2
    5 |       3 | p    | p              | s    | u      | 40001 | gp-node003 | gp-node003 | /data/greenplum/primary/gpseg3
    9 |       3 | m    | m              | s    | u      | 41001 | gp-node002 | gp-node002 | /data/greenplum/mirror/gpseg3
    3 |       1 | p    | p              | s    | u      | 40001 | gp-node002 | gp-node002 | /data/greenplum/primary/gpseg1
    7 |       1 | m    | m              | s    | u      | 41001 | gp-node003 | gp-node003 | /data/greenplum/mirror/gpseg1
    2 |       0 | p    | p              | s    | u      | 40000 | gp-node002 | gp-node002 | /data/greenplum/primary/gpseg0
    6 |       0 | m    | m              | s    | u      | 41000 | gp-node003 | gp-node003 | /data/greenplum/mirror/gpseg0
   10 |      -1 | m    | m              | s    | u      |  5432 | gp-node002 | gp-node002 | /data/greenplum/master/gpseg-1
(10 rows)
```

可以看到有两个master、4个primary和4个mirror。

查看数据复制：

```bash
postgres=# select * from pg_stat_replication ;
  pid  | usesysid | usename | application_name |  client_addr   | client_hostname | client_port |         backend_start         | backend_xmin |   state   | sent_location | writ
e_location | flush_location | replay_location | sync_priority | sync_state
-------+----------+---------+------------------+----------------+-----------------+-------------+-------------------------------+--------------+-----------+---------------+-----
-----------+----------------+-----------------+---------------+------------
 25715 |       10 | gpadmin | gp_walreceiver   | 192.168.56.142 |                 |       26952 | 2019-12-03 11:07:37.356605+08 |              | streaming | 0/C003B78     | 0/C0
03B78      | 0/C003B78      | 0/C003B78       |             1 | sync
(1 row)
```



## 创建数据库

现在我们开始创建测试数据库：

```bash
$ createdb test -E utf-8
```

没有设置PGDATABASE这个环境变量时，使用psql进行登录，默认的数据库是与操作系统用户名一致的，这时候会报错：

```bash
$ psql
psql: FATAL: database "gpadmin" does not exist
```

然后设置（export）环境变量PGDATABASE=test，这样就默认登录test数据库：

```bash
export PGDATABASE=test 

$ psql
psql (9.4.24)
Type "help" for help.

test=#
```

查询数据库版本并创建一张简单的表：

```bash
test=# select version();
test=# create table test01(id int primary key,name varchar(128));
CREATE TABLE
```

创建用户和数据库：

```bash
CREATE USER test WITH PASSWORD 'test';
CREATE DATABASE dw_lps owner=gpadmin;

GRANT ALL privileges ON DATABASE dw_lps TO gpadmin;
```

## 启动与关闭

启动数据库：

```bash
gpstart -a
```

关闭数据库：

```bash
gpstop -a

gpstop -M fast
```

重启数据库：

```bash
gpstop -ar
```

重新加载配置文件：

```bash
 gpstop -u
```

设置开机启动：

```bash
cat > greenplum.service <<EOF 
[Unit]
Description=greenplum server daemon

[Service]
Restart=on-failure
ExecStart=/usr/local/greenplum-db/bin/gpstart -a
 
[Install]
WantedBy=multi-user.target
EOF

sudo mv greenplum.service /usr/lib/systemd/system/
```



# 清空数据

```bash
#如有报错需重新初始化，清理以下内容：
kill -9 $(ps -ef |grep greenplum|awk '{print $2}')
gpssh -f hostfile_all -e "rm -rf /data/greenplum/master/*"
gpssh -f hostfile_segment -e "rm -rf /{data,data2}/greenplum/{mirror*,primary*}/*"
rm  -f /tmp/.s.PGSQL*.lock
```

# 升级

参考：https://gpdb.docs.pivotal.io/6-2/install_guide/upgrading.html

1、登陆：

```bash
su - gpadmin
```

2、停止数据库

master节点执行：

```bash
gpstop -a
```

3、删除软链接

```bash
sudo rm -rf /usr/local/greenplum-db
```

4、安装新版本：

```bash
sudo yum install greenplum-db-6.2.1-rhel7-x86_64.rpm -y
```

5、设置目录权限

```bash
sudo chown -R gpadmin:gpadmin /usr/local/greenplum*
```

6、设置环境变量

```bash
source ~/.bashrc
```

7、启动数据库

master节点执行：

```bash
gpstart -a
```



# 参考文章

- [greenplum集群的rpm（生产环境）部署及参数优化](https://blog.csdn.net/q936889811/article/details/85603814)
- [Installing the Greenplum Database Software](https://gpdb.docs.pivotal.io/6-1/install_guide/install_gpdb.html)
- [《Greenplum企业应用实战》一第2章 Greenplum快速入门2.1　软件安装及数据库初始化](https://yq.aliyun.com/articles/119215?spm=a2c4e.11154873.tagmain.59.5100732a6Q7ig7)