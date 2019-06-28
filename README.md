在ecs绑定好多网卡，主网卡，多网卡分别在不同子网，关闭源/目的检查

checkproxy.sh:
检查代理是否处于开启状态中，如果异常关闭则重启。

del_multiroute.sh
删除测试时产生的多余路由设置

multiroute
多网卡路由配置模板代码（双网卡）

multiroute.sh
多网卡路由配置模板代码（N张网卡）
自动检测系统网卡，自动配置

multiroute_test*.sh
测试多网卡路由配置稳定性
