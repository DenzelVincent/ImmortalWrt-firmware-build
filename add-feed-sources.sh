#!/bin/sh
# 阶段: ./scripts/feeds update -a 之前 (工作流步骤 "Load custom feeds", cwd = openwrt/)
# 用途: 往 feeds.conf.default 追加本项目需要的增量 feed 源（lucky / mosdns / airoha_npu）
# 口径: 增量包一律做成 feed 声明，不 clone 进 package/ —— clone 进去的包按 include/package-dumpinfo.mk
#       的 `Repository: $(if $(FEED),$(FEED),base)` 归进 base 仓库，跟源码树自带包混在一起，
#       没法单独发布；声明成 feed 才落进 bin/packages/<arch>/<feed>/，可单独发 Pages、可单独 apk add。
#       声明也不能挪走：scripts/feeds 只读 feeds.conf / feeds.conf.default 这两个文件，
#       少一条 src-git 就是 feeds install -a 不装、make defconfig 静默丢包（见提交 77684b6）。
# 约束: feed 名只能用字母数字下划线 —— scripts/feeds 的解析正则里名字捕获组是 (\w+)、
#       不含连字符, 带 `-` 会在 feeds update 时报 "Syntax error in feeds.conf.default"
#       (2026-10-10 的 CI 失败即此因, 不是仓库格式问题)。连字符限制只约束 feed 名，不约束 ref：
#       tag 名里的 `-`（如 v5.3.4-r15）走 ^<ref> 段，不受该正则影响。
# 版本锁: 三条 feed 一律锁 tag（^<tag>），不跟分支、也不在 CI 里动态取最新 tag ——
#       动态取等于回到 HEAD 漂移：重跑工作流拿到不同源码，已发布仓库与本次镜像对不上。
#       scripts/feeds 的 init_commit 是 `git fetch --depth=1 origin '<ref>' && git checkout '<ref>'`，
#       tag 与完整 SHA 走同一条命令，锁 tag 不比锁 commit 弱；只是 tag 能被 force-push 重指，
#       所以升版只走新 tag 名，绝不复用旧 tag（打 tag 前先推代码）。
#       换 tag 后本地要先删 feeds/<name>/ —— scripts/feeds 对带 ^ref 的 feed 是"给了 ref 就不 update"。
#       tag 名写错或忘了推 tag 不会静默：update 聚合各 feed 的返回值，失败即 exit 1，整步红。

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> ./feeds.conf.default
# echo "src-git small https://github.com/kenzok8/small" >> ./feeds.conf.default

# MosDNS (sbwml) —— 分流 DNS: mosdns 5.3.4 主程序 + luci-app-mosdns 界面 + geo2txt 地理解包工具。
# 【必须插在 src-git packages 之前】immortalwrt/packages 至今仍有 net/mosdns (5.3.3),
# 而 scripts/feeds 的 install_src 对同名包只认第一个声明的 feed ($installed{$name} 真即跳过)。
# packages 在前的后果: 装成官方那份 —— 它没有 stats_api / query log / adblock_set 等
# 二十多个补丁, luci-app-mosdns 的统计页 (/metrics) 拿不到数据,
# 而且它自带的 /etc/init.d/mosdns 与 /etc/mosdns/config.yaml 会和 luci-app-mosdns 的同名文件相撞。
# sed 的 i 命令按锚点插入, 锚点没匹配上就是静默不插, 故下面补一段行序断言。
# 锁 v5.3.4-r15，与之前锁的 commit dbdd91a 是同一提交（轻量 tag，直接指向 commit），改成 tag 不改内容。
# 上游 r15 之后 main 上没有未打 tag 的提交，按 tag 锁不落后于按分支锁。
grep -q '^src-git mosdns ' feeds.conf.default || \
  sed -i '/^src-git packages /i src-git mosdns https://github.com/sbwml/luci-app-mosdns.git^v5.3.4-r15' feeds.conf.default

# 断言 mosdns 行存在且排在 packages 之前 (grep -n 取行号比较)
mosdns_ln=$(grep -n '^src-git mosdns ' feeds.conf.default | cut -d: -f1)
packages_ln=$(grep -n '^src-git packages ' feeds.conf.default | cut -d: -f1)
if [ -z "$mosdns_ln" ] || [ -z "$packages_ln" ] || [ "$mosdns_ln" -gt "$packages_ln" ]; then
  echo "::error::feeds.conf.default 里 src-git mosdns 必须存在且排在 src-git packages 之前 (实际: mosdns=$mosdns_ln packages=$packages_ln)"
  exit 1
fi

# Lucky 大吉 (lucky 核心 + LuCI 界面：IPv6 端口转发 / DDNS / 反向代理)
# 仓库根下是 lucky/ 与 luci-app-lucky/ 两个包目录，可直接作为 feed 扫描；
# 锁 v3.3.3（annotated tag），peel 出来就是之前锁的 commit 9449a52，改成 tag 不改内容。
# 注意上游 main 上还有 5 个未打 tag 的提交（含 2026-10-29 "update v3.5.0 core"），
# 按 tag 锁就等于不要这批未 tag 的改动 —— 这是 tag 口径的代价，上游打 tag 后再升。
# feed 名 lucky 不含连字符，符合上面的命名约束。
grep -q '^src-git lucky ' feeds.conf.default || \
  echo 'src-git lucky https://github.com/gdy666/luci-app-lucky.git^v3.3.3' >>feeds.conf.default

# Airoha NPU 管理界面 (自维护) —— 同样锁 tag，不跟 main 走。
# 自维护仓库锁 tag 的代价是多两步（打 tag + 改这里的 pin），换来的是镜像里预装的那份和 Pages
# 发布的那份必然同源：跟 HEAD 时，周一编的镜像与周二发的源代码不同、版本号却相同，事后追不出装的是哪次提交。
# 配套的硬要求：app 仓库每次打 tag 都要同步 bump PKG_VERSION 或 PKG_RELEASE（luci-app-airoha-npu/Makefile），
# apk 只比版本号不比内容，版本号不动设备端 apk add 直接判定"已满足"、不会升级。
# 发版顺序：app 仓库提交 → 推 main → 打 tag → 改这里的 pin 提交 → 跑 publish-feed-repos.yml。
# 仓库形态前提：包本体在仓库里一层同名子目录 luci-app-airoha-npu/ 下（2026-11-08 改的）。
# 根上直接放 Makefile 的仓库当 feed 用，会被 include/scan.mk 的 find -mindepth 1 跳过根目录，
# 结果是 feeds update 报成功、扫出 0 个包、install -a 什么都不装，defconfig 静默丢界面。
grep -q '^src-git airoha_npu ' feeds.conf.default || \
  echo 'src-git airoha_npu https://github.com/DenzelVincent/luci-app-airoha-npu.git^v1.2.1' >>feeds.conf.default
