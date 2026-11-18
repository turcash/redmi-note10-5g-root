# 04 — Doğrulama

Kurulumun gerçekten çalıştığını kanıtlamak için aşağıdaki kontrolleri sırayla
yapın. Beklenen çıktılar bu cihazda alınmış **gerçek** çıktılardır.

---

## 1. Bağlantı

```powershell
adb devices -l
```

Beklenen (seri kısaltılmış):

```text
eeae...9ea   device usb:... product:treble_arm64_bvS model:note10 device:phhgsi_arm64_ab
```

`unauthorized` görünüyorsa telefondaki RSA istemini onaylayın.
`offline` görünüyorsa `adb kill-server` + `adb start-server` deneyin.

---

## 2. Cihaz kimliği

```powershell
adb shell getprop ro.product.vendor.device   # camellia
adb shell getprop ro.boot.hardware           # mt6833
adb shell getprop ro.board.platform          # mt6833
adb shell getprop ro.build.version.release   # 12
adb shell getprop ro.build.version.sdk       # 31 veya 32
adb shell getprop ro.build.product           # treble_arm64_bvS
adb shell getprop ro.product.device          # phhgsi_arm64_ab
```

> `ro.product.model=note10` ve `ro.product.device=phhgsi_arm64_ab` GSI'dan gelir;
> cihazın gerçek kimliği **vendor** katmanındadır.

---

## 3. Root

```powershell
adb shell su -c id
```

Beklenen:

```text
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
```

Kontroller:

| Kontrol | Beklenen | Anlamı |
|---|---|---|
| `uid=0` | Evet | Gerçek root |
| `context=u:r:magisk:s0` | Evet | Root Magisk'ten geliyor |
| `context=u:r:shell:s0` | Hayır | Root yok, yalnızca adb shell |

Magisk sürümü ve yolu:

```powershell
adb shell su -c magisk -v          # 31.0
adb shell su -c magisk --path
adb shell su -c magisk --list
```

Süper kullanıcı veritabanı:

```powershell
adb shell su -c ls -l /data/adb/magisk.db
```

---

## 4. Modüller

```powershell
adb shell su -c ls /data/adb/modules
```

Bu cihazda beklenen:

```text
camellia-wifi-fix
wifi-bekci
kabuk-sunucu
```

Tek tek durum:

```powershell
adb shell su -c cat /data/adb/modules/wifi-bekci/module.prop
adb shell su -c cat /data/adb/modules/camellia-wifi-fix/module.prop
```

`disable` adlı dosya varsa modül devre dışıdır:

```powershell
adb shell su -c ls /data/adb/modules/wifi-bekci/disable
```

---

## 5. Kablosuz ADB

Bu cihazda kalıcı olarak açıldı:

```powershell
adb shell su -c getprop persist.adb.tcp.port   # 5555
```

Sıfırdan açmak için:

```powershell
adb shell su -c "setprop persist.adb.tcp.port 5555"
adb tcpip 5555
adb connect <phone-ip>:5555
adb devices
```

IP'yi öğrenmek için:

```powershell
adb shell ip -4 addr show wlan0
```

> `persist.*` özelliği yeniden başlatmada korunur. Bu, cihazı ağda sürekli
> dinleyen bir ADB portu bırakır. Güvenlik için bkz. 08-guvenlik.md.

---

## 6. Wi-Fi düzeltmesi

```powershell
adb shell su -c "iw dev wlan0 get power_save"   # Power save: off
adb shell su -c "iw dev wlan0 link"
adb shell su -c "head -40 /data/local/tmp/camellia-wifi-fix.log"
adb shell su -c "tail -5 /data/local/tmp/camellia-wifi-perf.csv"
```

Beklenen:

```text
Connected to xx:xx:xx:xx:xx:xx
freq: 5xxx
signal: -5x dBm
Power save: off
```

Performans CSV'sinde `ping_ort` düşük (birkaç ms) olmalıdır.

---

## 7. Wi-Fi bekçisi

```powershell
adb shell su -c "cat /data/adb/modules/wifi-bekci/module.prop"
adb shell su -c "tail -20 /data/local/tmp/wifi-bekci.log"
```

Logda `basladi` ve gerekiyorsa `baglanti yok -> tarama` / `Wi-Fi kapat/ac`
satırları görünür. Normalde 15 saniyede bir tur atar.

---

## 8. Tek komutla özet

```powershell
.\scripts\04-dogrula.ps1
```

Betik; cihaz kimliği, root, Magisk sürümü, modüller, ADB TCP portu ve Wi-Fi
güç tasarrufu kontrollerini yapıp `PASS/FAIL` özeti verir.

---

## 9. Örnek tam doğrulama çıktısı

```text
== Cihaz
[OK]  model                : note10
[OK]  vendor.device        : camellia
[OK]  boot.hardware        : mt6833
[OK]  android              : 12
[OK]  build.product        : treble_arm64_bvS

== Root
[OK]  su -c id             : uid=0(root) ... context=u:r:magisk:s0
[OK]  magisk -v            : 31.0

== Moduller
[OK]  camellia-wifi-fix
[OK]  wifi-bekci

== Ag
[OK]  persist.adb.tcp.port : 5555
[OK]  wlan0 power_save     : off

SONUC: 11/11 PASS
```

---

## 10. Sıradaki adım

[docs/05-moduller.md](05-moduller.md)
