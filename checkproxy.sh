#!/bin/bash
path="/root";
#socks5代理服务是否正在运行
socks5status=`php ${path}/php-socks5/start.php status|awk 'NR==2{print $2}'`;
if [ "$socks5status" == "not" ];then
        ans=`php ${path}/php-socks5/start.php start -d|grep "[OK]"`;
        echo $ans;
        if [ "$ans" != "" ];then
                echo "php-socks5 is running";
        else
                echo “running php-socks5 not succeeded”;
        fi
fi
#检查http代理服务是否正在运行
httpstatus=`php ${path}/php-http-proxy/start.php status|awk 'NR==2{print $2}'`;
if [ "$httpstatus" == "not" ];then
        ans=`php ${path}/php-http-proxy/start.php start -d|grep "[OK]"`;
        echo $ans;
        if [ "$ans" != "" ];then
                echo "php-http-proxy is running";
        else
                echo "running php-http-proxy not succeeded";
        fi
fi
