# Redmi Note 10 5G（camellia）— Root 与 GSI 指南

**语言 / Languages:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

本仓库记录了在 **Redmi Note 10 5G**（代号 `camellia`，联发科 `MT6833` /
Dimensity 700）上**实际执行并验证**的完整流程：**解锁 Bootloader → Magisk
永久 Root → phh AOSP 12.1 GSI**。

它不只是命令清单：还说明了写入哪个分区、为什么写入、哪些分区**绝对不能**
碰，以及如何回滚。

> ⚠️ **警告：** 解锁 Bootloader、写入分区和安装 GSI 可能导致设备变砖、清除
> 所有数据并使保修失效。请仅在**自己的设备**上、做好备份后操作。风险自负。

---

## 结果（本机已验证）

| | |
|---|---|
| 设备 | Redmi Note 10 5G — `M2103K19C`，代号 `camellia` |
| SoC | 联发科 `MT6833`（Dimensity 700），arm64，A/B，动态分区（`super`） |
| Bootloader | 已解锁（`ro.boot.flash.locked=0`） |
| Root | **Magisk 31.0**，已修补 `boot_a`（systemless） |
| 系统 | phh AOSP 12.1 v416 **vanilla** GSI（Android 12） |
| 验证 | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| 持久性 | 重启后仍有效；root 位于 `boot_a` |
| 附加模块 | `camellia-wifi-fix` 0.3、`wifi-bekci` 1.0、`kabuk-sunucu` |

**关键点：** Root 是在安装 GSI **之前**、在 MIUI 上完成的。刷入 GSI 不会
改动 `boot`，只改变 `system`（和 `vbmeta`）。因此切换到 GSI 后 Magisk root
依然有效。

---

## 路线图

| # | 阶段 | 文档 | 时间 |
|---|---|---|---|
| 0 | 识别设备、做备份 | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 分钟 |
| 1 | 解锁 Bootloader | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 分钟 + 等待 |
| 2 | 用 Magisk Root | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 分钟 |
| 3 | 安装 GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 分钟 |
| 4 | 验证 Root | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 分钟 |
| 5 | 安装模块 | [docs/05-moduller.md](docs/05-moduller.md) | 10 分钟 |
| — | 故障排查 | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | 回滚到 MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 分钟 |
| — | 安全说明 | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | 参考链接 | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> 详细文档目前为土耳其语。所有命令和数值与语言无关；本 README 包含完整流程。

---

## 快速命令（Windows）

```powershell
# 在仓库根目录执行：

# 0) 检查环境和设备（adb 或 fastboot 模式）
.\scripts\00-kontrol.ps1

# 1) 关闭 vbmeta 校验（设备处于 FASTBOOT 模式）
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) 刷入 GSI（设备处于 FASTBOOTD 模式）
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) 验证 root 和系统（设备已开机，adb 已连接）
.\scripts\04-dogrula.ps1

# 4) 安装 Magisk 模块
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### 手动刷写顺序

```text
fastboot devices
fastboot getvar current-slot        # a
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
fastboot reboot fastboot
fastboot getvar is-userspace        # yes
fastboot set_active a
fastboot delete-logical-partition product
fastboot erase system
fastboot flash system system-squeak-arm64-ab-vanilla.img
fastboot -w
fastboot reboot
```

---

## 已验证输出

```text
$ adb devices -l
eeae...9ea   device usb:... product:treble_arm64_bvS model:note10 device:phhgsi_arm64_ab

$ adb shell getprop ro.product.vendor.device
camellia

$ adb shell getprop ro.boot.hardware
mt6833

$ adb shell getprop ro.build.version.release
12

$ adb shell su -c id
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0

$ adb shell su -c magisk -v
31.0

$ adb shell su -c getprop persist.adb.tcp.port
5555
```

`context=u:r:magisk:s0` 是 Magisk 授予 root 的直接证据。

---

## 仓库结构

```text
redmi-note10-5g-root/
├─ README.md                 土耳其语（主文件）
├─ README.<lang>.md          各语言翻译
├─ docs/                     详细步骤（土耳其语）
├─ scripts/                  Windows PowerShell 自动化
├─ magisk-modules/           两个模块的源码
└─ LICENSE
```

---

## 已知限制

- **无 OTA：** 安装 GSI 后无法应用 MIUI/HyperOS 更新。
- **Play Integrity / SafetyNet：** Bootloader 已解锁且 AVB 关闭，依赖证书的
  应用会失败。
- **Widevine：** 降为 L3（高清 DRM 播放受限）。
- **VoLTE/VoWiFi：** 取决于设备和运营商；此处未验证。
- **相机：** Vendor HAL 来自 `camellia` vendor 镜像，可能需要 phh 调整。

---

## 模块

| 模块 | 版本 | 作用 |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | 关闭 MTK Wi-Fi 省电/休眠/DTIM；平均 ping 9.2 ms → 2.75 ms |
| `wifi-bekci` | 1.0 | Wi-Fi 断开或开机未连接时自动重连已保存网络 |

安装：

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## 安全规则

- 之后**绝不要**执行 `fastboot flashing lock`。
- **绝不要**写入 `nvram`、`nvdata`、`nvcfg`、`protect1/2`、`persist`、
  `proinfo`、`seccfg`、`preloader`、`lk`、`tee`、`md1img`、`efuse`、`otp`。
- 只刷写本指南中列出的分区。
- 备份保存在手机之外，并加密保存。

---

## 许可证

[MIT](LICENSE) — 2026, contributors