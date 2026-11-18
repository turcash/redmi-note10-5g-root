# Redmi Note 10 5G (camellia) — Root & GSI Guide

**Languages:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

This repository documents the **bootloader unlock → permanent Magisk root →
phh AOSP 12.1 GSI** process that was actually applied and verified on a
**Redmi Note 10 5G** (codename `camellia`, MediaTek `MT6833` / Dimensity 700).

It is not just a command list: it explains which partition is written and why,
which partitions must **never** be touched, and how to roll back.

> ⚠️ **Warning:** Unlocking the bootloader, flashing partitions and installing a
> GSI can brick the device, erase all data and void the warranty. Apply this only
> on **your own device**, after taking a backup. Use at your own risk.

---

## Result (verified on this device)

| | |
|---|---|
| Device | Redmi Note 10 5G — `M2103K19C`, codename `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, dynamic partitions (`super`) |
| Bootloader | Unlocked (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, patched `boot_a` (systemless) |
| System | phh AOSP 12.1 v416 **vanilla** GSI (Android 12) |
| Verification | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Persistence | Survives reboot; root lives in `boot_a` |
| Extra modules | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**Key point:** Root was applied on MIUI **before** the GSI. The GSI flash does not
touch `boot`; only `system` (and `vbmeta`) change. That is why Magisk root
survived the switch to the GSI.

---

## Roadmap

| # | Stage | Document | Time |
|---|---|---|---|
| 0 | Identify the device, take backups | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 min |
| 1 | Unlock the bootloader | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 min + wait |
| 2 | Root with Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 min |
| 3 | Install the GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 min |
| 4 | Verify root | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 min |
| 5 | Install modules | [docs/05-moduller.md](docs/05-moduller.md) | 10 min |
| — | Troubleshooting | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | Roll back to MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 min |
| — | Security notes | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Sources | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> The detailed documents are currently in Turkish. All commands and values in
> them are language-independent; this README contains the complete flow.

---

## Quick commands (Windows)

```powershell
# From the repository root:

# 0) Check environment and device (adb or fastboot mode)
.\scripts\00-kontrol.ps1

# 1) Disable vbmeta verification (device in FASTBOOT mode)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) Flash the GSI (device in FASTBOOTD mode)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Verify root and system (device booted, adb connected)
.\scripts\04-dogrula.ps1

# 4) Install a Magisk module
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Manual flash sequence

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

## Verified output

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

`context=u:r:magisk:s0` is direct proof that root is granted by Magisk.

---

## Repository layout

```text
redmi-note10-5g-root/
├─ README.md                 Turkish (main)
├─ README.<lang>.md          translations
├─ docs/                     detailed steps (Turkish)
├─ scripts/                  Windows PowerShell automation
├─ magisk-modules/           source of the two modules
└─ LICENSE
```

---

## Known limits

- **No OTA:** MIUI/HyperOS updates do not apply to a GSI install.
- **Play Integrity / SafetyNet:** unlocked bootloader + disabled AVB → most
  certificate-based apps fail.
- **Widevine:** drops to L3 (HD DRM playback limited).
- **VoLTE/VoWiFi:** depends on device/operator; not verified here.
- **Camera:** vendor HAL comes from the `camellia` vendor image; phh tweaks may
  be needed.

---

## Modules

| Module | Version | Purpose |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | Disables MTK Wi-Fi power save/suspend/DTIM; 9.2 ms → 2.75 ms average ping |
| `wifi-bekci` | 1.0 | Reconnects to saved networks when Wi-Fi drops or does not connect at boot |

Install:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## Safety rules

- Never run `fastboot flashing lock` afterwards.
- Never write `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`, `proinfo`,
  `seccfg`, `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp`.
- Only flash the partitions named in this guide.
- Keep backups off the phone, encrypted.

---

## License

[MIT](LICENSE) — 2026, contributors