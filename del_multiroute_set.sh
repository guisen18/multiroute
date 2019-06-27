#!/bin/bash

intranetNIC=$(ip route|awk '/^default/{print $5}')
dgw=$(ip route |grep -v $intranetNIC|awk -F '/' 'NR == 1{print $1}'|sed 's/\.[0-9]*$/\.1/g')

NICnum=$(ip link list|grep UP|wc -l);
NICnum=$((NICnum-2));

iptables -t mangle -F

for i in $(seq 1 $NICnum)
do
    iptables -t mangle -X ETH$i
    ip route del table $((100+$i)) default via $dgw dev eth$i
done

iptables -t nat -F

for i in $(ip rule|awk -F ":" '/fwmark/{print $1}')
do
    ip rule del prio $i
done

#ip rule del `ip rule|`
#iptables -t nat -F

#ip route del table 100 default via 192.168.1.1 dev eth1
#ip route del table 101 default via 192.168.1.1 dev eth2
#ip rule del prio 32761
#ip rule del prio 32762
