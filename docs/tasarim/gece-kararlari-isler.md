# Gece notları kararları ve yapılacak işler (2026-11-10)

`docs/tasarim/gece-notlari.md` içindeki 14 soruya Sude'nin verdiği cevaplar ve bunlardan çıkan işler. Dal: `kil-gece`.

## Çalışma kuralları
- Önce `CLAUDE.md` ve `docs/tasarim/kil-tasarim-plani.md` okunur.
- Her iş ayrı commit. Commit mesajı Türkçe, ön eksiz, emir kipinde. `git push` yapılmaz.
- Xcode / simülatör derlemesi başlatılmaz; ekranlar test görüntüleriyle kontrol edilir (`build/gecici_test/` içindeki testler örnek, silinmeyecek).
- Metin değişiklikleri `assets/lang/` altındaki altı dosyanın hepsinde yapılır (`tr`, `en`, `de`, `es`, `fr`, `pt`).
- Fiyat, ürün kimliği, RevenueCat paket mantığı ve mağaza metinleri değişmez.
- Gizli dosyalara (`google-services.json`, `*.p8` vb.) dokunulmaz. Çalışma ağacındaki `android/app/google-services.json` değişikliği commit'e girmez.
- Her işten sonra `flutter analyze` ve yalnızca ilgili test dosyası; tüm testler en sonda bir kez (`flutter test -r failures-only`).

## Kararlar (iş çıkmayanlar)
| Soru | Karar |
|---|---|
| 1. Başlıklarda 2 kat sınırı | Kalsın |
| 3. En büyük yazıda uzun kelimelerin bölünmesi | Böyle kalsın, gövde yazısı küçülmez |
| 7a. Alışveriş boş liste metni | Uygun |
| 7b. "Temizle" onayı | Onay sormasın |
| 9a. Güncelleme uyarısı (iOS sistem, Android kil) | Uygun |
| 9b. Silme / çıkış onayları | iOS'ta da kil diyaloğu kalsın |
| 9c. Düğme sırası (ana düğme üstte, Vazgeç altta) | Kalsın |
| 10. Sınır uyarılarının kiremit rengi | Kalsın |
| 11. Apple düğmesi | Kil tarzında kalsın (incelemede sorun çıkarsa değişir) |
| 13b. Uygulama ikonu | Değişmez |
| 14. `cupertino_icons`, `ReviewService.resetForTesting`, `build/gecici_test/` | Kalsın |

## İşler

### İş 1 — İç sayfa ve ana sayfa başlıklarına 2 kat yazı sınırı (soru 2)
- `KilSayfaBasligi` / `KilIcSayfa` ve Defterim'deki "Tarifly" başlığı büyük yazıda en fazla 2 kat büyüsün (diğer başlıklardaki sınırla aynı yöntem).
- Bitti sayılır: 320 genişlik ve 3.2 kat yazıda "Çorbalar", "Tarif Düzenleme" kelime ortasından bölünmüyor, "Tarifly" kısalmıyor; test görüntüsünde taşma yok.

### İş 2 — Arama ekranı metinleri (soru 6)
- Arama kutusunda `folders_search_hint` yerine `recipes_search_hint` ("Tarif ara...").
- Sonuç yokken yeni bir anahtar: "Aradığınız kritere uygun tarif bulunamadı." (altı dilde).
- `folders_search_hint` / `folders_search_no_results` başka yerde kullanılmıyorsa İş 8'deki silinecek anahtarlara eklenir.

### İş 3 — "Pro" yerine her yerde "Premium" (soru 8a)
- Altı dil dosyasında kullanıcıya görünen tüm "Pro" ifadeleri "Premium" olur (rozet, "Pro'ya özel" uyarıları, Profil kartı vb.).
- Satın alma düğmesi: "Premium'a geç" (normal yazım, kısa). Diğer dillerde aynı anlamda kısa karşılık.
- Anahtar adları, ürün kimlikleri, analitik olay adları ve mağaza metinleri değişmez.
- Rozet "Premium" olunca dar yerlerde sığıp sığmadığına test görüntüsüyle bakılır; sığmıyorsa Sude'ye sorulur.

### İş 4 — Premium ekranında normal yazım (soru 8b)
- "EN AVANTAJLI" → "En avantajlı", "TARİFLY PREMIUM" → "Tarifly Premium" (altı dilde; büyük harf kodda `toUpperCase` ile yapılıyorsa o kaldırılır).

### İş 5 — Android için ayrı genel koşul metni (soru 8c)
- Paket yüklenemeyince çıkan `premium_sub_terms_body` Android'de "Apple Kimliği" diyor. Android için "Google Play hesabı" diyen ayrı bir metin eklenir (altı dilde), platforma göre seçilir.
- **Metin yazılmadan önce Türkçesi Sude'ye gösterilip onay alınır.**

### İş 6 — "Geri yükleme bulunamadı" bildirimi (soru 10)
- Premium ekranındaki kırmızı (hata) bildirim, Profil'deki gibi gri (bilgi) olur.

### İş 7 — Resmi Google logosu (soru 11)
- Giriş ekranındaki Google düğmesinde Material `g_mobiledata` ikonu yerine Google'ın resmi renkli "G" logosu.
- Yeni görsel dosyası gerekir. **Dosya indirilmeden önce Sude'ye kaynak ve dosya adı söylenip onay alınır** (Google'ın resmi marka paketi). Yeni paket (ör. `flutter_svg`) gerekiyorsa önce önerilir; PNG ile paket eklemeden çözmek tercih edilir.

### İş 8 — Temizlik (soru 4 ve 14)
Sude hepsini onayladı; ayrıntılı liste `gece-notlari.md` → "Aşama 10 / silinebilecekler".
- **Paketler:** `flutter_quill`, `flutter_quill_extensions`, `showcaseview`, `uuid`, `cloud_functions` `pubspec.yaml`'dan çıkar. `CLAUDE.md`'deki "Tarif editörü: flutter_quill" satırı güncellenir.
- **Yöntemler:** `FirebaseService.restoreFromFirebaseToLocal` ve `FirebaseService.saveGeneratedRecipeToFirestore` silinir.
- **Çeviri anahtarları:** Listedeki 59 anahtar altı dosyadan silinir. Silmeden önce her anahtarın `lib/` içinde kullanılmadığı (dinamik kurulanlar dahil) yeniden doğrulanır.
- **Varlık:** `assets/logo.png` `pubspec.yaml`'ın `assets` listesinden çıkar; dosya kalır.
- **Betikler:** Kökteki `fix_tr.dart` ve `update_langs.py` silinir.
- Paketlerden sonra `flutter pub get` ve tüm testler.

### İş 9 — Profil dosyasını taşı (soru 12)
- `lib/screens/settings_page.dart` (`SettingsPage`) → `lib/sayfalar/profil_sayfasi.dart` (`ProfilSayfasi`). `git mv` ile; içe aktarmalar ve testler güncellenir. Davranış değişmez.

### İş 10 — Açılış ekranı renkleri (soru 13a)
- `flutter_native_splash` ayarında açık `#F8F9FC` → `#FFFBEB`, koyu `#10121A` → `#1C1412`.
- `dart run flutter_native_splash:create` çalıştırılır; üretilen iOS/Android dosyaları commit'e girer.

### İş 11 — CLAUDE.md "Son kararlar"
- Bu dosyadaki kararlar tarihli (2026-11-10) kısa satırlar olarak eklenir: "Pro" yerine "Premium"; iç başlıklarda 2 kat sınırı; uzun kelimeler bölünebilir; onaylar iki platformda kil diyaloğu; resmi Google logosu; yemek modunda elle süreli zamanlayıcı.

## Ayrı işler (bu listede yapılmaz)

### Yemek modu zamanlayıcısı (soru 5) — ayrı oturum
- Karar: süreyi kullanıcının elle girdiği basit bir zamanlayıcı. Adım metninden süre tanıma yok.
- Yeni özellik; başlamadan Sude'yle netleşecekler: zamanlayıcı her adımda mı tek mi, uygulama arka plandayken ne olur (bildirim için yeni paket gerekir, önce önerilir), bitince ses / titreşim, yeni metinler (altı dil).

### Mağaza ekran görüntüleri (soru 13b)
- Kil tasarımıyla yeniden çekilecek. Sude gerçek cihaz derlemesini yapıp tasarımı onayladıktan sonra.
