#!/bin/sh
# 阶段: 编译完成后、上传 Pages 之前 (工作流步骤 "Stage feed repositories", cwd = 本仓库根目录)
# 用途: 把各自定义 feed 的 apk 仓库 (packages.adb + *.apk) 拷成 Pages 站点目录,
#       并与固件出厂的 customfeeds.list 逐条对账, 保证设备端每条 URL 都真有对应文件。
# 背景: 官方下载站不托管本项目 feed —— an7581.config 里已把 CONFIG_FEED_* 置 m
#       (只让默认源列表少掉死链, 不影响包编进固件)。设备端要能 apk add 这些 app, 源只能自己发。
# 签名: 索引与签名由构建系统的 index 目标完成 (apk mkndx --sign private-key.pem),
#       私钥就是工作流 "Load repository signing key" 还原的那对, 固件 /etc/apk/keys/ 里是配套公钥,
#       所以本脚本只搬运、不重签, 设备装包也不需要 --allow-untrusted。
# 口径: 设备端只 apk add 单个包, 不跑 apk upgrade -a —— 官方源是每日 snapshot,
#       全局升级会把依赖拉到与本固件编译那天不一致的版本。
# 用法: sh publish-feed-repos.sh [源码目录]    默认 openwrt; 输出目录固定 feed-site/

set -e

src_root="${1:-openwrt}"
pkgs="$src_root/bin/packages"
site="feed-site"
list="files/etc/apk/repositories.d/customfeeds.list"

if [ -z "$PUBLISH_FEEDS" ]; then
  echo "::error::未设置 PUBLISH_FEEDS (要发布哪些 feed 的仓库)"
  exit 1
fi
if [ ! -d "$pkgs" ]; then
  echo "::error::$pkgs 不存在, 没有可发布的 feed 仓库"
  exit 1
fi

# 一趟编译只有一个架构目录 (an7581 是 aarch64_cortex-a53), 反查而不写死, 换设备不用改这里
arch="$(ls -1 "$pkgs" | head -1)"
if [ -z "$arch" ] || [ ! -d "$pkgs/$arch" ]; then
  echo "::error::$pkgs 下没有架构目录"
  exit 1
fi

rm -rf "$site"
staged=0
for feed in $PUBLISH_FEEDS; do
  dir="$pkgs/$arch/$feed"
  if [ ! -f "$dir/packages.adb" ]; then
    echo "::warning::$feed 没有 packages.adb (本趟没产出该 feed 的包), 跳过"
    continue
  fi
  mkdir -p "$site/packages/$arch/$feed"
  cp "$dir/packages.adb" "$dir"/*.apk "$site/packages/$arch/$feed/"
  echo "[OK] $feed: $(ls -1 "$dir"/*.apk | wc -l) 个 apk"
  staged=1
done

if [ "$staged" != 1 ]; then
  echo "::error::PUBLISH_FEEDS ($PUBLISH_FEEDS) 里没有一个 feed 产出包, 检查配置与 feed 名"
  exit 1
fi

# 对账: 出厂 URL 里 /packages/ 之后的路径必须在站点里存在, 否则设备 apk update 就是 404
if [ -f "$list" ]; then
  for url in $(grep -o '^[^#].*/packages/.*packages\.adb$' "$list"); do
    path="packages/${url#*/packages/}"
    if [ ! -f "$site/$path" ]; then
      echo "::error::customfeeds.list 指向 $path, 但本次站点里没有 (检查架构名与 feed 名)"
      exit 1
    fi
    echo "[对账] $path"
  done
else
  echo "::warning::缺少 $list, 产出的固件不会自带这些源"
fi

echo "站点目录 $site 准备完毕 ($(du -sh "$site" | cut -f1)):"
ls -1 "$site"/packages/"$arch"/*/packages.adb
