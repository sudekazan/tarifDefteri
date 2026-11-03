# Tarifly (tarif_defteri_yeni)
Kişisel tarif defteri: klasörler, zengin metinli tarif oluşturma, yemek yapma modu, alışveriş listesi, "Bugün ne pişirsem" ve yapay zekâyla tarif üretme. Eski adı Tarif Defteri; paket adı hâlâ `tarif_defteri`.

# Teknoloji
- Flutter + Provider. Firebase: Auth, Firestore, Storage, Analytics.
- Giriş: e-posta, Google, Apple. Premium: RevenueCat (aylık / yıllık / ömür boyu). Reklam: AdMob + ATT.
- Dil: easy_localization, `assets/lang/` içinde `tr`, `en`, `de`, `es`, `fr`, `pt`.
- Tarif editörü: flutter_quill.

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
- Commit biçimi: `feat: ...`, `fix: ...`

# Son kararlar
- 2026-10-24: Ödüllü reklam zorunlu değil, "+1 hak" modeli.
- 2026-10-24: Premium ekranı çoklu plan (aylık / yıllık / ömür boyu).
- 2026-10-29: Uygulama Tarifly olarak yeniden markalandı.
- 2026-10-30: Google ve Apple ile giriş eklendi.
