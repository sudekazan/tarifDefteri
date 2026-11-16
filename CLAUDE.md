# Tarifly (tarif_defteri_yeni)
Kişisel tarif defteri: klasörler, zengin metinli tarif oluşturma, yemek yapma modu, alışveriş listesi, "Bugün ne pişirsem" ve yapay zekâyla tarif üretme. Eski adı Tarif Defteri; paket adı hâlâ `tarif_defteri`.

# Teknoloji
- Flutter + Provider. Firebase: Auth, Firestore, Storage, Analytics.
- Giriş: e-posta, Google, Apple. Premium: RevenueCat (aylık / yıllık / ömür boyu). Reklam: AdMob + ATT.
- Dil: easy_localization, `assets/lang/` içinde `tr`, `en`, `de`, `es`, `fr`, `pt`.
- Tarif oluşturma: bölüm ve madde listesi (zengin metin editörü yok).

# Yapı
- Ekranlar: `lib/sayfalar/` (çoğu), `lib/screens/` (ayarlar, tema, güncelleme)
- Durum: `lib/managers/app_state_manager.dart`. Modeller: `lib/tarifler_data/`
- Servisler: `lib/services/` (firebase, ai_recipe, ad, revenuecat, review, analytics)
- Yapay zekâ sunucusu: `backend/server.js` (Express, Render'da `tarif-defteri-api.onrender.com`, OpenRouter). Anahtarlar Render ortam değişkenlerinde.
- `functions/index.js` içindeki `generateRecipe` yorum satırında; yapay zekâ istekleri `backend/` üzerinden gidiyor.

# Komutlar
```bash
flutter analyze
flutter test
./build_release.sh   # Android App Bundle (--no-tree-shake-icons)
cd backend && npm start
```

# Kurallar
- Yeni bir metin anahtarı eklerken `assets/lang/` altındaki altı dosyanın hepsine ekle; Türkçe metni çevrilmeden bırakma.
- Girişte yerel tarifler Firebase verisiyle birleştirilir, asla ezilmez (COZUM_DOKUMANI.md). Elle test senaryoları: NASIL_TEST_EDILIR.md.
- Kökteki `AuthKey_*.p8` App Store Connect API anahtarı; gitignore'da. Dokunma, içeriğini okuma.
- Commit mesajları Türkçe, kısa ve anlaşılır olsun. Başına `fix:`, `feat:`, `düzeltme:` gibi ön ek konmaz. Örnek: `Küçük yazıları 11 pt'ye çıkar`

# Son kararlar
- 2026-10-24: Ödüllü reklam zorunlu değil, "+1 hak" modeli.
- 2026-10-24: Premium ekranı çoklu plan (aylık / yıllık / ömür boyu).
- 2026-10-29: Uygulama Tarifly olarak yeniden markalandı.
- 2026-10-30: Google ve Apple ile giriş eklendi.
- 2026-11-03: En küçük yazı 11 pt, yazılarda en az 4.5:1 kontrast (Apple HIG).
- 2026-11-04: Gerçek abone yok; önce ölçüm (analitik olayları). RevenueCat Experiments ile deneyler gerçek satın almalar başlayınca.
- 2026-11-04: AB onay formunda (AdMob GDPR mesajı) "İzin vermeyin" düğmesi tüm ülkelerde açık.
- 2026-11-09: Tüm uygulama UI UX Pro Max'in yumuşak kil tarzına (claymorphism) geçiyor. Plan ve renkler: `docs/tasarim/kil-tasarim-plani.md`.
- 2026-11-09: 10 pastel tema kalkıyor, tek palet: terrakota, adaçayı, krem. Başlıklar Caveat (yalnızca 22 pt ve üstü), metinler Quicksand.
- 2026-11-09: Karanlık modun koyu kil sürümü yapılacak. Gezinme alt sekme çubuğuna geçiyor: Defterim, Ne pişirsem, Alışveriş, Profil.
- 2026-11-09: Geçiş aşamalı. Her aşama ayrı commit; her aşamadan sonra simülatörde açık ve koyu modda bakılır.
- 2026-11-09: Xcode derlemesini Claude başlatmaz (bilgisayar ısınıyor). Ekranlar test görüntüleriyle kontrol edilir; gerçek cihaz derlemesini Sude yapar.
- 2026-11-09: "Yeni tarif" alt sayfasında önce klasör seçilir (klasör içinden açılınca o klasör seçili). "Yeni klasör" düğmesi "Klasörlerim" başlığının yanında. Ana sayfadan eklenen tarif kaydedilince o klasör açılır.
- 2026-11-10: Eski varsayılan klasör ikonu kodu (0xe2c7) ekranda klasör ikonu olarak gösterilir; kayıtlı veri değişmez.
- 2026-11-10: Uygulamada "Pro" yerine her yerde "Premium"; satın alma düğmesi "Premium'a geç", Premium ekranında büyük harf yok.
- 2026-11-10: Caveat başlıklar (iç sayfa ve ana sayfa dahil) büyük yazıda en fazla 2 kat büyür. Gövde yazısı küçülmez; en büyük yazıda uzun kelimelerin bölünmesi kabul.
- 2026-11-10: Silme ve çıkış onayları iOS'ta da kil diyaloğu; ana düğme üstte, "Vazgeç" altta. Güncelleme uyarısı iOS'ta sistem, Android'de kil.
- 2026-11-10: Giriş ekranında Google'ın resmi renkli "G" logosu kullanılır; Apple düğmesi kil tarzında kalır (incelemede sorun çıkarsa değişir).
- 2026-11-10: Yemek modu zamanlayıcısı süresi elle girilen basit bir zamanlayıcı olacak; adım metninden süre tanıma yok (ayrı iş).
- 2026-11-10: Tarif ve klasör önce cihaza yazılır, Firebase beklenmez; fotoğraf arkadan yüklenir.
- 2026-11-10: Çıkıştan önce tarifler buluta yedeklenir; yedeklenemezse kullanıcı uyarılır ("Yine de çık").
- 2026-11-10: Açılış reklamı yalnızca açılıştan sonraki 4 saniyede yüklenirse ve kullanıcı ana ekrandaysa gösterilir.
- 2026-11-11: 20 tarif sınırı her yoldan geçerli (Ne pişirsem, klasöre taşıma). Ödüllü reklam yüklenemezse hak yine verilir. Sunucuda istek metni en fazla 1000 karakter.
- 2026-11-11: Telefon dikeye kilitli (iPad döner). Değerlendirme isteğinde 7 gün ilk açılıştan sayılır. Zamanlayıcı bildirimi yaklaşık zamanlı kalır.
- 2026-11-11: Crashlytics ve "silinenler listesi" (silinen tarifin başka cihazdan geri gelmesi) yayından sonraya.
- 2026-11-16: Koyu mod kahverengi yerine nötr "Kömür" paleti (zemin #141414, yumuşak terrakota #E07A5A); web sitesi (hosting/) yalnızca açık mod.
