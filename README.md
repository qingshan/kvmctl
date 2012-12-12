kvmctl
======

简单的KVM控制脚本。

准备工作
-------

* 安装KVM

    yum -y install kvm qemu-kvm bridge-utils tunctl
    modprobe kvm ||　modprobe kvm-intel
    /sbin/lsmod | grep kvm

* 设置桥接网卡

/etc/sysconfig/network-scripts/ifcfg-eth0
    
    DEVICE=eth0
    ONBOOT=yes
    BRIDGE=br0
    NM_CONTROLLED=no


/etc/sysconfig/network-scripts/ifcfg-br0

    DEVICE=br0
    TYPE=Bridge
    IPADDR=192.168.1.11
    NETMASK=255.255.255.0
    ONBOOT=yes
    NM_CONTROLLED=no

/etc/sysctl.conf

    net.bridge.bridge-nf-call-ip6tables = 0
    net.bridge.bridge-nf-call-iptables = 0
    net.bridge.bridge-nf-call-arptables = 0


安装KVM控制脚本
---------------

    cp kvmctl.sh /usr/local/bin/kvmctl
    cp qemu-ifup.sh /etc/qemu-ifup
    cp qemu-ifdown.sh /etc/qemu-ifdown

创建虚拟机硬盘
--------------

创建虚拟机硬盘文件

    qemu-img create -f qcow2 centos-6-x86_64.img 10G

其中：
    centos-6-x86_64.img 虚拟机硬盘文件名
    10G 虚拟机硬盘文件大小


配置虚拟机参数
------------

在虚拟机硬盘文件的目录下创建同名的配置文件centos-6-x86_64.cfg，内容为：

    USER=F
    ID=0
    MEMORY=1024
    ISO=centos-6-x86_64.iso

其中：
    USER 每个产品都有一个字符代号；
    ID 每个虚拟机都有一个数字ID号，这个ID在一台宿主机同时运行的KVM虚拟机实例中是唯一的，否则同时启动会有端口冲突；
    MEMORY 虚拟机内存大小，单位MB；
    ISO 安装光盘iso的路径；

kvmctl 将根据USER & ID生成网卡MAC地址、VNC端口、monitor端口。

安装虚拟机
--------

启动虚拟机实例，使用安装光盘iso启动。

    kvmctl install centos-6-x86_64

使用VNC客户端连接虚拟机ID对应的VNC端口。
光盘安装之后，使用命令停止虚拟机实例：

    kvmctl stop centos-6-x86_64

等待1分钟左右，进程即停止。


运行虚拟机
---------

虚拟机安装好之后，使用命令即可运行虚拟机：

    kvmctl start centos-6-x86_64

使用VNC客户端连接虚拟机ID对应的VNC端口。
或者直接连接虚拟机的IP地址。


停止虚拟机
---------

使用命令即可停止虚拟机：

    kvmctl stop centos-6-x86_64

估计等1分钟左右即可停止。


虚拟硬盘
-------

创建数据盘：

    qemu-img create -f qcow2 -o preallocation=metadata centos-6-x86_64_data1.img 50G

设置centos-6-x86_64.cfg，添加一行：

    DISKS[1]=centos-6-x86_64_data1.img

如果是多块盘，可以依次添加多行。


致谢
----

kvmctl 是基于前辈的作品，根据自己的需要改造而成。如需追根溯源，请访问：

    http://www.linux-kvm.org/page/HowToConfigScript
