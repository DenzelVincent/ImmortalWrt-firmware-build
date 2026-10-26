#!/bin/sh
# 阶段: ./scripts/feeds install -a 之后、make defconfig 之前
#       (工作流步骤 "Clone custom packages", cwd = openwrt/)
# 用途: clone 不是 feed 格式的第三方包 —— 仓库根目录直接放 Makefile, scripts/feeds 扫不到,
#       只能整仓 clone 进 package/。
# 位置是硬约束: 这些包的依赖里有来自 feed 的包 (如 +luci-base), 在 feeds install 之前 clone
#       会让扫描阶段依赖解析不了, make defconfig 静默跳过整个包 —— 固件里没有对应界面,
#       但编译一路不报错。AN7581 分支上的 airoha-npu 就是这么丢的 (提交 77684b6)。
# 约定: clone 目录名 = 包名; 单个包 clone 失败只打 workflow 标记、不中断整趟编译
#       (丢插件不丢固件); 末尾自检目录, 日志出现 [MISSING] 即该包不会进固件。
# 本地编译同样要在 feeds install 之后跑一遍本脚本, 否则配置里选的包会被静默丢弃。
# 当前预置: 无。lucky 已改由 feed 安装 —— gdy666/luci-app-lucky 的仓库根下是
#       lucky/ 与 luci-app-lucky/ 两个包目录, 可由 add-feed-sources.sh 追加的 lucky feed
#       直接扫描, 不再 clone。
# 以后新增非 feed 包时按此格式添加, 并同步末尾自检:
#   clone_pkg https://github.com/<owner>/<repo>.git package/<包名> warning|error

clone_pkg() {  # $1=仓库地址 $2=目标目录 $3=失败时的日志级别 warning|error
  if git clone --depth 1 "$1" "$2"; then
    echo "[OK] $2"
  else
    echo "::$3::$2 克隆失败，该插件不会进入固件"
  fi
}

echo "=== 第三方包目录检查 ==="
echo "[INFO] 当前没有需要 clone 的非 feed 第三方包"
