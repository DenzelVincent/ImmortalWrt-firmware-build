#!/bin/sh
# 阶段: ./scripts/feeds update -a 之前 (工作流步骤 "Load custom feeds", cwd = openwrt/)
# 用途: 往 feeds.conf.default 追加或放开第三方 feed 源
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

# Lucky 大吉 (lucky 核心 + luci-app-lucky 界面: IPv6 端口转发 / DDNS / 反向代理)
# pin 取分支 tip: 作者的 v3.3.0~v3.3.3 四个附注标签全指向同一个旧 commit, 里面的包版本还是 2.27.2, tag 名与内容已脱钩
grep -q '^src-git lucky ' feeds.conf.default || \
  echo 'src-git lucky https://github.com/gdy666/luci-app-lucky.git^b07f65c28bb5fa3da1fea4b8af5ce24a1488e79a' >>feeds.conf.default

# 断言各增量 feed 的 ^ref 都是 40 位十六进制 sha —— 手写成 tag 名或短 sha 会红在 feeds update, 在这里先拦住
bad=""
for feed in lucky; do
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
