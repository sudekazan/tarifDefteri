import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tarifler_data/tarif_data.dart';

/// Tariflerin cihazdaki (SharedPreferences) kaydı.
///
/// Kural: tarif önce cihaza yazılır ve ekran güncellenir; buluta gönderme
/// beklenmez. Firestore yazması internet yokken sunucu onaylayana kadar
/// bitmez; beklenirse tarif kaydedilmemiş gibi görünür.

String _anahtar(int klasorId) => 'tarifler_$klasorId';

/// Yeni tarifi kendi klasörünün listesine ekler.
Future<void> yeniTarifiCihazaYaz(TarifData tarif) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _anahtar(tarif.klasor_id);
  final liste = prefs.getStringList(key) ?? [];
  liste.add(json.encode(tarif.toMap()));
  await prefs.setStringList(key, liste);
}

/// Düzenlenmiş tarifi cihazdaki kaydının yerine yazar. Kayıt bulunamazsa
/// (tarif silinmişse) hiçbir şey yazmaz ve false döner.
Future<bool> tarifiCihazdaGuncelle(TarifData tarif) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _anahtar(tarif.klasor_id);
  final liste = prefs.getStringList(key) ?? [];
  final idx = liste.indexWhere(
    (e) => json.decode(e)['tarif_id'] == tarif.tarif_id,
  );
  if (idx == -1) return false;
  liste[idx] = json.encode(tarif.toMap());
  await prefs.setStringList(key, liste);
  return true;
}

/// Tarifi cihazdan siler.
Future<void> tarifiCihazdanSil(int klasorId, int tarifId) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _anahtar(klasorId);
  final liste = prefs.getStringList(key) ?? [];
  liste.removeWhere((e) => json.decode(e)['tarif_id'] == tarifId);
  await prefs.setStringList(key, liste);
}

/// Cihaza yazılmış tarifi beklemeden buluta gönderir. [gonder] bulut
/// kaydını yapar ve fotoğrafların son yollarını (yüklenenler için bulut
/// adresi) döndürür; yollar değiştiyse cihazdaki kayıt da güncellenir.
///
/// Kullanıcı bu arada fotoğrafları yeniden düzenlediyse cihazdaki kayda
/// dokunulmaz.
Future<void> tarifiArkadanBulutaGonder(
  TarifData tarif,
  Future<List<String>> Function(TarifData tarif) gonder,
) async {
  try {
    final onceki = List<String>.from(tarif.tarif_resimler);
    final bulut = await gonder(tarif);
    if (listEquals(onceki, bulut)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _anahtar(tarif.klasor_id);
    final liste = prefs.getStringList(key) ?? [];
    final idx = liste.indexWhere(
      (e) => json.decode(e)['tarif_id'] == tarif.tarif_id,
    );
    if (idx == -1) return;
    final map = json.decode(liste[idx]) as Map<String, dynamic>;
    final kayitli = List<String>.from(map['tarif_resimler'] ?? const []);
    if (!listEquals(kayitli, onceki)) return;
    map['tarif_resimler'] = bulut;
    liste[idx] = json.encode(map);
    await prefs.setStringList(key, liste);
  } catch (e) {
    debugPrint('Tarif buluta gönderilemedi (cihazda duruyor): $e');
  }
}
