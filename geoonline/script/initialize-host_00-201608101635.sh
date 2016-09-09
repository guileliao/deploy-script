#!/bin/sh
#
# Filename: initialize-host_00.sh 
# Features: initialize OS for host-00
# Version: 1.0
# Buildtime: 201608101635
# Editor: guile.liao
# Email: liaolei@geostar.com.cn
# Copyleft: Licensed under the GPLv3
# 
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
                echo -e "\e[32m [$1] is OK. \e[0m"
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
if [[ ${_MYNAME_} != "host-00" ]];then
	echo -e "\e[31m Please make sure my hostname.\e[0m" && exit 0
fi
#
#
#========
#os_check
#========

function OS_CHECK()
{
	echo -e "\e[32m My IPaddress is [\e[0m\e[36;4m$(hostname -I)\e[0m\b\e[32m].\e[0m"

	if [[ $(grep "CentOS Linux release 7.2.1511" /etc/redhat-release) = "" ]];then
		echo -e "\e[31m Please use [CentOS 7.2.1511]. \e[0m" && exit 0
	else
		echo -e "\e[32m OS is OK. \e[0m"
	fi

	if [[ $(whoami) = "root" ]];then
		echo -e "\e[32m You are ROOT. \e[0m"
	else
		echo -e "\e[31m Please use [root] login. \e[0m" && exit 0
	fi
}
OS_CHECK
#
#
#==========
#file_check
#==========

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
#CHECK_FILE geoonline-server.tar.bz2
CHECK_FILE cas-server.tar.bz2 874b91ab19daacc5080a82ba6953d82c
CHECK_FILE geoagent.tar.bz2 ed3837988f7053b56b0163229cdd5c74
CHECK_FILE geoglobe-runtime.tar.bz2 04ca82b27a85e855af20e0015b8fbd1e
#
#
#====================
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
#===============
#close firewalld
#===============

systemctl disable firewalld > /dev/null
systemctl stop firewalld 2>/dev/null 1>/dev/null
#
#
#===========
#setup hosts
#===========

echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
echo "$(hostname -I)	host-00" >> /etc/hosts
echo '#HOST-01-IPADDRESS	host-01' >> /etc/hosts
echo '#HOST-02-IPADDRESS	host-02' >> /etc/hosts
echo '#HOST-03-IPADDRESS	host-03' >> /etc/hosts
echo '#HOST-04-IPADDRESS	host-04' >> /etc/hosts
echo '#HOST-05-IPADDRESS	host-05' >> /etc/hosts
echo '#HOST-06-IPADDRESS	host-06' >> /etc/hosts
echo '#HOST-07-IPADDRESS	host-07' >> /etc/hosts

#function ADD_HOST()
#{
#	read -p "Please input hostname:" $1
#	read -p "Please input ipaddr:" $2
#
#	if [[ $(grep "$2.*$1" /etc/hosts) = "" ]];then
#		echo "$2 $1" >> /etc/hosts
#	fi
#}
#
#
#=================================
#create CentOS7 DVD for repo_local
#=================================

CHECK_DIR $(pwd)/centos7

umount $(mount | grep "CentOS-7-x86_64-DVD-1511.iso" | awk '{print $3}') 2>/dev/null
mount -o loop $(pwd)/CentOS-7-x86_64-DVD-1511.iso $(pwd)/centos7

tar jcvf /etc/yum.repos.d/bak_$(date +%Y%m%d%H%M).tar.bz2 /etc/yum.repos.d/*.repo 2>/dev/null 1>/dev/null
rm -rf /etc/yum.repos.d/*.repo
echo '[CentOS7_Local]' > /etc/yum.repos.d/centos7_local.repo
echo 'name=CentOS 7.2.1511 DVD' >> /etc/yum.repos.d/centos7_local.repo
echo "baseurl=file://$(pwd)/centos7" >> /etc/yum.repos.d/centos7_local.repo
echo 'enabled=1' >> /etc/yum.repos.d/centos7_local.repo
echo 'gpgcheck=0' >> /etc/yum.repos.d/centos7_local.repo
yum clean all > /dev/null && yum makecache >/dev/null
#
#
#=============
#install tools
#=============

yum install -y wget ftp net-tools createrepo vsftpd httpd dnsmasq ntp bzip2 >/dev/null
#
#
#=======================
#install and setup httpd
#=======================

CHECK_PACKAGE httpd

if [[ -f "/etc/httpd/conf.d/welcome.conf" ]];then
        mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.old
fi

START_SERVICE httpd
#
#
#========================
#install and setup vsftpd
#========================

CHECK_PACKAGE vsftpd

sed -i s/^root/#root/g /etc/vsftpd/ftpusers
sed -i s/^root/#root/g /etc/vsftpd/user_list

START_SERVICE vsftpd
#
#
#=============================
#install and setup ntpd server
#=============================

CHECK_PACKAGE ntp
START_SERVICE ntpd
#
#
#=========================
#install and setup dnsmasq
#=========================

CHECK_PACKAGE dnsmasq

if [[ -d /etc/dnsmasq.bak ]];then
	cp -a /etc/dnsmasq.conf /etc/dnsmasq.bak/dnsmasq.conf.$(date +%Y%m%d%H%M) 
else
	mkdir /etc/dnsmasq.bak && cp -a /etc/dnsmasq.conf /etc/dnsmasq.bak/dnsmasq.conf.$(date +%Y%m%d%H%M)
fi

if [[ $(grep "^resolv-file=" /etc/dnsmasq.conf) = "" ]];then
	echo "resolv-file=/etc/resolv.conf" >> /etc/dnsmasq.conf
fi

if [[ $(grep "^listen-address=" /etc/dnsmasq.conf) = "" ]];then
	echo "listen-address=$(hostname -I)" >> /etc/dnsmasq.conf
fi

echo "#######################" > /etc/dnsmasq.d/gfstack.geo
echo "#GeoStack DNS A record#" >> /etc/dnsmasq.d/gfstack.geo
echo "#######################" >> /etc/dnsmasq.d/gfstack.geo
echo "#" >> /etc/dnsmasq.d/gfstack.geo
echo "#====" >> /etc/dnsmasq.d/gfstack.geo
echo "#HOST" >> /etc/dnsmasq.d/gfstack.geo
echo "#====" >> /etc/dnsmasq.d/gfstack.geo
echo "#" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=support01.gfstack.geo,host-00" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=host-01.gfstack.geo,host-01" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=host-02.gfstack.geo,host-02" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=host-03.gfstack.geo,host-03" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=host-04.gfstack.geo,host-04" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=host-05.gfstack.geo,host-05" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=host-06.gfstack.geo,host-06" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=host-07.gfstack.geo,host-07" >> /etc/dnsmasq.d/gfstack.geo
echo "#========" >> /etc/dnsmasq.d/gfstack.geo
echo "#GEOSTACK" >> /etc/dnsmasq.d/gfstack.geo
echo "#========" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=ntp.gfstack.geo,host-00" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=repo01.gfstack.geo,host-00" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=mcsrv.gfstack.geo,host-01" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=db-exte.gfstack.geo,host-01" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=db-inte.gfstack.geo,host-01" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=owncloud.gfstack.geo,host-01" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=geostack.gfstack.geo,host-02" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=mqsrv.gfstack.geo,host-02" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=monsrv.gfstack.geo,host-02" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=geoonline.gfstack.geo,host-03" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=cas.gfstack.geo,host-03" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=lb.gfstack.geo,host-04" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=gisdb.gfstack.geo,host-05" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=lxchost01.gfstack.geo,host-06" >> /etc/dnsmasq.d/gfstack.geo
echo "cname=lxchost02.gfstack.geo,host-07" >> /etc/dnsmasq.d/gfstack.geo
echo "#cname=lxchost03.gfstack.geo,host-08" >> /etc/dnsmasq.d/gfstack.geo
echo "#" >> /etc/dnsmasq.d/gfstack.geo
echo "##########" >> /etc/dnsmasq.d/gfstack.geo
echo "#FILE END#" >> /etc/dnsmasq.d/gfstack.geo
echo "##########" >> /etc/dnsmasq.d/gfstack.geo

START_SERVICE dnsmasq
#
#
#====================
#setup RepoSocket.jar
#====================

rpm -ivh $(pwd)/jdk-6u45-linux-amd64.rpm 2>/dev/null 1>/dev/null
cp -a /etc/profile /etc/profile.$(date +%Y%m%d%H%M)

if [[ $(grep 'export JAVA_HOME=/usr/java/jdk1.6.0_45' /etc/profile) = "" ]];then
	echo 'export JAVA_HOME=/usr/java/jdk1.6.0_45' >> /etc/profile
fi

if [[ $(grep 'export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/dt.jar' /etc/profile) = "" ]];then
        echo 'export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/dt.jar' >> /etc/profile
fi

if [[ $(grep 'export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/dt.jar' /etc/profile) = "" ]];then
	echo 'export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/dt.jar' >> /etc/profile
fi

if [[ $(grep 'export PATH=$JAVA_HOME/bin:$PATH' /etc/profile) = "" ]];then
	echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
fi

cp -a $(pwd)/RepoSocket.jar /opt/RepoSocket.jar
kill -9 $(ps aux|grep "java -jar /opt/RepoSocket.jar console"|grep -v grep|awk '{print $2}') 2>/dev/null
(java -jar /opt/RepoSocket.jar console 2>/opt/reposocket-error.log &) >/dev/null && echo -e "\e[32m RepoSocket.jar has been runnig. \e[0m"

if [[ $(grep "^java -jar /opt/RepoSocket.jar" /etc/rc.local) = "" ]];then
	echo 'java -jar /opt/RepoSocket.jar console 2>/opt/reposocket-error.log &' >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
fi
#
#
#==================
#create repo server
#==================

umount $(mount | grep "CentOS-7-x86_64-DVD-1511.iso" | awk '{print $3}') 2>/dev/null
mv $(pwd)/centos7 /var/www/html/
mv $(pwd)/CentOS-7-x86_64-DVD-1511.iso /var/www/html/
mount -o loop /var/www/html/CentOS-7-x86_64-DVD-1511.iso /var/www/html/centos7/

if [[ $(grep 'mount -o loop /var/www/html/CentOS-7-x86_64-DVD-1511.iso /var/www/html/centos7/' /etc/rc.local) = "" ]];then
        echo 'mount -o loop /var/www/html/CentOS-7-x86_64-DVD-1511.iso /var/www/html/centos7/' >> /etc/rc.local
fi

cat >/etc/yum.repos.d/centos7_local.repo<<EOF
[CentOS7_Local]
name=CentOS 7.2.1511 DVD
baseurl=file:///var/www/html/centos7
enabled=1
gpgcheck=0
EOF
yum clean all > /dev/null && yum makecache >/dev/null

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

read -p "Restart computer?[yes|no]" _YN1_
if [[ ${_YN1_} = "yes" || ${_YN1_} = "YES" ]];then
	reboot
elif [[ ${_YN1_} = "no" || ${_YN1_} = "NO" ]];then
	echo -e "\e[31m What are you doing? \e[0m" && exit 0
else
	echo -e "\e[31m What are you doing? \e[0m" && exit 0
fi
#
#
##########
#File end#
##########
