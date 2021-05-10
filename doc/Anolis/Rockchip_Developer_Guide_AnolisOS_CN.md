# Rockchip CentOS Developer Guide

文件标识：RK-KF-YF-998

发布版本：V1.0.0

日       期：2021-05-08

文件密级：□绝密   □秘密   □内部资料   ■公开

**免责声明**

本文档按“现状”提供，瑞芯微电子股份有限公司（“本公司”，下同）不对本文档的任何陈述、信息和内容的准确性、可靠性、完整性、适销性、特定目的性和非侵权性提供任何明示或暗示的声明或保证。本文档仅作为使用指导的参考。

由于产品版本升级或其他原因，本文档将可能在未经任何通知的情况下，不定期进行更新或修改。

**商标声明**

“Rockchip”、“瑞芯微”、“瑞芯”均为本公司的注册商标，归本公司所有。

本文档可能提及的其他所有注册商标或商标，由其各自拥有者所有。

**版权所有© 2021 瑞芯微电子股份有限公司**

超越合理使用范畴，非经本公司书面许可，任何单位和个人不得擅自摘抄、复制本文档内容的部分或全部，并不得以任何形式传播。

瑞芯微电子股份有限公司

Rockchip Electronics Co., Ltd.

地址：福建省福州市铜盘路软件园A区18号

网址：[www.rock-chips.com](http://www.rock-chips.com)

客户服务电话： +86-4007-700-590

客户服务传真： +86-591-83951833

客户服务邮箱： [fae@rock-chips.com](mailto:fae@rock-chips.com)

---

**前言**

 **概述**

 本文档简单介绍 Centos 编译、配置、使用、以及开发过程中注意事项。|

**产品版本**

| **芯片名称**             | **系统版本** | **内核版本** |
| ----------- | ----------- | ------------ |
| RK3399 | AnolisOS 8.2 rc2 | Linux 4.19    |

**读者对象**

本文档（本指南）主要适用于以下工程师：

 技术支持工程师

软件开发工程师

 **修订记录**

| **日期**   | **版本** | **作者**    | **修改说明**     |
| ---------- | -------- | :---------- | ---------------- |
| 2020-05-08 | V1.0.0   | Caesar Wang| 初始版本         |

---

 **目录**

[TOC]

---

## CentOS基础环境搭建

###   背景介绍


OpenAnolis操作系统社区提供有Anolis OS的公测下载
注意：整个安装过程和CentOS 8高度一致，并且里面的很多应用和技巧都沿用CentOS 8的，因此你可以参考CentOS 8的技术文档。

关于Anolis OS和OpenAnolis的介绍

1、关于Anolis OS

由阿里云、统信软件及众多社区伙伴联合在社区发起的Anolis OS开源发行版，支持多计算架构，提供稳定、高性能、安全、可靠的开源操作系统，短期目标是开发Anolis OS 8作为CentOS替代版，重新构建一个兼容国际主流Linux厂商发行版，中长期目标是探索打造一个面向未来的操作系统。

2、关于OpenAnolis

OpenAnolis是一个开源操作系统社区及系统软件创新平台，致力于通过开放的社区合作，推动软硬件及应用生态繁荣发展，共同构建云计算系统技术底座。OpenAnolis为云而生，是面向云的开源操作系统社区，是云原生系统，具有全栈开源生态，同时它开放、创新，是开放的创新平台。

参考：OpenAnolis开源社区介绍：开发Anolis OS 8来替代CentOS。

Anolis OS公测iso下载地址

OpenAnolis网站：https://openanolis.org/

下载总地址：http://mirrors.openanolis.org/

Anolis OS目录：http://mirrors.openanolis.org/anolis/

ISO的安装文件. 需要EFI来引导安装.如果是aarch64架构的CPU用的是U-BOOT启动, 就不能直接用官方方式更新固件. 下面讲述如何从官方镜像中提取rootfs用Uboot启动系统。

### Anolis OS rootfs 制作

下载Anolis 8.2 RC2 的安装包AnolisOS-8.2-RC2-aarch64-dvd.iso, 网址:http://mirrors.openanolis.org/anolis/8/isos/RC2/aarch64/


mount AnolisOS-8.2-RC2-aarch64-dvd.iso 后提取install.img镜像内部文件：LiveOS/rootfs.img，此文件实际上即是anolis的rootfs文件，但是不能直接使用。继续将install.img mount起来，然后进入mount的路径继续mount 文件LiveOS/rootfs.img，然后即可看到anolis os的整个内部文件系统了.

如果仅复制这些文件到根系统，通过uboot加载启动，你会发现系统根本无法启动，这是因为此rootfs默认启动方式为anaconda启动，uboot引导进入anaconda模式后会直接卡死。复制目录下的所有文件到根系统目录，删除

```
/etc/systemd/system/default.target
```

建立软连接

```
ln -s /usr/lib/systemd/system/multi-user.target etc/systemd/system/default.target
```

引导系统启动后进入multi-user模式。此时即可进入到centos系统，用户root，密码无，此时centos为纯净系统，除了基本命令外不带其他任何第三方命令，包括passwd、sudo、openssh、telnet、net-tools等等均没有，且yum命令报错找不到import yummain模块，无法使用。

复制AnolisOS-8.2-RC2-aarch64-dvd.iso 中，Packages目录与yum相关的四个rmp包

├── anolis-release-8.2-7.an8.aarch64.rpm
├── anolis-repos-8.2-7.an8.aarch64.rpm
├── yum-4.2.17-6.0.1.an8.noarch.rpm
└── yum-utils-4.0.12-3.el8.noarch.rpm


然后启动进入centos后执行：

```
rpm2cpio /packages/base/anolis-release-8.2-7.an8.aarch64.rpm|cpio -idumv
rpm2cpio /packages/base/anolis-repos-8.2-7.an8.aarch64.rpm|cpio -idumv
rpm2cpio /packages/base/yum-4.2.17-6.0.1.an8.noarch.rpm|cpio -idumv
rpm2cpio /packages/base/yum-utils-4.0.12-3.el8.noarch.rpm|cpio -idumv

```

修改文件/etc/yum.repos.d/*.repo中所有$releasever为8

（可在vim中输入：%s/$releasever/8/g来全局替换）

然后yum -help，yum命令已经可以使用.

### 网络的配置

Anolis OS使用ip参考相关网络配置,  比如ip addr

Ip  [选项]  操作对象{link|addr|route...}

```
# ip link show                           # 显示网络接口信息
# ip link set eth0 up                  # 开启网卡
# ip link set eth0 down                  # 关闭网卡
# ip link set eth0 promisc on            # 开启网卡的混合模式
# ip link set eth0 promisc offi          # 关闭网卡的混个模式
# ip link set eth0 txqueuelen 1200       # 设置网卡队列长度
# ip link set eth0 mtu 1400              # 设置网卡最大传输单元
# ip addr show                           # 显示网卡IP信息
# ip addr add 192.168.0.1/24 dev eth0    # 设置eth0网卡IP地址192.168.0.1
# ip addr del 192.168.0.1/24 dev eth0    # 删除eth0网卡IP地址
# ip route list                                            # 查看路由信息
# ip route add 192.168.4.0/24  via  192.168.0.254 dev eth0 # 设置192.168.4.0网段的网关为192.168.0.254,数据走eth0
# ip route add default via  192.168.0.254  dev eth0        # 设置默认网关为192.168.0.254
# ip route del 192.168.4.0/24                              # 删除192.168.4.0网段的网关
# ip route del default                                     # 删除默认路由
```
这里链接了一个eth0的以太网, /etc/sysconfig/network-scripts目录中看一下的网卡ip信息的配置文件名., 这边自己配置了ifcfg-eth0的文件.

```
[anaconda root@localhost ~]# cat /etc/sysconfig/network-scripts/ifcfg-eth0                                                                    
HWADDR=62:A4:32:19:BD:51
TYPE=Ethernet
BOOTPROTO=dhcp
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
NAME=eth0
UUID=5b0a7d76-1602-4e19-aee6-29f57618ca01
ONBOOT=yes
```
重启网络, ip addr就会发现,获取到相关ip了.

```
[anaconda root@localhost ~]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 62:a4:32:19:bd:51 brd ff:ff:ff:ff:ff:ff
    inet 172.16.21.219/24 brd 172.16.21.255 scope global noprefixroute dynamic eth0
       valid_lft 85239sec preferred_lft 85239sec
    inet6 fdcf:2c4b:554d::116/128 scope global noprefixroute 
       valid_lft forever preferred_lft forever
    inet6 fdcf:2c4b:554d:0:60a4:32ff:fe19:bd51/64 scope global noprefixroute 
       valid_lft forever preferred_lft forever
    inet6 fe80::60a4:32ff:fe19:bd51/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```
如果想固定IP, 可以这么设置:

```
vi /etc/sysconfig/network-scripts/ifcfg-eth0，输入以下参数，再用#将BOOTPROTO=dhcp注释。
IPADDR0=172.16.21.211
PREFIX0=24
GATEWAY0=172.16.21.1
DNS1=172.16.21.1
````
这样网络就配置起来了.

```
[anaconda root@localhost ~]# ping www.baidu.com
PING www.a.shifen.com (163.177.151.110) 56(84) bytes of data.
64 bytes from 163.177.151.110 (163.177.151.110): icmp_seq=1 ttl=55 time=17.8 ms
64 bytes from 163.177.151.110 (163.177.151.110): icmp_seq=2 ttl=55 time=17.8 ms
64 bytes from 163.177.151.110 (163.177.151.110): icmp_seq=3 ttl=55 time=17.7 ms
64 bytes from 163.177.151.110 (163.177.151.110): icmp_seq=4 ttl=55 time=17.8 ms
64 bytes from 163.177.151.110 (163.177.151.110): icmp_seq=5 ttl=55 time=18.1 ms
64 bytes from 163.177.151.110 (163.177.151.110): icmp_seq=6 ttl=55 time=17.7 ms
```

其他网络, USB以太网, WIFI配置方法一样.

更多参考 https://www.cnblogs.com/qiezizi/p/8004333.html

通过ip addr 配置ip后，即可用yum安装基本的命令和一些第三方常用库如：passwd、sudo、openssh、telnet、net-tools等。

```
[anaconda root@localhost ~]# yum update
Plugin "product-id" can't be imported
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile
 * base: mirror.xtom.com.hk
 * extras: mirror.xtom.com.hk
 * updates: mirror.xtom.com.hk
base                                                     | 3.6 kB     00:00     
extras                                                   | 2.9 kB     00:00     
updates                                                  | 2.9 kB     00:00   

[anaconda root@localhost /]# yum install -y sudo passwd openssh telnet net-tools openssh-server
Plugin "product-id" can't be imported
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile

Plugin "product-id" can't be imported
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile
 * base: mirror.xtom.com.hk
 * extras: mirror.xtom.com.hk
 * updates: mirror.xtom.com.hk
Resolving Dependencies
--> Running transaction check
---> Package sudo.aarch64 0:1.8.23-10.el7_9.1 will be installed
--> Processing Dependency: rtld(GNU_HASH) for package: sudo-1.8.23-10.el7_9.1.aarch64
--> Processing Dependency: libutil.so.1(GLIBC_2.17)(64bit) for package: sudo-1.8.23-10.el7_9.1.aarch64
--> Processing Dependency: libpam.so.0(LIBPAM_1.0)(64bit) for package: sudo-1.8.23-10.el7_9.1.aarch64
--> Processing Dependency: libgcrypt.so.11(GCRYPT_1.2)(64bit) for 
...
```
### 显示桌面的安装

官方的镜像是不带任何显示服务，需要自行安装。安装方法参考如下：

```
[anaconda root@localhost /]# yum groupinstall "Server with GUI"
...
```

重启即可, 想安装即可桌面

```
[anaconda root@localhost /]# yum grouplist 
Plugin "product-id" can't be imported
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile
 * base: mirror.worria.com
 * extras: mirror.worria.com
 * updates: mirror.worria.com
Installed Environment Groups:
   GNOME Desktop
Available Environment Groups:
   Minimal Install
   Compute Node
   Infrastructure Server
   File and Print Server
   Basic Web Server
   Virtualization Host
   Server with GUI
   KDE Plasma Workspaces
   Development and Creative Workstation
Available Groups:
   Compatibility Libraries
   Console Internet Tools
   Development Tools
   Graphical Administration Tools
   Legacy UNIX Compatibility
   Scientific Support
   Security Tools
   Smart Card Support
   System Administration Tools
   System Management
Done
```

## 安全启动

可以参考文档:
AVB 文档:<SDK>/tools/linux/Linux_SecurityAVB/Rockchip_User_Manual_Linux_AVB_EN.pdf
AB 文档: <SDK>/docs/Linux/Recovery/Rockchip_Developer_Guide_Linux_Upgrade_CN.pdf
Secureboot文档: <SDK>/Linux/Security/Rockchip_Developer_Guide_Linux_Secure_Boot_CN.pdf
下面介绍DMV的方式:

补丁主要有以下4部分:

├── PATCHES
│   ├── device
│   │   └── rockchip
│   │       └── local_diff.patch
│   ├── kernel
│   │   ├── 0001-arm64-dts-rockchip-update-secureity-optee.patch
│   │   └── git-merge-base.txt
│   ├── tools
│   │   └── local_diff.patch
│   └── u-boot
│       ├── 0001-uboot-add-fastboot-optee.patch
│       └── git-merge-base.txt

- uboot/rkbin (uboot/ 加 A/B，大小超了，去掉display, config用defconfig,除开customkey烧写，其他修改都是文档上有的)

  └── u-boot
      ├── 0001-uboot-add-fastboot-optee.patch

- kernel/ (config + dts)

  ├── kernel
  │   ├── 0001-arm64-dts-rockchip-update-secureity-optee.patch

- external/security/rk_user_tee/v1 补丁，base 不一样，可以直接手动打到191服务器v1目录下,注意CA是32位的，需要配编译链)
│   ├── patches
│   │   ├── 0001-testapp-keystore-and-uboot-storage.patch

- tools/Linux_SecurityDM(替换ramdisk, 主要是需要添加TA程序做key master. config 按已有规格走，系统输入参数用inputimg=）
Linux_SecurityDM用以下压缩包,替换原来的tools/linux/Linux_SecurityDM的内容
```
链接: https://pan.baidu.com/s/1Jfy0FFeovtuXVas_DCXH-Q 提取码: x8qx 
```

## 固件

链接: https://pan.baidu.com/s/1tBFlvVivtn0YQIFJ7XpF2A 提取码: bgr9

## Kernel 4.19

注意：这样使用的aarch64 centos系统 yum安装社区的命令等等均没有什么问题，唯一需要清除一点，因为内核用的是自己的，而不是官方的，所以如果安装的第三方命令需要内核支持的话需要自己打开相关选项重新编译自己的内核.

目前可以参考的源码:
https://github.com/rockchip-linux/kernel/tree/develop-4.19

编译方法跟Kernel4.4一样

## 其他问题

如果遇到空间不够,  可以扩展下或者parameter分配足够空间给rootf分区

```
[anaconda root@localhost ~]# resize2fs /dev/mmcblk1p8 
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/mmcblk1p8 is mounted on /; on-line resizing required
old_desc_blocks = 16, new_desc_blocks = 48
The filesystem on /dev/mmcblk1p8 is now 6291456 blocks long.
```


