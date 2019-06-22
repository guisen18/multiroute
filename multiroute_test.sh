#!/bin/bash
#while true
#do
#httpstat ip.sb --connect-time 2 -m 1 -S
#sleep 1
#httpstat ip.sb --connect-time 2 -m 1 -S
#sleep 1
#done


while true
do
curl --connect-timeout 2 -m 1 -v ip.sb 1> /dev/null 2>> /var/log/proxytest.log
sed '/'
sed -i '/^.*Current$/d' /var/log/proxytest.log
sed -i '/^.*Speed$/d' /var/log/proxytest.log
sed -i '/^.*--:--:--.*[0-9][0-9]*$/d' /var/log/proxytest.log
sed -i 's/  0.*0//g' /var/log/proxytest.log
sleep 1
done
root@ecs-test:~# cat multiroute_test.sh
#!/bin/bash
while true
do
ping ip.sb -c 10 1> /dev/null 2>> pingout.txt;
if [ "$?" != "0" ];then
date +"%Y-%m-%d %H:%M:%S" >> pingout.txt;
fi
done

