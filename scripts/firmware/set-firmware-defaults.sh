#!/bin/sh
# 阶段: make defconfig 之后、make download 与正式编译之前 (工作流步骤 "Load custom config" 末尾, cwd = openwrt/)
# 用途: 改固件的出厂默认值 —— 改的是会被装进 rootfs 的源码文件, 恢复出厂和 sysupgrade -n 后仍是这里的值

# Modify default IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# Set DHCP IP Address start and end (dnsmasq 出厂模板已是 start=100 / limit=150, 取消注释可把地址池扩满 /24)
#sed -i "s/option start.*/option start \'2\'/g" package/network/services/dnsmasq/files/dhcp.conf
#sed -i "s/option limit.*/option limit \'253\'/g" package/network/services/dnsmasq/files/dhcp.conf
