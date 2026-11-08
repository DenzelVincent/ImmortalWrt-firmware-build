# ImmortalWrt 固件云编译

> MT7981 源码：[Hanwckf's ImmortalWrt](https://github.com/hanwckf/immortalwrt-mt798x)（AX3000T）、
> [个人 ImmortalWrt Fork](https://github.com/DenzelVincent/immortalwrt/tree/24.10.6)（RAX3000M，`24.10.6`）、
> [U-Boot](https://github.com/hanwckf/bl-mt798x)  
> AN7581 源码：[ImmortalWrt](https://github.com/DenzelVincent/ponwrt)

本项目利用 GitHub Actions 编译 ImmortalWrt 固件，支持 MT7981 和 AN758x 两大平台。

## 分支结构

| 分支 | 说明 | 配置文件 |
|---|---|---|
| `master` | 总览分支，存放所有工作流模板（不存放设备配置） | — |
| `AN7581` | AN758x 平台编译目标（AN7581 XGS-PON） | `an7581.config` |
| `MT7981` | MT7981 平台两台设备的固件 + U-Boot | `ax3000t.config`、`rax3000m.config` |

> 2026-10-15 起原 `AN7581-GPON` / `AN7583-GPON` 两个分支并入 `AN7581`；AN7583 编译目标已于 2026-10-18
> 随配置和工作流一并移除；2026-11-08 GPON 编译目标移除（真机定案本机 BOSA 为 XG-PON 专用，GPON 确认不可用，
> PonWrt 源码的 `AN7581-GPON` 分支已同步删除），现只保留一份设备配置和一份工作流。
> 新增编译目标时配置各留一份、不合并（各工作流只读自己那份配置，cache key 的 `hashFiles` 参数是字面量，
> 并一会让改一台设备连带失效另一台的缓存）。要编哪台设备，在 Actions 页面选对应工作流。

## 编译工作流

| 工作流 | 所在分支 | 说明 | 触发方式 |
|---|---|---|---|
| `build-ax3000t-immortalwrt.yml` | MT7981 / master | 编译小米 AX3000T 固件（源码 hanwckf `openwrt-21.02`；standard / stock / AN8855 变体按配置勾选） | 手动触发 (`workflow_dispatch`) |
| `build-rax3000m-immortalwrt.yml` | MT7981 / master | 编译 CMCC RAX3000M 固件（源码个人 fork `24.10.6`，`mediatek/filogic` 子目标；同一 profile 也产出 eMMC 引导件，收集时排除，Release 只放 SPI-NAND 四件） | 手动触发 (`workflow_dispatch`) |
| `build-mt7981-u-boot.yml` | MT7981 / master | 并行编译 MT7981 平台所有板型变体的 U-Boot 引导加载器 | 手动触发 (`workflow_dispatch`) |
| `build-an7581-immortalwrt.yml` | AN7581 / master | 编译 AN7581 平台光猫固件 (XGS-PON)，源码分支 `REPO_BRANCH=master`；勾选 `publish_feeds` 时顺带把自建 feed 仓库发布到本仓库 Pages | 手动触发 (`workflow_dispatch`) |
| `publish-feed-repos.yml` | AN7581 / master | 只编 AN7581 发布集里的 app 包并签名发布到 Pages，不产固件镜像；用于 app 源码更新后单独发版 | 手动触发 (`workflow_dispatch`) |

> `REPO_URL` / `REPO_BRANCH` 写死在各工作流的 `env` 段（AN758x 指向 PonWrt 源码仓库的分支，
> RAX3000M 指向个人 fork `DenzelVincent/immortalwrt` 的 `24.10.6` 分支），不由本仓库分支名推导；
> 这些副本留在 master 是因为非默认分支的工作流必须先在默认分支存在才能手动运行。
> 源码仓库只保留默认 feed，`mosdns` / `lucky` / `airoha_npu` 等增量 feed 由各分支的 `add-feed-sources.sh` 统一追加。
>
> `publish-feed-repos.yml` 与 `build-an7581-immortalwrt.yml` 用同一份 `an7581.config`，两条 cache key
> 逐字相同（共用同一份 `dl/` 与 `.ccache`），选中哪些包也由同一份配置决定；它省掉的是内核与镜像组装，
> 工具链和 `luci-base`、`lua` 这类依赖省不掉，缓存命中也要几十分钟。

## MT7981 平台默认配置

- **默认 LAN IP**: `10.0.0.1`
- **DHCP 范围**: `10.0.0.100` – `10.0.0.249`（dnsmasq 出厂模板的 `start=100` / `limit=150`；`set-firmware-defaults.sh` 里把池扩满整个 /24 的两行 `sed` 处于注释状态，无需显式配置）

## AN758x 平台默认配置

- **默认 LAN IP**: `10.0.0.1`（`AN7581` 分支 `set-firmware-defaults.sh` 里改 IP 的 `sed` 行生效，把源码默认 `192.168.1.1` 改成 `10.0.0.1`）
- **包管理器**: APK (openssl)，文件系统 SquashFS + UBIFS
- **编译内核**: Linux 6.18

## MT7981 平台预装插件

| 插件 | 说明 |
|---|---|
| `luci-app-openclash` | OpenClash 代理客户端（LuCI 界面，内核需首次启动后下载） |
| `luci-app-samba4` | Samba4 文件共享服务（仅 RAX3000M） |
| `luci-app-hd-idle` | USB 硬盘自动休眠（仅 RAX3000M） |
| `luci-app-ttyd` | 网页终端（浏览器访问路由器 Shell） |
| `luci-app-autoreboot` | 定时自动重启 |
| `luci-app-turboacc-mtk` | MTK Turbo ACC 网络加速（仅 AX3000T，hanwckf 专有） |
| `luci-app-eqos-mtk` | MTK QoS 带宽控制（仅 AX3000T，hanwckf 专有） |
| `luci-app-mtwifi-cfg` | MTK WiFi 配置（仅 AX3000T，hanwckf 专有；RAX3000M 走主线 mt76 与 LuCI 无线页） |
| `luci-app-upnp` | UPnP 自动端口映射 |
| `luci-app-lucky` | Lucky 多合一工具（端口转发、DDNS、反向代理） |
| `luci-app-smartdns` | SmartDNS 并发 DNS 解析（同时预装 `smartdns` 核心；出厂监听 6053 挂 dnsmasq 上游、`enabled` 为 `0` 需手动启用） |
| `luci-app-package-manager` | LuCI 内在线安装/升级软件包（仅 RAX3000M，由 24.10 的 `luci` 集合带入） |
| `luci-theme-argon` | Argon 主题与 `luci-app-argon-config` 配置界面（AX3000T 另保留 `luci-theme-bootstrap-mod`；RAX3000M 的后备主题 bootstrap 随 `luci` 集合进入） |

## AN758x 平台预装插件

AN7581 XGS-PON 编译目标的插件清单如下，NPU 固件包为 `airoha-en7581-npu-firmware`。

| 插件 | 说明 |
|---|---|
| `luci-app-airoha-npu` | Airoha NPU 硬件加速管理（同时预装 `airoha-en7581-npu-firmware`） |
| `luci-app-argon-config` | Argon 主题设置界面 |
| `luci-app-autoreboot` | 定时自动重启 |
| `luci-app-diskman` | 磁盘分区 / 格式化 / 挂载管理 |
| `luci-app-firewall` | 防火墙管理 |
| `luci-app-hd-idle` | USB 硬盘自动休眠 |
| `luci-app-lucky` | Lucky 多合一工具（端口转发、DDNS、反向代理） |
| `luci-app-mosdns` | MosDNS 分流 DNS（国内外域名分流、广告拦截、查询日志；同时预装 `mosdns` 核心与 `geo2txt`） |
| `luci-app-openclash` | OpenClash 代理客户端（LuCI 界面，内核需首次启动后下载） |
| `luci-app-package-manager` | 软件包管理 |
| `luci-app-pon` | PON 光猫管理（同时预装 `airoha-ponctl` / `airoha-pond` / `airoha-pon-debug`） |
| `luci-app-samba4` | Samba4 文件共享服务 |
| `luci-app-ttyd` | 网页终端（浏览器访问路由器 Shell） |
| `luci-app-upnp` | UPnP 自动端口映射 |
| `luci-theme-argon` | Argon 主题（`luci-theme-bootstrap` 一并保留） |

> 上表中 `luci-app-lucky` 由 `add-feed-sources.sh` 追加的 `lucky` feed（固定提交）提供，
> `luci-app-mosdns` 由同一脚本插入的 `mosdns` feed 提供，`luci-app-airoha-npu` 由同一脚本追加的
> `airoha_npu` feed（本仓库自维护，不锁提交）提供，随 feeds 安装就位；其余来自源码分支自带的 feeds。
> 源码仓库的 `feeds.conf.default` 不写入增量 feed。
> 增量包一律做成 feed 声明、不 clone 进 `package/`：clone 进去的包按 `include/package-dumpinfo.mk`
> 的 `Repository: $(if $(FEED),$(FEED),base)` 归进 base 仓库，与源码树自带包混在一起，既不能单独发布
> 也不能单独 `apk add`；声明成 feed 才落进 `bin/packages/<arch>/<feed>/`。声明本身也不能挪出
> `feeds.conf.default`——`scripts/feeds` 只读那两个文件，少一条 `src-git` 就是 `install -a` 不装、
> `make defconfig` 静默丢包（见提交 `77684b6`）。当 feed 用的仓库还必须是 feed 形态（包在本仓库里
> 一层子目录），否则 `include/scan.mk` 的 `find -mindepth 1` 会跳过根目录那份 Makefile，扫出 0 个包。
> 清单以各设备配置文件里的 `CONFIG_PACKAGE_luci-app-*=y` 为准，本地编译时同样要先跑
> `add-feed-sources.sh` 再 `./scripts/feeds update -a`。
>
> 每个 `luci-app-*` 都配套 `luci-i18n-<app>-zh-cn`，简体中文界面随镜像内置。
> MosDNS 出厂是**关闭**状态（监听 `5335`），不会开机就占住 53 端口，要用时在 LuCI「服务 → MosDNS」里自行启用。

> **AN7581 上这些预装 app 后续怎么升级**：官方下载站不托管本项目 feed，`an7581.config` 把它们的
> `CONFIG_FEED_*` 置 `m`，设备默认源列表 `distfeeds.list` 因此只留官方地址（`=m` 只影响源列表，
> 不影响包是否编译预装进固件）。发布到 Pages 的是 `pon_userspace` / `lucky` / `mosdns` / `airoha_npu`
> 四个 feed，仓库由 make 用固件同一把私钥签名生成，两个入口：AN7581 固件工作流勾选 `publish_feeds`
> （整镜像那趟顺带发布），或独立跑 `publish-feed-repos.yml`（只编 app 并发布、不产镜像）。
> **发布清单就是出厂的 `/etc/apk/repositories.d/customfeeds.list`**，指向本仓库 Pages，两个发布脚本
> 逐条解析它、缺一条即硬失败，工作流里不再另写一份 feed 列表。
> `pon_drivers`（那批 kmod）故意不在清单里：与本机内核 vermagic 强绑定，单包升级风险最高，驱动更新只能整镜像。
> 设备上只 `apk add` 需要的单个包，不要跑 `apk upgrade -a`（官方源是每日 snapshot，全局升级
> 会与固件编译那天的基线错配）。MT7981 平台用 opkg，上述 apk 源文件与 `publish_feeds` 均不适用。
> 完整口径见 `AN7581` 分支 README 的「设备端软件源与 app 升级」。

## 支持的设备

### MT7981 平台 - 固件 (ImmortalWrt)

| 设备 | 配置标识符 | 变体 |
|---|---|---|
| 小米 AX3000T | `xiaomi_mi-router-ax3000t` | 标准版、stock 版、AN8855 版、AN8855-stock 版；配置标识符保持上游原名，收集步骤把产物名里的 `mi-router-` 段去掉，出 `xiaomi_ax3000t`（勾了 AN8855 变体再多一个 `xiaomi_ax3000t-an8855`），两变体分目录各自打包 |
| CMCC RAX3000M | `cmcc_rax3000m` | 官方 24.10 仅此一个 profile，SPI-NAND 与 eMMC 两套 preloader/fip（含 `-emmc-gpt.bin`）同批产出，但本机型是 SPI-NAND，eMMC 三件套在收集步骤按 `*emmc*` 排除，Release 只放 sysupgrade/recovery 两个 itb 加 `-nand-preloader.bin`/`-nand-bl31-uboot.fip` |

### MT7981 平台 - U-Boot

| 板型 | `BOARD` 值 | SoC |
|---|---|---|
| 小米 AX3000T | `ax3000t` | MT7981 |
| 小米 AX3000T (AN8855) | `ax3000t_an8855` | MT7981 |
| CMCC RAX3000M (SPI-NAND) | `cmcc_rax3000m` | MT7981 |
| CMCC RAX3000M (eMMC) | `cmcc_rax3000m-emmc` | MT7981 |

### AN7581 平台 - 固件 (ImmortalWrt)

| SoC | 设备 | Profile | 原厂校准/身份数据分区 |
| --- | --- | --- | --- |
| AN7581 | FiberHome HG5382A | `fiberhome_hg5382a` | `factory` |
| AN7581 | FiberHome HG5585F CT | `fiberhome_hg5585f-ct` | `factory` |
| AN7581 | FiberHome HG5585F CU | `fiberhome_hg5585f-cu` | `factory` |
| AN7581 | Gemtek XG2010G | `gemtek_xg2010g` | `dsd` |
| AN7581 | Nokia XG-040G-MD UBI | `nokia_xg-040g-md-ubi` | `bosa`、`ri` |
| AN7581 | Nokia XG-040G-TF UBI | `nokia_xg-040g-tf-ubi` | `bosa`、`ri` |
| AN7581 | UnionMan UNG00A | `unionman_ung00a` | `reservearea` |
| AN7581 | ZNXT ZN504XG-D | `znxt_zn504xg-d` | `reservearea` |
| AN7581 | ZNXT ZN515XG-D | `znxt_zn515xg-d` | `reservearea` |
| AN7583 | Nokia XG-040G-MF | `nokia_xg-040g-mf`、`nokia_xg-040g-mf-ubi` | `bosa`、`ri` |

> 上表是 PonWrt 平台支持的完整设备清单；`AN7581` 分支当前只提供 AN7581 XGS-PON 一个编译目标
> （Nokia XG-040G-MD），不含 AN7583 编译目标，`configs/an7583.config` 仅作参考。

## 自定义编译

如需自定义固件配置，请克隆本仓库并根据需求进行修改。

主要定制入口：

| 文件 | 用途 |
|---|---|
| `an7581.config`（在 `AN7581` 分支根目录）、`ax3000t.config` / `rax3000m.config`（在 `MT7981` 分支根目录） | 按设备型号命名的 OpenWrt menuconfig 配置，master 不存放配置文件 — 定义目标设备、内核选项、软件包；`ax3000t.config` 面向 hanwckf 21.02 的 `mediatek/mt7981`，`rax3000m.config` 面向个人 fork `24.10.6` 的 `mediatek/filogic`，两份配置的 target 符号与软件包段互不通用；工作流复制成 `openwrt/.config` 并无条件追加 `CONFIG_CCACHE=y`（`dl/` 与 `.ccache` 两层缓存默认启用；三份固件编译工作流各带 `clean_dl_cache` / `clean_ccache` 两个清理开关，默认不勾）；缓存 key 的前缀取自工作流 env 的 `CONFIG_NAME`，三个值（`an7581` / `ax3000t` / `rax3000m`）两两不同，key 与恢复键都带 `-dl-` / `-ccache-` 段，同一分支上的多份工作流才不会恢复到彼此的缓存；改设备名要同步 `CONFIG_FILE`、`CONFIG_NAME` 和 key 里 `hashFiles` 的字面文件名（该参数不接受变量）；勾选清理开关时对应的 `Clear ... cache` 步骤排在同层 `Cache ...` 之前，删掉本设备前缀的条目后本趟全量下载/重编、收尾重存（一趟即恢复热度），并有删净断言，没删净直接失败；`rax3000m.config` 另显式关闭 7 个 `trusted-firmware-a-mt79xx-ram-*`（上游 `include/trusted-firmware-a.mk` 给了 `DEFAULT:=TARGET_mediatek_filogic`，勾 filogic 就默认全选，各自只往 BIN_DIR 丢一个 UART 救砖 `mt79xx-ram-*-bl2.bin`，关掉省 7 次 TFA 交叉编译；`*-spim-nand-ddr4` 等隐藏变体不能关，镜像构建要用它们的 staging 产物） |
| `add-feed-sources.sh` | feeds 更新**前**执行的钩子脚本 — 往 `feeds.conf.default` 追加本项目的增量 feed。feed 名只能用字母、数字、下划线，带连字符会让 `feeds update` 报语法错误。AN7581 分支当前插入 `mosdns` feed（`sbwml/luci-app-mosdns`，固定提交）并追加 `lucky`（`gdy666/luci-app-lucky`，固定提交）与 `airoha_npu`（`DenzelVincent/luci-app-airoha-npu`，自维护故不锁提交），均 `grep` 判重；**`mosdns` 必须用 `sed` 插到 `src-git packages` 之前而非追加** —— `immortalwrt/packages` 里也有 `net/mosdns`（5.3.3，缺 `stats_api` 等二十多个补丁），而 `scripts/feeds` 的 `install_src` 对同名包只认第一个声明的 feed，行序反了会装成官方那份、LuCI 统计页拿不到数据，脚本插完立刻断言行序。MT7981 分支只追加 `lucky`。源码仓库只保留默认 feed，增量 feed 一律在本脚本增删；也不写回源码仓库。原 `clone-packages.sh`（clone 非 feed 格式包到 `package/`）已于 2026-11-08 退役：clone 进去的包按 `include/package-dumpinfo.mk` 的 `Repository: $(if $(FEED),$(FEED),base)` 归进 base 仓库，无法单独发布或单独 `apk add`，唯一预置的 `luci-app-airoha-npu` 改造成 feed 形态（包在本仓库一层子目录）后迁到本脚本。**退役只落在 `AN7581` / master**：`MT7981` 分支仍保留 `clone-packages.sh`，两份工作流（`build-ax3000t-immortalwrt.yml` / `build-rax3000m-immortalwrt.yml`）照样在 feeds install 之后调它，只是当前预置为空、留给将来的非 feed 格式包，所以 `MT7981` 分支的表格里仍有独立一行 |
| `build-feed-packages.sh` | `make defconfig` **后**、`make package/index` **前**执行的钩子脚本（仅 `publish-feed-repos.yml`） — 从出厂 `customfeeds.list` 取 feed 名，再到 `tmp/.packagedeps` 里取这些 feed 下被 `.config` 选中的包路径，拼成 `make package/<路径>/compile` 目标；不编内核、不组装镜像，但工具链与依赖省不掉。空集合、feed 目录不存在都硬失败 |
| `set-firmware-defaults.sh` | `make defconfig` **后**、编译**前**执行的钩子脚本 — 用 `sed` 改源码树里会被装进 rootfs 的文件，即固件的出厂默认值（恢复出厂和 `sysupgrade -n` 后仍是这里的值）。AN758x 编译目标共用一份，改动对所有产出生效；MT7981 与 AN7581 两分支都把默认 LAN IP 改成 `10.0.0.1` |
| `publish-feed-repos.sh` | 编译**完成后**、上传 Pages **前**执行的钩子脚本 — 逐条解析出厂 `files/etc/apk/repositories.d/customfeeds.list` 里的 `<arch>/<feed>`，把已签名的仓库拷成 `feed-site/`；清单里任何一条本次没产出就失败（Pages 整站替换）。索引与签名由构建系统的 `index` 目标用固件同一把私钥完成，本脚本只搬运，两个发布工作流共用 |
| `feeds.conf.default` | （可选）覆盖默认 feeds 软件源 |
| `files/` | （可选）预置文件目录，将文件覆盖到固件根文件系统；`files/etc/apk/repositories.d/customfeeds.list` 同时是设备端出厂源清单与 CI 发布清单（单一事实来源） |

## 编译指南参考

- AX3000T（hanwckf 分支）与 AN758x：[hanwckf ImmortalWrt MT798x 编译说明](https://cmi.hanwckf.top/p/immortalwrt-mt798x/)
- RAX3000M（个人 fork）：源码为 [DenzelVincent/immortalwrt](https://github.com/DenzelVincent/immortalwrt/tree/24.10.6) 的 `24.10.6` 分支，
  设备定义在 `target/linux/mediatek/image/filogic.mk`，U-Boot 与 preloader/fip 由源码 `package/boot/uboot-mediatek` 一起构建；固件工作流的整理步骤按 `*cmcc_rax3000m-*` 收本 profile 的文件并排除 `*emmc*`，最终 4 件，数量不符直接失败

## 许可证

本项目依据 Apache 2.0 许可证进行授权。有关详细信息，请参阅 [LICENSE](LICENSE) 文件。
