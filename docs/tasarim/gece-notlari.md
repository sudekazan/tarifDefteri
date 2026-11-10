# Gece notları (kil tasarımı, `kil-gece` dalı)

Gece çalışmasında Sude'ye sorulamayan sorular ve sabah bakılacaklar. Her aşama kendi başlığı altında.

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

