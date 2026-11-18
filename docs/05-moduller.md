# 05 — Magisk modülleri

Root'un asıl faydası modüllerle başlar. Bu depoda, bu cihaz için yazılmış iki
modülün **kaynağı** var. Her ikisi de Magisk'in standart modül yapısını kullanır.

---

## 1. Magisk modülü nasıl çalışır?

Bir modül, `magisk --install-module <zip>` ile kurulan bir zip'tir. Zip'in
**kökünde** şu dosyalar bulunur:

| Dosya | Görev | Zorunlu |
|---|---|---|
| `module.prop` | Kimlik, sürüm, açıklama | ✅ |
| `service.sh` | Açılışta çalışan betik (root) | ❌ |
| `post-fs-data.sh` | `/data` bağlanmadan önce çalışır | ❌ |
| `system.prop` | Sistem özellikleri | ❌ |
| `customize.sh` | Kurulum sırasında çalışır | ❌ |
| `uninstall.sh` | Kaldırma sırasında çalışır | ❌ |
| `disable` | Varsa modül devre dışı | ❌ |

`service.sh`, Android açılışı tamamlandıktan sonra **root** olarak çalışır.
Bu yüzden modüller güçlüdür; yalnızca kaynağını bildiğiniz modülleri kurun.

### Kurulum

```powershell
adb push .\modul.zip /data/local/tmp/
adb shell su -c "magisk --install-module /data/local/tmp/modul.zip"
adb reboot
```

### Geçici devre dışı bırakma

```powershell
adb shell su -c "touch /data/adb/modules/<id>/disable"
adb reboot
```

### Kaldırma

```powershell
adb shell su -c "rm -rf /data/adb/modules/<id>"
# veya bir sonraki açılışta:
adb shell su -c "magisk --remove-modules"
```

> `magisk --remove-modules` bir sonraki yeniden başlatmada **tüm** modülleri
> kaldırır. Tek modül için `rm -rf` daha güvenlidir.

---

## 2. `camellia-wifi-fix` 0.3

### Sorun

MTK Wi-Fi sürücüsü ekran kapanınca veya boştayken agresif güç tasarrufuna
giriyor; `SETSUSPENDMODE` ve DTIM dinlemesi gecikmeyi artırıyor. Sonuç: yüksek
ping, paket kaybı, kopmalar.

### Çözüm

Modül açılışta ve 10 saniyede bir şunları uygular:

```sh
settings put global wifi_suspend_optimizations_enabled 0
settings put global wifi_scan_always_enabled 0
settings put global ble_scan_always_enabled 0
iw dev wlan0 set power_save off
echo 1 > /proc/net/wlan/setCAM
iwpriv wlan0 driver "SETSUSPENDMODE 0"
iwpriv wlan0 driver "SET_MDTIM 1"
```

### Ölçüm (5 GHz, -56 dBm)

| | Ortalama ping | Maksimum |
|---|---|---|
| Modülsüz | 9.2 ms | 206 ms |
| Modüllü | 2.75 ms | 6 ms |

### Kurulum

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix -YenidenBaslat
```

Elle:

```powershell
Compress-Archive -Path .\magisk-modules\camellia-wifi-fix\* -DestinationPath .\camellia-wifi-fix.zip -Force
adb push .\camellia-wifi-fix.zip /data/local/tmp/
adb shell su -c "magisk --install-module /data/local/tmp/camellia-wifi-fix.zip"
adb reboot
```

### Doğrulama

```powershell
adb shell su -c "iw dev wlan0 get power_save"   # off
adb shell su -c "tail -20 /data/local/tmp/camellia-wifi-fix.log"
adb shell su -c "tail -3 /data/local/tmp/camellia-wifi-perf.csv"
```

> `system.prop` içindeki MTK Wi-Fi özellikleri MIUI'nin `build.prop`'undan
> alınmıştır. GSI'da eksik olan vendor özelliklerini tamamlar.

---

## 3. `wifi-bekci` 1.0

### Sorun

Wi-Fi kopuyor veya açılışta kayıtlı ağa kendiliğinden bağlanmıyor. Özellikle
7/24 çalışan bir cihazda bu, kablosuz ADB ve uzaktan erişimi koparıyor.

### Mantık (15 saniyede bir)

```text
Wi-Fi kapalı        -> aç
Bağlı değil         -> tarama tetikle (her tur)
~45 sn hâlâ yok     -> Wi-Fi kapat/aç + tara (sonra ~2 dk'da bir)
Bağlı ama gateway 3 tur yanıtsız -> kapat/aç (bayat bağlantı)
```

Android, tarama sonrası **kayıtlı ağlara** kendiliğinden bağlanır; modül yeni
ağ oluşturmaz, yalnızca mevcut kayıtlı ağa dönüşü hızlandırır.

### Kurulum

```powershell
.\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci -YenidenBaslat
```

### Doğrulama

```powershell
adb shell su -c "tail -20 /data/local/tmp/wifi-bekci.log"
```

Test: Wi-Fi'yi kapatın, ~20 saniye içinde kayıtlı ağa dönmelidir.

### `camellia-wifi-fix` ile ilişkisi

İki modül çakışmaz: `camellia-wifi-fix` güç/gecikme ayarlarını uygular,
`wifi-bekci` ise yeniden bağlanmayı yönetir. Aynı anda kullanılabilir.

---

## 4. `kabuk-sunucu` (harici)

Bu cihazın asıl amacı 7/24 çalışan bir sunucuya dönüşmek. `kabuk-sunucu`
modülü, `/data/kabuk/bin/kabuk-boot` betiğini açılışta başlatır; kilit ekranı
ve uygulama açılmadan servisler ayağa kalkar.

Kaynağı ayrı bir projededir; bu depoda yalnızca ADI geçer. Kurulumu:

```powershell
adb shell su -c "ls /data/adb/modules/kabuk-sunucu"
adb shell su -c "/data/kabuk/bin/kabuk status"
```

---

## 5. Modül geliştirme ipuçları

- `service.sh` **root** çalışır; `su` çağırmayın.
- Sonsuz döngüde `sleep` kullanın; CPU'yu meşgul etmeyin.
- Log'u `/data/local/tmp/` altında tutun ve boyut sınırı koyun.
- Açılışta servislerden önce bekleyin:

  ```sh
  until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
  ```

- `uninstall.sh` içinde değiştirdiğiniz global ayarları geri alın.
- Modül zip'inde **üst klasör olmamalı**; `module.prop` zip kökünde olmalı.
  `Compress-Archive -Path .\modul\*` bunu sağlar.

---

## 6. Sıradaki adım

Sorun çıkarsa: [docs/06-sorun-giderme.md](06-sorun-giderme.md)
