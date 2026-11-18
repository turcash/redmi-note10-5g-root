# Betikler

Windows PowerShell 5.1+ için yazıldı. Linux/macOS'ta `docs/` içindeki komutları
doğrudan kullanın; betikler Windows'a özgüdür.

## Ön koşul

- `adb` ve `fastboot` PATH'te **veya** `ADB` / `FASTBOOT` ortam değişkenleriyle
  tanımlı **veya** şu konumlardan birinde:
  - `<depo>\tools\platform-tools\`
  - `<depo>\platform-tools\`
  - `C:\platform-tools\`
  - `%LOCALAPPDATA%\Android\Sdk\platform-tools\`
  - `%ANDROID_HOME%\platform-tools\`

Kontrol:

```powershell
.\scripts\00-kontrol.ps1
```

## Betikler

| Betik | Mod | Ne yapar |
|---|---|---|
| `00-kontrol.ps1` | adb / fastboot | Araçları, cihazı, özellikleri ve yedek dosyalarını kontrol eder |
| `01-vbmeta.ps1` | fastboot | AVB doğrulamasını kapatır (onay ister) |
| `02-gsi-yaz.ps1` | fastbootd | `product` siler, `system` yazar, istenirse `-w` |
| `03-modul-yukle.ps1` | adb + root | Klasör/zip modülü kurar |
| `04-dogrula.ps1` | adb | Root, modül, Wi-Fi ve ağ kontrolü |
| `geri-donus.ps1` | fastboot | Yalnızca 7 bölümü yazar; `GERI DON` onayı ister |

## Örnek akış

```powershell
# 1) Ortam ve cihaz
.\scripts\00-kontrol.ps1 -Yedek D:\Yedek

# 2) Fastboot'ta AVB kapat
.\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img

# 3) fastbootd'ye geç
fastboot reboot fastboot

# 4) GSI yaz
.\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil

# 5) Açılış sonrası doğrula
.\scripts\04-dogrula.ps1

# 6) Modülleri kur
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

## Güvenlik davranışı

- Her yıkıcı adım **`evet`** yazılarak onaylanır.
- Geri dönüş betiği ek olarak **`GERI DON`** metnini ister.
- `geri-donus.ps1` yalnızca sabit 7 bölümü yazar; yasaklı bölümler kodda geçmez.
- Komutlardan biri hata verirse betik durur (özellikle `flash` adımları).

## Not

Betikler `common.ps1` içindeki `Invoke-Fastboot` / `Invoke-Root` sarmalayıcılarını
kullanır. Cihaz birden fazlaysa betikler hata verir; tek cihaz bağlayın.
