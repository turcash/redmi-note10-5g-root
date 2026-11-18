# Redmi Note 10 5G (camellia) — Hướng dẫn root và GSI

**Ngôn ngữ:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

Kho lưu trữ này ghi lại quy trình **mở khóa bootloader → root vĩnh viễn bằng
Magisk → GSI phh AOSP 12.1** đã được thực hiện và kiểm chứng thực tế trên
**Redmi Note 10 5G** (tên mã `camellia`, MediaTek `MT6833` / Dimensity 700).

Đây không chỉ là danh sách lệnh: tài liệu giải thích phân vùng nào được ghi và
vì sao, những phân vùng **tuyệt đối không** được chạm vào, và cách khôi phục.

> ⚠️ **Cảnh báo:** mở khóa bootloader, ghi phân vùng và cài GSI có thể làm hỏng
> máy, xóa toàn bộ dữ liệu và mất bảo hành. Chỉ thực hiện trên **thiết bị của
> bạn**, sau khi đã sao lưu. Tự chịu rủi ro.

---

## Kết quả (đã kiểm chứng trên máy này)

| | |
|---|---|
| Thiết bị | Redmi Note 10 5G — `M2103K19C`, tên mã `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, phân vùng động (`super`) |
| Bootloader | Đã mở (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, đã vá `boot_a` (systemless) |
| Hệ thống | GSI phh AOSP 12.1 v416 **vanilla** (Android 12) |
| Kiểm chứng | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Duy trì | Sống qua khởi động lại; root nằm trong `boot_a` |
| Mô-đun thêm | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**Điểm chính:** root được thực hiện trên MIUI **trước** khi cài GSI. Việc flash
GSI không chạm vào `boot`; chỉ `system` (và `vbmeta`) thay đổi. Vì vậy root
Magisk vẫn hoạt động sau khi chuyển sang GSI.

---

## Lộ trình

| # | Giai đoạn | Tài liệu | Thời gian |
|---|---|---|---|
| 0 | Xác định thiết bị, sao lưu | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 phút |
| 1 | Mở bootloader | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 phút + chờ |
| 2 | Root bằng Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 phút |
| 3 | Cài GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 phút |
| 4 | Kiểm tra root | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 phút |
| 5 | Cài mô-đun | [docs/05-moduller.md](docs/05-moduller.md) | 10 phút |
| — | Xử lý sự cố | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | Quay về MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 phút |
| — | Bảo mật | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Nguồn | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> Tài liệu chi tiết hiện bằng tiếng Thổ Nhĩ Kỳ. Mọi lệnh và giá trị không phụ
> thuộc ngôn ngữ; README này chứa toàn bộ quy trình.

---

## Lệnh nhanh (Windows)

```powershell
# Từ thư mục gốc của kho:

# 0) Kiểm tra môi trường và thiết bị (chế độ adb hoặc fastboot)
.\scripts\00-kontrol.ps1

# 1) Tắt xác minh vbmeta (thiết bị ở chế độ FASTBOOT)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) Flash GSI (thiết bị ở chế độ FASTBOOTD)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Kiểm tra root và hệ thống (máy đã bật, adb đã kết nối)
.\scripts\04-dogrula.ps1

# 4) Cài mô-đun Magisk
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Thứ tự flash thủ công

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

## Kết quả kiểm chứng

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

`context=u:r:magisk:s0` là bằng chứng trực tiếp rằng root do Magisk cấp.

---

## Cấu trúc kho

```text
redmi-note10-5g-root/
├─ README.md                 tiếng Thổ Nhĩ Kỳ (chính)
├─ README.<lang>.md          bản dịch
├─ docs/                     các bước chi tiết (tiếng Thổ Nhĩ Kỳ)
├─ scripts/                  tự động hóa PowerShell cho Windows
├─ magisk-modules/           mã nguồn hai mô-đun
└─ LICENSE
```

---

## Giới hạn đã biết

- **Không OTA:** bản cập nhật MIUI/HyperOS không áp dụng cho GSI.
- **Play Integrity / SafetyNet:** bootloader mở + AVB tắt → ứng dụng dùng
  chứng chỉ sẽ lỗi.
- **Widevine:** giảm xuống L3 (DRM HD bị hạn chế).
- **VoLTE/VoWiFi:** phụ thuộc thiết bị/nhà mạng; chưa kiểm chứng.
- **Camera:** HAL vendor đến từ ảnh `camellia`; có thể cần tinh chỉnh phh.

---

## Mô-đun

| Mô-đun | Phiên bản | Chức năng |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | Tắt tiết kiệm điện/tạm ngưng/DTIM của Wi-Fi MTK; ping trung bình 9,2 ms → 2,75 ms |
| `wifi-bekci` | 1.0 | Tự kết nối lại mạng đã lưu khi Wi-Fi mất hoặc không kết nối lúc khởi động |

Cài đặt:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## Quy tắc an toàn

- Không bao giờ chạy `fastboot flashing lock` sau đó.
- Không bao giờ ghi `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`,
  `proinfo`, `seccfg`, `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp`.
- Chỉ flash các phân vùng được nêu trong hướng dẫn này.
- Giữ bản sao lưu ngoài điện thoại và được mã hóa.

---

## Giấy phép

[MIT](LICENSE) — 2026, contributors