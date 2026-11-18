# Redmi Note 10 5G (camellia) — Руководство по root и GSI

**Языки:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

В этом репозитории описан процесс **разблокировки загрузчика → постоянного
root через Magisk → установки GSI phh AOSP 12.1**, который был реально
выполнен и проверен на **Redmi Note 10 5G** (кодовое имя `camellia`,
MediaTek `MT6833` / Dimensity 700).

Это не просто список команд: здесь объясняется, какой раздел записывается и
почему, какие разделы **нельзя** трогать никогда и как откатиться.

> ⚠️ **Внимание:** разблокировка загрузчика, запись разделов и установка GSI
> могут превратить устройство в «кирпич», удалить все данные и лишить
> гарантии. Применяйте только на **своём устройстве** и после резервной
> копии. Все действия — на ваш риск.

---

## Результат (проверено на этом устройстве)

| | |
|---|---|
| Устройство | Redmi Note 10 5G — `M2103K19C`, кодовое имя `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, динамические разделы (`super`) |
| Загрузчик | Разблокирован (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, пропатчен `boot_a` (systemless) |
| Система | GSI phh AOSP 12.1 v416 **vanilla** (Android 12) |
| Проверка | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Сохранение | Переживает перезагрузку; root находится в `boot_a` |
| Модули | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**Главное:** root был получен на MIUI **до** установки GSI. Прошивка GSI не
затрагивает `boot`; меняются только `system` (и `vbmeta`). Поэтому root Magisk
сохранился после перехода на GSI.

---

## План

| # | Этап | Документ | Время |
|---|---|---|---|
| 0 | Определить устройство, сделать бэкап | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 мин |
| 1 | Разблокировать загрузчик | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 мин + ожидание |
| 2 | Root через Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 мин |
| 3 | Установить GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 мин |
| 4 | Проверить root | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 мин |
| 5 | Установить модули | [docs/05-moduller.md](docs/05-moduller.md) | 10 мин |
| — | Решение проблем | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | Откат на MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 мин |
| — | Безопасность | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Источники | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> Подробные документы пока на турецком. Все команды и значения не зависят от
> языка; в этой README приведён полный порядок действий.

---

## Быстрые команды (Windows)

```powershell
# Из корня репозитория:

# 0) Проверить окружение и устройство (режим adb или fastboot)
.\scripts\00-kontrol.ps1

# 1) Отключить проверку vbmeta (устройство в режиме FASTBOOT)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) Прошить GSI (устройство в режиме FASTBOOTD)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Проверить root и систему (устройство загружено, adb подключён)
.\scripts\04-dogrula.ps1

# 4) Установить модуль Magisk
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Ручная последовательность прошивки

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

## Проверенный вывод

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

`context=u:r:magisk:s0` — прямое доказательство, что root выдаёт Magisk.

---

## Структура репозитория

```text
redmi-note10-5g-root/
├─ README.md                 турецкий (основной)
├─ README.<lang>.md          переводы
├─ docs/                     подробные шаги (турецкий)
├─ scripts/                  автоматизация PowerShell для Windows
├─ magisk-modules/           исходники двух модулей
└─ LICENSE
```

---

## Известные ограничения

- **Нет OTA:** обновления MIUI/HyperOS не применяются к GSI.
- **Play Integrity / SafetyNet:** открытый загрузчик и отключённый AVB →
  приложения с проверкой сертификатов не работают.
- **Widevine:** падает до L3 (HD DRM ограничен).
- **VoLTE/VoWiFi:** зависит от устройства и оператора; здесь не проверялось.
- **Камера:** vendor HAL берётся из образа `camellia`; могут понадобиться
  настройки phh.

---

## Модули

| Модуль | Версия | Назначение |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | Отключает энергосбережение/сон/DTIM Wi-Fi MTK; средний ping 9,2 мс → 2,75 мс |
| `wifi-bekci` | 1.0 | Переподключается к сохранённым сетям при обрыве или отсутствии связи при загрузке |

Установка:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## Правила безопасности

- Никогда не выполняйте `fastboot flashing lock` после этого.
- Никогда не записывайте `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`,
  `proinfo`, `seccfg`, `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp`.
- Прошивайте только разделы, указанные в этом руководстве.
- Храните бэкапы вне телефона и в зашифрованном виде.

---

## Лицензия

[MIT](LICENSE) — 2026, contributors