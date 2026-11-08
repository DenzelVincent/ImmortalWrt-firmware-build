# ImmortalWrt 固件云编译 (Airoha AN758x)

> 源码：[ImmortalWrt](https://github.com/DenzelVincent/ponwrt) | 基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)

本仓库用 GitHub Actions 云编译 Airoha AN758x 平台的光猫固件。本分支当前只有一个编译目标（AN7581 XGS-PON），一份工作流和一份设备配置文件。

> 2026-11-08 起移除 GPON 编译目标：真机定案本机 BOSA（XG0210/EN7572AN）为 XG-PON 专用，GPON 确认不可用；
> PonWrt 源码仓库的 `AN7581-GPON` 分支与本仓库的 GPON 工作流、设备配置已一并删除。

## 免责声明

ImmortalWrt 是一个用于研究和开发的开源光猫固件项目。

刷写固件或修改 PON 相关配置存在风险，可能导致设备无法启动、配置或设备数据丢失、PON 无法注册等问题。操作前请务必备份原厂固件及设备相关数据。

使用者应自行确保相关操作符合当地法律法规及运营商相关规定。请勿将本项目用于未经授权的网络接入、冒用或复制他人设备身份，或干扰运营商网络正常运行。

因刷写、配置或使用本项目产生的设备故障、网络服务异常及其他后果，由使用者自行承担。

## 编译目标一览

配置和脚本共用，只有下面这几处按目标区分。要新增一个编译目标，复制一份工作流改这几个值即可。

| 工作流 | 目标设备 | 源码分支 (`REPO_BRANCH`) | 设备配置 (`CONFIG_FILE`) | 缓存前缀 (`CONFIG_NAME`) | Profile (`SUBTARGET`) |
| --- | --- | --- | --- | --- | --- |
| `build-an7581-immortalwrt.yml` | Nokia XG-040G-MD (AN7581, XGS-PON) | `master` | `an7581.config` | `an7581` | `an7581` |

> `REPO_BRANCH` 指向 PonWrt 源码仓库的分支（当前为 `master`）。源码分支写死在工作流的 `env` 段，不由本仓库分支名推导。
>
> `CONFIG_NAME` 是缓存 key 的前缀：key 与恢复键都形如 `CONFIG_NAME-dl-…` / `CONFIG_NAME-ccache-…`，
> 新增编译目标时各前缀必须互不相同，才不会恢复到彼此的缓存。

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

云编译配置只选中 `nokia_xg-040g-md-ubi` 这一台设备。上表是平台支持的完整设备清单：
AN7583 那行只说明 PonWrt 平台支持该设备，本分支不含 AN7583 编译目标（`configs/an7583.config` 仅作参考）。

## 默认配置

| 项目 | 值 |
| --- | --- |
| 管理地址 | `10.0.0.1` |
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
| `luci-app-airoha-npu` | Airoha NPU 硬件加速管理 |
| `luci-app-argon-config` | Argon 主题设置 |
| `luci-app-autoreboot` | 定时重启 |
| `luci-app-diskman` | 磁盘分区 / 格式化 / 挂载管理 |
| `luci-app-firewall` | 防火墙管理 |
| `luci-app-hd-idle` | 硬盘休眠管理 |
| `luci-app-lucky` | Lucky 多合一工具（端口转发、DDNS、反向代理） |
| `luci-app-mosdns` | MosDNS 分流 DNS（国内外域名分流、广告拦截、查询日志；同时预装 `mosdns` 核心与 `geo2txt`） |
| `luci-app-openclash` | Clash 代理管理 |
| `luci-app-package-manager` | 软件包管理 |
| `luci-app-pon` | PON 光猫管理 |
| `luci-app-samba4` | Samba 文件共享 |
| `luci-app-ttyd` | Web 终端 |
| `luci-app-upnp` | UPnP 管理 |

> 上表按设备配置文件里实测的 `CONFIG_PACKAGE_luci-app-*=y` 列出。
> 每个 `luci-app-*` 都配套 `luci-i18n-<app>-zh-cn`（含 `luci-i18n-base-zh-cn`），简体中文界面内置。
> 主题带 `luci-theme-argon`，`luci-theme-bootstrap` 一并保留。
>
> `luci-app-lucky` 由 `add-feed-sources.sh` 追加的 `lucky` feed（固定提交）提供，随 feeds 安装自动就位；
> `luci-app-mosdns` 由同一脚本插入的 `mosdns` feed 提供，
> 其中 `mosdns` feed 有行序硬约束（必须排在 `src-git packages` 之前，理由见脚本注释）；
> `luci-app-airoha-npu` 不是 feed 格式，由工作流在 `make defconfig` 之前 `git clone` 到 `package/`。
> 顺序反了 kconfig 不报错，只会静默不打包该界面；本地编译同样要先克隆再 `make defconfig`（见下面"本地编译"一节）。
>
> MosDNS 出厂是**关闭**状态（`/etc/config/mosdns` 里 `enabled '0'`、监听 `5335`），不会开机就占住 53 端口；
> 要用时在 LuCI「服务 → MosDNS」里自行启用，统计页读的是 mosdns 的 API 端口，默认 `9091`，开箱即用。
>
> 这些 app 的 feed 官方站不托管，默认源列表里已注释掉；设备端手工升级见「设备端软件源与 app 升级」一节。

### PON 平台组件

| 软件包 | 说明 |
| --- | --- |
| `airoha-ponctl` | PON 控制工具 |
| `airoha-pond` | PON 守护进程 |
| `airoha-pon-debug` | PON 调试工具 |
| `airoha-en7581-npu-firmware` | EN7581 NPU 固件 |

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
│   └── build-an7581-immortalwrt.yml       # AN7581 XGS-PON 固件编译
├── an7581.config                  # 云编译配置（工作流的 CONFIG_FILE）
├── configs/                       # 从源码仓库拷来的参考配置，工作流不读取
│   ├── an7581.config              # AN7581 全设备配置（menuconfig 完整展开结果）
│   ├── an7583.config              # AN7583 全设备配置（menuconfig 完整展开结果，本分支无对应编译目标）
│   └── release.config             # 发布配置增量
├── add-feed-sources.sh            # 插入点 1：feeds update 之前，增删第三方 feed 源
├── clone-packages.sh              # 插入点 2：feeds install 之后，clone 非 feed 格式的第三方包
├── set-firmware-defaults.sh       # 插入点 3：make defconfig 之后，改固件出厂默认值
├── publish-feed-repos.sh          # 插入点 4：编译完成之后，把各 feed 的已签名仓库拷成 Pages 站点
└── files/                         # 固件出厂预置文件，工作流整目录 mv 进 openwrt/，rootfs 生成时覆盖同名文件
    └── etc/apk/repositories.d/customfeeds.list   # 设备端自建源清单，指向本仓库 Pages
```

> 设备配置按型号命名放在仓库根，是为了和编译期真正的 `openwrt/.config` 区分开：
> 工作流把自己那份复制成 `openwrt/.config`，再无条件追加 `CONFIG_CCACHE=y`，然后 `make defconfig` 展开。
> `configs/` 下的同名文件只是参考，不参与编译。
>
> 新增编译目标时配置文件各留一份、不并成一份，是因为缓存 key 的哈希参数（`hashFiles`）按 GitHub 规定只能是
> 字面量；各工作流只哈希自己那份，改一台设备的配置不会让另一台的缓存失效。
>
> 本仓库根目录**不放** `feeds.conf.default`（工作流留着 `[ -e ]` 覆盖入口，按需自建）。
> `files/` 同理是留着入口后新增的：只放需要随固件出厂的文件，别往里塞编译期脚本。

## 脚本说明

四个脚本对应编译流程里的四个插入点，工作流按 `env` 段的 `SCRIPT_ADD_FEED_SOURCES` /
`SCRIPT_CLONE_PACKAGES` / `SCRIPT_SET_FIRMWARE_DEFAULTS` / `SCRIPT_PUBLISH_FEED_REPOS`
四个变量调用。文件名写"做什么"，执行阶段写在各脚本的头注释里；各编译目标共用同一批脚本，改动对所有产出生效。

### `add-feed-sources.sh`

feeds 更新**前**执行，改 `feeds.conf.default`。源码仓库（PonWrt）只保留默认 feed，第三方 feed 统一在这里增删：

- `mosdns` feed（`sbwml/luci-app-mosdns`，固定提交 `dbdd91a`）用 `sed` **插到 `src-git packages` 之前**，不是追加：
  `immortalwrt/packages` 里也有一个 `net/mosdns`（5.3.3），而 `scripts/feeds` 的 `install_src` 对同名包只认第一个声明的 feed。
  行序反了会装成官方那份 —— 缺 `stats_api` / query log / `adblock_set` 等二十多个补丁，LuCI 统计页拿不到数据，
  还会和 `luci-app-mosdns` 自带的 `/etc/init.d/mosdns` 撞文件。脚本插完立刻断言行序
- `lucky` feed（`gdy666/luci-app-lucky`，固定提交 `9449a52`）追加到末尾
- 两条都用 `grep` 判重，重复执行不会写出第二条
- 其余示例（`helloworld`、PassWall、kenzok8）保持注释状态
- feed 名只能用字母数字下划线，带连字符会让 `feeds update` 报 `Syntax error in feeds.conf.default`

### `clone-packages.sh`

feeds 安装**后**、`make defconfig` **前**执行，clone 不是 feed 格式的第三方包到 `package/<包名>/`。
位置是硬约束：这些包的依赖写着 `+luci-base` 这类 feed 包，提前 clone 会让 `make defconfig`
静默跳过整包 —— 固件里没有对应界面但编译不报错（2026-10-10 踩过，见提交 `77684b6`）。
本地编译要在 `./scripts/feeds install -a` 之后手动跑一遍同样的 clone。当前预置：

- `luci-app-airoha-npu`（AN758x 平台专用，失败打 `::error::`）

`luci-app-lucky`、`luci-app-mosdns` 都由 `add-feed-sources.sh` 处理的 feed 提供，不走本脚本。

### `set-firmware-defaults.sh`

`make defconfig` **后**、编译**前**执行，用 `sed` 改源码树里会被装进 rootfs 的文件，
即改固件的出厂默认值。恢复出厂和 `sysupgrade -n` 之后仍是这里的值。当前生效的改动：

- `sed` 改默认 LAN IP 那一行当前**生效**：把源码原生 `192.168.1.1` 改成 `10.0.0.1`。
  改动会让**所有产出的固件一起**改掉默认地址，只想改某一台时不要动这里，
  改各自工作流的 `env` 段另加变量；要恢复原生默认就注释掉该行。
- 可添加其他 `sed` 命令修改 DHCP、主机名等默认配置（DHCP 地址池出厂值是
  `start=100` / `limit=150`，即 `.100`–`.249`，一般不必显式改）

### `publish-feed-repos.sh`

编译**完成后**、上传 Pages **前**执行，把各自定义 feed 已经生成好的仓库（`packages.adb` + `*.apk`）
拷成站点目录 `feed-site/packages/<arch>/<feed>/`。要点：

- 索引和签名不是本脚本做的：构建系统的 `index` 目标对每个 feed 目录跑过
  `apk mkndx --sign private-key.pem`，私钥就是步骤 9 还原的那对，固件 `/etc/apk/keys/` 里是配套公钥，
  所以设备装这里的包**不需要** `--allow-untrusted`。本脚本只搬运，不重签。
- 架构目录从 `openwrt/bin/packages/` 反查，不写死 `aarch64_cortex-a53`，换设备不用改脚本。
- 拷完逐条核对 `files/etc/apk/repositories.d/customfeeds.list` 里的 URL：`/packages/` 之后的路径
  本次站点里必须真有对应文件，缺就在编译 job 里 `::error::` 失败——避免发出去一个装不上任何东西的站点。
- 要发布哪些 feed 由工作流 `env.PUBLISH_FEEDS` 决定，它和出厂清单是一体两面，改一处要同步另一处。

## 设备端软件源与 app 升级

三个事实决定了这套口径，改配置前先对齐：

1. **官方下载站不托管本项目 feed**。`%U` 在编译期展开成 `CONFIG_VERSION_REPO`
   （默认 `https://downloads.immortalwrt.org/snapshots`），所有 feed 共用这一个基地址，
   于是 `pon_drivers` / `pon_userspace` / `lucky` / `mosdns` / `video` 的仓库地址必然 404。
2. **`CONFIG_FEED_*` 只管设备端的源列表，不管包编不编进固件**（`include/feeds.mk` 里它只有生成
   `distfeeds.conf` / `repositories.d` 两处消费点）。所以 `an7581.config` 里把上述 feed 置 `m`：
   默认源列表只剩官方地址，`apk update` 不再报死链，而 app 照旧预装。**不要**为了"分离"把
   feed 从 `feeds.conf.default` 挪走——`scripts/feeds install -a` 就不拉取它了，包会被
   `make defconfig` 静默跳过（同 `clone-packages.sh` 头注释里 `77684b6` 那个坑）。
3. **`distfeeds.list` 是构建生成的，`customfeeds.list` 才是给用户改的**。前者每次刷机重写，
   后者由 apk 包安装并登记为 conffile，sysupgrade 保留。自建源一律走后者。

于是分工是：默认源=官方包（可正常 `apk upgrade`），自建源=本项目 feed，由勾选 `publish_feeds`
的那趟编译发布到本仓库 Pages，站点地址即 `files/etc/apk/repositories.d/customfeeds.list` 里那几条。

**升级口径：只手工装单个包，不跑全局升级。** 官方源是每日 snapshot，`apk upgrade -a` 会把
`luci-base`、`libc` 这些依赖拉到与固件编译那天不一致的版本，而自建站点上的包是按编译那天的基线做的。

```sh
apk update && apk add --simulate luci-app-lucky     # 先看会不会连带升级官方包
apk add luci-app-lucky                              # 只列出该包及其缺失依赖时才执行
```

两点补充：`kmod-*`（在 `pon_drivers` 里）依赖完全一致的内核版本，换过内核就别手装；
手装的包只存在于 overlay，`sysupgrade` 与恢复出厂都会回退到固件预装版本——要固化就更新
`add-feed-sources.sh` 里的 feed pin，让它随下趟编译进镜像。站点每次部署整站替换，
只保留最近一趟编译的包，历史版本去对应 run 的 artifact 里找。

### feeds 源

本仓库不带 `feeds.conf.default`，基础 feeds 用源码分支自带的那份。源码 `master` 分支含 `pon_drivers`（Airoha PON 硬件驱动）与 `pon_userspace`（LuCI/ponctl/pond 等用户空间工具）两个 feed，指向上游 `pbs05/openwrt-pon-drivers`、`pbs05/openwrt-pon-userspace`。

默认 feed 的源只改源码仓库那一处；第三方/编译期增量 feed（当前是 `mosdns`、`lucky`）只在 `add-feed-sources.sh` 增删，不写进源码仓库，两边不要互相掺。若确需整体换源，在本仓库根目录新建 `feeds.conf.default`，工作流会 `mv` 到源码目录并计入 `dl/` 缓存 key。

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
10. 将工作流 `CONFIG_FILE` 指向的那份配置复制为 `openwrt/.config`，无条件追加 `CONFIG_CCACHE=y` → `make defconfig` 展开（展开后自检这一行还在）
11. 执行 `set-firmware-defaults.sh` 修改固件出厂默认参数
12. 预下载软件包源码 (`make download`)
13. 编译固件：全并发 → 同级并发重试 → 才降级 `make -j1 V=s`（ccache 取自步骤 10 写入的 .config，命令行不带参数）
14. 收集固件镜像到 `release/<设备>/`，上传 artifact，打包 `tar.zst` 发布到 GitHub Release
15. 执行 `publish-feed-repos.sh` 把各 feed 的已签名仓库拷成 `feed-site/`，与出厂 `customfeeds.list` 逐条对账，暂存成 Pages artifact（仅勾选 `publish_feeds` 时）
16. `pages` job 把该站点部署到 GitHub Pages（仅勾选 `publish_feeds` 时；Pages Source 须已设为 GitHub Actions）
17. 清理旧 workflow runs (保留 7 天 / 至少 3 条) 和旧 Release (保留最近 3 个)

### 触发方式

在 GitHub Actions 页面左侧**先选工作流**，再点 "Run workflow"，按需勾选开关（两个缓存清理 + 两个发布）：

- `clean_dl_cache` — 先清空 `dl/` 下载缓存再编译。改了某个 package 的源码版本或下载地址
  （Makefile 里的 `PKG_VERSION` / `PKG_SOURCE_VERSION` / `PKG_SOURCE_URL`）而缓存里仍是同名旧包时
  勾选；这些字段不在缓存 key 的哈希范围内，改了不会自动失效。
- `clean_ccache` — 先清空 `openwrt/.ccache` 编译对象缓存再编译。怀疑复用到了不对的产物时勾选。
- `release` — 编译成功后创建 GitHub Release（只发固件镜像压缩包），默认关闭，关闭时只保留 artifact。
- `publish_feeds` — 把各 feed 的 apk 仓库发布到本仓库 Pages，供设备端 `apk add` 单个包，默认关闭。
  首次勾选前要在 仓库 Settings → Pages 把 Source 设为 **GitHub Actions**；没设好就失败，不静默跳过。

两层缓存默认都是启用的：`Cache ...` 步骤没有 if，恒定恢复 + 收尾保存，`CONFIG_CCACHE=y` 由
`Load custom config` 步骤无条件写进 `.config`。勾选清理开关时，对应的 `Clear ... cache` 步骤排在
同层 `Cache ...` 步骤**之前**，先删掉本设备前缀的条目，本趟恢复必然落空 → 全量下载/重编 →
收尾把新条目存回去，一趟冷编译就把缓存重新灌满（旧写法"关掉开关"要付两趟才恢复热度）。
没勾选时行为与改造前的"开关为 true"完全一致。删完有断言检查同前缀残留，没删净就直接失败，
而不是静默用旧缓存；也可以直接去 仓库 Settings → Actions → Caches 手动删除。

定时编译：编辑对应 workflow 文件取消 `schedule` 注释 (UTC 时间)。

### 自定义配置

- 改某台设备的软件包和内核模块，改它自己那份配置（`an7581.config`）；`configs/` 下的参考配置改了不影响云编译，工作流不读它
- 改默认 IP、DHCP 等参数改 `set-firmware-defaults.sh`，注意它对所有产出生效
- 换源码分支只改对应工作流 `env` 段的 `REPO_BRANCH`，本仓库的分支名不参与推导
- 新增编译目标：复制一份工作流，改 `name:`、`REPO_BRANCH`、`CONFIG_FILE`、`CONFIG_NAME`、`DEVICE_NAME`、`SUBTARGET`，以及两处 cache key 里 `hashFiles` 的配置文件名（`CONFIG_NAME` 必须与现有各前缀互不为前缀）

## 本地编译

各目标只是"克隆哪个源码分支 + 拷哪份配置"不同，其余步骤一致：

| 目标 | `git clone --depth 1 -b <分支>` | `cp <配置> .config` |
| --- | --- | --- |
| AN7581 XGS-PON | `master` | `an7581.config` |

```sh
# 安装编译所需的工具链和库
sudo bash -c 'bash <(curl -s https://build-scripts.immortalwrt.org/init_build_environment.sh)'

# 拉取源码（分支按上表选；浅克隆只取当前快照，需要完整历史/版本号时去掉 --depth 1）
git clone --depth 1 -b master https://github.com/DenzelVincent/ponwrt.git
cd ponwrt

# 增删第三方 feed (mosdns / lucky 都由编译仓库的 add-feed-sources.sh 统一处理，必须在 feeds update 之前执行)
sh /path/to/ImmortalWrt-firmware-build/add-feed-sources.sh

# 更新并安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 克隆第三方包 (lucky 已由上面的 feed 提供；airoha-npu 不在 feed 中，必须在 make defconfig 前完成，否则 kconfig 静默丢弃)
git clone --depth 1 https://github.com/DenzelVincent/luci-app-airoha-npu.git package/luci-app-airoha-npu

# 选择配置（按上表选对应那份）
cp an7581.config .config

# 开始编译
make defconfig

make -j$(nproc)
```

固件位于 `bin/targets/airoha/an7581/`。

## 刷入

使用 [AN758x-Stock2UBI](https://github.com/pbs05/an758x-stock2ubi) 备份原厂闪存并安装 UBI 布局。启动镜像和 Web 恢复界面由 [AN758x U-Boot](https://github.com/pbs05/uboot-an758x) 提供。

刷入 ImmortalWrt 后，通过 U-Boot Web 或 LuCI 的"网络 → PON → 配置 → PON board data"恢复原厂校准和身份数据。烽火 `factory` 需要先使用 [FiberHome Factory](https://github.com/pbs05/fiberhome-factory) 转换；转换后的烽火数据、`reservearea` 和 `dsd` 写入 PonWrt 的 `factory` 卷；Nokia 的 `bosa` 和 `ri` 写入同名卷。
