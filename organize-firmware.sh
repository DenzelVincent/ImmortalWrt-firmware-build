#!/bin/sh
# 阶段: make 之后 (工作流步骤 "Organize firmware files")，cwd = 本仓库根目录
# 用途: 把编译产物按设备归集到 release/<设备名>/，并输出设备清单供 package/release job 做 matrix
# 事实来源: bin/targets/airoha/<subtarget>/profiles.json —— 只含本次实际启用的 profile，images[].name 是精确文件名
# 依据: 用精确名单而非 image_prefix 前缀匹配，否则 nokia_xg-040g-md-ubi 会把 -ubi-usb-sfp 变体的镜像一起吞进来
# 注意: device_label 是产物命名的唯一登记处，新增设备必须在此补一行，未登记即报错退出，不静默跳过
# 用法: sh organize-firmware.sh    需 env SUBTARGET；须从本仓库根目录执行

set -e

img_dir="openwrt/bin/targets/airoha/${SUBTARGET}"
profiles="$img_dir/profiles.json"

if [ ! -f "$profiles" ]; then
  echo "::error::缺少 $profiles，无法确定镜像归属哪个设备"
  exit 1
fi

# slug -> 产物名用的设备名(大写去品牌)；artifact 名、Release 标签、delete_tag_pattern 共用这套字面量
device_label() {
  case "$1" in
    nokia_xg-040g-md-ubi) echo "XG-040G-MD" ;;
    fiberhome_hg5382a)    echo "HG5382A" ;;
    *) return 1 ;;
  esac
}

rm -rf release
mkdir -p release
labels=""

# profiles.json 的键即本次启用的设备；slug 是设备标识符，不含空格，可安全按词拆分
for slug in $(jq -r '.profiles | keys[]' "$profiles"); do
  label="$(device_label "$slug")" || {
    echo "::error::未登记的设备 slug: $slug（在 organize-firmware.sh 的 device_label 里补映射）"
    exit 1
  }

  names="$(jq -r --arg s "$slug" '.profiles[$s].images[].name' "$profiles")"
  if [ -z "$names" ]; then
    echo "::error::设备 $slug 在 profiles.json 里没有 images 名单"
    exit 1
  fi

  mkdir -p "release/$label"
  count=0
  for name in $names; do
    if [ ! -f "$img_dir/$name" ]; then
      echo "::error::profiles.json 列出的镜像不存在: $img_dir/$name"
      exit 1
    fi
    cp "$img_dir/$name" "release/$label/"
    count=$((count + 1))
  done

  echo "=== $label ($slug): $count 个镜像 ==="
  labels="$labels$label
"
done

if [ -z "$labels" ]; then
  echo "::error::$profiles 里没有已启用的设备 profile，检查配置文件的 Target Devices 段"
  exit 1
fi

# 去重后转 JSON 数组，供 package/release job 的 strategy.matrix 使用
devices="$(printf '%s' "$labels" | sort -u | jq -R . | jq -sc .)"
echo "devices=$devices" >> "$GITHUB_OUTPUT"
echo "status=success" >> "$GITHUB_OUTPUT"
ls -lR release