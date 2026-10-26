#!/bin/sh
# 阶段: ./scripts/feeds update -a 之前 (工作流步骤 "Load custom feeds", cwd = openwrt/)
# 用途: 往 feeds.conf.default 追加或放开第三方 feed 源
# 约束: feed 名只能用字母数字下划线 —— scripts/feeds 的解析正则里名字捕获组是 (\w+)、
#       不含连字符, 带 `-` 会在 feeds update 时报 "Syntax error in feeds.conf.default"。
# 不在这里 clone 包: 非 feed 格式的第三方包必须等 feeds install 之后才 clone,
#       否则依赖解析不到、包会被 make defconfig 静默跳过, 见 clone-packages.sh。

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> ./feeds.conf.default
# echo "src-git small https://github.com/kenzok8/small" >> ./feeds.conf.default

# Lucky 大吉 (lucky 核心 + LuCI 界面：IPv6 端口转发 / DDNS / 反向代理)
# 仓库根下是 lucky/ 与 luci-app-lucky/ 两个包目录，可直接作为 feed 扫描；
# 固定提交避免上游改动影响编译。feed 名 lucky 不含连字符，符合上面的命名约束。
# RAX3000M 的源码 (DenzelVincent/immortalwrt 24.10.6) 自带同一行，先判断再追加，避免重复 feed 名。
grep -q '^src-git lucky ' feeds.conf.default || \
  echo 'src-git lucky https://github.com/gdy666/luci-app-lucky.git^9449a5250c61f1aa8f16b2d8e04a9da25c26e735' >>feeds.conf.default
