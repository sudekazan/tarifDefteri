import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/sayfalar/klasor_ici.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';
import 'package:tarif_defteri/sayfalar/arama_sayfasi.dart';
import 'package:tarif_defteri/sayfalar/premium_sayfasi.dart';
import 'package:tarif_defteri/sayfalar/bugun_ne_pisisem_sayfasi.dart';
import 'package:tarif_defteri/services/revenuecat_service.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:share_plus/share_plus.dart';
import 'klasor_kayit.dart';
import '../services/analytics_service.dart';
import '../utils/arama_metni.dart';
import '../services/firebase_service.dart';
import '../utils/magaza_linki.dart';
import '../services/ad_service.dart';
import '../utils/klasor_adi.dart';
import '../widgets/ana_sayfa_parcalari.dart';
import '../widgets/kil/kil.dart';
import '../widgets/tarif_ekle_alt_sayfasi.dart';
import '../widgets/tarif_listesi_parcalari.dart';
import 'tarif_ekleme_akisi.dart';

/// Ana sayfa (Defterim sekmesi): başlık ve Pro rozeti, arama kutusu,
/// "Bugün ne pişirsem" kartı ve iki sütunlu klasör kartları.
class Klasorler extends StatefulWidget {
  const Klasorler({super.key, this.nePisirsemAc, this.gorunduSinyali});

  /// "Bugün ne pişirsem" kartına dokununca çağrılır; kabukta o sekmeye geçer.
  /// Verilmezse sayfa üstüne açılır.
  final VoidCallback? nePisirsemAc;

  /// Kabukta Defterim sekmesi yeniden seçilince haber verir; klasörler yeniden
  /// okunur (Ne pişirsem varsayılan klasör açmış ya da Profil'de çıkış
  /// yapılmış olabilir).
  final Listenable? gorunduSinyali;

  @override
  State<Klasorler> createState() => _KlasorlerState();
}

class _KlasorlerState extends State<Klasorler> {
  List<KlasorData> klasorListesi = [];
  List<KlasorData> filtrelenmisKlasorler = [];
  TextEditingController aramaController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    widget.gorunduSinyali?.addListener(_klasorleriSadeceyukle);
    // AB onay formu ve ATT izni ekran çizildikten sonra istenir; reklamlar
    // ancak bunlardan sonra yüklenir. Banner kabukta (AnaKabuk) durur.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AdService.izinleriIsteVeReklamlariBaslat();
      // App Open Ad - İlk açılışlarda kullanıcıyı ve Apple incelemesini rahatsız etmemek için kontrol
      final prefs = await SharedPreferences.getInstance();
      int launchCount = prefs.getInt('app_launch_count') ?? 0;
      prefs.setInt('app_launch_count', launchCount + 1);

      if (launchCount >= 2) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            AdService.loadAppOpenAd();
            AdService.showAdIfAvailable();
          }
        });
      }
    });
    _temizleEskiKlasorler();
    _klasorleriYukle().then((_) {
      _filtreleKlasorler('');
    });

    // Değerlendirme isteği artık açılışta değil, kullanıcının memnun olduğu
    // anlarda soruluyor (bkz. ReviewService.onRecipeSaved ve
    // yemek_yapma_modu.dart'ta tarif tamamlandığında).
  }

  @override
  void dispose() {
    widget.gorunduSinyali?.removeListener(_klasorleriSadeceyukle);
    aramaController.dispose();
    super.dispose();
  }

  Future<void> _temizleEskiKlasorler() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? eski = prefs.getStringList('klasorler');
    if (eski != null && eski.isNotEmpty) {
      try {
        // Eğer eski formatta (sadece isim) kayıt varsa, decode sırasında hata olur
        json.decode(eski.first);
      } catch (e) {
        // Eski format, temizle
        await prefs.remove('klasorler');
      }
    }
  }

  bool _isSyncing = false;

  Future<void> _klasorleriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Mevcut klasörleri kontrol et
    List<String> mevcutKlasorler = prefs.getStringList('klasorler') ?? [];

    // SADECE klasör listesi boşsa VE daha önce varsayılanlar eklenmemişse ekle
    // Bu sayede güncelleme yapan kullanıcıların mevcut klasörleri korunur
    bool defaultsAdded = prefs.getBool('defaultFoldersAdded') ?? false;

    if (!defaultsAdded) {
      // Yeni kullanıcı veya mevcut kullanıcı - sadece flag'i ayarla, varsayılan klasör ekleme
      await prefs.setBool('defaultFoldersAdded', true);
    }

    setState(() {
      klasorListesi = mevcutKlasorler.asMap().entries.map((e) {
        final map = json.decode(e.value);
        map['klasor_id'] ??= e.key + 1;
        return KlasorData.fromMap(map);
      }).toList();
    });

    // Eğer kullanıcı giriş yapmışsa ve halihazırda senkronize olmuyorsak
    if (_firebaseService.isUserLoggedIn && !_isSyncing) {
      _isSyncing = true;
      _firebaseService.mergeLocalAndCloudData().then((_) {
        _isSyncing = false;
        // Veriler birleştirildikten sonra listeyi tekrar yükle (ama sync tetiklemeden)
        if (mounted) {
          _klasorleriSadeceyukle();
        }
      }).catchError((e) {
        _isSyncing = false;
        debugPrint("Otomatik senkronizasyon hatası: $e");
      });
    }
  }

  /// Sadece SharedPreferences'tan klasörleri yükler, sync tetiklemez
  Future<void> _klasorleriSadeceyukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> mevcutKlasorler = prefs.getStringList('klasorler') ?? [];
    if (mounted) {
      setState(() {
        klasorListesi = mevcutKlasorler.asMap().entries.map((e) {
          final map = json.decode(e.value);
          map['klasor_id'] ??= e.key + 1;
          return KlasorData.fromMap(map);
        }).toList();
      });
      _filtreleKlasorler(aramaController.text);
    }
  }

  // Klasörleri filtreleme metodu
  void _filtreleKlasorler(String aramaKelimesi) {
    // Favoriler klasörü için özel KlasorData
    final favorilerKlasor = KlasorData(
      klasor_id: -1,
      klasor_adi: 'Favoriler',
      iconCode: Icons.favorite.codePoint,
    );

    if (aramaKelimesi.isEmpty) {
      setState(() {
        filtrelenmisKlasorler = [favorilerKlasor, ...klasorListesi];
      });
    } else {
      setState(() {
        filtrelenmisKlasorler = [
          favorilerKlasor, // Favoriler klasörünü her zaman ekle
          ...klasorListesi.where((klasor) =>
              aramaEslesir(klasor.klasor_adi, aramaKelimesi)),
        ];
      });
    }
  }

  // Mevcut _klasorEkle metodunuzun güncellenmiş hali
  Future<void> _klasorEkle(String klasorAdi, int iconCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? [];

    // Silme sonrası eski klasör ID'leri ile (özellikle 1,2,3,4 gibi varsayılanlarla)
    // veya silinmiş farklı klasörlerle çakışmayı önlemek için zaman damgası kullanarak eşsiz ID oluşturuyoruz.
    int yeniKlasorId = DateTime.now().millisecondsSinceEpoch;

    // Firebase'e de kaydet
    KlasorData yeniKlasor = KlasorData(
      klasor_id: yeniKlasorId,
      klasor_adi: klasorAdi,
      iconCode: iconCode,
    );

    klasorJsonList.add(json.encode(yeniKlasor.toMap()));
    await prefs.setStringList('klasorler', klasorJsonList);

    await _firebaseService.saveKlasorToFirebase(yeniKlasor);
    AnalyticsService.klasorOlusturuldu(klasorSayisi: klasorJsonList.length);

    _klasorleriYukle().then((_) {
      _filtreleKlasorler(aramaController.text); // Yeni klasör eklendiğinde filtreyi güncelle
    });
  }

  // Mevcut sil metodunuzun güncellenmiş hali
  Future<void> sil(int klasorId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); // prefs'i burada tanımla
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? []; // klasorJsonList'i burada tanımla
    int indexToRemove = -1;
    for (int i = 0; i < klasorJsonList.length; i++) {
      final map = json.decode(klasorJsonList[i]);
      final int storedId = map['klasor_id'] ?? (i + 1);
      if (storedId == klasorId) {
        indexToRemove = i;
        break;
      }
    }
    if (indexToRemove != -1) {
      // Klasörün içindeki tariflerin görsellerini (yerel + bulut) de sil
      String tarifKey = 'tarifler_$klasorId';
      final tariflerJson = prefs.getStringList(tarifKey) ?? [];
      for (final tarifStr in tariflerJson) {
        try {
          await _firebaseService.deleteImagesForTarif(TarifData.fromMap(json.decode(tarifStr)));
        } catch (e) {
          debugPrint('Klasör silinirken tarif görseli temizleme hatası: $e');
        }
      }
      await prefs.remove(tarifKey);
      klasorJsonList.removeAt(indexToRemove);
      await prefs.setStringList('klasorler', klasorJsonList);

      // Firebase'den de sil
      await _firebaseService.deleteKlasorFromFirebase(klasorId);

      _klasorleriYukle().then((_) {
        _filtreleKlasorler(aramaController.text); // Silme işleminden sonra filtreyi güncelle
      });
    }
  }

  Future<void> _klasorYenidenAdlandirDialog(KlasorData klasor) async {
    final TextEditingController nameController = TextEditingController(text: klasor.klasor_adi);

    await showDialog(
      context: context,
      builder: (context) => KilDiyalog(
        baslik: 'folders_rename'.tr(),
        icerik: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'folders_new_name'.tr(),
          ),
          autofocus: true,
        ),
        eylemler: [
          KilDugme.birincil(
            etiket: 'common_save'.tr(),
            tamGenislik: true,
            onPressed: () async {
              String yeniAd = nameController.text.trim();
              if (yeniAd.isNotEmpty && yeniAd != klasor.klasor_adi) {
                Navigator.pop(context);
                await _klasorYenidenAdlandir(klasor, yeniAd);
              }
            },
          ),
          KilDiyalogMetinDugmesi(
            etiket: 'common_cancel'.tr(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _klasorYenidenAdlandir(KlasorData klasor, String yeniAd) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? [];

    for (int i = 0; i < klasorJsonList.length; i++) {
      final map = json.decode(klasorJsonList[i]);
      final int storedId = map['klasor_id'] ?? (i + 1);
      if (storedId == klasor.klasor_id) {
        map['klasor_adi'] = yeniAd;
        map['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        klasorJsonList[i] = json.encode(map);
        break;
      }
    }

    await prefs.setStringList('klasorler', klasorJsonList);

    klasor.klasor_adi = yeniAd;
    klasor.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _firebaseService.saveKlasorToFirebase(klasor);

    _klasorleriYukle().then((_) {
      _filtreleKlasorler(aramaController.text);
    });
  }

  void _yeniKlasorEkle() async {
    if (!RevenueCatService.isProUser && klasorListesi.length >= RevenueCatService.freeKlasorLimit) {
      KilBildirim.goster(
        context,
        'klasor_limit_reached'.tr(args: ['${RevenueCatService.freeKlasorLimit}']),
        tur: KilBildirimTuru.uyari,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'klasor_limit')),
      ).then((_) {
        if (mounted) setState(() {});
      });
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KlasorKayit()),
    );
    if (result != null && result is Map && result['klasorAdi'] != null && result['iconCode'] != null) {
      _klasorEkle(result['klasorAdi'], result['iconCode']);
    }
  }

  /// "Yeni tarif" alt sayfası: ilk klasör seçili gelir. Tarif kaydedilince
  /// kaydedildiği klasör açılır.
  Future<void> _yeniTarif() async {
    if (klasorListesi.isEmpty) return;
    final secim = await TarifEkleAltSayfasi.goster(
      context,
      klasorler: klasorListesi,
      baslangicKlasoru: klasorListesi.first,
      girisYapildi: _firebaseService.isUserLoggedIn,
      klasorAdi: klasorGorunenAdi,
    );
    if (secim == null || !mounted) return;
    TarifEklemeAkisi(
      context: context,
      klasor: secim.klasor,
      yenile: () => setState(() {}),
      kaydedilince: (_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KlasorIci(klasorData: secim.klasor),
          ),
        );
      },
    ).baslat(secim.yol);
  }

  void _nePisirsemAc() {
    final ac = widget.nePisirsemAc;
    if (ac != null) {
      ac();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BugunNePisisemSayfasi()),
    ).then((_) {
      _klasorleriYukle().then((_) => _filtreleKlasorler(''));
    });
  }

  void _aramayiAc() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AramaSayfasi()),
    ).then((_) {
      _klasorleriYukle().then((_) => _filtreleKlasorler(''));
    });
  }

  void _premiumAc() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'ana_ekran')),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _klasoruAc(KlasorData klasor) async {
    if (klasor.klasor_id != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => KlasorIci(klasorData: klasor)),
      );
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<TarifData> favoriTarifler = [];
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? [];
    for (int i = 0; i < klasorJsonList.length; i++) {
      final map = json.decode(klasorJsonList[i]);
      int kid = map['klasor_id'] ?? (i + 1);
      String key = 'tarifler_$kid';
      List<String> tariflerJson = prefs.getStringList(key) ?? [];
      for (var e in tariflerJson) {
        var map = json.decode(e);
        if (map['isFavorite'] == true) {
          favoriTarifler.add(TarifData.fromMap(map));
        }
      }
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoriTariflerSayfasi(favoriTarifler: favoriTarifler),
      ),
    );
  }

  void _silmeOnayi(KlasorData klasor) {
    KilDiyalog.onayIste(
      context,
      ikon: Icons.delete_outline_rounded,
      tehlikeli: true,
      baslik: 'folders_delete_title'.tr(),
      mesaj: '${klasorGorunenAdi(klasor)}${'folders_delete_confirm_suffix'.tr()}',
      onayEtiketi: 'common_yes'.tr(),
      vazgecEtiketi: 'common_no'.tr(),
    ).then((onay) {
      if (onay == true) sil(klasor.klasor_id);
    });
  }

  Widget _klasorMenusu(KilRenkleri r, KlasorData klasor) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: r.solukYazi),
      onSelected: (value) {
        if (value == 'rename') {
          _klasorYenidenAdlandirDialog(klasor);
        } else if (value == 'delete') {
          _silmeOnayi(klasor);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 20, color: r.baslik),
              const SizedBox(width: 8),
              Text('folders_rename'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 20, color: r.hata),
              const SizedBox(width: 8),
              Text('folders_delete_title'.tr()),
            ],
          ),
        ),
      ],
    );
  }

  /// [sira]: kartın listedeki yeri (0 Favoriler). Diğer klasörler üç renk
  /// arasında sırayla döner.
  Widget _klasorKarti(KilRenkleri r, KlasorData klasor, int sira) {
    final favori = klasor.klasor_id == -1;
    final renkler = [r.klasorTatli, r.klasorCorba, r.klasorKahvalti];
    return KlasorKarti(
      ad: klasorGorunenAdi(klasor),
      ikon: favori ? Icons.favorite_rounded : klasor.icon,
      renk: favori ? r.klasorFavori : renkler[(sira - 1) % renkler.length],
      onTap: () => _klasoruAc(klasor),
      menu: favori ? null : _klasorMenusu(r, klasor),
    );
  }

  Widget _baslik() {
    // Rozet yanına sığmazsa (büyük yazı) başlığın altına iner; başlık
    // kısalmaz.
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          header: true,
          // Caveat (headlineLarge, 34); büyük yazıda en fazla 2 kat büyür,
          // yoksa "Tarifly" kısalıyordu.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: KilSayfaBasligi.baslikSiniri,
            child: Text(
              'app_title'.tr(),
              style: Theme.of(context).textTheme.headlineLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (!RevenueCatService.isProUser)
          ProRozeti(
            etiket: 'home_pro_badge'.tr(),
            anlamEtiketi: 'premium_title'.tr(),
            onPressed: _premiumAc,
          ),
      ],
    );
  }

  Widget _bosDurum(KilRenkleri r, TextTheme yaziTemasi) {
    return KilKart(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: r.klasorTatli.zemin,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.menu_book_rounded, size: 38, color: r.klasorTatli.ikon),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'folders_empty_title'.tr(),
            style: yaziTemasi.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'folders_empty_subtitle'.tr(),
            style: yaziTemasi.bodyMedium?.copyWith(color: r.solukYazi),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          KilDugme.birincil(
            etiket: 'folders_empty_add_button'.tr(),
            ikon: Icons.add_rounded,
            onPressed: _yeniKlasorEkle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yaziTemasi = Theme.of(context).textTheme;
    final klasorVar = klasorListesi.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Üst çubuk yok; durum çubuğu ikonları zemine göre seçilir.
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
            children: [
              _baslik(),
              const SizedBox(height: 8),
              AramaKutusu(
                ipucu: 'recipes_search_hint'.tr(),
                onTap: _aramayiAc,
              ),
              const SizedBox(height: 20),
              NePisirsemKarti(
                rozet: 'what_to_cook_hero_badge'.tr(),
                baslik: 'what_to_cook_title'.tr(),
                altBaslik: 'what_to_cook_subtitle'.tr(),
                onTap: _nePisirsemAc,
              ),
              const SizedBox(height: 28),
              if (klasorVar) ...[
                // Sığarsa yan yana; sığmazsa (büyük yazı) düğme alt satıra iner,
                // kelimeler bölünmez.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Semantics(
                      header: true,
                      // Caveat (headlineSmall, 26).
                      child: Text(
                        'home_folders_title'.tr(),
                        style: yaziTemasi.headlineSmall,
                      ),
                    ),
                    KilDugme.ikincil(
                      etiket: 'home_new_folder'.tr(),
                      ikon: Icons.create_new_folder_rounded,
                      onPressed: _yeniKlasorEkle,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                KlasorIzgarasi(
                  kartlar: [
                    for (var i = 0; i < filtrelenmisKlasorler.length; i++)
                      _klasorKarti(r, filtrelenmisKlasorler[i], i),
                  ],
                ),
              ] else
                _bosDurum(r, yaziTemasi),
            ],
          ),
        ),
        floatingActionButton: klasorVar
            ? KilDugme.birincil(
                etiket: 'home_new_recipe'.tr(),
                ikon: Icons.add_rounded,
                onPressed: _yeniTarif,
              )
            : null,
      ),
    );
  }
}

// Favori tarifler için özel sayfa
class FavoriTariflerSayfasi extends StatefulWidget {
  final List<TarifData> favoriTarifler;
  const FavoriTariflerSayfasi({super.key, required this.favoriTarifler});

  @override
  State<FavoriTariflerSayfasi> createState() => _FavoriTariflerSayfasiState();
}

class _FavoriTariflerSayfasiState extends State<FavoriTariflerSayfasi> {
  List<TarifData> filtreliTarifler = [];
  List<TarifData> tumFavoriler = []; // Arama sırasında filtrelenmemiş tam liste
  bool aramaYapiliyorMu = false;
  TextEditingController aramaController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    tumFavoriler = List.from(widget.favoriTarifler);
    filtreliTarifler = List.from(tumFavoriler);
  }

  void _filtreleTarifler(String arama) {
    setState(() {
      if (arama.isEmpty) {
        filtreliTarifler = List.from(tumFavoriler);
      } else {
        filtreliTarifler = tumFavoriler.where((tarif) =>
          aramaEslesir(tarif.tarif_adi, arama) ||
          aramaEslesir(tarif.tarif_aciklama, arama)
        ).toList();
      }
    });
  }

  /// Favoriler ekranında bir tarif görüntülenip Düzenle ile değiştirildiğinde
  /// çağrılır. Eskiden burada yanlışlıkla `_favoriDurumunuDegistir` çağrılıyordu;
  /// o fonksiyon depoya sadece `isFavorite` alanını yazıyor, düzenlemedeki
  /// diğer tüm değişiklikler (başlık, malzemeler, fotoğraflar) yerelde
  /// kaybolup sadece Firebase'e gidiyor, cihaz ile bulut kalıcı olarak
  /// farklılaşıyordu.
  Future<void> _tarifDuzenlemesiniKaydet(TarifData guncelTarif) async {
    setState(() {
      final index = tumFavoriler.indexWhere((t) => t.tarif_id == guncelTarif.tarif_id);
      if (index != -1) {
        if (guncelTarif.isFavorite) {
          tumFavoriler[index] = guncelTarif;
        } else {
          tumFavoriler.removeAt(index);
        }
      }
      filtreliTarifler = List.from(tumFavoriler);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'tarifler_${guncelTarif.klasor_id}';
      final tariflerJson = prefs.getStringList(key) ?? [];
      final idx = tariflerJson.indexWhere(
          (e) => json.decode(e)['tarif_id'] == guncelTarif.tarif_id);
      if (idx != -1) {
        tariflerJson[idx] = json.encode(guncelTarif.toMap());
        await prefs.setStringList(key, tariflerJson);
      }
      await _firebaseService.updateTarifInFirebase(guncelTarif);
    } catch (e) {
      debugPrint('Favori tarif düzenleme kaydı hatası: $e');
    }
  }

  /// Favori durumunu hem UI'da hem de kalıcı depoda günceller
  Future<void> _favoriDurumunuDegistir(TarifData tarif) async {
    setState(() {
      tarif.isFavorite = !tarif.isFavorite;
      if (!tarif.isFavorite) {
        tumFavoriler.removeWhere((t) => t.tarif_id == tarif.tarif_id);
        filtreliTarifler.removeWhere((t) => t.tarif_id == tarif.tarif_id);
      }
    });

    // SharedPreferences'ta favori durumunu güncelle
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'tarifler_${tarif.klasor_id}';
      final tariflerJson = prefs.getStringList(key) ?? [];
      final idx = tariflerJson.indexWhere(
          (e) => json.decode(e)['tarif_id'] == tarif.tarif_id);
      if (idx != -1) {
        final map = json.decode(tariflerJson[idx]) as Map<String, dynamic>;
        map['isFavorite'] = tarif.isFavorite;
        tariflerJson[idx] = json.encode(map);
        await prefs.setStringList(key, tariflerJson);
      }
      // Firebase'de de güncelle
      await _firebaseService.updateTarifInFirebase(tarif);
    } catch (e) {
      debugPrint('Favori güncelleme hatası: $e');
    }
  }

  /// Tarifi hem SharedPreferences'tan hem Firebase'den kalıcı olarak siler
  Future<void> _tarifSil(TarifData tarif) async {
    // Önce UI'dan kaldır
    setState(() {
      tumFavoriler.removeWhere((t) => t.tarif_id == tarif.tarif_id);
      filtreliTarifler.removeWhere((t) => t.tarif_id == tarif.tarif_id);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'tarifler_${tarif.klasor_id}';
      final tariflerJson = prefs.getStringList(key) ?? [];
      tariflerJson.removeWhere(
          (e) => json.decode(e)['tarif_id'] == tarif.tarif_id);
      await prefs.setStringList(key, tariflerJson);

      // Firebase'den de sil
      await _firebaseService.deleteTarifFromFirebase(
          tarif.klasor_id, tarif.tarif_id);

      // Görselleri (yerel + bulut) de sil, yetim dosya kalmasın
      await _firebaseService.deleteImagesForTarif(tarif);
    } catch (e) {
      debugPrint('Tarif silme hatası: $e');
    }
  }

  /// Tarif içeriğini paylaşır
  Future<void> _tarifPaylas(BuildContext btnContext, TarifData tarif) async {
    try {
      String shareText = '📖 ${tarif.tarif_adi}\n\n';
      shareText += tarif.tarif_aciklama;
      shareText += '\n\n━━━━━━━━━━━━━━━━━━\n';
      shareText += 'share_from_app'.tr();
      shareText += '\n${'share_download_cta'.tr()} $magazaLinki';

      // iOS için butonun konumunu al (iPad popup için)
      final box = btnContext.findRenderObject() as RenderBox?;
      final sharePositionOrigin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await Share.share(
        shareText,
        subject: tarif.tarif_adi,
        sharePositionOrigin: sharePositionOrigin,
      );
      AnalyticsService.tarifPaylasildi(kaynak: 'klasorler');
    } catch (e) {
      if (mounted) {
        KilBildirim.goster(
          context,
          'share_error_generic'.tr(),
          tur: KilBildirimTuru.hata,
          sure: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  void dispose() {
    aramaController.dispose();
    super.dispose();
  }

  void _silmeOnayi(TarifData tarif) {
    KilDiyalog.onayIste(
      context,
      ikon: Icons.delete_outline_rounded,
      tehlikeli: true,
      baslik: 'recipes_delete_title'.tr(),
      mesaj: '${tarif.tarif_adi}${'recipes_delete_confirm_suffix'.tr()}',
      onayEtiketi: 'common_yes'.tr(),
      vazgecEtiketi: 'common_no'.tr(),
    ).then((onay) {
      if (onay == true) _tarifSil(tarif);
    });
  }

  Future<void> _tarifiAc(TarifData tarif) async {
    final guncelTarif = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TarifDetay(tarif: tarif),
      ),
    );
    if (guncelTarif != null && guncelTarif is TarifData) {
      _tarifDuzenlemesiniKaydet(guncelTarif);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;

    return TarifListesiGorunumu(
      baslik: 'favorites_title'.tr(),
      aramaAcik: aramaYapiliyorMu,
      aramaController: aramaController,
      aramaIpucu: 'favorites_search_hint'.tr(),
      onAramaAcKapat: () {
        setState(() {
          if (aramaYapiliyorMu) {
            aramaYapiliyorMu = false;
            aramaController.clear();
            filtreliTarifler = List.from(tumFavoriler);
          } else {
            aramaYapiliyorMu = true;
          }
        });
      },
      onAramaDegisti: _filtreleTarifler,
      satirlar: [
        for (final tarif in filtreliTarifler)
          TarifSatiri(
            ad: tarif.tarif_adi,
            resimYolu: tarif.tarif_resimler.isNotEmpty
                ? tarif.tarif_resimler.first
                : null,
            favori: tarif.isFavorite,
            favoriEtiketi: tarif.isFavorite
                ? 'recipe_favorite_remove'.tr()
                : 'recipe_favorite_add'.tr(),
            paylasEtiketi: 'recipe_detail_share_tooltip'.tr(),
            silEtiketi: 'recipes_delete_title'.tr(),
            onTap: () => _tarifiAc(tarif),
            onFavori: () => _favoriDurumunuDegistir(tarif),
            onPaylas: (dugmeContext) => _tarifPaylas(dugmeContext, tarif),
            onSil: () => _silmeOnayi(tarif),
          ),
      ],
      bosDurum: TarifBosDurum(
        ikon: Icons.favorite_rounded,
        renk: r.klasorFavori,
        baslik: 'favorites_empty_text'.tr(),
      ),
    );
  }
}
