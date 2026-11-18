# 09 — Kaynaklar

Aşağıdaki bağlantılar bu rehberde kullanılan araçların resmî veya birincil
kaynaklarıdır. Sürümler ve politikalar değişebilir; indirmeden önce kontrol edin.

---

## Android / platform

| Kaynak | Adres |
|---|---|
| Android Platform Tools (adb, fastboot) | <https://developer.android.com/tools/releases/platform-tools> |
| Android Verified Boot (AVB) | <https://source.android.com/docs/security/features/verifiedboot> |
| A/B ve dinamik bölümler | <https://source.android.com/docs/core/ota/dynamic_partitions> |
| Google USB Driver | <https://developer.android.com/studio/run/win-usb> |

## Xiaomi

| Kaynak | Adres |
|---|---|
| Mi Unlock (resmî) | <https://en.miui.com/unlock/> |
| Xiaomi Community (bootloader kuralları) | <https://c.mi.com/> |
| Mi Unlock Tool indirme | <https://en.miui.com/unlock/download.html> |

> Bootloader açma politikası 2024–2026 arasında birkaç kez değişti. Güncel
> koşullar (hesap yaşı, topluluk seviyesi, yıllık kota) için resmî sayfayı
> esas alın.

## Magisk

| Kaynak | Adres |
|---|---|
| Magisk (topjohnwu) | <https://github.com/topjohnwu/Magisk> |
| Magisk belgeleri | <https://topjohnwu.github.io/Magisk/> |
| Modül geliştirme | <https://topjohnwu.github.io/Magisk/guides.html> |
| Magisk sürümleri | <https://github.com/topjohnwu/Magisk/releases> |

## GSI / Treble

| Kaynak | Adres |
|---|---|
| phhusson treble_experimentations | <https://github.com/phhusson/treble_experimentations> |
| phh GSI sürümleri | <https://github.com/phhusson/treble_experimentations/releases> |
| Treble destek durumu | <https://github.com/phhusson/treble_experimentations/wiki> |
| Android GSI belgeleri | <https://developer.android.com/topic/generic-system-image> |

## Araçlar

| Araç | Adres | Ne için |
|---|---|---|
| payload-dumper-go | <https://github.com/ssut/payload-dumper-go> | Fastboot ROM'dan `boot.img` çıkarma |
| 7-Zip | <https://www.7-zip.org/> | `.gz` / `.tar` açma |
| SHA-256 aracı | PowerShell `Get-FileHash` | İmaj doğrulama |

## Alternatif root çözümleri

| Çözüm | Adres | Not |
|---|---|---|
| KernelSU | <https://github.com/tiann/KernelSU> | Çekirdek içi root; uyumlu kernel derlemesi gerekir |
| APatch | <https://github.com/bmax121/APatch> | Kernel patch tabanlı |
| Magisk Delta | <https://github.com/HuskyDG/magisk-files> | Topluluk fork'u; resmî değil |

> Bu cihazda **Magisk 31.0** kullanıldı. KernelSU/APatch, uyumlu bir özel
> çekirdek gerektirdiğinden bu rehberde denenmedi.

## Bu depodaki modüllerin ilgili projeleri

| Proje | Adres |
|---|---|
| Kabuk (root sunucu) | Bu depo dışında; yerel `Kabuk/` projesi |
| phh Treble Settings | GSI içinde gelir |
