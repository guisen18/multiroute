#!/bin/bash
set -e
set -x
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

NICnum=$(ip link list|grep UP|wc -l)
NICnum=$((NICnum-2))

#source gateway
sgw=$(ip route |grep -v via |grep $intranetNIC|awk -F '/' '{print $1}'|sed 's/\.[0-9]*$/\.1/g')
sCIDR=$(ip route |grep -v via |grep $intranetNIC|awk '/^[0-9].*\/[0-9]{1,2}/{print $1}')

#destination gateway
dgw=$(ip route |grep -v $intranetNIC|awk -F '/' 'NR == 1{print $1}'|sed 's/\.[0-9]*$/\.1/g')
dCIDR=$(ip route |grep -v $intranetNIC|awk 'NR == 1{print $1}')

if [ "$NICnum" -lt "1" ];then
        echo "the num of NIC is less than 2";
        exit 1;
fi

for i in $(seq 1 $((NICnum)))
do

        iptables -t mangle -N ETH$i

        iptables -t mangle -A ETH$i -j MARK --set-mark $i

        iptables -t mangle -A ETH$i -j CONNMARK --save-mark

        iptables -t mangle -A OUTPUT -s $sCIDR -m state --state NEW -m statistic --mode nth --every $((NICnum)) --packet $((i-1)) -j ETH$i
done

iptables -t mangle -A OUTPUT -s $sCIDR -m state --state ESTABLISHED,RELATED -j CONNMARK --restore-mark

for i in $(seq 1 $((NICnum)))
do
        hex=$(printf %x $i)

        ip rule add fwmark 0x$hex table $((100+$i))

        ip route add table $((100+$i)) default via $dgw dev ${arr[$((i-1))]}

        iptables -t nat -A POSTROUTING -s $sCIDR -o ${arr[$((i-1))]} -j MASQUERADE

        echo 0 > /proc/sys/net/ipv4/conf/${arr[$((i-1))]}/rp_filter

done

echo 0 > /proc/sys/net/ipv4/conf/default/rp_filter

echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter

echo 0 > /proc/sys/net/ipv4/conf/$intranetNIC/rp_filter




##安装php解释器
apt-get update -y
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

