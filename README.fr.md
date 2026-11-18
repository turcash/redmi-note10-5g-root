# Redmi Note 10 5G (camellia) — Guide root et GSI

**Langues :** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

Ce dépôt documente le processus **déverrouillage du bootloader → root permanent
avec Magisk → GSI phh AOSP 12.1** réellement appliqué et vérifié sur un
**Redmi Note 10 5G** (nom de code `camellia`, MediaTek `MT6833` / Dimensity 700).

Ce n'est pas une simple liste de commandes : il explique quelle partition est
écrite et pourquoi, quelles partitions ne doivent **jamais** être touchées et
comment revenir en arrière.

> ⚠️ **Avertissement :** déverrouiller le bootloader, écrire des partitions et
> installer une GSI peut rendre l'appareil inutilisable, effacer toutes les
> données et annuler la garantie. À faire uniquement sur **votre propre
> appareil**, après une sauvegarde. À vos risques et périls.

---

## Résultat (vérifié sur cet appareil)

| | |
|---|---|
| Appareil | Redmi Note 10 5G — `M2103K19C`, nom de code `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, partitions dynamiques (`super`) |
| Bootloader | Déverrouillé (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, `boot_a` patchée (systemless) |
| Système | GSI phh AOSP 12.1 v416 **vanilla** (Android 12) |
| Vérification | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Persistance | Survit au redémarrage ; le root est dans `boot_a` |
| Modules | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**Point clé :** le root a été fait sur MIUI **avant** la GSI. Le flash de la GSI
ne touche pas à `boot` ; seuls `system` (et `vbmeta`) changent. C'est pourquoi le
root Magisk a survécu au passage à la GSI.

---

## Feuille de route

| # | Étape | Document | Durée |
|---|---|---|---|
| 0 | Identifier l'appareil, faire une sauvegarde | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 min |
| 1 | Déverrouiller le bootloader | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 min + attente |
| 2 | Root avec Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 min |
| 3 | Installer la GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 min |
| 4 | Vérifier le root | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 min |
| 5 | Installer les modules | [docs/05-moduller.md](docs/05-moduller.md) | 10 min |
| — | Dépannage | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | Retour à MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 min |
| — | Sécurité | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Sources | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> Les documents détaillés sont en turc. Toutes les commandes et valeurs sont
> indépendantes de la langue ; ce README contient le déroulé complet.

---

## Commandes rapides (Windows)

```powershell
# Depuis la racine du dépôt :

# 0) Vérifier l'environnement et l'appareil (mode adb ou fastboot)
.\scripts\00-kontrol.ps1

# 1) Désactiver la vérification vbmeta (appareil en mode FASTBOOT)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) Flasher la GSI (appareil en mode FASTBOOTD)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Vérifier le root et le système (appareil démarré, adb connecté)
.\scripts\04-dogrula.ps1

# 4) Installer un module Magisk
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Séquence de flash manuelle

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

## Sortie vérifiée

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

`context=u:r:magisk:s0` prouve directement que le root est accordé par Magisk.

---

## Structure du dépôt

```text
redmi-note10-5g-root/
├─ README.md                 turc (principal)
├─ README.<lang>.md          traductions
├─ docs/                     étapes détaillées (turc)
├─ scripts/                  automatisation PowerShell Windows
├─ magisk-modules/           code source des deux modules
└─ LICENSE
```

---

## Limites connues

- **Pas d'OTA :** les mises à jour MIUI/HyperOS ne s'appliquent pas à une GSI.
- **Play Integrity / SafetyNet :** bootloader déverrouillé + AVB désactivé → les
  applications à certificat échouent.
- **Widevine :** passe en L3 (DRM HD limité).
- **VoLTE/VoWiFi :** dépend de l'appareil/opérateur ; non vérifié ici.
- **Appareil photo :** le HAL vendor vient de l'image `camellia` ; des réglages
  phh peuvent être nécessaires.

---

## Modules

| Module | Version | Rôle |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | Désactive l'économie d'énergie/suspend/DTIM du Wi-Fi MTK ; ping moyen 9,2 ms → 2,75 ms |
| `wifi-bekci` | 1.0 | Se reconnecte aux réseaux enregistrés en cas de coupure ou d'absence de connexion au démarrage |

Installation :

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## Règles de sécurité

- N'exécutez jamais `fastboot flashing lock` ensuite.
- N'écrivez jamais `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`,
  `proinfo`, `seccfg`, `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp`.
- Ne flashez que les partitions indiquées dans ce guide.
- Gardez les sauvegardes hors du téléphone et chiffrées.

---

## Licence

[MIT](LICENSE) — 2026, contributors