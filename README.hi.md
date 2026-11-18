# Redmi Note 10 5G (camellia) — रूट और GSI गाइड

**भाषाएँ:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

यह रिपॉज़िटरी **Redmi Note 10 5G** (कोडनेम `camellia`, MediaTek `MT6833` /
Dimensity 700) पर वास्तव में लागू और सत्यापित किए गए **बूटलोडर अनलॉक →
Magisk से स्थायी रूट → phh AOSP 12.1 GSI** की पूरी प्रक्रिया का दस्तावेज़ है।

यह केवल कमांड की सूची नहीं है: कौन-सा पार्टीशन क्यों लिखा जाता है, किन
पार्टीशन को **कभी** नहीं छूना चाहिए और वापस कैसे जाना है — यह सब समझाया गया है।

> ⚠️ **चेतावनी:** बूटलोडर अनलॉक करना, पार्टीशन फ़्लैश करना और GSI इंस्टॉल
> करना डिवाइस को ब्रिक कर सकता है, सारा डेटा मिटा सकता है और वारंटी समाप्त
> कर सकता है। केवल **अपने ही डिवाइस** पर, बैकअप के बाद करें। जोखिम आपका है।

---

## परिणाम (इस डिवाइस पर सत्यापित)

| | |
|---|---|
| डिवाइस | Redmi Note 10 5G — `M2103K19C`, कोडनेम `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, डायनामिक पार्टीशन (`super`) |
| बूटलोडर | अनलॉक (`ro.boot.flash.locked=0`) |
| रूट | **Magisk 31.0**, पैच किया गया `boot_a` (systemless) |
| सिस्टम | phh AOSP 12.1 v416 **vanilla** GSI (Android 12) |
| सत्यापन | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| स्थायित्व | रीबूट के बाद भी बना रहता है; रूट `boot_a` में है |
| अतिरिक्त मॉड्यूल | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**मुख्य बात:** रूट GSI से **पहले** MIUI पर किया गया था। GSI फ़्लैश `boot` को
नहीं छूता; केवल `system` (और `vbmeta`) बदलते हैं। इसलिए GSI पर जाने के बाद भी
Magisk रूट बना रहा।

---

## रोडमैप

| # | चरण | दस्तावेज़ | समय |
|---|---|---|---|
| 0 | डिवाइस पहचानें, बैकअप लें | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 मिनट |
| 1 | बूटलोडर अनलॉक करें | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 मिनट + प्रतीक्षा |
| 2 | Magisk से रूट | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 मिनट |
| 3 | GSI इंस्टॉल करें | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 मिनट |
| 4 | रूट सत्यापित करें | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 मिनट |
| 5 | मॉड्यूल इंस्टॉल करें | [docs/05-moduller.md](docs/05-moduller.md) | 10 मिनट |
| — | समस्या निवारण | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | MIUI पर वापस | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 मिनट |
| — | सुरक्षा | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | स्रोत | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> विस्तृत दस्तावेज़ अभी तुर्की में हैं। सभी कमांड और मान भाषा-निरपेक्ष हैं;
> इस README में पूरा प्रवाह दिया गया है।

---

## त्वरित कमांड (Windows)

```powershell
# रिपॉज़िटरी रूट से:

# 0) वातावरण और डिवाइस जाँचें (adb या fastboot मोड)
.\scripts\00-kontrol.ps1

# 1) vbmeta सत्यापन बंद करें (डिवाइस FASTBOOT मोड में)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) GSI फ़्लैश करें (डिवाइस FASTBOOTD मोड में)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) रूट और सिस्टम सत्यापित करें (डिवाइस चालू, adb जुड़ा)
.\scripts\04-dogrula.ps1

# 4) Magisk मॉड्यूल इंस्टॉल करें
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### मैनुअल फ़्लैश क्रम

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

## सत्यापित आउटपुट

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

`context=u:r:magisk:s0` सीधा प्रमाण है कि रूट Magisk दे रहा है।

---

## रिपॉज़िटरी संरचना

```text
redmi-note10-5g-root/
├─ README.md                 तुर्की (मुख्य)
├─ README.<lang>.md          अनुवाद
├─ docs/                     विस्तृत चरण (तुर्की)
├─ scripts/                  Windows PowerShell ऑटोमेशन
├─ magisk-modules/           दोनों मॉड्यूल का स्रोत
└─ LICENSE
```

---

## ज्ञात सीमाएँ

- **कोई OTA नहीं:** MIUI/HyperOS अपडेट GSI पर लागू नहीं होते।
- **Play Integrity / SafetyNet:** बूटलोडर अनलॉक + AVB बंद → प्रमाणपत्र वाले
  ऐप विफल होते हैं।
- **Widevine:** L3 पर गिर जाता है (HD DRM सीमित)।
- **VoLTE/VoWiFi:** डिवाइस/ऑपरेटर पर निर्भर; यहाँ सत्यापित नहीं।
- **कैमरा:** vendor HAL `camellia` vendor इमेज से आता है; phh सेटिंग्स लग सकती हैं।

---

## मॉड्यूल

| मॉड्यूल | संस्करण | कार्य |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | MTK Wi-Fi पावर सेव/सस्पेंड/DTIM बंद करता है; औसत ping 9.2 ms → 2.75 ms |
| `wifi-bekci` | 1.0 | Wi-Fi टूटने या बूट पर न जुड़ने पर सहेजे गए नेटवर्क से दोबारा जोड़ता है |

इंस्टॉल:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## सुरक्षा नियम

- बाद में कभी `fastboot flashing lock` न चलाएँ।
- कभी `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`, `proinfo`, `seccfg`,
  `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp` न लिखें।
- केवल इस गाइड में बताए गए पार्टीशन फ़्लैश करें।
- बैकअप फ़ोन से बाहर और एन्क्रिप्टेड रखें।

---

## लाइसेंस

[MIT](LICENSE) — 2026, contributors