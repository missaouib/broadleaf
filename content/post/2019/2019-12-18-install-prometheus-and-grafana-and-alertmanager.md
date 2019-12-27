---
layout: post
title: 安装Prometheus、Grafana、Alertmanager
date: 2019-12-18T08:00:00+08:00
categories: [ devops ]
tags: [prometheus、grafana]
---

# 安装Prometheus

1、下载最新版本：https://prometheus.io/download/

```bash
wget https://github.com/prometheus/prometheus/releases/download/v2.14.0/prometheus-2.14.0.linux-amd64.tar.gz

tar zxvf prometheus-2.14.0.linux-amd64.tar.gz 

mv prometheus-2.14.0.linux-amd64 /usr/local/prometheus

cd /usr/local/prometheus/ && ls
```

默认配置文件prometheus.yml：

```yaml
cat prometheus.yml
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

2、配置开启启动服务

```bash
cat > prometheus.service <<EOF 
[Unit]
Description=prometheus server daemon

[Service]
Restart=on-failure
ExecStart=/usr/local/prometheus/prometheus --config.file=/usr/local/prometheus/prometheus.yml
 
[Install]
WantedBy=multi-user.target
EOF

sudo mv prometheus.service /usr/lib/systemd/system/
```

3、启动服务

```bash
sudo systemctl daemon-reload && sudo systemctl start prometheus.service
```

4、浏览器访问 http://192.168.1.111:9090/

# Prometheus配置说明

## 全局配置文件

全局配置文件prometheus.yml，详细说明可以参考官方文档：https://prometheus.io/docs/prometheus/latest/configuration/configuration/

该文件一共包括下面几个部分：

```bash
<scrape_config>
<tls_config>
<azure_sd_config>
<consul_sd_config>
<dns_sd_config>
<ec2_sd_config>
<openstack_sd_config>
<file_sd_config>
<gce_sd_config>
<kubernetes_sd_config>
<marathon_sd_config>
<nerve_sd_config>
<serverset_sd_config>
<triton_sd_config>
<static_config>
<relabel_config>
<metric_relabel_configs>
<alert_relabel_configs>
<alertmanager_config>
<remote_write>
<remote_read>
```

## scrape_configs

我们来看看prometheus.yml文件中的 scrape_configs：

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

这块就是来配置我们要监控的东西，注释说明：

```bash
job_name: <job_name>  ##指定job名字
[ scrape_interval: <duration> | default = <global_config.scrape_interval> ]
[ scrape_timeout: <duration> | default = <global_config.scrape_timeout> ]  ##这两段指定采集时间，默认继承全局
[ metrics_path: <path> | default = /metrics ]  ##metrics路径，默认metrics
[ honor_labels: <boolean> | default = false ]  ##默认附加的标签，默认不覆盖
```

它默认暴露监控数据的接口就是 `ip:9090/metrics`，例如：我们可以访问 http://192.168.1.111:9090/metrics ，返回内容：

```bash
# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 1.0766e-05
go_gc_duration_seconds{quantile="0.25"} 1.6389e-05
go_gc_duration_seconds{quantile="0.5"} 2.1001e-05
go_gc_duration_seconds{quantile="0.75"} 0.00011938
go_gc_duration_seconds{quantile="1"} 0.000171923
go_gc_duration_seconds_sum 0.000398526
go_gc_duration_seconds_count 7
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 40
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.13.4"} 1
```

在 `ip:9090/targets` 能看到当前监控的主机，现在只有本机一个，标签显示也在这里。

![image-20191218160332343](https://tva1.sinaimg.cn/large/006tNbRwgy1ga0xr031yaj31mi0m4whp.jpg)

### 添加标签

去 `WEB` 界面看一下当前被监控端 `CPU` 使用率，查询 process_cpu_seconds_total

![image-20191218160716122](https://tva1.sinaimg.cn/large/006tNbRwgy1ga0xusgzwkj320u0p642o.jpg)

可以看到默认 process_cpu_seconds_total 有两个标签：instance、job。

我们可以更改配置文件，添加一个标签：

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          server: local
```

重启服务：

```bash
sudo systemctl restart prometheus.service
```

刷新一下页面，可以看到多了一个标签：

![image-20191218161054692](https://tva1.sinaimg.cn/large/006tNbRwly1ga0xyk09vzj311e0rqq5s.jpg)

然后，可以根据标签去查询：

```bash
process_cpu_seconds_total{server="local"}

sum(process_cpu_seconds_total{server="local"})
```

### 标签重命名

修改job_name名称：

```yaml
scrape_configs:
  - job_name: 'k8s-test-master001'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          server: local
```

重启服务：

```bash
sudo systemctl restart prometheus.service
```

![image-20191218161439387](https://tva1.sinaimg.cn/large/006tNbRwly1ga0y2gg9u9j30zq0rywhg.jpg)

现在要将 `job` 这个标签标记为 `local`，用 `relabel` 进行重命名：

```yaml
scrape_configs:
  - job_name: 'k8s-test-master001'
    static_configs:
      - targets: ['localhost:9090']
    relabel_configs:
    - action: replace
      source_labels: ['job']  ##源标签
      regex: (.*)             ##正则，会匹配到job值
      replacement: $1         ##引用正则匹配到的内容
      target_label: local     ##赋予新的标签，名为local
```

重启服务，刷新页面，新的数据已经有了，之前的标签还会保留，因为没有配置删除他

![image-20191218161658302](https://tva1.sinaimg.cn/large/006tNbRwly1ga0y4v4ud9j314t0u0n0o.jpg)

上面配置中，action 配置了重新打标签动作，还有其他配置：

| 值        | 描述                                                         |
| --------- | ------------------------------------------------------------ |
| replace   | 默认，通过正则匹配 source_label 的值，使用 replacement 来引用表达式匹配的分组 |
| keep      | 删除 regex 于链接不匹配的目标 source_labels                  |
| drop      | 删除 regex 与连接匹配的目标 source_labels                    |
| labeldrop | 匹配 Regex 所有标签名称                                      |
| labelkeep | 匹配 regex 所有标签名称                                      |
| hashmod   | 设置 target_label 为 modulus 连接的哈希值 source_lanels      |
| labelmap  | 匹配 regex 所有标签名称，复制匹配标签的值分组，replacement 分组引用 (${1},${2}) 替代 |

例如，可以删除标签：

```yaml
scrape_configs:
  - job_name: 'k8s-test-master001'
    static_configs:
      - targets: ['localhost:9090']
    relabel_configs:
    - action: replace
      source_labels: ['job']  ##源标签
      regex: (.*)             ##正则，会匹配到job值
      replacement: $1         ##引用正则匹配到的内容
      target_label: local     ##赋予新的标签，名为local
    - action: drop
      source_labels: ["job"]
```

删除标签为 `job` 的节点，目前只有一个节点，所以这个跑了之后就看不到数据了。

### 删除标签

刚刚新打了一个标签，也就是 `local` 标签，所以之前的 `job` 标签可以删了

```yaml
scrape_configs:
  - job_name: 'k8s-test-master001'
    static_configs:
      - targets: ['localhost:9090']
    relabel_configs:
    - action: replace
      source_labels: ['job']  ##源标签
      regex: (.*)             ##正则，会匹配到job值
      replacement: $1         ##引用正则匹配到的内容
      target_label: local     ##赋予新的标签，名为local
    - action: labeldrop
      regex: job
```

## file_sd_configs

修改配置文件 prometheus.yml：

```yaml
scrape_configs:
  - job_name: 'k8s-test-master001'
    file_sd_configs:
      - files: ['/usr/local/prometheus/files_sd_configs/*.yaml']
        refresh_interval: 5s
```

创建目录：

```bash
mkdir /usr/local/prometheus/files_sd_configs && cd /usr/local/prometheus/files_sd_configs
```

创建配置文件configs.yml 

```bash
cat > configs.yml << EOF
- targets: ['localhost:9090'] 
  labels:
    name: k8s-test-master001
EOF
```

文件保存五秒后就能看到发现的主机了，查数据也没问题

![image-20191218163605773](https://tva1.sinaimg.cn/large/006tNbRwly1ga0yorizu2j31ie0ocjv9.jpg)

# Prometheus监控例子

## 监控服务器

在被监控的服务器上安装 node_exporter 

```bash
wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
tar zxf node_exporter-0.18.1.linux-amd64.tar.gz 
sudo mv node_exporter-0.18.1.linux-amd64 /usr/local/node_exporter
cd /usr/local/node_exporter
```

配置到系统服务中：

```bash
cat > node_exporter.service <<OEF 
[Unit]
Description=node_exporter
 
[Service]
Restart=on-failure
ExecStart=/usr/local/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
OEF

sudo mv node_exporter.service /usr/lib/systemd/system/
```

启动服务：

```bash
sudo systemctl daemon-reload && sudo systemctl start node_exporter.service
```

查看服务状态：

```bash
curl -s 127.0.0.1:9100/metrics | head 
```

修改 prometheus.yml，添加配置：

```yaml
scrape_configs:
  - job_name: 'k8s-test-master001'
    file_sd_configs:
      - files: ['/usr/local/prometheus/files_sd_configs/*.yaml']
        refresh_interval: 5s
  - job_name: 'nodes'
    file_sd_configs:
      - files: ['/usr/local/prometheus/nodes_sd_configs/*.yaml']
        refresh_interval: 5s
```

创建目录：

```bash
mkdir /usr/local/prometheus/nodes_sd_configs && cd /usr/local/prometheus/nodes_sd_configs
```

创建配置文件nodes.yaml：

```yaml
cat > nodes.yaml << EOF
- targets: ['k8s-test-master002:9100'] 
  labels:
    name: k8s-test-master002
EOF
```

重启服务：

```bash
sudo systemctl restart prometheus.service
```

### 查询CPU使用率

查看`nodes CPU` 利用率，以 `node` 开头的 `sql` 都是 `node_expores` 采集的指标

```bash
node_cpu_seconds_total
```

统计最近5分钟cpu使用率：

```bash
100 - irate(node_cpu_seconds_total{mode="idle"}[5m])*100
```

### 查询内存使用率

统计内存使用率：

```bash
100 - (node_memory_MemFree_bytes+node_memory_Cached_bytes+node_memory_Buffers_bytes) / node_memory_MemTotal_bytes *100
```

### 查询硬盘使用率

统计硬盘使用率：

```bash
node_filesystem_files

100- (node_filesystem_free_bytes{mountpoint="/",fstype=~"ext4|xfs"} / node_filesystem_size_bytes{mountpoint="/",fstype=~"ext4|xfs"} *100)
```

### 查询系统服务运行状态

在安装了node_exporter的节点，修改node_exports启动命令，添加两个参数，这里设置的是监听 docker 和 sshd 服务。

```bash
cat > node_exporter.service <<OEF 
[Unit]
Description=node_exporter
 
[Service]
Restart=on-failure
ExecStart=/usr/local/node_exporter/node_exporter --collector.systemd --collector.systemd.unit-whitelist=(docker|sshd).service

[Install]
WantedBy=multi-user.target
OEF

sudo mv node_exporter.service /usr/lib/systemd/system/
```

然后重启服务：

```bash
sudo systemctl daemon-reload  && sudo systemctl restart node_exporter.service 
```

在prometheus界面查看服务状态：

```bash
node_systemd_unit_state{exported_name=~"(docker|sshd).service"}
```



## 监控MySQL

在mysql服务区上安装 [mysql_exporter](https://prometheus.io/download/#mysqld_exporter) 

```bash
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.12.1/mysqld_exporter-0.12.1.linux-amd64.tar.gz
tar zxvf mysqld_exporter-0.12.1.linux-amd64.tar.gz
sudo mv mysqld_exporter-0.12.1.linux-amd64 /usr/local/mysqld_exporter 
cd /usr/local/mysqld_exporter 
```

然后再mysql创建用户和角色：

```bash
mysql> CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'exporter';
Query OK, 0 rows affected (0.02 sec)

mysql> GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
Query OK, 0 rows affected (0.00 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)

mysql> select user,host from mysql.user;
```

需要写一个文件，`mysqld_exporter` 直接读这个文件就可以连接 `mysql` 了，

```bash
cat > my.cnf << EOF
[client]
user=exporter
password=exporter
EOF
```

创建Systemd服务：

```bash
cat > mysqld_exporter.service <<OEF 
[Unit]
Description=mysqld_exporter
After=network.target
 
[Service]
Restart=on-failure
ExecStart=/usr/local/mysqld_exporter/mysqld_exporter -config.my-cnf="/usr/local/mysqld_exporter/my.cnf"

[Install]
WantedBy=multi-user.target
OEF

sudo mv mysqld_exporter.service /usr/lib/systemd/system/
```



直接启动

```shell
systemctl start mysql_exporter
```

可以看到监听端口为 9104。

现在把这个加到prometheus中

```yaml
  - job_name: 'mysql'
    static_configs: 
    - targets: ['192.168.1.75:9104']
```

重启prometheus服务：

```bash
sudo systemctl restart prometheus.service
```

可以监控的指标：

```bash
mysql_up
mysql_global_variables_innodb_buffer_pool_size
```

更多指标可以查看 http://192.168.1.75:9104/metrics 



## 监控Docker

想要监控 `docker` 需要用到名为 `cadvisor` 的工具

直接用 `docker` 去启动就完了，命令如下

```bash
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  google/cadvisor:latest
```

容器启动后也是会暴露一个指标接口，默认是 `8080/metrics`

现在把这个加到prometheus中

```yaml
  - job_name: 'docker'
    static_configs: 
    - targets: ['192.168.1.248:8080']
```

重启prometheus服务：

```bash
sudo systemctl restart prometheus.service
```

可以监控的指标：

## 监控MongoDB

参考 https://github.com/percona/mongodb_exporter

## 监控Redis

参考 https://github.com/oliver006/redis_exporter

# 安装Grafana

docker安装：

```bash
docker run \
 -u 0 \
 -d \
 -p 3100:3000  \
 --name=grafana   \
 -v /var/lib/grafana:/var/lib/grafana \
 -v /etc/grafana/grafana.ini:/etc/grafana/grafana.ini \
 grafana/grafana
```

## 导入Dashboard模板

导入MySQL模板：

```bash
 git clone https://github.com/percona/grafana-dashboards.git
 cp -r grafana-dashboards/dashboards /var/lib/grafana/
 
 vim /etc/grafana/grafana.ini
 [dashboards.json]
 enabled = true
 path = /var/lib/grafana/dashboards
```



# 安装Alertmanager

## 安装并配置

```bash
wget https://github.com/prometheus/alertmanager/releases/download/v0.18.0/alertmanager-0.18.0.linux-amd64.tar.gz
tar zxf alertmanager-0.18.0.linux-amd64.tar.gz 
mv alertmanager-0.18.0.linux-amd64 /usr/local/alertmanager && cd /usr/local/alertmanager 
```

修改配置文件alertmanager.yml 

```yaml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.163.com:25'         #smtp服务地址
  smtp_from: 'xxx@163.com'                  #发送邮箱
  smtp_auth_username: 'xxx@163.com'         #认证用户名
  smtp_auth_password: 'xxxx'                #认证密码
  smtp_require_tls: false                   #禁用tls

route:
  group_by: ['alertname']                #根据标签进行alert分组，可以写多个
  group_wait: 10s                        #发送告警等待时间
  group_interval: 10s                    #分组告警信息间隔时间，譬如两组，第一组发送后等待十秒发送第二组
  repeat_interval: 1m										 #重复发送告警时间，时间不要太短，也不要太长
  receiver: 'email'                      #定义接受告警组名
receivers:                                  
- name: 'email'                          #定义组名
  email_configs:                         #配置邮件
  - to: 'xx@xxx.com'                     #收件人
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
```

检查配置文件是否有问题：

```bash
./amtool check-config alertmanager.yml 
```

添加到系统服务：

```bash
cat > alertmanager.service <<OEF 
[Unit]
Description=alertmanager
 
[Service]
Restart=on-failure
ExecStart=/usr/local/alertmanager/alertmanager --config.file=/usr/local/alertmanager/alertmanager.yml

[Install]
WantedBy=multi-user.target
OEF

sudo mv alertmanager.service /usr/lib/systemd/system/
```

启动服务：

```bash
systemctl start alertmanager
```



修改 prometheus 配置文件：

```yaml
alerting:
  alertmanagers:
  - static_configs:
    - targets:
       - 127.0.0.1:9093   ##配置alertmanager地址，我的在本机

rule_files:
  - "rules/*.yml"         ##配置告警规则的文件
```



## 配置receivers通知

### 配置邮件通知

### 配置钉钉通知

## 创建告警规则

创建一个目录：

```bash
mkdir /usr/local/prometheus/rules
```

创建一个告警规则，监控采集器是否宕机

```bash
groups:
- name: exports.rules     ##定义这组告警的组名，同性质的，都是监控实例exports是否开启的模板
  rules:
  - alert: 采集器凉了     ## 告警名称
    expr: up == 0        ## 告警表达式，监控up指标，如果等于0就进行下面的操作
    for: 1m              ## 持续一分钟为0进行告警
    labels:              ## 定义告警级别
      severity: ERROR
    annotations:         ## 定义了告警通知怎么写，默认调用了{$labels.instance&$labels.job}的值
      summary: "实例 {{ $labels.instance }} 采集器凉了撒"
      description: "实例 {{ $labels.instance }} job 名为 {{ $labels.job }} 的采集器凉了有一分钟了撒"
```

监控内存使用率超过 `80`：

```yaml
groups:
- name: memeory_rules
  rules:
  - alert: 内存炸了
    expr: 100 - (node_memory_MemFree_bytes+node_memory_Cached_bytes+node_memory_Buffers_bytes) / node_memory_MemTotal_bytes * 100 > 80
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "{{ $labels.instance }} 内存炸了"
      description: "{{ $labels.instance }} 内存炸了，当前使用率为 {{ $value }}"
```

监控TCP连接数：

```yaml
groups:
- name: tcp-established_rules
  rules:
  - alert: TCP连接数过高
    expr: node_sockstat_TCP_alloc > 300 
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "{{ $labels.instance }} TCP连接数过高"
      description: "{{ $labels.instance }} TCP连接数过高，当前连接数 {{ $value }}"
```

