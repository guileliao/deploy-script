#!/bin/sh
#
# Filename: deploy_single_role.sh 
# Features: initialize OS and deploy container
# Version: 1.0
# Buildtime: 201608
# Editor: guile.liao
# Email: liaolei@geostar.com.cn
# Copyleft: Licensed under the GPLv3
# 
#
#=======
#
#=======

set -u
set -e
#
#
#===============
#public_function
#===============

function CHECK_FILE()
{
        if [[ ! -f $1 ]];then
                echo -e "\e[31m Please upload [$1],and run me again. \e[0m" && exit 0
        elif [[ $(md5sum $1|awk '{print $1}') != "$2" ]];then
                echo -e "\e[31m Please check md5sum for [$1],and run me again. \e[0m" && exit 0
        else
                echo -e "\e[32m [\e[0m\e[36;4m$1\e[0m] is OK. \e[0m"
        fi
}

function CHECK_DIR()
{
	if [[ ! -d $1 ]];then
		mkdir -p $1	
	fi
}

function CHECK_PACKAGE()
{
	if [[ $(rpm -qa|grep $1|grep -v grep) = "" ]];then
	
		yum install -y $1 2>/dev/null 1>/dev/null
	fi
}

function START_SERVICE()
{
	systemctl enable $1 && systemctl restart $1 && echo -e "\e[32m $1 has been started. \e[0m"
}


##################################################################################################

#=======
#license
#=======

clear

function LICENSE_AGREE()
{
	read -p "Do you agree to follow the GPLv3? [yes|no]:" _MYLICENSE_
	if [[ ${_MYLICENSE_} != "yes" ]];then
		echo -e "\e[31m Bye-Bye.\e[0m" && exit 0
	fi
}

LICENSE_AGREE

clear
#
#
#========
#os_check
#========

function OS_CHECK()
{
	echo -e "\e[32m My IPaddress is [\e[0m\e[36;4m$(hostname -I)\e[0m\b\e[32m].\e[0m"
	echo -e "\e[32m My hostname is [\e[0m\e[36;4m$(hostname)\e[0m\e[32m].\e[0m"

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
	elif [[ ${_SE_STATE_} = "disabled" ]];then
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
}
#
#
#==================
#create_repo_server
#==================

function CREATE_REPO_SERVER()
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
	CHECK_FILE cas-server.tar.bz2 874b91ab19daacc5080a82ba6953d82c
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

	if [[ $(rpm -qa|grep "httpd"|grep -v "grep") = "" ]];then
		yum install -y httpd 1>/dev/null && systemctl enable httpd && systemctl start httpd
	else
		systemctl enable httpd && systemctl start httpd
	fi

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
	#CHECK_DIR /var/www/html/container/xml
	mv $(pwd)/RepoSocket.jar $(pwd)/jdk-6u45-linux-amd64.rpm  /var/www/html/utility/
	mv $(pwd)/*-server.tar.bz2  /var/www/html/container/template/
	mv $(pwd)/geoagent.tar.bz2  /var/www/html/geoagent/
	mv $(pwd)/activemq-cpp-3.8.3-1.el7.x86_64.rpm /var/www/html/geoagent/
	mv $(pwd)/geoglobe-runtime.tar.bz2  /var/www/html/container/template/

	(yum clean all 1>/dev/null 2>/dev/null && yum makecache 1>/dev/null 2>/dev/null && echo -e "\e[32m Repo_Server has been created. \e[0m")||echo -e "\e[31m Repo_Server create error. \e[0m"
}
#
#
#==================
#create_repo_client
#==================

function CREATE_REPO_CLIENT()
{
	read -p "Please input support_server ipaddress:" _SUPPORT_SERVER_IP_

cat>/etc/yum.repos.d/centos7_local.repo<<EOF
	[CentOS7_Local]
	name=CentOS 7.2.1511 DVD
	baseurl=http://${_SUPPORT_SERVER_IP_}/centos7
	enabled=1
	gpgcheck=0
EOF

	(yum clean all 1>/dev/null 2>/dev/null && yum makecache 1>/dev/null 2>/dev/null && echo -e "\e[32m Repo_Client has been created. \e[0m")||echo -e "\e[31m Repo_Client create error. \e[0m"

}
#
#
#=================
#deploy_dns_server
#=================

function DEPLOY_DNS_SERVER()
{
	
}
#
#
#==============
#setup BUILDING
#==============

#echo "$(date +%Y%m%d%H%M)" > /BUILDING

#read -p "Restart computer?[yes|no]" _YN_

#if [[ ${_YN_} = "yes" || ${_YN1_} = "YES" ]];then
#	reboot
#elif [[ ${_YN_} = "no" || ${_YN1_} = "NO" ]];then
#	echo -e "\e[31m What are you doing? \e[0m" && exit 0
#else
#	echo -e "\e[31m What are you doing? \e[0m" && exit 0
#fi
#
#
##################################################################################################

echo -e "\e[2m\t(a)\e[0m Environment Check"
echo -e "\e[2m\t(b)\e[0m Create Repo Server"
echo -e "\e[2m\t(c)\e[0m Create Repo Client"

read -p "Please change:" _CHANGE_

case ${_CHANGE_} in
	a)
		OS_CHECK
		;;
	b)
		CREATE_REPO_SERVER
		;;
	c)
		CREATE_REPO_CLIENT
		;;
	d)
		CREATE_REPO_SERVER
		;;
	e)
		exit 0
		;;
esac
#
#
##########
#File end#
##########
