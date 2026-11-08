#!/bin/sh
# 阶段: make defconfig 之后、make package/index 之前 (publish-feed-repos.yml 的 "Compile feed packages" 步骤)
# 用途: 只编译发布集里各 feed 被 .config 选中的包，不编固件镜像
# 事实来源: files/etc/apk/repositories.d/customfeeds.list —— 出厂源清单即发布清单，工作流里不另写一份
# 依据: tmp/.packagedeps 第三列是相对 package/ 的目录路径，须补成 make 的 package/<路径>/compile 目标形态
# 代价: 单包 compile 会先把依赖与工具链编出来，缓存命中也要几十分钟，省掉的是内核与镜像组装
# 用法: sh build-feed-packages.sh [源码目录]    默认 openwrt；须从本仓库根目录执行（清单按相对路径解析）

set -e

src_root="${1:-openwrt}"
list_rel="files/etc/apk/repositories.d/customfeeds.list"

# 清单路径先绝对化：工作流可能已把整个 files/ mv 进源码目录当出厂 overlay，两处都找一遍
if [ ! -f "$list_rel" ] && [ -f "$src_root/$list_rel" ]; then
  list_rel="$src_root/$list_rel"
fi
if [ ! -f "$list_rel" ]; then
  echo "::error::缺少 files/etc/apk/repositories.d/customfeeds.list（应从本仓库根目录执行本脚本）"
  exit 1
fi
list="$(cd "$(dirname "$list_rel")" && pwd)/$(basename "$list_rel")"

cd "$src_root" 2>/dev/null || { echo "::error::进不了源码目录 $src_root"; exit 1; }

deps="tmp/.packagedeps"
if [ ! -f "$deps" ]; then
  echo "::error::缺少 $deps，先执行 make defconfig 再生成包列表"
  exit 1
fi

# 与 publish-feed-repos.sh 同一条 sed：把 URL 拆成 "arch feed"，# 开头的行不参与；这里只要第二列
feeds=$(sed -n 's|^[^#]*/packages/\([^/]*\)/\([^/]*\)/packages\.adb$|\1 \2|p' "$list" \
        | awk '{print $2}' | sort -u)
if [ -z "$feeds" ]; then
  echo "::error::$list 里没解析出任何 feed 名"
  exit 1
fi

targets=""
saved_IFS=$IFS
IFS='
'
for feed in $feeds; do
  # feed 目录不存在 = feeds install 没装它（仓库形态不对也会落在这里）
  if [ ! -d "package/feeds/$feed" ]; then
    echo "::error::package/feeds/$feed 不存在，feeds update/install 没产出这个 feed（检查 add-feed-sources.sh 的源与仓库形态）"
    exit 1
  fi

  # $1 形如 package-$(CONFIG_PACKAGE_xxx)，$3 起是 package/ 下的相对路径；buildonly 行不匹配
  paths=$(awk -v p="feeds/$feed/" '$1 ~ /^package-\$\(CONFIG_PACKAGE_/ {
            for (i = 3; i <= NF; i++) if (index($i, p) == 1) print "package/" $i "/compile"
          }' "$deps" | sort -u)

  if [ -z "$paths" ]; then
    echo "::error::feed $feed 里没有被选中的包，检查配置文件里的 CONFIG_PACKAGE_* 是否指向该 feed"
    exit 1
  fi

  echo "=== $feed: $(echo "$paths" | wc -l) 个包 ==="
  echo "$paths" | sed 's/^/  /'
  targets="$targets $paths"
done
IFS=$saved_IFS

echo "=== 编译 $(echo $targets | wc -w) 个包 ==="
# 与整镜像编译同款兜底：先并发，失败同级重试一次，才降级 -j1 V=s
# shellcheck disable=SC2086  # targets 是空格分隔的路径列表，必须分词
make -j"$(nproc)" $targets || make -j"$(nproc)" $targets || make -j1 V=s $targets

echo "[OK] 发布集包编译完毕，接着 make package/index 生成签名索引"
