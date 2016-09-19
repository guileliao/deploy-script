#!/bin/sh
#
# Filename: deploy_application_server.sh 
# Features: initialize OS and deploy container for application server.
# Version: 1.0
# Buildtime: 201609191217
# Editor: guile.liao
# Email: liaolei@geostar.com.cn
# Copyleft: Licensed under the GPLv3
# 
#
#==========
#set myself
#==========
#
set -u
#set -e


#===============
#public_function
#===============
#
function CHECK_FILE()
{
	if [[ ! -f $1 ]];then
		echo -e "\e[31m Please upload [$1],and run me again. \e[0m" && exit 0
	elif [[ $(md5sum $1|awk '{print $1}') != "$2" ]];then
		echo -e "\e[31m Please check md5sum for [$1],and run me again. \e[0m" && exit 0
	else
		echo -e "\e[32m [\e[0m\e[36;4m$1\e[0m\e[32m] is OK. \e[0m"
	fi
#funciton end
}
function CHECK_DIR()
{
	if [[ ! -d $1 ]];then
		mkdir -p $1	
	fi
#funciton end
}
function CHECK_PACKAGE()
{
	if [[ $(rpm -qa|grep $1|grep -v grep) = "" ]];then
		yum install -y $1 2>/dev/null 1>/dev/null
	fi
#funciton end
}
function START_SERVICE()
{
	(systemctl enable $1 && systemctl restart $1 && echo -e "\e[32m $1 has been started. \e[0m")||(echo -e "\e[31m $1 error. \e[0m" && exit 0)
}


#=======
#license
#=======
#
function LICENSE_AGREE()
{
	local _MYLICENSE=""
	clear
	read -p "Do you agree to follow the GPLv3? [yes|no]:" _MYLICENSE
	if [[ ${_MYLICENSE} != "yes" ]];then
		echo -e "\e[31m Bye-Bye.\e[0m" && exit 0
	fi
#funciton end
}
LICENSE_AGREE


#========
#os_check
#========
#
function OS_CHECK()
{
	echo -e "\e[32m My IPaddress is [\e[0m\e[36;4m$(hostname -I)\e[0m\b\e[32m].\e[0m"
	echo -e "\e[32m My hostname is [\e[0m\e[36;4m$(hostname) \e[0m\e[32m].\e[0m"

	if [[ $(grep "CentOS Linux release 7.2.1511" /etc/redhat-release) = "" ]];then
		echo -e "\e[31m Please use [CentOS 7.2.1511]. \e[0m" && exit 0
	else
		echo -e "\e[32m OS version is [\e[0m\e[36;4mCentOS 7.2.1511\e[0m\e[32m]. \e[0m"
	fi

	echo -e "\e[32m My gateway is [\e[0m\e[36;4m$(ip route list|grep "default"|awk '{print $3}')\e[0m\e[32m].\e[0m"

	if [[ $(whoami) = "root" ]];then
		echo -e "\e[32m You are [\e[0m\e[36;4mroot\e[0m\e[32m]. \e[0m"
	else
		echo -e "\e[31m Please use [root] login. \e[0m" && exit 0
	fi

	if [[ $(grep "^SELINUX=" /etc/selinux/config | awk -F "=" '{print $2}') = "enforcing" ]];then
        	sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config
		setenforce 0  
	elif [[ $(grep "^SELINUX=" /etc/selinux/config | awk -F "=" '{print $2}') = "disabled" ]];then
		sed -i s/SELINUX=disabled/SELINUX=permissive/g /etc/selinux/config
		setenforce 0 
	else
        	echo -e "\e[32m SELINUX is [\e[0m\e[36;4mpermissive\e[0m\e[32m]. \e[0m"
	fi

	if [[ $(ping $(ip route list|grep "default"|awk '{print $3}') -w 3|grep "received"|awk '{print $4}') > "0" ]];then
		echo -e "\e[32m LAN is OK. \e[0m"
	fi

	if [[ $(ping www.kernel.org -w 3 2>/dev/null|grep "received"|awk '{print $4}') > "0" ]];then
		echo -e "\e[32m Internet is OK. \e[0m"
	else
		echo -e "\e[31m No connection of the internet. \e[0m"
	fi

	if [[ $(free -g|grep "^Mem"|awk '{print $2}') < "14" ]];then
		echo -e "\e[31m The host shall not be less than 16GB of memory. \e[0m" && exit 0
	fi
#funciton end
}
OS_CHECK


#==================
#create_repo_server
#==================
#
function CREATE_REPO_SERVER()
{
	CHECK_FILE jdk-6u45-linux-amd64.rpm 518e6673f3f07e87bbef3e83f287b5f8
	CHECK_FILE RepoSocket.jar 55b660989536224aa61fd8672b77f1c5
	CHECK_FILE CentOS-7-x86_64-DVD-1511.iso c875b0f1dabda14f00a3e261d241f63e
	CHECK_FILE activemq-cpp-3.8.3-1.el7.x86_64.rpm c4900906e1cfff8a7a310694686e80be
	CHECK_FILE setupdb-server.tar.bz2 5b30cab71ea3261215bdb9b276c254b0
	CHECK_FILE mcsrv-server.tar.bz2 5ba170998e7f7b665847c3f40e1adaca
#	CHECK_FILE owncloud-server.tar.bz2 cd8c0fae43b85460a98e2558016d2881
	CHECK_FILE geostack-server.tar.bz2 93ee53b9e280f2d29d29f9701f20b0e6
	CHECK_FILE monsrv-server.tar.bz2 b17a4f61a510b289e317f2188536260c
	CHECK_FILE mqsrv-server.tar.bz2 635de0e65c11036371dbd638174ed567
#	CHECK_FILE geoonline-server.tar.bz2
#	CHECK_FILE cas-server.tar.bz2 874b91ab19daacc5080a82ba6953d82c
	CHECK_FILE geoagent.tar.bz2 ed3837988f7053b56b0163229cdd5c74
	CHECK_FILE geoglobe-runtime.tar.bz2 04ca82b27a85e855af20e0015b8fbd1e
	CHECK_DIR $(pwd)/centos7
	umount $(mount | grep "CentOS-7-x86_64-DVD-1511.iso" | awk '{print $3}') 2>/dev/null
	mount -o loop $(pwd)/CentOS-7-x86_64-DVD-1511.iso $(pwd)/centos7
cat>/etc/yum.repos.d/centos7_local.repo<<EOF
[CentOS7_Local]
name=CentOS 7.2.1511 DVD
baseurl=file://$(pwd)/centos7
enabled=1
gpgcheck=0
EOF
	yum clean all > /dev/null && yum makecache >/dev/null
	CHECK_PACKAGE httpd
	rm -rf /etc/httpd/conf.d/welcome.conf
	echo "Listen 9090" > /etc/httpd/conf.d/repo.conf
	sed -i s/"^Listen"/"#Listen"/g /etc/httpd/conf/httpd.conf
	START_SERVICE httpd
	umount $(mount | grep "CentOS-7-x86_64-DVD-1511.iso" | awk '{print $3}') 2>/dev/null
	mv $(pwd)/centos7 /var/www/html/
	mv $(pwd)/CentOS-7-x86_64-DVD-1511.iso /var/www/html/
	mount -o loop /var/www/html/CentOS-7-x86_64-DVD-1511.iso /var/www/html/centos7/
	if [[ $(grep 'mount -o loop /var/www/html/CentOS-7-x86_64-DVD-1511.iso /var/www/html/centos7/' /etc/rc.local) = "" ]];then
		echo 'mount -o loop /var/www/html/CentOS-7-x86_64-DVD-1511.iso /var/www/html/centos7/' >> /etc/rc.local
	fi
cat>/etc/yum.repos.d/centos7_local.repo<<EOF
[CentOS7_Local]
name=CentOS 7.2.1511 DVD
baseurl=file:///var/www/html/centos7
enabled=1
gpgcheck=0
EOF
	yum clean all >/dev/null && yum makecache >/dev/null
	CHECK_DIR /var/www/html/repo
	CHECK_DIR /var/www/html/geoglobe
	CHECK_DIR /var/www/html/geoagent
	CHECK_DIR /var/www/html/utility
	CHECK_DIR /var/www/html/container/template
	mv $(pwd)/RepoSocket.jar $(pwd)/jdk-6u45-linux-amd64.rpm  /var/www/html/utility/
	mv $(pwd)/*-server.tar.bz2  /var/www/html/container/template/
	mv $(pwd)/geoagent.tar.bz2  /var/www/html/geoagent/
	mv $(pwd)/activemq-cpp-3.8.3-1.el7.x86_64.rpm /var/www/html/geoagent/
	mv $(pwd)/geoglobe-runtime.tar.bz2  /var/www/html/container/template/
	(yum clean all 1>/dev/null 2>/dev/null && yum makecache 1>/dev/null 2>/dev/null && echo -e "\e[32m Repo_Server has been created. \e[0m")||echo -e "\e[31m Repo_Server create error. \e[0m"
#funciton end
}
CREATE_REPO_SERVER


#=================
#setup ntpd server
#=================
#
CHECK_PACKAGE ntp
START_SERVICE ntpd


#===========
#setup hosts
#===========
#
cat>/etc/hosts<<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$(hostname -I)	appserver
192.168.122.10	db-exte.gfstack.geo
192.168.122.10	db-inte.gfstack.geo
192.168.122.20	mcsrv.gfstack.geo
#{IPADDRESS}	owncloud.gfstack.geo
192.168.122.30	mqsrv.gfstack.geo
192.168.122.40  monsrv.gfstack.geo
192.168.122.50	omgr.gfstack.geo
192.168.122.50	portal.gfstack.geo
#192.168.122.70	cas.gfstack.geo
192.168.122.80	geoonline.gfstack.geo
#192.168.122.90	lb.gfstack.geo
EOF


#=============
#setup_libvirt
#=============
#
function SETUP_LIBVIRT()
{
	CHECK_PACKAGE libvirt
	if [[ $(grep "^listen_tls = 0" /etc/libvirt/libvirtd.conf) = "" ]];then
		echo "listen_tls = 0" >> /etc/libvirt/libvirtd.conf
	fi
	if [[ $(grep "^listen_tcp = 1" /etc/libvirt/libvirtd.conf) = "" ]];then
		echo "listen_tcp = 1" >> /etc/libvirt/libvirtd.conf
	fi
	if [[ $(grep "^auth_tcp = "none"" /etc/libvirt/libvirtd.conf) = "" ]];then
		echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf
	fi
	if [[ $(grep "^tcp_port = "16509"" /etc/libvirt/libvirtd.conf) = "" ]];then
		echo 'tcp_port = "16509"' >> /etc/libvirt/libvirtd.conf
	fi
	if [[ $(grep "^mdns_adv = 0" /etc/libvirt/libvirtd.conf) = "" ]];then
		echo "mdns_adv = 0" >> /etc/libvirt/libvirtd.conf
	fi
	if [[ $(grep "^LIBVIRTD_ARGS="--listen"" /etc/sysconfig/libvirtd) = "" ]];then
		echo "LIBVIRTD_ARGS="--listen"" >> /etc/sysconfig/libvirtd
	fi
	sed -i s/'"192.168.122.254"'/'"192.168.122.249"'/g /etc/libvirt/qemu/networks/default.xml
	sed -i s/'"192.168.122.2"'/'"192.168.122.200"'/g /etc/libvirt/qemu/networks/default.xml
	sed -i s/'"192.168.122.1"'/'"192.168.122.254"'/g /etc/libvirt/qemu/networks/default.xml
	START_SERVICE libvirtd
#funciton end
}
SETUP_LIBVIRT


#==============
#setup iptalbes
#==============
#
CHECK_PACKAGE iptables-services
sed -i s/'IPTABLES_SAVE_ON_STOP="no"'/'IPTABLES_SAVE_ON_STOP="yes"'/g /etc/sysconfig/iptables-config
sed -i s/'IPTABLES_SAVE_ON_RESTART="no"'/'IPTABLES_SAVE_ON_RESTART="yes"'/g /etc/sysconfig/iptables-config
START_SERVICE iptables
_NICNAME_=$(ls -l /etc/sysconfig/network-scripts/ifcfg-*|grep -v "ifcfg-lo"|awk '{print $9}'|awk -F "/" '{print $5}'|awk -F "-" '{print $2}')

#-------
#setupdb
#-------
#
if [[ $(iptables -t nat -L|grep "DNAT.*3306") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 3306 --jump DNAT --to-destination 192.168.122.10:3306
fi
if [[ $(iptables -t nat -L|grep "DNAT.*10:22") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2210 --jump DNAT --to-destination 192.168.122.10:22
fi

#--------
#memcache
#--------
#
if [[ $(iptables -t nat -L|grep "DNAT.*11211") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 11211 --jump DNAT --to-destination 192.168.122.20:11211
fi
if [[ $(iptables -t nat -L|grep "DNAT.*20:22") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2220 --jump DNAT --to-destination 192.168.122.20:22
fi

#--------
#activemq
#--------
#
if [[ $(iptables -t nat -L|grep "DNAT.*8161") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8161 --jump DNAT --to-destination 192.168.122.30:8161
fi
if [[ $(iptables -t nat -L|grep "DNAT.*61616") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 61616 --jump DNAT --to-destination 192.168.122.30:61616
fi
if [[ $(iptables -t nat -L|grep "DNAT.*30:22") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2230 --jump DNAT --to-destination 192.168.122.30:22
fi

#------
#zabbix
#------
#
if [[ $(iptables -t nat -L|grep "DNAT.*40:80") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8084 --jump DNAT --to-destination 192.168.122.40:80
fi
if [[ $(iptables -t nat -L|grep "DNAT.*10051") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 10051 --jump DNAT --to-destination 192.168.122.40:10051
fi
if [[ $(iptables -t nat -L|grep "DNAT.*10052") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 10052 --jump DNAT --to-destination 192.168.122.40:10052
fi
if [[ $(iptables -t nat -L|grep "DNAT.*40:22") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2240 --jump DNAT --to-destination 192.168.122.40:22
fi

#--------
#geostack
#--------
#
if [[ $(iptables -t nat -L|grep "DNAT.*50:8080") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8083 --jump DNAT --to-destination 192.168.122.50:8080
fi
if [[ $(iptables -t nat -L|grep "DNAT.*50:22") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2250 --jump DNAT --to-destination 192.168.122.50:22
fi

#--------
#owncloud
#--------
#
#if [[ $(iptables -t nat -L|grep "DNAT.*60:80") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8082 --jump DNAT --to-destination 192.168.122.60:80
#fi

#if [[ $(iptables -t nat -L|grep "DNAT.*60:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2260 --jump DNAT --to-destination 192.168.122.60:22
#fi

#---
#cas
#---
#
#if [[ $(iptables -t nat -L|grep "DNAT.*70:8080") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 80 --jump DNAT --to-destination 192.168.122.70:8080
#fi
#if [[ $(iptables -t nat -L|grep "DNAT.*70:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2270 --jump DNAT --to-destination 192.168.122.70:22
#fi

#---------
#geoonline
#---------

if [[ $(iptables -t nat -L|grep "DNAT.*80:8080") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8081 --jump DNAT --to-destination 192.168.122.80:8080
fi

if [[ $(iptables -t nat -L|grep "DNAT.*80:22") = "" ]];then
	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2280 --jump DNAT --to-destination 192.168.122.80:22
fi

#--
#lb
#--
#
#if [[ $(iptables -t nat -L|grep "DNAT.*90:8080") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8080 --jump DNAT --to-destination 192.168.122.90:8080
#fi
#if [[ $(iptables -t nat -L|grep "DNAT.*90:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2290 --jump DNAT --to-destination 192.168.122.90:22
#fi

#----------------------------
#create clear_forward_list.sh
#----------------------------
#
systemctl restart iptables &>/dev/null
cat >/root/clear_forward_list.sh<<EOF
#!/bin/sh
#
#
# Filename: clear_forward_list.sh
# Features: Clear iptables ACL.
# Version: 1.0
# Build: 20160721
# Editor: liucheng
# Email: liucheng@geostar.com.cn
#
#
_ACLNUM_=\$(iptables -t nat -L | grep '192.168.122.0/24' | wc -l)
#
echo -e "\e[33m Waiting for iptables clear forward list. \e[0m"
b=''
for ((i=0;\${i}<=100;i+=1))
do
        printf "PROGRESS:[%-1s]%d%%\r" \${b} \${i}
        sleep 0.2
        b=#\${b}
done
echo
iptables -F
iptables -t mangle -F
if [[ \${_ACLNUM_} -gt 5 ]];then
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 -d 224.0.0.0/24 -j RETURN
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 -d 255.255.255.255/32 -j RETURN
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p tcp -j MASQUERADE --to-ports 1024-65535
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p udp -j MASQUERADE --to-ports 1024-65535
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE
fi
EOF
if [[ $(grep "clear_forward_list.sh" /etc/rc.local) = "" ]];then
	echo 'sh /root/clear_forward_list.sh' >> /etc/rc.local && chmod +x /etc/rc.d/rc.local
fi
systemctl restart iptables >/dev/null && sh /root/clear_forward_list.sh


#================
#deploy_container
#================
#
CHECK_PACKAGE bzip2

function DEPLOY_CONTAINER()
{
#	local _IMAGE_PATH=/var/lib/libvirt/images
	CHECK_DIR /var/lib/libvirt/images/xml_lxc

cat>/var/lib/libvirt/images/xml_lxc/$1.xml<<EOF
<domain type="lxc">
  <name>$1</name>
  <memory>$2</memory>
  <currentMemory>0</currentMemory>
  <vcpu>1</vcpu>
  <os>
    <type arch="x86_64">exe</type>
    <init>/sbin/init</init>
  </os>
  <features>
    <privnet/>
  </features>
  <cpu mode='custom' match='exact'>
    <model fallback='allow'>kvm64</model>
    <topology sockets='1' cores='1' threads='1'/>
  </cpu>
  <clock offset='localtime'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/libexec/libvirt_lxc</emulator>
    <filesystem>
      <source dir="/var/lib/libvirt/images/$1"/>
      <target dir="/"/>
    </filesystem>
    <interface type="bridge">
      <source bridge="virbr0"/>
    </interface>
    <console type="pty"/>
  </devices>
</domain>
EOF
	virsh -c lxc:/// destroy $1 2>/dev/null 1>/dev/null
	virsh -c lxc:/// undefine $1 2>/dev/null 1>/dev/null
	rm -rf /var/lib/libvirt/images/$1 2>/dev/null 1>/dev/null
	tar jxvf /var/www/html/container/template/$1.tar.bz2 -C /var/lib/libvirt/images/ 1>/dev/null 2>/dev/null
	virsh -c lxc:/// define /var/lib/libvirt/images/xml_lxc/$1.xml
	virsh -c lxc:/// autostart $1
	virsh -c lxc:/// start $1
	if [[ $(virsh -c lxc:/// list --all|grep "$1"|awk '{print $3}') = "running" ]];then
		echo -e "\e[32m [\e[0m\e[36;4m$1\e[0m\e[32m] has been deployed. \e[0m"
	else
		echo -e "\e[31m [\e[0m\e[36;4m$1\e[0m\e[31m] error. \e[0m"
	fi
#function end
}
echo -e "\e[33m 1GB = 1024MB = 1048576KB \e[0m"
DEPLOY_CONTAINER setupdb-server 8388608
DEPLOY_CONTAINER mcsrv-server 4194304
#DEPLOY_CONTAINER owncloud-server 8388608
DEPLOY_CONTAINER geostack-server 8388608
DEPLOY_CONTAINER monsrv-server 4194304
DEPLOY_CONTAINER mqsrv-server 8388608
DEPLOY_CONTAINER geoonline-server 8388608
#DEPLOY_CONTAINER cas-server 4194304
#DEPLOY_CONTAINER lb-server 4194304


#==============
#setup_building
#==============
function SETUP_BUILDING()
{
	local _YOURNAME=""
	local _YN=""

	read -p "Please input your name:" _YOURNAME
	echo -e "$(date +%Y%m%d%H%M)\n${_YOURNAME}" > /BUILDING
	read -p "Restart computer?[yes|no]" _YN

	if [[ ${_YN} = "yes" || ${_YN} = "YES" ]];then
		reboot
	elif [[ ${_YN} = "no" || ${_YN} = "NO" ]];then
		echo -e "\e[31m What are you doing? \e[0m" && exit 0
	else
		echo -e "\e[31m What are you doing? \e[0m" && exit 0
	fi
	unset local _YOURNAME
	unset local _YN
}
SETUP_BUILDING


##########
#File end#
##########