# Tarifly yayın öncesi inceleme (2026-11-10)

Dal: `kil-gece` (main'den 20 commit ileride, push yok). Sürüm: 1.0.24+53.
Yöntem: kodun tamamı okundu (ekranlar, servisler, sunucu, mağaza ayarları). Uygulama cihazda çalıştırılmadı; aşağıdaki hatalar kod okunarak bulundu, her birinin yanında nasıl deneneceği yazıyor.

Ölçülenler:
- `flutter analyze`: hata yok. 1 uyarı (`klasor_data.dart:28`, bilinen ikon kodu), 12 bilgi notu (değişken adları, eski `purchasePackage` çağrısı).
- `flutter test`: 289 testin hepsi geçti.
- Çeviri: 6 dilde 362'şer anahtar, eksik yok, Türkçe kalmış metin yok. Kodda kullanılıp dilde olmayan anahtar yok.
- Ekranlarda koda sabit yazılmış renk yok; hepsi `KilRenkleri`'nden geliyor.

## Kısa sonuç

Tasarım, çeviri, satın alma ekranı, hesap silme ve reklam izinleri yayına hazır düzeyde. Yayından önce düzeltilmesi gereken 5 konu var; dördü kullanıcının yazdığı tarifin kaybolmasına ya da kaybolmuş gibi görünmesine yol açıyor, biri reklam politikası riski.

## 1. Yayından önce düzeltilmeli

### 1.1 Aramadan açılan tarifte düzenleme kaydedilmiyor
`lib/sayfalar/arama_sayfasi.dart` (`_tarifiAc`). Tarif detayı düzenlenen tarifi geri döndürüyor, kaydetme işini onu açan sayfa yapıyor. Klasör içi ve Favoriler kaydediyor; Arama sayfası yalnızca listeyi yeniden okuyor. Sonuç: aramayla bulunan tarif düzenlenip "Kaydet"e basılınca değişiklik sessizce kayboluyor.
Deneme: bir tarifi ara, aç, adını değiştir, kaydet, tekrar aç.

### 1.2 Giriş yapmış kullanıcı internetsizken tarif kaydedemiyor
`lib/sayfalar/tarif_ekleme_akisi.dart` (`_tarifEkle`), `bugun_ne_pisisem_sayfasi.dart` (`_tarifKaydet`). Önce Firebase'e yazılması bekleniyor, cihaza ondan sonra yazılıyor. Firestore yazma işlemi internet yokken sunucudan onay gelene kadar bitmez. Sonuç: tarif listede görünmüyor, kullanıcı kaydedilmediğini sanıyor. Fotoğraf varsa `tarif_olusturma.dart` içindeki yükleme bekleme çemberi dakikalarca dönebilir (Firebase Storage varsayılan olarak 10 dakikaya kadar yeniden dener).
Aynı sıra klasör ekleme, silme ve yeniden adlandırmada da var: liste, Firebase cevabı gelmeden yenilenmiyor.
Çözüm yönü: önce cihaza yaz ve ekranı güncelle, Firebase'e arkadan gönder; fotoğraf yüklemesine kısa bir süre sınırı koy.
Deneme: giriş yap, uçak modunu aç, fotoğrafsız ve fotoğraflı birer tarif kaydet.
Girişsiz kullanıcı etkilenmiyor.

### 1.3 Çıkış yapınca cihazdaki tarifler siliniyor, kullanıcı uyarılmıyor
`lib/services/firebase_service.dart` (`signOut`, `_oturumKalintilariniTemizle`). Çıkışta cihazdaki tüm klasör ve tarifler siliniyor. Firebase'e yazma hataları yalnızca konsola yazıldığı için (ör. internet yokken, fotoğraf yüklenemeyince) buluta gitmemiş bir tarif varsa çıkışla birlikte tek kopyası da gidiyor. Onay metni yalnızca "Çıkış yapmak istediğinizden emin misiniz?" diyor.
Çözüm yönü: çıkıştan önce bekleyen yazmaların bitmesini bekle, bitmiyorsa kullanıcıya söyle; onay metnine tariflerin hesapta saklandığını ve tekrar girişte geri geleceğini ekle.

### 1.4 Kutuya yazılıp "+"ya basılmamış madde kaydedilmiyor
`lib/sayfalar/tarif_olusturma.dart` (`_kaydet`). Kullanıcı son malzemeyi ya da adımı yazıp doğrudan "Kaydet"e basarsa o satır tarife eklenmiyor. Tek madde buysa "en az bir madde ekleyin" hatası çıkıyor. Kaydetmeden önce kutularda bekleyen metin maddeye çevrilmeli.
Aynı dosyada küçük bir hata: bölüm silinince alttaki bölümün yazı kutusu bir üsttekiyle karışıyor (kutular sıra numarasıyla tutuluyor).

### 1.5 Açılış reklamı kullanıcı uygulamayı kullanırken çıkabiliyor
`lib/sayfalar/klasorler.dart` (initState), `lib/services/ad_service.dart` (`_showAfterLoad`). Üçüncü açılıştan itibaren reklam 2 saniye sonra isteniyor; hazır değilse "yüklenince göster" işaretleniyor. Yavaş ağda reklam 5–10 saniye sonra, kullanıcı tarif açmışken ya da yazı yazarken tam ekran çıkar. AdMob bunu "beklenmeyen reklam" sayıyor ve hesap kısıtlamasına kadar gidebiliyor.
Çözüm yönü: reklam yalnızca açılışta hazırsa gösterilsin; hazır değilse o açılışta gösterilmesin.

## 2. Önemli, ilk güncellemeye kalabilir

1. **Fontlar internetten iniyor.** Quicksand ve Caveat `google_fonts` ile çalışma anında indiriliyor, uygulamaya gömülü değil. İlk açılış internetsizse sistem fontu görünür, internet varsa yazılar bir an sonra değişir. Font dosyalarını `assets/` altına koymak yeterli; yeni paket gerekmiyor.
2. **Silinen tarif başka cihazdan geri gelebilir.** Birleştirme "yalnızca cihazda olan"ı buluta geri yüklüyor. İki cihaz kullanan biri A'da sildiği tarifi B'yi açınca geri görür. Tek cihazda sorun yok.
3. **Değerlendirme isteği neredeyse hiç çıkmaz.** `review_service.dart` "ilk açılış tarihini" uygulama açılışında değil, ilk tetiklenmede kaydediyor; ardından 7 gün bekliyor. 5. tarif tetiklemesi de yalnızca bir kez çalışıyor. Tarih açılışta kaydedilmeli.
4. **"Buluta yedekle" her zaman "yedeklendi" diyor.** Hatalar servis içinde yutuluyor; internet yokken de başarı mesajı çıkıyor (ya da 1.2'deki gibi bekliyor).
5. **Yemek modu zamanlayıcısı Android'de geç ötebilir.** Bildirim "yaklaşık zamanlı" kuruluyor; telefon uykudayken dakikalarca gecikebilir. Tam zamanlı alarm ek izin ister; karar senin.
6. **Profil › Kullanım koşulları Android'de de Apple'ın sözleşmesini açıyor.** Premium ekranında doğru ayrım var, Profil'de yok.
7. **Dil değişince Ne pişirsem'deki malzeme ve öğün çipleri eski dilde kalıyor** (uygulama yeniden açılana kadar).
8. **Yatay ekran açık.** Ekranlar dikey tasarlandı ama telefon çevrilince yatay dönüyor. Telefonda dikeye kilitlemek en güvenlisi.
9. **Sunucu (`backend/server.js`):** istek metninde uzunluk sınırı yok (maliyet ve kötüye kullanım); 500 hatasında iç hata metni istemciye gidiyor. Kimlik doğrulama, günlük sınır ve hak iadesi doğru çalışıyor.
10. **Çökme raporu yok.** Mağazadaki kullanıcıda uygulama çökerse haberin olmaz. Firebase Crashlytics öneririm (yeni paket; onayınla).
11. **Fotoğraflar:** buluttaki resimler her seferinde internetten çekiliyor, internetsizken görünmüyor; liste küçük resimleri tam boy çözülüyor. Yüklenen fotoğrafın cihazdaki kopyası silinmeden kalıyor. Önbellek için `cached_network_image` öneririm (yeni paket; onayınla).
12. **iOS izin metinleri yalnızca Türkçe.** Kamera, galeri ve izleme izni açıklamaları İngilizce kullanıcıya da Türkçe görünür. `Info.plist`'te desteklenen diller listesi (`CFBundleLocalizations`) de yok.
13. **Hesap silme uyarısında abonelik yok.** Aktif aboneliğin hesap silinince iptal olmadığı, mağazadan iptal edilmesi gerektiği yazmıyor.
14. **Ücretsiz sınır tutarsızlıkları:** Ne pişirsem'den ve "klasöre taşı"dan gelen tarifler 20 tarif sınırına takılmıyor. Ödüllü reklam yüklenemezse hak yine veriliyor (günde en fazla 3; kabul edilebilir).

## 3. Kullanıcı deneyimi önerileri

- **İlk açılış:** yeni kullanıcı boş bir sayfa ve "klasör ekle" görüyor; klasör açmadan tarif ekleyemiyor. Hazır bir "Tariflerim" klasörüyle başlamak ya da ilk tarifi klasörsüz kabul etmek ilk dakikayı kolaylaştırır.
- **Kilitli seçenekler:** "Şefe sor" ve "Linkten tarif" girişsizken kilitli; dokununca yalnızca "Giriş Gerekli" bildirimi çıkıyor. Ne pişirsem'deki gibi "Giriş yap" düğmeli olmalı. "Linkten tarif" ücretsiz kullanıcıya açık görünüyor, adres yazdıktan sonra "Premium'a özel" deniyor; seçenekte baştan Premium rozeti olmalı.
- **Tarif detayı:** favori düğmesi yok (yalnızca listede). Düzenleyip kaydedince detay yerine listeye dönülüyor. Porsiyon "1.0x" yerine "1x" yazmalı.
- **Tarif oluşturma:** hiçbir şey yazılmamışken ya da hiçbir şey değişmemişken de "değişiklikler kaybolacak" uyarısı çıkıyor. Kamera ikonu galeriyi açıyor; "fotoğraf çek" seçeneği yok. Madde ve adımların sırası değiştirilemiyor.
- **Alışveriş listesi:** tarifteki tüm malzemeleri tek dokunuşla ekleme ve listeyi paylaşma yok. Liste buluta yedeklenmiyor. "Temizle" onay sormuyor.
- **Adlandırma:** aynı özellik "AI Şef", "Şefe sor", "Sihirli Şef" ve "Bugün ne pişirsem" adlarıyla geçiyor. Metinlerde "sen" ve "siz" karışık ("Sınırları Kaldırın" / "Dolabındaki"). Tek ad ve tek hitap seçilmeli.
- **Premium ekranı:** ömür boyu paket seçiliyken de "İstediğiniz zaman iptal edebilirsiniz" yazıyor.
- **Banner:** sabit 320×50; yüklenince içerik 50 piksel yukarı zıplıyor. Uyarlanır banner ve yer ayırma daha düzgün durur.
- **Karanlık mod:** yalnızca aç/kapa var; "sistemi izle" seçeneği yok.

## 4. Arayüz değerlendirmesi

İyi olanlar: tek renk kaynağı, 4.5:1 kontrastın testle korunması, büyük yazı desteği (2 kat sınırı, sığmayınca alt satıra inen düzenler), ekran okuyucu etiketleri, boş durum kartları, 48 pt dokunma alanları, koyu modun ayrı tasarlanması.

Dikkat edilecekler: ana sayfada iki ayrı "ekle" düğmesi var (üstte "Yeni klasör", altta yüzen "Yeni tarif"); klasör menüsü (üç nokta) Material açılır menüsü, kil tarzının dışında kalıyor; "SİHİRLİ ŞEF" rozeti büyük harf (Premium ekranında büyük harf kaldırılmıştı).

## 5. Renk temaları

Teknik olarak kolay: ekranlarda sabit renk olmadığı için yeni bir palet, `KilRenkleri`'ne yeni bir açık ve koyu değer seti eklemek demek. Zor olan kısım her paletin 28 rengini iki modda kontrastla doğrulamak, Lottie animasyonunun ve açılış ekranının sabit renkleri ve mağaza görsellerinin tek palete göre hazırlanmış olması.

Önerim: 10 pastel temaya dönmemek. Krem zemin, yazı renkleri ve kil dokusu sabit kalsın; yalnızca vurgu rengi (başlık, ana düğme, seçili çip, öne çıkan kart) değişsin. 3–4 seçenek yeter. Böylece marka tanınır kalır, doğrulanacak renk sayısı paletin dörtte birine iner.

Aday vurgu renkleri ve ölçtüğüm kontrastlar (hepsi 4.5:1'in üstünde):

| Ad | Açık mod | Beyaz yazı / düğme | Başlık / krem | Koyu mod başlık | Başlık / koyu zemin |
|---|---|---|---|---|---|
| Terrakota (şimdiki) | `#9A3412` | 7.3 | 7.1 | `#FDBA74` | 10.8 |
| Zeytin | `#3F6212` | 7.1 | 6.8 | `#BEF264` | 13.9 |
| Vişne | `#9F1239` | 8.0 | 7.7 | `#FDA4AF` | 9.6 |
| Patlıcan | `#6B21A8` | 8.7 | 8.4 | `#D8B4FE` | 10.3 |
| Yaban mersini | `#1E40AF` | 8.7 | 8.4 | `#93C5FD` | 10.1 |

Dikkat: adaçayı yeşili "onay / tamamlandı" anlamında kullanılıyor; Zeytin seçilirse ana düğme ile onay rengi birbirine yaklaşır. Hata kırmızısı da Vişne'ye yakın. Bu ikisi seçilecekse onay ve hata tonları ayrıca ayarlanmalı.

Temaların ücretsiz mi Premium ayrıcalığı mı olacağı ve yayından önce mi sonra mı ekleneceği senin kararın. Benim önerim yayından sonra: 2026-11-09'da tek palete geçildi, mağaza görselleri buna göre yenilenecek; önce 1. bölümdeki hatalar.

## 6. Kontrol edemediklerim

- **Firestore ve Storage güvenlik kuralları** repoda yok (konsolda duruyor). Her kullanıcının yalnızca kendi `users/{uid}` verisine erişebildiğini Firebase konsolundan doğrula.
- Render sunucusunun planı: ücretsiz planda sunucu uyur, ilk yapay zekâ isteği 30–50 saniye sürebilir.
- Gerçek satın alma, Google ve Apple ile giriş, reklamlar ve bildirimler cihaz ister (`docs/tasarim/gece-notlari.md` içindeki cihaz listesi geçerli).
- `android/app/google-services.json` üzerinde commit edilmemiş değişiklik var (72 satır eklenmiş). İçeriğine bakmadım. Bu dosya ve iki `GoogleService-Info.plist` git'te izleniyor; depo herkese açıksa kaldırılmalı.
