import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // kDebugMode için
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tarif_defteri/sayfalar/klasor_ici.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';
import 'package:tarif_defteri/sayfalar/arama_sayfasi.dart';
import 'package:tarif_defteri/sayfalar/alisveris_listesi.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'klasor_kayit.dart';
import '../services/firebase_service.dart';
import '../services/ad_service.dart';
import '../services/review_service.dart';

class Klasorler extends StatefulWidget {
  @override
  State<Klasorler> createState() => _KlasorlerState();
}

class _KlasorlerState extends State<Klasorler> {
  bool aramaYapiliyorMu = false;
  List<KlasorData> klasorListesi = [];
  List<KlasorData> filtrelenmisKlasorler = [];
  TextEditingController aramaController = TextEditingController();

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // Interstitial ad kaldırıldı, yerine App Open Ad kullanılacak.
  
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    // App Open Ad gösterilmeye çalışılır - 1 saniye gecikme ile
    Future.delayed(const Duration(seconds: 1), () {
      print('### KLASORLER_DEBUG: timer triggered. Checking AdService...');
      // Ensure it's loaded (idempotent if already loading/loaded)
      AdService.loadAppOpenAd();
      AdService.showAdIfAvailable();
    });
    _temizleEskiKlasorler();
    _klasorleriYukle().then((_) {
      _filtreleKlasorler('');
    });

    // Uygulama açıldığında review kontrolü yap (3 saniye gecikme ile - reklamdan sonra)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) ReviewService.checkAndRequestReview(context);
    });
  }

  @override
  void dispose() {
    aramaController.dispose(); // Controller'ı dispose etmeyi unutmayın
    _bannerAd?.dispose();
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
        final int klasorId = map['klasor_id'] ?? e.key + 1;
        return KlasorData.fromMap({
          'klasor_id': klasorId,
          'klasor_adi': map['klasor_adi'],
          'iconCode': map['iconCode'] ?? 0xe2c7,
        });
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
        print("Otomatik senkronizasyon hatası: $e");
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
          final int klasorId = map['klasor_id'] ?? e.key + 1;
          return KlasorData.fromMap({
            'klasor_id': klasorId,
            'klasor_adi': map['klasor_adi'],
            'iconCode': map['iconCode'] ?? 0xe2c7,
          });
        }).toList();
      });
      _filtreleKlasorler(aramaController.text);
    }
  }
  
  Future<void> _varsayilanKlasorleriEkle(SharedPreferences prefs) async {
    // 4 varsayılan klasör tanımla - kullanıcının diline göre isimlendir
    final defaultKlasorler = [
      KlasorData(klasor_id: 1, klasor_adi: 'default_folder_desserts'.tr(), iconCode: Icons.cake.codePoint),
      KlasorData(klasor_id: 2, klasor_adi: 'default_folder_soups'.tr(), iconCode: Icons.soup_kitchen.codePoint),
      KlasorData(klasor_id: 3, klasor_adi: 'default_folder_main_dishes'.tr(), iconCode: Icons.restaurant.codePoint),
      KlasorData(klasor_id: 4, klasor_adi: 'default_folder_breakfast'.tr(), iconCode: Icons.egg_alt.codePoint),
    ];
    
    // SharedPreferences'a kaydet
    List<String> klasorJsonList = defaultKlasorler.map((k) => json.encode({
      'klasor_id': k.klasor_id,
      'klasor_adi': k.klasor_adi,
      'iconCode': k.iconCode,
    })).toList();
    await prefs.setStringList('klasorler', klasorJsonList);
    
    // Firebase'e kaydet (giriş yapılmışsa)
    for (var klasor in defaultKlasorler) {
      await _firebaseService.saveKlasorToFirebase(klasor);
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
              klasor.klasor_adi.toLowerCase().contains(aramaKelimesi.toLowerCase())),
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
    
    klasorJsonList.add(json.encode({
      'klasor_id': yeniKlasorId,
      'klasor_adi': klasorAdi,
      'iconCode': iconCode,
    }));
    await prefs.setStringList('klasorler', klasorJsonList);
    
    // Firebase'e de kaydet
    KlasorData yeniKlasor = KlasorData(
      klasor_id: yeniKlasorId,
      klasor_adi: klasorAdi,
      iconCode: iconCode,
    );
    await _firebaseService.saveKlasorToFirebase(yeniKlasor);
    
    _klasorleriYukle().then((_) {
      _filtreleKlasorler(aramaController.text); // Yeni klasör eklendiğinde filtreyi güncelle
    });
  }

  // Mevcut sil metodunuzun güncellenmiş hali
  Future<void> sil(int klasor_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); // prefs'i burada tanımla
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? []; // klasorJsonList'i burada tanımla
    int indexToRemove = -1;
    for (int i = 0; i < klasorJsonList.length; i++) {
      final map = json.decode(klasorJsonList[i]);
      final int storedId = map['klasor_id'] ?? (i + 1);
      if (storedId == klasor_id) {
        indexToRemove = i;
        break;
      }
    }
    if (indexToRemove != -1) {
      // Klasörün içindeki tarifleri de sil
      String tarifKey = 'tarifler_$klasor_id';
      await prefs.remove(tarifKey);
      klasorJsonList.removeAt(indexToRemove);
      await prefs.setStringList('klasorler', klasorJsonList);
      
      // Firebase'den de sil
      await _firebaseService.deleteKlasorFromFirebase(klasor_id);
      
      _klasorleriYukle().then((_) {
        _filtreleKlasorler(aramaController.text); // Silme işleminden sonra filtreyi güncelle
      });
    }
  }

  Future<void> _klasorYenidenAdlandirDialog(KlasorData klasor) async {
    final TextEditingController nameController = TextEditingController(text: klasor.klasor_adi);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('folders_rename'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'folders_new_name'.tr,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              String yeniAd = nameController.text.trim();
              if (yeniAd.isNotEmpty && yeniAd != klasor.klasor_adi) {
                Navigator.pop(context);
                await _klasorYenidenAdlandir(klasor, yeniAd);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('common_save'.tr, style: const TextStyle(color: Colors.white)),
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KlasorKayit()),
    );
    if (result != null && result is Map && result['klasorAdi'] != null && result['iconCode'] != null) {
      _klasorEkle(result['klasorAdi'], result['iconCode']);
    }
  }

  // _interstitialAdUnitId kaldırıldı.


  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  // _loadInterstitialAd kaldırıldı.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'app_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color ?? Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AramaSayfasi()),
              ).then((_) {
                _klasorleriYukle().then((_) => _filtreleKlasorler(''));
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Theme.of(context).iconTheme.color ?? Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlisverisListesi()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).iconTheme.color ?? Colors.black),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              _klasorleriYukle().then((_) => _filtreleKlasorler(''));
            },
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: klasorListesi.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 80,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'folders_empty_title'.tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'folders_empty_subtitle'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _yeniKlasorEkle,
                        icon: const Icon(Icons.add),
                        label: Text('folders_empty_add_button'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          itemCount: filtrelenmisKlasorler.length, // filtrelenmisKlasorler'i kullan
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            var klasor = filtrelenmisKlasorler[index]; // filtrelenmisKlasorler'den oku
            return GestureDetector(
              onTap: () async {
                if (klasor.klasor_id == -1) {
                  // Favoriler klasörüne tıklandı
                  // Tüm klasörlerdeki favori tarifleri topla
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
                  // Favori tarifleri gösterecek yeni bir sayfa aç
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => FavoriTariflerSayfasi(favoriTarifler: favoriTarifler),
                  ));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => KlasorIci(klasorData: klasor)))
                      .then((value){
                    print("Klasör içeriği açıldı.");
                  });
                }
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: klasor.klasor_id == -1
                    ? (isDark ? const Color(0xFF2A1B1B) : const Color(0xFFFFF3E0))
                    : Theme.of(context).cardColor,
                child: SizedBox(
                  height: 84,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(
                          klasor.icon,
                          color: klasor.klasor_id == -1
                              ? (isDark ? Colors.redAccent : Colors.red)
                              : Theme.of(context).primaryColor,
                          size: 36,
                        ),
                      ),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            // Var olan 1,2,3,4 ID'li klasör eğer ismi değiştirilmiş sıradan bir klasör ise çevrilmesin
                            String displayName = klasor.klasor_adi;
                            if (klasor.klasor_id == 1 && (displayName == 'default_folder_desserts'.tr() || displayName == 'Tatlılar' || displayName == 'Desserts')) {
                              displayName = 'default_folder_desserts'.tr();
                            } else if (klasor.klasor_id == 2 && (displayName == 'default_folder_soups'.tr() || displayName == 'Çorbalar' || displayName == 'Soups')) {
                              displayName = 'default_folder_soups'.tr();
                            } else if (klasor.klasor_id == 3 && (displayName == 'default_folder_main_dishes'.tr() || displayName == 'Ana Yemekler' || displayName == 'Main Dishes')) {
                              displayName = 'default_folder_main_dishes'.tr();
                            } else if (klasor.klasor_id == 4 && (displayName == 'default_folder_breakfast'.tr() || displayName == 'Kahvaltılıklar' || displayName == 'Breakfast')) {
                              displayName = 'default_folder_breakfast'.tr();
                            }

                            return Text(
                              klasor.klasor_id == -1 ? 'folders_favorites'.tr() : displayName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: klasor.klasor_id == -1
                                    ? (isDark ? Colors.redAccent : Colors.red)
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                        ),
                      ),

                      if (klasor.klasor_id != -1)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(context).primaryColor,
                          ),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _klasorYenidenAdlandirDialog(klasor);
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('folders_delete_title'.tr()),
                                  content: Text(
                                    '${klasor.klasor_adi}${'folders_delete_confirm_suffix'.tr()}',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('common_no'.tr()),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        sil(klasor.klasor_id);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                      ),
                                      child: Text(
                                        'common_yes'.tr(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Text('folders_rename'.tr),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('folders_delete_title'.tr),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _isBannerAdReady
          ? SafeArea(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                height: _bannerAd!.size.height.toDouble(),
                child: Center(
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
          : null,
      floatingActionButton: klasorListesi.isEmpty && !aramaYapiliyorMu
          ? const SizedBox.shrink()
          : FloatingActionButton(
              onPressed: _yeniKlasorEkle,
              backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
              child: const Icon(Icons.add, color: Colors.black),
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
          tarif.tarif_adi.toLowerCase().contains(arama.toLowerCase()) ||
          tarif.tarif_aciklama.toLowerCase().contains(arama.toLowerCase())
        ).toList();
      }
    });
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
      print('Favori güncelleme hatası: $e');
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
    } catch (e) {
      print('Tarif silme hatası: $e');
    }
  }

  /// Tarif içeriğini paylaşır
  Future<void> _tarifPaylas(BuildContext btnContext, TarifData tarif) async {
    try {
      String shareText = '📖 ${tarif.tarif_adi}\n\n';
      shareText += tarif.tarif_aciklama;
      shareText += '\n\n━━━━━━━━━━━━━━━━━━\n';
      shareText += 'share_from_app'.tr();

      // iOS için butonun konumunu al (iPad popup için)
      final box = btnContext.findRenderObject() as RenderBox?;
      final sharePositionOrigin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await Share.share(
        shareText,
        subject: tarif.tarif_adi,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('share_error_generic'.tr()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: aramaYapiliyorMu
            ? TextField(
                controller: aramaController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'favorites_search_hint'.tr(),
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: _filtreleTarifler,
              )
            : Text('favorites_title'.tr()),
        actions: [
          IconButton(
            icon: Icon(aramaYapiliyorMu ? Icons.close : Icons.search),
            onPressed: () {
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
          ),
        ],
      ),
      body: filtreliTarifler.isEmpty
          ? Center(child: Text('favorites_empty_text'.tr()))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: filtreliTarifler.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tarif = filtreliTarifler[index];
                return GestureDetector(
                  onTap: () async {
                    final guncelTarif = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TarifDetay(tarif: tarif),
                      ),
                    );
                    if (guncelTarif != null && guncelTarif is TarifData) {
                      _favoriDurumunuDegistir(guncelTarif);
                    }
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Theme.of(context).cardColor,
                    child: SizedBox(
                      height: 100,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Tarif görseli
                            if (tarif.tarif_resimler.isNotEmpty)
                              Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: tarif.tarif_resimler.first.startsWith('http')
                                      ? Image.network(
                                          tarif.tarif_resimler.first,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[300],
                                                child: Icon(Icons.broken_image,
                                                    color: Colors.grey[600], size: 24),
                                              ),
                                        )
                                      : File(tarif.tarif_resimler.first).existsSync()
                                          ? Image.file(
                                              File(tarif.tarif_resimler.first),
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(
                                                    color: Colors.grey[300],
                                                    child: Icon(Icons.broken_image,
                                                        color: Colors.grey[600], size: 24),
                                                  ),
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: Icon(Icons.image_not_supported,
                                                  color: Colors.grey[600], size: 24),
                                            ),
                                ),
                              ),

                            // Tarif adı ve alt yazı
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tarif.tarif_adi,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'recipes_tap_for_details'.tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Aksiyon butonları
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Favori kaldır
                                IconButton(
                                  icon: Icon(
                                    tarif.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  onPressed: () => _favoriDurumunuDegistir(tarif),
                                ),

                                // Paylaş
                                Builder(
                                  builder: (btnContext) => IconButton(
                                    icon: Icon(
                                      Icons.share,
                                      color: Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    onPressed: () =>
                                        _tarifPaylas(btnContext, tarif),
                                  ),
                                ),

                                // Sil
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                            'recipes_delete_title'.tr()),
                                        content: Text(
                                          '${tarif.tarif_adi}${'recipes_delete_confirm_suffix'.tr()}',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx),
                                            child: Text('common_no'.tr()),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _tarifSil(tarif);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: Text(
                                              'common_yes'.tr(),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}