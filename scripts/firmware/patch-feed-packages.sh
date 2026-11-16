#!/bin/sh
# 阶段: ./scripts/feeds install -a 之后、make defconfig 之前 (工作流步骤 "Install feeds" 末尾, cwd = openwrt/)
# 用途: 修 LuCI 表单"提交值等于控件默认值就当没填"这一类缺陷, 以及 mosdns ad_source 的配套声明
#
# 根因: openwrt/luci commit 974b5864e05e 往 CBIAbstractValue.parse() 的空值判据里加了 fval == this.default,
#       于是"等于默认值"和"留空"共用同一条 remove() 分支。后果两条, 得两条补丁:
#       1) 已写进 UCI 的值, 之后每次点"保存并应用"都被重新删一遍 —— remove 在 !isEqual(cval, fval) 之前, 与现值无关
#       2) mosdns 的 ad_source 声明了 o.default = 'geosite.dat', 全新刷机后不动下拉框直接保存 => 键压根不落盘
#       第 2 条才致命: init 对空 ad_source 的兜底是 /var/mosdns/disable-ads.txt, 而该文件只在 ad_source 含
#       geosite.dat 时才由 geo2txt 生成, 于是 adlist 插件 init 失败 -> 开机崩溃循环(设备实测)
#
# 分工: form.js 管第 1 条(全部 LuCI 页面共用这个 parse), rmempty=false 管第 2 条(app 自己的声明)
#       只补第 1 层仍会崩 —— 全新刷机(UCI 无键)与"选了别的源又选回默认值"两种情况 cval != fval, 照旧走 remove()
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

# ---------- 2) basic.js: ad_source 显式不 rmempty, 让默认值也真的写进 UCI ----------
[ -f "$ad_js" ] || {
  echo "::error::找不到 $ad_js（mosdns feed 的包目录结构变了？）"
  exit 1
}

anchor="o.default = 'geosite.dat';"
if grep -qF "$anchor" "$ad_js"; then
  # 幂等: 下一行已经是 rmempty 就不再插第二遍
  grep -A1 -F "$anchor" "$ad_js" | grep -qF 'o.rmempty = false;' ||
    sed -i "s@^\([[:space:]]*\)o\.default = 'geosite\.dat';@\1o.default = 'geosite.dat';\n\1o.rmempty = false;@" "$ad_js"
  # sed 只认行首空白, 上面那条 grep 判定用的是相邻行, 两者都得成立才算打上
  grep -A1 -F "$anchor" "$ad_js" | grep -qF 'o.rmempty = false;' || {
    echo "::error::$anchor 之后没跟上 o.rmempty = false;（缩进或写法与锚点不符），ad_source 仍会不落盘"
    exit 1
  }
else
  echo "::warning::basic.js 没匹配到 ad_source 的默认值行（上游可能改了写法），不动它"
fi

echo "feed 补丁完成: form.js 已限定删除条件, ad_source 已强制落盘"
