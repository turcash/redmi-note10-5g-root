# Redmi Note 10 5G (camellia) — Root ve GSI Rehberi

**Diller / Languages:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

Bu depo, **Redmi Note 10 5G** (kod adı `camellia`, MediaTek `MT6833` / Dimensity 700)
cihazında uygulanmış ve doğrulanmış **bootloader açma → Magisk ile kalıcı root →
phh AOSP 12.1 GSI** kurulumunun tam kaydıdır.

Amaç sadece "komut listesi" vermek değil; hangi bölüme neden yazıldığını, hangi
bölümlere **asla** dokunulmaması gerektiğini ve geri dönüşün nasıl yapıldığını da
belgelemek. Rehber, birebir bu cihazda çalıştırılan adımlardan ve alınan gerçek
çıktılardan üretildi.

> ⚠️ **Uyarı:** Bootloader açmak, bölüm yazmak ve GSI kurmak cihazı tuğlaya
> çevirebilir, tüm verileri siler ve garantiyi geçersiz kılar. Yalnızca **kendi
> cihazınızda** ve yedek aldıktan sonra uygulayın. Risk size aittir.

---

## Sonuç (bu cihazda doğrulanan durum)

| | |
|---|---|
| Cihaz | Redmi Note 10 5G — `M2103K19C`, kod adı `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, dinamik bölümler (`super`) |
| Bootloader | Açık (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, `boot_a` yamalı (systemless) |
| Sistem | phh AOSP 12.1 v416 **vanilla** GSI (Android 12) |
| Doğrulama | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Kalıcılık | Yeniden başlatmada korunur; root `boot_a` içinde |
| Ek modüller | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**En önemli nokta:** Root, GSI kurulumundan **önce** MIUI üzerinde yapıldı.
GSI kurulumu `boot` bölümüne dokunmaz; yalnızca `system` (ve `vbmeta`) değişir.
Bu yüzden Magisk root GSI'ya geçtikten sonra da aynen çalışmaya devam etti.

---

## Yol haritası

| # | Aşama | Belge | Süre (yaklaşık) |
|---|---|---|---|
| 0 | Cihazı tanı, yedek al | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 dk (yedek boyutuna göre) |
| 1 | Bootloader'ı aç | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 dk + bekleme süresi |
| 2 | Magisk ile root | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 dk |
| 3 | GSI kur | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 dk |
| 4 | Root'u doğrula | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 dk |
| 5 | Modülleri kur | [docs/05-moduller.md](docs/05-moduller.md) | 10 dk |
| — | Sorun giderme | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | MIUI'ye geri dönüş | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 dk |
| — | Güvenlik notları | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Kaynaklar | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

---

## Hızlı komut özeti (Windows)

```powershell
# Depo kokunde, PowerShell:

# 0) Ortami ve cihazi kontrol et (adb veya fastboot modunda)
.\scripts\00-kontrol.ps1

# 1) vbmeta dogrulamasini kapat  (cihaz FASTBOOT modunda)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) GSI'yi yaz  (cihaz FASTBOOTD modunda)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Root ve sistem dogrulamasi  (cihaz acik, adb bagli)
.\scripts\04-dogrula.ps1

# 4) Magisk modulu kur
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

Ayrıntılı komutlar ve her adımın açıklaması ilgili `docs/` dosyasındadır.

---

## Diller

Ayrıntılı adımlar Türkçe yazıldı; her dilde tam akış ve doğrulanmış değerler
içeren bir README bulunur:

| Dil | Dosya |
|---|---|
| Türkçe | [README.md](README.md) |
| English | [README.en.md](README.en.md) |
| 简体中文 | [README.zh-CN.md](README.zh-CN.md) |
| Русский | [README.ru.md](README.ru.md) |
| Deutsch | [README.de.md](README.de.md) |
| Português (BR) | [README.pt-BR.md](README.pt-BR.md) |
| हिन्दी | [README.hi.md](README.hi.md) |
| Bahasa Indonesia | [README.id.md](README.id.md) |
| Español | [README.es.md](README.es.md) |
| Tiếng Việt | [README.vi.md](README.vi.md) |
| العربية | [README.ar.md](README.ar.md) |
| Français | [README.fr.md](README.fr.md) |

Bu diller, cihazın en çok satıldığı pazarlara göre seçildi: Hindistan, Çin,
Endonezya, Rusya/BDT, Avrupa (Almanya, Fransa, Portekiz, İspanya), Latin
Amerika, Vietnam ve Orta Doğu.

---

## Depo yapısı

```
redmi-note10-5g-root/
├─ README.md                 bu dosya
├─ README.<dil>.md           ceviriler (12 dil)
├─ docs/
│  ├─ 00-cihaz.md            cihaz, bolumler, yedek, tehlikeli bolumler
│  ├─ 01-bootloader.md       Mi Unlock ile bootloader acma
│  ├─ 02-magisk-root.md      boot.img yamalama ve Magisk root
│  ├─ 03-gsi.md              phh AOSP 12.1 GSI kurulumu
│  ├─ 04-dogrulama.md        root/sistem dogrulama + kablosuz ADB
│  ├─ 05-moduller.md         Magisk modulleri (wifi-fix, wifi-bekci)
│  ├─ 06-sorun-giderme.md    belirti → cozum tablosu
│  ├─ 07-geri-donus.md       MIUI'ye geri donme
│  ├─ 08-guvenlik.md         guvenlik ve gizlilik notlari
│  └─ 09-kaynaklar.md        resmi baglantilar
├─ scripts/
│  ├─ common.ps1             ortak fonksiyonlar
│  ├─ 00-kontrol.ps1         ortam/cihaz kontrolu
│  ├─ 01-vbmeta.ps1          AVB dogrulamasini kapat
│  ├─ 02-gsi-yaz.ps1         GSI yazma
│  ├─ 03-modul-yukle.ps1     Magisk modulu kurma
│  ├─ 04-dogrula.ps1         dogrulama
│  └─ geri-donus.ps1         MIUI'ye donus (cift onayli)
├─ magisk-modules/
│  ├─ camellia-wifi-fix/     MTK Wi-Fi guc/gecikme duzeltmesi
│  └─ wifi-bekci/            Wi-Fi kopma bekcisi
└─ LICENSE
```

---

## Doğrulanmış çıktılar

Bu cihazda alınan gerçek çıktılar (seri numarası kısaltılmıştır):

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

`su` komutunun `u:r:magisk:s0` SELinux bağlamında çalışması, root'un Magisk
tarafından verildiğinin doğrudan kanıtıdır.

---

## Neler denenmedi / bilinen sınırlar

- **OTA güncellemesi yok:** GSI kurulu cihazda MIUI/HyperOS OTA'sı uygulanmaz.
- **Play Integrity / SafetyNet:** Bootloader açık ve AVB kapalı olduğu için
  sertifika gerektiren bankacılık/DRM uygulamaları çalışmayabilir.
- **Widevine:** L1 yerine L3'e düşer (yüksek çözünürlüklü DRM oynatma kısıtlanır).
- **VoLTE/VoWiFi:** phh GSI'da cihaz/operatör desteğine göre değişir; bu rehberde
  doğrulanmamıştır.
- **Kamera:** Vendor HAL `camellia` bölümünden gelir; bazı phh sürümlerinde ek
  ayar gerekebilir.

---

## Katkı

Cihaz aynı olsa bile firmware sürümü, bölüm boyutu veya fastboot davranışı
değişebilir. Bir adım sizde farklı sonuç verirse **tahminle devam etmeyin**;
`fastboot getvar all` çıktısını ve hata mesajını kaydedin.

## Lisans

[MIT](LICENSE) — 2026, contributors