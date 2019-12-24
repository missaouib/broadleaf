---
layout: post
title: Rancher使用letsEncrypt生成证书并做DNS01校验
date: 2019-11-07T08:00:00+08:00
categories: [ kubernetes ]
tags: [kubernetes,rancher,tls]
---

前面[使用Helm安装Rancher HA集群](/2019/11/03/install-rancher-ha-with-helm/)，配置证书的时候，因为没有权威证书，所以测试过利用Rancher和自签名文件来生成证书，但是生成的证书在浏览器不被信任。当时，也测试过通过letsEncrypt来生成，但是没有配置成功。把Rancher的Chart源码阅读之后，将源码修改了，增加了DNS01校验方式，最后测试成功。

在阅读本文章之前，先阅读以下两篇文章：

- [使用Helm安装Rancher HA集群](/2019/11/03/install-rancher-ha-with-helm/)
- [使用Cert Manager配置Let’s Encrypt证书](/2019/11/04/using-cert-manager-with-nginx-ingress/)



# 版本说明

版本说明：

- Rancher：v2.3.3
- Cert-Manager：v0.12.0



# Rancher Chart源码

Rancher Chart源码在 https://github.com/rancher/rancher/tree/master/chart ，当前rancher版本为2.3.3，可以看下[创建Issuer的源码](https://github.com/rancher/rancher/blob/master/chart/templates/issuer-letsEncrypt.yaml) issuer-letsEncrypt.yaml：

```yaml
{{- if eq .Values.tls "ingress" -}}
  {{- if eq .Values.ingress.tls.source "letsEncrypt" -}}
    {{- if .Capabilities.APIVersions.Has "cert-manager.io/v1alpha2" -}}
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: {{ template "rancher.fullname" . }}
  labels:
    app: {{ template "rancher.fullname" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    heritage: {{ .Release.Service }}
    release: {{ .Release.Name }}
spec:
  acme:
    {{- if eq .Values.letsEncrypt.environment "production" }}
    server: https://acme-v02.api.letsencrypt.org/directory
    {{- end }}
    {{- if eq .Values.letsEncrypt.environment "staging" }}
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    {{- end }}
    email: {{ .Values.letsEncrypt.email }}
    privateKeySecretRef:
      name: letsencrypt-{{ .Values.letsEncrypt.environment }}
    solvers:
    - http01:
        ingress:
          class: nginx
    {{- else if .Capabilities.APIVersions.Has "certmanager.k8s.io/v1alpha1" -}}
apiVersion: certmanager.k8s.io/v1alpha1
kind: Issuer
metadata:
  name: {{ template "rancher.fullname" . }}
  labels:
    app: {{ template "rancher.fullname" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    heritage: {{ .Release.Service }}
    release: {{ .Release.Name }}
spec:
  acme:
    {{- if eq .Values.letsEncrypt.environment "production" }}
    server: https://acme-v02.api.letsencrypt.org/directory
    {{- end }}
    {{- if eq .Values.letsEncrypt.environment "staging" }}
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    {{- end }}
    email: {{ .Values.letsEncrypt.email }}
    privateKeySecretRef:
      name: letsencrypt-{{ .Values.letsEncrypt.environment }}
    http01: {}
    {{- end -}}
  {{- end -}}
{{- end -}}
```

可以看到

- letsEncrypt使用的是http01校验，因为服务器上没有配置web服务器，所以用该方式校验比较麻烦，故改为dns01方式校验。
- 正对certmanager的api版本做了兼容



# 添加DNS01校验

参考 [使用Cert Manager配置Let’s Encrypt证书](/2019/11/04/using-cert-manager-with-nginx-ingress/) 这篇完整，我们可以利用 [cert-manager-webhook-godaddy](https://github.com/inspectorioinc/cert-manager-webhook-godaddy) 通过webhook的方式进行dns01校验。

> 注意：请先安装 cert-manager-webhook-godaddy ，再往下操作

其创建issuer代码如下：

```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: junecloud@163.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - selector:
        dnsNames:
        - '*.javachen.space'
      dns01:
        webhook:
          groupName: acme.javachen.space 
          solverName: godaddy
          config:
            authApiKey: e4hN4QrFgzdo_RHXe1ef2qpBPmiJPD2ZUcW
            authApiSecret: XXXXXXXX
            production: true
            ttl: 600
```

对比上面两个yaml文件，我们修改Rancher Chart源码，将http01改为solvers：

```yaml
    solvers:
    - selector:
        dnsNames:
        - '*.javachen.space'
      dns01:
        webhook:
          groupName: acme.javachen.space 
          solverName: godaddy
          config:
            authApiKey: e4hN4QrFgzdo_RHXe1ef2qpBPmiJPD2ZUcW
            authApiSecret: XXXXXXXX
            production: true
            ttl: 600
```

# 修改Rancher Chart源码

查看 Rancher Chart：

```bash
$ helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

$ helm search rancher
NAME                  	CHART VERSION	APP VERSION	DESCRIPTION
rancher-stable/rancher	2.3.3        	v2.3.3     	Install Rancher Server to manage Kubernetes clusters ...
```

下载chart：

```bash
helm fetch rancher-stable/rancher
tar zxvf rancher-2.3.3.tgz
```

查看rancher/templates/issuer-letsEncrypt.yaml：

```yaml
{{- if eq .Values.tls "ingress" -}}
  {{- if eq .Values.ingress.tls.source "letsEncrypt" -}}
apiVersion: certmanager.k8s.io/v1alpha1
kind: Issuer
metadata:
  name: {{ template "rancher.fullname" . }}
  labels:
    app: {{ template "rancher.fullname" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    heritage: {{ .Release.Service }}
    release: {{ .Release.Name }}
spec:
  acme:
    {{- if eq .Values.letsEncrypt.environment "production" }}
    server: https://acme-v02.api.letsencrypt.org/directory
    {{- end }}
    {{- if eq .Values.letsEncrypt.environment "staging" }}
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    {{- end }}
    email: {{ .Values.letsEncrypt.email }}
    privateKeySecretRef:
      name: letsencrypt-{{ .Values.letsEncrypt.environment }}
    http01: {}
  {{- end -}}
{{- end -}}
```

可以看到rancher2.3.3的chart中还是使用的certmanager.k8s.io/v1alpha1 API。

所以，建议还是下载  https://github.com/rancher/rancher/tree/master/chart  源码进行修改。

```bash
git clone https://github.com/rancher/rancher

cd rancher
```

修改chart/templates/issuer-letsEncrypt.yaml：

```bash
{{- if eq .Values.tls "ingress" -}}
  {{- if eq .Values.ingress.tls.source "letsEncrypt" -}}
    {{- if .Capabilities.APIVersions.Has "cert-manager.io/v1alpha2" -}}
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: {{ template "rancher.fullname" . }}
  labels:
    app: {{ template "rancher.fullname" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    heritage: {{ .Release.Service }}
    release: {{ .Release.Name }}
spec:
  acme:
    {{- if eq .Values.letsEncrypt.environment "production" }}
    server: https://acme-v02.api.letsencrypt.org/directory
    {{- end }}
    {{- if eq .Values.letsEncrypt.environment "staging" }}
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    {{- end }}
    email: {{ .Values.letsEncrypt.email }}
    privateKeySecretRef:
      name: letsencrypt-{{ .Values.letsEncrypt.environment }}
{{- if .Values.letsEncrypt.solvers  }}   
    solvers:  
{{ toYaml .Values.letsEncrypt.solvers | indent 4 }}
{{- else }}
    solvers:
    - http01:
        ingress:
          class: nginx
{{- end }}        
    {{- else if .Capabilities.APIVersions.Has "certmanager.k8s.io/v1alpha1" -}}
apiVersion: certmanager.k8s.io/v1alpha1
kind: Issuer
metadata:
  name: {{ template "rancher.fullname" . }}
  labels:
    app: {{ template "rancher.fullname" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    heritage: {{ .Release.Service }}
    release: {{ .Release.Name }}
spec:
  acme:
    {{- if eq .Values.letsEncrypt.environment "production" }}
    server: https://acme-v02.api.letsencrypt.org/directory
    {{- end }}
    {{- if eq .Values.letsEncrypt.environment "staging" }}
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    {{- end }}
    email: {{ .Values.letsEncrypt.email }}
    privateKeySecretRef:
      name: letsencrypt-{{ .Values.letsEncrypt.environment }}
{{- if .Values.letsEncrypt.solvers  }}   
    solvers:  
{{ toYaml .Values.letsEncrypt.solvers | indent 4 }}
{{- else }}
    http01: {}
{{- end }}  
    {{- end -}}
  {{- end -}}
{{- end -}}
```

修改rancher/templates/ingress.yaml代码：

```yaml
	{{- if ne .Values.ingress.tls.source "secret" }}
    {{- if .Capabilities.APIVersions.Has "cert-manager.io/v1alpha2" }}
    cert-manager.io/cluster-issuer: {{ template "rancher.fullname" . }}
    {{- else if .Capabilities.APIVersions.Has "certmanager.k8s.io/v1alpha1" }}
    certmanager.k8s.io/issuer: {{ template "rancher.fullname" . }}
    {{- end }}
  {{- end }}
```

- 说明：将 cert-manager.io/issuer 改为 cert-manager.io/cluster-issuer

修改rancher/values.yaml，在environment下面添加`solvers: []`

```
letsEncrypt:
  # email: none@example.com
  environment: production
  solvers: []
```

最后修改Chart.yaml设置版本：

```yaml
apiVersion: v1
name: rancher
description: Install Rancher Server to manage Kubernetes clusters across providers.
version: 2.3.3
appVersion: v2.3.3
home: https://rancher.com
icon: https://github.com/rancher/ui/blob/master/public/assets/images/logos/welcome-cow.svg
keywords:
  - rancher
sources:
  - https://github.com/rancher/rancher
  - https://github.com/rancher/server-chart
maintainers:
  - name: Rancher Labs
    email: charts@rancher.com
```



# 安装Rancher

创建rancher-values.yaml：

```bash
cat <<EOF > rancher-values.yaml
hostname: rancher.javachen.space
ingress:
  tls:
    source: letsEncrypt
letsEncrypt:
  email: junecloud@163.com
  environment: production
  solvers: 
  - selector:
      dnsNames:
      - 'rancher.javachen.space'
    dns01:
      webhook:
        groupName: acme.javachen.space 
        solverName: godaddy
        config:
          authApiKey: e4hN4QrFgzdo_RHXe1ef2qpBPmiJPD2ZUcW
          authApiSecret: QsHuDdnnCbzp5DmEQzq4ts
          production: true
          ttl: 600
EOF
```

从本地chart文件安装：

```bash
helm install rancher --namespace cattle-system \
	./rancher -f rancher-values.yaml
```

查看证书：

```bash
$ kubectl get secret,certificate,ClusterIssuer -n cattle-system

NAME                                   TYPE                                  DATA   AGE
secret/cattle-token-zwq9x              kubernetes.io/service-account-token   3      27s
secret/default-token-ps9vd             kubernetes.io/service-account-token   3      27s
secret/rancher-token-wcdlh             kubernetes.io/service-account-token   3      10s
secret/sh.helm.release.v1.rancher.v1   helm.sh/release.v1                    1      10s
secret/tls-rancher-ingress             kubernetes.io/tls                     3      26s

NAME                                              READY   SECRET                AGE
certificate.cert-manager.io/tls-rancher-ingress   False   tls-rancher-ingress   10s

NAME                                    READY   AGE
clusterissuer.cert-manager.io/rancher   True    10s
```

可以看到letsEncrypt自动创建了证书 rancher-letsencrypt-prod ，查看证书状态：

```
kubectl describe clusterissuer rancher -n cattle-system

kubectl describe certificate tls-rancher-ingress -n cattle-system

kubectl describe CertificateRequest tls-rancher-ingress-2667258947 -n cattle-system

kubectl describe order tls-rancher-ingress-2667258947 -n cattle-system

kubectl describe Challenge tls-rancher-ingress-2667258947-2022664050-2433006835 -n cattle-system
```

当tls-rancher-ingress状态为true时候，证书就创建成功了。

```bash
$ kubectl get certificate tls-rancher-ingress -n cattle-system
NAME                  READY   SECRET                AGE
tls-rancher-ingress   True    tls-rancher-ingress   35m
```

如果出错，根据日志提示进行排查原因。

查看rancher状态：

```
kubectl -n cattle-system rollout status deploy/rancher

kubectl -n cattle-system get deploy rancher
```

# 浏览器访问

先在本地配置hosts：

```bash
192.168.56.111 rancher.javachen.space
```

浏览器访问 https://rancher.javachen.space/

![image-20191123193359459](https://tva1.sinaimg.cn/large/006y8mN6gy1g987c68rlwj30z20kojt0.jpg)

# 卸载重装

```bash
helm del rancher -n cattle-system

kubectl delete pod,service,deploy,ingress,secret,pvc,replicaset,daemonset --all -n cattle-system

kubectl delete ServiceAccount,ClusterRoleBinding,Role,clusterissuer rancher -n cattle-system
```

# 升级版本

从源代码chart升级：

```bash
helm upgrade rancher --namespace cattle-system \
	./rancher --version v2.3.3 -f rancher-values.yaml
```

> 通过`--version`指定升级版本，`镜像tag`不需要指定，会自动根据chart版本获取。

查看状态：

```bash
kubectl -n cattle-system rollout status deploy/rancher

kubectl -n cattle-system get deploy rancher
```

# 总结

我将修改后的rancher chart源代码提交到了 https://github.com/javachen/charts ，欢迎提意见。
