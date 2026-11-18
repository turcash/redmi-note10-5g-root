# Redmi Note 10 5G (camellia) — Guia de root e GSI

**Idiomas:** [Türkçe](README.md) · [English](README.en.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Português](README.pt-BR.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Español](README.es.md) · [Tiếng Việt](README.vi.md) · [العربية](README.ar.md) · [Français](README.fr.md)

Este repositório documenta o processo **desbloquear o bootloader → root
permanente com Magisk → GSI phh AOSP 12.1** que foi realmente aplicado e
verificado em um **Redmi Note 10 5G** (codinome `camellia`, MediaTek `MT6833` /
Dimensity 700).

Não é apenas uma lista de comandos: explica qual partição é gravada e por quê,
quais partições **nunca** devem ser tocadas e como reverter.

> ⚠️ **Aviso:** desbloquear o bootloader, gravar partições e instalar uma GSI
> pode inutilizar o aparelho, apagar todos os dados e anular a garantia. Faça
> isso apenas no **seu próprio aparelho**, após um backup. Use por sua conta e
> risco.

---

## Resultado (verificado neste aparelho)

| | |
|---|---|
| Aparelho | Redmi Note 10 5G — `M2103K19C`, codinome `camellia` |
| SoC | MediaTek `MT6833` (Dimensity 700), arm64, A/B, partições dinâmicas (`super`) |
| Bootloader | Desbloqueado (`ro.boot.flash.locked=0`) |
| Root | **Magisk 31.0**, `boot_a` corrigida (systemless) |
| Sistema | GSI phh AOSP 12.1 v416 **vanilla** (Android 12) |
| Verificação | `su -c id` → `uid=0(root) ... context=u:r:magisk:s0` |
| Persistência | Sobrevive à reinicialização; o root fica em `boot_a` |
| Módulos extras | `camellia-wifi-fix` 0.3, `wifi-bekci` 1.0, `kabuk-sunucu` |

**Ponto principal:** o root foi feito no MIUI **antes** da GSI. O flash da GSI
não altera o `boot`; apenas `system` (e `vbmeta`) mudam. Por isso o root do
Magisk continuou funcionando após a troca para a GSI.

---

## Roteiro

| # | Etapa | Documento | Tempo |
|---|---|---|---|
| 0 | Identificar o aparelho, fazer backup | [docs/00-cihaz.md](docs/00-cihaz.md) | 30–60 min |
| 1 | Desbloquear o bootloader | [docs/01-bootloader.md](docs/01-bootloader.md) | 10 min + espera |
| 2 | Root com Magisk | [docs/02-magisk-root.md](docs/02-magisk-root.md) | 20 min |
| 3 | Instalar a GSI | [docs/03-gsi.md](docs/03-gsi.md) | 20–30 min |
| 4 | Verificar o root | [docs/04-dogrulama.md](docs/04-dogrulama.md) | 5 min |
| 5 | Instalar módulos | [docs/05-moduller.md](docs/05-moduller.md) | 10 min |
| — | Solução de problemas | [docs/06-sorun-giderme.md](docs/06-sorun-giderme.md) | — |
| — | Voltar ao MIUI | [docs/07-geri-donus.md](docs/07-geri-donus.md) | 20–40 min |
| — | Segurança | [docs/08-guvenlik.md](docs/08-guvenlik.md) | — |
| — | Fontes | [docs/09-kaynaklar.md](docs/09-kaynaklar.md) | — |

> Os documentos detalhados estão em turco. Todos os comandos e valores são
> independentes de idioma; este README contém o fluxo completo.

---

## Comandos rápidos (Windows)

```powershell
# Na raiz do repositório:

# 0) Verificar ambiente e aparelho (modo adb ou fastboot)
.\scripts\00-kontrol.ps1

# 1) Desativar a verificação vbmeta (aparelho em modo FASTBOOT)
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 2) Gravar a GSI (aparelho em modo FASTBOOTD)
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 3) Verificar root e sistema (aparelho ligado, adb conectado)
.\scripts\04-dogrula.ps1

# 4) Instalar módulo Magisk
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Sequência manual de flash

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

## Saída verificada

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

`context=u:r:magisk:s0` é a prova direta de que o root é concedido pelo Magisk.

---

## Estrutura do repositório

```text
redmi-note10-5g-root/
├─ README.md                 turco (principal)
├─ README.<lang>.md          traduções
├─ docs/                     passos detalhados (turco)
├─ scripts/                  automação PowerShell para Windows
├─ magisk-modules/           código-fonte dos dois módulos
└─ LICENSE
```

---

## Limitações conhecidas

- **Sem OTA:** atualizações MIUI/HyperOS não se aplicam a uma GSI.
- **Play Integrity / SafetyNet:** bootloader desbloqueado + AVB desativado →
  aplicativos com verificação de certificado falham.
- **Widevine:** cai para L3 (DRM em HD limitado).
- **VoLTE/VoWiFi:** depende do aparelho/operadora; não verificado aqui.
- **Câmera:** o HAL vendor vem da imagem `camellia`; ajustes phh podem ser
  necessários.

---

## Módulos

| Módulo | Versão | Função |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | Desativa economia de energia/suspensão/DTIM do Wi-Fi MTK; ping médio 9,2 ms → 2,75 ms |
| `wifi-bekci` | 1.0 | Reconecta às redes salvas quando o Wi-Fi cai ou não conecta na inicialização |

Instalação:

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

---

## Regras de segurança

- Nunca execute `fastboot flashing lock` depois.
- Nunca grave `nvram`, `nvdata`, `nvcfg`, `protect1/2`, `persist`, `proinfo`,
  `seccfg`, `preloader`, `lk`, `tee`, `md1img`, `efuse`, `otp`.
- Grave apenas as partições indicadas neste guia.
- Mantenha os backups fora do aparelho e criptografados.

---

## Licença

[MIT](LICENSE) — 2026, contributors