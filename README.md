# ImmortalWrt 固件云编译 (Airoha AN758x)

> 源码：[ImmortalWrt](https://github.com/DenzelVincent/ponwrt) | 基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)

本仓库用 GitHub Actions 云编译 Airoha AN758x 平台的光猫固件。三个编译目标（AN7581 XGS-PON、AN7581 GPON、AN7583 GPON）都在本分支上，各自一份工作流和一份设备配置文件，互不干扰；要编哪台就在 Actions 页面选对应的工作流。

## 免责声明

ImmortalWrt 是一个用于研究和开发的开源光猫固件项目。

刷写固件或修改 PON 相关配置存在风险，可能导致设备无法启动、配置或设备数据丢失、PON 无法注册等问题。操作前请务必备份原厂固件及设备相关数据。

使用者应自行确保相关操作符合当地法律法规及运营商相关规定。请勿将本项目用于未经授权的网络接入、冒用或复制他人设备身份，或干扰运营商网络正常运行。

因刷写、配置或使用本项目产生的设备故障、网络服务异常及其他后果，由使用者自行承担。

## 编译目标一览

三份配置和脚本共用，只有下面这几处按目标区分。要新增一个编译目标，复制一份工作流改这几个值即可。

| 工作流 | 目标设备 | 源码分支 (`REPO_BRANCH`) | 设备配置 (`CONFIG_FILE`) | 缓存前缀 (`CONFIG_NAME`) | Profile (`SUBTARGET`) |
| --- | --- | --- | --- | --- | --- |
| `build-an7581-immortalwrt.yml` | Nokia XG-040G-MD (AN7581, XGS-PON) | `master` | `an7581.config` | `an7581` | `an7581` |
| `build-an7581-gpon-immortalwrt.yml` | Nokia XG-040G-MD (AN7581, GPON) | `AN7581-GPON` | `an7581-gpon.config` | `an7581-gpon` | `an7581` |
| `build-an7583-gpon-immortalwrt.yml` | Nokia XG-040G-MF (AN7583, GPON) | `AN7583-GPON` | `an7583-gpon.config` | `an7583-gpon` | `an7583` |

> `REPO_BRANCH` 指向 PonWrt 源码仓库的分支：GPON 两个目标用的是含 GPON 内核 patch 的分支，
> XGS-PON 用的是纯净基线 `master`。源码分支写死在各自工作流的 `env` 段，不由本仓库分支名推导。
>
> `CONFIG_NAME` 是缓存 key 的前缀，三个值（外加 MT7981 那条分支的 `mt7981`）互不为前缀，
> 所以同一分支上的三份工作流不会恢复到彼此的缓存。

## 支持设备

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

三份云编译配置各自只选中一台设备（`nokia_xg-040g-md-ubi` 或 `nokia_xg-040g-mf-ubi`），上表是平台支持的完整设备清单。

## 默认配置

| 项目 | 值 |
| --- | --- |
| 管理地址 | `192.168.1.1` |
| CPU 架构 | `aarch64_cortex-a53` |
| 文件系统 | SquashFS + UBIFS |
| 包管理器 | APK (openssl) |
| 防火墙 | firewall4 + nftables (JSON) |
| DNS/DHCP | dnsmasq-full (DNSSEC、TFTP、Conntrack) |
| SSH | Dropbear |
| Web 服务 | uhttpd + LuCI (简体中文) |
| 网络加速 | BBR 拥塞控制 + CAKE 队列管理 + NFT Offload |
| VPN | WireGuard |
| 编译内核 | Linux 6.18 |

## 预装软件包

### LuCI 应用

| 软件包 | 说明 |
| --- | --- |
| `luci-app-adguardhome` | AdGuard Home DNS 过滤（同时预装 `adguardhome` 核心） |
| `luci-app-airoha-npu` | Airoha NPU 硬件加速管理 |
| `luci-app-autoreboot` | 定时重启 |
| `luci-app-firewall` | 防火墙管理 |
| `luci-app-hd-idle` | 硬盘休眠管理 |
| `luci-app-lucky` | Lucky 多合一工具（端口转发、DDNS、反向代理） |
| `luci-app-openclash` | Clash 代理管理 |
| `luci-app-package-manager` | 软件包管理 |
| `luci-app-pon` | PON 光猫管理 |
| `luci-app-samba4` | Samba 文件共享 |
| `luci-app-ttyd` | Web 终端 |
| `luci-app-upnp` | UPnP 管理 |

> 上表按三份设备配置文件里实测的 `CONFIG_PACKAGE_luci-app-*=y` 列出，三个编译目标清单一致。
> 每个 `luci-app-*` 都配套 `luci-i18n-<app>-zh-cn`（含 `luci-i18n-base-zh-cn`），简体中文界面内置；
> 主题带 `luci-theme-argon`，`luci-theme-bootstrap` 一并保留。
>
> `luci-app-lucky` 由 `add-feed-sources.sh` 追加的 `lucky` feed（固定提交）提供，随 feeds 安装自动就位；
> `luci-app-airoha-npu` 不是 feed 格式，由工作流在 `make defconfig` 之前 `git clone` 到 `package/`。
> 顺序反了 kconfig 不报错，只会静默不打包该界面；本地编译同样要先克隆再 `make defconfig`（见下面"本地编译"一节）。

### PON 平台组件

| 软件包 | 说明 |
| --- | --- |
| `airoha-ponctl` | PON 控制工具 |
| `airoha-pond` | PON 守护进程 |
| `airoha-pon-debug` | PON 调试工具 |
| `airoha-en7581-npu-firmware` | EN7581 NPU 固件（AN7583 配置里为 `airoha-an7583-npu-firmware`） |

### 内核模块

| 软件包 | 说明 |
| --- | --- |
| `kmod-wireguard` | WireGuard VPN |
| `kmod-tcp-bbr` | BBR 拥塞控制算法 |
| `kmod-sched-cake` | CAKE 队列管理 |
| `kmod-nft-offload` | NFT 硬件卸载 |
| `kmod-nft-tproxy` | NFT 透明代理 |
| `kmod-nft-bridge` | NFT 桥接 |
| `kmod-nf-flow` | 连接跟踪快路径 |
| `kmod-nf-conntrack-bridge` | 桥接连接跟踪 |
| `kmod-tun` | TUN/TAP 虚拟网络设备 |
| `kmod-mt7915e` | MediaTek MT7915 WiFi 驱动 |
| `kmod-usb3` / `kmod-usb-xhci-hcd` | USB 3.0 支持 |
| `kmod-fs-ext4` / `kmod-fs-exfat` / `kmod-fs-vfat` | 文件系统驱动 |
| `kmod-phy-airoha-en8811h` | Airoha EN8811H 2.5G PHY 驱动 |
| `kmod-phy-maxlinear` / `kmod-phy-realtek` | MaxLinear / Realtek PHY 驱动 |
| `kmod-airoha-en7572` / `kmod-airoha-xpon` / `kmod-airoha-paged-bosa` | Airoha PON 驱动 |

## 仓库结构

```
├── .github/workflows/
│   ├── build-an7581-immortalwrt.yml       # AN7581 XGS-PON 固件编译
│   ├── build-an7581-gpon-immortalwrt.yml  # AN7581 GPON 固件编译
│   └── build-an7583-gpon-immortalwrt.yml  # AN7583 GPON 固件编译
├── an7581.config                  # 云编译配置（XGS-PON 工作流的 CONFIG_FILE）
├── an7581-gpon.config             # 云编译配置（AN7581 GPON 工作流的 CONFIG_FILE）
├── an7583-gpon.config             # 云编译配置（AN7583 GPON 工作流的 CONFIG_FILE）
├── configs/                       # 从源码仓库拷来的参考配置，工作流不读取
│   ├── an7581.config              # AN7581 全设备配置（menuconfig 完整展开结果）
│   ├── an7583.config              # AN7583 全设备配置（menuconfig 完整展开结果）
│   └── release.config             # 发布配置增量
├── add-feed-sources.sh            # 插入点 1：feeds update 之前，增删第三方 feed 源
├── clone-packages.sh              # 插入点 2：feeds install 之后，clone 非 feed 格式的第三方包
└── set-firmware-defaults.sh       # 插入点 3：make defconfig 之后，改固件出厂默认值
```

> 设备配置按型号命名放在仓库根，是为了和编译期真正的 `openwrt/.config` 区分开：
> 工作流把自己那份复制成 `openwrt/.config`，再无条件追加 `CONFIG_CCACHE=y`，然后 `make defconfig` 展开。
> `configs/` 下的同名文件只是参考，不参与编译。
>
> 配置文件保留三份、不并成一份，是因为缓存 key 的哈希参数（`hashFiles`）按 GitHub 规定只能是
> 字面量；各工作流只哈希自己那份，改 AN7583 的配置不会让 AN7581 的缓存失效。
>
> 本仓库根目录**不放** `feeds.conf.default`（工作流留着 `[ -e ]` 覆盖入口，按需自建）。

## 脚本说明

三个脚本对应编译流程里的三个插入点，工作流按 `env` 段的 `SCRIPT_ADD_FEED_SOURCES` /
`SCRIPT_CLONE_PACKAGES` / `SCRIPT_SET_FIRMWARE_DEFAULTS` 三个变量调用。文件名写"做什么"，
执行阶段写在各脚本的头注释里；三份编译目标共用同一批脚本，改动对三份产出同时生效。

### `add-feed-sources.sh`

feeds 更新**前**执行，改 `feeds.conf.default`。源码仓库（PonWrt）只保留默认 feed，第三方 feed 统一在这里追加：

- 当前追加 `lucky` feed（`gdy666/luci-app-lucky`，固定提交 `9449a52`；`grep` 判重，重复执行不会写第二条）
- 其余示例（`helloworld`、PassWall、kenzok8）保持注释状态
- feed 名只能用字母数字下划线，带连字符会让 `feeds update` 报 `Syntax error in feeds.conf.default`

### `clone-packages.sh`

feeds 安装**后**、`make defconfig` **前**执行，clone 不是 feed 格式的第三方包到 `package/<包名>/`。
位置是硬约束：这些包的依赖写着 `+luci-base` 这类 feed 包，提前 clone 会让 `make defconfig`
静默跳过整包 —— 固件里没有对应界面但编译不报错（2026-10-10 踩过，见提交 `77684b6`）。
本地编译要在 `./scripts/feeds install -a` 之后手动跑一遍同样的 clone。当前预置：

- `luci-app-airoha-npu`（AN758x 平台专用，失败打 `::error::`）

`luci-app-lucky` 已改由 `add-feed-sources.sh` 追加的 `lucky` feed 提供，不再由本脚本处理。

### `set-firmware-defaults.sh`

`make defconfig` **后**、编译**前**执行，用 `sed` 改源码树里会被装进 rootfs 的文件，
即改固件的出厂默认值。恢复出厂和 `sysupgrade -n` 之后仍是这里的值。当前内容均为注释示例：

- `sed` 改默认 LAN IP 那一行现在是注释状态，三个目标都用原生 `192.168.1.1`。
  取消注释会让**三份产出的固件一起**改掉默认地址，只想改某一台时不要动这里，
  改各自工作流的 `env` 段另加变量。
- 可添加其他 `sed` 命令修改 DHCP、主机名等默认配置（DHCP 地址池出厂值是
  `start=100` / `limit=150`，即 `.100`–`.249`，一般不必显式改）

### feeds 源

本仓库不带 `feeds.conf.default`，基础 feeds 用各源码分支自带的那份。三个分支都含 `pon_drivers`（Airoha PON 硬件驱动）与 `pon_userspace`（LuCI/ponctl/pond 等用户空间工具）两个 feed，区别只在指向哪个 fork：

| 源码分支 | `pon_drivers` / `pon_userspace` 指向 |
| --- | --- |
| `master` | 上游 `pbs05/openwrt-pon-drivers`、`pbs05/openwrt-pon-userspace` |
| `AN7581-GPON` / `AN7583-GPON` | `DenzelVincent` 的 fork（含 GPON 兼容性改造） |

默认 feed 的源只改源码仓库那一处；第三方/编译期增量 feed（当前是 `lucky`）只在 `add-feed-sources.sh` 追加，不写进源码仓库，两边不要互相掺。若确需整体换源，在本仓库根目录新建 `feeds.conf.default`，工作流会 `mv` 到源码目录并计入 `dl/` 缓存 key。

## 云编译

### 编译流程

1. 释放 Runner 磁盘空间 (约 6GB)
2. 检出本仓库配置文件与脚本
3. 安装编译依赖工具链
4. 按工作流 `env.REPO_BRANCH` 克隆 ImmortalWrt 源码到 `/srcdir` (更大磁盘)
5. 缓存 `dl/` 下载目录与 `openwrt/.ccache`（默认启用；key = 工作流 env 里的 `CONFIG_NAME` + `-dl-`/`-ccache-` + 配置内容哈希；`CONFIG_NAME` 与 `CONFIG_FILE` 成对定义，清理开关见下方"触发方式"）
6. 加载 feeds 源（本仓库不带 `feeds.conf.default`，用源码分支自带的那份），执行 `add-feed-sources.sh`
7. 更新并安装 feeds
8. 执行 `clone-packages.sh` clone 非 feed 格式的第三方包（必须在 feeds install 之后，理由见"脚本说明"）
9. 加载 APK 仓库签名密钥 (可选，未配置则跳过)
10. 将工作流 `CONFIG_FILE` 指向的那份配置（已含 release 增量）复制为 `openwrt/.config`，无条件追加 `CONFIG_CCACHE=y` → `make defconfig` 展开（展开后自检这一行还在）
11. 执行 `set-firmware-defaults.sh` 修改固件出厂默认参数
12. 预下载软件包源码 (`make download`)
13. 编译固件：全并发 → 同级并发重试 → 才降级 `make -j1 V=s`（ccache 取自步骤 10 写入的 .config，命令行不带参数）
14. 收集固件镜像到 `release/<设备>/`，上传 artifact，打包 `tar.zst` 发布到 GitHub Release
15. 清理旧 workflow runs (保留 7 天 / 至少 3 条) 和旧 Release (保留最近 3 个)

### 触发方式

在 GitHub Actions 页面左侧**先选工作流**（三份对应三台设备），再点 "Run workflow"，按需勾选两个缓存清理开关：

- `clean_dl_cache` — 先清空 `dl/` 下载缓存再编译。改了某个 package 的源码版本或下载地址
  （Makefile 里的 `PKG_VERSION` / `PKG_SOURCE_VERSION` / `PKG_SOURCE_URL`）而缓存里仍是同名旧包时
  勾选；这些字段不在缓存 key 的哈希范围内，改了不会自动失效。
- `clean_ccache` — 先清空 `openwrt/.ccache` 编译对象缓存再编译。怀疑复用到了不对的产物时勾选。

两层缓存默认都是启用的：`Cache ...` 步骤没有 if，恒定恢复 + 收尾保存，`CONFIG_CCACHE=y` 由
`Load custom config` 步骤无条件写进 `.config`。勾选清理开关时，对应的 `Clear ... cache` 步骤排在
同层 `Cache ...` 步骤**之前**，先删掉本设备前缀的条目，本趟恢复必然落空 → 全量下载/重编 →
收尾把新条目存回去，一趟冷编译就把缓存重新灌满（旧写法"关掉开关"要付两趟才恢复热度）。
没勾选时行为与改造前的"开关为 true"完全一致。删完有断言检查同前缀残留，没删净就直接失败，
而不是静默用旧缓存；也可以直接去 仓库 Settings → Actions → Caches 手动删除。

定时编译：编辑对应 workflow 文件取消 `schedule` 注释 (UTC 时间)。

### 自定义配置

- 改某台设备的软件包和内核模块，改它自己那份配置（`an7581.config` / `an7581-gpon.config` / `an7583-gpon.config`）；`configs/` 下的参考配置改了不影响云编译，工作流不读它
- 改默认 IP、DHCP 等参数改 `set-firmware-defaults.sh`，注意它对三份产出生效
- 换源码分支只改对应工作流 `env` 段的 `REPO_BRANCH`，本仓库的分支名不参与推导
- 新增编译目标：复制一份工作流，改 `name:`、`REPO_BRANCH`、`CONFIG_FILE`、`CONFIG_NAME`、`DEVICE_NAME`、`SUBTARGET`，以及两处 cache key 里 `hashFiles` 的配置文件名（`CONFIG_NAME` 必须与现有各前缀互不为前缀）

## 本地编译

三个目标只是"克隆哪个源码分支 + 拷哪份配置"不同，其余步骤一致：

| 目标 | `git clone --depth 1 -b <分支>` | `cp <配置> .config` |
| --- | --- | --- |
| AN7581 XGS-PON | `master` | `an7581.config` |
| AN7581 GPON | `AN7581-GPON` | `an7581-gpon.config` |
| AN7583 GPON | `AN7583-GPON` | `an7583-gpon.config` |

```sh
# 安装编译所需的工具链和库
sudo bash -c 'bash <(curl -s https://build-scripts.immortalwrt.org/init_build_environment.sh)'

# 拉取源码（分支按上表选，这里以 AN7581 XSGPON 为例；浅克隆只取当前快照，需要完整历史/版本号时去掉 --depth 1）
git clone --depth 1 -b master https://github.com/DenzelVincent/ponwrt.git
# git clone --depth 1 -b AN7581-GPON https://github.com/DenzelVincent/ponwrt.git
# git clone --depth 1 -b AN7583-GPON https://github.com/DenzelVincent/ponwrt.git
cd ponwrt

# 追加第三方 feed (lucky 由编译仓库的 add-feed-sources.sh 统一追加，必须在 feeds update 之前执行)
sh /path/to/ImmortalWrt-firmware-build/add-feed-sources.sh

# 更新并安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 克隆第三方包 (lucky 已由上面的 feed 提供；airoha-npu 不在 feed 中，必须在 make defconfig 前完成，否则 kconfig 静默丢弃)
git clone --depth 1 https://github.com/DenzelVincent/luci-app-airoha-npu.git package/luci-app-airoha-npu

# 选择配置（按上表选对应那份）
cp an758.config .config
# cp an7581-gpon.config .config
# cp an7583-gpon.config .config

# 开始编译
make defconfig
make -j$(nproc)
```

固件位于 `bin/targets/airoha/an7581/`（AN7581 两个目标）或 `bin/targets/airoha/an7583/`（AN7583 目标）。

## 刷入

使用 [AN758x-Stock2UBI](https://github.com/pbs05/an758x-stock2ubi) 备份原厂闪存并安装 UBI 布局。启动镜像和 Web 恢复界面由 [AN758x U-Boot](https://github.com/pbs05/uboot-an758x) 提供。

刷入 ImmortalWrt 后，通过 U-Boot Web 或 LuCI 的"网络 → PON → 配置 → PON board data"恢复原厂校准和身份数据。烽火 `factory` 需要先使用 [FiberHome Factory](https://github.com/pbs05/fiberhome-factory) 转换；转换后的烽火数据、`reservearea` 和 `dsd` 写入 PonWrt 的 `factory` 卷；Nokia 的 `bosa` 和 `ri` 写入同名卷。
