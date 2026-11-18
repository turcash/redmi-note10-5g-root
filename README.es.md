# Redmi Note 10 5G (camellia) — Guía de root y GSI

**Idiomas:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

Este repositorio documenta el proceso **desbloquear el bootloader → root
permanente con Magisk → GSI phh AOSP 12.1** que se aplicó y verificó realmente
en un **Redmi Note 10 5G** (nombre en clave `camellia`, MediaTek `MT6833` /
Dimensity 700).

No es solo una lista de comandos: explica qué partición se escribe y por qué,
qué particiones **nunca** deben tocarse y cómo revertir.

> ⚠️ **Advertencia:** desbloquear el bootloader, escribir particiones e instalar
> una GSI puede dejar el dispositivo inservible, borrar todos los datos y anular
> la garantía. Hazlo solo en **tu propio dispositivo**, después de una copia de
> seguridad. Bajo tu responsabilidad.

---

## Resultado (verificado en este dispositivo)

| | |
|---|---|
| Dispositivo | Redmi Note 10 5G — `M2103K19C`, nombre en clave `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, particiones dinámicas (`super`) |
| Bootloader | Desbloqueado (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, `boot_a` parcheada (systemless) |
| Sistema | GSI phh AOSP 12.1 v416 **vanilla** (Android 12) |
| Verificación | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Persistencia | Sobrevive al reinicio; el root está en `boot_a` |
| Módulos extra | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**Punto clave:** el root se hizo en MIUI **antes** de la GSI. El flasheo de la
GSI no toca `boot`; solo cambian `system` (y `vbmeta`). Por eso el root de
Magisk siguió funcionando tras pasar a la GSI.

---

## Hoja de ruta

| # | Etapa | Documento | Tiempo |
|---|---|---|---|
| 0 | Identificar el dispositivo, hacer copia | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 min |
| 1 | Desbloquear el bootloader | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 min + espera |
| 2 | Root con Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 min |
| 3 | Instalar la GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 min |
| 4 | Verificar el root | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 min |
| 5 | Instalar módulos | [docs/05-moduller.md](docs/05-moduller.md) | 10 min |
| — | Solución de problemas | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | Volver a MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 min |
| — | Seguridad | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Fuentes | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> Los documentos detallados están en turco. Todos los comandos y valores son
> independientes del idioma; este README contiene el flujo completo.

---

## Comandos rápidos (Windows)

```powershell
# Desde la raíz del repositorio:

# 0) Comprobar entorno y dispositivo (modo adb o fastboot)
.\scripts\00-kontrol.ps1

# 1) Desactivar la verificación vbmeta (dispositivo en modo FASTBOOT)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) Flashear la GSI (dispositivo en modo FASTBOOTD)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Verificar root y sistema (dispositivo encendido, adb conectado)
.\scripts\04-dogrula.ps1

# 4) Instalar módulo Magisk
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Secuencia manual de flasheo

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

## Salida verificada

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

`context=u:r:magisk:s0` es la prueba directa de que el root lo concede Magisk.

---

## Estructura del repositorio

```text
redmi-note10-5g-root/
├─ README.md                 turco (principal)
├─ README.<lang>.md          traducciones
├─ docs/                     pasos detallados (turco)
├─ scripts/                  automatización PowerShell para Windows
├─ magisk-modules/           código fuente de los dos módulos
└─ LICENSE
```

---

## Límites conocidos

- **Sin OTA:** las actualizaciones MIUI/HyperOS no se aplican a una GSI.
- **Play Integrity / SafetyNet:** bootloader desbloqueado + AVB desactivado →
  las apps con certificados fallan.
- **Widevine:** baja a L3 (DRM HD limitado).
- **VoLTE/VoWiFi:** depende del dispositivo/operador; no verificado aquí.
- **Cámara:** el HAL vendor viene de la imagen `camellia`; pueden hacer falta
  ajustes de phh.

---

## Módulos

| Módulo | Versión | Función |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | Desactiva el ahorro de energía/suspensión/DTIM del Wi-Fi MTK; ping medio 9,2 ms → 2,75 ms |
| `wifi-bekci` | 1.0 | Reconecta a redes guardadas cuando el Wi-Fi cae o no conecta al arrancar |

Instalación:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## Reglas de seguridad

- Nunca ejecutes `fastboot flashing lock` después.
- Nunca escribas `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`, `proinfo`,
  `seccfg`, `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp`.
- Flashea solo las particiones indicadas en esta guía.
- Mantén las copias fuera del teléfono y cifradas.

---

## Licencia

[MIT](LICENSE) — 2026, contributors