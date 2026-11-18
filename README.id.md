# Redmi Note 10 5G (camellia) — Panduan Root & GSI

**Bahasa:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

Repositori ini mendokumentasikan proses **membuka bootloader → root permanen
dengan Magisk → GSI phh AOSP 12.1** yang benar-benar diterapkan dan diverifikasi
pada **Redmi Note 10 5G** (nama kode `camellia`, MediaTek `MT6833` /
Dimensity 700).

Ini bukan sekadar daftar perintah: dijelaskan partisi mana yang ditulis dan
mengapa, partisi mana yang **tidak boleh** disentuh, serta cara mengembalikannya.

> ⚠️ **Peringatan:** Membuka bootloader, menulis partisi, dan memasang GSI dapat
> membuat perangkat mati total, menghapus semua data, dan membatalkan garansi.
> Lakukan hanya pada **perangkat Anda sendiri** setelah membuat cadangan. Risiko
> ditanggung sendiri.

---

## Hasil (terverifikasi di perangkat ini)

| | |
|---|---|
| Perangkat | Redmi Note 10 5G — `M2103K19C`, nama kode `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, partisi dinamis (`super`) |
| Bootloader | Terbuka (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, `boot_a` ditambal (systemless) |
| Sistem | GSI phh AOSP 12.1 v416 **vanilla** (Android 12) |
| Verifikasi | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Ketahanan | Bertahan setelah reboot; root berada di `boot_a` |
| Modul tambahan | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**Poin utama:** Root dipasang di MIUI **sebelum** GSI. Flash GSI tidak menyentuh
`boot`; hanya `system` (dan `vbmeta`) yang berubah. Karena itu root Magisk tetap
berfungsi setelah beralih ke GSI.

---

## Peta jalan

| # | Tahap | Dokumen | Waktu |
|---|---|---|---|
| 0 | Identifikasi perangkat, buat cadangan | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 mnt |
| 1 | Buka bootloader | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 mnt + tunggu |
| 2 | Root dengan Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 mnt |
| 3 | Pasang GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 mnt |
| 4 | Verifikasi root | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 mnt |
| 5 | Pasang modul | [docs/05-moduller.md](docs/05-moduller.md) | 10 mnt |
| — | Pemecahan masalah | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | Kembali ke MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 mnt |
| — | Keamanan | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Sumber | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> Dokumen rinci saat ini dalam bahasa Turki. Semua perintah dan nilai tidak
> bergantung pada bahasa; README ini memuat alur lengkapnya.

---

## Perintah cepat (Windows)

```powershell
# Dari akar repositori:

# 0) Periksa lingkungan dan perangkat (mode adb atau fastboot)
.\scripts\00-kontrol.ps1

# 1) Nonaktifkan verifikasi vbmeta (perangkat dalam mode FASTBOOT)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) Flash GSI (perangkat dalam mode FASTBOOTD)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Verifikasi root dan sistem (perangkat menyala, adb tersambung)
.\scripts\04-dogrula.ps1

# 4) Pasang modul Magisk
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Urutan flash manual

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

## Keluaran terverifikasi

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

`context=u:r:magisk:s0` adalah bukti langsung bahwa root diberikan oleh Magisk.

---

## Struktur repositori

```text
redmi-note10-5g-root/
├─ README.md                 Turki (utama)
├─ README.<lang>.md          terjemahan
├─ docs/                     langkah rinci (Turki)
├─ scripts/                  otomasi PowerShell Windows
├─ magisk-modules/           sumber kedua modul
└─ LICENSE
```

---

## Batasan yang diketahui

- **Tanpa OTA:** pembaruan MIUI/HyperOS tidak berlaku pada GSI.
- **Play Integrity / SafetyNet:** bootloader terbuka + AVB mati → aplikasi
  berbasis sertifikat gagal.
- **Widevine:** turun ke L3 (DRM HD terbatas).
- **VoLTE/VoWiFi:** tergantung perangkat/operator; belum diverifikasi.
- **Kamera:** HAL vendor berasal dari image `camellia`; mungkin perlu pengaturan phh.

---

## Modul

| Modul | Versi | Fungsi |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | Mematikan hemat daya/suspend/DTIM Wi-Fi MTK; ping rata-rata 9,2 ms → 2,75 ms |
| `wifi-bekci` | 1.0 | Menyambung ulang ke jaringan tersimpan saat Wi-Fi putus atau gagal saat boot |

Pemasangan:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## Aturan keamanan

- Jangan pernah menjalankan `fastboot flashing lock` setelahnya.
- Jangan pernah menulis `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`,
  `proinfo`, `seccfg`, `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp`.
- Hanya flash partisi yang disebutkan dalam panduan ini.
- Simpan cadangan di luar ponsel dan terenkripsi.

---

## Lisensi

[MIT](LICENSE) — 2026, contributors