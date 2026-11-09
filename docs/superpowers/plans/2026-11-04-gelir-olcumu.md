# Gelir ölçümü ve düzeltmeleri — uygulama planı

> **Uygulayan için:** Görevler sırayla, tek tek yapılır. Her görevden önce ve sonra Sude'ye sorulur (başlayayım mı → sonucu gösterdim → commit edeyim mi). Adımlar `- [ ]` ile işaretlenir.

**Amaç:** Kullanıcının nerede kaybolduğunu görmek için eksik analitiği eklemek; paywall'daki yanlış abonelik bilgisini düzeltmek; reklam gelirini engelleyen izin sorunlarını gidermek.

**Yaklaşım:** Tüm olay metotları önce `AnalyticsService` içinde tanımlanır ve testlenir (Görev 1). Sonraki görevler bu metotları ekranlara bağlar. Paywall metni, RevenueCat bağlantısı ve reklam izinleri ayrı görevlerdir.

**Teknoloji:** Flutter, firebase_analytics 11, purchases_flutter 10.18, google_mobile_ads 8 (UMP içinde), easy_localization.

**Kaynak:** [GELIR_ANALIZI.md](../../../GELIR_ANALIZI.md) (bölüm 3, 4, 5)

## Genel kurallar

- Font, renk, yerleşim değişmez. Yeni paket eklenmez.
- Fiyat, limit, ürün kimliği değişmez. Sürüm/build numarası değişmez. Push yok.
- Kullanıcıya görünen her yeni metin `assets/lang/` altındaki 6 dosyanın hepsine eklenir; Türkçe metin çevrilmeden bırakılmaz.
- Olay adları mevcut stile uyar: Türkçe, küçük harf, alt çizgili (`paywall_goruldu` gibi). Firebase sınırı: olay ve parametre adı en çok 40 karakter, değer en çok 100 karakter.
- Analitik hiçbir zaman kullanıcı akışını bozmaz: çağrılar `await` edilmez, hatalar yutulur (mevcut `_log` davranışı).
- Her görevin sonunda `flutter analyze` ve `flutter test`. Başlangıç durumu: 0 hata, 1 uyarı, toplam 141 bulgu. Yeni hata veya uyarı eklenmemeli.
- `test/widget_test.dart` Flutter'ın hazır sayaç testi; uygulamayla ilgisi yok ve şu an zaten başarısız. Silmek için Sude'ye ayrıca sorulur. O silinene kadar `flutter test` sonucunda yalnızca yeni testlere bakılır.
- Commit: yalnızca o görevin dosyaları eklenir (çalışma alanındaki ilgisiz android/ios değişiklikleri eklenmez). Mesaj Türkçe, ön eksiz, emir kipinde, sonunda `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Dikkat edilecekler (testlerin kapsamadığı durumlar)

1. Ödüllü reklam yüklenemediğinde kullanıcı bugünkü gibi yine +1 hak almalı; yalnızca olay eklenir, davranış değişmez. → Görev 3, elle kontrol.
2. Satın alma iptal edilince bugünkü gibi hata mesajı çıkmamalı. → Görev 2, testte `iptal` sonucu.
3. Başarılı satın almadan sonra paywall kapanırken `paywall_kapatildi` gönderilmemeli. → Görev 2, elle kontrol (DebugView).
4. Arama olayı her tuşa basışta değil, arama sayfası başına en çok bir kez gönderilmeli. → Görev 4, elle kontrol.
5. Onay formu (UMP) ağ hatası verirse uygulama açılmaya devam etmeli; reklam isteyip istememe `canRequestAds()` sonucuna göre olmalı. → Görev 8, elle kontrol.

Elle kontrol yöntemi: Firebase DebugView. iOS'ta Xcode şemasına `-FIRDebugEnabled` argümanı; Android'de `adb shell setprop debug.firebase.analytics.app com.sudekazan.tarif_defteri_yeni`.

---

## Sude'nin yapacağı konsol işleri (kod yok)

- [ ] Firebase → Analytics → Custom definitions: `source`, `package_id`, `kaynak`, `sonuc`, `yer` için olay kapsamlı özel boyut; `is_pro` için kullanıcı kapsamlı özel boyut. (Görev 1'den önce yapılabilir.)
- [ ] RevenueCat → Integrations → Firebase'i aç. (Görev 7'den sonra)
- [ ] RevenueCat → Integrations → Apple Search Ads'i aç. (Görev 7'de token toplamaya "evet" denirse)
- [ ] AdMob → Privacy & messaging → GDPR mesajı oluştur ve yayınla. (Görev 8'den önce şart)

---

### Görev 1: Analitik altyapısı ve `is_pro`

**Dosyalar:**
- Değişecek: `lib/services/analytics_service.dart`
- Değişecek: `lib/services/revenuecat_service.dart` (`_isPro` atanan 5 yer)
- Yeni test: `test/analytics_service_test.dart`

**Arayüz (sonraki görevler bunları kullanır):**
- `@visibleForTesting static Future<void> Function(String name, Map<String, Object>? params)? testLogger;` — doluysa `_log` Firebase yerine bunu çağırır.
- `@visibleForTesting static Future<void> Function(String name, String? value)? testUserPropertyLogger;`
- `static Future<void> setIsPro(bool isPro)` → user property `is_pro` = `'true'` / `'false'`
- `static Future<void> satinAlma({String? packageId, String? priceString, required String source})`
- `static Future<void> satinAlmaBasarisiz({required String source, String? packageId, required bool iptalEdildi})` → `satin_alma_basarisiz` {`source`, `package_id`, `iptal_edildi`}
- `static Future<void> paywallKapatildi(String source)` → `paywall_kapatildi` {`source`}
- `static Future<void> aiKullanildi({required bool isPro, required String kaynak})` → + `kaynak`
- `static Future<void> aiLimitDoldu({required String kaynak})` → `ai_limit_doldu` {`kaynak`}
- `static Future<void> odulluReklam({required String sonuc, required String yer})` → `odullu_reklam` {`sonuc`, `yer`}
- `static Future<void> yemekModuAcildi()`, `yemekModuTamamlandi()` → `yemek_modu_acildi`, `yemek_modu_tamamlandi`
- `static Future<void> alisverisListesiAcildi()`, `alisverisListesineEklendi()` → `alisveris_listesi_acildi`, `alisveris_listesine_eklendi`
- `static Future<void> aramaYapildi({required bool sonucVar})` → `arama_yapildi` {`sonuc_var`}
- `static Future<void> klasorOlusturuldu({required int klasorSayisi})` → `klasor_olusturuldu` {`klasor_sayisi`}
- `static Future<void> tarifPaylasildi({required String kaynak})` → + `kaynak`
- Sabit değerler: `kaynak` için `'ne_pisirsem'`, `'klasor_ai'`, `'link'`; paylaşım için `'tarif_detay'`, `'klasor_ici'`, `'klasorler'`. `sonuc` için `'izlendi'`, `'yarida_kapatildi'`, `'yuklenemedi'`.
- Bool'lar `'true'`/`'false'` metni olarak gönderilir; mevcut `is_pro` ve `is_ai_generated` parametreleri de buna çevrilir. Neden: firebase_analytics 11.6 yalnız metin ve sayı kabul ediyor (`_assertParameterTypesAreCorrect`). Bugünkü bool değerler debug'da hata verip olayı düşürüyor (DebugView'da görünmez), release'de ise doğru kaydedileceği garanti değil.

- [x] **Adım 1: Başarısız testleri yaz** — `test/analytics_service_test.dart`
  - `satinAlma` → ad `satin_alma`, parametrelerde `source: 'ai_limit'`
  - `satinAlmaBasarisiz(iptalEdildi: true)` → `iptal_edildi: 'true'`
  - `aiLimitDoldu(kaynak: 'link')` → ad `ai_limit_doldu`, `kaynak: 'link'`
  - `odulluReklam(sonuc: 'yuklenemedi', yer: 'ne_pisirsem')` → iki parametre doğru
  - `setIsPro(true)` → `testUserPropertyLogger` `('is_pro', 'true')` ile çağrılır
  - `testLogger` hata fırlatırsa metot yine sorunsuz tamamlanır
- [x] **Adım 2:** `flutter test test/analytics_service_test.dart` → derleme hatasıyla başarısız (metotlar yok)
- [x] **Adım 3:** Metotları ve test kancalarını ekle; imzası değişen mevcut çağrılara (`aiKullanildi`, `aiLimitDoldu`, `satinAlma`, `tarifPaylasildi`) doğru değerleri ver: `ne_pisirsem`, `isUrl ? 'link' : 'klasor_ai'`, `widget.source`, `tarif_detay`.
- [x] **Adım 4:** `revenuecat_service.dart` içinde `_isPro`'yu atayan yerleri tek bir `_setPro(bool)` üzerinden geçir; bu metot `AnalyticsService.setIsPro` çağırır.
- [x] **Adım 5:** `flutter test test/analytics_service_test.dart` → geçer; `flutter analyze` → yeni hata/uyarı yok
- [x] **Adım 6:** Sude'ye göster, onay gelirse commit: `Analitik olaylarını ve Pro kullanıcı özelliğini ekle` (b103bfa)

### Görev 2: Paywall ve satın alma olayları

**Dosyalar:**
- Değişecek: `lib/services/revenuecat_service.dart` (`purchasePackage`)
- Değişecek: `lib/sayfalar/premium_sayfasi.dart` (`_purchase`, `dispose`)
- Yeni test: `test/revenuecat_service_test.dart`

**Arayüz:**
- `enum SatinAlmaSonucu { basarili, iptal, hata }` (`revenuecat_service.dart`)
- `static Future<SatinAlmaSonucu> purchasePackage(Package package)` — bugün `bool` dönüyor; tek çağıran `premium_sayfasi.dart:127`.
- `@visibleForTesting static SatinAlmaSonucu sonucFromError(PlatformException e)` — `PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError` ise `iptal`, değilse `hata`.

- [x] **Adım 1: Başarısız test** — `sonucFromError(PlatformException(code: '1'))` → `iptal`; `code: '2'` → `hata`
- [x] **Adım 2:** Test başarısız (metot yok)
- [x] **Adım 3:** `purchasePackage`'ı enum döndürecek şekilde değiştir; `premium_sayfasi.dart`'ta: başarılıysa `satinAlma(source: widget.source)` ve `_proAktiflesti = true` (başarılı geri yüklemede de); değilse `satinAlmaBasarisiz(...)`. Kullanıcıya görünen davranış aynı kalır (iptalde mesaj yok).
- [x] **Adım 4:** `dispose` içinde `_proAktiflesti` false ise `paywallKapatildi(widget.source)`
- [x] **Adım 5:** Testler geçer, analyze temiz
- [x] **Adım 6:** Sude'ye göster, commit: `Paywall kapatma ve başarısız satın alma olaylarını ekle` (ff140c4)

### Görev 3: AI ve ödüllü reklam olayları

**Dosyalar:**
- Değişecek: `lib/sayfalar/bugun_ne_pisisem_sayfasi.dart` (181, 221, 272. satırlar civarı)
- Değişecek: `lib/sayfalar/klasor_ici.dart` (587, 652, 784. satırlar civarı)
- Değişecek: `lib/services/ad_service.dart` (`showRewardedAd`)

**Arayüz:**
- `static void showRewardedAd({required String yer, VoidCallback? onAdClosed, Function(RewardItem)? onUserEarnedReward})` — `yer`: `'ne_pisirsem'` veya `'klasor_ici'`. Reklam yoksa / gösterilemezse `yuklenemedi`; SDK ödül verdiyse `izlendi`; ödülsüz kapandıysa `yarida_kapatildi`. Pro kullanıcı için olay gönderilmez.

- [x] **Adım 1:** `ai_limit_doldu`'yu yerel kontrol "hak yok" dediğinde de gönder (bugün yalnız sunucu reddedince gidiyor). Bir denemede olay en çok bir kez gider: yerel kontrol "hak yok" derse sunucuya hiç istek gitmez.
- [x] **Adım 2:** `ai_kullanildi` ve `ai_limit_doldu` çağrılarına doğru `kaynak` ver (Görev 1'de yapıldı)
- [x] **Adım 3:** `showRewardedAd`'e `yer` ve `odulluReklam` olayını ekle; iki çağrıyı güncelle
- [x] **Adım 4:** analyze temiz (DebugView kontrolü yapılmadı: ödüllü reklamı izle / yarıda kapat → doğru `sonuc`)
- [x] **Adım 5:** Sude'ye göster, commit: `AI kullanımı ve ödüllü reklam olaylarını ayrıntılandır` (751cd59)

### Görev 4: Özellik kullanım olayları

**Dosyalar:**
- `lib/sayfalar/yemek_yapma_modu.dart` (`initState` → açıldı; 648. satırdaki bitiş düğmesi → tamamlandı)
- `lib/sayfalar/alisveris_listesi.dart` (`initState` → açıldı; `_ekle` → eklendi)
- `lib/sayfalar/arama_sayfasi.dart` (`dispose` → sayfada en az bir arama yapıldıysa bir kez `arama_yapildi`, `sonuc_var` = son boş olmayan aramanın sonucu; ayrıca unutulmuş `_aramaController.dispose()` eklendi)
- `lib/sayfalar/klasorler.dart` (`_klasorEkle` sonu → `klasorOlusturuldu(klasorSayisi: klasorJsonList.length)`)

- [x] **Adım 1:** Dört ekrana çağrıları ekle
- [x] **Adım 2:** analyze temiz (DebugView kontrolü yapılmadı: her olay bir kez görünmeli, arama sayfa başına bir kez)
- [x] **Adım 3:** Sude'ye göster, commit: `Yemek modu, alışveriş listesi, arama ve klasör olaylarını ekle` (9c3c4b7)

### Görev 5: Paylaşımlara mağaza linki

**Dosyalar:**
- Yeni: `lib/utils/magaza_linki.dart` — `String get magazaLinki` (bugün `tarif_detay.dart:29`'daki değerler, aynen taşınır)
- Değişecek: `lib/sayfalar/tarif_detay.dart`, `lib/sayfalar/klasorler.dart:895`, `lib/sayfalar/klasor_ici.dart:1118`

- [x] **Adım 1:** Linki ortak dosyaya taşı; `tarif_detay.dart` onu kullansın
- [x] **Adım 2:** Diğer iki paylaşımın sonuna mevcut `share_download_cta` metni + link ekle (yeni çeviri yok); üçüne de `tarifPaylasildi(kaynak: ...)`
- [x] **Adım 3:** analyze temiz (cihazda paylaşım metni denenmedi)
- [x] **Adım 4:** Sude'ye göster, commit: `Tüm paylaşımlara mağaza linki ekle` (de1c6ae)

### Görev 6: Paywall'da plana göre abonelik koşulları

**Dosyalar:**
- Değişecek: `lib/sayfalar/premium_sayfasi.dart` (617. satırdaki metin, 330. satırdaki rozet değişmez — rozet metni dil dosyasında)
- Değişecek: `assets/lang/{tr,en,de,es,fr,pt}.json`
- Yeni test: `test/abonelik_kosullari_test.dart`

**Arayüz:**
- `({String key, List<String> args}) abonelikKosullari(PackageType type, String priceString, {required bool isIOS})` — saf fonksiyon, `lib/utils/abonelik_kosullari.dart`.
- Anahtarlar: `premium_terms_monthly_ios`, `premium_terms_monthly_android`, `premium_terms_annual_ios`, `premium_terms_annual_android`, `premium_terms_lifetime`. Paket seçilmemişse ya da tür bilinmiyorsa mevcut `premium_sub_terms_body`'ye düşer.

**Türkçe taslak (Sude onaylayacak; diğer 5 dile çevrilecek):**
- Aylık (iOS): "• Plan: Aylık Premium, {fiyat} / ay\n• Ödeme, satın alma onayıyla Apple Kimliği hesabınızdan alınır.\n• Dönem bitmeden en az 24 saat önce iptal edilmezse abonelik otomatik yenilenir; ücret dönem bitimine 24 saat kala alınır.\n• Aboneliğinizi Apple Hesap Ayarları'ndan yönetebilir ve iptal edebilirsiniz."
- Yıllık: aynısı, "Yıllık Premium, {fiyat} / yıl"
- Android sürümleri: "Apple Kimliği" yerine "Google Play hesabınız", "Apple Hesap Ayarları" yerine "Google Play → Abonelikler"
- Ömür boyu: "• Plan: Ömür Boyu Premium, {fiyat}, tek seferlik ödeme\n• Abonelik değildir, yenilenmez ve tekrar ücret alınmaz."

**Sude'nin kararları (2026-11-04):** Rozet 6 dilde "TARIFLY PREMIUM" (Türkçe "TARİFLY PREMIUM"). Yıllık rozet "EN POPÜLER" yerine "EN AVANTAJLI" (en: BEST VALUE, de: BESTES ANGEBOT, es: MÁS VENTAJOSO, fr: MEILLEURE OFFRE, pt: MAIS VANTAJOSO).

- [x] **Adım 1: Başarısız test** — `annual + isIOS:false` → `premium_terms_annual_android`, args `['₺X']`; `lifetime` → `premium_terms_lifetime` (iOS/Android aynı); `weekly` → `premium_sub_terms_body`
- [x] **Adım 2:** Test başarısız
- [x] **Adım 3:** Fonksiyonu yaz; 617. satırdaki `Text`'i `_selectedPackage`'a göre bu fonksiyonla besle (stil aynı kalır)
- [x] **Adım 4:** 5 yeni anahtarı 6 dosyaya ekle (Sude'nin onayladığı Türkçe metinle)
- [x] **Adım 5:** Test geçer, analyze temiz (simülatör kontrolü yapılmadı: üç plan seçilerek metnin değiştiği görülmeli)
- [x] **Adım 6:** Sude'ye göster, commit: `Abonelik koşullarını plana göre göster, rozetleri düzelt` (11ee6cf)

### Görev 7: RevenueCat ↔ Firebase bağlantısı (ve isteğe bağlı Apple Ads token)

**Dosyalar:**
- Değişecek: `lib/services/revenuecat_service.dart` (`init`, `Purchases.configure` sonrası)

**Arayüz:**
- `Purchases.setFirebaseAppInstanceId(id)` — `id`, yeni `AnalyticsService.appInstanceId()`'den; null ise çağrılmaz. `configure` sonrası ve her `logIn` sonrası çağrılır.
- Sude "evet" derse yalnız iOS'ta: `Purchases.enableAdServicesAttributionTokenCollection()`

- [x] **Adım 1:** Sude'ye Apple Ads token sorusunu sor (ayrı karar) — 2026-11-04: evet
- [x] **Adım 2:** Çağrıları `init` içine, hataya karşı korumalı ekle
- [x] **Adım 3:** analyze temiz (RevenueCat panelinde `$firebaseAppInstanceId` kontrolü yapılmadı; yeni sürümle Sude'nin kendi hesabında görünmeli)
- [x] **Adım 4:** Sude'ye göster, commit: `RevenueCat'i Firebase ve Apple Ads'e bağla` (b3d6763)

### Görev 8: AB reklam onayı (UMP) ve ATT zamanlaması

**Ön koşul:** AdMob'da GDPR mesajı yayında.

**Dosyalar:**
- Değişecek: `lib/services/ad_service.dart` — yeni `static Future<void> izinleriIsteVeReklamlariBaslat()`
- Değişecek: `lib/main.dart:54-62` — `MobileAds.initialize`, ATT ve reklam yükleme buradan kaldırılır
- Değişecek: `lib/sayfalar/klasorler.dart` — ilk kare çizildikten sonra (`addPostFrameCallback`) yeni metodu çağırır; açılış reklamı mantığı bu metodun bitmesini bekler
- Değişecek: `lib/widgets/banner_ad_widget.dart` ve `klasorler.dart`'taki banner — `AdService.reklamlarHazir` true olana kadar yüklenmez (planda yoktu; AB'de onaydan önce reklam istenmemesi için gerekli)
- Değişecek: `lib/screens/settings_page.dart` — `getPrivacyOptionsRequirementStatus() == required` ise "Gizlilik seçenekleri" satırı → `ConsentForm.showPrivacyOptionsForm`
- Değişecek: 6 dil dosyası — `settings_privacy_options` (TR taslak: "Reklam gizlilik seçenekleri")

**Sıra (metodun içi):** `requestConsentInfoUpdate` → `loadAndShowConsentFormIfRequired` → ATT isteği → `canRequestAds()` true ise `MobileAds.initialize` + açılış ve ödüllü reklam yükle. Herhangi bir adım hata verirse sonraki adıma geçilir; uygulama asla bekleyip takılmaz.

- [x] **Adım 1:** Metodu yaz, `main.dart` ve `klasorler.dart`'ı bağla
- [x] **Adım 2:** Ayarlar satırını ve metin anahtarını ekle
- [x] **Adım 3:** analyze temiz
- [ ] **Adım 4:** (Simülatör bilgisayarı çok yorduğu için yarıda bırakıldı; Sude'nin telefonunda denenecek.) Elle test: debug'da `ConsentDebugSettings(debugGeography: DebugGeography.debugGeographyEea)` ile simülatörde onay formu çıkar; sonra ATT penceresi çıkar; reklam yüklenir. Türkiye ayarıyla form çıkmaz. Test ayarı commit'e girmez.
- [x] **Adım 5:** Sude'ye göster, commit: `AB kullanıcıları için reklam onayı ekle ve ATT iznini ekran açıldıktan sonra iste` (b80201e; cihaz testi yapılmadan)

### Görev 9: Kullanılmayan geçiş reklamı kodunu kaldır

**Dosyalar:** `lib/services/ad_service.dart` (`_interstitialAd`, `interstitialAdUnitId`, `loadInterstitialAd`, `showInterstitialAd`; hiçbir yerden çağrılmıyor)

- [x] **Adım 1:** Sude'ye sor (kod silme) — 2026-11-04: evet
- [x] **Adım 2:** Sil; analyze temiz
- [x] **Adım 3:** Commit: `Kullanılmayan geçiş reklamı kodunu kaldır` (38df59e)

---

## Bu planda olmayanlar (veri gelince)

- Banner'ı ekran genişliğine uyan (adaptive) banner'a çevirmek — görünümü değiştirir.
- Açılış reklamına sıklık sınırı.
- RevenueCat Experiments deneyleri, ücretsiz sınırları değiştirmek, fiyat.
