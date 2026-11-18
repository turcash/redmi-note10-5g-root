# 00 — Cihaz, bölümler ve yedek

## 1. Cihazı tanı

Root işlemine başlamadan önce cihazın **tam modelini ve kod adını** doğrulayın.
Yanlış cihaz için hazırlanmış `boot.img` veya GSI, tuğlaya yol açar.

### Hızlı kimlik kontrolü

Cihaz açıkken (adb bağlı):

```powershell
adb shell getprop ro.product.model
adb shell getprop ro.product.vendor.device
adb shell getprop ro.boot.hardware
adb shell getprop ro.board.platform
adb shell getprop ro.build.version.release
adb shell getprop ro.boot.flash.locked
```

Bu cihazda beklenen değerler:

| Özellik | Değer |
|---|---|
| Model | `M2103K19C` (China hardware) |
| Kod adı | `camellia` |
| SoC | `mt6833` (Dimensity 700) |
| Platform | `mt6833` |
| Android | `12` |
| Bootloader | `0` (açık) |
| Slot yapısı | A/B (`_a` / `_b`) |
| Dinamik bölümler | Var (`super`) |

> GSI kurulduktan sonra `ro.product.model` değeri `note10`, `ro.product.device`
> değeri `phhgsi_arm64_ab` görünür. Bu **normaldir**; ürün adı GSI'dan gelir.
> Cihaz kimliği için `ro.product.vendor.device` ve `ro.boot.hardware` kullanın.

### Fastboot'ta kimlik

```powershell
fastboot devices
fastboot getvar product
fastboot getvar current-slot
fastboot getvar unlocked
fastboot getvar is-userspace
```

- `product: camellia` olmalı.
- `unlocked: yes` olmalı. `no` ise **durun** — önce bootloader açılmalı.
- `current-slot: a` (bu cihazda aktif slot `a`).
- `is-userspace: no` → normal fastboot; `yes` → fastbootd.

---

## 2. Bölüm haritası

Bu cihaz A/B ve dinamik bölümlü olduğu için isimler `_a` / `_b` ekli olabilir.

| Bölüm | İçerik | Bu rehberde yazılır mı? |
|---|---|---|
| `boot_a` / `boot_b` | Kernel + ramdisk | ✅ Magisk yamalı imaj |
| `vbmeta_a` / `vbmeta_b` | Android Verified Boot (AVB) | ✅ Doğrulamayı kapatmak için |
| `system` | GSI hedefi (mantıksal, `super` içinde) | ✅ GSI yazılır |
| `product` | Mantıksal bölüm | ✅ **Silinir** (yer açmak için) |
| `userdata`, `metadata` | Kullanıcı verisi | ✅ `fastboot -w` ile temizlenir |
| `super` | Dinamik bölüm kabı | ⚠️ Yalnızca geri dönüşte |
| `dtbo_a`, `vendor_boot_a` | Cihaza özel | ⚠️ Yalnızca geri dönüşte |
| `nvram`, `nvdata`, `nvcfg` | IMEI / modem kalibrasyonu | ❌ **ASLA** |
| `protect1`, `protect2` | Korunan fabrika verisi | ❌ **ASLA** |
| `persist`, `persistbak` | Sensör/kamera kalibrasyonu | ❌ **ASLA** |
| `proinfo` | Ürün bilgisi | ❌ **ASLA** |
| `seccfg` | Bootloader kilit durumu | ❌ **ASLA** |
| `preloader*`, `lk*`, `tee*`, `md1img*` | Boot zinciri | ❌ **ASLA** |
| `efuse`, `otp` | Tek yazımlık donanım | ❌ **ASLA** |

**Altın kural:** Listede "yalnızca geri dönüşte" yazan bölümler dışında, bu
rehberde adı geçmeyen hiçbir bölüme yazmayın.

---

## 3. Yedek (geri dönüş için zorunlu)

Root/GSI işleminden önce **en az** şu bölümlerin yedeğini alın:

```text
super  boot_a  dtbo_a  vendor_boot_a
vbmeta_a  vbmeta_system_a  vbmeta_vendor_a
nvram  nvdata  nvcfg  protect1  protect2  persist  proinfo  seccfg
```

Bu cihazda 69 bölümün tam yedeği alındı (`bolumler/*.img.gz`) ve
`SHA256SUMS.all` ile bütünlüğü doğrulandı. Yedek **bilgisayarda** tutulmalı;
telefonda bırakılan yedek, telefon açılmazsa işe yaramaz.

### Yedek bütünlüğünü doğrulama

```powershell
cd D:\Yedek
Get-Content SHA256SUMS.all | ForEach-Object {
  $h, $f = $_ -split '\s+', 2
  $f = $f.TrimStart('.', '/') -replace '/', '\'
  $actual = (Get-FileHash $f -Algorithm SHA256).Hash.ToLower()
  if ($actual -ne $h) { "BOZUK: $f" }
}
```

Hiç `BOZUK` satırı çıkmamalıdır.

### Kritik dosyaların varlığı

```powershell
$gerekli = 'nvram','nvdata','nvcfg','protect1','protect2','persist','proinfo','seccfg','super','vbmeta_a','boot_a'
foreach ($b in $gerekli) {
  $p = "D:\Yedek\bolumler\$b.img.gz"
  if (!(Test-Path $p) -or (Get-Item $p).Length -eq 0) { "EKSIK: $b" }
}
```

---

## 4. Gerekli dosyalar

| Dosya | Nereden | SHA-256 (bu cihaz) |
|---|---|---|
| `system-squeak-arm64-ab-vanilla.img` | phhusson/treble_experimentations sürüm v416 | `3394888867eb48b21d91ae2885ba1664d3b71c1ccaacc389833445be674fb4a6` |
| `vbmeta.img` | Cihazın **kendi** stok `vbmeta_a` bölümü (8 MiB) | `c9a5b9c74ce8a5d34c797ba0446733daf86e7e5d3cf17219dbb6245fe5ef1eb7` |
| MIUI fastboot ROM | `V13.0.2.0.SKSMIXM` (aynı sürüm!) | — |
| `Magisk.apk` | topjohnwu/Magisk (bu cihazda 31.0) | — |
| `platform-tools` | Google | — |

> `vbmeta.img` başka bir cihazdan alınmamalıdır. Kendi cihazınızın stok
> `vbmeta_a` bölümünün yedeği kullanılmalıdır.

### Dosya özeti doğrulama

```powershell
Get-FileHash .\system-squeak-arm64-ab-vanilla.img -Algorithm SHA256
Get-FileHash .\vbmeta.img -Algorithm SHA256
```

---

## 5. Sürücüler (Windows)

- Google USB Driver veya Xiaomi USB Driver kurulu olmalı.
- `fastboot` modunda cihaz görünmüyorsa Aygıt Yöneticisi → bilinmeyen cihaz →
  sürücüyü elle **Android Bootloader Interface** olarak seçin.
- `fastbootd` modunda ayrı bir sürücü gerekebilir; aynı yöntemle güncelleyin.
- USB 3.x portları bazı makinelerde sorun çıkarır; **USB 2.0 portu** veya
  doğrudan anakart portu deneyin. Hub kullanmayın.

---

## 6. Sıradaki adım

Cihaz kimliği doğrulandıysa ve yedekler tamamsa:
[docs/01-bootloader.md](01-bootloader.md)
