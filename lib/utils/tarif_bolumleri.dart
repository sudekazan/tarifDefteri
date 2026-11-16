import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../tarifler_data/tarif_data.dart';

/// Tarifin bölümleri (malzemeler, yapılış, sos...). Her bölüm
/// `{'title', 'type', 'items'}` alanlı bir Map'tir; `items` bir `List<String>`.
///
/// Yeni tariflerde bölümler `tarif_aciklama_json` alanında durur. Eski
/// tariflerde yalnızca düz metin vardır; o zaman metin başlık kelimelerine
/// ve madde işaretlerine bakılarak bölümlere ayrılır.
///
/// [varsayilanBaslik]: Başlıksız maddeler için açılan bölümün adı (çevrilmiş
/// "Malzemeler"). Çeviri çağıranda yapılır; böylece işlev testte de çalışır.
List<Map<String, dynamic>> tarifBolumleriniCoz(
  TarifData tarif, {
  required String varsayilanBaslik,
}) {
  final jsonMetni = tarif.tarif_aciklama_json;
  if (jsonMetni != null && jsonMetni.isNotEmpty) {
    try {
      final List<dynamic> decoded = json.decode(jsonMetni);
      return decoded.map<Map<String, dynamic>>((e) {
        return {
          'title': e['title'],
          'type': e['type'],
          'items': List<String>.from(e['items'] ?? []),
          'isExpanded': e['isExpanded'] ?? true,
        };
      }).toList();
    } catch (e) {
      debugPrint('Tarif bölümleri JSON çözülemedi: $e');
    }
  }
  return _duzMetniCoz(tarif.tarif_aciklama, varsayilanBaslik);
}

List<Map<String, dynamic>> _duzMetniCoz(String metin, String varsayilanBaslik) {
  final bolumler = <Map<String, dynamic>>[];
  if (metin.isEmpty) return bolumler;

  String currentSection = '';
  String currentType = '';
  List<String> currentItems = [];

  void ekle() {
    // Başlık ve madde varsa eklenir.
    if (currentSection.isNotEmpty && currentItems.isNotEmpty) {
      bolumler.add({
        'title': currentSection,
        'type': currentType,
        'items': List<String>.from(currentItems),
      });
    }
  }

  bool isHeader(String line, List<String> keywords) {
    final lower = line.replaceAll(':', '').trim().toLowerCase();
    // Numaralı ya da işaretli maddeler başlık sayılmaz
    // ("2. İç malzemelerini karıştırın" gibi).
    if (RegExp(r'^\d+').hasMatch(lower)) return false;
    if (lower.startsWith('*') || lower.startsWith('-') || lower.startsWith('•')) {
      return false;
    }
    // Uzun satırlar başlık sayılmaz.
    if (lower.length > 40) return false;
    for (final k in keywords) {
      if (lower.contains(k.toLowerCase())) return true;
    }
    return false;
  }

  const basliklar = <(String, List<String>)>[
    ('malzemeler', ['malzemeler', 'ingredients', 'içindekiler']),
    ('harc', ['harç', 'filling', 'iç harcı']),
    ('hamur', ['hamuru', 'dough', 'hamur']),
    ('serbet', ['şerbeti', 'syrup', 'şerbet', 'serbet']),
    ('sos', ['sosu', 'sauce', 'sos']),
    ('puf_noktasi', ['püf noktası', 'tips', 'puf noktasi', 'chef notes']),
    ('yapilis', ['yapılışı', 'instructions', 'steps', 'hazırlanışı', 'tarif', 'yapilis']),
    ('linkler', ['linkler', 'links']),
  ];

  for (final line in metin.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final baslikTuru = basliklar
        .where((b) => isHeader(trimmed, b.$2))
        .map((b) => b.$1)
        .firstOrNull;

    if (baslikTuru != null) {
      ekle();
      currentSection = trimmed.replaceAll(':', '');
      currentType = baslikTuru;
      currentItems = [];
    } else if (trimmed.startsWith('*') ||
        trimmed.startsWith('•') ||
        trimmed.startsWith('-') ||
        RegExp(r'^\d+\.').hasMatch(trimmed) ||
        trimmed.startsWith('🔗')) {
      String item;
      if (trimmed.startsWith('*') || trimmed.startsWith('•') || trimmed.startsWith('-')) {
        item = trimmed.substring(1).trim();
      } else if (trimmed.startsWith('🔗')) {
        item = trimmed.replaceFirst('🔗', '').trim();
      } else {
        item = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
      }
      if (item.isNotEmpty) {
        // Başlıksız madde: varsayılan olarak "Malzemeler" bölümü açılır.
        if (currentSection.isEmpty) {
          currentSection = varsayilanBaslik;
          currentType = 'malzemeler';
        }
        currentItems.add(item);
      }
    } else if (currentItems.isNotEmpty) {
      // Önceki maddenin devamı (çok satırlı madde).
      currentItems[currentItems.length - 1] += ' $trimmed';
    } else if (currentSection.isNotEmpty) {
      // Bölüm var ama madde yok: açıklama gibi eklenir.
      currentItems.add(trimmed);
    }
    // Bölüm de madde de yoksa düz metin yok sayılır.
  }
  ekle();
  return bolumler;
}

/// Tarifin paylaşım için düz metni: ad, bölümler (malzemeler madde işaretli,
/// yapılış numaralı). Bölüm yoksa ham açıklama.
String tarifDuzMetni(TarifData tarif, List<Map<String, dynamic>> bolumler) {
  final b = StringBuffer('📖 ${tarif.tarif_adi}\n\n');
  if (bolumler.isEmpty) {
    b.write(tarif.tarif_aciklama);
    b.write('\n');
    return b.toString();
  }
  for (final bolum in bolumler) {
    b.write('${bolum['title']}\n');
    b.write('${'─' * 20}\n');
    final List<String> maddeler = List<String>.from(bolum['items'] ?? const []);
    for (var i = 0; i < maddeler.length; i++) {
      b.write(bolum['type'] == 'yapilis' ? '${i + 1}. ' : '• ');
      b.write('${maddeler[i]}\n');
    }
    b.write('\n');
  }
  return b.toString();
}
