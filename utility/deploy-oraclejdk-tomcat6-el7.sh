#!/bin/bash
#
# Filename: deploy-oraclejdk-tomcat6.sh
# Features: setup oracleJDK and apache-tomcat6
# Version: 1.0
# Buildtime: 201609090900
# Editor: guile.liao
# Email: liaolei@geostar.com.cn
# Copyleft: Licensed under the GPLv3
#
#
# The warning message: color=red
# The correct message: color=green
# The information: color=yellow
# The menu: color=blue
# The keyword: color&highlighted 
# The global variable: _VARIABLE_NAME_
# The local variable: _VARIABLE_NAME
# The function: FUNCITON_NAME()
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
	if [[ $(free -g|grep "^Mem"|awk '{print $2}') < "6" ]];then
		echo -e "\e[31m The host shall not be less than 8GB of memory. \e[0m" && exit
	fi
#function end
}

#----------
#check_file
#----------
#check files and md5sum
function CHECK_FILE()
{
    if [[ ! -f $1 ]];then
        echo -e "\e[31m Please upload [$1],and run me again. \e[0m" && exit
    elif [[ $(md5sum $1|awk '{print $1}') != "$2" ]];then
        echo -e "\e[31m Please check md5sum for [$1],and run me again. \e[0m" && exit
    else
        echo -e "\e[32m [\e[0m\e[36;4m$1\e[0m\e[32m] is OK. \e[0m"
    fi
#function end
}


#=============
#role_function
#=============
#
#--------
#os_check
#--------
#check OS,display system information
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
	CHECK_FILE jdk-6u45-linux-amd64.rpm 518e6673f3f07e87bbef3e83f287b5f8
	CHECK_FILE apache-tomcat-6.0.45.tar.gz dc1db1e54157544dc5d042734c35cb99
#function end
}
OS_CHECK

#---------------
#setup_oraclejdk
#---------------
#install oracle jdk,setup $JAVA_HOME to /etc/profile
function SETUP_ORACLEJDK()
{
    if [[ -f $(pwd)/jdk-6u45-linux-amd64.rpm ]];then
        rpm -ivh $(pwd)/jdk-6u45-linux-amd64.rpm &>/dev/null && echo -e "\e[32m Oracle_JDK has been installed.\e[0m"
    else
        echo -e "\e[31m Please check file [\e[31;1mjdk-6u45-linux-amd64.rpm\e[0m\e[31m].\e[0m"
    fi
    cp -a /etc/profile /etc/profile_$(date +%Y%m%d%H%M%S)
    if [[ $(grep 'export JAVA_HOME=/usr/java/jdk1.6.0_45') = "" ]];then
        echo 'export JAVA_HOME=/usr/java/jdk1.6.0_45'>>/etc/profile
    fi
    if [[ $(grep 'export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/dt.jar') = "" ]];then
        echo 'export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/jre/lib/dt.jar'>>/etc/profile
    fi
    if [[ $(grep 'export PATH=$JAVA_HOME/bin:$PATH') = "" ]];then
        echo 'export PATH=$JAVA_HOME/bin:$PATH'>>/etc/profile
    fi
#function end
}
SETUP_ORACLEJDK

#-------------
#setup_tomcat6
#-------------
#install apache-tomcat6
function SETUP_TOMCAT6()
{
    if [[ -f $(pwd)/apache-tomcat-6.0.45.tar.gz ]];then
        tar zxvf $(pwd)/apache-tomcat-6.0.45.tar.gz -C /opt && mv $(pwd)/apache-tomcat-6.0.45.tar.gz /opt
        echo '/opt/apache-tomcat-6.0.45/bin/startup.sh'>>/etc/rc.local
        chmod +x /etc/rc.d/rc.local
cat>/opt/apache-tomcat-6.0.45/conf/tomcat-user.xml<<EOF
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
  <role rolename="admin"/>
  <role rolename="manager"/>
  <user username="admin" password="1" roles="admin,manager"/>
</tomcat-users>
EOF
		echo -e "\e[32m Apache-Tomcat6 has been installed,enalbe self-starting.\e[0m"
		echo -e "\e[32m WEB ACCOUNT:\n\tUSERNAME:[\e[32;1madmin\e[0m\e[32m]\n\tPASSWORD:[\e[32;1m1\e[0m\e[32m]\n\tHTTPPORT:[\e[32;1m8080\e[0m\e[32m]\e[0m"
		echo -e "\e[32m TOMCAT PATH:\n\tWEBAPPS:[\e[32;1m/opt/apache-tomcat-6.0.45/webapps\e[0m\e[32m]\n\tLOG:[\e[32;1m/opt/apache-tomcat-6.0.45/logs\e[0m\e[32m]\e[0m"
    else
        echo -e "\e[31m Please check file [\e[31;1mapache-tomcat-6.0.45.tar.gz\e[0m\e[31m].\e[0m"
    fi
	/opt/apache-tomcat-6.0.45/bin/startup.sh
#function end
}
SETUP_TOMCAT6

#====
#menu
#====
#note
function BACKUP()
{
_INPUT_=""
while true;
    do
        echo -e "menu"
        read -p "Your choice is:" _INPUT_
        case ${_IPNUT_} in
            0)
                clear
                echo -e "\e[31;1m Press 'Enter' continue.\e[0m"
                read -t 5
                ;;
            1)
                clear
                echo -e "\e[31;1m Press 'Enter' continue.\e[0m"
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
}
echo -e "\e[31m Press 'Enter' key reboot.\e[0m"
read -t 10


##########
#File end#
##########