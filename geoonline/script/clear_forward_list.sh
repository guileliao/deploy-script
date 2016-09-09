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
_ACLNUM_=5
#
echo -e "\e[33m Waiting for iptables clear forward list. \e[0m"
b=''
for ((i=0;${i}<=100;i+=1))
do
        printf "PROGRESS:[%-1s]%d%%\r" ${b} ${i}
        sleep 0.2
        b=#${b}
done
echo
iptables -F
iptables -t mangle -F
if [[ ${_ACLNUM_} -gt 5 ]];then
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 -d 224.0.0.0/24 -j RETURN
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 -d 255.255.255.255/32 -j RETURN
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p tcp -j MASQUERADE --to-ports 1024-65535
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -p udp -j MASQUERADE --to-ports 1024-65535
	iptables -t nat -D POSTROUTING -s 192.168.122.0/24 ! -d 192.168.122.0/24 -j MASQUERADE
fi
