#!/bin/sh
#
# Filename: deploy-geoglobe_server.sh 
# Features: initialize GeoGlobe Server container host.
# Version: 1.0
# Buildtime: 201608161406
# Editor: guile.liao
# Email: liaolei@geostar.com.cn
# Copyleft: Licensed under the GPLv3
# 
#
#==========
#set myself
#==========

set -u
#set -e
#
#
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
		echo -e "\e[32m [\e[0m\e[36;4m$1\e[0m] is OK. \e[0m"
	fi
#function end
}
function CHECK_DIR()
{
	if [[ ! -d $1 ]];then
		mkdir -p $1	
	fi
#function end
}
function CHECK_PACKAGE()
{
	if [[ $(rpm -qa|grep $1|grep -v grep) = "" ]];then
	
		yum install -y $1 2>/dev/null 1>/dev/null
	fi
#function end
}
function START_SERVICE()
{
	systemctl enable $1 && systemctl restart $1 && echo -e "\e[32m $1 has been started. \e[0m"
}


#=======
#license
#=======
#
function LICENSE_AGREE()
{
	clear
	read -p "Do you agree to follow the GPLv3? [yes|no]:" _MYLICENSE_
	if [[ ${_MYLICENSE_} != "yes" ]];then
		echo -e "\e[31m Bye-Bye.\e[0m" && exit
	fi
#function end
}
LICENSE_AGREE


#=========================
#get_application_ipaddress
#=========================
#
read -p "Please input application server ipaddress:" _GET_APPSERVER_IP_
if [[ $(ping ${_GET_APPSERVER_IP_} -w 3|grep "received"|awk '{print $4}') > "0" ]];then
	echo -e "\e[32m Application server is OK. \e[0m"
else
	echo -e "\e[31m Please check Application server. \e[0m" && exit
fi


#========
#os_check
#========
#
#----------
#rename_nic
#----------
#rename nic to eth0
function RENMAE_NIC()
{
	local _NICNAME=$(ip addr | grep "^2"|awk -F ": " '{print $2}')
	if [[ ${_NICNAME} != "eth0" ]];then
		echo -e "\e[31m The nic name is [\e[31;1m${_NICNAME}\e[0m].\n Press 'Enter' key rename nic name to 'eth0'.\e[0m"
		read -t 5
		sed -i s/"^NAME=.*$"/"NAME=eth0"/g /etc/sysconfig/network-scripts/ifcfg-${_NICNAME}
		sed -i s/"^DEVICE=.*$"/"DEVICE=eth0"/g /etc/sysconfig/network-scripts/ifcfg-${_NICNAME}
		mv /etc/sysconfig/network-scripts/ifcfg-${_NICNAME} /etc/sysconfig/network-scripts/ifcfg-eth0
		sed -i s/'rhgb quiet"$'/'net.ifnames=0 biosdevname=0 rhgb quiet"'/g /etc/default/grub
		grub2-mkconfig -o /boot/grub2/grub.cfg
		echo -e "\e[32m The nic name has renamed.\n Press 'Enter' key reboot.\e[0m"
		read -t 5
		reboot
	fi
	unset local _NICNAME
#function end
}

#-----------
#set_selinux
#-----------
#set selinux status to "permissive"
function SET_SELINUX()
{
	local _SE_STATUS=$(sestatus|grep "^Current mode"|awk '{print $3}')
	if [[ ${_SE_STATUS} != "permissive" ]];then
		sed -i s/^SELINUX=.*/SELINUX=permissive/g /etc/selinux/config
		setenforce 0
	fi
	unset local _SESTATUS
#function end
}

#------------
#check_os_ver
#------------
#check os version information
function CHECK_OS_VER()
{
	local _OS_VER=$(grep "CentOS Linux release 7.2.1511" /etc/redhat-release)
	if [[ -z ${_OS_VER} ]];then
		echo -e "\e[31m Please use [CentOS 7.2.1511].\e[0m" && exit
	else
		echo -e "\e[32m OS version is [\e[0m\e[32;1mCentOS 7.2.1511\e[0m\e[32m].\e[0m"
	fi
	unset local _OS_VER
#function end
}

#-------------
#check_account
#-------------
#check login account is "root"
function CHECK_ACCOUNT()
{
	if [[ $(id -u) = "0" ]];then
		echo -e "\e[32m You are [\e[0m\e[36;4mroot\e[0m\e[32m]. \e[0m"
	else
		echo -e "\e[31m Please use [\e[31;1mroot\e[0m] login.\e[0m" && exit
	fi
#function end
}

#-------------
#check_network
#-------------
#check internet and LAN
function CHECK_NETWORK()
{
	if [[ $(ping $(ip route list|grep "default"|awk '{print $3}') -w 3|grep "received"|awk '{print $4}') > "1" ]];then
		echo -e "\e[32m LAN is OK. \e[0m"
	fi
	if [[ $(ping www.kernel.org -w 3|grep "received"|awk '{print $4}') > "1" ]];then
		echo -e "\e[32m Internet is OK. \e[0m"
	else
		echo -e "\e[31m No connection of the internet. \e[0m"
	fi
#function end
}

#--------------
#check_host_ram
#--------------
#check host memory limite
function CHECK_HOST_RAM()
{
	if [[ $(free -g|grep "^Mem"|awk '{print $2}') < "14" ]];then
		echo -e "\e[31m The host shall not be less than 16GB of memory. \e[0m" && exit
	fi
#function end
}

function OS_CHECK()
{
	CHECK_OS_VER
	CHECK_HOST_RAM
	CHECK_ACCOUNT
	SET_SELINUX
	RENMAE_NIC
	echo -e "\e[32m My IPaddress is [\e[0m\e[32;1m$(hostname -I)\e[0m\b\e[32m].\e[0m"
	echo -e "\e[32m My hostname is [\e[0m\e[32;1m$(hostname) \e[0m\e[32m].\e[0m"
	echo -e "\e[32m My gateway is [\e[0m\e[32;1m$(ip route list|grep "default"|awk '{print $3}')\e[0m\e[32m].\e[0m"
	CHECK_NETWORK
}
OS_CHECK


#===========
#setup hosts
#===========

cat>/etc/hosts<<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${_GET_APPSERVER_IP_}	support01.gfstack.geo
${_GET_APPSERVER_IP_}	ntp.gfstack.geo
${_GET_APPSERVER_IP_}	db-exte.gfstack.geo
${_GET_APPSERVER_IP_}	db-inte.gfstack.geo
${_GET_APPSERVER_IP_}	mcsrv.gfstack.geo
${_GET_APPSERVER_IP_}	portal.gfstack.geo
${_GET_APPSERVER_IP_}	omgr.gfstack.geo
${_GET_APPSERVER_IP_}	monsrv.gfstack.geo
${_GET_APPSERVER_IP_}	mqsrv.gfstack.geo
${_GET_APPSERVER_IP_}	cas.gfstack.geo
#{IPADDRESS}	lb.gfstack.geo
${_GET_APPSERVER_IP_}	owncloud.gfstack.geo
EOF
#
#
#==================
#create_repo_client
#==================

function CREATE_REPO_CLIENT()
{
cat>/etc/yum.repos.d/centos7_local.repo<<EOF
[CentOS7_Local]
name=CentOS 7.2.1511 DVD
baseurl=http://support01.gfstack.geo:9090/centos7
enabled=1
gpgcheck=0
EOF
	(yum clean all &>/dev/null && yum makecache &>/dev/null && echo -e "\e[32m Repo_Client has been created. \e[0m")||(echo -e "\e[31m Repo_Client create error. \e[0m" && exit)
#function end
}
CREATE_REPO_CLIENT


#================
#setup_ntp_client
#================
#
CHECK_PACKAGE ntp
sed -i s/^server/#server/g /etc/ntp.conf
if [[ $(grep "server ntp.gfstack.geo iburst" /etc/ntp.conf) = "" ]];then
	echo "server ntp.gfstack.geo iburst" >> /etc/ntp.conf
fi
START_SERVICE ntpd


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
#function end
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

#----------------------------
#create clear_forward_list.sh
#----------------------------
#
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
systemctl restart iptables &>/dev/null && sh /root/clear_forward_list.sh


#===============
#deploy_geoagent
#===============
#
yum install -y http://support01.gfstack.geo:9090/geoagent/activemq-cpp-3.8.3-1.el7.x86_64.rpm
rm -rf /opt/geoagent*
curl http://support01.gfstack.geo:9090/geoagent/geoagent.tar.bz2 -o /opt/geoagent.tar.bz2 && tar jxvf /opt/geoagent.tar.bz2 -C /opt 1>/dev/null 2>/dev/null && rm -rf /opt/geoagent.tar.bz2 && chmod 777 -R /opt/geoagent
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


#===============================
#get_geoglobe_container_template
#===============================
#
CHECK_PACKAGE bzip2
curl http://support01.gfstack.geo:9090/container/template/geoglobe-runtime.tar.bz2 -o /var/lib/libvirt/images/geoglobe-runtime.tar.bz2 && \
tar jxvf /var/lib/libvirt/images/geoglobe-runtime.tar.bz2 -C /var/lib/libvirt/images/ &>/dev/null


#==============
#setup BUILDING
#==============
#
read -p "Please input your name:" _YOURNAME_
echo -e "$(date +%Y%m%d%H%M)\n${_YOURNAME_}" > /BUILDING
read -p "Restart computer?[yes|no]" _YN_
if [[ ${_YN_} = "yes" || ${_YN_} = "YES" ]];then
	reboot
else
	echo -e "\e[31m What are you doing? \e[0m" && exit
fi


##########
#File end#
##########
