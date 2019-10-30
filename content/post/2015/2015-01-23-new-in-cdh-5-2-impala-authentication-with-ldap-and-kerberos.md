---
layout: post

title: CDH 5.2中Impala认证集成LDAP和Kerberos
date: 2015-01-23T08:00:00+08:00

categories: [ impala ]

tags: [ hadoop,kerberos,ldap,impala ]

description:  Impala是基于 Apache Hadoop 的一个开源的分析数据库，使用 Kerberos 和 LDAP 来支持认证-作为一种角色来证明你是否是你所说的你是谁。Kerberos 在1.0版本中就已经被支持了，而 LDAP 是最近才被支持，在 CDH 5.2 中，你能够同时使用两者。

published: true

---

这是一篇翻译的文章，原文为 [New in CDH 5.2: Impala Authentication with LDAP and Kerberos](http://blog.cloudera.com/blog/images/10/new-in-cdh-5-2-impala-authentication-with-ldap-and-kerberos/)。由于翻译水平有限，难免会一些翻译不准确的地方，欢迎指正！

-----

Impala 认证现在可以通过 LDAP 和 Kerberos 联合使用来解决。下文来解释为什么和怎样解决。

Impala，是基于 Apache Hadoop 的一个开源的分析数据库，使用 Kerberos 和 LDAP 来支持认证-作为一种角色来证明你是否是你所说的你是谁。Kerberos 在1.0版本中就已经被支持了，而 LDAP 是最近才被支持，在 CDH 5.2 中，你能够同时使用两者。

同时使用 LDAP 和 Kerberos 提供了显著的价值；Kerberos 保留了核心的认证协议并且总是用在 Impala 进程彼此之间以及和 Hadoop 集群连接的时候。然后，Kerberos 需要更多的维护支持。LDAP 是在整个企业中无处不在，并且通常由通过 ODBC 和 JDBC 驱动程序连接到 Impala 的客户端应用程序来使用。两者的组合使用是有一定道理的。

下表表明了各种组合和它们的使用场景：

|Impala 认证|使用场景|
|:---|:---|
|No Authentication|非安全的集群。我们确定既然你在阅读这篇文章，那你不会对这种场景感兴趣|
| Kerberos Only|Hadoop 集群开启 Kerberos 认证，并且连接到 Impala 的每个用户或者客户端都有一个 Kerberos principal。（详细说明见下文。）|
|LDAP Only|Hadoop 集群 没有开启 Kerberos 认证，但是你想认证连接 Impala 的外包的客户端，如你使用 Active Directory 或者其他的 LDAP 服务。|
|Kerberos and LDAP| Hadoop 集群开启 Kerberos 认证。在 Impala 外部的用户没有 Kerberos principal，但是有一个 LDAP 的凭证。|

![impala-ldap](http://blog.cloudera.com/wp-content/uploads/images/10/impala-ldap-f1.png)

在这篇文章中，我将解释为何以及如何使用 LDAP 和 Kerberos 的组合来建立 Impala 认证。

# 1. Kerberos

Kerberos 仍然是 Apache Hadoop 的主要认证机制。下面是 Kerberos 的一些术语将会帮助你理解这篇文章讨论的内容。

- `principal` 是 Kerberos 主体，就要一个用户或者一个守护进程。对于我们来说，一个 principal 对于守护进程来说是 `name/hostname@realm`，或者对于用户来说仅仅是 `name@realm`。
- `name` 字段可能是一个进程，例如 `impala`，或者是一个用户名，例如 `m`yoder`。
- `hostname` 可能是一个机器的全名称，或者是一个 Hadoop 定义的 _HOST 字符串，通常会机器全名称自动替换。
- `realm` 类似于（但不必要和其一样）一个 DNS 域名。

Kerberos 主体能够证明他们是谁，要么通过提供一个密码（如果主体是人），或者通过提供“密钥表”的文件。 Impala 守护进程需要一个密钥表文件，该文件必须得到很好的保护：任何可以读取密钥表文件的人可以冒充 Impala 守护进程。

Basic support for Kerberos in impala for this process is straightforward: Supply the following arguments, and the daemons will use the given principal and the keys in the keytab file to take on the identity of the principal for all communication.

在 Impala 中对 Kerberos 基本的支持很简单：提供以下参数，守护程序将使用给定的主体和 key，在密钥表文件中验证所有通信的主体的身份。

~~~bash
--principal=impala/hostname@realm
--keytab_file=/full/path/to/keytab
~~~

还有另一外一种情况是 Impala 守护进程（impalad）运行在一个负载均衡器下。

当客户端通过负载平衡器（一个代理）运行查询时，客户端期望 impalad 有一个和负载平衡器的名称的主体。所以当 Impalad 对外部查询提供服务时，需要使用一个和代理相同名称的主体，但是当做后台程序之间的通讯时需要一个主体匹配实际的主机名称。

~~~bash
--principal=impala/proxy-hostname@realm
--be_principal=impala/actual-hostname@realm
--keytab_file=/full/path/to/keytab
~~~

第一个参数 `--principal` 定义 Impalad 服务外部查询时使用哪一个主体，`--be_principal` 参数定义 Impalad 进程之间通信时使用哪一个主体。两个主体的 key 必须存在于相同的 keytab 文件中。

## 调试 Kerberos

Kerberos是一个优雅的协议，但是当出现错误的时候实际的实现不是非常有帮助的。下面主要有两件事情需要检查，在出现认证失败的时候：

- `Time`。Kerberos 是依赖于同步时钟，因此在所有使用 Kerberos 的机器上安装和使用 NTP（网络时间协议）是一个最佳实践。
- `DNS`。请确保您的主机名是全名称的并且正向（名称 - > IP）和反向（IP->名称）DNS查找是否正确。

除此之外，也可以设置两个环境变量以输出 Kerberos 调试信息。输出可能是一小部分的内容，但通常是帮助你解决问题。

- `KRB5_TRACE=/full/path/to/trace/output.log`：该环境变量指定调试日志输出路径。
- `JAVA_TOOL_OPTIONS=-Dsun.security.krb5.debug=true`：该环境变量会传给 Impala 守护进程，并传递给内部的 java 组件。

## Kerberos Flags

[Cloudera documentation for Kerberos and Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/Impala/Installing-and-Using-Impala/ciiu_kerberos.html) 给出了详细的说明，这里只做简要介绍：

![](http://blog.cloudera.com/wp-content/uploads/images/10/impala-auth-tab2.png)

# 2. LDAP

Kerberos 是伟大的，但它确实需要最终用户有一个有效的 Kerberos 证书，这在许多环境中是不实际的，因为每个与 Impala 和Hadoop集群交互的用户都必须配置 Kerberos 主体。对于使用 Active Directory 来管理用户帐户的组织，可能需要在 MIT Kerberos 领域频繁的创建每个用户对应的用户帐户。取而代之的时许多企业环境使用 LDAP 协议，在客户使用自己的用户名和密码进行身份验证自己。

当配置为使用LDAP，把 impalad 看作为一个 LDAP 代理：客户端（ Impala shell，ODBC，JDBC，hue 等等）发送其用户名和密码到 impalad ，然后 impalad 将用户名和密码发送给 LDAP 服务器并尝试登录。在 LDAP 术语中，impalad 发出 LDAP “绑定” 操作。如果 LDAP 服务器为该次登陆尝试返回成功，则 impalad 接受连接。

LDAP只用于验证外部客户，如Impala shell，ODBC，JDBC，和 hue。所有其他后端认证由 Kerberos 的处理。

## LDAP 配置

LDAP 是复杂的（而且强大的），因为它非常灵活；有许多方式来配置 LDAP 实体和验证这些实体。在一般情况下，每个人都在 LDAP 具有专有名称或DN，可被认为是 LDAP 中的用户名或主体。

让我们来看看对于两个不同的LDAP服务器用户是如何设置的。第一个用户名为“Test1 Person”，并存在 Windows2008 Active Directory 中。

~~~
# Test1 Person, Users, ad.sec.cloudera.com
dn: CN=Test1 Person,CN=Users,DC=ad,DC=sec,DC=cloudera,DC=com
cn: Test1 Person
sAMAccountName: test1
userPrincipalName: test1@ad.sec.cloudera.com
~~~

第二个用户是我：用户 myoder 的项，存在于 OpenLDAP 服务器中：

~~~
# myoder, People, cloudera.com
dn: uid=myoder,ou=People,dc=cloudera,dc=com
cn: Michael Yoder
uid: myoder
homeDirectory: /home/myoder
~~~

为了简单，上面中的其他的许多项都被删除了。下面来看看这两个账户的相同点和不同点：

- `DN`：在注释后面的第一行就是 DN。这是一个 LDAP 账户最主要的标识串。
- `CN`：通用名称。对 AD 来说，他和 DN 是一样的；对于 OpenLDAP 来说他是一个人的名称，他不是 DN 中的 uid。
- `sAMAccountName`：只存在 AD 中的条目，是一个用户名称的过时的形式。尽管其过时了，但是被广泛使用中。
- `userPrincipalName`：只存在 AD 中的条目，通过转换，应该映射到用户的邮箱名称。其通常像这样的格式：`sAMAccountName@fully.qualified.domain.com`。这是 Active Directory 更现代的名称并且被广泛使用。

这里还有一些额外有趣的关于 AD 的实现细节。通常，LDAP 认证是基于 DN。对于 AD，下面[几项会被轮流尝试](http://msdn.microsoft.com/en-us/library/cc223499.aspx)：

- 首先，使用 DN
- userPrincipalName
- sAMAccountName + "@" + the DNS domain name
- Netbios domain name + "\" + the sAMAccountName
- 其他的一些机制，请看上面的链接里的内容。

## LDAP 和 Impalad

考虑所有这些的不同点，幸运的是 Impala 进程提供了几个机制去标识 LDAP 的配置。首先，使用简单的配置：

- `--enable_ldap_auth` 必须设置为 true
- `--ldap_uri=ldap://ldapserver.your.company.com` 必须定义

仅仅设置这些，传递给 impalad 的用户名（通过 impala shell、jdbc、odbc 等等）直接传递到 LDAP 服务器。这个过程对于 AD 来说没什么问题，如果用户名称是全名称，就像 `test1@ad.sec.cloudera.com` - 其使用 `userPrincipal` 或者 `sAMAccountName` 加上 DNS 域名都会匹配上。

也可以设置 impalad 启动参数以便 这域名（在当前情况下是 `ad.sec.cloudera.com` ）可以自动添加到 用户名上，这需要通过设置参数 `--ldap_domain=ad.sec.cloudera.com` 添加到 impalad 的启动参数中。现在，当一个客户端用户访问时，例如 test1 用户，其会将域名名称追加到用户名称之后以便追加后的结果 `test1@ad.sec.cloudera.com` 传递给 AD 。这种方式对于你的用户来说是很方便的。

目前，对于 AD 来说都运行正常。但是对于其他的 LDAP 服务器，例如 OpenLDAP 呢？OpenLDAP 没有 sAMAccountName 或者 userPrincipalName 中的任何一个，取而代之的是我们不得不直接使用 DN 进行认证。用户将不会去关心他们的 LDAP DN！

幸运地是，impalade 对于这种场景也提供了一些参数。`--ldap_baseDN=X` 参数用户将用户名称转换为 LDAP DN，以便这个 DN 结果看上去像 `uid=username,X`。例如，如果设置 `--ldap_baseDN=ou=People,dc=cloudera,dc=com `，传递的用户名是 myoder，传到到 LDAP 的查询将是 `uid=myoder,ou=People,dc=cloudera,dc=com`，这将会和 myoder 的 DN 想匹配。

为了获得最大的灵活性，也可以通过 `--ldap_bind_pattern` 参数将指定用户名任意映射到一个DN。这个想法是，该参数中必须有一个名称为 #UID 的占位符，并且 `#UID` 会被用户名替代。例如你可以通过指定 `--ldap_bind_pattern=uid=#UID,ou=People,dc=cloudera,dc=com` 来定义 `--ldap_baseDN`。当 myoder 这个用户进来时，其将会替换 `#UID`，并且我们将得到和上面一直的字符串。这个参数应该在需要对 DN 有更多控制的时候才使用。

## LDAP 和 TLS

当使用 LDAP 时，传递个 LDAP 服务器的用户名和密码都是明文的。这意味着没有任何的保护，任何人都可以看到传输中的密码。为了阻止这一点，你必须使用 TLS（Transport Layer Security，更为人熟知的是 SSL） 来保护连接。 这里有两种不同的连接需要保护：客户端和 impalad 进程之间以及 impalad 进程和 LDAP 服务器之间。

### 客户端和 impalad 之间

TLS 连接的认证需要使用证书来完成，所以 impalad 进程（作为 TLS server）需要他自己的证书。Impalad 呈现该证书给客户端以证明他的确是 impalad 进程。为了提供该证书，impalad 进程需要设置下面两个参数：

~~~bash
--ssl_server_certificate=/full/path/to/impalad-cert.pem 
--ssl_private_key=/full/path/to/impalad-key.pem
~~~

现在客户端必须使用 TLS 和 impalad 通信。在 impala-shell 中，你必须设置 `--ssl` 和 `--ca_cert=/full/path/to/ca-certificate.pem` 这两个参数。ca_cert 参数必须指定为上面 `ssl_server_certificate` 参数定义的值。对于 ODBC 连接来说，请参考 [ the Cloudera ODBC driver for Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/Connectors/PDF/Cloudera-ODBC-Driver-for-Impala-Install-Guide.pdf)。其提供了一个全面的描述。关于设置证书、认证和 TLS 的必要性。

坦白地说，在 impala 客户端和 impalad 进程之间使用 TLS 是一个很好的想法，不管是否使用 LDAP。然而，你的查询，以及这些查询的结果都是通过明文传输的。

### Impalad 和 LDAP 服务器之间

这里有两种方法开启和 LDAP 服务器之间的 TLS ：

- 在 impalad 启动参数中添加 `--ldap_tls`。该连接会使用 LDAP 的端口，但是在第一次连接之后，会发送一个 `STRATETLS` 的请求，该请求会使用 TLS 升级该连接为一个安全的连接并且使用相同的端口。
- URL 使用 `ldaps://` 开头。这将会使用一个不同于  `ldap://` 的端口。

最后，到 LDAP 服务器的连接需要他自己的认证；在这种情况下，你知道 impalad 是在和正确的 ldap 服务器通话并且你不会将你的密码发送给一个无赖的人为工具的请求。你需要添加 `--ldap_ca_certificate` 参数到 impalad 定义 LDAP 服务器的证书存放的位置。

### LDAP Flags

[Cloudera documentation for LDAP and Impala](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/Impala/Installing-and-Using-Impala/ciiu_ldap.html) 一文包括这部分的信息，并且建议你阅读 [TLS between the Impala client and the Impala daemon](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/Impala/Installing-and-Using-Impala/ciiu_ssl.html) 这篇文章。

![](http://blog.cloudera.com/wp-content/uploads/images/10/impala-auth-tab3.png)

# 3. 一起使用

如果我们想同事使用 Kerberos 和 LDAP 认证，则需要如下配置：

~~~bash
impalad --enable_ldap_auth \
    --ldap_uri=ldap://ldapserver.your.company.com \
    --ldap_tls \
    --ldap_ca_certificate=/full/path/to/certs/ldap-ca-cert.pem \
    --ssl_server_certificate=/full/path/to/certs/impala-cert.pem \
    --ssl_private_key=/full/path/to/certs/impala-key.pem \
    --principal=impala/_HOST@EXAMPLE.COM \
    --keytab_file=/full/path/to/keytab
~~~

当使用 Kerberos 认证时，使用  impala shell 连接：

~~~bash
impala-shell.sh --ssl \
    --ca_cert=/full/path/to/cert/impala-ca-cert.pem \
    -k
~~~

当使用 LDAP 认证时：

~~~bash
impala-shell.sh --ssl \
   --ca_cert=/full/path/to/cert/impala-ca-cert.pem \
   -l -u myoder@cloudera.com
~~~

原文作者为 Michael Yoder，Cloudera 软件工程师。






