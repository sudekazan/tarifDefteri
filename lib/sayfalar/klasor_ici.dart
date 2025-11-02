import 'package:flutter/material.dart';
import 'package:tarif_defteri/sayfalar/tarif_olusturma.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class KlasorIci extends StatefulWidget {
  final KlasorData klasorData;
  const KlasorIci({super.key, required this.klasorData});

  @override
  State<KlasorIci> createState() => _KlasorIciState();
}

class _KlasorIciState extends State<KlasorIci> {
  List<TarifData> tarifListesi = [];
  List<TarifData> filtreliTarifler = [];
  bool aramaYapiliyorMu = false;
  TextEditingController aramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tarifleriYukle();
  }

  Future<void> _tarifleriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    setState(() {
      tarifListesi = tariflerJson.map((e) {
        var map = json.decode(e);
        return TarifData(
          tarif_id: map['tarif_id'],
          tarif_adi: map['tarif_adi'],
          tarif_aciklama: map['tarif_aciklama'],
          tarif_resimler: map['tarif_resimler'] != null
              ? List<String>.from(map['tarif_resimler'])
              : map['tarif_resim'] != null && map['tarif_resim'].isNotEmpty
                  ? [map['tarif_resim']]
                  : [],
          klasor_id: map['klasor_id'],
          isFavorite: map['isFavorite'] ?? false,
        );
      }).toList();
      filtreliTarifler = List.from(tarifListesi);
    });
  }

  void _filtreleTarifler(String arama) {
    setState(() {
      if (arama.isEmpty) {
        filtreliTarifler = List.from(tarifListesi);
      } else {
        filtreliTarifler = tarifListesi.where((tarif) =>
          tarif.tarif_adi.toLowerCase().contains(arama.toLowerCase()) ||
          tarif.tarif_aciklama.toLowerCase().contains(arama.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _tarifEkle(TarifData yeniTarif) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    yeniTarif.tarif_id = tariflerJson.length + 1;
    tariflerJson.add(json.encode({
      'tarif_id': yeniTarif.tarif_id,
      'tarif_adi': yeniTarif.tarif_adi,
      'tarif_aciklama': yeniTarif.tarif_aciklama,
      'tarif_resimler': yeniTarif.tarif_resimler,
      'klasor_id': yeniTarif.klasor_id,
      'isFavorite': yeniTarif.isFavorite,
    }));
    await prefs.setStringList(key, tariflerJson);
    _tarifleriYukle();
  }

  Future<void> _tarifGuncelle(TarifData guncelTarif) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    int index = tariflerJson.indexWhere((e) => json.decode(e)['tarif_id'] == guncelTarif.tarif_id);
    if (index != -1) {
      tariflerJson[index] = json.encode({
        'tarif_id': guncelTarif.tarif_id,
        'tarif_adi': guncelTarif.tarif_adi,
        'tarif_aciklama': guncelTarif.tarif_aciklama,
        'tarif_resimler': guncelTarif.tarif_resimler,
        'klasor_id': guncelTarif.klasor_id,
        'isFavorite': guncelTarif.isFavorite,
      });
      await prefs.setStringList(key, tariflerJson);
      _tarifleriYukle();
    }
  }

  void _tarifDuzenle(TarifData tarif) async {
    final guncelTarif = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TarifOlusturma(tarifData: tarif)),
    );
    if (guncelTarif != null && guncelTarif is TarifData && guncelTarif.tarif_adi.isNotEmpty) {
      _tarifGuncelle(guncelTarif);
    }
  }

  Future<void> _tarifSil(int tarif_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'tarifler_${widget.klasorData.klasor_id}';
    List<String> tariflerJson = prefs.getStringList(key) ?? [];
    tariflerJson.removeWhere((e) => json.decode(e)['tarif_id'] == tarif_id);
    await prefs.setStringList(key, tariflerJson);
    _tarifleriYukle();
  }

  void _yeniTarifEkle() async {
    final yeniTarif = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TarifOlusturma(
          tarifData: TarifData(
            tarif_id: 0,
            tarif_adi: '',
            tarif_aciklama: '',
            tarif_resimler: [],
            klasor_id: widget.klasorData.klasor_id,
            isFavorite: false,
          ),
        ),
      ),
    );
    if (yeniTarif != null && yeniTarif is TarifData && yeniTarif.tarif_adi.isNotEmpty) {
      _tarifEkle(yeniTarif);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    return Scaffold(
        appBar: AppBar(
          title: aramaYapiliyorMu
              ? TextField(
                  controller: aramaController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Tarif ara..."),
                  onChanged: (arama) {
                    if (mounted) {
                      _filtreleTarifler(arama);
                    }
                  },
                )
              : Text(widget.klasorData.klasor_adi, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          actions: [
            aramaYapiliyorMu
                ? IconButton(
                    key: const ValueKey('clear_search'),
                    icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          aramaYapiliyorMu = false;
                          aramaController.clear();
                          filtreliTarifler = List.from(tarifListesi);
                        });
                      }
                    },
                  )
                : IconButton(
                    key: const ValueKey('search_button'),
                    icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          aramaYapiliyorMu = true;
                        });
                      }
                    },
                  ),
          ],
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: filtreliTarifler.isEmpty
              ? Center(
                  child: Text(
                    "Henüz hiç tarif yok!",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                )
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
                          _tarifGuncelle(guncelTarif);
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
                                // Görsel önizleme geçici olarak devre dışı
                                /* if (tarif.tarif_resimler.isNotEmpty)
                                  Container(
                                    width: 60,
                                    height: 60,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: File(tarif.tarif_resimler.first).existsSync()
                                        ? Image.file(
                                            File(tarif.tarif_resimler.first),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Icon(Icons.broken_image, color: Colors.grey[600], size: 24),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 24),
                                          ),
                                    ),
                                  ), */
                                
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
                                      onPressed: () async {
                                        setState(() {
                                          tarif.isFavorite = !tarif.isFavorite;
                                        });
                                        SharedPreferences prefs = await SharedPreferences.getInstance();
                                        String key = 'tarifler_${widget.klasorData.klasor_id}';
                                        List<String> tariflerJson = prefs.getStringList(key) ?? [];
                                        int idx = tariflerJson.indexWhere((e) => (json.decode(e)['tarif_id'] == tarif.tarif_id));
                                        if (idx != -1) {
                                          var map = json.decode(tariflerJson[idx]);
                                          map['isFavorite'] = tarif.isFavorite;
                                          tariflerJson[idx] = json.encode(map);
                                          await prefs.setStringList(key, tariflerJson);
                                        }
                                      },
                                    ),
                                    
                                    // Paylaş butonu
                                    Builder(
                                      builder: (BuildContext btnContext) {
                                        return IconButton(
                                          icon: Icon(
                                            Icons.share,
                                            color: Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: () async {
                                            try {
                                              String shareText = '📖 ${tarif.tarif_adi}\n\n';
                                              shareText += tarif.tarif_aciklama;
                                              shareText += '\n\n━━━━━━━━━━━━━━━━━━\n';
                                              shareText += '📱 Tarif Defterimden paylaşıldı';
                                              
                                              // iOS için butonun konumunu al
                                              final box = btnContext.findRenderObject() as RenderBox?;
                                              final sharePositionOrigin = box != null 
                                                ? box.localToGlobal(Offset.zero) & box.size
                                                : null;
                                              
                                              await Share.share(
                                                shareText,
                                                subject: tarif.tarif_adi,
                                                sharePositionOrigin: sharePositionOrigin,
                                              );
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Paylaşım yapılamadı'),
                                                    backgroundColor: Colors.red,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    
                                    // Silme butonu
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Tarif Sil'),
                                            content: Text("${tarif.tarif_adi} silinsin mi?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Hayır'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _tarifSil(tarif.tarif_id);
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
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _yeniTarifEkle,
          backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
    );
  }
}