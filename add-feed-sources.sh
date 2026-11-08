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
# 源码引用统一锁 tag（口径与 AN7581 分支同名脚本头注释一致）：不跟分支、不在 CI 里动态取最新 tag，
# 升版只用新 tag 名不复用旧名（tag 可被 force-push 重指）。v3.3.3 剥开就是原来锁的 commit 9449a52，
# scripts/feeds 的 init_commit 对 tag 和完整 SHA 走同一条 fetch+checkout，所以换写法不改一行内容。
# 换 tag 后本地要先删 feeds/lucky/ —— 带 ^ref 的 feed 在 scripts/feeds 里是"给了 ref 就不 update"。
# feed 名 lucky 不含连字符，符合上面的命名约束；ref 里的连字符不受该限制约束。
# 源码仓库的 feeds.conf.default 只保留默认 feed，第三方 feed 统一在这里追加；
# grep 判重保证重复执行不会写入第二条。
grep -q '^src-git lucky ' feeds.conf.default || \
  echo 'src-git lucky https://github.com/gdy666/luci-app-lucky.git^v3.3.3' >>feeds.conf.default
