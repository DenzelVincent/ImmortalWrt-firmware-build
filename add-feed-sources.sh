#!/bin/sh
# 阶段: ./scripts/feeds update -a 之前 (工作流步骤 "Load custom feeds", cwd = openwrt/)
# 用途: 往 feeds.conf.default 追加本项目需要的增量 feed 源（mosdns / lucky / airoha_npu）
# 口径: 增量包一律做成 feed 声明, 不 clone 进 package/ —— clone 进去的包归进 base 仓库, 没法单独发布
# 约束: feed 名只能用字母数字下划线, 带 `-` 会让 feeds update 报语法错误 (^<ref> 段里的连字符不受此限)
# 版本锁: 一律锁完整 commit sha (^<40位sha>), 不锁 tag、不跟分支、不在 CI 里动态取最新
#       tag 锁不住: scripts/feeds 的 init_commit = clone --depth 1 → fetch --depth=1 <ref> → checkout <ref>,
#       末步按名字检出, 只有 tag 恰好指向被克隆的那个 commit 才碰巧成功, 上游一推新提交就报 pathspec
#       sha 由 fetch 按对象取、checkout 按对象解析, 与 tip 位置无关
#       换 pin 后本地先删 feeds/<name>/ —— 带 ^ref 的 feed 在 scripts/feeds 里不会再 update

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# MosDNS 分流 DNS (mosdns 主程序 + luci-app-mosdns 界面 + geo2txt)，pin = tag v5.3.4-r15
# 必须插在 src-git packages 之前: scripts/feeds 对同名包只认第一个声明的 feed, packages 在前会装成官方那份
grep -q '^src-git mosdns ' feeds.conf.default || \
  sed -i '/^src-git packages /i src-git mosdns https://github.com/sbwml/luci-app-mosdns.git^dbdd91ab8ac8b079b6a3ca1a48d99e970d17111b' feeds.conf.default

# 断言 mosdns 行存在且排在 packages 之前 (sed 锚点没匹配上是静默不插)
mosdns_ln=$(grep -n '^src-git mosdns ' feeds.conf.default | cut -d: -f1)
packages_ln=$(grep -n '^src-git packages ' feeds.conf.default | cut -d: -f1)
if [ -z "$mosdns_ln" ] || [ -z "$packages_ln" ] || [ "$mosdns_ln" -gt "$packages_ln" ]; then
  echo "::error::feeds.conf.default 里 src-git mosdns 必须存在且排在 src-git packages 之前 (实际: mosdns=$mosdns_ln packages=$packages_ln)"
  exit 1
fi

# Lucky 大吉 (lucky 核心 + luci-app-lucky 界面: IPv6 端口转发 / DDNS / 反向代理)
# pin 取分支 tip: 作者的 v3.3.0~v3.3.3 四个附注标签全指向同一个旧 commit, 里面的包版本还是 2.27.2, tag 名与内容已脱钩
grep -q '^src-git lucky ' feeds.conf.default || \
  echo 'src-git lucky https://github.com/gdy666/luci-app-lucky.git^b07f65c28bb5fa3da1fea4b8af5ce24a1488e79a' >>feeds.conf.default

# Airoha NPU 管理界面 (自维护)，pin = tag v1.2.1: 打 tag 必须同步 bump PKG_VERSION/PKG_RELEASE, apk 只比版本号不比内容
grep -q '^src-git airoha_npu ' feeds.conf.default || \
  echo 'src-git airoha_npu https://github.com/DenzelVincent/luci-app-airoha-npu.git^b24b50a1de1a72f237c2307016b98a065976b9c6' >>feeds.conf.default

# 断言三条增量 feed 的 ^ref 都是 40 位十六进制 sha —— 手写成 tag 名或短 sha 会红在 feeds update, 在这里先拦住
bad=""
for feed in mosdns lucky airoha_npu; do
  ref=$(awk -v n="$feed" '$1 == "src-git" && $2 == n { sub(/.*\^/, "", $3); print $3 }' feeds.conf.default)
  case "$ref" in
    *[!0-9a-f]*) bad="$bad $feed=$ref" ;;
    *) [ "${#ref}" -eq 40 ] || bad="$bad $feed=$ref" ;;
  esac
done
if [ -n "$bad" ]; then
  echo "::error::^ref 必须是 40 位完整 commit sha, 不能是 tag 名或短 sha:$bad"
  exit 1
fi
