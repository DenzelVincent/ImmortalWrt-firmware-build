#!/bin/sh
# 阶段: make defconfig 之后、make download 与正式编译之前 (工作流步骤 "Load custom config" 末尾, cwd = openwrt/)
# 用途: 改固件的出厂默认值 —— 改的是会被装进 rootfs 的源码文件, 恢复出厂和 sysupgrade -n 后仍是这里的值
# 注意: 本脚本被本分支各编译目标共用, 改动对所有产出同时生效

# Modify default IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate
