# 02 — Magisk ile kalıcı root

Bu cihazda root, **MIUI 13 üzerinde** ve **GSI kurulmadan önce** yapıldı:

```text
Magisk 31.0, boot_a yamali
```

GSI kurulumu `boot` bölümüne dokunmadığı için root korundu. Bu bölüm, aynı
yöntemi sıfırdan uygulamak isteyenler içindir.

> ⚠️ Yanlış `boot.img` yazmak cihazı açılmaz hale getirir. **Aynı yazılım
> sürümünden** alınmış `boot.img` kullanın. Elinizde stok `boot.img` yedeği
> yoksa önce onu edinin.

---

## 1. Neden `boot` yamalı?

Magisk "systemless" çalışır: `/system` değiştirilmez, root `boot` içindeki
ramdisk'e enjekte edilir. Bu sayede:

- GSI kurulumu (`system` değişimi) root'u **silmez**.
- Fabrika güncellemesi yapılmadığı sürece kalıcıdır.
- Geri almak için stok `boot.img` yazmak yeterlidir.

Alternatif olarak `vendor_boot` yamalama yöntemi de vardır; ancak bu cihazda
çalışan yöntem `boot_a` yamalamadır.

---

## 2. Doğru `boot.img`'yi edinme

### Yol A — Fastboot ROM'dan (önerilen)

1. Cihazın **tam olarak** mevcut sürümünü öğrenin:

   ```powershell
   adb shell getprop ro.build.version.incremental
   adb shell getprop ro.build.display.id
   ```

   Bu cihazda: `V13.0.2.0.SKSMIXM`

2. Aynı sürümün **fastboot ROM** paketini indirin (tgz).
3. `payload.bin` dosyasını çıkarın ve `boot.img`'yi ayırın:

   ```powershell
   payload-dumper-go -o cikti payload.bin
   ```

   `cikti\boot.img` oluşur.

### Yol B — Cihazdan (root varsa)

Root zaten varsa (ör. eski Magisk kurulumu):

```powershell
adb shell su -c "dd if=/dev/block/by-name/boot_a of=/sdcard/boot_a.img"
adb pull /sdcard/boot_a.img
```

> Root yoksa bu yol çalışmaz; `dd` izni reddedilir. O durumda Yol A'yı kullanın.

### Doğrulama

```powershell
Get-FileHash .\boot.img -Algorithm SHA256
```

Boyut genellikle 32–64 MiB aralığındadır ve Android boot header ile başlar
(`ANDROID!`).

---

## 3. Magisk ile yamalama

1. `Magisk.apk`'yı cihaza kurun (bu cihazda **31.0**):

   ```powershell
   adb install .\Magisk.apk
   ```

2. Magisk uygulamasını açın.
3. **Magisk → Yükle (Install) → Bir dosyayı seç ve yamala**.
4. `boot.img`'yi seçin.
5. İşlem bitince oluşan dosyayı (genellikle
   `/sdcard/Download/magisk_patched-<surum>_<id>.img`) bilgisayara çekin:

   ```powershell
   adb pull /sdcard/Download/magisk_patched-31000_xxxxx.img .
   ```

6. Dosya adını sadeleştirin: `magisk_patched.img`

---

## 4. Yamalı boot'u yazma

```powershell
adb reboot bootloader
fastboot devices
fastboot getvar current-slot
```

Aktif slot `a` ise:

```powershell
fastboot flash boot magisk_patched.img
```

A/B cihazlarda `flash boot` aktif slota yazar. Daha açık olmak isterseniz:

```powershell
fastboot flash boot_a magisk_patched.img
```

> **Yapmayın:** `fastboot flash boot` yerine yanlış slotu (`boot_b`) yazmayın.
> Aktif slot dışındaki slota yazmak, sonraki slot değişiminde sorun çıkarır.

Ardından:

```powershell
fastboot reboot
```

İlk açılış normalden uzun sürebilir (1–3 dk).

---

## 5. Root doğrulama

Cihaz açıldıktan sonra:

```powershell
adb devices
adb shell getprop sys.boot_completed
adb shell su -c id
```

Beklenen çıktı:

```text
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
```

`context=u:r:magisk:s0` görülüyorsa root **Magisk tarafından** veriliyor demektir.
İlk `su` çağrısında telefonda "Süper kullanıcı izni" istemi çıkabilir; **İzin ver**.

Magisk sürümü:

```powershell
adb shell su -c magisk -v
# 31.0
```

Magisk kurulum durumu:

```powershell
adb shell su -c magisk --path
adb shell su -c ls -l /data/adb/magisk
```

---

## 6. Root kaybolursa

| Belirti | Neden | Çözüm |
|---|---|---|
| `su: not found` | Magisk aktif değil | Magisk uygulamasını aç; gerekirse yamalı boot'u tekrar yaz |
| `Permission denied` | Süper kullanıcı izni verilmemiş | Magisk → Süper kullanıcı → izin ver |
| `context=u:r:shell:s0` | Root yok, yalnızca adb shell | boot yaması uygulanmamış |
| Açılışta bootloop | Yanlış boot.img | Stok `boot.img`'yi fastboot ile geri yaz |

Stok boot'a dönüş:

```powershell
fastboot flash boot stok_boot.img
fastboot reboot
```

---

## 7. GSI öncesi kontrol listesi

- [ ] `su -c id` → `uid=0` ve `u:r:magisk:s0`
- [ ] `magisk -v` sürümü görünüyor
- [ ] Stok `boot.img` yedeği bilgisayarda duruyor
- [ ] `vbmeta_a` yedeği var
- [ ] Cihaz şarjı %50'nin üzerinde
- [ ] USB kablo sağlam, veri aktarımı yapıyor

Hepsi tamamsa: [docs/03-gsi.md](03-gsi.md)
