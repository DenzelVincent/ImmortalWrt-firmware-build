#!/bin/sh
# 阶段: ./scripts/feeds install -a 之后、make defconfig 之前 (工作流步骤 "Install feeds" 末尾, cwd = openwrt/)
# 用途: 修 LuCI 表单"提交值等于控件默认值就当没填"这一类缺陷, 以及 mosdns 广告源 / 概览端口行的定制
#
# 根因: openwrt/luci commit 974b5864e05e 往 CBIAbstractValue.parse() 的空值判据里加了 fval == this.default,
#       于是"等于默认值"和"留空"共用同一条 remove() 分支:
#       已写进 UCI 的值, 之后每次点"保存并应用"都被重新删一遍 —— remove 在 !isEqual(cval, fval) 之前, 与现值无关
#       Flag 的 parse 有同款无条件 remove, 但布尔开关"无键=关"是约定, 且 mosdns 里 default=enabled 的那几个
#       本来就带了 rmempty=false, 所以不动它, 免得扩大语义变更面
#
# 落点: package/feeds/<feed>/<pkg> 只是 scripts/feeds 建的软链(ln -sf ../../../feeds/...), 补丁实际写进
#       feeds/<name>/ 本体 -> 再跑一次 ./scripts/feeds update -a 就冲掉且不报错; 本地顺序固定 update -> install -> 本脚本
# 失效: 上游改掉这段后 danger 判据不再命中, 脚本打 ::warning:: 放行 —— 确认上游已修就删掉对应段落

form_js=package/feeds/luci/luci-base/htdocs/luci-static/resources/form.js
ad_js=package/feeds/mosdns/luci-app-mosdns/htdocs/luci-static/resources/view/mosdns/basic.js

# ---------- 1) form.js: 给"等于默认值"补一个"UCI 现值确实不等"的前提 ----------
[ -f "$form_js" ] || {
  echo "::error::找不到 $form_js（luci feed 的包目录结构变了？该路径由 scripts/feeds install 建软链）"
  exit 1
}

if grep -qF '(fval == this.default && (this.optional || this.rmempty))) {' "$form_js"; then
  sed -i 's@(fval == this\.default && (this\.optional || this\.rmempty)))@(fval == this.default \&\& (this.optional || this.rmempty) \&\& !isEqual(cval, fval)))@' "$form_js"
else
  echo "::warning::form.js 没匹配到待改的那行（本趟 feed 可能已含等价修复或换了写法），继续按 danger 判据验收"
fi

# danger 判据按去空白形态匹配, 与压缩后的产物一致, 设备端可用同一条串复核
# 行尾多出的第三个 ')' 把它和 Flag.parse 里那条只两层的写法区分开
if tr -d ' \t' <"$form_js" | grep -qF '(fval==this.default&&(this.optional||this.rmempty)))'; then
  echo "::error::form.js 里'等于默认值就无条件删'还在（锚点失配或上游换了写法），保存会删掉已写入的 UCI 值"
  exit 1
fi

# ---------- 2) basic.js: 去掉 ad_source 默认值 v2ray-geosite, 接入自建聚合清单 ----------
# 只删 o.default 不删选项: v2ray-geosite 留在下拉框里仍可手动选 (选中时 geo2txt 照旧产
# category-ads-all), 但新装/未改动的配置不再被隐式写成 geosite.dat
# 聚合清单: adblock-dns-aggregator 每周发布到 output 分支, mosdns/lite.txt = cn + HaGeZi Light,
# 头部 # 注释 + 纯域名, 正合 adblock_set (解析时 RemoveComment "#");
# update_adlist 按 basename(lite.txt) 落地到 /etc/mosdns/rule/adlist, 与现有源的 basename 不冲突;
# o.value 的第二参数只是下拉框/已选列表的显示别名, UCI 里存的仍是 URL
[ -f "$ad_js" ] || {
  echo "::error::找不到 $ad_js（mosdns feed 的包目录结构变了？）"
  exit 1
}

agg_url='https://raw.githubusercontent.com/DenzelVincent/adblock-dns-aggregator/output/mosdns/lite.txt'
agg_alias='adblock-dns-aggregator (lite)'
agg_tmp=$(mktemp) || {
  echo "::error::mktemp 失败，无法改写 basic.js"
  exit 1
}

# 删默认值行 (grep -vF 只认整行固定串, 不碰 o.value 选项)
grep -vF -e "o.default = 'geosite.dat';" "$ad_js" > "$agg_tmp" && cat "$agg_tmp" > "$ad_js"

# 再在 anti-AD 选项后插入聚合清单; URL 里的括号在 sed BRE 里是分组语法, 用 awk 按行内容插
if ! grep -qF "$agg_url" "$ad_js"; then
  awk -v url="$agg_url" -v alias="$agg_alias" '
    !done && index($0, "anti-ad-domains.txt") {
      print
      match($0, /^[ \t]*/)
      print substr($0, 1, RLENGTH) "o.value(\047" url "\047, \047" alias "\047);"
      done = 1
      next
    }
    { print }
  ' "$ad_js" > "$agg_tmp" && cat "$agg_tmp" > "$ad_js"
fi

rm -f "$agg_tmp"

grep -qF "o.default = 'geosite.dat';" "$ad_js" && {
  echo "::error::basic.js 里 ad_source 的默认值仍未删掉（上游改了写法？）"
  exit 1
}
grep -qF "o.value('geosite.dat', 'v2ray-geosite');" "$ad_js" || {
  echo "::error::basic.js 里 v2ray-geosite 选项丢了（本应保留）"
  exit 1
}
grep -qF "$agg_url" "$ad_js" || {
  echo "::error::basic.js 插入聚合清单选项失败（没匹配到 anti-AD 选项行？）"
  exit 1
}

# ---------- 3) 29_ports.js: 端口状态行改 flex 均分, 卡片固定 100px ----------
# 原样式是 grid auto-fit + justify-items:center: 卡片固定 100px, 靠 1fr 轨道剩余空间居中,
# 改成 flex + space-evenly 后各卡间距严格相等, 窄屏自动折行; 不写主题 .ifacebox,
# 避免外溢到「网络→接口」页的接口卡和概览「网络」区块
# 必须带 !important: Argon 主题对端口行有页面级 :has() 规则 (display:grid !important,
# 卡片 width:auto/min-width:0/margin:0 !important), 内联不加权就整段被吃掉, 卡片会被拉宽铺满
ports_js=package/feeds/luci/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js
[ -f "$ports_js" ] || {
  echo "::error::找不到 $ports_js（luci feed 的包目录结构变了？）"
  exit 1
}

old='display:grid;grid-template-columns:repeat(auto-fit, minmax(100px, 1fr));margin-bottom:1em;align-items:center;justify-items:center;text-align:center'
new='display:flex!important;flex-wrap:wrap!important;justify-content:space-evenly!important;align-items:center!important;column-gap:8px;margin-bottom:1em!important;text-align:center'
box_old='margin:.25em;width:100px'
box_new='margin:.25em!important;width:150px!important;min-width:150px!important;max-width:150px!important'

# 每次构建 feeds update -a 都会重置回上游源码, 只会遇到这一种原始形态
if grep -qF "$old" "$ports_js"; then
  sed -i "s@$old@$new@" "$ports_js"
fi

if grep -qF "$box_old" "$ports_js"; then
  sed -i "s@$box_old@$box_new@" "$ports_js"
fi

grep -qF 'justify-content:space-evenly!important' "$ports_js" || {
  echo "::error::29_ports.js 容器样式锚点失配（上游换了写法？），端口行布局未生效"
  exit 1
}
grep -qF 'width:150px!important' "$ports_js" || {
  echo "::error::29_ports.js 卡片宽度锚点失配（上游换了写法？），卡片仍会被主题拉宽"
  exit 1
}

# ---------- 4) mosdns.uc: 广告源全空时自己产兜底文件, 不依赖开机前是否存在 ----------
# geosite 默认值移除后, "启用了 adblock 但一个源都没选"变得可达: get_adlist 此刻输出为空,
# init.d 回落到 /var/mosdns/disable-ads.txt, 而该文件在 tmpfs 开机后只有 adblock=0 的分支才写,
# 于是 adblock_set 指到不存在的文件 -> 启动失败。空列表时直接写空文件并返回它, 兜底闭环
uc_uc=package/feeds/mosdns/luci-app-mosdns/root/usr/share/mosdns/mosdns.uc
[ -f "$uc_uc" ] || {
  echo "::error::找不到 $uc_uc（mosdns feed 的包目录结构变了？）"
  exit 1
}

if ! grep -qF "push(adlist, '/var/mosdns/disable-ads.txt')" "$uc_uc"; then
  grep -qF 'print(join("\n", adlist)' "$uc_uc" || {
    echo "::error::mosdns.uc 没匹配到 get_adlist 的输出行（上游可能改了写法），兜底文件未生成"
    exit 1
  }
  uc_tmp=$(mktemp) || {
    echo "::error::mktemp 失败，无法改写 mosdns.uc"
    exit 1
  }
  awk '
    !done && index($0, "print(join(\"\\n\", adlist)") {
      match($0, /^[ \t]*/)
      ind = substr($0, 1, RLENGTH)
      print ind "if (length(adlist) === 0) {"
      print ind "\twritefile(\047/var/mosdns/disable-ads.txt\047, \047\047);"
      print ind "\tpush(adlist, \047/var/mosdns/disable-ads.txt\047);"
      print ind "}"
      done = 1
    }
    { print }
  ' "$uc_uc" > "$uc_tmp" && cat "$uc_tmp" > "$uc_uc"
  rm -f "$uc_tmp"
fi

grep -qF "push(adlist, '/var/mosdns/disable-ads.txt')" "$uc_uc" || {
  echo "::error::mosdns.uc 空列表兜底未写入"
  exit 1
}

# ---------- 5) luci.upnp: 修 fw4 计数器插在 dport/dnat 之间导致状态页永远空 ----------
# fw4 打印的规则形如 "... th dport N counter packets X bytes Y dnat ip to A:P",
# 原正则要求 dport 后紧跟 dnat, match 恒失败 -> ubus call luci.upnp get_status 返回空列表,
# 页面不显示映射、也没有删除按钮; 加 .* 后捕获组编号不变 (协议/外部端口/内网地址/内网端口)
upnp_uc=package/feeds/luci/luci-app-upnp/root/usr/share/rpcd/ucode/luci.upnp
[ -f "$upnp_uc" ] || {
  echo "::error::找不到 $upnp_uc（luci feed 的包目录结构变了？）"
  exit 1
}

# 源码里是 ucode 正则的字面量 "[0-9]"，sed 没转义的 [0-9] 是字符集，永远匹配不到字面 '['，
# 所以 grep -F 用未转义串判存在，sed 用 \[0-9\] 的 BRE 写法；替换串里的 [ 是字面量，无需转义
upnp_old='th dport ([0-9]+) dnat ip to ([0-9.]+):([0-9]+)'
upnp_old_re='th dport (\[0-9\]+) dnat ip to (\[0-9.\]+):(\[0-9\]+)'
upnp_new='th dport ([0-9]+).*dnat ip to ([0-9.]+):([0-9]+)'
if grep -qF "$upnp_old" "$upnp_uc"; then
  sed -i "s@$upnp_old_re@$upnp_new@" "$upnp_uc"
fi

grep -qF "$upnp_new" "$upnp_uc" || {
  echo "::error::luci.upnp 的 dport/dnat 正则未修上（上游已改写法？），UPnP 状态页会继续为空"
  exit 1
}

echo "feed 补丁完成: form.js 已限定删除条件, v2ray-geosite 默认值已移除, 聚合清单已入下拉框, 端口行已改 flex 均分, 空广告源已有兜底, UPnP 状态页正则已兼容 fw4 计数器"
