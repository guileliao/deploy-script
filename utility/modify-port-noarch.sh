#!/bin/bash
#
# Filename: {FILENAME.SH}
# Features: {FEATURES}
# Version: {}
# Buildtime: {YYYYMMDDHHMMSS}
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
#-----------------------
#public_function_name_01
#-----------------------
#note
function FUNCTION_NAME_01()
{
    
#function end
}

#-----------------------
#public_function_name_02
#-----------------------
#note
function FUNCTION_NAME_02()
{
    
#function end
}


#=============
#role_function
#=============
#
#---------------------
#role_function_name_01
#---------------------
#note
function ROLE_FUNCTION_NAME_01()
{

#function end
}

#----------
#check_port
#----------
#check host port
function MODIFY_PORT()
{
	local _APPIP=""
	local _APPPORT=""
	local _HOSTPORT=""
	local _INPUT=""
	while true;
		do
			clear
			echo -e "\e[33m####################################\e[0m"
			echo -e "\e[34;1m 0.Append appliction port to host.\e[0m"
			echo -e "\e[34;1m 1.Delete host port as application.\e[0m"
			echo -e "\e[34;1m x.exit.\e[0m"
			echo -e "\e[33m####################################\e[0m"
			read -p "Your choice is:" _INPUT
			case ${_INPUT} in
				0)
					read -p "Please enter application ipaddress:" _APPIP
					read -p "Please enter application port:" _APPPORT
					read -p "Please enter host port:" _HOSTPORT
					if [[ $(iptables -t nat -L -n|grep "DNAT.*${_APPIP}:${_APPPORT}") != "" ]];then
						echo -e "\e[31m The port has been occupied.\e[0m"
						continue
					else
						iptables --table nat -A PREROUTING --in-interface eth0 --protocol tcp --dport ${_HOSTPORT} --jump DNAT --to-destination ${_APPIP}:${_APPPORT}
						iptables -t nat -L -n|grep "DNAT.*${_APPIP}:${_APPPORT}"
						echo -e "\e[31m Press 'Enter' key exit.\e[0m"
						read -t 10
						clear
						unset _APPIP
						unset _APPPORT
						unset _HOSTPORT
                        unset _INPUT
						break 1
					fi
					;;
				1)
					read -p "Please enter application ipaddress:" _APPIP
					read -p "Please enter application port:" _APPPORT
					read -p "Please enter host port:" _HOSTPORT
					iptables --table nat -D PREROUTING --in-interface eth0 --protocol tcp --dport ${_HOSTPORT} --jump DNAT --to-destination ${_APPIP}:${_APPPORT}
					echo -e "\e[31m The port has been deleted,Press 'Enter' key exit.\e[0m"
					read -t 5
					clear
					unset _APPIP
					unset _APPPORT
					unset _HOSTPORT
                    unset _INPUT
					break 1
					;;
				x)
					clear
					echo -e "\e[31m Press 'Enter' key exit.\e[0m"
					read -t 5
					clear
					break 1
					;;
				*)
					clear
					echo -e "\e[31m What are you doing?\n Press 'Enter' key continue.\e[0m"
					read -t 5
					clear
					continue
					;;
			esac
		done
		unset _APPIP
		unset _APPPORT
		unset _HOSTPORT
		unset _INPUT
#function end
}
MODIFY_PORT


#====
#menu
#====
#note
function MENU()
{
    local _INPUT=""
    while true;
        do
            echo -e "\e[34;1m menu\e[0m"
            read -p "Your choice is:" _INPUT
            case ${_IPNUT} in
                0)
                    clear
                    echo -e "\e[31;1m 按'Enter'键继续。\e[0m"
                    read -t 5
                    ;;
                1)
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
#funciton end
}


##########
#File end#
##########