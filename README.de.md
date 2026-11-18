# Redmi Note 10 5G (camellia) — Root- und GSI-Anleitung

**Sprachen:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

Dieses Repository dokumentiert den **Bootloader-Entsperren → dauerhaftes
Magisk-Root → phh AOSP 12.1 GSI**-Prozess, der auf einem **Redmi Note 10 5G**
(Codename `camellia`, MediaTek `MT6833` / Dimensity 700) tatsächlich
durchgeführt und verifiziert wurde.

Es ist keine reine Befehlsliste: Es erklärt, welche Partition beschrieben wird
und warum, welche Partitionen **niemals** angefasst werden dürfen und wie man
zurückrollt.

> ⚠️ **Warnung:** Bootloader entsperren, Partitionen flashen und ein GSI
> installieren kann das Gerät unbrauchbar machen, alle Daten löschen und die
> Garantie verlieren. Nur am **eigenen Gerät** und erst nach einem Backup
> anwenden. Benutzung auf eigene Gefahr.

---

## Ergebnis (auf diesem Gerät verifiziert)

| | |
|---|---|
| Gerät | Redmi Note 10 5G — `M2103K19C`, Codename `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, dynamische Partitionen (`super`) |
| Bootloader | Entsperrt (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, gepatchte `boot_a` (systemless) |
| System | phh AOSP 12.1 v416 **Vanilla**-GSI (Android 12) |
| Nachweis | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Persistenz | Übersteht Neustart; Root liegt in `boot_a` |
| Zusatzmodule | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**Wichtigster Punkt:** Root wurde auf MIUI **vor** dem GSI eingerichtet. Der
GSI-Flash berührt `boot` nicht; nur `system` (und `vbmeta`) ändern sich. Deshalb
blieb das Magisk-Root beim Wechsel zum GSI erhalten.

---

## Fahrplan

| # | Phase | Dokument | Dauer |
|---|---|---|---|
| 0 | Gerät identifizieren, Backup erstellen | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 min |
| 1 | Bootloader entsperren | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 min + Wartezeit |
| 2 | Root mit Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 min |
| 3 | GSI installieren | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 min |
| 4 | Root prüfen | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 min |
| 5 | Module installieren | [docs/05-moduller.md](docs/05-moduller.md) | 10 min |
| — | Fehlerbehebung | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | Zurück zu MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 min |
| — | Sicherheit | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Quellen | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> Die ausführlichen Dokumente sind derzeit auf Türkisch. Alle Befehle und Werte
> sind sprachunabhängig; diese README enthält den vollständigen Ablauf.

---

## Schnellbefehle (Windows)

```powershell
# Im Wurzelverzeichnis des Repositories:

# 0) Umgebung und Gerät prüfen (adb- oder fastboot-Modus)
.\scripts\00-kontrol.ps1

# 1) vbmeta-Verifikation deaktivieren (Gerät im FASTBOOT-Modus)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) GSI flashen (Gerät im FASTBOOTD-Modus)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Root und System prüfen (Gerät gestartet, adb verbunden)
.\scripts\04-dogrula.ps1

# 4) Magisk-Modul installieren
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Manuelle Flash-Reihenfolge

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

## Verifizierte Ausgabe

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

`context=u:r:magisk:s0` ist der direkte Beweis, dass Root von Magisk vergeben wird.

---

## Repository-Struktur

```text
redmi-note10-5g-root/
├─ README.md                 Türkisch (Hauptdatei)
├─ README.<lang>.md          Übersetzungen
├─ docs/                     ausführliche Schritte (Türkisch)
├─ scripts/                  Windows-PowerShell-Automatisierung
├─ magisk-modules/           Quellcode der beiden Module
└─ LICENSE
```

---

## Bekannte Grenzen

- **Kein OTA:** MIUI/HyperOS-Updates lassen sich mit GSI nicht installieren.
- **Play Integrity / SafetyNet:** offener Bootloader + deaktiviertes AVB →
  zertifikatsbasierte Apps schlagen fehl.
- **Widevine:** fällt auf L3 zurück (HD-DRM eingeschränkt).
- **VoLTE/VoWiFi:** geräte- und betreiberabhängig; hier nicht verifiziert.
- **Kamera:** Vendor-HAL kommt aus dem `camellia`-Vendor-Image; ggf. phh-Tweaks.

---

## Module

| Modul | Version | Zweck |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | Deaktiviert MTK-Wi-Fi-Energiesparen/Suspend/DTIM; 9,2 ms → 2,75 ms Durchschnittsping |
| `wifi-bekci` | 1.0 | Verbindet bei Abbrüchen oder fehlender Verbindung beim Start erneut mit gespeicherten Netzen |

Installation:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## Sicherheitsregeln

- Niemals anschließend `fastboot flashing lock` ausführen.
- Niemals `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`, `proinfo`,
  `seccfg`, `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp` beschreiben.
- Nur die in dieser Anleitung genannten Partitionen flashen.
- Backups verschlüsselt und außerhalb des Telefons aufbewahren.

---

## Lizenz

[MIT](LICENSE) — 2026, contributors