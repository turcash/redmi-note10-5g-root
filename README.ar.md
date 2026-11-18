# Redmi Note 10 5G (camellia) — دليل الروت وGSI

**اللغات:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

يوثّق هذا المستودع عملية **فتح الـ bootloader → روت دائم عبر Magisk → تثبيت
GSI من phh AOSP 12.1** التي طُبّقت فعليًا وتم التحقق منها على **Redmi Note
10 5G** (الاسم الرمزي `camellia`، معالج MediaTek `MT6833` / Dimensity 700).

الأمر ليس مجرد قائمة أوامر: فهو يشرح أي قسم يُكتب ولماذا، والأقسام التي
**يجب ألا** تُلمس إطلاقًا، وكيفية الرجوع.

> ⚠️ **تحذير:** فتح الـ bootloader وكتابة الأقسام وتثبيت GSI قد يؤدي إلى تعطيل
> الجهاز نهائيًا، وحذف كل البيانات، وإلغاء الضمان. نفّذ ذلك على **جهازك
> الشخصي فقط** وبعد أخذ نسخة احتياطية. المسؤولية عليك.

---

## النتيجة (تم التحقق على هذا الجهاز)

| | |
|---|---|
| الجهاز | Redmi Note 10 5G — `M2103K19C`، الاسم الرمزي `camellia` |
| المعالج | MediaTek `MT6833` (Dimensity 700)، arm64، A/B، أقسام ديناميكية (`super`) |
| الـ bootloader | مفتوح (`ro.boot.flash.locked=0`) |
| الروت | **Magisk 31.0**، تم تعديل `boot_a` (systemless) |
| النظام | GSI من phh AOSP 12.1 v416 **vanilla** (Android 12) |
| التحقق | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| الاستمرارية | يبقى بعد إعادة التشغيل؛ الروت داخل `boot_a` |
| وحدات إضافية | `camellia-wifi-fix` 0.3، `wifi-bekci` 1.0، `kabuk-sunucu` |

**النقطة الأهم:** تم عمل الروت على MIUI **قبل** تثبيت GSI. تثبيت GSI لا يمس
`boot`؛ يتغير فقط `system` (و`vbmeta`). لذلك بقي روت Magisk يعمل بعد الانتقال
إلى GSI.

---

## خارطة الطريق

| # | المرحلة | المستند | الوقت |
|---|---|---|---|
| 0 | التعرف على الجهاز وأخذ نسخة احتياطية | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 دقيقة |
| 1 | فتح الـ bootloader | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 دقائق + انتظار |
| 2 | الروت عبر Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 دقيقة |
| 3 | تثبيت GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 دقيقة |
| 4 | التحقق من الروت | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 دقائق |
| 5 | تثبيت الوحدات | [docs/05-moduller.md](docs/05-moduller.md) | 10 دقائق |
| — | حل المشكلات | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | الرجوع إلى MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 دقيقة |
| — | الأمان | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | المصادر | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> المستندات التفصيلية حاليًا بالتركية. جميع الأوامر والقيم لا تعتمد على اللغة؛
> وهذا الملف يحتوي على التسلسل الكامل.

---

## أوامر سريعة (Windows)

```powershell
# من جذر المستودع:

# 0) فحص البيئة والجهاز (وضع adb أو fastboot)
.\scripts\00-kontrol.ps1

# 1) إيقاف التحقق من vbmeta (الجهاز في وضع FASTBOOT)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) تثبيت GSI (الجهاز في وضع FASTBOOTD)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) التحقق من الروت والنظام (الجهاز يعمل وadb متصل)
.\scripts\04-dogrula.ps1

# 4) تثبيت وحدة Magisk
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### تسلسل التثبيت اليدوي

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

## مخرجات تم التحقق منها

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

`context=u:r:magisk:s0` دليل مباشر على أن الروت يمنحه Magisk.

---

## هيكل المستودع

```text
redmi-note10-5g-root/
├─ README.md                 التركية (الرئيسي)
├─ README.<lang>.md          الترجمات
├─ docs/                     الخطوات التفصيلية (تركي)
├─ scripts/                  أتمتة PowerShell لويندوز
├─ magisk-modules/           مصدر الوحدتين
└─ LICENSE
```

---

## حدود معروفة

- **لا يوجد OTA:** تحديثات MIUI/HyperOS لا تُطبّق على GSI.
- **Play Integrity / SafetyNet:** bootloader مفتوح + AVB معطّل → التطبيقات
  المعتمدة على الشهادات تفشل.
- **Widevine:** ينخفض إلى L3 (تشغيل DRM عالي الدقة محدود).
- **VoLTE/VoWiFi:** يعتمد على الجهاز والمشغل؛ لم يتم التحقق هنا.
- **الكاميرا:** يأتي HAL من صورة `camellia`؛ قد تحتاج إعدادات phh.

---

## الوحدات

| الوحدة | الإصدار | الوظيفة |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | يعطّل توفير الطاقة/التعليق/DTIM في Wi-Fi MTK؛ متوسط ping من 9.2 مللي ثانية إلى 2.75 |
| `wifi-bekci` | 1.0 | يعيد الاتصال بالشبكات المحفوظة عند انقطاع Wi-Fi أو عدم الاتصال عند الإقلاع |

التثبيت:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## قواعد الأمان

- لا تشغّل `fastboot flashing lock` بعد ذلك أبدًا.
- لا تكتب أبدًا على `nvram` أو `nvdata` أو `nvcfg` أو `protect1/2` أو `persist`
  أو `proinfo` أو `seccfg` أو `preloader` أو `lk` أو `tee` أو `md1img` أو
  `efuse` أو `otp`.
- ثبّت فقط الأقسام المذكورة في هذا الدليل.
- احفظ النسخ الاحتياطية خارج الهاتف ومشفّرة.

---

## الترخيص

[MIT](LICENSE) — 2026, contributors