#!/bin/bash
#
# Filename: {FILENAME.SH}
# Features: {FEATURES}
# Version: {}
# Buildtime: {YYYYMMDDHHMMSS}
# Auteur: guile.liao
# Email: liaolei@geostar.com.cn
# Copyleft: Licensed under the GPLv3
#
#
# The warning message: color=red[31m]
# The correct message: color=green[32m]
# The information: color=yellow[33m]
# The menu: color=blue[34;1m]
# The keyword: color&highlighted[1m]
# The global variable name: _VARIABLE_NAME_
# The local variable name: _VARIABLE_NAME
# Usage variable: ${VARIABLE_NAME}
# The function name: FUNCITON_NAME()
#
#==========
#set myself
#==========
#
set -u
#set -e


#===============
#atomic_function
#===============
#
#-----------------------
#atomic_function_name_01
#-----------------------
#note
function FUNCTION_NAME_01()
{

#function end
}

#-----------------------
#atomic_function_name_02
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
#call funciton
function MENU()
{
    local _INPUT=""
    while true;
        do
            echo -e "\e[33m##############################\e[0m"
            echo -e "\e[33m System check begining......\e[0m"

            echo -e "\e[33m System check finished.\e[0m"
            echo -e "\e[33m##############################\e[0m"
            echo -e "\e[34m==============================\e[0m"
            echo -e "\e[34;1m 0.change_00\e[0m"
            echo -e "\e[34;1m 1.change_01\e[0m"
            echo -e "\e[34;1m 2.change_02\e[0m"
            echo -e "\e[34;1m x.Exit\e[0m"
            echo -e "\e[34m==============================\e[0m"
            read -p "Your choice is:" _INPUT
            case ${_IPNUT} in
                0)
                    clear
                    echo -e "\e[31;1m Press 'Enter' key exit.\e[0m"
                    read -t 5
                    ;;
                1)
                    clear
                    echo -e "\e[31;1m Press 'Enter' key exit.\e[0m"
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
#file end#
##########