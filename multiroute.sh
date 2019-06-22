#!/bin/bash
set -e
intranetNIC=$(ip route|awk '/^default/{print $5}')
lo="lo"
num=0

for i in $(ip link list |grep UP|awk -F ': ' '{print $2}')
do
        if [ "$i" != "$lo" ] && [ "$i" != "$intranetNIC" ];then
                echo $i
                arr[$num]=$i
                num=$((num+1))
        fi
done

NICnum=$(ip link list|grep UP|wc -l);
NICnum=$((NICnum-2));
#source gateway
sgw=192.168.1.1
sCIDR=$sgw/24
#destination gateway
dgw=192.168.100.1

if [ "$NICnum" -lt "1" ];then
        echo "the num of NIC is less than 2";
        exit 1;
fi

for i in $(seq 1 $((NICnum)))
do
        iptables -t mangle -N ETH$i

        iptables -t mangle -A ETH$i -j MARK --set-mark $((i+5))

        iptables -t mangle -A ETH$i -j CONNMARK --save-mark

        iptables -t mangle -A OUTPUT -s $sCIDR -m state --state NEW -m statistic --mode nth --every $((NICnum)) --packet $((i-1)) -j ETH$i
done

iptables -t mangle -A OUTPUT -s $sCIDR -m state --state ESTABLISHED,RELATED -j CONNMARK --restore-mark

for i in $(seq 1 $((NICnum)))
do
        ip rule add fwmark 0x$((i+5)) table 10$i

        ip route add table 10$i default via $dgw dev ${arr[$((i-1))]}

        iptables -t nat -A POSTROUTING -s $sCIDR -o ${arr[$((i-1))]} -j MASQUERADE

        echo 0 > /proc/sys/net/ipv4/conf/${arr[$((i-1))]}/rp_filter

done

echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter

echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter

echo 0 > /proc/sys/net/ipv4/conf/$intranetNIC/rp_filter

exit 0




##安装php解释器
apt install php-cli -y;
#服务安装目录
path="/root";

#检查socks5代理服务是否安装
ans=`find $path -name php-socks5`;
if [ "$ans" == "" ];then
        cd $path;
        git clone https://github.com/walkor/php-socks5;
        cd ./php-socks5;
        ans=`composer 2>&1 | grep "Composer version"|awk '{print $1}'`;
#本地没有composer服务 则进行安装
        if [ "$ans" == "" ];then
                wget https://getcomposer.org/composer.phar;
                mv composer.phar composer;
                chmod a+x composer;
                mv composer /usr/bin/composer;
                composer config -g repo.packgist composer https://packagist.phpcomposer.com;
                composer install;
        fi
fi
#检查http代理服务是否安装
ans=`find $path -name php-http-proxy`;
if [ "$ans" == "" ];then
        cd $path;
        git clone https://github.com/walkor/php-http-proxy;
fi

#启动socks5代理
ans=`php $path/php-socks5/start.php start -d|grep "[OK]"`;
if [ "$ans" != "" ];then
        echo "php-socks5 is running";
else
        killall php;
        ps aux|grep WorkerMan|awk '{print $2}'|xargs kill -9;
        php $path/php-socks5/start.php start -d;
fi

#启动http代理
ans=`php $path/php-http-proxy/start.php start -d|grep "[OK]"`;
if [ "$ans" != "" ];then
        echo "php-http-proxy is running";
else
        killall php;
        ps aux|grep WorkerMan|awk '{print $2}'|xargs kill -9;
        php $path/php-http-proxy/start.php start -d;
fi



###########################################################################################
##上面内容是多网卡路由负载自动配置，以下为iptables配置参考模板
##1.      建立ETH0隧道和ETH1隧道，报文打标签，链路跟踪下与报文保持打相同标签
#iptables -t mangle -N ETH0
#
#iptables -t mangle -A ETH0 -j MARK --set-mark 5
#
#iptables -t mangle -A ETH0 -j CONNMARK --save-mark
#
#iptables -t mangle -N ETH1
#
#iptables -t mangle -A ETH1 -j MARK --set-mark 6
#
#iptables -t mangle -A ETH1 -j CONNMARK --save-mark
#
#
#
##2.      设置源来自内网网卡的报文每2个分别进入步骤1建立的隧道
#
#iptables -t mangle -A OUTPUT -s 192.168.0.0/24 -m state --state NEW -m statistic --mode nth --every 2 --packet 0 -j ETH0
#
#iptables -t mangle -A OUTPUT -s 192.168.0.0/24 -m state --state NEW -m statistic --mode nth --every 2 --packet 1 -j ETH1
#
#
#
##3.      设置链路跟踪生效
#
#iptables -t mangle -A OUTPUT -s 192.168.0.0/24 -m state --state ESTABLISHED,RELATED -j CONNMARK --restore-mark
#
#
#
##4.      设置规则报文带标签5命中table100的路由，标签6命中table101 路由
#
#ip rule add fwmark 0x5 table 100
#
#ip rule add fwmark 0x6 table 101
#
#
#
##5.      设置路由分别从不同的网卡去网关
#
#ip route add table 100 default via 192.168.1.1 dev eth1
#
#ip route add table 101 default via 192.168.1.1 dev eth2
#
#
#
##6.      （可选）设置路由保留内网网卡内网2层通讯可用。也可以加其他内网路由规则
#
##ip route add 192.168.0.0/24 dev eth0 table 100
#
##ip route add 192.168.0.0/24 dev eth0 table 101
#
#
#
##7.      设置从内网IP到eth0/eth1 的报文分别做SNAT转对应网卡上的IP地址
#
#iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth1 -j MASQUERADE
#
#iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth2 -j MASQUERADE
#
#
#
##8.      设置虚拟机OS, IP MAC 不校验，使SNAT报文返回生效。
#
#echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter
#
#echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
#
#echo 0 > /proc/sys/net/ipv4/conf/eth0/rp_filter
#
#echo 0 > /proc/sys/net/ipv4/conf/eth1/rp_filter
#
#echo 0 > /proc/sys/net/ipv4/conf/eth2/rp_filter
#

