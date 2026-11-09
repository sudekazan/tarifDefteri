# Kil tasarımına geçiş planı (Tarifly)

Tarih: 2026-11-09. Durum: **Aşama 1–6 tamamlandı; ekranlar aşama 7'den itibaren yenilenecek.**
Kaynak: UI UX Pro Max'in "Recipe & Cooking App" önerisi (claymorphism) ve Sude ile yapılan önce/sonra görsel çalışması.

## Kararlar (Sude, 2026-11-09)
- Uygulamanın tamamı yumuşak kil tarzına (claymorphism) geçer: kalın açık kenar, alttan sert gölge, yuvarlak köşeler, sıcak yemek renkleri.
- 10 pastel tema kalkar, herkes tek paleti görür. Ayarlar › Tema sayfası ve girişi kalkar.
- Karanlık mod kalır ve koyu kil sürümü yapılır: derinlik gölgeyle değil, kenar ve açık bir üst çizgiyle verilir.
- Gezinme alt sekme çubuğuna geçer: **Defterim, Ne pişirsem, Alışveriş, Profil**. Arama, ana sayfada bir kutu olur. Premium, başlığın yanında küçük bir "Pro" rozeti olur.
- Geçiş aşamalı yapılır: her aşama ayrı commit, her aşamadan sonra simülatörde açık ve koyu modda bakılır.
- 2026-11-09'daki "üst çubuk siyah" kararı bu tasarımla geçersiz kalır, çünkü renkli üst çubuk kalkıyor.
- Profil sekmesi Ayarlar ekranı olarak kalmaz: üstte hesap bilgisi olan ayrı bir profil ekranı olur (aşama 9).
- Ana sayfadaki düğme aşama 3'te "Yeni tarif" olur ve tarif ekleme alt sayfasını açar; aşama 2'de eskisi gibi "Yeni klasör ekle".
- Sekme adları: tr Defterim / Ne pişirsem / Alışveriş / Profil; en Cookbook / What to cook / Shopping / Profile; de Kochbuch / Was kochen / Einkauf / Profil; es Recetario / Qué cocinar / Compras / Perfil; fr Carnet / Que cuisiner / Courses / Profil; pt Caderno / O que cozinhar / Compras / Perfil.

## Renkler
Ekranlarda renk koda sabit yazılmaz. Hepsi bir `ThemeExtension`'dan (aşağıda `KilRenkleri`) okunur.

| Görev | Açık | Koyu |
|---|---|---|
| Zemin | `#FFFBEB` krem | `#1C1412` koyu kahve |
| Kart / yüzey | `#FFFFFF` | `#2A1F1B` |
| Soluk yüzey (sekme zemini, alınanlar) | `#F8F2F0` | `#241A16` |
| Kenar ve kart gölgesi | `#F2E6E2` | `#4A3830` (yalnız kenar) |
| Ana yazı | `#0F172A` | `#FAF3EE` |
| Soluk yazı | `#475569` | `#C9B8AE` |
| Başlık / birincil (terrakota) | `#9A3412` | `#FDBA74` (başlık), `#FB923C` (düğme) |
| Birincil üstündeki yazı | `#FFFFFF` | `#1C1412` |
| Birincil düğme gölgesi | `#7C2D12` | gölge yok, kenar `#C2410C` |
| Öne çıkan kart (kiremit) | `#C2410C`, yazı beyaz | `#3B2418`, yazı `#FDBA74` |
| Vurgu (adaçayı) | `#059669`, yazı siyah | `#34D399`, yazı siyah |
| Seçili çip zemini / yazısı | `#FFEDD5` / `#9A3412` | `#3B2418` / `#FDBA74` |
| Hata | `#DC2626`, üstündeki yazı beyaz | `#F87171`, üstündeki yazı `#1C1412` |
| Hata kutusu zemini / yazısı | `#FEE2E2` / `#991B1B` | `#4A1D1D` / `#FCA5A5` |
| Tanıtan kenar (onay kutusu, metin kutusu) | `#8A766F` | `#8A7268` |
| Vurgu düğmesi gölgesi | `#047857` | gölge yok, kenar `#059669` |
| Koyu kartın üst çizgisi | — | `#6B5246` |

Ölçülen kontrastlar (WCAG): açık modda ana yazı 17.2, soluk yazı 7.3, terrakota başlık 7.0, terrakota düğmede beyaz 7.3, kiremit kartta beyaz 5.2, adaçayında siyah 5.6, seçili çip 6.4. Koyu modda ana yazı 16.5, soluk yazı 8.4, başlık 10.8, turuncu düğmede koyu yazı 8.0, adaçayında siyah 10.9, seçili çip 8.6.

Aşama 1'de ölçülenler (zemin / kart / soluk yüzey üzerinde):
- **Hata, açık:** `#DC2626` zeminde 4.66, kartta 4.83, hata düğmesinde beyaz 4.83. Soluk yüzeyde 4.36 kalıyor; hata yazısı soluk yüzeyin (sekme zemini, alınanlar) üstüne konmaz.
- **Hata, koyu:** `#F87171` zeminde 6.55, kartta 5.79, soluk yüzeyde 6.15; üstündeki koyu yazı 6.55. Hata kutusu yazısı açıkta 6.8, koyuda 7.5.
- **Tanıtan kenar, açık `#8A766F`:** 4.13 / 4.28 / 3.87. **Koyu `#8A7268`:** 4.05 / 3.58 / 3.80. Metin kutusu kenarı 1.5 px, odakta 2 px birincil renk.
- **Onay kutusu:** işaretliyken adaçayı zemin, siyah onay işareti. Adaçayı kartın üstünde açıkta 3.77, koyuda 8.34.
- Süs kenarı (`#F2E6E2` / `#4A3830`) 1.1–1.6 arası; bir öğeyi tanıtmak için kullanılmaz.

Kenarlar yalnızca süs; 1.2 ile 1.4 arası. Bir öğeyi tanıtan kenarlar (onay kutusu, metin kutusu) en az 3:1 olmalı; renkleri yukarıdaki tabloda.

Klasör ikon renkleri (zemin / ikon, ikonun zemine kontrastı):

| Klasör | Açık | Koyu |
|---|---|---|
| Favoriler | `#FFE4E6` / `#BE123C` (5.2) | `#3F1D25` / `#FDA4AF` (7.9) |
| Tatlılar | `#FFEDD5` / `#9A3412` (6.4) | `#3B2418` / `#FDBA74` (8.6) |
| Çorbalar | `#D1FAE5` / `#065F46` (6.8) | `#0F3A2E` / `#6EE7B7` (8.3) |
| Kahvaltılıklar | `#FEF3C7` / `#92400E` (6.4) | `#3A2C12` / `#FCD34D` (9.4) |

Bunlar `KilRenkleri.klasorFavori` vb. olarak kodda. Kontrastlar `test/kil_renkleri_test.dart` içinde denetleniyor; renk değişirse test uyarır.

## Yazı tipi
- **Başlıklar:** Caveat 700, yalnızca 22 pt ve üstü (ekran başlığı 28–34, bölüm başlığı 24–26). Küçük boyutta el yazısı okunmaz.
- **Metin ve arayüz:** Quicksand 500/700. Gövde 16–17 pt; en küçük yazı 11 pt (CLAUDE.md, 2026-11-03).
- `google_fonts` zaten projede, yeni paket gerekmiyor. Türkçe harfler (ş, ğ, ı, İ) aşama 1'de ekranda kontrol edilecek.
- Kullanıcının seçtiği en büyük yazı boyutunda taşma denenecek.
- Görsellerdeki 12 px'lik gövde yazısı, küçük telefon çizimine sığsın diye seçildi; uygulamada yukarıdaki boyutlar geçerli.

## Ortak bileşenler (`lib/widgets/kil/`)
- `KilRenkleri`: `ThemeExtension`, açık ve koyu değerler. `ThemeData` içinde kart, düğme, çip, metin kutusu, `NavigationBar`, alt sayfa ve FAB temaları.
- `KilKart`: beyaz zemin, 2 px kenar, 20 köşe, alttan `0 4 0` sert gölge. Koyu modda gölge yerine kenar ve üstte ince açık çizgi.
- `KilDugme`: birincil (terrakota), ikincil (beyaz), vurgu (adaçayı). Basınca 150–200 ms içinde birkaç piksel aşağı iner; "hareketi azalt" açıksa animasyon yok.
- `KilCip`: seçili ve seçilmemiş hal.
- `KilYuvarlakDugme`: geri, kapat ve ara düğmeleri. Görünen boyut 36, dokunma alanı 48.
- `KilOnayKutusu`, `KilAltSayfa` (alttan açılan pencere).
- Her dokunulan öğe en az 48x48.

## Gezinme
- Yeni bir kabuk ekranı: `NavigationBar` ve 4 sekme. Sekmeler `IndexedStack` içinde tutulur, böylece sekme değişince durum kaybolmaz.
  - Defterim → `klasorler.dart`
  - Ne pişirsem → `bugun_ne_pisisem_sayfasi.dart`
  - Alışveriş → `alisveris_listesi.dart`
  - Profil → `settings_page.dart`
- Banner reklam sekme çubuğunun hemen üstünde durur; Pro kullanıcılarda gösterilmez.
- Android geri tuşu: ilk sekmede değilken önce ilk sekmeye döner.
- **Analitik:** Ekran ve olay adları değişmemeli (2026-11-04 kararı: önce ölçüm). `analytics_service.dart` içindeki ekran olayları sekmelere doğru bağlanmalı.

## Metinler
- Yeni anahtarlar (sekme adları vb.) `assets/lang/` altındaki altı dosyanın hepsine eklenir.
- Premium satın alma düğmesinin metnini **Sude belirler**. Bu bir mağaza/paywall metni, uydurulmaz.

## Aşamalar
Her aşamadan sonra: `flutter analyze`, ilgili testler, simülatörde açık ve koyu modda ekran görüntüsü, commit (Sude'ye sorarak).

1. **Temel — tamamlandı (2026-11-09):** `KilRenkleri`, açık ve koyu `ThemeData`, fontlar ve ortak bileşenler. Tema seçimi kalkar (`AppTheme`, `appThemeColors`, `theme_settings_page.dart`, `AppStateManager.currentTheme`, Ayarlar'daki giriş). Kayıtlı eski tema tercihi sessizce yok sayılır. Ekranlar henüz eski yapıda ama temadan okunan renkleri değişir.
   - Dosyalar: `lib/theme/kil_renkleri.dart` (`context.kil` kısa yolu), `lib/builders/app_theme_builder.dart`, `lib/widgets/kil/` (`kil.dart` hepsini dışa verir).
   - Diyalog başlıkları Caveat değil Quicksand 700 20: çoğu bir cümle, el yazısıyla zor okunuyor. Caveat yalnızca ekran başlıkları (üst çubuk 28), `headline*` ve `display*` stillerinde.
   - Malzeme `Checkbox` da `KilOnayKutusu` gibi adaçayı; `Switch` ve `Radio` birincil renk.
   - `NavigationBar` teması hazır, ama üst kenar çizgisini aşama 2'deki kabuk ekranı çizecek (`NavigationBar`'ın kenar ayarı yok).
   - Testler: `test/kil_renkleri_test.dart` (kontrastlar), `test/kil_bilesenler_test.dart` (48'lik dokunma alanı, "hareketi azalt"), `test/app_theme_builder_test.dart` (en küçük yazı 11, Caveat yalnızca 22 ve üstü).
2. **Gezinme ve ana sayfa — tamamlandı (2026-11-09; simülatörde açık/koyu mod ve en büyük yazı kontrolü Sude'nin isteğiyle sona bırakıldı):** alt sekme kabuğu, yeni ana sayfa (başlık ve Pro rozeti, arama kutusu, "Bugün ne pişirsem" kartı, iki sütunlu klasör kartları, yeni klasör düğmesi).
   - Dosyalar: `lib/sayfalar/ana_kabuk.dart` (`AnaKabuk`), `lib/widgets/kil/kil_sekme_cubugu.dart` (`KilSekmeCubugu`, üst süs kenarını çizer), `lib/widgets/ana_sayfa_parcalari.dart` (`ProRozeti`, `AramaKutusu`, `NePisirsemKarti`, `KlasorKarti`, `KlasorIzgarasi`).
   - Sekmeler ilk seçildiğinde kurulur; açılışta dört ekran birden yüklenmez. Kurulmuş bir sekme yeniden seçilince sayfaya sinyal gider, sayfa verisini tazeler (Defterim klasörleri, Ne pişirsem klasörleri ve kalan hakkı, Alışveriş listeyi, Profil Pro durumunu).
   - Analitik: olay adları aynı. `alisveris_listesi_acildi` eskisi gibi her açılışta, yani Alışveriş sekmesi her seçildiğinde gönderilir; açılışta gönderilmez.
   - Banner kabukta bir kez, sekme çubuğunun hemen üstünde. Kabuğun üstündeki bir sayfa (ör. Premium) kapanınca kabuk yeniden çizilir; Pro olunca banner kalkar (`AnaKabuk.rotaGozlemcisi`). Ayarlar'daki ayrı banner kalktı.
   - "Bugün ne pişirsem" kartı sekmeye geçer. Ne pişirsem sekmesinde geri düğmesi yok; tarif kaydedilince form boşalır ve Defterim'e dönülür.
   - Ana sayfada üst çubuk yok; başlık Caveat 34, "Klasörlerim" Caveat 26. Üst çubuktaki alışveriş ve ayarlar ikonları kalktı. Arama bir kutu, premium başlığın yanında "Pro" rozeti.
   - Klasör renkleri: Favoriler pembe, diğerleri tatlı / çorba / kahvaltı renkleri arasında sırayla döner. Yazı 1.6 katın üstündeyse klasörler tek sütuna geçer.
   - Sekme etiketleri en fazla 1.3 kat büyür (Apple'ın sekme çubukları da büyümez).
   - Android geri tuşu: Defterim dışındaki sekmede önce Defterim'e döner.
   - `/settings` rotası ve kullanılmayan `KlasorlerWithTheme` (`lib/widgets/klasorler_with_theme.dart`) kaldırıldı.
   - `test/widget_test.dart`: Flutter'ın sayaç şablonu duruyordu (uygulamada sayaç yok, hep kalıyordu). Yerine kabuğun duman testi geldi: sekme geçişi, sekmelerin ilk seçilince kurulması, yeniden seçilince sinyal, geri tuşu. Testte sekmeler `AnaKabuk.sekmeKurucu` ile sahte sayfalarla değiştirilir (Firebase gerekmesin).
   - Testler: `test/kil_sekme_cubugu_test.dart` (48'lik dokunma alanı, altı dilde 320 genişlikte ve en büyük yazıda taşma yok, yeni metinler altı dilde), `test/ana_sayfa_parcalari_test.dart` (48'lik dokunma alanı, iki sütun / tek sütun, açık ve koyu modda 3.2 kat yazıda taşma yok).
   - Aşama 3 sırasında yapılan kontrolde bulunup düzeltilenler (2026-11-10): "Bugün ne pişirsem" kartında yazı 1.6 katın üstündeyse daire metnin üstüne çıkar (önce en büyük yazıda kelimeler ortasından bölünüyordu). Pro rozeti ve arama kutusu ekran okuyucuyla açılamıyordu (`excludeSemantics` dokunma eylemini de siliyordu); eylem `Semantics.onTap` ile verildi. Bu iki test dosyasındaki "320 genişlik" denemeleri ekranı gerçekte daraltmıyordu; artık daraltıyor.
3. **Klasör içi — tamamlandı (2026-11-09; simülatör yerine test görüntüleriyle açık/koyu ve 3.2 kat yazıda bakıldı, gerçek cihaz kontrolü aşama 2 ile birlikte Sude'nin derlemesinde):** tarif listesi, tarif ekleme alt sayfası (kendim yazacağım, Şefe sor, linkten tarif), klasör kaydı. Ana sayfadaki düğme "Yeni tarif" oldu ve bu alt sayfayı açıyor.
   - Sude'nin kararları: "Yeni klasör" düğmesi "Klasörlerim" başlığının yanında, sığmazsa (büyük yazı) altına iner (hiç klasör yokken boş durumdaki "Yeni klasör ekle" düğmesi kalır). Alt sayfada klasör seçici hep görünür; klasör içinden açılınca o klasör seçili gelir. Ana sayfadan eklenen tarif kaydedilince o klasör açılır (klasör içinden başka klasör seçilirse de o klasör açılır). Favoriler ekranı da aynı görünüme geçti.
   - Dosyalar: `lib/sayfalar/tarif_ekleme_akisi.dart` (`TarifEklemeAkisi`: üç akış klasör içinden buraya taşındı, mantık ve analitik değerleri aynı; tarif sınırı için klasördeki tarif sayısı cihazdan okunuyor), `lib/widgets/tarif_ekle_alt_sayfasi.dart`, `lib/widgets/tarif_listesi_parcalari.dart` (`TarifSatiri`, `TarifListesiGorunumu`, `TarifBosDurum`), `lib/widgets/klasor_ikon_secici.dart`, `lib/widgets/kil/kil_sayfa_basligi.dart` (`KilSayfaBasligi`, `kilDurumCubuguStili`), `lib/utils/klasor_adi.dart` (`klasorGorunenAdi`, iki sayfadaki kopya kaldırıldı).
   - İç sayfalarda üst çubuk yok: geri ve arama yuvarlak düğme, altında Caveat 34 başlık (büyük yazıda kesilmez). Tarif satırında kalp ve "⋮" menüsü (Paylaş, Tarif Sil); yazı 1.6 katın üstündeyse ad, görsel ve düğmelerin altına iner. Alt sayfadaki seçenekler de 1.6 katın üstünde ikonu metnin üstüne alır.
   - Klasör kaydı: başlık "Yeni klasör", ad kutusunun görünen etiketi var, ad boşken Kaydet pasif. İkon kutuları 56x56; seçili kutuda onay işareti de var.
   - Diyaloglar ve snackbar'lar aşama 9'a bırakıldı (akışlardaki sabit renkler orada).
   - Klasör ikonu (2026-11-10, Sude onayladı): eski varsayılan kod `0xe2c7` bugünkü ikon fontunda "5 sn ileri" ikonu çıkıyordu (ikon seçmeden açılan klasörler, Ne pişirsem'in "Tariflerim"i dahil). `KlasorData.icon` bu kodu ekranda klasör ikonu (`0xe2a3`) olarak gösterir; kayıtlı değer değişmez. Yeni klasörlerin ve klasör kaydının varsayılanı `KlasorData.varsayilanIkon`. Test: `test/klasor_data_test.dart`.
   - Testler: `test/tarif_listesi_parcalari_test.dart`, `test/tarif_ekle_alt_sayfasi_test.dart` (48'lik dokunma alanları, seçim, girişsiz kilit, 320 genişlik ve 3.2 kat yazıda taşma, ekran okuyucu, klasör kaydı dönüşü, yeni metinler altı dilde). Bu testler ekranı `tester.view.physicalSize` ile gerçekten daraltıyor.
4. **Tarif detayı ve tarif oluşturma — tamamlandı (2026-11-10, gece çalışması; simülatör yerine test görüntüleriyle açık/koyu, 402 genişlikte 1x ve 320 genişlikte 3.2 kat yazıda bakıldı):**
   - `flutter_quill` (ve `flutter_quill_extensions`) `pubspec.yaml`'da var ama `lib/` içinde hiç kullanılmıyor; tarif oluşturma bölüm ve madde listesiyle çalışıyor. Araç çubuğu olmadığı için bu madde boşa düştü. Paket kaldırılmadı (gece notlarında soru).
   - İki ekranda da üst çubuk yok: `KilIcSayfa` (yuvarlak geri, sağda yuvarlak eylem düğmeleri, altında Caveat 34 başlık). Tarif detayının başlığı tarifin adı; eylemler Paylaş, Klasöre taşı, Düzenle. Oluşturmada başlık "Tarif Ekleme/Düzenleme", eylem fotoğraf ekle. Oluşturmada geri düğmesi eskisi gibi "değişiklikler kaybolacak" uyarısından geçer (`Navigator.maybePop` → `PopScope`).
   - Tarif detayı: favori tarifte başlık altında pembe "Favoriler" rozeti; görseller 20 köşeli kil çerçevede, sayaç kart renginde hap; porsiyon kartı (`PorsiyonAyari`, "−" ve "+" 48'lik yuvarlak düğme, en küçük çarpanda "−" pasif); her bölüm bir `KilKart`, başlığı Caveat 26 ve renkli ikon kutusu; yapılışta numaralı daire, malzemede onay dairesi ve 48'lik sepet düğmesi (önce dokunma alanı 22'ydi, etiketi de yoktu). Bağlantılar mavi yerine terrakota. "Yemek Yapma Modu" sağ altta `KilDugme`. Klasöre taşıma alt sayfası `KilAltSayfa` + `KilSecimListesi`.
   - Tarif oluşturma: "Fotoğraf Ekle" tam genişlik ikincil düğme, eklenen fotoğraflar altında şerit (silme düğmesi 48'lik yuvarlak; önce 24'tü). Tarif adı kartında görünen etiketli metin kutusu (tema kenarı, 3:1). "Tarif Bölümleri" Caveat başlık ve "Bölüm Ekle" düğmesi (sığmazsa alta iner). Bölüm kartlarında sil (hata rengi), madde sil ve "+" düğmeleri 48'lik ve etiketli. "Kaydet" tam genişlik birincil düğme. Bölüm seçimi alt sayfası `KilSecimListesi`.
   - Yazı 1.6 katın üstündeyse (`tarifUstUsteMi`) bölüm ikonu ve düğmeler başlığın, madde işareti ve düğmeleri maddenin üstüne çıkar; madde kutusu tam genişlik olur, "+" altına iner. Önce 320 genişlikte kelimeler ortasından bölünüyordu.
   - Mantık değişmedi: bölüm ayrıştırma, porsiyon ölçekleme, alışveriş listesine ekleme, taşıma, paylaşma metni, kaydetme (yalnızca `_kaydet()` metoduna taşındı, içerik aynı) ve analitik (`tarifPaylasildi(kaynak: 'tarif_detay')`) aynı. Diyaloglar (vazgeç uyarısı, madde düzenleme, büyük fotoğraf) ve snackbar'lar aşama 9'a bırakıldı.
   - Bölüm ikonları yuvarlak sürümlere geçti; hamurun ikonu daireden `bakery_dining`'e. Kayıtlı bölüm türleri aynı.
   - Yeni metinler (altı dilde): `recipe_detail_portion_decrease`, `recipe_detail_portion_increase`, `recipe_edit_delete_photo`, `recipe_edit_delete_section`, `recipe_edit_delete_item`, `recipe_edit_add_item`.
   - Dosyalar: `lib/widgets/tarif_detay_parcalari.dart` (`KilIcSayfa`, `TarifBolumKarti`, `TarifBolumBasligi`, `TarifMaddeSatiri`, `TarifMaddeIsareti`, `TarifBaglantisi`, `TarifAciklamaKarti`, `PorsiyonAyari`, `TarifGorseli`, `TarifGorselGalerisi`, `FavoriRozeti`, `tarifBolumIkonu`, `tarifBolumuMalzemeMi`; iki sayfadaki `_getSectionIcon` kopyası kalktı), `lib/widgets/tarif_olusturma_parcalari.dart` (`TarifFotoSeridi`, `TarifBolumDuzenleKarti`, `TarifBolumlerBasligi`), `lib/widgets/kil/kil_secim_listesi.dart` (`KilSecimListesi`, `KilSecenek`; satır en az 56), `lib/sayfalar/tarif_detay.dart`, `lib/sayfalar/tarif_olusturma.dart`.
   - Testler: `test/tarif_detay_parcalari_test.dart`, `test/tarif_olusturma_parcalari_test.dart` (48'lik dokunma alanları, ekran okuyucu başlığı ve düğmeleri, madde ekleme/silme/düzenleme, büyük yazıda üst üste diziliş, açık ve koyu modda 320 genişlik ve 3.2 kat yazıda taşma yok, yeni metinler altı dilde).
5. **Yemek yapma modu — tamamlandı (2026-11-10, gece çalışması; simülatör yerine test görüntüleriyle açık/koyu, 402 genişlikte 1x, 320 genişlikte 1x (tr, fr, de) ve 320x640'ta 3.2 kat yazıda bakıldı):**
   - İşleyiş aynı: malzeme ve adım ayrıştırma (JSON ve eski düz metin), porsiyon çarpanı, malzeme işaretleme (sayfada ve alt pencerede ortak), sayfa sayfa gezinme, ekranın açık kalması (`WakelockPlus` açılışta açılır, kapanışta kapanır), "Tamamla"da değerlendirme isteği ve çift dokunuş koruması. Analitik olay adları aynı (`yemek_modu_acildi`, `yemek_modu_tamamlandi`). Ekranda zamanlayıcı yoktu, eklenmedi (gece notlarında soru).
   - Üst çubuk yok: yuvarlak geri, sağda "Malzemeler" ikincil düğmesi (alt pencereyi açar), altında Caveat 30 tarif adı (en fazla 2 satır). Altında konum ("Adım 1 / 3"), sayfa sayısı ve terrakota ilerleme çubuğu.
   - Malzemeler sayfası: özet kartı (ikon kutusu, Caveat başlık, "1 / 5 hazır" hapı, ilerleme çubuğu; hepsi hazırsa hap ve çubuk adaçayı ve onay işaretli) ve her malzeme ayrı satır: en az 64 yükseklik, 20'lik yazı, 32'lik onay dairesi (işaretsizken tanıtan kenar, işaretliyken adaçayı). İşaretli satır soluk yüzey, yazı soluk ve üstü çizili. Ekran okuyucu satırı "işaretli/işaretsiz" okur.
   - Adım sayfası: Caveat 30 numaralı daire ve Caveat 34 "Adım 2" başlığı, altında kaydırılan kil kartında 26'lık adım metni.
   - Alt düğmeler 56 yüksekliğinde, 18'lik yazı (`KilDugme`'ye `buyuk` seçeneği eklendi): "Önceki" ikincil, "Sonraki Adım" birincil, son sayfada "Tamamla" vurgu (adaçayı). Etiketler yan yana bölünmeden sığmıyorsa (320 genişlikte tr/fr/de, büyük yazı) düğmeler alt alta dizilir, ileri üstte. "Hareketi azalt" açıkken sayfa geçişi animasyonsuz.
   - Malzeme alt penceresi `KilAltSayfa`: Caveat başlık, 48'lik kapat düğmesi, aynı malzeme satırları; ekranın en fazla %70'i.
   - Büyük yazı (1.6 katın üstü): üst kısım tek satır (geri, tek satır başlık, yuvarlak "Malzemeler" düğmesi), konum yazısı gizlenir (aynı bilgi sayfa başlığında), adım başlığı kartın içine girer, onay dairesi metnin üstüne çıkar. Üst kısım, ilerleme, alt düğmeler, malzeme özeti ve "Adım 2" başlığı en fazla 2 kat büyür (`yemekCubukYaziSiniri`; sekme etiketlerindeki 1.3 sınırı gibi); adım ve malzeme yazıları sınırsız büyür. Yoksa 3.2 katta adıma yer kalmıyordu.
   - Koda sabit renk kalmadı (önce `Colors.green`, `0xFF1A1D2B` vb.).
   - Dosyalar: `lib/widgets/yemek_modu_parcalari.dart` (`YemekModuBasligi`, `YemekSayfaIlerlemesi`, `YemekIlerlemeCubugu`, `YemekMalzemeOzeti`, `YemekMalzemeSatiri`, `YemekMalzemeListesi`, `YemekAdimSayfasi`, `YemekModuAltCubuk`, `yemekYaziSiniri`), `lib/sayfalar/yemek_yapma_modu.dart`, `lib/widgets/kil/kil_dugme.dart` (`buyuk`).
   - Yeni metin yok; var olan `cooking_mode_*` anahtarları kullanıldı.
   - Testler: `test/yemek_modu_parcalari_test.dart` (satır 64, alt düğmeler 56, ekran okuyucu, büyük yazıda düzen; gerçek sayfayla ekranın açık tutulup bırakılması, olay adları, malzeme işaretleme, alt pencere, gezinme ve Tamamla, boş tarif; açık ve koyu modda 320 genişlik, 1x ve 3.2 kat yazıda taşma yok; metinler altı dilde).
6. **Bugün ne pişirsem — tamamlandı (2026-11-10, gece çalışması; test görüntüleriyle açık/koyu, 402 genişlikte 1x ve 320 genişlikte 3.2 kat yazıda bakıldı):**
   - İşleyiş aynı: yapay zekâ isteği ve metni, giriş ve hak kontrolü, "+1 hak" ödüllü reklam, Premium kaynakları (`ne_pisirsem_ekrani`, `ne_pisirsem_badge`, `ai_limit_choice`), analitik olaylar, kayıt ve form sıfırlama. Tek ek: kayıt klasörü alındıktan sonra `mounted` kontrolü (eski uyarı). `FirebaseService` artık ilk kullanımda kuruluyor (`late final`), böylece sayfa testte açılıyor.
   - Üst çubuk yok: Caveat 34 başlık ve yanında "Pro" rozeti (büyük yazıda altında); üstüne açılınca `KilSayfaBasligi`. Kiremit tanıtım kartı (rozet, açıklama, şef emojisi), kalan hak kartı ("Daha Fazla Hak" 48'lik düğme). Bölüm başlıkları Caveat 26.
   - Seçilen malzemeler kil kartında `SeciliMalzemeCipi` (dokununca çıkar, ekran okuyucu "Sil" ipucu). Elle ekleme kutusu tema kenarlı, "Ekle" `KilDugme` (büyük yazıda alta iner). Popüler malzemeler, öğün ve süre `KilCip` (emojiyle; `KilCip`'e `emoji` eklendi); öğün ve süre yatay kaydırma yerine sarılıyor, tüm seçenekler görünür.
   - Klasör seçimi açılır menü yerine `KlasorSecimKutusu` → `KilAltSayfa` + `KilSecimListesi` (klasör renkleri, seçili klasörde onay işareti; `KilSecenek`'e `secili` ve `renk` eklendi). Klasör adları `klasorGorunenAdi` ile (varsayılan klasörler çevrilir).
   - "Şefe Sor" tam genişlik büyük birincil düğme.
   - Bekleme: `AiBeklemeKatmani` (karartma + kil kartı, alttaki sayfaya dokunulamaz). Lottie dosyası değişmedi; çizerken mor tava/saplar terrakota, pembe kâse ve yeşil şişe adaçayı, kulplar ana yazı rengine eşleniyor (`AiChefLoadingAnimation.renkTemsilcileri`). Animasyonun beyaz arka plan katmanı kart rengine boyanıyor: önce koyu modda kartın ortasında beyaz dikdörtgen çıkıyordu. Alev ve baharat renkleri kaldı. Klasör içinden açılan bekleme diyaloğu da aynı renkleri alır.
   - "+1 hak" diyaloğu kil renklerinde (`KilDugme`, büyük yazıda kaydırılır); dönüş değerleri aynı.
   - Caveat başlıklar ve bekleme kartı en fazla 2 kat büyür (`nePisirsemBaslikSiniri`, Aşama 5'teki gibi).
   - Snackbar'lar, Pro limit ve hata diyalogları aşama 9'a bırakıldı.
   - Dosyalar: `lib/widgets/ne_pisirsem_parcalari.dart`, `lib/sayfalar/bugun_ne_pisisem_sayfasi.dart`, `lib/widgets/ai_chef_loading_animation.dart`, `lib/widgets/ai_hak_doldu_dialog.dart`, `lib/widgets/kil/kil_cip.dart`, `lib/widgets/kil/kil_secim_listesi.dart`. Yeni metin yok.
   - Testler: `test/ne_pisirsem_parcalari_test.dart` (renk eşlemesi ve koyu/açık modda arka planın kart rengi, 48'lik dokunma alanları, ekran okuyucu, büyük yazıda diziliş, bekleme katmanı, diyalog seçimi, gerçek sayfada seçim/kaldırma/temizleme/klasör değiştirme/uyarı, 320 genişlik 1x ve 3.2 kat yazıda açık ve koyu taşma yok, metinler altı dilde).
7. **Alışveriş listesi ve arama.**
8. **Premium:** fiyatlar RevenueCat'ten gelir; metinler Sude onaylamadan değişmez.
9. **Kalanlar:** giriş ekranı (`auth_screen.dart`), Profil (üstte hesap bilgisi olan yeni profil ekranı; ayarlar onun altında), güncelleme ekranı, diyaloglar ve snackbar'lar.
10. **Son tarama:** elle yazılmış renkler (`grep "Color(0x\|Colors\."`; başlangıçta yaklaşık 660 kullanım var), karanlık mod turu, en büyük yazı boyutu, tüm testler.

## Her ekranda kontrol listesi
- Yazı kontrastı en az 4.5:1; öğeyi tanıtan kenarlar ve ikonlar en az 3:1.
- Dokunma alanı en az 48x48.
- Açık mod, koyu mod ve en büyük yazı boyutu.
- Koda sabit renk yok; renkler `KilRenkleri`'nden.
- "Hareketi azalt" açıkken animasyon yok.
- Yeni metinler altı dil dosyasının hepsinde.

## Açık sorular (Sude)
- Premium satın alma düğmesinin metni.
- Mağaza ekran görüntüleri ve uygulama ikonu yeni tarza göre yenilenecek mi?
- Profil ekranında hesap bilgisinin altında neler olacak (ör. tarif ve klasör sayısı)? Aşama 9'dan önce konuşulacak.
