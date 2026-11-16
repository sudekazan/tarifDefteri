import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../tarifler_data/tarif_data.dart';
import 'firebase_service.dart';

/// Tarifly linkiyle tarif paylaşma.
///
/// Paylaşan (giriş yapmış) kişinin tarifinin bir kopyası herkesin
/// okuyabildiği `paylasilanTarifler/{kod}` belgesine yazılır; link
/// `https://tarifly.web.app/t/{kod}` olur. Tarifly yüklüyse link uygulamayı
/// açar (iOS Universal Links, Android App Links), değilse aynı adresteki web
/// sayfası tarifi gösterir.
///
/// Belge, paylaşma anındaki kopyadır: paylaşan tarifi sonra değiştirirse
/// link yeniden paylaşılınca güncellenir. Alıcı ekleyince tarif onun
/// defterine bağımsız bir kopya olarak yazılır.

/// Linklerin alan adı (Firebase Hosting'deki `tarifly` sitesi).
const String paylasimAlanAdi = 'tarifly.web.app';

/// Firestore koleksiyonu. Kuralı Firebase konsolunda: herkes okur, yalnızca
/// sahibi yazar ve siler.
const String paylasilanTariflerKoleksiyonu = 'paylasilanTarifler';

/// Paylaşılan tarifte en fazla kaç fotoğraf gider.
const int paylasimEnFazlaResim = 5;

/// Paylaşılan fotoğraflar yalnızca Firebase Storage'dan gelir; başka
/// adresler (elle yazılmış belgeler) yok sayılır.
const String _resimAdresiBasi = 'https://firebasestorage.googleapis.com/';

const int _kodUzunlugu = 8;

// Karıştırılan harfler (0/O, 1/l/I) yok.
const String _kodHarfleri =
    'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';

final RegExp _kodBicimi = RegExp(r'^[A-Za-z0-9]{8}$');

/// Rastgele 8 harfli paylaşım kodu.
String yeniPaylasimKodu([Random? rastgele]) {
  final r = rastgele ?? Random.secure();
  return List.generate(
    _kodUzunlugu,
    (_) => _kodHarfleri[r.nextInt(_kodHarfleri.length)],
  ).join();
}

/// Koddan paylaşım linki.
String paylasimLinki(String kod) => 'https://$paylasimAlanAdi/t/$kod';

/// Gelen link bir Tarifly paylaşım linkiyse kodu, değilse null döner.
String? linktenPaylasimKodu(Uri uri) {
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  if (uri.host != paylasimAlanAdi) return null;
  final parcalar = uri.pathSegments.where((p) => p.isNotEmpty).toList();
  if (parcalar.length != 2 || parcalar[0] != 't') return null;
  return _kodBicimi.hasMatch(parcalar[1]) ? parcalar[1] : null;
}

/// Paylaşılan belgenin içeriği (zaman damgaları hariç). Yalnızca Firebase
/// Storage adresi olan fotoğraflar girer.
Map<String, dynamic> paylasimBelgesi({
  required TarifData tarif,
  required List<Map<String, dynamic>> bolumler,
  required String sahipUid,
  required List<String> resimler,
  required String dil,
}) {
  return {
    'sahipUid': sahipUid,
    'tarifId': tarif.tarif_id,
    'ad': tarif.tarif_adi,
    'aciklama': tarif.tarif_aciklama,
    'bolumler': [
      for (final b in bolumler)
        {
          'title': '${b['title'] ?? ''}',
          'type': '${b['type'] ?? ''}',
          'items': List<String>.from(b['items'] ?? const []),
        },
    ],
    'resimler': resimler
        .where((r) => r.startsWith(_resimAdresiBasi))
        .take(paylasimEnFazlaResim)
        .toList(),
    'dil': dil,
    'surum': 1,
  };
}

/// Firestore'dan gelen paylaşım verisinin bölümleri. Bozuk alanlar atlanır.
List<Map<String, dynamic>> paylasimBolumleri(Map<String, dynamic> veri) {
  final ham = veri['bolumler'];
  if (ham is! List) return [];
  final sonuc = <Map<String, dynamic>>[];
  for (final b in ham) {
    if (b is! Map) continue;
    final maddeler = b['items'];
    sonuc.add({
      'title': '${b['title'] ?? ''}',
      'type': '${b['type'] ?? ''}',
      'items': maddeler is List ? maddeler.map((m) => '$m').toList() : <String>[],
    });
  }
  return sonuc;
}

/// Firestore'dan gelen paylaşım verisinin fotoğraf adresleri.
List<String> paylasimResimleri(Map<String, dynamic> veri) {
  final ham = veri['resimler'];
  if (ham is! List) return [];
  return ham
      .whereType<String>()
      .where((r) => r.startsWith(_resimAdresiBasi))
      .take(paylasimEnFazlaResim)
      .toList();
}

/// Paylaşılan veriden alıcının defterine yazılacak yeni tarif.
/// Fotoğraflar ayrıca indirilip [resimler] olarak verilir.
TarifData paylasilandanTarif(
  Map<String, dynamic> veri, {
  required int klasorId,
  required List<String> resimler,
  int? simdi,
}) {
  final zaman = simdi ?? DateTime.now().millisecondsSinceEpoch;
  final bolumler = paylasimBolumleri(veri);
  return TarifData(
    tarif_id: zaman,
    tarif_adi: '${veri['ad'] ?? ''}',
    tarif_aciklama: '${veri['aciklama'] ?? ''}',
    tarif_aciklama_json: bolumler.isEmpty ? null : json.encode(bolumler),
    tarif_resimler: resimler,
    klasor_id: klasorId,
    updatedAt: zaman,
  );
}

class TarifPaylasimService {
  TarifPaylasimService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _koleksiyon =>
      _firestore.collection(paylasilanTariflerKoleksiyonu);

  /// Tarifin paylaşım linkini oluşturur. Aynı tarif daha önce paylaşıldıysa
  /// aynı kod kullanılır, içerik güncellenir. Giriş yoksa hata fırlatır.
  /// Cihazda duran fotoğraflar önce buluta yüklenir.
  Future<String> linkOlustur(
    TarifData tarif, {
    required List<Map<String, dynamic>> bolumler,
    required String dil,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Paylaşmak için giriş gerekli');

    final resimler = await _bulutAdresleri(tarif.tarif_resimler);

    final onceki = await _koleksiyon
        .where('sahipUid', isEqualTo: uid)
        .where('tarifId', isEqualTo: tarif.tarif_id)
        .limit(1)
        .get();

    final veri = paylasimBelgesi(
      tarif: tarif,
      bolumler: bolumler,
      sahipUid: uid,
      resimler: resimler,
      dil: dil,
    );
    veri['guncelleme'] = FieldValue.serverTimestamp();

    final String kod;
    if (onceki.docs.isNotEmpty) {
      kod = onceki.docs.first.id;
      await _koleksiyon.doc(kod).set(veri, SetOptions(merge: true));
    } else {
      kod = yeniPaylasimKodu();
      veri['olusturulma'] = FieldValue.serverTimestamp();
      await _koleksiyon.doc(kod).set(veri);
    }
    return paylasimLinki(kod);
  }

  /// Paylaşılan tarifi getirir; yoksa null.
  Future<Map<String, dynamic>?> getir(String kod) async {
    final belge = await _koleksiyon.doc(kod).get();
    return belge.exists ? belge.data() : null;
  }

  /// Kullanıcının paylaştığı tüm tarifleri siler (hesap silinirken).
  Future<void> kullanicininPaylasimlariniSil(String uid) async {
    final belgeler =
        await _koleksiyon.where('sahipUid', isEqualTo: uid).get();
    for (final b in belgeler.docs) {
      await b.reference.delete();
    }
  }

  /// Paylaşılan fotoğrafları alıcının cihazına indirir; böylece paylaşan
  /// tarifi silse de alıcıdaki kopya bozulmaz. İndirilemeyen fotoğrafın
  /// bulut adresi kalır.
  Future<List<String>> resimleriIndir(List<String> adresler) async {
    if (adresler.isEmpty) return [];
    final klasor = Directory(
      path.join((await getApplicationDocumentsDirectory()).path, 'tarif_images'),
    );
    if (!await klasor.exists()) await klasor.create(recursive: true);

    final sonuc = <String>[];
    final zaman = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < adresler.length; i++) {
      try {
        final yanit = await http
            .get(Uri.parse(adresler[i]))
            .timeout(const Duration(seconds: 20));
        if (yanit.statusCode != 200 || yanit.bodyBytes.isEmpty) {
          sonuc.add(adresler[i]);
          continue;
        }
        final dosya = File(path.join(klasor.path, 'paylasilan_${zaman}_$i.jpg'));
        await dosya.writeAsBytes(yanit.bodyBytes);
        sonuc.add(dosya.path);
      } catch (e) {
        debugPrint('Paylaşılan fotoğraf indirilemedi: $e');
        sonuc.add(adresler[i]);
      }
    }
    return sonuc;
  }

  /// Fotoğrafların bulut adresleri; cihazdaki fotoğraflar yüklenir.
  /// Yüklenemeyen fotoğraf paylaşıma girmez.
  Future<List<String>> _bulutAdresleri(List<String> yollar) async {
    final sonuc = <String>[];
    for (final yol in yollar) {
      if (sonuc.length >= paylasimEnFazlaResim) break;
      if (yol.startsWith(_resimAdresiBasi)) {
        sonuc.add(yol);
        continue;
      }
      final dosya = File(yol);
      if (!dosya.existsSync()) continue;
      final adres = await FirebaseService().uploadImage(dosya);
      if (adres != null) sonuc.add(adres);
    }
    return sonuc;
  }
}
