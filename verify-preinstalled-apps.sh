#!/bin/sh
# 阶段: make defconfig 之后、make download 与正式编译之前
#       (工作流步骤 "Load custom config" 末尾, cwd = openwrt/, 排在 set-firmware-defaults.sh 之前)
# 用法: verify-preinstalled-apps.sh <源配置文件路径>
#       <源配置文件> 是本仓库根目录那份手工维护的 an7581.config / an7581-gpon.config, 不是 openwrt/.config ——
#       .config 是 defconfig 展开后的结果, 被丢掉的行在里面根本不存在, 只有拿"意图"对"结果"才能发现静默丢行。
# 为什么需要: feed 拉取失败、feed 行序错、包名写错时 kconfig 只静默丢行, 编译一路绿灯、
#       产出没有对应界面的固件 (2026-10-10 airoha-npu 就是这么丢的, 见 clone-packages.sh)。
#       本脚本排在 make download 之前, 失败只损失十几分钟, 不会白编几小时。
# 维护: 自检 1 的冲突表按"官方 feed 里有同名包"的第三方包逐条追加;
#       自检 2 的 app 清单从源配置自动抽, 新增 app 不用改本脚本, 只有 DEPENDS 派生的包要补进 EXTRA_REQUIRED。

if [ -z "$1" ]; then
  echo "::error::用法: $0 <源配置文件路径>"
  exit 1
fi
SRC_CONFIG=$1
[ -f "$SRC_CONFIG" ] || { echo "::error::找不到源配置文件 $SRC_CONFIG"; exit 1; }
[ -f .config ] || { echo "::error::当前目录下没有 .config, 本脚本须在 make defconfig 之后于源码根目录执行"; exit 1; }

fail=0

# ============================================================
# 自检 1: 同名包冲突 —— 查软链落点
# ============================================================
# scripts/feeds 的 install_src 对同名包只认第一个声明的 feed ($installed{$name} 真即 return 0),
# 所以第三方 feed 必须排在官方 feed 之前 (见 add-feed-sources.sh 里 mosdns 的插入方式与行序断言)。
# 装错版本不会丢行, CONFIG_PACKAGE_x=y 照样在, 自检 2 抓不到, 只能在这里查它实际链到了哪个 feed。
# 表格式: <包名>|<不应存在的路径>|<装错的后果>
while IFS='|' read -r name badpath why; do
  [ -n "$name" ] || continue
  if [ -e "$badpath" ]; then
    echo "::error::$name 装成了 $badpath —— $why"
    fail=1
  fi
done <<'CONFLICTS'
mosdns|package/feeds/packages/mosdns|immortalwrt/packages 的官方 net/mosdns 是 5.3.3, 没有 stats_api / query log / adblock_set 等二十多个补丁, LuCI 统计页与监控面板全拿不到数据, 还会和 luci-app-mosdns 自带的 /etc/init.d/mosdns 撞文件
CONFLICTS

# ============================================================
# 自检 2: 静默丢行 —— 拿源配置的意图对 .config 的结果
# ============================================================
# 2a) 源配置里所有 CONFIG_PACKAGE_luci-*=y 逐个核对 (app / 语言包 / 主题 / 库全覆盖)。
#     只扫 luci-* 不扫全部 CONFIG_PACKAGE_: 非 luci 那些含 MAC80211_DEBUGFS、TAR_BZIP2 这类
#     父包子选项, 能否留下取决于目标平台是否启用父包, 一律硬断言会误伤。
#     tr -d '\r' 是防本机 autocrlf 把 CR 带进值里 (.gitattributes 已强制 *.config eol=lf, 这里是兜底)。
# 2b) EXTRA_REQUIRED 放 DEPENDS 派生、源配置里没写但缺了界面就变死界面的包。
#     这些名字写在这里不是为了兜底选择 (它们由上游 DEPENDS 的 + 前缀自动 select),
#     而是让报错直接指向缺的那个包, 不用从"luci-app-mosdns 丢了"倒推是哪一环断的。
EXTRA_REQUIRED="mosdns geo2txt v2ray-geoip v2ray-geosite luci-lua-runtime curl"

missing=""
for p in $(tr -d '\r' < "$SRC_CONFIG" | sed -n 's/^CONFIG_PACKAGE_\(luci-[^=]*\)=y$/\1/p') $EXTRA_REQUIRED; do
  grep -q "^CONFIG_PACKAGE_$p=y" .config || missing="$missing $p"
done

if [ -n "$missing" ]; then
  echo "::error::以下包被 make defconfig 丢掉, 固件里不会有对应界面:$missing"
  echo "::error::常见原因: add-feed-sources.sh 的 feed 没拉下来 / clone-packages.sh 的包没 clone 到 / 包名与上游 Makefile 的 PKG_NAME 不一致"
  fail=1
fi

[ "$fail" -eq 0 ] && echo "[OK] 预装 app 自检通过"
exit "$fail"
