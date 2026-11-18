# 03 — phh AOSP 12.1 GSI kurulumu

Bu cihazda MIUI kaldırılıp **phh AOSP 12.1 v416 vanilla** GSI kuruldu.
Amaç, Android'i yalnızca sürücü katmanı olarak kullanıp üstte Alpine chroot /
sunucu işlerini çalıştırmaktı. GSI **vanilla** seçildi: Google uygulamaları yok,
gereksiz servis yok.

| | |
|---|---|
| İmaj | `system-squeak-arm64-ab-vanilla.img` |
| Sürüm | phh AOSP 12.1 v416 (vanilla) |
| Boyut | 1 815 252 992 bayt |
| SHA-256 | `3394888867eb48b21d91ae2885ba1664d3b71c1ccaacc389833445be674fb4a6` |
| Hedef | `system` (mantıksal, `super` içinde) |
| Slot | `a` |

> ⚠️ Bu adım `system` bölümünü siler ve `fastboot -w` ile **tüm verileri**
> temizler. Yedek almadan başlamayın.

---

## 1. Ön koşullar

- Bootloader açık (`unlocked: yes`)
- `boot_a` Magisk ile yamalı (root korunacak)
- `vbmeta.img` = cihazın **kendi** stok `vbmeta_a` yedeği
- GSI imajı ve SHA-256 doğrulanmış
- platform-tools güncel (`fastboot --version`)
- Cihaz şarjı ≥ %50

### Dosya doğrulama

```powershell
Get-FileHash .\system-squeak-arm64-ab-vanilla.img -Algorithm SHA256
# 3394888867eb48b21d91ae2885ba1664d3b71c1ccaacc389833445be674fb4a6

Get-FileHash .\vbmeta.img -Algorithm SHA256
# c9a5b9c74ce8a5d34c797ba0446733daf86e7e5d3cf17219dbb6245fe5ef1eb7
```

---

## 2. Fastboot'a gir

Cihazı kapatın. **Ses Kıs + Güç** basılı tutun. `FASTBOOT` yazısı çıkınca
USB'ye bağlayın.

```powershell
fastboot devices
fastboot getvar current-slot     # a
fastboot getvar unlocked         # yes
fastboot getvar product          # camellia
```

`unlocked: no` ise **dur**.

---

## 3. vbmeta doğrulamasını kapat

AVB (Android Verified Boot), imzasız/değiştirilmiş `system` ve `boot` ile
açılışı engeller. GSI ve Magisk için doğrulama kapatılmalıdır.

```powershell
fastboot --disable-verity --disable-verification flash vbmeta .\vbmeta.img
```

Bu komut, stok `vbmeta` imajını yazarken bayrakları "doğrulama kapalı" olacak
şekilde değiştirir. Çıktıda `OKAY` görülmelidir.

> Bu adım atlanırsa açılışta "dm-verity corruption" / "device is corrupt"
> ekranı çıkar veya sistem açılmaz.

---

## 4. fastbootd'ye geç

Mantıksal bölümler (`system`, `product`) yalnızca **fastbootd** üzerinden
yazılabilir.

```powershell
fastboot reboot fastboot
fastboot devices
fastboot getvar is-userspace     # yes olmali
```

Ekranda `fastbootd` yazmalıdır.

### Windows'ta cihaz görünmüyorsa

Aygıt Yöneticisi → bilinmeyen cihaz → **Sürücüyü güncelle → Bilgisayarımdaki
sürücülere göz at → Listeden seç → Android Bootloader Interface**.

---

## 5. Bölüm hazırlığı

```powershell
fastboot set_active a
fastboot delete-logical-partition product
fastboot erase system
```

- **`set_active a`**: Bu cihazda çalışan slot `a`. Diğer slota yazıp aktif
  bırakmak karışıklığa yol açar.
- **`delete-logical-partition product`**: GSI 1.8 GB olduğu için `super`
  içinde yer açılır. `product` bu cihazda kullanılmıyor.
- **`erase system`**: Eski MIUI sistemini temizler; ardından yazılacak.

> `delete-logical-partition product` hata verirse `fastboot getvar
> partition-size:product_a` ile bölümün gerçekten silindiğini kontrol edin.
> Hâlâ yer yoksa **durup** inceleyin; rastgele başka bölüm silmeyin.

---

## 6. GSI'yi yaz

```powershell
fastboot flash system .\system-squeak-arm64-ab-vanilla.img
```

- 1.8 GB'lık imaj olduğu için işlem 1–3 dakika sürebilir.
- `invalid sparse file format` uyarısı **normaldir**; fastboot ham imajı
  parçalayarak yazar.
- `Not enough space to resize partition` hatası → `product` silinmemiş demektir.
  Adım 5'i tekrarlayın; hâlâ olmuyorsa durun.

---

## 7. Veriyi temizle ve başlat

```powershell
fastboot -w
fastboot reboot
```

- `-w` komutu `userdata` ve `metadata` bölümlerini temizler.
- İlk açılış **3–5 dakika** sürebilir. Boot animasyonunda kalması normaldir.
- 10 dakikadan uzun sürerse 06-sorun-giderme.md'ye bakın.

---

## 8. Açılış sonrası

1. Kurulum sihirbazını geçin (Google hesabı **gerekmez**, vanilla imaj).
2. **Ayarlar → Telefon hakkında → Derleme numarası**'na 7 kez dokunun.
3. **Geliştirici seçenekleri → USB hata ayıklama** açın.
4. Bilgisayardan gelen RSA iznini onaylayın.

```powershell
adb devices
adb shell getprop ro.build.product        # treble_arm64_bvS
adb shell getprop ro.product.device       # phhgsi_arm64_ab
adb shell getprop ro.build.version.release # 12
```

### Root hâlâ yerinde mi?

GSI `boot` bölümüne dokunmadığı için Magisk korunmuş olmalı:

```powershell
adb shell su -c id
# uid=0(root) ... context=u:r:magisk:s0
```

`su` yoksa Magisk uygulamasını kurup daha önce yamaladığınız `boot.img`'yi
yeniden yazın (bkz. 02-magisk-root.md).

### phh Treble ayarları

Ekran/parlaklık ve MediaTek davranışları için:

**Ayarlar → Phh Treble Settings**

| Sorun | Ayar |
|---|---|
| Parlaklık titriyor | Misc → *Force alternative backlight scale*, *Use linear screen brightness slider* |
| Wi-Fi sorunları | MediaTek seçenekleri + `camellia-wifi-fix` modülü (bkz. 05) |
| Kamera | Misc → kamera HAL seçenekleri |
| Ses | Audio → uygun HAL |

---

## 9. Neden `boot` yazılmıyor?

GSI yalnızca `system` bölümünü değiştirir. `boot_a` içindeki Magisk yamalı
ramdisk olduğu gibi kalır. Bu yüzden:

- Root GSI'da da çalışır.
- Geri dönmek için GSI'yı silmek yeterli değildir; MIUI `system` imajı gerekir.
- GSI'nın kendi `boot.img`'sini **yazmayın**; yazarsanız root kaybolur.

---

## 10. Sıradaki adım

[docs/04-dogrulama.md](04-dogrulama.md)
