# 01 — Bootloader açma

Bu cihazda bootloader **zaten açıktı** (`ro.boot.flash.locked=0`). Bu bölüm,
aynı cihazı sıfırdan hazırlayanlar için referanstır. Politikalar değişebilir;
her zaman Xiaomi'nin resmî sayfasını esas alın.

> ⚠️ Bootloader açmak **tüm verileri siler**, garantiyi geçersiz kılabilir ve
> Widevine L1'i kaybettirir. Ayrıca açılışta "orange state" uyarısı görünür.

---

## 1. Ön koşullar

| Gereksinim | Açıklama |
|---|---|
| Mi hesabı | Cihazda oturum açılmış, en az 30 günlük hesap |
| Mi Unlock Tool | Xiaomi'nin resmî aracı (Windows) |
| USB hata ayıklama | Açık |
| OEM kilidi açma | Açık (Geliştirici seçenekleri) |
| SIM / internet | Hesap doğrulaması için gerekebilir |
| Bekleme süresi | MIUI'de genellikle **168 saat (7 gün)**; modele/sürüme göre değişir |

> **2025–2026 notu:** Xiaomi, HyperOS ile bootloader açma kurallarını ciddi
> biçimde sıkılaştırdı (Xiaomi Community seviyesi, 30 günlük bekleme, yıllık
> kota vb.). Bu cihaz MIUI 13 üzerinde açıldığı için klasik Mi Unlock akışı
> geçerliydi. Güncel kurallar için:
> <https://en.miui.com/unlock/>

---

## 2. Cihaz tarafı hazırlık

1. **Ayarlar → Telefon hakkında → MIUI sürümü**'ne 7 kez dokunun.
2. **Ayarlar → Ek ayarlar → Geliştirici seçenekleri**:
   - **USB hata ayıklama** → açık
   - **OEM kilidi açma** → açık
   - **Mi Hesabı ile ilişkilendir** (Mi Unlock durumu) → hesabı ekleyin
3. Cihazı internete bağlayın ve hesabın senkronize olmasını bekleyin.
4. Gerekirse **Ayarlar → Şifreler ve güvenlik → Gizlilik → Cihazı bul**'u kapatın
   (bazı MIUI sürümlerinde unlock'ı engeller).

### Doğrulama

```powershell
adb shell getprop ro.boot.flash.locked   # 1 = kilitli, 0 = acik
adb shell getprop ro.secureboot.lockstate
adb shell settings get global oem_unlock_allowed
```

---

## 3. Mi Unlock Tool ile açma

1. Mi Unlock Tool'u indirip kurun: <https://en.miui.com/unlock/>
2. Cihazı kapatın.
3. **Ses Kıs + Güç** basılı tutarak **FASTBOOT** ekranına girin.
4. USB ile bağlayın.
5. Mi Unlock'a aynı Mi hesabıyla giriş yapın.
6. Araç cihazı tanıyacak ve kalan süreyi gösterecek.
7. Süre dolduğunda **Unlock**'a basın. Cihaz verileri silerek yeniden başlar.

### Süreç sonrası kontrol

```powershell
fastboot devices
fastboot getvar unlocked
fastboot getvar secure
fastboot oem device-info
```

Beklenen:

```text
unlocked: yes
secure: no
(bootloader) Device unlocked: true
```

> `Device unlocked: false` veya `unlocked: no` görüyorsanız **devam etmeyin**.
> Kilitli bootloader'a yazma denemesi `FAILED (remote: 'Flashing is not allowed')`
> hatası verir; zorlamak cihazı tuğlaya çevirebilir.

---

## 4. Açılış uyarısı (normaldir)

Bootloader açıkken cihaz açılışta şu tarz bir uyarı gösterebilir:

```text
The bootloader is unlocked and software integrity cannot be guaranteed.
```

Bu bir arıza değildir. Kilit **tekrar kapatılmamalıdır** (özellikle GSI/Magisk
sonrası); `fastboot flashing lock` bu cihazda tuğlaya yol açabilir.

---

## 5. Sık yapılan hatalar

| Hata | Neden / çözüm |
|---|---|
| `fastboot devices` boş | Sürücü, kablo, USB 2.0 portu; `fastboot --version` kontrol |
| Mi Unlock "current account cannot unlock" | Hesap yaşı, bölge veya kota; resmî kurallara bakın |
| "Could not verify account" | Cihazda Mi hesabı oturumu ve internet |
| Süre bitmeden tekrar deneme | Kalan saat sıfırlanabilir; acele etmeyin |
| `FAILED (remote: 'Flashing is not allowed')` | Bootloader hâlâ kilitli |
| Açılışta bootloop | Yanlış `boot`/`vbmeta`; stok imajla geri dönün |

---

## 6. Sıradaki adım

Bootloader açıksa: [docs/02-magisk-root.md](02-magisk-root.md)
