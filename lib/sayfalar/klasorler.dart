import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tarif_defteri/sayfalar/klasor_ici.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import 'klasor_kayit.dart';

class Klasorler extends StatefulWidget {
  @override
  State<Klasorler> createState() => _KlasorlerState();
}

class _KlasorlerState extends State<Klasorler> {
  bool aramaYapiliyorMu = false;
  List<KlasorData> klasorListesi = [];
  List<KlasorData> filtrelenmisKlasorler = [];
  TextEditingController aramaController = TextEditingController();

  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _temizleEskiKlasorler();
    _klasorleriYukle().then((_) {
      // Klasörler yüklendikten sonra filtreli listeyi de güncelle
      _filtreleKlasorler('');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('onboarding_shown_main') ?? false;
      if (!shown && mounted) {
        ShowCaseWidget.of(context).startShowCase([
          _searchKey,
          _settingsKey,
          _fabKey,
        ]);
        await prefs.setBool('onboarding_shown_main', true);
      }
    });
  }

  @override
  void dispose() {
    aramaController.dispose(); // Controller'ı dispose etmeyi unutmayın
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

  Future<void> _klasorleriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? [];
    setState(() {
      klasorListesi = klasorJsonList.asMap().entries.map((e) {
        final map = json.decode(e.value);
        return KlasorData.fromMap({
          'klasor_id': e.key + 1,
          'klasor_adi': map['klasor_adi'],
          'iconCode': map['iconCode'] ?? 0xe2c7,
        });
      }).toList();
    });
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
    SharedPreferences prefs = await SharedPreferences.getInstance(); // prefs'i burada tanımla
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? []; // klasorJsonList'i burada tanımla
    klasorJsonList.add(json.encode({
      'klasor_adi': klasorAdi,
      'iconCode': iconCode,
    }));
    await prefs.setStringList('klasorler', klasorJsonList);
    _klasorleriYukle().then((_) {
      _filtreleKlasorler(aramaController.text); // Yeni klasör eklendiğinde filtreyi güncelle
    });
  }

  // Mevcut sil metodunuzun güncellenmiş hali
  Future<void> sil(int klasor_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); // prefs'i burada tanımla
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? []; // klasorJsonList'i burada tanımla
    if (klasor_id > 0 && klasor_id <= klasorJsonList.length) {
      // Klasörün içindeki tarifleri de sil
      String tarifKey = 'tarifler_$klasor_id';
      await prefs.remove(tarifKey);
      klasorJsonList.removeAt(klasor_id - 1);
      await prefs.setStringList('klasorler', klasorJsonList);
      _klasorleriYukle().then((_) {
        _filtreleKlasorler(aramaController.text); // Silme işleminden sonra filtreyi güncelle
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: aramaYapiliyorMu
            ? TextField(
          controller: aramaController, // Arama kontrolcüsünü ata
          autofocus: true,
          decoration: const InputDecoration(hintText: "Klasör ara..."), // Hint metnini değiştir
          onChanged: (arama) {
            _filtreleKlasorler(arama); // Arama yapıldığında filtreleme metodunu çağır
          },
        )
            : const Text("Tarif Defteri",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          aramaYapiliyorMu
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                aramaYapiliyorMu = false;
                aramaController.clear(); // Arama metnini temizle
                _filtreleKlasorler(''); // Filtreyi sıfırla (tüm klasörleri göster)
              });
            },
          )
              : Showcase(
                key: _searchKey,
                title: 'Arama',
                description: 'Klasörler içinde hızlıca arama yapabilirsiniz.',
                child: IconButton(
                  icon: const Icon(Icons.search,color: Colors.black,),
                  onPressed: () {
                    setState(() {
                      aramaYapiliyorMu = true;
                    });
                  },
                ),
              ),
          Showcase(
            key: _settingsKey,
            title: 'Ayarlar',
            description: 'Tema ve koyu mod gibi uygulama ayarlarını buradan yapın.',
            child: IconButton(
              icon: const Icon(Icons.settings,color: Colors.black,),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor, // Dinamik tema rengi
        child: filtrelenmisKlasorler.isEmpty && !aramaYapiliyorMu
            ? Center(
          child: Text(
            "Henüz hiç klasör yok!",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        )
            : (filtrelenmisKlasorler.isEmpty && aramaYapiliyorMu)
            ? Center(
          child: Text(
            "Aradığınız kritere uygun klasör bulunamadı.",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                    int kid = i + 1;
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
                color: klasor.klasor_id == -1 ? const Color(0xFFFFF3E0) : Theme.of(context).cardColor,
                child: SizedBox(
                  height: 84,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(klasor.icon, color: klasor.klasor_id == -1 ? Colors.red : Theme.of(context).primaryColor, size: 36),
                      ),
                      Expanded(
                        child: Text(
                          klasor.klasor_adi,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: klasor.klasor_id == -1 ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (klasor.klasor_id != -1)
                        IconButton(
                          onPressed: (){
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Klasör Sil'),
                                content: Text("${klasor.klasor_adi} silinsin mi?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Hayır'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      sil(klasor.klasor_id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Evet', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.clear, color: Color(0xFFA5D6A7)),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Showcase(
        key: _fabKey,
        title: 'Yeni Klasör',
        description: 'Buradan yeni bir klasör oluşturabilirsiniz.',
        child: FloatingActionButton(
          onPressed: _yeniKlasorEkle,
          backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}

// Favori tarifler için özel sayfa (Bu kısım aynı kalmalı)
class FavoriTariflerSayfasi extends StatefulWidget {
  final List<TarifData> favoriTarifler;
  const FavoriTariflerSayfasi({super.key, required this.favoriTarifler});

  @override
  State<FavoriTariflerSayfasi> createState() => _FavoriTariflerSayfasiState();
}

class _FavoriTariflerSayfasiState extends State<FavoriTariflerSayfasi> {
  List<TarifData> filtreliTarifler = [];
  bool aramaYapiliyorMu = false;
  TextEditingController aramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtreliTarifler = List.from(widget.favoriTarifler);
  }

  void _filtreleTarifler(String arama) {
    setState(() {
      if (arama.isEmpty) {
        filtreliTarifler = List.from(widget.favoriTarifler);
      } else {
        filtreliTarifler = widget.favoriTarifler.where((tarif) =>
          tarif.tarif_adi.toLowerCase().contains(arama.toLowerCase()) ||
          tarif.tarif_aciklama.toLowerCase().contains(arama.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _favoriDurumunuDegistir(TarifData tarif) async {
    // Bu kısım şimdilik basit bir toggle işlemi yapıyor
    // Gerçek uygulamada veritabanında güncelleme yapılacak
    setState(() {
      tarif.isFavorite = !tarif.isFavorite;
      if (!tarif.isFavorite) {
        filtreliTarifler.removeWhere((t) => t.tarif_id == tarif.tarif_id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: aramaYapiliyorMu
            ? TextField(
                controller: aramaController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Favori tarif ara...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: _filtreleTarifler,
              )
            : const Text('Favori Tarifler'),
        actions: [
          IconButton(
            icon: Icon(aramaYapiliyorMu ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (aramaYapiliyorMu) {
                  aramaYapiliyorMu = false;
                  aramaController.clear();
                  filtreliTarifler = List.from(widget.favoriTarifler);
                } else {
                  aramaYapiliyorMu = true;
                }
              });
            },
          ),
        ],
      ),
      body: filtreliTarifler.isEmpty
          ? const Center(child: Text('Hiç favori tarif yok!'))
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        itemCount: filtreliTarifler.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          var tarif = filtreliTarifler[index];
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
                height: 90,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      if (tarif.tarif_resimler.isNotEmpty)
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(tarif.tarif_resimler.first),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      
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
                              'Detayları görmek için tıklayın',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favori butonu
                          IconButton(
                            icon: Icon(
                              tarif.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => _favoriDurumunuDegistir(tarif),
                          ),
                          // Paylaş butonu
                          IconButton(
                            icon: Icon(
                              Icons.share,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () {
                              // Paylaşma işlevi burada olacak
                            },
                          ),
                          // Silme butonu
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () {
                              // Silme işlevi burada olacak
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