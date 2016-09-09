#!/bin/bash
#
# Filename: deploy-container-multiple-role.sh
# Features: initialize OS and deploy container.
# Version: 1.0
# Buildtime: 201609071217
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
#----------
#check_file
#----------
#check files and md5sum
function CHECK_FILE()
{
    if [[ ! -f $1 ]];then
        echo -e "\e[31m Please upload [$1],and run me again. \e[0m" && exit 0
    elif [[ $(md5sum $1|awk '{print $1}') != "$2" ]];then
        echo -e "\e[31m Please check md5sum for [$1],and run me again. \e[0m" && exit 0
    else
        echo -e "\e[32m [\e[0m\e[36;4m$1\e[0m\e[32m] is OK. \e[0m"
    fi
#function end
}

#-----------
#verify_file
#-----------
#verify md5sum
function VERIFY_FILE()
{
	CHECK_FILE jdk-6u45-linux-amd64.rpm 518e6673f3f07e87bbef3e83f287b5f8
	CHECK_FILE RepoSocket.jar 55b660989536224aa61fd8672b77f1c5
	CHECK_FILE CentOS-7-x86_64-DVD-1511.iso c875b0f1dabda14f00a3e261d241f63e
	CHECK_FILE activemq-cpp-3.8.3-1.el7.x86_64.rpm c4900906e1cfff8a7a310694686e80be
	CHECK_FILE setupdb-server.tar.bz2 5b30cab71ea3261215bdb9b276c254b0
	CHECK_FILE mcsrv-server.tar.bz2 5ba170998e7f7b665847c3f40e1adaca
	CHECK_FILE owncloud-server.tar.bz2 cd8c0fae43b85460a98e2558016d2881
	CHECK_FILE geostack-server.tar.bz2 93ee53b9e280f2d29d29f9701f20b0e6
	CHECK_FILE monsrv-server.tar.bz2 b17a4f61a510b289e317f2188536260c
	CHECK_FILE mqsrv-server.tar.bz2 635de0e65c11036371dbd638174ed567
#	CHECK_FILE geoonline-server.tar.bz2
#	CHECK_FILE cas-server.tar.bz2 874b91ab19daacc5080a82ba6953d82c
	CHECK_FILE geoagent.tar.bz2 ed3837988f7053b56b0163229cdd5c74
	CHECK_FILE geoglobe-runtime.tar.bz2 04ca82b27a85e855af20e0015b8fbd1e
#function end
}

#--------------
#deploy_service
#--------------
#
function CHECK_PACKAGE()
{
	if [[ $(rpm -qa|grep $1) = "" ]];then
		yum install -y $1 &>/dev/null
	elif [[ $(echo $?) != 0 ]]; then
		echo -e "\e[31m $1 has been not installed.\e[0m"
	fi
#function end
}
function START_SERVICE()
{
	systemctl enable $1 && systemctl restart $1 && echo -e "\e[32m $1 has been started. \e[0m"
#function end
}

#----------
#edit_hosts
#----------
#inset domainname to "/etc/hosts"
function EDIT_HOSTS()
{
	local _ARG=0
	for _ARG in $@;
		do
			if [[ $(grep "${_ARG}.gfstack.geo" /etc/hosts) = "" ]];then
				echo "#{IPADDRESS}	${_ARG}.gfstack.geo" >> /etc/hosts
			fi
		done
#function end
}


#=============
#role_function
#=============
#
#--------
#os_check
#--------
#
function OS_CHECK()
{
	local _NICNAME=$(ip addr|grep "^2"|awk -F ": " '{print $2}')
	local _HNAME=$(uname -n)
	local _IPADDRESS=$(hostname -I)
	local _OSVERSION=$(grep "CentOS Linux release 7.2.1511" /etc/redhat-release)
	local _GATEWAY=$(ip route list|grep "default"|awk '{print $3}')
	local _USERID=$(id -u)
	local _SESTATUS=$(sestatus|grep "^Current mode"|awk '{print $3}')
	local _MEMSIZE=$(free -g|grep "^Mem"|awk '{print $2}')
#	if [[ ${_MEMSIZE} < "14" ]];then
#		echo -e "\e[31m The host shall not be less than 16GB of memory. \e[0m" && exit 0
#	fi
	if [[ ${_NICNAME} != "eth0" ]];then
		sed -i s/"^NAME=.*$"/"NAME=eth0"/g /etc/sysconfig/network-scripts/ifcfg-${_NICNAME}
		sed -i s/"^DEVICE=.*$"/"DEVICE=eth0"/g /etc/sysconfig/network-scripts/ifcfg-${_NICNAME}
		mv /etc/sysconfig/network-scripts/ifcfg-${_NICNAME} /etc/sysconfig/network-scripts/ifcfg-eth0
		sed -i s/'rhgb quiet"$'/'net.ifnames=0 biosdevname=0 rhgb quiet"'/g /etc/default/grub
		grub2-mkconfig -o /boot/grub2/grub.cfg
		echo -e "\e[31m The computer will reboot,run me again on logined.\n Press 'Enter' key reboot ...\e[0m"
		read -t 5
		reboot
	fi
	if [[ ${_SESTATUS} != "permissive" ]];then
		sed -i s/SELINUX=.*/SELINUX=permissive/g /etc/selinux/config
		setenforce 0
	fi
	if [[ ${_OSVERSION} = "" ]];then
		echo -e "\e[31m Please use [CentOS 7.2.1511]. \e[0m" && exit 0
	else
		echo -e "\e[32m OS version is [\e[0m\e[36;4mCentOS 7.2.1511\e[0m\e[32m]. \e[0m"
	fi
	if [[ ${_USERID} != "0" ]];then
		echo -e "\e[31m Please use [root] login. \e[0m" && exit 0
	fi
	if [[ $(ping ${_GATEWAY} -w 3|grep "received"|awk '{print $4}') > "0" ]];then
		echo -e "\e[32m LAN is OK. \e[0m"
	else
		echo -e "\e[31m No connection of the LAN. \e[0m"
	fi
	if [[ $(ping www.kernel.org -w 3 2>/dev/null|grep "received"|awk '{print $4}') > "0" ]];then
		echo -e "\e[32m Internet is OK. \e[0m"
	else
		echo -e "\e[31m No connection of the internet. \e[0m"
	fi
	echo -e "\e[32m My hostname is [\e[0m\e[36;4m${_HNAME}\e[0m\b\e[32m].\e[0m"
	echo -e "\e[32m My ipaddress is [\e[0m\e[36;4m${_IPADDRESS}\e[0m\e[32m].\e[0m"
	echo -e "\e[32m My default gateway is [\e[0m\e[36;4m${_GATEWAY}\e[0m\e[32m].\e[0m"
	if [[ $(rpm -qa|grep "^vsftpd") != "" ]];then
		echo -e "\e[32m Vsftpd has been installed.\e[0m"
	else
		echo -e "\e[31m Vsftpd has been not installed.\e[0m" && exit 0
	fi
	EDIT_HOSTS "portal" "omgr" "mcsrv" "monsrv" "mqsrv" "db-exte" "db-inte" "owncloud" "cas" "lb" "geoonline"
#function end
}

#-----------
#setup_httpd
#-----------
#install and setup http service
function SETUP_HTTPD()
{
	CHECK_PACKAGE httpd
	if [[ -f "/etc/httpd/conf.d/welcome.conf" ]];then
		mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.old
	fi
	START_SERVICE httpd
#function end
}

#------------
#setup_vsftpd
#------------
#install and setup ftp service
function SETUP_VSFTPD()
{
	CHECK_PACKAGE vsftpd
	sed -i s/^root/#root/g /etc/vsftpd/ftpusers
	sed -i s/^root/#root/g /etc/vsftpd/user_list
	START_SERVICE vsftpd
#function end
}

#---------
#setup_ntp
#---------
#install and setup ntp service
function SETUP_NTP()
{
	local _INPUT=0
	while true;
		do
			clear
			echo "===================="
			echo "     Setup NTP      "
			echo "===================="
			echo -e "1.Create NTP [\e[1;36mserver\e[0m]."
			echo -e "2.Create NTP [\e[1;36mclient\e[0m]."
			echo -e "x.Back"
			read -p "Your choice is:" _INPUT
			case ${_INPUT} in
				1)
					CHECK_PACKAGE ntp
					START_SERVICE ntpd
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				2)
					CHECK_PACKAGE ntp
					sed -i s/^server/#server/g /etc/ntp.conf
					if [[ $(grep "server ntp.gfstack.geo iburst" /etc/ntp.conf) = "" ]];then
						echo "server ntp.gfstack.geo iburst" >> /etc/ntp.conf
					fi
					START_SERVICE ntpd
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				x)
					echo -e "\e[31m Press 'Enter' key back.\e[0m"
					read -t 5
					break
					;;
				*)
					echo -e "\e[31m What are you doing?\n Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
			esac
		done
#function end
}

#-------------
#setup_libvirt
#-------------
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

#------------------
#create_repo_server
#------------------
#
function CREATE_REPO()
{
	local _INPUT=0
	while true;
		do
			clear
			echo "===================="
			echo "    Create Repo     "
			echo "===================="
			echo -e "1.Create repo \e[4;36mserver\e[0m."
			echo -e "2.Create repo \e[4;36mclient\e[0m."
			echo -e "x.Back"
			read -p "Your choice is:" _INPUT
			case ${_INPUT} in
				1)
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read
					clear
					;;
				2)
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read
					clear
					;;
				x)
					echo -e "\e[31m Press 'Enter' key back.\e[0m"
					read -t
					break
					;;
				*)
					echo -e "\e[31m What are you doing?\n Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
			esac
		done
#function end
}

#--------------
#setup_iptables
#--------------
#setup iptables,clear forward_list
function SETUP_IPTABLES()
{
	CHECK_PACKAGE iptables-services
	sed -i s/'IPTABLES_SAVE_ON_STOP="no"'/'IPTABLES_SAVE_ON_STOP="yes"'/g /etc/sysconfig/iptables-config
	sed -i s/'IPTABLES_SAVE_ON_RESTART="no"'/'IPTABLES_SAVE_ON_RESTART="yes"'/g /etc/sysconfig/iptables-config
cat>/root/clear_forward_list.sh<<EOF
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
	START_SERVICE iptables && sh /root/clear_forward_list.sh
#function end
}

#----------------
#define_container
#----------------
#$1=container name
#$2=container maxmemory
function DEFINE_CONTAINER()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _GET_LIBIVRTD_STATUS=$(ps aux|grep "libvirtd"|grep -v "grep")
	mkdir -p ${_IMAGE_PATH}/{xml_lxc,template}
	CHECK_PACKAGE bzip2
	if [[ ${_GET_LIBIVRTD_STATUS} != "" ]];then
		echo -e "\e[32m libvirtd.service has running."
	elif [[ ${_GET_LIBIVRTD_STATUS} = "" ]];then
		echo -e "\e[31m libvirt has been not running or installed." && exit 0
	fi
cat>${_IMAGE_PATH}/xml_lxc/$1-server.xml<<EOF
<domain type="lxc">
  <name>$1-server</name>
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
      <source dir="${_IMAGE_PATH}/$1-server"/>
      <target dir="/"/>
    </filesystem>
    <interface type="bridge">
      <source bridge="virbr0"/>
    </interface>
    <console type="pty"/>
  </devices>
</domain>
EOF
	if [[ ! -f ${_IMAGE_PATH}/template/$1-server.tar.bz2 ]];then
		echo -e "\e[31m [$1-server.tar.bz2] does not exist,upload it and run me again.\n upload path:${_IMAGE_PATH}\e[0m" && exit 0
	else
		tar jxvf ${_IMAGE_PATH}/template/$1-server.tar.bz2 -C ${_IMAGE_PATH}/ &>/dev/null
	fi
#function end
}

#----------------
#write_deploy_log
#----------------
#Write log file After the container deployment
function WRITE_DEPLOY_LOG()
{
	touch container_deploy.log
	sed -i "/^$1/d" container_deploy.log
	echo -e "$1\t$2\t$(date +%Y%m%d%H%M%S)" >> container_deploy.log
	cat container_deploy.log
	echo -e "\e[31m Press 'Enter' key Continue.\e[0m"
	read -t 5
#function end	
}

#---------------------------
#01.deploy_container_setupdb
#---------------------------
#deploy container "setupdb-server"
function DEPLOY_CONTAINER_SETUPDB()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _CONTAINER_ROLE=setupdb
	local _CONTAINER_RAM=""
	while true;
		do
			clear
			echo -e "\e[33;1m Container MINI_RAM=2GB]\e[0m"
			echo -e "\e[33;1m 1GB=1024MB=1048576KB\e[0m"
			read -p "Container memory size is(KB):" _CONTAINER_RAM
			if [ ${_CONTAINER_RAM} -ge ${_CONTAINER_RAM} &>/dev/null -a ${_CONTAINER_RAM} -gt 2097152 ];then
				echo -e "\e[32m You enter memory size is [\e[32;1m$[${_CONTAINER_RAM}/1024]\e[0m]MB\e[0m"
				break 1
			else
				echo -e "\e[31m Please enter a positive integer.\n Press 'Enter' key Continue.\e[0m"
				read -t 5
				continue
			fi
		done
	virsh -c lxc:/// destroy ${_CONTAINER_ROLE}-server &>/dev/null
	virsh -c lxc:/// undefine ${_CONTAINER_ROLE}-server &>/dev/null
	rm -rf /etc/libvirt/qemu/networks/autostart/${_CONTAINER_ROLE}-server
	DEFINE_CONTAINER ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
	if [[ $(iptables -t nat -L|grep "DNAT.*10:3306") = "" ]];then
        iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 3306 --jump DNAT --to-destination 192.168.122.10:3306
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*10:22") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 2210 --jump DNAT --to-destination 192.168.122.10:22
	fi
	virsh -c lxc:/// define ${_IMAGE_PATH}/xml_lxc/${_CONTAINER_ROLE}-server.xml
	virsh -c lxc:/// autostart ${_CONTAINER_ROLE}-server
	virsh -c lxc:/// start ${_CONTAINER_ROLE}-server
	WRITE_DEPLOY_LOG ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
#function end
}

#-------------------------
#02.deploy_container_mcsrv
#-------------------------
#deploy container "mcsrv-server"
function DEPLOY_CONTAINER_MCSRV()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _CONTAINER_ROLE=mcsrv
	local _CONTAINER_RAM=""
	while true;
		do
			clear
			echo -e "\e[33;1m Container MINI_RAM=2GB]\e[0m"
			echo -e "\e[33;1m 1GB=1024MB=1048576KB\e[0m"
			read -p "Container memory size is(KB):" _CONTAINER_RAM
			if [ ${_CONTAINER_RAM} -ge ${_CONTAINER_RAM} &>/dev/null -a ${_CONTAINER_RAM} -gt 2097152 ];then
				echo -e "\e[32m You enter memory size is [\e[32;1m$[${_CONTAINER_RAM}/1024]\e[0m]MB\e[0m"
				break 1
			else
				echo -e "\e[31m Please enter a positive integer.\n Press 'Enter' key Continue.\e[0m"
				read -t 5
				continue
			fi
		done
	virsh -c lxc:/// destroy ${_CONTAINER_ROLE}-server &>/dev/null
	virsh -c lxc:/// undefine ${_CONTAINER_ROLE}-server &>/dev/null
	rm -rf /etc/libvirt/qemu/networks/autostart/${_CONTAINER_ROLE}-server
	DEFINE_CONTAINER ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
	if [[ $(iptables -t nat -L|grep "DNAT.*11211") = "" ]];then
        iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 11211 --jump DNAT --to-destination 192.168.122.20:11211
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*20:22") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 2220 --jump DNAT --to-destination 192.168.122.20:22
	fi
	virsh -c lxc:/// define ${_IMAGE_PATH}/xml_lxc/${_CONTAINER_ROLE}-server.xml
	virsh -c lxc:/// autostart ${_CONTAINER_ROLE}-server
	virsh -c lxc:/// start ${_CONTAINER_ROLE}-server
	WRITE_DEPLOY_LOG ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
#function end
}

#-------------------------
#03.deploy_container_mqsrv
#-------------------------
#deploy container "mqsrv-server"
function DEPLOY_CONTAINER_MQSRV()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _CONTAINER_ROLE=mqsrv
	local _CONTAINER_RAM=""
	while true;
		do
			clear
			echo -e "\e[33;1m Container MINI_RAM=2GB]\e[0m"
			echo -e "\e[33;1m 1GB=1024MB=1048576KB\e[0m"
			read -p "Container memory size is(KB):" _CONTAINER_RAM
			if [ ${_CONTAINER_RAM} -ge ${_CONTAINER_RAM} &>/dev/null -a ${_CONTAINER_RAM} -gt 2097152 ];then
				echo -e "\e[32m You enter memory size is [\e[32;1m$[${_CONTAINER_RAM}/1024]\e[0m]MB\e[0m"
				break 1
			else
				echo -e "\e[31m Please enter a positive integer.\n Press 'Enter' key Continue.\e[0m"
				read -t 5
				continue
			fi
		done
	virsh -c lxc:/// destroy ${_CONTAINER_ROLE}-server &>/dev/null
	virsh -c lxc:/// undefine ${_CONTAINER_ROLE}-server &>/dev/null
	rm -rf /etc/libvirt/qemu/networks/autostart/${_CONTAINER_ROLE}-server
	DEFINE_CONTAINER ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
	if [[ $(iptables -t nat -L|grep "DNAT.*8161") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 8161 --jump DNAT --to-destination 192.168.122.30:8161
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*61616") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 61616 --jump DNAT --to-destination 192.168.122.30:61616
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*30:22") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 2230 --jump DNAT --to-destination 192.168.122.30:22
	fi
	virsh -c lxc:/// define ${_IMAGE_PATH}/xml_lxc/${_CONTAINER_ROLE}-server.xml
	virsh -c lxc:/// autostart ${_CONTAINER_ROLE}-server
	virsh -c lxc:/// start ${_CONTAINER_ROLE}-server
	WRITE_DEPLOY_LOG ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
#function end
}

#--------------------------
#04.deploy_container_monsrv
#--------------------------
#deploy container "monsrv-server"
function DEPLOY_CONTAINER_MONSRV()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _CONTAINER_ROLE=monsrv
	local _CONTAINER_RAM=""
	while true;
		do
			clear
			echo -e "\e[33;1m Container MINI_RAM=2GB]\e[0m"
			echo -e "\e[33;1m 1GB=1024MB=1048576KB\e[0m"
			read -p "Container memory size is(KB):" _CONTAINER_RAM
			if [ ${_CONTAINER_RAM} -ge ${_CONTAINER_RAM} &>/dev/null -a ${_CONTAINER_RAM} -gt 2097152 ];then
				echo -e "\e[32m You enter memory size is [\e[32;1m$[${_CONTAINER_RAM}/1024]\e[0m]MB\e[0m"
				break 1
			else
				echo -e "\e[31m Please enter a positive integer.\n Press 'Enter' key Continue.\e[0m"
				read -t 5
				continue
			fi
		done
	virsh -c lxc:/// destroy ${_CONTAINER_ROLE}-server &>/dev/null
	virsh -c lxc:/// undefine ${_CONTAINER_ROLE}-server &>/dev/null
	rm -rf /etc/libvirt/qemu/networks/autostart/${_CONTAINER_ROLE}-server
	DEFINE_CONTAINER ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
	if [[ $(iptables -t nat -L|grep "DNAT.*40:80") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 8084 --jump DNAT --to-destination 192.168.122.40:80
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*10051") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 10051 --jump DNAT --to-destination 192.168.122.40:10051
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*10052") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 10052 --jump DNAT --to-destination 192.168.122.40:10052
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*40:22") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 2240 --jump DNAT --to-destination 192.168.122.40:22
	fi
	virsh -c lxc:/// define ${_IMAGE_PATH}/xml_lxc/${_CONTAINER_ROLE}-server.xml
	virsh -c lxc:/// autostart ${_CONTAINER_ROLE}-server
	virsh -c lxc:/// start ${_CONTAINER_ROLE}-server
	WRITE_DEPLOY_LOG ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
#function end
}

#----------------------------
#05.deploy_container_geostack
#----------------------------
#deploy container "geostack-server"
function DEPLOY_CONTAINER_GEOSTACK()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _CONTAINER_ROLE=geostack
	local _CONTAINER_RAM=""
	while true;
		do
			clear
			echo -e "\e[33;1m Container MINI_RAM=2GB]\e[0m"
			echo -e "\e[33;1m 1GB=1024MB=1048576KB\e[0m"
			read -p "Container memory size is(KB):" _CONTAINER_RAM
			if [ ${_CONTAINER_RAM} -ge ${_CONTAINER_RAM} &>/dev/null -a ${_CONTAINER_RAM} -gt 2097152 ];then
				echo -e "\e[32m You enter memory size is [\e[32;1m$[${_CONTAINER_RAM}/1024]\e[0m]MB\e[0m"
				break 1
			else
				echo -e "\e[31m Please enter a positive integer.\n Press 'Enter' key Continue.\e[0m"
				read -t 5
				continue
			fi
		done
	virsh -c lxc:/// destroy ${_CONTAINER_ROLE}-server &>/dev/null
	virsh -c lxc:/// undefine ${_CONTAINER_ROLE}-server &>/dev/null
	rm -rf /etc/libvirt/qemu/networks/autostart/${_CONTAINER_ROLE}-server
	DEFINE_CONTAINER ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
	if [[ $(iptables -t nat -L|grep "DNAT.*50:8080") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 8083 --jump DNAT --to-destination 192.168.122.50:8080
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*50:22") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 2250 --jump DNAT --to-destination 192.168.122.50:22
	fi
	virsh -c lxc:/// define ${_IMAGE_PATH}/xml_lxc/${_CONTAINER_ROLE}-server.xml
	virsh -c lxc:/// autostart ${_CONTAINER_ROLE}-server
	virsh -c lxc:/// start ${_CONTAINER_ROLE}-server
	WRITE_DEPLOY_LOG ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
#function end
}

#----------------------------
#06.deploy_container_owncloud
#----------------------------
#deploy container "owncloud-server"
function DEPLOY_CONTAINER_OWNCLOUD()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _CONTAINER_ROLE=owncloud
	local _CONTAINER_RAM=""
	while true;
		do
			clear
			echo -e "\e[33;1m Container MINI_RAM=2GB]\e[0m"
			echo -e "\e[33;1m 1GB=1024MB=1048576KB\e[0m"
			read -p "Container memory size is(KB):" _CONTAINER_RAM
			if [ ${_CONTAINER_RAM} -ge ${_CONTAINER_RAM} &>/dev/null -a ${_CONTAINER_RAM} -gt 2097152 ];then
				echo -e "\e[32m You enter memory size is [\e[32;1m$[${_CONTAINER_RAM}/1024]\e[0m]MB\e[0m"
				break 1
			else
				echo -e "\e[31m Please enter a positive integer.\n Press 'Enter' key Continue.\e[0m"
				read -t 5
				continue
			fi
		done
	virsh -c lxc:/// destroy ${_CONTAINER_ROLE}-server &>/dev/null
	virsh -c lxc:/// undefine ${_CONTAINER_ROLE}-server &>/dev/null
	rm -rf /etc/libvirt/qemu/networks/autostart/${_CONTAINER_ROLE}-server
	DEFINE_CONTAINER ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
	if [[ $(iptables -t nat -L|grep "DNAT.*60:80") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 8082 --jump DNAT --to-destination 192.168.122.60:80
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*60:22") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 2260 --jump DNAT --to-destination 192.168.122.60:22
	fi
	virsh -c lxc:/// define ${_IMAGE_PATH}/xml_lxc/${_CONTAINER_ROLE}-server.xml
	virsh -c lxc:/// autostart ${_CONTAINER_ROLE}-server
	virsh -c lxc:/// start ${_CONTAINER_ROLE}-server
	WRITE_DEPLOY_LOG ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
#function end
}

#-----------------------------
#07.deploy_container_geoonline
#-----------------------------
#deploy container "geoonline-server"
function DEPLOY_CONTAINER_GEOONLINE()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _CONTAINER_ROLE=geoonline
	local _CONTAINER_RAM=""
	while true;
		do
			clear
			echo -e "\e[33;1m Container MINI_RAM=2GB]\e[0m"
			echo -e "\e[33;1m 1GB=1024MB=1048576KB\e[0m"
			read -p "Container memory size is(KB):" _CONTAINER_RAM
			if [ ${_CONTAINER_RAM} -ge ${_CONTAINER_RAM} &>/dev/null -a ${_CONTAINER_RAM} -gt 2097152 ];then
				echo -e "\e[32m You enter memory size is [\e[32;1m$[${_CONTAINER_RAM}/1024]\e[0m]MB\e[0m"
				break 1
			else
				echo -e "\e[31m Please enter a positive integer.\n Press 'Enter' key Continue.\e[0m"
				read -t 5
				continue
			fi
		done
	virsh -c lxc:/// destroy ${_CONTAINER_ROLE}-server &>/dev/null
	virsh -c lxc:/// undefine ${_CONTAINER_ROLE}-server &>/dev/null
	rm -rf /etc/libvirt/qemu/networks/autostart/${_CONTAINER_ROLE}-server
	DEFINE_CONTAINER ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
	if [[ $(iptables -t nat -L|grep "DNAT.*80:8080") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 8081 --jump DNAT --to-destination 192.168.122.80:8080
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*80:22") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 2280 --jump DNAT --to-destination 192.168.122.80:22
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*80:10012") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 10012 --jump DNAT --to-destination 192.168.122.80:10012
	fi
	virsh -c lxc:/// define ${_IMAGE_PATH}/xml_lxc/${_CONTAINER_ROLE}-server.xml
	virsh -c lxc:/// autostart ${_CONTAINER_ROLE}-server
	virsh -c lxc:/// start ${_CONTAINER_ROLE}-server
	WRITE_DEPLOY_LOG ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
#function end
}

#----------------------
#08.deploy_container_lb
#----------------------
#deploy container "lb-server"
function DEPLOY_CONTAINER_LB()
{
	local _IMAGE_PATH=/var/lib/libvirt/images
	local _CONTAINER_ROLE=lb
	local _CONTAINER_RAM=""
	while true;
		do
			clear
			echo -e "\e[33;1m Container MINI_RAM=2GB]\e[0m"
			echo -e "\e[33;1m 1GB=1024MB=1048576KB\e[0m"
			read -p "Container memory size is(KB):" _CONTAINER_RAM
			if [ ${_CONTAINER_RAM} -ge ${_CONTAINER_RAM} &>/dev/null -a ${_CONTAINER_RAM} -gt 2097152 ];then
				echo -e "\e[32m You enter memory size is [\e[32;1m$[${_CONTAINER_RAM}/1024]\e[0m]MB\e[0m"
				break 1
			else
				echo -e "\e[31m Please enter a positive integer.\n Press 'Enter' key Continue.\e[0m"
				read -t 5
				continue
			fi
		done
	virsh -c lxc:/// destroy ${_CONTAINER_ROLE}-server &>/dev/null
	virsh -c lxc:/// undefine ${_CONTAINER_ROLE}-server &>/dev/null
	rm -rf /etc/libvirt/qemu/networks/autostart/${_CONTAINER_ROLE}-server
	DEFINE_CONTAINER ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
	if [[ $(iptables -t nat -L|grep "DNAT.*90:8080") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 8085 --jump DNAT --to-destination 192.168.122.90:8080
	fi
	if [[ $(iptables -t nat -L|grep "DNAT.*90:22") = "" ]];then
		iptables --table nat --append PREROUTING --in-interface eth0 --protocol tcp --dport 2290 --jump DNAT --to-destination 192.168.122.90:22
	fi
	virsh -c lxc:/// define ${_IMAGE_PATH}/xml_lxc/${_CONTAINER_ROLE}-server.xml
	virsh -c lxc:/// autostart ${_CONTAINER_ROLE}-server
	virsh -c lxc:/// start ${_CONTAINER_ROLE}-server
	WRITE_DEPLOY_LOG ${_CONTAINER_ROLE} ${_CONTAINER_RAM}
#function end
}


#================
#Application_menu
#================
#run function
function APPLICATION_MENU()
{
	local _INPUT=0
	while true;
		do
			clear
			echo "===================="
			echo "  Deploy Container  "
			echo "===================="
			echo -e "1.Deploy [\e[1;36mSetupDB(MySQL)\e[0m] container."
			echo -e "2.Deploy [\e[1;36mMemcached\e[0m] container."
			echo -e "3.Deploy [\e[1;36mActiveMQ\e[0m] container."
			echo -e "4.Deploy [\e[1;36mZabbix\e[0m] container."
			echo -e "5.Deploy [\e[1;36mGeoStack\e[0m] container."
			echo -e "6.Deploy [\e[1;36mOwnCloud\e[0m] container."
			echo -e "7.Deploy [\e[1;36mGeoOnline\e[0m] container."
			echo -e "x.Back"
			read -p "Your choice is:" _INPUT
			case ${_INPUT} in
				1)
					DEPLOY_CONTAINER_SETUPDB
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				2)
					DEPLOY_CONTAINER_MCSRV
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				3)
					DEPLOY_CONTAINER_MQSRV
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				4)
					DEPLOY_CONTAINER_MONSRV
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				5)
					DEPLOY_CONTAINER_GEOSTACK
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				6)
					DEPLOY_CONTAINER_OWNCLOUD
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				7)
					DEPLOY_CONTAINER_GEOONLINE
					echo -e "\e[32m Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
				x)
					echo -e "\e[31m Press 'Enter' key back.\e[0m"
					read -t 5
					break
					;;
				*)
					echo -e "\e[31m What are you doing?\n Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					;;
			esac
		done
#function end
}


#===========
#master_menu
#===========
#select function & run script
_INPUT_=""
while true;
    do
        clear
        echo -e "\e[33;1m##############################################\e[0m"
        echo -e "\e[33;1m Start system testing......\e[0m"
        OS_CHECK
		echo -e "\e[33;1m System testing is completed.\e[0m"
        echo -e "\e[33;1m##############################################\e[0m"
        echo -e "\e[1m==============================================\e[0m"
        echo -e "\e[1m Filename: $(echo $0)\e[0m"
    	echo -e "\e[1m Features: initialize OS and deploy container.\e[0m"
        echo -e "\e[1m Version: 1.0\e[0m"
        echo -e "\e[1m Buildtime: 20160906\e[0m"
        echo -e "\e[1m Editor: guile.liao\e[0m"
        echo -e "\e[1m Email: liaolei@geostar.com.cn\e[0m"
        echo -e "\e[1m Copyleft: Licensed under the GPLv3\e[0m"
        echo -e "\e[1m==============================================\e[0m"
    	echo -e "\e[34;1m  0.Create ntp service\e[0m"
    	echo -e "\e[34;1m  1.Create ftp server\e[0m"
    	echo -e "\e[34;1m  2.Setup firewall\e[0m"
    	echo -e "\e[34;1m  3.Create container runtime\e[0m"
    	echo -e "\e[34;1m  4.Depoly Base-Application container\e[0m"
    	echo -e "\e[34;1m  5.Depoly GeoGlobe-Server container\e[0m"
    	echo -e "\e[34;1m  6.Deploy GeoAgent\e[0m"
    	echo -e "\e[34;1m  7.Deploy Zabbix-Agent\e[0m"
    	echo -e "\e[34;1m  8.NULL\e[0m"
    	echo -e "\e[34;1m  9.NULL\e[0m"
    	echo -e "\e[34;1m  x.Exit Menu\e[0m"
    	read -p "Your choice is:" _INPUT_
    	case ${_INPUT_} in
            0)
                clear
    			SETUP_NTP
				echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		1)
    			clear
				SETUP_VSFTPD
    			echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		2)
    			clear
    			SETUP_IPTABLES
				echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		3)
    			clear
				SETUP_LIBVIRT
    			echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		4)
    			clear
				APPLICATION_MENU
    			echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		5)
    			clear
    			echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		6)
    			clear
    			echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		7)
    			clear
    			echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		8)
    			clear
    			echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		9)
    			clear
    			echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                read -t 5
    			;;
    		x)
    			clear
    			echo -e "\e[31m Press 'Enter' key exit.\e[0m"
                read -t 5
                clear
    			break
    			;;
    		*)
                clear
                echo -e "\e[31m What are you doing?\n Press 'Enter' key continue.\e[0m"
                read -t 5
    			;;
            esac
    done
##########
#file end#
##########