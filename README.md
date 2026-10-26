# ImmortalWrt MT7981 路由器固件编译

> 源码：[Hanwckf's ImmortalWrt](https://github.com/hanwckf/immortalwrt-mt798x)（AX3000T）｜
> [个人 ImmortalWrt Fork](https://github.com/DenzelVincent/immortalwrt/tree/24.10.6)（RAX3000M，`24.10.6`）｜
> [U-Boot](https://github.com/hanwckf/bl-mt798x)

本项目利用 GitHub Actions 编译 ImmortalWrt 固件及相应的 U-Boot。
一台设备一条工作流、一份配置文件，互不干扰（同分支上两条工作流共用 Actions 缓存命名空间，
靠缓存 key 的 `CONFIG_NAME` 前缀分隔）：

- **小米 AX3000T**（标准版 / stock 版 / AN8855 交换芯片版）
- **CMCC RAX3000M**（SPI-NAND，官方 24.10 的同一个 profile 也会产出 eMMC 引导件，收集时排除，Release 只放 SPI-NAND 四件套）

## 编译工作流

| 工作流 | 设备配置 | 说明 | 触发方式 |
|---|---|---|---|
| `build-ax3000t-immortalwrt.yml` | `ax3000t.config` | 编译小米 AX3000T 固件（配置里勾选哪些变体就出哪些） | 手动触发 (`workflow_dispatch`) |
| `build-rax3000m-immortalwrt.yml` | `rax3000m.config` | 编译 CMCC RAX3000M 固件（个人 fork `24.10.6`，`mediatek/filogic` 子目标） | 手动触发 (`workflow_dispatch`) |
| `build-mt7981-u-boot.yml` | — | 并行编译所有板型变体的 U-Boot 引导加载器 | 手动触发 (`workflow_dispatch`) |

两条固件工作流的源码仓库不同：AX3000T 用 `hanwckf/immortalwrt-mt798x` 的 `openwrt-21.02`，
RAX3000M 用 `DenzelVincent/immortalwrt` 的 `24.10.6` 分支（官方 `v24.10.6` 的个人 fork，
便于后续个性化改造；feeds 由源码自带的 `feeds.conf.default` 按提交锁定，本仓库不再覆盖）。
主线把 MT7981 归到 `mediatek/filogic` 子目标，
无线改用内核态 mt76，`kmod-mt_wifi`/`mtwifi-cfg`/`luci-app-turboacc-mtk`/`luci-app-eqos-mtk`/`mii_mgr`
这类 hanwckf 专有符号在主线不存在，所以 `rax3000m.config` 是按 24.10 重出的：删掉私有段，
改选 `luci` 集合（= `luci-light` + `luci-app-package-manager`）与 Argon 主题，
OpenClash 的 `luci-compat`/`dnsmasq-full`/`bash`/`curl`/`ruby`/`kmod-nft-tproxy` 等依赖由 feed 的 DEPENDS 自带。
换仓库最容易踩的坑是 `make defconfig` 静默跑错 target，两条工作流各自的
`EXPECT_TARGET`/`EXPECT_DEVICE` 断言会在这种情况下直接失败，而不是编出一个没有本项目软件包的固件。

## 默认配置

- **默认 LAN IP**: `10.0.0.1`
- **DHCP 地址池**: `10.0.0.100` – `10.0.0.249`（dnsmasq 出厂模板默认 `start=100` / `limit=150`，租期 12h）

## 预装插件

| 插件 | 说明 |
|---|---|
| `luci-app-openclash` | OpenClash 代理客户端（LuCI 界面，内核需首次启动后下载） |
| `luci-app-samba4` | Samba4 文件共享服务（仅 RAX3000M，`rax3000m.config` 独有） |
| `luci-app-hd-idle` | USB 硬盘自动休眠（仅 RAX3000M，`rax3000m.config` 独有） |
| `luci-app-ttyd` | 网页终端（浏览器访问路由器 Shell） |
| `luci-app-autoreboot` | 定时自动重启 |
| `luci-app-turboacc-mtk` | MTK Turbo ACC 网络加速（仅 AX3000T，hanwckf 专有） |
| `luci-app-eqos-mtk` | MTK QoS 带宽控制（仅 AX3000T，hanwckf 专有） |
| `luci-app-mtwifi-cfg` | MTK WiFi 配置（仅 AX3000T，hanwckf 专有；RAX3000M 走主线 mt76 与 LuCI 无线页） |
| `luci-app-upnp` | UPnP 自动端口映射 |
| `luci-app-lucky` | Lucky 多合一工具（端口转发、DDNS、反向代理） |
| `luci-app-smartdns` | SmartDNS 并发 DNS 解析（同时向多个上游查询、返回最快 IP，支持 DoT/DoH 加密上游；菜单「服务 → SmartDNS」）。核心和界面两条工作流各自的 feeds 里都有 —— packages 的 `net/smartdns`（C 程序，依赖 libpthread/libopenssl）和 luci 的 `luci-app-smartdns`（只带视图与 `po/`，不带 `/etc/init.d`、`/etc/config`，服务与配置只有一套），无需 clone。出厂 `enabled` 为 `0`、监听 `6053`、`redirect` 为 `dnsmasq-upstream`（挂在 dnsmasq 上游、不抢 53），需在界面里手动启用 |
| `luci-app-package-manager` | LuCI 内在线安装/升级软件包（仅 RAX3000M，由 `luci` 集合带入，`rax3000m.config` 显式写它的中文语言包） |
| `luci-theme-argon` | Argon 主题与 `luci-app-argon-config` 配置界面（AX3000T 另保留 `luci-theme-bootstrap-mod`；RAX3000M 的后备主题 bootstrap 随 `luci` 集合进入） |

> `luci-app-lucky` 走 feed 安装：`gdy666/luci-app-lucky` 的仓库根下是 `lucky/` 与
> `luci-app-lucky/` 两个包目录，可直接作为 feed 扫描。RAX3000M 的源码自带 `lucky` feed
> （固定提交 `9449a52`）；AX3000T 由 `add-feed-sources.sh` 追加同一条 feed（脚本先判断是否已存在）。
> 两支都不再 clone 到 `package/`。

## 支持的设备

### 固件 (ImmortalWrt)

| 设备 | 配置标识符 | 变体 | 固件工作流 |
|---|---|---|---|
| 小米 AX3000T | `xiaomi_mi-router-ax3000t` | 标准版、`-stock`、`-an8855`、`-an8855-stock`；配置标识符保持上游原名，收集步骤把产物名里的 `mi-router-` 段去掉，出 `xiaomi_ax3000t`（勾了 AN8855 变体再多一个 `xiaomi_ax3000t-an8855`），两变体分目录各自打包 | `build-ax3000t-immortalwrt.yml` |
| CMCC RAX3000M | `cmcc_rax3000m` | 官方 24.10 只有这一个 profile，`-emmc-preloader.bin`/`-emmc-bl31-uboot.fip`/`-emmc-gpt.bin` 虽与 SPI-NAND 引导件同批产出，但本机型用不到，收集步骤按 `*emmc*` 排除，Release 只放 sysupgrade/recovery 两个 itb 加 `-nand-preloader.bin`/`-nand-bl31-uboot.fip` | `build-rax3000m-immortalwrt.yml` |

### U-Boot

| 板型 | `BOARD` 值 | SoC |
|---|---|---|
| 小米 AX3000T | `ax3000t` | MT7981 |
| 小米 AX3000T (AN8855) | `ax3000t_an8855` | MT7981 |
| CMCC RAX3000M (SPI-NAND) | `cmcc_rax3000m` | MT7981 |
| CMCC RAX3000M (eMMC) | `cmcc_rax3000m-emmc` | MT7981 |

## 自定义编译

如需自定义固件配置，请克隆本仓库并根据需求进行修改。

主要定制入口：

| 文件 | 用途 |
|---|---|
| `ax3000t.config`、`rax3000m.config` | OpenWrt menuconfig 配置 — 一份对应一条固件工作流，各自只启用本机型设备（`ax3000t.config` 里同一机型的其它变体行注释保留，勾选哪些就出哪些镜像）。`ax3000t.config` 面向 hanwckf 21.02 的 `mediatek/mt7981`，`rax3000m.config` 面向个人 fork `24.10.6` 的 `mediatek/filogic`，两份配置的 target 符号与软件包段互不通用。工作流把选中的那份复制成 `openwrt/.config`，并无条件追加 `CONFIG_CCACHE=y`（`dl/` 与 `openwrt/.ccache` 两层缓存默认启用，触发表只留清理开关）。`Cache ...` 的 key 前缀取自工作流 env 的 `CONFIG_NAME`（与 `CONFIG_FILE` 成对定义），改设备要同步 `CONFIG_FILE`、`CONFIG_NAME`、key 里的哈希文件名、`EXPECT_TARGET`/`EXPECT_DEVICE` 四处。`Load custom config` 步骤末尾有两道断言：defconfig 结果里必须仍有 `EXPECT_TARGET`/`EXPECT_DEVICE`（拦配置文件与源码树不匹配导致的静默跑错 target），以及 `CONFIG_CCACHE=y` 仍在。`rax3000m.config` 另显式关闭 7 个 `trusted-firmware-a-mt79xx-ram-*`：上游 `include/trusted-firmware-a.mk` 对它们写了 `DEFAULT:=TARGET_mediatek_filogic`，勾了 filogic 就默认全选，各自只往 BIN_DIR 丢一个 UART 救砖 `mt79xx-ram-*-bl2.bin`，关掉可省 7 次 arm-trusted-firmware 交叉编译（真正刷机用的 `*-spim-nand-ddr4` 等隐藏变体不能关，镜像构建要用它们的 staging 产物）。勾选 `clean_dl_cache` / `clean_ccache` 时，对应的 `Clear ... cache` 步骤排在同层 `Cache ...` 步骤之前，先从 Actions 缓存存储删掉本设备前缀的条目，本趟恢复落空、全量下载/重编并收尾重存，一趟冷编译即恢复热度；删除后还有残留断言，没删净直接失败 |
| `add-feed-sources.sh` | feeds 更新**前**执行的钩子脚本 — 增删第三方软件源（改 `feeds.conf.default`）。feed 名只能用字母、数字、下划线，带连字符会让 `feeds update` 报语法错误。当前追加 `lucky` feed（`gdy666/luci-app-lucky`，固定提交；RAX3000M 源码已自带该行时跳过） |
| `clone-packages.sh` | feeds 安装**后**、`make defconfig` **前**执行的钩子脚本 — clone 非 feed 格式的第三方包到 `package/<包名>/`。位置是硬约束：这些包的依赖写着 `+luci-base` 这类 feed 包，提前 clone 会让 `make defconfig` 静默跳过整包（固件里没有对应界面，但编译不报错，见提交 `77684b6`）。当前无预置包（lucky 已改由 `lucky` feed 提供），以后新增非 feed 包仍走这里 |
| `set-firmware-defaults.sh` | `make defconfig` **后**、编译**前**执行的钩子脚本 — 用 `sed` 改源码树里会被装进 rootfs 的文件，即固件的出厂默认值（恢复出厂和 `sysupgrade -n` 后仍是这里的值）。当前把默认 LAN IP 改为 `10.0.0.1`；DHCP 地址池出厂值为 `start=100` / `limit=150`（即 `.100`–`.249`），一般不必显式配置 |
| `feeds.conf.default` | （可选）覆盖默认 feeds 软件源 |
| `files/` | （可选）预置文件目录，将文件覆盖到固件根文件系统 |

## 编译指南参考

- AX3000T（hanwckf 分支）：[hanwckf ImmortalWrt MT798x 编译说明](https://cmi.hanwckf.top/p/immortalwrt-mt798x/)
- RAX3000M（个人 fork）：源码为 [DenzelVincent/immortalwrt](https://github.com/DenzelVincent/immortalwrt/tree/24.10.6) 的 `24.10.6` 分支，
  设备定义在 `target/linux/mediatek/image/filogic.mk`（`Device/cmcc_rax3000m_common` 起）；
  U-Boot 与 preloader/fip 由源码 `package/boot/uboot-mediatek` 一起构建，产物已在固件目录里；固件工作流的整理步骤按 `*cmcc_rax3000m-*` 收本 profile 的文件并排除 `*emmc*`，最终 4 件，数量不符直接失败

## 许可证

本项目依据 Apache 2.0 许可证进行授权。有关详细信息，请参阅 [LICENSE](LICENSE) 文件。
