# Magisk modülleri

Bu klasörde, Redmi Note 10 5G (`camellia`) için yazılmış iki Magisk modülünün
**kaynağı** bulunur. İkisi de bu cihazda test edildi.

| Modül | Sürüm | Görev |
|---|---|---|
| `camellia-wifi-fix` | 0.3 | MTK Wi-Fi güç tasarrufunu/uyku modunu kapatır, gecikmeyi düşürür |
| `wifi-bekci` | 1.0 | Wi-Fi kopunca kayıtlı ağa otomatik geri bağlar |

## Kurulum

```powershell
# Tek modul
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat

# Ikisi birden
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci -YenidenBaslat
```

Elle zip'leyip kurmak için:

```powershell
Compress-Archive -Path .\magisk-modules\wifi-bekci\* -DestinationPath .\wifi-bekci.zip -Force
adb push .\wifi-bekci.zip /data/local/tmp/
adb shell su -c "magisk --install-module /data/local/tmp/wifi-bekci.zip"
adb reboot
```

> Zip'in **kökünde** `module.prop` olmalıdır. `Compress-Archive -Path .\modul\*`
> bunu sağlar; `.\modul` klasörünü doğrudan sıkıştırmak üst klasör oluşturur ve
> Magisk modülü tanımaz.

## Doğrulama

```powershell
adb shell su -c "ls /data/adb/modules"
adb shell su -c "iw dev wlan0 get power_save"      # off
adb shell su -c "tail -20 /data/local/tmp/wifi-bekci.log"
adb shell su -c "tail -20 /data/local/tmp/camellia-wifi-fix.log"
```

## Kaldırma / devre dışı bırakma

```powershell
# Gecici devre disi (yeniden baslatinca etkin olur)
adb shell su -c "touch /data/adb/modules/wifi-bekci/disable"
adb reboot

# Kalici kaldirma
adb shell su -c "rm -rf /data/adb/modules/wifi-bekci"
```

`camellia-wifi-fix` kaldırılırken `uninstall.sh` şu ayarı geri alır:

```sh
settings put global wifi_suspend_optimizations_enabled 1
```
