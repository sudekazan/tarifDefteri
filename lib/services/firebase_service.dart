import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../tarifler_data/tarif_data.dart';
import '../tarifler_data/klasor_data.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı ID'sini al
  String? get userId => _auth.currentUser?.uid;

  // Kullanıcının giriş yapıp yapmadığını kontrol et
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Klasörleri Firebase'e kaydet
  Future<void> saveKlasorToFirebase(KlasorData klasor) async {
    if (!isUserLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('klasorler')
          .doc(klasor.klasor_id.toString())
          .set({
        'klasor_id': klasor.klasor_id,
        'klasor_adi': klasor.klasor_adi,
        'iconCode': klasor.iconCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Klasör kaydetme hatası: $e');
    }
  }

  // Klasörleri Firebase'den yükle
  Future<List<KlasorData>> loadKlasorlerFromFirebase() async {
    if (!isUserLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('klasorler')
          .orderBy('createdAt')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return KlasorData(
          klasor_id: data['klasor_id'],
          klasor_adi: data['klasor_adi'],
          iconCode: data['iconCode'],
        );
      }).toList();
    } catch (e) {
      print('Klasör yükleme hatası: $e');
      return [];
    }
  }

  // Klasörü Firebase'den sil
  Future<void> deleteKlasorFromFirebase(int klasorId) async {
    if (!isUserLoggedIn) return;

    try {
      // Klasörü sil
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('klasorler')
          .doc(klasorId.toString())
          .delete();

      // Klasöre ait tarifleri de sil
      final tarifler = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tarifler')
          .where('klasor_id', isEqualTo: klasorId)
          .get();

      for (var doc in tarifler.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Klasör silme hatası: $e');
    }
  }

  // Tarifi Firebase'e kaydet
  Future<void> saveTarifToFirebase(TarifData tarif) async {
    if (!isUserLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tarifler')
          .doc('${tarif.klasor_id}_${tarif.tarif_id}')
          .set({
        'tarif_id': tarif.tarif_id,
        'tarif_adi': tarif.tarif_adi,
        'tarif_aciklama': tarif.tarif_aciklama,
        'tarif_resimler': tarif.tarif_resimler,
        'klasor_id': tarif.klasor_id,
        'isFavorite': tarif.isFavorite,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Tarif kaydetme hatası: $e');
    }
  }

  // Tarifleri Firebase'den yükle
  Future<List<TarifData>> loadTariflerFromFirebase(int klasorId) async {
    if (!isUserLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tarifler')
          .where('klasor_id', isEqualTo: klasorId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TarifData(
          tarif_id: data['tarif_id'],
          tarif_adi: data['tarif_adi'],
          tarif_aciklama: data['tarif_aciklama'],
          tarif_resimler: List<String>.from(data['tarif_resimler'] ?? []),
          klasor_id: data['klasor_id'],
          isFavorite: data['isFavorite'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Tarif yükleme hatası: $e');
      return [];
    }
  }

  // Tarifi Firebase'den sil
  Future<void> deleteTarifFromFirebase(int klasorId, int tarifId) async {
    if (!isUserLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tarifler')
          .doc('${klasorId}_$tarifId')
          .delete();
    } catch (e) {
      print('Tarif silme hatası: $e');
    }
  }

  // Tarifi güncelle
  Future<void> updateTarifInFirebase(TarifData tarif) async {
    if (!isUserLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tarifler')
          .doc('${tarif.klasor_id}_${tarif.tarif_id}')
          .update({
        'tarif_adi': tarif.tarif_adi,
        'tarif_aciklama': tarif.tarif_aciklama,
        'tarif_resimler': tarif.tarif_resimler,
        'isFavorite': tarif.isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Tarif güncelleme hatası: $e');
    }
  }

  Future<void> backupLocalDataToFirebase() async {
    if (!isUserLoggedIn) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final klasorJsonList = prefs.getStringList('klasorler') ?? [];
      final List<KlasorData> klasorler = [];
      final Map<int, List<TarifData>> tariflerMap = {};

      for (int i = 0; i < klasorJsonList.length; i++) {
        final map = json.decode(klasorJsonList[i]);
        final int klasorId = map['klasor_id'] ?? i + 1;
        final klasor = KlasorData(
          klasor_id: klasorId,
          klasor_adi: map['klasor_adi'],
          iconCode: map['iconCode'] ?? 0xe2c7,
        );
        klasorler.add(klasor);

        final key = 'tarifler_$klasorId';
        final tariflerJson = prefs.getStringList(key) ?? [];
        final List<TarifData> tarifList = tariflerJson.map((e) {
          final tarifMap = json.decode(e);
          return TarifData.fromMap(tarifMap);
        }).toList();

        if (tarifList.isNotEmpty) {
          tariflerMap[klasorId] = tarifList;
        }
      }

      await backupToFirebase(klasorler, tariflerMap);
    } catch (e) {
      print('Local verileri Firebase\'e yedekleme hatası: $e');
    }
  }

  Future<void> restoreFromFirebaseToLocal() async {
    if (!isUserLoggedIn) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final klasorler = await loadKlasorlerFromFirebase();

      final List<String> klasorJsonList = klasorler.map((klasor) {
        final map = {
          'klasor_id': klasor.klasor_id,
          'klasor_adi': klasor.klasor_adi,
          'iconCode': klasor.iconCode,
        };
        return json.encode(map);
      }).toList();

      await prefs.setStringList('klasorler', klasorJsonList);

      for (final klasor in klasorler) {
        final tarifler = await loadTariflerFromFirebase(klasor.klasor_id);
        final key = 'tarifler_${klasor.klasor_id}';
        final List<String> tariflerJson = tarifler.map((tarif) {
          final map = {
            'tarif_id': tarif.tarif_id,
            'tarif_adi': tarif.tarif_adi,
            'tarif_aciklama': tarif.tarif_aciklama,
            'tarif_resimler': tarif.tarif_resimler,
            'klasor_id': tarif.klasor_id,
            'isFavorite': tarif.isFavorite,
          };
          return json.encode(map);
        }).toList();
        await prefs.setStringList(key, tariflerJson);
      }
    } catch (e) {
      print('Firebase\'den local\'e veri çekme hatası: $e');
    }
  }

  // Yerel verileri Firebase'deki verilerle akıllıca birleştir
  Future<void> mergeLocalAndCloudData() async {
    if (!isUserLoggedIn) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Önce yerel verileri Firebase'e yedekle
      await backupLocalDataToFirebase();
      
      // 2. Firebase'den güncel verileri çek
      final cloudKlasorler = await loadKlasorlerFromFirebase();
      final localKlasorJsonList = prefs.getStringList('klasorler') ?? [];
      
      // 3. Yerel klasörleri oku
      final List<KlasorData> localKlasorler = [];
      for (int i = 0; i < localKlasorJsonList.length; i++) {
        final map = json.decode(localKlasorJsonList[i]);
        final int klasorId = map['klasor_id'] ?? i + 1;
        localKlasorler.add(KlasorData(
          klasor_id: klasorId,
          klasor_adi: map['klasor_adi'],
          iconCode: map['iconCode'] ?? 0xe2c7,
        ));
      }
      
      // 4. Klasör ID'lerini birleştir (hem yerel hem de cloud'dan gelenleri)
      final Set<int> allKlasorIds = {};
      allKlasorIds.addAll(localKlasorler.map((k) => k.klasor_id));
      allKlasorIds.addAll(cloudKlasorler.map((k) => k.klasor_id));
      
      // 5. Her klasör için tarifleri birleştir
      Map<int, List<TarifData>> mergedTarifler = {};
      
      for (final klasorId in allKlasorIds) {
        // Yerel tarifleri oku
        final localKey = 'tarifler_$klasorId';
        final localTariflerJson = prefs.getStringList(localKey) ?? [];
        final List<TarifData> localTarifler = localTariflerJson.map((e) {
          return TarifData.fromMap(json.decode(e));
        }).toList();
        
        // Cloud tariflerini oku
        final cloudTarifler = await loadTariflerFromFirebase(klasorId);
        
        // Tarifleri birleştir (tarif_id'ye göre deduplicate et)
        final Map<int, TarifData> tarifMap = {};
        
        // Önce cloud tariflerini ekle
        for (var tarif in cloudTarifler) {
          tarifMap[tarif.tarif_id] = tarif;
        }
        
        // Sonra yerel tarifleri ekle (eğer aynı ID yoksa)
        for (var tarif in localTarifler) {
          if (!tarifMap.containsKey(tarif.tarif_id)) {
            tarifMap[tarif.tarif_id] = tarif;
            // Yeni yerel tarifi Firebase'e de kaydet
            await saveTarifToFirebase(tarif);
          }
        }
        
        mergedTarifler[klasorId] = tarifMap.values.toList();
      }
      
      // 6. Birleştirilmiş klasörleri oluştur (cloud öncelikli, ama yerel olanları da ekle)
      final Map<int, KlasorData> mergedKlasorlerMap = {};
      
      // Cloud klasörleri ekle
      for (var klasor in cloudKlasorler) {
        mergedKlasorlerMap[klasor.klasor_id] = klasor;
      }
      
      // Yerel klasörleri ekle (eğer cloud'da yoksa)
      for (var klasor in localKlasorler) {
        if (!mergedKlasorlerMap.containsKey(klasor.klasor_id)) {
          mergedKlasorlerMap[klasor.klasor_id] = klasor;
          // Yeni yerel klasörü Firebase'e de kaydet
          await saveKlasorToFirebase(klasor);
        }
      }
      
      // 7. Birleştirilmiş verileri yerel depolamaya kaydet
      final mergedKlasorList = mergedKlasorlerMap.values.toList();
      final List<String> klasorJsonList = mergedKlasorList.map((klasor) {
        final map = {
          'klasor_id': klasor.klasor_id,
          'klasor_adi': klasor.klasor_adi,
          'iconCode': klasor.iconCode,
        };
        return json.encode(map);
      }).toList();
      
      await prefs.setStringList('klasorler', klasorJsonList);
      
      // Tarifleri kaydet
      for (final entry in mergedTarifler.entries) {
        final key = 'tarifler_${entry.key}';
        final List<String> tariflerJson = entry.value.map((tarif) {
          final map = {
            'tarif_id': tarif.tarif_id,
            'tarif_adi': tarif.tarif_adi,
            'tarif_aciklama': tarif.tarif_aciklama,
            'tarif_resimler': tarif.tarif_resimler,
            'klasor_id': tarif.klasor_id,
            'isFavorite': tarif.isFavorite,
          };
          return json.encode(map);
        }).toList();
        await prefs.setStringList(key, tariflerJson);
      }
      
      print('Yerel ve cloud verileri başarıyla birleştirildi!');
    } catch (e) {
      print('Veri birleştirme hatası: $e');
      rethrow;
    }
  }

  // Tüm verileri Firebase'e yedekle (local -> cloud)
  Future<void> backupToFirebase(
      List<KlasorData> klasorler, Map<int, List<TarifData>> tarifler) async {
    if (!isUserLoggedIn) return;

    try {
      // Klasörleri kaydet
      for (var klasor in klasorler) {
        await saveKlasorToFirebase(klasor);
      }

      // Tarifleri kaydet
      for (var entry in tarifler.entries) {
        for (var tarif in entry.value) {
          await saveTarifToFirebase(tarif);
        }
      }
    } catch (e) {
      print('Yedekleme hatası: $e');
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Kullanıcı hesabını ve tüm verilerini kalıcı olarak sil
  Future<void> deleteUserAccount() async {
    if (!isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      final currentUserId = userId;
      
      // 1. Kullanıcının tüm tariflerini sil
      final tariflerSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tarifler')
          .get();
      
      for (var doc in tariflerSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Kullanıcının tüm klasörlerini sil
      final klasorlerSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('klasorler')
          .get();
      
      for (var doc in klasorlerSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3. Kullanıcı belgesini sil
      await _firestore.collection('users').doc(currentUserId).delete();

      // 4. Firebase Authentication'dan hesabı sil
      await _auth.currentUser?.delete();
      
    } catch (e) {
      print('Hesap silme hatası: $e');
      rethrow; // Hatayı yukarı fırlat ki UI'da gösterebillelim
    }
  }
}
