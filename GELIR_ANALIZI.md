# Tarifly gelir analizi (taslak)

Tarih: 2026-11-04. Durum: **taslak, Firebase ve AdMob verisi bekleniyor.** Bu dosyada hiçbir rakam tahmin değildir; rakam gereken yerlerde "veri gerekli" yazıyor.

**RevenueCat verisi (Sude, 2026-11-04):** 3 satın alma var; üçü de Sude ve iki yakını. Yani **gerçek abone yok**, iptal yok. Bu yüzden:
- Asıl soru "paywall nasıl daha iyi satar" değil, **"kullanıcılar neden paywall'a gelmiyor ya da gelip almıyor"**. Bunu Firebase verisi gösterecek.
- Şu an para getirebilecek tek kaynak **AdMob**. Reklam düzeltmeleri (öneri 6, 7) bu yüzden öne çıktı.
- RevenueCat Experiments (bölüm 4, öncelik 4) **ertelendi**: deney yapmak için her iki grupta da gerçek satın alma gerekir.
- Bu 3 satın alma ileride rakamlara bakarken hariç tutulmalı.

---

## 1. Kısaca

- Uygulamada gelir iki yerden geliyor: **Pro abonelik** (aylık / yıllık / ömür boyu, RevenueCat) ve **AdMob reklamları** (açılış reklamı, banner, ödüllü reklam).
- En büyük sorun **ölçüm eksikliği**: satın almanın hangi paywall'dan geldiği, yemek modu, alışveriş listesi ve ödüllü reklam hiç ölçülmüyor. Bu yüzden önce ölçümü düzeltmek, sonra deney yapmak gerekiyor.
- Paywall'daki **abonelik koşulları metni her planda "1 Ay" diyor**. Varsayılan seçili plan yıllık olduğu için kullanıcı yıllık alırken "1 Ay" yazısını görüyor. Bu hem güveni zedeler hem App Store incelemesinde (kural 3.1.2) sorun çıkarabilir.
- AB'deki kullanıcılar için **reklam onay formu (GDPR) yok**. Almanca, Fransızca, İspanyolca, Portekizce destekli bir uygulamada bu, AB'de reklam gelirini düşürür ve yasal risk taşır.

---

## 2. Bugünkü gelir yüzeyleri (koddan)

### Paywall'ın açıldığı yerler

`PremiumSayfasi(source: ...)` değerleri. Firebase'de `paywall_goruldu` olayının `source` parametresi bunlar:

| source | Nerede | Ne zaman |
|---|---|---|
| `ana_ekran` | [klasorler.dart:391](lib/sayfalar/klasorler.dart:391) | Üst çubuktaki taç simgesi |
| `klasor_limit` | [klasorler.dart:309](lib/sayfalar/klasorler.dart:309) | 4. klasörü açmaya çalışınca |
| `tarif_limit` | [klasor_ici.dart:566](lib/sayfalar/klasor_ici.dart:566), [klasor_ici.dart:836](lib/sayfalar/klasor_ici.dart:836) | Bir klasöre 21. tarifi eklerken |
| `link_pro_only` | [klasor_ici.dart:579](lib/sayfalar/klasor_ici.dart:579) | Ücretsiz kullanıcı linkten tarif çekmek isteyince |
| `ai_limit` | [klasor_ici.dart:790](lib/sayfalar/klasor_ici.dart:790) | Sunucu "hak bitti" deyince (yedek yol) |
| `ai_limit_choice` | [bugun_ne_pisisem_sayfasi.dart:323](lib/sayfalar/bugun_ne_pisisem_sayfasi.dart:323), [klasor_ici.dart:721](lib/sayfalar/klasor_ici.dart:721) | Hak bitti penceresinde "Pro'ya Geç" |
| `ne_pisirsem_ekrani` | [bugun_ne_pisisem_sayfasi.dart:410](lib/sayfalar/bugun_ne_pisisem_sayfasi.dart:410) | "Bugün ne pişirsem" ekranındaki düğme |
| `ne_pisirsem_badge` | [bugun_ne_pisisem_sayfasi.dart:544](lib/sayfalar/bugun_ne_pisisem_sayfasi.dart:544) | Kalan hak rozetindeki "Sınırsız Yap" |
| `settings` | [settings_page.dart:481](lib/screens/settings_page.dart:481) | Ayarlar (kodda `ayarlar` değil `settings` yazıyor) |

### Ücretsiz sınırlar

| Sınır | Değer | Nerede tanımlı |
|---|---|---|
| Klasör | 3 | [revenuecat_service.dart](lib/services/revenuecat_service.dart) `freeKlasorLimit` |
| Klasör başına tarif | 20 | [revenuecat_service.dart](lib/services/revenuecat_service.dart) `freeTarifPerKlasorLimit` |
| Günlük AI Şef hakkı | 3 | Uygulamada `canUseAi()` içinde sabit `3`; asıl kontrol sunucuda: [backend/server.js:52](backend/server.js:52) `FREE_DAILY_AI_LIMIT` |
| Reklamla ek hak | günde en çok 3 | [backend/server.js:56](backend/server.js:56) `MAX_BONUS_USES_PER_DAY` |
| Linkten tarif çekme | yalnızca Pro | [klasor_ici.dart:573](lib/sayfalar/klasor_ici.dart:573) |

Yani ücretsiz kullanıcı günde 3 + 3 = 6 AI tarifi alabiliyor, toplam 60 tarif saklayabiliyor.

### Reklamlar

| Tür | Nerede | Not |
|---|---|---|
| Açılış reklamı (App Open) | [klasorler.dart:51](lib/sayfalar/klasorler.dart:51) | 3. açılıştan itibaren her soğuk açılışta. Sıklık sınırı yok. |
| Banner (320×50, sabit boy) | Ana ekran, klasör içi, tarif detayı, tarif oluşturma, klasör kaydı, ayarlar | Yemek yapma modunda yok (paywall'daki "yemek yaparken bölünmeyen" vaadiyle uyumlu). |
| Ödüllü reklam "+1 hak" | [bugun_ne_pisisem_sayfasi.dart:350](lib/sayfalar/bugun_ne_pisisem_sayfasi.dart:350), [klasor_ici.dart:756](lib/sayfalar/klasor_ici.dart:756) | İsteğe bağlı (2026-10-24 kararı). |
| Geçiş reklamı (Interstitial) | Kullanılmıyor | Kod duruyor ama hiçbir yerden çağrılmıyor. |

### Paywall'ın kendisi

- Planlar aylık → yıllık → ömür boyu sırasıyla diziliyor, **yıllık varsayılan seçili** ve üstünde "EN POPÜLER" rozeti var ([premium_sayfasi.dart:44](lib/sayfalar/premium_sayfasi.dart:44)).
- Yıllık planın tasarruf yüzdesi gerçek fiyatlardan hesaplanıyor (iyi).
- Kapatma düğmesi sol üstte, görünür (App Store'a uygun).
- Ücretsiz deneme (intro offer) varsa paywall bunu **göstermiyor**; kodda deneme bilgisi okunmuyor.
- Yıllık planda "aylık karşılığı" gösterilmiyor; yalnızca toplam fiyat var.

---

## 3. Koddaki sorunlar

| # | Sorun | Nerede | Neden önemli |
|---|---|---|---|
| S1 | Abonelik koşulları her planda "Abonelik Süresi: 1 Ay" diyor; ömür boyu plan için de "otomatik yenilenir" yazıyor; Android'de de "Apple Kimliği" geçiyor | [premium_sayfasi.dart:617](lib/sayfalar/premium_sayfasi.dart:617), `premium_sub_terms_body` (6 dil) | Yanlış bilgi. App Store kural 3.1.2 süre ve fiyatın doğru yazılmasını istiyor. |
| S2 | `satin_alma` olayında `source` yok | [premium_sayfasi.dart:131](lib/sayfalar/premium_sayfasi.dart:131) | Hangi paywall'ın para kazandırdığı görülemiyor. |
| S3 | `ai_limit_doldu` eksik sayılıyor: uygulama hakkın bittiğini kendisi fark edince olay gönderilmiyor, yalnızca sunucu reddedince gönderiliyor | [bugun_ne_pisisem_sayfasi.dart:181](lib/sayfalar/bugun_ne_pisisem_sayfasi.dart:181), [klasor_ici.dart:587](lib/sayfalar/klasor_ici.dart:587) | Limitin kaç kişiyi durdurduğu olduğundan az görünür. |
| S4 | Üç paylaşım noktasından ikisinde mağaza linki ve `tarif_paylasildi` olayı yok | [klasorler.dart:895](lib/sayfalar/klasorler.dart:895), [klasor_ici.dart:1118](lib/sayfalar/klasor_ici.dart:1118) (iyi örnek: [tarif_detay.dart:327](lib/sayfalar/tarif_detay.dart:327)) | Paylaşılan tarif yeni kullanıcı getiremiyor; paylaşım eksik sayılıyor. |
| S5 | AB için reklam onay formu (Google UMP) yok | `ad_service.dart`, `main.dart` | AB'de reklam az gösterilir veya hiç gösterilmez; GDPR riski. UMP, kurulu `google_mobile_ads` paketinin içinde geliyor, yeni paket gerekmez. |
| S6 | ATT izni ekran açılmadan (`runApp`'ten önce) isteniyor | [main.dart:60](lib/main.dart:60) | iOS bu durumda izin penceresini bazen hiç göstermez. Gösterilmezse reklam takip izni hiç alınmaz, iOS reklam geliri düşer. Cihazda denenip doğrulanmalı. |
| S7 | Firebase'de kullanıcının Pro olup olmadığı (user property) kaydedilmiyor | `analytics_service.dart` | Pro ve ücretsiz kullanıcıların davranışı ayrı ayrı incelenemiyor. |
| S8 | RevenueCat ile Firebase bağlı değil (`setFirebaseAppInstanceId` çağrılmıyor) | `revenuecat_service.dart` | Yenileme, iptal, deneme→abonelik dönüşümü Firebase'e düşmüyor. |
| S9 | Apple Ads token toplanmıyor (`enableAdServicesAttributionTokenCollection`) | `revenuecat_service.dart` | Aboneliklerin hangi Apple Ads kampanyasından geldiği görünmüyor. **Ayrı onay gerekiyor.** |
| S10 | Ödüllü reklam yüklenemezse kullanıcı reklamsız +1 hak alıyor | [ad_service.dart:255](lib/services/ad_service.dart:255) | Kullanıcı için iyi, ama ne sıklıkta olduğu bilinmiyor. Ölçülmeli. |
| S11 | Paywall rozeti Türkçede hâlâ "TARİF DEFTERİ PRO" (İngilizcede "TARIFLY PRO") | [premium_sayfasi.dart:330](lib/sayfalar/premium_sayfasi.dart:330), `premium_badge_pro` | Marka tutarsızlığı. |
| S12 | Geçiş reklamı kimlikleri açılış reklamıyla aynı | [ad_service.dart:30](lib/services/ad_service.dart:30) | Şu an kullanılmadığı için zararı yok; ileride açılırsa çalışmaz. Temizlik. |
| S13 | "EN POPÜLER" rozeti yıllık plana sabit yazılmış | `premium_badge_most_popular` | Veri yıllığın en çok satan olduğunu göstermiyorsa yanıltıcı sayılabilir. Veri gelince kontrol edilecek. |

---

## 4. Önceliklendirilmiş öneriler

Etki, emek ve risk: **Y** = yüksek, **O** = orta, **D** = düşük. Etki tahmini nitel; rakam veri gelince eklenecek.

### Öncelik 1: Doğru ölçüm ve doğru bilgi (deneylerden önce şart)

| # | Öneri | Etki | Emek | Risk | Not |
|---|---|---|---|---|---|
| 1 | Abonelik koşulları metnini seçili plana göre göster (süre, fiyat; ömür boyu için "tek seferlik"; Android'de Google Play metni) | Y | D | D | S1. 6 dile yeni metin anahtarları. Görünüm aynı kalır. |
| 2 | Eksik analitik olaylarını ekle (bkz. bölüm 5), `satin_alma`'ya `source` ekle, `ai_limit_doldu` eksiğini düzelt, `is_pro` user property | Y | D | D | S2, S3, S7. Yeni paket yok. |
| 3 | Firebase konsolunda `source`, `package_id` gibi parametreleri "özel boyut" olarak kaydet | Y | D | D | Kod değil, konsol işi. Kaydedilmeyen parametre raporda kaynak bazında görünmez ve geçmişe dönük dolmaz. **Bugün yapılabilir.** |
| 4 | RevenueCat ↔ Firebase bağlantısı (`setFirebaseAppInstanceId` + RevenueCat panelinde Firebase entegrasyonu) | O | D | D | S8. |
| 5 | Apple Ads token toplama | O | D | D | S9. **Ayrı onay bekliyor.** |

### Öncelik 2: Reklam gelirini kurtarma

| # | Öneri | Etki | Emek | Risk | Not |
|---|---|---|---|---|---|
| 6 | AB kullanıcıları için Google UMP onay formu | Y (AB'de) | O | D | S5. AdMob panelinde "Privacy & messaging" altında GDPR mesajı oluşturulmalı. |
| 7 | ATT iznini ilk ekran açıldıktan sonra iste | O | D | D | S6. Önce gerçek cihazda izin penceresi çıkıyor mu bakılmalı. |
| 8 | Paylaşımlara mağaza linki ve olay ekle | O | D | D | S4. Ücretsiz yeni kullanıcı kaynağı. |
| 9 | Banner'ı "adaptive" banner'a çevir (ekran genişliğine uyan banner) | O | D | O | Genelde daha çok kazandırır, ama banner biraz uzar. Görünümü değiştirdiği için senin onayın gerekir. |
| 10 | Açılış reklamına sıklık sınırı (ör. X saatte bir) | ? | D | O | Veri gerekli: açılış reklamı geliri ile 7. gün geri dönüş oranı birlikte bakılmalı. X'i sen belirlersin. |

### Öncelik 3: Küçük temizlikler

| # | Öneri | Etki | Emek | Risk |
|---|---|---|---|---|
| 11 | Türkçe rozeti "TARİFLY PRO" yap | D | D | D |
| 12 | Kullanılmayan geçiş reklamı kodunu kaldır | D | D | D |
| 13 | "EN POPÜLER" rozetini veriye göre doğrula; yıllık en çok satan değilse "EN AVANTAJLI" gibi doğru bir ifadeye çevir | D | D | D |

### Öncelik 4: RevenueCat Experiments ile denenecekler (ertelendi)

**Şimdilik ertelendi:** gerçek satın alma olmadığı için bu deneylerin sonucu ölçülemez. Satın almalar başlayınca yeniden ele alınacak.

Kurallar:
- **Aynı anda tek deney**, tek değişken. Her deney yeterli satın alma birikene kadar sürer (genelde birkaç hafta; süreyi trafiğe göre birlikte belirleriz).
- RevenueCat Experiments iki "offering"i (paket grubu) karşılaştırır. Bu yüzden fiyat, plan ve deneme süresi doğrudan test edilebilir. Paywall metni veya ücretsiz sınır gibi şeyler için uygulamanın offering'in **metadata** alanını okuması gerekir (küçük kod değişikliği).
- Fiyat, deneme süresi, sınır değerlerini ben önermiyorum; sen belirlersin.
- Deneme sunulursa paywall'da deneme süresi ve sonrasında alınacak ücret açıkça yazmalı (Apple kuralı).

| # | Deney | Ne değişir | Ön koşul | Emek |
|---|---|---|---|---|
| D1 | Yıllık planda ücretsiz deneme var / yok | Offering B'de deneme teklifli yıllık ürün | App Store Connect'te deneme teklifli ayrı bir ürün; paywall'ın deneme bilgisini göstermesi (kod) | O |
| D2 | Ömür boyu plan göster / gizle | Offering B'de lifetime paketi yok | Plan bazında gelir verisi | D |
| D3 | Fiyat testi (aylık veya yıllık, tek seferde biri) | Offering B'de farklı fiyatlı ürün | Yeni fiyatlı ürün (fiyatı sen belirlersin) | D |
| D4 | Yıllık planda "aylık karşılığı" küçük yazı ile göster | Metadata ile açılıp kapanır | Metadata okuma kodu. Faturalanan tutar en belirgin kalmalı (Apple kuralı). | D |
| D5 | Linkten tarif çekme: yalnız Pro / ilk N ücretsiz | Metadata'daki N | Metadata okuma + yerel sayaç. N'yi sen belirlersin. | O |
| D6 | Günlük AI hakkı | Sınır değeri | Sınır sunucuda sabit; test için sunucu değişikliği gerekir. En sona bırakılmalı. | Y |

---

## 5. Eklenecek analitik olayları (öneri)

Mevcut olayların adlandırmasına uygun (Türkçe, alt çizgili):

| Olay | Parametreler | Neyi cevaplar |
|---|---|---|
| `satin_alma` (mevcut, genişlet) | + `source` | Hangi paywall para kazandırıyor? |
| `satin_alma_basarisiz` | `source`, `package_id`, `iptal_edildi` (bool) | Ödeme ekranında kaç kişi vazgeçiyor? |
| `paywall_kapatildi` | `source` | Paywall'dan alım yapmadan çıkma oranı |
| `ai_kullanildi` (mevcut, genişlet) | + `kaynak`: `ne_pisirsem` / `klasor_ai` / `link` | AI'nın hangi kullanımı daha değerli? |
| `ai_limit_doldu` (mevcut, düzelt) | + `kaynak` | Limit kaç kişiyi durduruyor? |
| `odullu_reklam` | `sonuc`: `izlendi` / `yarida_kapatildi` / `yuklenemedi`, `yer` | "+1 hak" ne kadar kullanılıyor, reklam ne sıklıkta yüklenemiyor? |
| `yemek_modu_acildi`, `yemek_modu_tamamlandi` | — | Yemek modu gerçekten kullanılıyor mu? |
| `alisveris_listesine_eklendi`, `alisveris_listesi_acildi` | — | Alışveriş listesi değerli mi? |
| `arama_yapildi` | `sonuc_var` (bool) | Arama kullanılıyor mu, sonuç buluyor mu? |
| `klasor_olusturuldu` | `klasor_sayisi` | Kullanıcılar 3 klasör sınırına ne kadar yaklaşıyor? |
| user property `is_pro` | `true` / `false` | Tüm olayları Pro / ücretsiz diye ayırmak |

---

## 6. Senden istenen veriler

Ekran görüntüsü veya CSV yeterli. Son 30 gün olur, 90 gün daha iyi.

**RevenueCat (Charts)**
- [x] Geldi (2026-11-04): 3 satın alma, üçü de Sude ve yakınları. Gerçek abone yok.

**Firebase Analytics (Events)**
- [ ] `paywall_goruldu` sayısı, mümkünse `source`'a göre
- [ ] `satin_alma`, `ai_kullanildi`, `ai_limit_doldu`, `tarif_kaydedildi`, `tarif_paylasildi` sayıları
- [ ] Günlük aktif kullanıcı ve 1. / 7. gün geri dönüş oranı (Retention)

**AdMob**
- [ ] Reklam biçimine göre gelir: App Open, Banner, Rewarded (ve eCPM)
- [ ] Ülkelere göre gelir (AB payını görmek için)

**Apple Ads**
- [ ] Harcama, yükleme sayısı, yükleme başı maliyet

**Sorular**
- [ ] App Store Connect'te herhangi bir planda ücretsiz deneme tanımlı mı?
- [ ] Planların şu anki fiyatları (TR ve ABD)?
- [ ] RevenueCat hesabında Experiments özelliği açık mı?

---

## 7. Kullanıcı nerede kayboluyor? (asıl soru)

Gerçek abone olmadığı için önce şu zincirin hangi halkasında kopma olduğunu bulmak gerekiyor:

| Adım | Firebase'de bakılacak | Kopma buradaysa anlamı |
|---|---|---|
| 1. Yükleme | `first_open` | Az yükleme var; sorun mağaza sayfası / reklam. |
| 2. İlk değer | `tarif_kaydedildi`, `ai_kullanildi` | Kullanıcı ilk tarifi kaydetmeden bırakıyor; sorun ilk açılış deneyimi. |
| 3. Sınıra çarpma | `ai_limit_doldu`, `paywall_goruldu` (`klasor_limit`, `tarif_limit`, `link_pro_only`) | Kimse sınıra çarpmıyorsa ücretsiz sürüm Pro'ya ihtiyaç bırakmıyor. |
| 4. Paywall | `paywall_goruldu` toplamı | Çok kişi görüp hiç alım yoksa sorun paywall, fiyat ya da değer anlatımı. |
| 5. Alım | `satin_alma` | — |

Hangi adımda kopma olduğuna göre bir sonraki iş seçilecek. Sınırları daraltmak gibi kararlar ancak bu tablo dolunca ve senin onayınla.

---

## 8. Önerilen ilk adımlar (senin onayınla)

1. **Bugün, kod yok:** Firebase'de `source` parametresini özel boyut olarak kaydet (öneri 3) ve bölüm 7'deki olay sayılarını paylaş.
2. **Öneri 1 + 2:** Abonelik koşulları metnini düzelt, analitik eksiklerini tamamla. Tek sürümde çıkabilir. Bu tek başına para getirmez; kopmanın yerini görünür yapar.
3. **Öneri 6 + 7:** UMP onay formu ve ATT zamanlaması. Gerçek abone olmadığı için şu an doğrudan gelire en yakın iş bu.
4. Deneyler (öncelik 4): satın almalar başlayınca.

Öneri 5 (Apple Ads token) ayrıca onayını bekliyor.

---

## 9. Yapılanlar (2026-11-04)

Plan: [docs/superpowers/plans/2026-11-04-gelir-olcumu.md](docs/superpowers/plans/2026-11-04-gelir-olcumu.md). Push yapılmadı.

| Commit | Ne |
|---|---|
| b103bfa | Analitik olayları ve `is_pro` kullanıcı özelliği (öneri 2) |
| ff140c4 | `paywall_kapatildi`, `satin_alma_basarisiz`, `satin_alma`'ya `source` (S2) |
| 751cd59 | `ai_limit_doldu` eksik sayımı (S3), `odullu_reklam` (S10) |
| 9c3c4b7 | Yemek modu, alışveriş listesi, arama, klasör olayları |
| de1c6ae | Tüm paylaşımlara mağaza linki (S4, öneri 8) |
| 11ee6cf | Abonelik koşulları plana göre (S1, öneri 1); rozetler "TARIFLY PREMIUM" ve "EN AVANTAJLI" (S11, S13) |
| b3d6763 | RevenueCat ↔ Firebase ve Apple Ads token (S8, S9; öneri 4, 5) |
| b80201e | AB onay formu (UMP) ve ATT zamanlaması (S5, S6; öneri 6, 7) — cihazda denenmedi |
| 38df59e | Kullanılmayan geçiş reklamı kodu silindi (S12, öneri 12) |

**Konsol işleri tamam (2026-11-04):** Firebase özel boyutlar, RevenueCat ↔ Firebase, RevenueCat ↔ Apple Ads, AdMob GDPR mesajı.

**Sırada:** iPhone'da Görev 8 kontrolü → yeni sürüm → 2–4 hafta veri → bölüm 7'deki tabloyu doldur.
