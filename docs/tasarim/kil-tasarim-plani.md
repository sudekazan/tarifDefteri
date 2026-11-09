# Kil tasarımına geçiş planı (Tarifly)

Tarih: 2026-11-09. Durum: **Aşama 1 tamamlandı; ekranlar aşama 2'den itibaren yenilenecek.**
Kaynak: UI UX Pro Max'in "Recipe & Cooking App" önerisi (claymorphism) ve Sude ile yapılan önce/sonra görsel çalışması.

## Kararlar (Sude, 2026-11-09)
- Uygulamanın tamamı yumuşak kil tarzına (claymorphism) geçer: kalın açık kenar, alttan sert gölge, yuvarlak köşeler, sıcak yemek renkleri.
- 10 pastel tema kalkar, herkes tek paleti görür. Ayarlar › Tema sayfası ve girişi kalkar.
- Karanlık mod kalır ve koyu kil sürümü yapılır: derinlik gölgeyle değil, kenar ve açık bir üst çizgiyle verilir.
- Gezinme alt sekme çubuğuna geçer: **Defterim, Ne pişirsem, Alışveriş, Profil**. Arama, ana sayfada bir kutu olur. Premium, başlığın yanında küçük bir "Pro" rozeti olur.
- Geçiş aşamalı yapılır: her aşama ayrı commit, her aşamadan sonra simülatörde açık ve koyu modda bakılır.
- 2026-11-09'daki "üst çubuk siyah" kararı bu tasarımla geçersiz kalır, çünkü renkli üst çubuk kalkıyor.

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
2. **Gezinme ve ana sayfa:** alt sekme kabuğu, yeni ana sayfa (başlık, arama kutusu, "Bugün ne pişirsem" kartı, iki sütunlu klasör kartları, "Yeni tarif" düğmesi).
3. **Klasör içi:** tarif listesi, tarif ekleme alt sayfası (kendim yazacağım, Şefe sor, linkten tarif), klasör kaydı.
4. **Tarif detayı ve tarif oluşturma:** `flutter_quill` editörünün araç çubuğu ve renkleri dikkat ister.
5. **Yemek yapma modu.**
6. **Bugün ne pişirsem:** AI bekleme ekranındaki Lottie animasyonunun yeni renklerle uyumu da kontrol edilir.
7. **Alışveriş listesi ve arama.**
8. **Premium:** fiyatlar RevenueCat'ten gelir; metinler Sude onaylamadan değişmez.
9. **Kalanlar:** giriş ekranı (`auth_screen.dart`), Profil/Ayarlar, güncelleme ekranı, diyaloglar ve snackbar'lar.
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
- Profil sekmesi: şimdiki Ayarlar ekranı olduğu gibi mi kalsın, yoksa üstte hesap bilgisi olan bir profil ekranı mı olsun?
