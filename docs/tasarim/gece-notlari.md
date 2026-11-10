# Gece notları (kil tasarımı, `kil-gece` dalı)

Gece çalışmasında Sude'ye sorulamayan sorular ve sabah bakılacaklar. Her aşama kendi başlığı altında.

## Sabah özeti (2026-11-10)

Aşama 1–10 bitti. Aşama 4–10 `kil-gece` dalında, push yapılmadı. Ayrıntılar aşağıda, her aşamanın kendi başlığında.

### Karar vermen gereken sorular
Gece hep mevcut davranışı koruyan seçenekle devam edildi. Cevap "böyle kalsın" ise bir şey yapmak gerekmiyor.

**Hepsini ilgilendiren**
1. **Büyük yazıda başlıklar.** Ne pişirsem, Alışveriş, Premium, yemek modu ve diyaloglarda başlıklar en fazla 2 kat büyüyor. Bu sınır uygun mu? (Aşama 5, 6, 9)
2. **İç sayfa başlıkları ve ana sayfa başlığı sınırsız büyüyor** (Aşama 10'da bulundu). 320 genişlik ve 3.2 kat yazıda klasör içi, tarif detayı ve tarif oluşturmadaki Caveat 34 başlık kelime ortasından bölünüyor ("Çorbal-ar", "Tarif Düzenl-eme"). Defterim'deki "Tarifly" başlığı da "Ta…" diye kısalıyor. 1. sorudaki 2 kat sınırı bunlara da uygulansın mı? Değişiklik tek yerde: `KilSayfaBasligi` / `KilIcSayfa` ve ana sayfa başlığı.
3. **En büyük yazıda uzun kelimeler bölünüyor.** Tek başına satıra sığmayan kelimeler ("Patlıcanları", "Fotoğra-f Ekle", "Zeytinyağı", "Medyadan") her ekranda bölünüyor. Taşma yok. Bu boyutta gövde yazısı küçülsün mü, yoksa böyle kalabilir mi? (Aşama 4–9)

**Ekran ekran**
4. **Tarif oluşturma:** `flutter_quill` ve `flutter_quill_extensions` hiç kullanılmıyor. Kaldırılsınlar mı? (Aşama 4; aşağıdaki "silinebilecekler" listesinde de var.)
5. **Yemek modu:** Zamanlayıcı yok, eklenmedi. İster misin? İstersen adım metnindeki "25 dakika" gibi süreden mi başlasın, yoksa süreyi elle mi gireceksin? (Aşama 5)
6. **Arama:** Kutuda "Klasör ara...", sonuç yokken "…klasör bulunamadı." yazıyor ama aranan şey tarif. "Tarif ara..." ve yeni bir "…tarif bulunamadı." metnine geçilsin mi? (Aşama 7)
7. **Alışveriş:** Boş liste kartının metni uygun mu? "Temizle" eskisi gibi onay sormuyor; sorsun mu? (Aşama 7)
8. **Premium:**
   - Satın alma düğmesinin metni ne olsun? Şu an "PRO'YA GEÇ VE SINIRLARI KALDIR".
   - "EN AVANTAJLI" ve "TARİFLY PREMIUM" büyük harfle yazılıyor. Normal yazıma geçsinler mi?
   - Paket yüklenemeyince çıkan koşul metni Android'de de "Apple Kimliği" diyor. Android için ayrı bir metin olsun mu? (Aşama 8)
9. **Diyaloglar:**
   - Güncelleme uyarısı Android'de kil diyaloğuna döndü; iOS'ta sistem uyarısı olarak kaldı. Uygun mu?
   - Silme ve çıkış onayları iOS'ta sistem (Cupertino) uyarısı olsun mu?
   - Onay diyaloglarında ana düğme üstte, "Vazgeç" altta. Eskiden yan yanaydı. Bu sıra uygun mu? (Aşama 9)
10. **Bildirimler:** Sınır uyarıları turuncu yerine kiremit renginde. "Geri yükleme bulunamadı" bildirimi Profil'de gri, Premium'da kırmızı; ikisi aynı renk olsun mu? (Aşama 9)
11. **Giriş:**
    - Google düğmesinde Material'ın "G" ikonu var. Resmi Google logosu istersen bir görsel dosyası eklemek gerekir.
    - Apple düğmesi kil tarzında. App Store incelemesinde sorun çıkarsa Apple'ın siyah/beyaz düğmesine geçilir. (Aşama 9)
12. **Profil:** Dosya hâlâ `lib/screens/settings_page.dart` (`SettingsPage`). `lib/sayfalar/profil_sayfasi.dart` olarak taşınsın mı? (Aşama 9)
13. **Açılış ekranı ve ikon** (Aşama 10'da bulundu):
    - `flutter_native_splash` açılış ekranı hâlâ eski renklerde: açıkta `#F8F9FC`, koyuda `#10121A`. Kil kremi `#FFFBEB` ve koyu kahve `#1C1412` olsun mu? Değişirse `dart run flutter_native_splash:create` yeniden çalıştırılmalı.
    - Uygulama ikonu ve mağaza ekran görüntüleri yenilenecek mi? (Plandaki açık soru.)
14. **Silinebilecekler:** "Aşama 10 / silinebilecekler" listesindekiler silinsin mi? Gece hiçbir şey silinmedi.

### Cihazda özellikle bakılacak yerler
Testlerde fontlar ve emoji olmadığı ya da eklentiler taklit edildiği için aşağıdakiler yalnızca cihazda doğrulanabilir.
- **Lottie bekleme animasyonu** ("Şefe Sor" ve klasör içinden yapay zekâyla tarif): açık ve koyu modda renkler (mor yerine terrakota, kâse ve şişe adaçayı; alevler kırmızı kaldı), koyu modda beyaz dikdörtgen kalmamış olmalı.
- **Premium:**
  - Gerçek RevenueCat paketleriyle fiyatlar, paket sırası ve "EN AVANTAJLI".
  - Koşul metnindeki "→" işareti (testte kutu çıkıyordu).
  - Satın alma düğmesinin iki satıra inmesi ve satın alma sırasındaki bekleme katmanı.
  - Pro olunca alt banner'ın kalkması.
- **Giriş:**
  - Google ve Apple ile giriş, şifre sıfırlama.
  - Girişten sonra yerel tariflerin birleşmesi, ezilmemesi (`NASIL_TEST_EDILIR.md`).
  - Profil'de giriş yöntemi hapı ("Google ile giriş yapıldı").
- **Emojiler:** Şef emojisi, güncelleme başlığındaki 🎉 🚀 ve dil seçimindeki bayraklar testte kutu çıkıyordu.
- **Kabuk:**
  - Alt sekme çubuğu ile banner reklamın yerleşimi.
  - Durum çubuğu ikonlarının açık ve koyu modda okunması.
  - Android geri tuşunun önce Defterim'e dönmesi.
- **Koyu mod:** Profil'deki anahtarla anında geçiş, her sekmede bir kez.
- **En büyük yazı:** iOS'ta Ayarlar › Erişilebilirlik › Ekran ve Metin Boyutu › Daha Büyük Metin'i en sona alıp her sekmeye bak. Testte 3.2 kat denendi.
- **Yemek modu:** Ekranın açık kalması ve "Tamamla"dan sonra değerlendirme isteği.
- **Güncelleme uyarısı:** iOS'ta sistem uyarısı, Android'de kil diyaloğu.
- **Klasör ikonları:** İkon seçilmeden açılmış eski klasörlerde klasör ikonu görünmeli.
- **Açılış ekranı:** Eski renkte (13. soru); kil temasına geçişte renk sıçraması olup olmadığına bak.

## Aşama 4 (tarif detayı ve tarif oluşturma)

### Sorular
- **`flutter_quill` kullanılmıyor.** `flutter_quill` ve `flutter_quill_extensions` `pubspec.yaml`'da var ama `lib/` içinde hiçbir yerde içe aktarılmıyor; tarif oluşturma bölüm/madde listesiyle çalışıyor. Plandaki "Quill araç çubuğu ve renkleri" maddesi bu yüzden boşa düştü. Paketler kaldırılsın mı? (Uygulama boyutunu ve derleme süresini azaltır; gece paket değişikliği yapılmadı.) Kaldırılırsa CLAUDE.md'deki "Tarif editörü: flutter_quill" satırı da güncellenmeli.
- **En büyük yazıda tek uzun kelime bölünüyor.** 320 genişlik ve 3.2 kat yazıda düzen doğru (ikonlar metnin üstüne çıkıyor), ama tek başına satıra sığmayan kelimeler yine bölünüyor: Caveat 26 bölüm başlığı ("Malzeme-ler", 83 pt), uzun madde kelimeleri ("Patlıcanla-rı") ve `KilDugme`'deki "Fotoğra-f Ekle" (Aşama 1 bileşeni). Fotoğraf kutucuklarındaki "Görsel bulunamadı" yazısı da 120 px'lik kutuda "Gör…" diye kesiliyor. Bölüm başlıkları büyük yazıda Quicksand'e mi geçsin, yoksa böyle kalabilir mi? (Gece: dokunulmadı, mevcut hali korundu.)

### Bilgi
- Dokunulmayan ve aşama 9'a kalan: "Değişiklikler kaybolacak" uyarısı (sabit amber/kırmızı renkler), madde düzenleme diyaloğu, büyük fotoğraf diyaloğu (siyah zemin), kaydetme sırasındaki yükleniyor göstergesi ve snackbar'lar (yeşil/kırmızı).
- Kullanılmaz hale gelen dosya yok. İki sayfadaki `_getSectionIcon` ve `_buildErrorWidget` kopyaları kodun içinden kalktı (yerine `tarifBolumIkonu`, `TarifGorseli`).
- `tarif_detay.dart`'taki klasör adı çevirisi (`_showMoveDialog`) `klasorGorunenAdi` ile aynı işi yapıyor ama `Map` üzerinden çalışıyor; davranışı korumak için olduğu gibi bırakıldı.
- `flutter analyze`: 74 bulgu, hepsi eski kod (Aşama 3 sonunda 103). Aşama 4 dosyalarında bulgu yok; `tarif_olusturma.dart`'taki eski uyarılar da temizlendi. Tek uyarı (`warning`) `lib/tarifler_data/klasor_data.dart:28` (`IconData(codePoint)` sabit değil, ikon ağacı küçültmesini etkiler; derleme `--no-tree-shake-icons` ile yapıldığı için sorun çıkarmıyor).
- Test görüntüleri: `build/gecici_test/asama4_ekranlar_test.dart` (commit'e girmez). Tarif detayı gerçek `TarifDetay` sayfasıyla, tarif oluşturma (Firebase istediği için) `build`'in kopyasıyla çizildi. 20 görüntüde taşma yok.

## Aşama 5 (yemek yapma modu)

### Sorular
- **Zamanlayıcı yok.** Görevde "adımlar, zamanlayıcı ve ekranın açık kalması" geçiyordu, ama yemek yapma modunda hiç zamanlayıcı yoktu (ne kodda ne metinlerde). Yeni bir özellik olduğu için eklenmedi. İstenirse: adım metnindeki "25 dakika" gibi süreleri bulup adımın altına "25 dk zamanlayıcı başlat" düğmesi koymak mı, yoksa elle süre girilen basit bir zamanlayıcı mı?
- **Üst/alt kısım yazısı en fazla 2 kat.** 3.2 kat yazıda üst kısım, ilerleme ve alt düğmeler adıma yer bırakmıyordu. Bunlar, malzeme özeti ve "Adım 2" başlığı en fazla 2 kat büyüyor (sekme etiketlerindeki 1.3 sınırı gibi); adım ve malzeme yazıları sınırsız. Uygun mu?
- **En büyük yazıda tek uzun kelime yine bölünüyor** (Aşama 4'teki soruyla aynı): 320 genişlik ve 3.2 kat yazıda 26'lık adım metninde "Patlıcanları", malzemede "patlıcan" satıra sığmıyor. Adım metni bu boyutta küçülsün mü?

### Bilgi
- Alt düğmeler etiketler sığmazsa alt alta diziliyor; 402 genişlikte Türkçe yan yana, 320 genişlikte (tr, fr, de) alt alta.
- `KilDugme`'ye `buyuk` seçeneği eklendi (56 yükseklik, 18 yazı, 24 ikon); başka ekran etkilenmedi.
- `flutter analyze`: 59 bulgu, hepsi eski kod (Aşama 4 sonunda 74; yemek modundaki eski `withOpacity` uyarıları kalktı). Aşama 5 dosyalarında bulgu yok.
- Test görüntüleri: `build/gecici_test/asama5_ekranlar_test.dart` (commit'e girmez; `--dart-define=DIL=fr --dart-define=EN=320` ile dil ve genişlik). Gerçek `YemekYapmaModu` sayfasıyla çizildi; 28 görüntüde taşma yok.
- Tüm testler: 165 geçti.

## Aşama 6 (bugün ne pişirsem)

### Sorular
- **Lottie renkleri.** Dosya değiştirilmedi; renkler çizerken eşleniyor (mor → terrakota, pembe kâse ve yeşil şişe → adaçayı). Alevler mercan kırmızısı kaldı. Beğenilmezse eşleme `AiChefLoadingAnimation._dolguEslemesi`'nde tek yerden değişir. Gerçek cihazda bir kez bakılmalı.
- **Başlıklar en fazla 2 kat.** Caveat başlıklar ve bekleme kartı yazısı en fazla 2 kat büyüyor (Aşama 5 ile aynı soru). Uygun mu?
- **En büyük yazıda uzun kelimeler** (Aşama 4–5'teki soru): "+1 hak" diyaloğunun gövde metni 320 genişlikte 3.2 katta yine bölünüyor.

### Bilgi
- Önceki sürümde koyu modda bekleme animasyonunun beyaz arka planı kartın ortasında beyaz dikdörtgen olarak görünüyordu; düzeldi.
- Öğün ve süre seçenekleri yatay kaydırma yerine alt satıra sarılıyor.
- `flutter analyze`: 53 bulgu, hepsi eski kod (Aşama 5 sonunda 59). Aşama 6 dosyalarında bulgu yok.
- Test görüntüleri: `build/gecici_test/asama6_ekranlar_test.dart` ve `asama6_lottie_test.dart` (commit'e girmez); 20 görüntüde taşma yok.
- Tüm testler: 184 geçti.


## Aşama 7 (alışveriş listesi ve arama)

### Sorular
- **Arama ekranında "klasör" metinleri.** Tarif arama ekranının kutusunda "Klasör ara..." (`folders_search_hint`), sonuç yokken "Aradığınız kritere uygun klasör bulunamadı." (`folders_search_no_results`) yazıyor; ama aranan şey tarif. Metin korunmak için gece değiştirilmedi. Öneri: kutuda ana sayfadaki gibi `recipes_search_hint` ("Tarif ara..."), sonuç yokta yeni bir "…uygun tarif bulunamadı." metni. Değişsin mi?
- **Alışveriş listesi boş durumu.** Önce liste boşken ekran boş kalıyordu; şimdi bir kart var: "Listen boş" / "Eklediğin malzemeler burada görünür. Tarif detayındaki sepet düğmesiyle de ekleyebilirsin." (altı dilde). Metin uygun mu?
- **"Temizle" düğmesinin yeri.** Eskiden üst çubukta etiketsiz bir ikondu (alınan yokken de görünüyordu). Şimdi "Alınanlar" başlığının yanında, yalnızca alınan varken. Eskisi gibi onay sormuyor; sorsun mu?
- **En büyük yazıda uzun kelimeler** (Aşama 4–6'daki soru): 320 genişlik ve 3.2 katta "Zeytinyağı" ve arama bilgi kartındaki "Aradığınız" satıra sığmıyor, bölünüyor.

### Bilgi
- Liste işlemleri, kayıt anahtarları, arama mantığı ve olay adları değişmedi; testler bunları gerçek sayfayla denetliyor.
- Aynı malzeme iki kez eklenebiliyordu, öyle kaldı.
- `flutter analyze`: 49 bulgu, hepsi eski kod (Aşama 6 sonunda 53; arama sayfasındaki eski uyarılar kalktı). Aşama 7 dosyalarında bulgu yok. Ağ yoktu; analiz ve testler `--no-pub` ile çalıştı.
- Test görüntüleri: `build/gecici_test/asama7_ekranlar_test.dart` (commit'e girmez); 22 görüntüde taşma yok.
- Tüm testler: 205 geçti.

## Aşama 8 (Premium)

### Sorular
- **Satın alma düğmesinin metni** (plandaki açık soru): şu an "PRO'YA GEÇ VE SINIRLARI KALDIR", büyük harf. Değişmedi. Büyük harfli uzun metin okunması zor; 402 genişlikte iki satıra iniyor. Öneri: "Pro'ya geç" gibi kısa ve normal yazımlı bir metin. Senin kararın.
- **"EN AVANTAJLI" ve "TARİFLY PREMIUM" büyük harf.** Değişmedi; kil tarzında diğer rozetler normal yazımlı ("Pro", "Favoriler"). Normal yazıma geçsin mi?
- **Koşullardaki "→" işareti** (ör. "Google Play → Abonelikler"): Quicksand'de bu işaret yok, telefonda başka bir yazı tipinden çizilir. Test görüntüsünde kutu çıkıyor (testte yedek yazı tipi yok). Cihazda bakılmalı.
- **Paket yokken koşul metni.** Paket gelmeyince eski genel metin çıkıyor ve Android'de de "Apple Kimliği" diyor (`premium_sub_terms_body`). Önceden de böyleydi; Android için ayrı genel metin olsun mu?
- **Profil'deki Pro kartı.** "Premium'a Geç" satırı kiremit karta döndü; sayfanın geri kalanı aşama 9'da yenilenecek. Aşama 9'daki profil tasarımında bu kartın yeri (hesap bilgisinin altında mı) konuşulmalı.
- **En büyük yazıda uzun kelimeler** (önceki aşamalardaki soru): 320 genişlik ve 3.2 katta kenar boşlukları daraltıldı, "Reklamsız" artık sığıyor; ama "Medyadan" gibi uzun kelimeler hâlâ bölünüyor.

### Bilgi
- Fiyat, ürün kimliği, paket mantığı, satın alma / geri yükleme akışı ve analitik olaylar değişmedi; testler gerçek sayfayla sahte paketlerle denetliyor (`PremiumSayfasi.paketGetir`).
- Uygulamada Pro kilidi ikonu yok; tarif ekleme alt sayfasındaki kilit giriş için.
- `flutter analyze`: 41 bulgu, hepsi eski kod (Aşama 7 sonunda 49; Premium ve Ayarlar'daki eski `withOpacity` uyarıları kalktı). Aşama 8 dosyalarında bulgu yok.
- Test görüntüleri: `build/gecici_test/asama8_ekranlar_test.dart` (commit'e girmez); 50 görüntüde taşma yok. Şef emojisi testte kutu görünüyor (testte emoji yazı tipi yok), cihazda normal.
- Tüm testler: 222 geçti.

## Aşama 9 (giriş, Profil, güncelleme, diyaloglar ve snackbar'lar)

### Sorular
- **Güncelleme uyarısı Android'de değişti.** Eskiden her platformda Cupertino (iOS tarzı) diyalogdu. "iOS'ta uyarı adaptif kalsın" isteğine göre iOS ve macOS'ta Cupertino kaldı (düğmeler terrakota), Android'de kil diyaloğu oldu. Uygun mu?
- **Uygulama diyalogları iOS'ta Material.** Eskiden de öyleydi (hiçbiri `showAdaptiveDialog` değildi), korundu. Silme ve çıkış onayları iOS'ta Cupertino uyarısı olsun mu? Olursa kil görünümü yalnızca Android'de kalır.
- **Düğme sırası.** Onay diyaloglarında ana eylem üstte tam genişlik, "Vazgeç / Hayır / İptal" altında soluk metin düğmesi (büyük yazıda bölünmesin diye alt alta). Eskiden yan yanaydı, vazgeç soldaydı. Uygun mu?
- **Sınır ve "Pro'ya özel" uyarıları** turuncu yerine kiremit (öne çıkan kart) snackbar; "AI için giriş gerekli" hata renginde, "Giriş Yap" eylemiyle. Geri yükleme bulunamadı bildirimi Profil'de gri (bilgi), Premium'da kırmızıydı; ikisi de eskisi gibi bırakıldı. Birleştirilsin mi?
- **Google düğmesindeki "G".** Eskiden mavi bir "G" harfiydi; şimdi Material'ın `g_mobiledata` ikonu, terrakota (kil rengi). Google'ın resmi logosu istenirse görsel dosya gerekir (yeni varlık).
- **Apple ile giriş düğmesi** eskisi gibi kendi tasarımımız (ikincil kil düğme, Apple ikonu). Apple'ın kuralları özel düğmeye izin veriyor ama incelemede sorun çıkarsa siyah/beyaz resmi stile geçmek gerekebilir.
- **Profil'de "Premium" başlığı** kalktı; Pro kartı hesap kartının hemen altında, kartın kendi başlığı "Premium'a Geç" / "Premium Aktif". "Ayarlar" bölüm başlığı koyu mod ve dil için kullanıldı.
- **Dosya adı.** Profil ekranı hâlâ `lib/screens/settings_page.dart` / `SettingsPage` (dosya silinmedi, yeniden adlandırılmadı). İstenirse `lib/sayfalar/profil_sayfasi.dart` olarak taşınabilir.
- **Büyük yazıda başlıklar.** Diyalog başlıkları en fazla 2 kat büyüyor (önceki aşamalardaki başlık sınırı gibi); gövde ve düğmeler sınırsız. 3.2 katta metin kutusu etiketleri ("E-po…", "Yeni İs…") Flutter'ın kendi davranışıyla kısaltılıyor; uzun kelimeler (ör. güncelleme metni) yine bölünüyor.
- **Güncelleme başlığındaki 🎉 ve 🚀** test görüntüsünde kutu çıkıyor (testte emoji yazı tipi yok); cihazda normal.

### Bilgi
- `flutter analyze`: 20 bulgu, hepsi eski kod (Aşama 8 sonunda 41). Aşama 9'da değişen dosyalarda yeni bulgu yok (`klasor_ici.dart:196` ve `klasor_data.dart` eskiden kalma).
- Şifre gösterme düğmesinin ekran okuyucu etiketi yok (eskiden de yoktu; yeni metin gerektiği için eklenmedi).
- Test görüntüleri: `build/gecici_test/asama9_ekranlar_test.dart` (commit'e girmez); 40 görüntüde taşma yok.
- Tüm testler: 274 geçti.


## Aşama 10 (son tarama)

### Sorular
Sorular yukarıdaki sabah özetinde: 2 (iç sayfa ve ana sayfa başlıkları büyük yazıda), 13 (açılış ekranı renkleri) ve 14 (silinebilecekler).

### Bilgi
- **Elle yazılmış renkler:** `grep -rn --include='*.dart' -E "Color\(0x|Colors\." lib` 62 sonuç veriyor (başlangıçta yaklaşık 660). Hepsi izinli yerlerde:
  - 54'ü `lib/theme/kil_renkleri.dart` içindeki palet tanımları.
  - 2'si `lib/builders/app_theme_builder.dart` içinde: `_saydam` ve `_siyah`. Siyah, temanın `shadow` ve `scrim` rengi; Material'ın varsayılanı da siyah, karartma saydamlığı Flutter'dan geliyor.
  - 6'sı `Colors.transparent`.
  - `Color.fromARGB`, `fromRGBO`, `CupertinoColors` ve başka sabit renk yok.
- **Koyu mod turu:** `build/gecici_test/asama10_tur_test.dart` (commit'e girmez) 11 ana ekranı gerçek sayfalarıyla çiziyor: Defterim, klasör içi, tarif detayı, tarif oluşturma, yemek modu, Ne pişirsem, Alışveriş, arama, Premium, giriş, Profil. Her ekran açık ve koyu modda, 402 genişlikte 1x ve 320 genişlikte 3.2 kat yazıyla çizildi; 44 görüntünün hiçbirinde taşma yok.
  - Defterim, klasör içi ve tarif oluşturma ilk kez kopya yerine gerçek sayfayla çizildi. Firebase, AdMob onayı ve Firebase Auth kanalları testte taklit edildi.
  - Test her yazının rengini arkasındaki zemine göre ölçtü: yazıda en az 4.5, ikonda en az 3.0.
  - Sınırın altında kalan 24 ölçüm de yanlış alarm: görünmeyen ipucu yazıları (saydamlığı 0, kutu doluyken ya da etiket yukarı kalkınca), renkli emojiler (yazı rengi emojiye işlemez) ve işaretsiz onay kutusunun 0 ölçekle gizlenen onay ikonu.
  - Gerçek bir kontrast hatası çıkmadı. Kenarlar ve klasör renkleri zaten `test/kil_renkleri_test.dart` içinde denetleniyor.
- **En büyük yazı turu:** Taşma yok. Uzun kelimelerin bölünmesi önceki aşamalardaki gibi. Yeni bulunan: iç sayfa başlıkları ve ana sayfa başlığı 3.2 katta sınırsız büyüyor (sabah özetinde 2. soru). Mevcut davranış korundu, kod değişmedi.
- `flutter analyze`: 20 bulgu, Aşama 9 sonundakiyle aynı, hepsi eski kod. Bu aşamada `lib/` değişmedi.

### Aşama 10 / silinebilecekler
Hiçbiri silinmedi. Silmeden önce senin onayın gerekiyor.

**Dosyalar ve sınıflar.** `lib/` altındaki 64 Dart dosyasının hepsi bir yerden içe aktarılıyor. Hiç kullanılmayan sınıf ya da enum yok. Aşama 1–9'da boşa düşen dosyalar (`theme_settings_page.dart`, `klasorler_with_theme.dart` vb.) o aşamalarda zaten kaldırılmıştı.

**Paketler.** Bunlar `pubspec.yaml`'da var ama `lib/` içinde hiç içe aktarılmıyor:
- `flutter_quill`, `flutter_quill_extensions`: Tarif oluşturma bölüm ve madde listesiyle çalışıyor (Aşama 4'teki soru). Kaldırılırsa CLAUDE.md'deki "Tarif editörü: flutter_quill" satırı da güncellenmeli.
- `showcaseview`: Tanıtım turu yok.
- `uuid`
- `cloud_functions`: `functions/index.js` içindeki `generateRecipe` yorum satırında, yapay zekâ istekleri `backend/` üzerinden gidiyor.
- `cupertino_icons`: `CupertinoIcons` hiçbir yerde kullanılmıyor. Flutter şablonundan kalma ve küçük bir paket; kalabilir.

**Kullanılmayan yöntemler.** Hiçbir yerden çağrılmıyorlar:
- `FirebaseService.restoreFromFirebaseToLocal` (`lib/services/firebase_service.dart:289`). Girişteki birleştirme `mergeLocalAndCloudData` ile yapılıyor.
- `FirebaseService.saveGeneratedRecipeToFirestore` (`lib/services/firebase_service.dart:717`). Yapay zekâ tarifleri normal tarif kaydıyla saklanıyor.
- `ReviewService.resetForTesting` (`lib/services/review_service.dart:83`). Geliştirme yardımcısı; elle test için kalabilir.

**Çeviri anahtarları.** 59 anahtar `lib/` içinde hiç kullanılmıyor. Her biri altı dil dosyasında da var. Dinamik kurulan anahtarlar (`premium_terms_*_ios/android`, dil adları) bu listeye alınmadı.
- Tema seçiminden kalanlar: `theme_name_pastel_green`, `theme_name_pastel_blue`, `theme_name_pastel_lilac`, `theme_name_pastel_pink`, `theme_name_pastel_orange`, `theme_name_pastel_gray`, `theme_name_pastel_turquoise`, `theme_name_pastel_red`, `theme_name_pastel_purple`, `theme_name_pastel_yellow`, `settings_theme_title`.
- Eski ana sayfa ve gezinmeden kalanlar: `home_title`, `home_subtitle`, `btn_get_started`, `btn_favorites`, `btn_settings`, `btn_change_language`, `folder_title`, `recipes_title`, `no_recipes`, `add_recipe`, `add_option_title`, `folder_add_title`, `folder_name_hint`, `recipes_tap_for_details`.
- Eski giriş ekranından kalanlar: `auth_title_login`, `auth_title_register`, `auth_toggle_question_login`, `auth_toggle_question_register`, `auth_toggle_button_login`, `auth_toggle_button_register`, `auth_register_success`, `auth_error_code_prefix`, `auth_error_unexpected_prefix`.
- Eski Ayarlar ekranından kalanlar: `settings_premium_title`, `settings_logged_in`.
- Eski Premium ekranından kalanlar: `premium_feature_ads`, `premium_feature_ads_desc`, `premium_feature_ai`, `premium_feature_ai_desc`, `premium_feature_link`, `premium_feature_link_desc`, `premium_no_packages`, `premium_updating_packages`, `premium_offerings_unreachable`, `premium_upgrade_button`.
- Ne pişirsem ve yapay zekâdan kalanlar: `what_to_cook_btn_try`, `what_to_cook_ingredients_title`, `what_to_cook_limit_dialog_title`, `what_to_cook_limit_dialog_body`, `what_to_cook_loading_message`, `ai_create_button`, `ai_generating_message`, `ai_success_message`.
- Diğer: `common_error`, `share_error_with_message_prefix`, `recipe_edit_photos_title`, `cooking_mode_steps`, `error_server_unexpected`.

**Varlıklar.**
- `assets/logo.png` `pubspec.yaml`'ın `assets` listesinde, yani uygulamaya paketleniyor (216 KB). Ama Dart kodunda kullanılmıyor; yalnızca `flutter_native_splash` açılış ekranını üretirken okuyor. Dosya kalmalı; yalnızca `assets` listesinden çıkarılabilir.
- `logo_white_bg.png` ve `logo_adaptive_foreground.png` ikon üretiminde kullanılıyor; kalmalı.

**Kökteki tek seferlik betikler.** Uygulamayla ilgisi yok.
- `fix_tr.dart`: `flutter analyze`'daki `avoid_print` bulgusu buradan geliyor.
- `update_langs.py`

**Geçici test dosyaları.** `build/gecici_test/` (Aşama 2–10 test görüntüleri). `build/` git'e girmiyor; istersen silebilirsin.
