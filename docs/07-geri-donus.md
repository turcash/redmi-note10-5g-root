# 07 — MIUI'ye geri dönüş

GSI'dan MIUI'ye dönmek için **tam bölüm yedeği** gerekir. Bu cihazda 69 bölümün
yedeki alınmıştı (`bolumler/*.img.gz`). Yedek yoksa geri dönüş, doğru
sürümdeki fastboot ROM ile yapılabilir; ancak IMEI/persist gibi bölümler
**asla** fastboot ROM'dan yazılmamalıdır.

> ⚠️ Geri dönüş **tüm verileri siler**. Ayrıca yanlış bölüm yazmak cihazı
> kalıcı olarak bozabilir. Yalnızca aşağıdaki listede olan bölümleri yazın.

---

## 1. Gerekli dosyalar

`bolumler\` klasöründe (gzip'li):

```text
super.img.gz
vbmeta_a.img.gz
vbmeta_system_a.img.gz
vbmeta_vendor_a.img.gz
boot_a.img.gz
dtbo_a.img.gz
vendor_boot_a.img.gz
```

Yedek bütünlüğünü doğrulayın:

```powershell
cd D:\Yedek
Get-Content bolumler\SHA256SUMS -ErrorAction SilentlyContinue
Get-Content SHA256SUMS.all | Select-String 'super|vbmeta|boot_a|dtbo|vendor_boot'
```

---

## 2. Gzip'leri açın

PowerShell ile:

```powershell
$src = 'D:\Yedek\bolumler'
$dst = 'D:\Yedek\acik'
New-Item -ItemType Directory -Force -Path $dst | Out-Null

Add-Type -AssemblyName System.IO.Compression
Get-ChildItem $src -Filter *.img.gz | ForEach-Object {
    $out = Join-Path $dst ($_.Name -replace '\.gz$', '')
    $in  = [IO.File]::OpenRead($_.FullName)
    $os  = [IO.File]::Create($out)
    $gz  = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
    $gz.CopyTo($os)
    $gz.Dispose(); $os.Dispose(); $in.Dispose()
    Write-Host "acildi: $out"
}
```

`super.img` yaklaşık **8.5 GB** olacaktır. Disk alanı yeterli olmalı.

---

## 3. Fastboot'a gir

Cihazı kapatın, **Ses Kıs + Güç** ile FASTBOOT'a girin.

```powershell
fastboot devices
fastboot getvar current-slot    # a
```

> Bu adımlar **fastbootd'de değil**, normal bootloader fastboot'unda yapılır.
> `fastboot getvar is-userspace` → `no` olmalı.

---

## 4. Geri yazma sırası

```powershell
fastboot flash super            D:\Yedek\acik\super.img
fastboot flash vbmeta_a         D:\Yedek\acik\vbmeta_a.img
fastboot flash vbmeta_system_a  D:\Yedek\acik\vbmeta_system_a.img
fastboot flash vbmeta_vendor_a  D:\Yedek\acik\vbmeta_vendor_a.img
fastboot flash boot_a           D:\Yedek\acik\boot_a.img
fastboot flash dtbo_a           D:\Yedek\acik\dtbo_a.img
fastboot flash vendor_boot_a    D:\Yedek\acik\vendor_boot_a.img
fastboot -w
fastboot reboot
```

- `super.img` ham ~8.5 GB; fastboot otomatik parçalar, sabırlı olun.
- `-w` verileri temizler; MIUI ilk açılışta kurulum sihirbazı gelir.
- İlk açılış 5–10 dakika sürebilir.

---

## 5. Otomatik betik

```powershell
.\scripts\geri-donus.ps1 -Yedek D:\Yedek
```

Betik:

1. Gerekli dosyaları kontrol eder.
2. `.gz` dosyalarını geçici klasöre açar.
3. Ekranda **GERI DON** yazmanızı ister.
4. Yalnızca yukarıdaki 7 bölümü yazar.
5. `-w` ve reboot yapar.

Yasaklı bölümler (`nvram`, `persist`, `seccfg` vb.) betikte **hiç geçmez**.

---

## 6. Geri dönüş sonrası

```powershell
adb devices
adb shell getprop ro.product.vendor.device   # camellia
adb shell getprop ro.build.version.incremental
```

MIUI açıldıysa root gitti (stok `boot_a` geri yazıldı). Yeniden root için
02-magisk-root.md'yi uygulayın.

---

## 7. Yapılmaması gerekenler

| ❌ Yapmayın | Neden |
|---|---|
| `fastboot flashing lock` | İmzasız boot/system ile tuğla riski |
| `fastboot erase nvram` / `persist` | IMEI/kalibrasyon kaybı, geri dönüşü yok |
| `fastboot flash preloader` | Boot zinciri bozulur |
| Başka cihazın `super.img`'si | Bölüm tablosu uyuşmaz |
| Yedeği doğrulamadan yazmak | Bozuk imaj = bozuk cihaz |

---

## 8. Yedek yoksa

Doğru sürümün **fastboot ROM**'unu (ör. `V13.0.2.0.SKSMIXM`) indirip stok
bölümleri yazabilirsiniz. Ancak:

- `nvram`, `nvdata`, `persist`, `seccfg` gibi bölümleri ROM'dan yazmayın.
- IMEI kaybı yasal ve teknik olarak ciddi sonuç doğurur.
- ROM sürümü cihazın bölge/modeliyle **birebir** uyumlu olmalı.

Bu durumda en güvenli yol, yetkili servis veya cihaza özel unbrick aracıdır.
