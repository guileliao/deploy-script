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

#---------------------
#role_function_name_02
#---------------------
#note
function ROLE_FUNCTION_NAME_02()
{

#function end
}


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