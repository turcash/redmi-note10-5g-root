# 06 — Sorun giderme

Belirtiye göre arayın. Her satırda **neden** ve **ne yapmalı** var.
Emin değilseniz cihaza yazmayın; önce `fastboot getvar all` ve hata mesajını
kaydedin.

---

## Bağlantı / sürücü

| Belirti | Neden | Çözüm |
|---|---|---|
| `adb devices` boş | USB hata ayıklama kapalı, kablo veri desteklemiyor, sürücü yok | Kabloyu değiştirin, USB hata ayıklamayı açın, Google USB Driver kurun |
| `unauthorized` | RSA izni verilmemiş | Telefondaki istemi onaylayın; `adb kill-server` sonra tekrar |
| `offline` | adb sunucusu takıldı | `adb kill-server`, `adb start-server` |
| `fastboot devices` boş | Bootloader sürücüsü yok / yanlış mod | Aygıt Yöneticisi → **Android Bootloader Interface** seçin; USB 2.0 portu deneyin |
| fastbootd görünmüyor | fastbootd sürücüsü farklı | Aynı yöntemle sürücüyü güncelleyin; `fastboot getvar is-userspace` ile modu doğrulayın |
| Cihaz sürekli yeniden bağlanıyor | Güç/USB portu yetersiz | Hub kullanmayın; doğrudan anakart portu |

---

## Fastboot hataları

| Hata | Neden | Çözüm |
|---|---|---|
| `FAILED (remote: 'Flashing is not allowed')` | Bootloader kilitli | **Durdurun.** Önce bootloader açılmalı. Zorlamayın. |
| `FAILED (remote: 'unknown command')` | Eski fastboot | platform-tools'u güncelleyin |
| `cannot load '...'` | Yol/uzantı hatası | Dosya yolunu tırnak içine alın; dosyanın gerçekten var olduğunu kontrol edin |
| `invalid sparse file format` | Ham (sparse olmayan) imaj | **Normal**, yazmaya devam eder |
| `Not enough space to resize partition` | `product` silinmemiş | `fastboot delete-logical-partition product` tekrar; `partition-size:product_a` kontrol |
| `FAILED (remote: 'partition table doesn't exist')` | Yanlış mod (fastbootd gerekli) | `fastboot reboot fastboot` |
| `fastboot: error: Failed to boot into userspace fastboot` | `super`/`misc` bozuk | Stok `boot`/`vbmeta` ile geri dönün |

---

## Açılış sorunları

| Belirti | Neden | Çözüm |
|---|---|---|
| Bootloop / logo > 10 dk | `vbmeta` doğrulaması açık, eksik `-w`, bozuk system | Fastboot → `--disable-verity --disable-verification flash vbmeta`, sonra `-w` ve reboot |
| "dm-verity corruption" / "device is corrupt" | AVB kapatılmamış | Adım 3'ü (vbmeta) tekrarlayın |
| "No valid slot to boot" | Aktif slot boş | `fastboot set_active a`; gerekirse stok `boot_a` yazın |
| Sürekli fastboot'a düşüyor | `boot_a` yanlış/bozuk | Stok `boot.img` yazın |
| Açılıyor ama dokunmatik yok | Vendor/firmware uyumsuzluğu | Stok `vendor_boot`/`dtbo` yedeğini kontrol edin |
| Şifreleme hatası | `-w` yapılmamış | `fastboot -w` (veriler silinir) |

**Altın kural:** Açılmıyorsa önce **stok `boot_a`** ve **stok `vbmeta_a`**
yazıp deneyin. `system`'e dokunmadan da açılış test edilebilir (MIUI stok
system'i geri yüklenerek).

---

## Root sorunları

| Belirti | Neden | Çözüm |
|---|---|---|
| `su: not found` | Magisk aktif değil | Yamalı `boot.img`'yi tekrar yazın; Magisk uygulamasını açın |
| `su` var ama izin yok | Süper kullanıcı izni verilmemiş | Magisk → Süper kullanıcı → uygulamaya izin ver |
| `context=u:r:shell:s0` | Root yok | `boot` yaması uygulanmamış |
| Magisk "N/A" gösteriyor | Yamalı boot yüklenmemiş | Doğru sürümden alınmış `boot.img` ile tekrar yamalayın |
| GSI sonrası root gitti | GSI'nın `boot.img`'si yazılmış | Yamalı `boot_a`'yı geri yazın |
| Modül kurulmuyor | Zip kökünde `module.prop` yok | Zip'i `modul\*` ile oluşturun |

---

## Wi-Fi

| Belirti | Neden | Çözüm |
|---|---|---|
| Wi-Fi açılmıyor | Vendor sürücü/GSI uyumsuzluğu | `camellia-wifi-fix` kurun; Phh MediaTek ayarlarını deneyin |
| Yüksek ping / kopma | MTK güç tasarrufu | `camellia-wifi-fix`; `iw dev wlan0 get power_save` → `off` |
| Açılışta bağlanmıyor | Tarama/bağlanma gecikmesi | `wifi-bekci` modülü |
| Bağlı ama internet yok | Bayat gateway | `wifi-bekci` gateway ping kontrolü; router'ı kontrol edin |
| 5 GHz görünmüyor | Bölge/kanal | Router kanalını 36–64 aralığına alın |

Log'lar:

```powershell
adb shell su -c "tail -50 /data/local/tmp/camellia-wifi-fix.log"
adb shell su -c "tail -50 /data/local/tmp/wifi-bekci.log"
```

---

## Ekran / duyusal

| Belirti | Çözüm |
|---|---|
| Parlaklık titriyor | Phh Treble Settings → Misc → *Force alternative backlight scale* + *Use linear screen brightness slider* |
| Otomatik parlaklık çalışmıyor | Aynı menüde alternatif ölçek |
| Dokunmatik kayması | Phh → Misc → dokunmatik kalibrasyon |
| Ses gelmiyor | Phh → Audio HAL; `vendor` uyumu |

---

## ADB / ağ

| Belirti | Neden | Çözüm |
|---|---|---|
| Kablosuz ADB kopuyor | Wi-Fi uyku/kopma | `wifi-bekci` + `camellia-wifi-fix` |
| `connection refused` | Port değişmiş / adbd kapalı | Telefonda kablosuz hata ayıklamayı açın; yeni portu kullanın |
| IP değişiyor | DHCP | Router'da MAC rezervasyonu yapın |
| `adb connect` sonrası `offline` | Farklı RSA anahtarı | `adb kill-server`; telefondaki eski anahtarı kaldırın |

---

## Son çare: stok boot'a dönüş

```powershell
fastboot devices
fastboot flash boot stok_boot.img
fastboot flash vbmeta stok_vbmeta.img
fastboot reboot
```

Hâlâ açılmıyorsa [docs/07-geri-donus.md](07-geri-donus.md) ile MIUI'ye dönün.

> **Asla** `fastboot flashing lock` çalıştırmayın. Bu cihazda kilidi geri
> kapatmak, imzasız `boot`/`system` nedeniyle tuğlaya yol açabilir.
