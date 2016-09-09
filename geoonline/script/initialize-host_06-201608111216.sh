#!/bin/sh
#
# Filename: initialize-host_06.sh 
# Features: initialize OS for host-04
# Version: 0.1
# Build: 201608111216
# Editor: guile.liao
# Email: liaolei@geostar.com.cn
# Copyleft: Licensed under the GPLv3
# 
#
#
#=======
#license
#=======

clear

read -p "Do you agree to follow the GPLv3? [yes|no]:" _MYLICENSE_
if [[ ${_MYLICENSE_} != "yes" ]];then
	echo -e "\e[31m Bye-Bye.\e[0m" && exit 0
fi
#
#
#============
#get hostname
#============

clear

read -p "Please input my hostname [host-XX]:" _MYNAME_
if [[ ${_MYNAME_} != "host-06" ]];then
	echo -e "\e[31m Please make sure my hostname.\e[0m" && exit 0
fi
#
#
#========
#check OS
#========

echo -e "\e[32m My IPaddress is [\e[0m\e[36;4m$(hostname -I)\e[0m\b\e[32m].\e[0m"

function OS_CHECK()
{
	if [[ $(grep "CentOS Linux release 7.2.1511" /etc/redhat-release) = "" ]];then
		echo -e "\e[31m Please use [CentOS 7.2.1511]. \e[0m" && exit 0
	else
		echo -e "\e[32m OS is OK. \e[0m"
	fi

	if [[ $(whoami) = "root" ]];then
		echo -e "\e[32m You are boss~~~. \e[0m"
	else
		echo -e "\e[31m Please use [root] login. \e[0m" && exit 0
	fi
	
	if [[ $(free -g|grep "^Mem"|awk '{print $2}') < "14" ]];then
		echo -e "\e[31m The host shall not be less than 16GB of memory. \e[0m" && exit 0
	fi
}
OS_CHECK
#
#
#=======================
#get host-00`s ipaddress
#=======================

read -p "Please input HOST-00 IPaddress:" _IPADDRESS_

if [[ $(ping -w 3 ${_IPADDRESS_}|grep "received"|awk -F "," '{print $2}'|awk '{print $1}') != "0" ]];then
	echo -e "\e[32m Support server is OK. \e[0m"
else
	echo -e "\e[31m Please check support server. \e[0m" && exit 0
fi
#
#
##===================
#modify selinux state
#====================

function SELINUX_MODIFY()
{
        if [[ $(grep "^SELINUX=" /etc/selinux/config | awk -F "=" '{print $2}') = "enforcing" ]];then
                sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config
                setenforce 0
        elif [[ ${_SE_STATE_} = "disabled" ]];then
                sed -i s/SELINUX=disabled/SELINUX=permissive/g /etc/selinux/config
                setenforce 0
        else
                echo -e "\e[32m SELINUX is OK. \e[0m"
        fi
}
SELINUX_MODIFY
#
#
#================
#setup dns client
#================

echo "nameserver ${_IPADDRESS_}" > /etc/resolv.conf

if [[ $(grep "^echo" /etc/rc.local) = "" ]];then
	echo "echo "nameserver ${_IPADDRESS_}" > /etc/resolv.conf" >> /etc/rc.local && chmod +x /etc/rc.d/rc.local
fi

if [[ $(ping support01.gfstack.geo -w 3|grep "received"|awk -F "," '{print $2}'|awk '{print $1}') != "0" ]];then
	echo -e "\e[32m DNS is OK. \e[0m"
else
	echo -e "\e[31m Please check DNS,and run me again. \e[0m" && exit 0
fi
#
#
#===========
#setup hosts
#===========

cat >/etc/hosts<<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$(hostname -I)	${_MYNAME_}
#host-01
#192.168.122.10	db-exte.gfstack.geo
#192.168.122.10	db-inte.gfstack.geo
#192.168.122.20	mcsrv.gfstack.geo
#192.168.122.60	owncloud.gfstack.geo
#host-02
#192.168.122.30	mqsrv.gfstack.geo
#192.168.122.40  monsrv.gfstack.geo
#192.168.122.50	omgr.gfstack.geo
#192.168.122.50	portal.gfstack.geo
#host-03
#192.168.122.70	cas.gfstack.geo
#192.168.122.80	geoonline.gfstack.geo
#host-04
#192.168.122.90	lb.gfstack.geo
EOF
#
#
#=================================
#create CentOS7 DVD for repo_local
#=================================

tar jcvf /etc/yum.repos.d/bak_$(date +%Y%m%d%H%M).tar.bz2 /etc/yum.repos.d/*.repo 2>/dev/null 1>/dev/null
rm -rf /etc/yum.repos.d/*.repo

cat > /etc/yum.repos.d/centos7_local.repo<<EOF
[CentOS7_Local]
name=CentOS 7.2.1511 DVD
baseurl=http://support01.gfstack.geo/centos7/
enabled=1
gpgcheck=0
EOF

yum clean all > /dev/null && yum makecache > /dev/null && echo -e "\e[32m Repo_local has been created. \e[0m"
#
#
#=============
#install tools
#=============

yum install -y wget ftp net-tools vsftpd ntp libvirt iptables-services bzip2 > /dev/null
#
#
#============
#setup vsftpd
#============

sed -i s/^root/#root/g /etc/vsftpd/ftpusers && sed -i s/^root/#root/g /etc/vsftpd/user_list

systemctl restart vsftpd > /dev/null && systemctl enable vsftpd > /dev/null && echo -e "\e[32m Vsftpd has been started. \e[0m"
#
#
#==========
#setup ntpd
#==========

sed -i s/^server/#server/g /etc/ntp.conf

if [[ $(grep "server ntp.gfstack.geo iburst" /etc/ntp.conf) = "" ]];then
	echo "server ntp.gfstack.geo iburst" >> /etc/ntp.conf
fi

systemctl restart ntpd > /dev/null && systemctl enable ntpd > /dev/null && echo -e "\e[32m Ntpd has been started. \e[0m"
#
#
#=============
#setup libvirt
#=============

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

systemctl enable libvirtd > /dev/null && systemctl restart libvirtd > /dev/null && echo -e "\e[32m Libvirtd has been started. \e[0m"
#
#
#==============
#setup iptalbes
#==============

sed -i s/'IPTABLES_SAVE_ON_STOP="no"'/'IPTABLES_SAVE_ON_STOP="yes"'/g /etc/sysconfig/iptables-config
sed -i s/'IPTABLES_SAVE_ON_RESTART="no"'/'IPTABLES_SAVE_ON_RESTART="yes"'/g /etc/sysconfig/iptables-config

systemctl enable iptables 1>/dev/null 2>/dev/null && systemctl start iptables > /dev/null && echo -e "\e[32m Iptables has been started. \e[0m"

_NICNAME_=$(ls -l /etc/sysconfig/network-scripts/ifcfg-*|grep -v "ifcfg-lo"|awk '{print $9}'|awk -F "/" '{print $5}'|awk -F "-" '{print $2}')

#-------
#host-01
#-------
#
#if [[ $(iptables -t nat -L|grep "DNAT.*3306") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 3306 --jump DNAT --to-destination 192.168.122.10:3306
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*10:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2210 --jump DNAT --to-destination 192.168.122.10:22
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*11211") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 11211 --jump DNAT --to-destination 192.168.122.20:11211
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*20:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2220 --jump DNAT --to-destination 192.168.122.20:22
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*80") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 80 --jump DNAT --to-destination 192.168.122.60:80
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*60:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2260 --jump DNAT --to-destination 192.168.122.60:22
#fi

#-------
#host-02
#-------
#
#if [[ $(iptables -t nat -L|grep "DNAT.*8161") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8161 --jump DNAT --to-destination 192.168.122.30:8161
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*61616") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 61616 --jump DNAT --to-destination 192.168.122.30:61616
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*30:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2230 --jump DNAT --to-destination 192.168.122.30:22
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*80") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 80 --jump DNAT --to-destination 192.168.122.40:80
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*10051") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 10051 --jump DNAT --to-destination 192.168.122.40:10051
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*10052") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 10052 --jump DNAT --to-destination 192.168.122.40:10052
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*40:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2240 --jump DNAT --to-destination 192.168.122.40:22
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*8080") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8080 --jump DNAT --to-destination 192.168.122.50:8080
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*50:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2250 --jump DNAT --to-destination 192.168.122.50:22
#fi

#-------
#host-03
#-------
#
#if [[ $(iptables -t nat -L|grep "DNAT.*8080") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8080 --jump DNAT --to-destination 192.168.122.80:8080
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*80:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2280 --jump DNAT --to-destination 192.168.122.80:22
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*80") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8080 --jump DNAT --to-destination 192.168.122.70:80
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*70:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2270 --jump DNAT --to-destination 192.168.122.70:22
#fi

#-------
#host-04
#-------
#
#if [[ $(iptables -t nat -L|grep "DNAT.*8080") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 8080 --jump DNAT --to-destination 192.168.122.90:8080
#fi
#
#if [[ $(iptables -t nat -L|grep "DNAT.*90:22") = "" ]];then
#	iptables --table nat --append PREROUTING --in-interface ${_NICNAME_} --protocol tcp --dport 2290 --jump DNAT --to-destination 192.168.122.90:22
#fi

systemctl restart iptables > /dev/null

#create clear_forward_list.sh

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
echo -e "\e[31m Waiting for iptables clear forward list. \e[0m"
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

systemctl restart iptables > /dev/null && sh /root/clear_forward_list.sh
#
#
#===========================
#download container template
#===========================

_IMAGE_PATH_=/var/lib/libvirt/images

if [[ ! -d "${_IMAGE_PATH_}/template_lxc/" ]];then
	mkdir -p ${_IMAGE_PATH_}/template_lxc/
fi

function DOWN_FILE()
{
	curl http://support01.gfstack.geo/container/template/$1.tar.bz2 -o ${_IMAGE_PATH_}/template_lxc/$1.tar.bz2
}

#host-01
#DOWN_FILE setupdb-server
#DOWN_FILE mcsrv-server
#DOWN_FILE owncloud-server
#host-02
#DOWN_FILE geostack-server
#DOWN_FILE monsrv-server
#DOWN_FILE mqsrv-server
#host-03
#DOWN_FILE geoonline-server
#DOWN_FILE cas-server
#host-04
#DOWN_FILE lb-server
#host-06
DOWN_FILE geoglobe-runtime
tar jxvf ${_IMAGE_PATH_}/template_lxc/geoglobe-runtime.tar.bz2 -C ${_IMAGE_PATH_}
#
#
#==========================
#create define file for LXC
#==========================
#
#if [[ ! -d "${_IMAGE_PATH_}/xml_lxc/" ]];then
#        mkdir -p ${_IMAGE_PATH_}/xml_lxc/
#fi
#
#cat >${_IMAGE_PATH_}/xml_lxc/define_container.xml<<EOF
#<domain type="lxc">
#  <name>CONTAINER_NAME</name>
#  <memory>MAX_MEMORY</memory>
#  <currentMemory>0</currentMemory>
#  <vcpu>1</vcpu>
#  <os>
#    <type arch="x86_64">exe</type>
#    <init>/sbin/init</init>
#  </os>
#  <features>
#    <privnet/>
#  </features>
#  <cpu mode='custom' match='exact'>
#    <model fallback='allow'>kvm64</model>
#    <topology sockets='1' cores='1' threads='1'/>
#  </cpu>
#  <clock offset='localtime'/>
#  <on_poweroff>destroy</on_poweroff>
#  <on_reboot>restart</on_reboot>
#  <on_crash>restart</on_crash>
#  <devices>
#    <emulator>/usr/libexec/libvirt_lxc</emulator>
#    <filesystem>
#      <source dir="${_IMAGE_PATH_}/CONTAINER_NAME"/>
#      <target dir="/"/>
#    </filesystem>
#    <interface type="bridge">
#      <source bridge="virbr0"/>
#    </interface>
#    <console type="pty"/>
#  </devices>
#</domain>
#EOF
#
#function CREATE_XML()
#{
#	cat ${_IMAGE_PATH_}/xml_lxc/define_container.xml > ${_IMAGE_PATH_}/xml_lxc/$1.xml
#	sed -i s/CONTAINER_NAME/$1/g ${_IMAGE_PATH_}/xml_lxc/$1.xml
#	sed -i s/MAX_MEMORY/$2/g ${_IMAGE_PATH_}/xml_lxc/$1.xml
#	echo -e "\e[33m $1 ram=$2KB \e[0m"
#}
#
#echo -e '\e[33m "$2" is MAX_MEMORY (KB). \e[0m'
#echo -e "\e[33m 1GB = 1024MB = 1048576KB \e[0m"
#
#host-01
#CREATE_XML setupdb-server 8388608
#CREATE_XML mcsrv-server 4194304
#CREATE_XML owncloud-server 8388608
#host-02
#CREATE_XML geostack-server 8388608
#CREATE_XML monsrv-server 4194304
#CREATE_XML mqsrv-server 8388608
#host-03
#CREATE_XML geoonline-server 8388608
#CREATE_XML cas-server 4194304
#host-04
#CREATE_XML lb-server 4194304
#
#
#================
#deploy container
#================
#
#function DEPLOY_CONTAINER()
#{
#	virsh -c lxc:/// destroy $1 2>/dev/null 1>/dev/null
#	virsh -c lxc:/// undefine $1 2>/dev/null 1>/dev/null
#	rm -rf ${_IMAGE_PATH_}/$1 2>/dev/null 1>/dev/null
#	tar jxvf ${_IMAGE_PATH_}/template_lxc/$1.tar.bz2 -C ${_IMAGE_PATH_}/
#	virsh -c lxc:/// define ${_IMAGE_PATH_}/xml_lxc/$1.xml
#	virsh -c lxc:/// autostart $1
#	virsh -c lxc:/// start $1
#	virsh -c lxc:/// list --all
#}
#
#host-01
#DEPLOY_CONTAINER setupdb-server
#DEPLOY_CONTAINER mcsrv-server
#DEPLOY_CONTAINER owncloud-server
#host-02
#DEPLOY_CONTAINER monsrv-server
#DEPLOY_CONTAINER mqsrv-server
#DEPLOY_CONTAINER geostack-server
#host-03
#DEPLOY_CONTAINER geoonline-server
#DEPLOY_CONTAINER cas-server
#host-04
#DEPLOY_CONTAINER lb-server
#
#
#===============
#deploy geoagent
#===============

yum install -y http://support01.gfstack.geo/geoagent/activemq-cpp-3.8.3-1.el7.x86_64.rpm
rm -rf /opt/geoagent*
curl http://support01.gfstack.geo/geoagent/geoagent.tar.bz2 -o /opt/geoagent.tar.bz2 && tar jxvf /opt/geoagent.tar.bz2 -C /opt && rm -rf /opt/geoagent.tar.bz2 && chmod 777 -R /opt/geoagent

if [[ $(grep "/opt/.*/bin/" /etc/ld.so.conf) = "" ]];then
	echo "/opt/geoagent/bin/" >> /etc/ld.so.conf
fi

ldconfig

if [[ $(grep "/opt.*geoagent" /etc/rc.local) = "" ]];then
	echo "/opt/geoagent/bin/geoagent" >> /etc/rc.local
fi

if [[ $(ps aux|grep "geoagent"|grep -v "grep") = "" ]];then
	/opt/geoagent/bin/geoagent && echo -e "\e[32m GeoAgent has been started.\e[0m"
fi
#
#
#==============
#setup hostname
#==============

echo "${_MYNAME_}" > /etc/hostname
echo -e "\e[32m I am [${_MYNAME_}].\e[0m"
#
#
#==============
#setup BUILDING
#==============

echo "$(date +%Y%m%d%H%M)" > /BUILDING

read -p "Restart computer?[yes|no]" _YN_
if [[ ${_YN_} = "yes" || ${_YN_} = "YES" ]];then
	reboot
elif [[ ${_YN_} = "no" || ${_YN_} = "NO" ]];then
	echo -e "\e[31m What are you doing? \e[0m" && exit 0
else
	echo -e "\e[31m What are you doing? \e[0m" && exit 0
fi
#
#
##########
#File end#
##########
