#!/bin/sh
# 阶段: ./scripts/feeds update -a 之前 (工作流步骤 "Load custom feeds", cwd = openwrt/)
# 用途: 往 feeds.conf.default 追加或放开第三方 feed 源
# 约束: feed 名只能用字母数字下划线, 带 `-` 会让 feeds update 报语法错误 (^<ref> 段里的连字符不受此限)
# 版本锁: 一律锁 tag (^<tag>), 不跟分支也不在 CI 里动态取最新 tag; 升版只用新 tag 名, 不复用旧 tag
#       换 tag 后本地先删 feeds/<name>/ —— 带 ^ref 的 feed 在 scripts/feeds 里不会再 update

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# Lucky 大吉 (lucky 核心 + luci-app-lucky 界面: IPv6 端口转发 / DDNS / 反向代理)
grep -q '^src-git lucky ' feeds.conf.default || \
  echo 'src-git lucky https://github.com/gdy666/luci-app-lucky.git^v3.3.3' >>feeds.conf.default
