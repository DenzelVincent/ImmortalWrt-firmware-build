# ImmortalWrt 固件云编译

> MT7981 源码：[Hanwckf's ImmortalWrt](https://github.com/hanwckf/immortalwrt-mt798x)（AX3000T）、
> [ImmortalWrt 官方仓库](https://github.com/immortalwrt/immortalwrt)（RAX3000M，`v24.10.6`）、
> [U-Boot](https://github.com/hanwckf/bl-mt798x)  
> AN7581 源码：[ImmortalWrt](https://github.com/DenzelVincent/ponwrt)

本项目利用 GitHub Actions 编译 ImmortalWrt 固件，支持 MT7981 和 AN758x 两大平台。

## 分支结构

| 分支 | 说明 | 配置文件 |
|---|---|---|
| `master` | 总览分支，存放所有工作流模板（不存放设备配置） | — |
| `AN7581` | AN758x 平台三个编译目标（XGS-PON 与 GPON）合并在同一分支 | `an7581.config`、`an7581-gpon.config`、`an7583-gpon.config` |
| `MT7981` | MT7981 平台两台设备的固件 + U-Boot | `ax3000t.config`、`rax3000m.config` |

> 2026-10-15 起原 `AN7581-GPON` / `AN7583-GPON` 两个分支并入 `AN7581`：三份设备配置和三份工作流
> 全部保留、不合并（各工作流只读自己那份配置，cache key 的 `hashFiles` 参数是字面量，并一会让
> 改一台设备连带失效另两台的缓存），只有 README 合成一份。要编哪台设备，在 Actions 页面选对应工作流。

## 编译工作流

| 工作流 | 所在分支 | 说明 | 触发方式 |
|---|---|---|---|
| `build-ax3000t-immortalwrt.yml` | MT7981 / master | 编译小米 AX3000T 固件（源码 hanwckf `openwrt-21.02`；standard / stock / AN8855 变体按配置勾选） | 手动触发 (`workflow_dispatch`) |
| `build-rax3000m-immortalwrt.yml` | MT7981 / master | 编译 CMCC RAX3000M 固件（源码官方 v24.10.6，`mediatek/filogic` 子目标；同一 profile 也产出 eMMC 引导件，收集时排除，Release 只放 SPI-NAND 四件） | 手动触发 (`workflow_dispatch`) |
| `build-mt7981-u-boot.yml` | MT7981 / master | 并行编译 MT7981 平台所有板型变体的 U-Boot 引导加载器 | 手动触发 (`workflow_dispatch`) |
| `build-an7581-immortalwrt.yml` | AN7581 / master | 编译 AN7581 平台光猫固件 (XGS-PON)，源码分支 `REPO_BRANCH=master` | 手动触发 (`workflow_dispatch`) |
| `build-an7581-gpon-immortalwrt.yml` | AN7581 / master | 编译 AN7581 平台光猫固件 (GPON)，源码分支 `REPO_BRANCH=AN7581-GPON` | 手动触发 (`workflow_dispatch`) |
| `build-an7583-gpon-immortalwrt.yml` | AN7581 / master | 编译 AN7583 平台光猫固件 (GPON)，源码分支 `REPO_BRANCH=AN7583-GPON` | 手动触发 (`workflow_dispatch`) |

> `REPO_URL` / `REPO_BRANCH` 写死在各工作流的 `env` 段（AN758x 指向 PonWrt 源码仓库的分支，
> RAX3000M 指向官方 `immortalwrt/immortalwrt` 的 `v24.10.6` 标签），不由本仓库分支名推导；
> 这些副本留在 master 是因为非默认分支的工作流必须先在默认分支存在才能手动运行。

## MT7981 平台默认配置

- **默认 LAN IP**: `10.0.0.1`
- **DHCP 范围**: `10.0.0.100` – `10.0.0.249`（dnsmasq 出厂模板的 `start=100` / `limit=150`；`set-firmware-defaults.sh` 里把池扩满整个 /24 的两行 `sed` 处于注释状态，无需显式配置）

## AN758x 平台默认配置

- **默认 LAN IP**: `192.168.1.1`（三个编译目标一致；`AN7581` 分支 `set-firmware-defaults.sh` 里改 IP 的 `sed` 行处于注释状态）
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

三个编译目标（AN7581 XGS-PON / AN7581 GPON / AN7583 GPON）的插件清单一致，仅 NPU 固件包按 SoC 区分。

| 插件 | 说明 |
|---|---|
| `luci-app-adguardhome` | AdGuard Home DNS 过滤（同时预装 `adguardhome` 核心） |
| `luci-app-airoha-npu` | Airoha NPU 硬件加速管理（AN7581 配 `airoha-en7581-npu-firmware`，AN7583 配 `airoha-an7583-npu-firmware`） |
| `luci-app-autoreboot` | 定时自动重启 |
| `luci-app-firewall` | 防火墙管理 |
| `luci-app-hd-idle` | USB 硬盘自动休眠 |
| `luci-app-lucky` | Lucky 多合一工具（端口转发、DDNS、反向代理） |
| `luci-app-openclash` | OpenClash 代理客户端（LuCI 界面，内核需首次启动后下载） |
| `luci-app-package-manager` | 软件包管理 |
| `luci-app-pon` | PON 光猫管理（同时预装 `airoha-ponctl` / `airoha-pond` / `airoha-pon-debug`） |
| `luci-app-samba4` | Samba4 文件共享服务 |
| `luci-app-ttyd` | 网页终端（浏览器访问路由器 Shell） |
| `luci-app-upnp` | UPnP 自动端口映射 |
| `luci-theme-argon` | Argon 主题（`luci-theme-bootstrap` 一并保留） |

> 除 `luci-app-airoha-npu` 外，上表都来自源码分支自带的 feeds。
> `luci-app-lucky` 来自 PonWrt 的 `lucky` feed（`feeds.conf.default` 中固定提交），随 feeds 安装自动就位；
> `luci-app-airoha-npu` 不是 feed 格式，改由 AN7581 分支的 `clone-packages.sh` 在工作流
> "Clone custom packages" 步骤（`./scripts/feeds install -a` 之后、`make defconfig` **之前**）
> `git clone` 到 `package/`——顺序反了 kconfig 不会报错，只会静默不打包该界面（见提交 `77684b6`）。
> 清单以各设备配置文件里的 `CONFIG_PACKAGE_luci-app-*=y` 为准，本地编译时同样要先克隆再 `make defconfig`。
>
> 每个 `luci-app-*` 都配套 `luci-i18n-<app>-zh-cn`，简体中文界面随镜像内置。

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

## 自定义编译

如需自定义固件配置，请克隆本仓库并根据需求进行修改。

主要定制入口：

| 文件 | 用途 |
|---|---|
| `an7581.config` / `an7581-gpon.config` / `an7583-gpon.config`（均在 `AN7581` 分支根目录）、`ax3000t.config` / `rax3000m.config`（在 `MT7981` 分支根目录） | 按设备型号命名的 OpenWrt menuconfig 配置，master 不存放配置文件 — 定义目标设备、内核选项、软件包；`ax3000t.config` 面向 hanwckf 21.02 的 `mediatek/mt7981`，`rax3000m.config` 面向官方 v24.10.6 的 `mediatek/filogic`，两份配置的 target 符号与软件包段互不通用；工作流复制成 `openwrt/.config` 并无条件追加 `CONFIG_CCACHE=y`（`dl/` 与 `.ccache` 两层缓存默认启用；五份固件编译工作流各带 `clean_dl_cache` / `clean_ccache` 两个清理开关，默认不勾）；缓存 key 的前缀取自工作流 env 的 `CONFIG_NAME`，`an7581-` / `an7581-gpon-` / `an7583-gpon-` / `ax3000t-` / `rax3000m-` 五组前缀互不为前缀，同一分支上的多份工作流才不会恢复到彼此的缓存；改设备名要同步 `CONFIG_FILE`、`CONFIG_NAME` 和 key 里 `hashFiles` 的字面文件名（该参数不接受变量）；勾选清理开关时对应的 `Clear ... cache` 步骤排在同层 `Cache ...` 之前，删掉本设备前缀的条目后本趟全量下载/重编、收尾重存（一趟即恢复热度），并有删净断言，没删净直接失败；`rax3000m.config` 另显式关闭 7 个 `trusted-firmware-a-mt79xx-ram-*`（上游 `include/trusted-firmware-a.mk` 给了 `DEFAULT:=TARGET_mediatek_filogic`，勾 filogic 就默认全选，各自只往 BIN_DIR 丢一个 UART 救砖 `mt79xx-ram-*-bl2.bin`，关掉省 7 次 TFA 交叉编译；`*-spim-nand-ddr4` 等隐藏变体不能关，镜像构建要用它们的 staging 产物） |
| `add-feed-sources.sh` | feeds 更新**前**执行的钩子脚本 — 增删第三方软件源（改 `feeds.conf.default`）。feed 名只能用字母、数字、下划线，带连字符会让 `feeds update` 报语法错误 |
| `clone-packages.sh` | feeds 安装**后**、`make defconfig` **前**执行的钩子脚本 — clone 非 feed 格式的第三方包到 `package/<包名>/`。位置是硬约束：提前 clone 时 `+luci-base` 这类 feed 依赖解析不了，`make defconfig` 会静默跳过整包（编译不报错，见提交 `77684b6`）。AN7581 分支预置 `luci-app-airoha-npu`（lucky 已由 PonWrt 的 `lucky` feed 提供），MT7981 分支预置 `luci-app-lucky` |
| `set-firmware-defaults.sh` | `make defconfig` **后**、编译**前**执行的钩子脚本 — 用 `sed` 改源码树里会被装进 rootfs 的文件，即固件的出厂默认值（恢复出厂和 `sysupgrade -n` 后仍是这里的值）。AN758x 三个编译目标共用一份，改动对三份产出同时生效；MT7981 分支把默认 LAN IP 改成 `10.0.0.1`，AN7581 分支该行保持注释 |
| `feeds.conf.default` | （可选）覆盖默认 feeds 软件源 |
| `files/` | （可选）预置文件目录，将文件覆盖到固件根文件系统 |

## 编译指南参考

- AX3000T（hanwckf 分支）与 AN758x：[hanwckf ImmortalWrt MT798x 编译说明](https://cmi.hanwckf.top/p/immortalwrt-mt798x/)
- RAX3000M（官方仓库）：源码为 [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) 的 `v24.10.6` 标签，
  设备定义在 `target/linux/mediatek/image/filogic.mk`，U-Boot 与 preloader/fip 由源码 `package/boot/uboot-mediatek` 一起构建；固件工作流的整理步骤按 `*cmcc_rax3000m-*` 收本 profile 的文件并排除 `*emmc*`，最终 4 件，数量不符直接失败

## 许可证

本项目依据 Apache 2.0 许可证进行授权。有关详细信息，请参阅 [LICENSE](LICENSE) 文件。
