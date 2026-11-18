# 08 — Güvenlik ve gizlilik

Root'lu bir telefon, **sizin** için güçlü; **saldırgan** için de güçlü. Bu
bölüm, bu cihazı 7/24 açık tutarken alınması gereken önlemleri özetler.

---

## 1. Tehdit modeli

Bootloader açık + AVB kapalı + Magisk root:

| Risk | Açıklama |
|---|---|
| Fiziksel erişim | Cihazı ele geçiren kişi `boot`/`system` değiştirebilir, veriyi okuyabilir |
| Doğrulanmış açılış yok | Kötü niyetli yazılım tespit edilemez |
| Root yetkisi | Herhangi bir root süreci tüm sisteme erişir |
| ADB over TCP | Aynı ağdaki biri shell açabilir (yetkilendirme olsa bile) |
| Modüller | `service.sh` root çalışır; kötü modül = tam ele geçirme |

**Sonuç:** Bu cihazı bankacılık, kimlik, sağlık gibi hassas işler için
kullanmayın; ev sunucusu / otomasyon için ayırın.

---

## 2. ADB over TCP

Bu cihazda `persist.adb.tcp.port=5555` kalıcı olarak açık. Bu, ağdaki herkese
bir ADB kapısı bırakır.

### Öneriler

- Yalnızca **güvenilir ağda** (ev LAN'ı) veya **Tailscale/WireGuard** içinde
  kullanın.
- Router'da 5555 portunu internete **yönlendirmeyin**.
- İşiniz bittiğinde kapatın:

  ```powershell
  adb shell su -c "setprop persist.adb.tcp.port ''"
  adb usb
  ```

- RSA anahtarlarını yönetin:

  ```powershell
  adb shell su -c "cat /data/misc/adb/adb_keys"
  ```

  Yabancı anahtar varsa temizleyin.

- `adb` yetkilendirmesi ilk bağlantıda sorulur; "Her zaman izin ver" seçeneğini
  yalnızca kendi bilgisayarınızda kullanın.

---

## 3. Magisk ve modüller

- Modülleri yalnızca **kaynağını gördüğünüz** yerden kurun. Bu depodaki iki
  modül denetlenebilir ve küçüktür.
- Magisk'i güncellerken dikkat: büyük sürüm atlamaları modülleri bozabilir.
- **Zygisk** ve **DenyList** bankacılık uygulamalarını gizlemez; Play Integrity
  yine başarısız olur.
- `magisk --sqlite` / `magisk.db` süper kullanıcı izinlerini tutar; yedeklerken
  hassas veri olarak değerlendirin.

---

## 4. Veri ve yedekler

- `userdata` şifrelemesi (FBE) çalışır; ancak boot zinciri güvenilir olmadığı
  için "cihaz kapalıyken güvenli" varsayımı zayıftır.
- Yedeklerde IMEI, `persist`, `nvram` gibi hassas bölümler var. Bunları
  şifreli diskte tutun, buluta yüklemeyin.
- `adb pull` ile çekilen loglarda MAC, IP, SSID, hesap adları bulunabilir;
  paylaşmadan önce temizleyin.

---

## 5. Play Integrity / DRM

| Hizmet | Durum | Neden |
|---|---|---|
| Play Integrity (basic) | Genellikle başarısız | Bootloader açık, AVB kapalı |
| SafetyNet | Kullanımdan kalktı | — |
| Widevine L1 | Kayıp (L3) | Doğrulanmış boot yok |
| Netflix HD | Çalışmaz | L3 |
| Bankacılık uygulamaları | Değişken | Root/Play Integrity kontrolü |

Bunlar **beklenen** sonuçlardır; root'un doğal bedelidir.

---

## 6. Ağ servisleri

Bu cihazda çalışan servisler (Kabuk, SSH, web paneli, ADB) saldırı yüzeyidir:

- SSH için anahtar tabanlı kimlik doğrulama; parola ile giriş kapalı.
- Web paneli (varsa) yalnızca Tailscale arayüzüne bağlayın.
- Varsayılan portları değiştirmek yeterli değildir; erişim kontrolü şart.
- `ufw`/`iptables` ile yalnızca gerekli portları açın.
- Tailscale kullanıyorsanız ACL ile cihaz erişimini sınırlayın.

---

## 7. Güncelleme

GSI kurulu cihazda MIUI OTA'sı yoktur. Güvenlik yamaları için:

- phh GSI'nin yeni sürümlerini takip edin; `system` imajını güncelleyin.
- Magisk'i resmî GitHub sürümlerinden güncelleyin.
- Kullandığınız modüllerin kaynağını kontrol edin.
- Android güvenlik yaması tarihini `getprop ro.build.version.security_patch`
  ile takip edin.

---

## 8. Yasal / etik

- Yalnızca **kendi cihazınızda** işlem yapın.
- IMEI değiştirme, `nvram`/`persist` yazma gibi işlemler birçok ülkede yasal
  sorun doğurur ve cihazı kalıcı olarak bozar.
- Bootloader açmak garantiyi geçersiz kılabilir.
- Üçüncü taraf yazılımların lisanslarına uyun.

---

## 9. Hızlı kontrol listesi

- [ ] ADB TCP portu yalnızca güvenilir ağda açık
- [ ] Router'da 5555 internete kapalı
- [ ] SSH parola girişi kapalı, anahtar kullanılıyor
- [ ] Modüller yalnızca denetlenmiş kaynaktan
- [ ] Yedekler şifreli ve çevrimdışı
- [ ] Cihazda hassas hesap/uygulama yok
- [ ] GSI/Magisk güncellemeleri takip ediliyor
