# Kil tasarımına geçiş planı (Tarifly)

Tarih: 2026-11-09. Durum: **Aşama 1, 2 ve 3 tamamlandı; ekranlar aşama 4'ten itibaren yenilenecek.**
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
4. **Tarif detayı ve tarif oluşturma:** `flutter_quill` editörünün araç çubuğu ve renkleri dikkat ister.
5. **Yemek yapma modu.**
6. **Bugün ne pişirsem:** AI bekleme ekranındaki Lottie animasyonunun yeni renklerle uyumu da kontrol edilir.
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
