#!/bin/sh
# 阶段: ./scripts/feeds update -a 之前 (工作流步骤 "Load custom feeds", cwd = openwrt/)
# 用途: 往 feeds.conf.default 追加本项目需要的增量 feed 源（mosdns / lucky / airoha_npu）
# 口径: 增量包一律做成 feed 声明, 不 clone 进 package/ —— clone 进去的包归进 base 仓库, 没法单独发布
# 约束: feed 名只能用字母数字下划线, 带 `-` 会让 feeds update 报语法错误 (^<ref> 段里的连字符不受此限)
# 版本锁: 一律锁 tag (^<tag>), 不跟分支也不在 CI 里动态取最新 tag; 升版只用新 tag 名, 不复用旧 tag
#       换 tag 后本地先删 feeds/<name>/ —— 带 ^ref 的 feed 在 scripts/feeds 里不会再 update
#       tag 名写错或忘了推 tag 不会静默: feeds update 失败即整步红

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# MosDNS 分流 DNS (mosdns 主程序 + luci-app-mosdns 界面 + geo2txt)
# 必须插在 src-git packages 之前: scripts/feeds 对同名包只认第一个声明的 feed, packages 在前会装成官方那份
grep -q '^src-git mosdns ' feeds.conf.default || \
  sed -i '/^src-git packages /i src-git mosdns https://github.com/sbwml/luci-app-mosdns.git^v5.3.4-r15' feeds.conf.default

# 断言 mosdns 行存在且排在 packages 之前 (sed 锚点没匹配上是静默不插)
mosdns_ln=$(grep -n '^src-git mosdns ' feeds.conf.default | cut -d: -f1)
packages_ln=$(grep -n '^src-git packages ' feeds.conf.default | cut -d: -f1)
if [ -z "$mosdns_ln" ] || [ -z "$packages_ln" ] || [ "$mosdns_ln" -gt "$packages_ln" ]; then
  echo "::error::feeds.conf.default 里 src-git mosdns 必须存在且排在 src-git packages 之前 (实际: mosdns=$mosdns_ln packages=$packages_ln)"
  exit 1
fi

# Lucky 大吉 (lucky 核心 + luci-app-lucky 界面: IPv6 端口转发 / DDNS / 反向代理)
grep -q '^src-git lucky ' feeds.conf.default || \
  echo 'src-git lucky https://github.com/gdy666/luci-app-lucky.git^v3.3.3' >>feeds.conf.default

# Airoha NPU 管理界面 (自维护): 打 tag 必须同步 bump PKG_VERSION/PKG_RELEASE, apk 只比版本号不比内容
grep -q '^src-git airoha_npu ' feeds.conf.default || \
  echo 'src-git airoha_npu https://github.com/DenzelVincent/luci-app-airoha-npu.git^v1.2.1' >>feeds.conf.default
