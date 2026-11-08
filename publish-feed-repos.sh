#!/bin/sh
# 阶段: 编译完成后、上传 Pages 之前 (工作流步骤 "Stage feed repositories", cwd = 本仓库根目录)
# 用途: 把各自定义 feed 已生成好的仓库 (packages.adb + *.apk) 拷成 Pages 站点目录。
# 事实来源: files/etc/apk/repositories.d/customfeeds.list —— 出厂源清单就是发布清单。
#       逐条解析 URL 里的 <arch> <feed>，两列都从清单来，不在工作流里另写一份 feed 列表，
#       省掉两处漂移；任何一条在本次编译产物里没有 packages.adb 就直接失败，
#       因为 Pages 部署是整站替换，缺一条就等于设备端那条 URL 变 404。
# 背景: 官方下载站不托管本项目 feed —— an7581.config 里已把 CONFIG_FEED_* 置 m
#       (只让默认源列表少掉死链, 不影响包编进固件)。设备端要能 apk add 这些 app, 源只能自己发。
# 签名: 索引与签名由构建系统的 index 目标完成 (apk mkndx --sign private-key.pem)，
#       私钥就是工作流 "Load repository signing key" 还原的那对, 固件 /etc/apk/keys/ 里是配套公钥,
#       所以本脚本只搬运、不重签, 设备装包也不需要 --allow-untrusted。
# 口径: 设备端只 apk add 单个包, 不跑 apk upgrade -a —— 官方源是每日 snapshot,
#       全局升级会把依赖拉到与本固件编译那天不一致的版本。kmod 类不在此列，见清单注释。
# 用法: sh publish-feed-repos.sh [源码目录]    默认 openwrt; 输出目录固定 feed-site/

set -e

src_root="${1:-openwrt}"
pkgs="$src_root/bin/packages"
site="feed-site"
list="files/etc/apk/repositories.d/customfeeds.list"

# 固件编译工作流的 "Load custom config" 步骤会把整个 files/ mv 进源码目录当出厂 overlay，
# 那时清单已经不在仓库根了；两处都找一遍，别把发布步骤绑在 mv 之前。
if [ ! -f "$list" ] && [ -f "$src_root/$list" ]; then
  list="$src_root/$list"
fi

if [ ! -d "$pkgs" ]; then
  echo "::error::$pkgs 不存在, 没有可发布的 feed 仓库"
  exit 1
fi
if [ ! -f "$list" ]; then
  echo "::error::缺少 $list, 发布清单没有事实来源"
  exit 1
fi

# URL 形如 https://<站点>/packages/<arch>/<feed>/packages.adb；以 # 开头的行不参与
rows=$(sed -n 's|^[^#]*/packages/\([^/]*\)/\([^/]*\)/packages\.adb$|\1 \2|p' "$list" | sort -u)
if [ -z "$rows" ]; then
  echo "::error::$list 里没解析出任何源地址 (期望路径段 /packages/<arch>/<feed>/packages.adb)"
  exit 1
fi

rm -rf "$site"
# IFS 只按行切, 保证 "arch feed" 这一对不被拆散, 同时循环体留在当前 shell (计数才有效)
saved_IFS=$IFS
IFS='
'
for row in $rows; do
  arch=${row%% *}
  feed=${row##* }
  dir="$pkgs/$arch/$feed"
  if [ ! -f "$dir/packages.adb" ]; then
    echo "::error::清单要求 $arch/$feed 的仓库, 但 $dir/packages.adb 不存在 (该 feed 本趟没产出包, 或架构名与清单不符)"
    exit 1
  fi
  mkdir -p "$site/packages/$arch/$feed"
  cp "$dir/packages.adb" "$dir"/*.apk "$site/packages/$arch/$feed/"
  echo "[OK] $feed ($(ls -1 "$dir"/*.apk | wc -l) 个 apk)"
done
IFS=$saved_IFS

echo "站点目录 $site 准备完毕 ($(du -sh "$site" | cut -f1)):"
ls -1 "$site"/packages/*/*/packages.adb
