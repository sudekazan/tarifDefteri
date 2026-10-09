import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';
import 'package:tarif_defteri/sayfalar/tarif_detay.dart';

class AramaSayfasi extends StatefulWidget {
  const AramaSayfasi({Key? key}) : super(key: key);

  @override
  State<AramaSayfasi> createState() => _AramaSayfasiState();
}

class _AramaSayfasiState extends State<AramaSayfasi> {
  final TextEditingController _aramaController = TextEditingController();
  List<TarifData> _tumTarifler = [];
  List<TarifData> _filtrelenmisTarifler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tumTarifleriYukle();
  }

  Future<void> _tumTarifleriYukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> klasorJsonList = prefs.getStringList('klasorler') ?? [];
    List<TarifData> tumTarifler = [];

    for (int i = 0; i < klasorJsonList.length; i++) {
      final map = json.decode(klasorJsonList[i]);
      int kid = map['klasor_id'] ?? (i + 1);
      
      String key = 'tarifler_$kid';
      List<String> tariflerJson = prefs.getStringList(key) ?? [];
      for (var e in tariflerJson) {
        var tarifMap = json.decode(e);
        tumTarifler.add(TarifData.fromMap(tarifMap));
      }
    }

    if (mounted) {
      setState(() {
        _tumTarifler = tumTarifler;
        _isLoading = false;
      });
    }
  }

  void _ara(String query) {
    if (query.isEmpty) {
      setState(() {
        _filtrelenmisTarifler = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filtrelenmisTarifler = _tumTarifler.where((tarif) {
        return tarif.tarif_adi.toLowerCase().contains(lowerQuery) || 
               tarif.tarif_aciklama.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _aramaController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'folders_search_hint'.tr(),
            border: InputBorder.none,
          ),
          onChanged: _ara,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _aramaController.clear();
              _ara('');
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _aramaController.text.isEmpty
              ? Center(
                  child: Text(
                    'recipe_search_prompt'.tr(),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : _filtrelenmisTarifler.isEmpty
                  ? Center(
                      child: Text(
                        'folders_search_no_results'.tr(),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      itemCount: _filtrelenmisTarifler.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        var tarif = _filtrelenmisTarifler[index];
                        return GestureDetector(
                          onTap: () async {
                            final guncelTarif = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TarifDetay(tarif: tarif),
                              ),
                            );
                            if (guncelTarif == true || (guncelTarif != null && guncelTarif is TarifData)) {
                              _tumTarifleriYukle().then((_) => _ara(_aramaController.text));
                            }
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
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
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: Icon(Icons.broken_image, color: Colors.grey[600], size: 24),
                                                );
                                              },
                                            )
                                          : File(tarif.tarif_resimler.first).existsSync()
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
                                                child: Icon(Icons.broken_image, color: Colors.grey[600], size: 24),
                                              ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      tarif.tarif_adi,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
