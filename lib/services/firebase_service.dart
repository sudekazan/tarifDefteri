import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../tarifler_data/tarif_data.dart';
import '../tarifler_data/klasor_data.dart';
import '../utils/error_helper.dart';
import 'revenuecat_service.dart';
import 'tarif_paylasim_service.dart';

/// Kullanıcı Google/Apple sign-in akışını kendi isteğiyle iptal ettiğinde
/// (ör. hesap seçim ekranını kapatınca) fırlatılır; bu durumda hata
/// mesajı gösterilmemelidir.
class SignInCancelledException implements Exception {}

/// deleteUserAccount() sırasında Firebase Auth hesabını silmek için
/// yeniden (güncel) kimlik doğrulaması gerektiğinde fırlatılır. UI, silmeden
/// önce [FirebaseService.reauthYontemi]'ne göre kimliği tazelediği için
/// normalde oluşmaz; oluşursa kullanıcı işlemi baştan tekrar dener (silme
/// adımları tekrar çalıştırılabilir, zararsızdır).
class ReauthRequiredException implements Exception {
  @override
  String toString() => 'requires-recent-login';
}

/// Hesap silme gibi hassas işlemlerden önce kimliğin hangi yöntemle
/// tazeleneceği. Google/Apple ile giriş yapan kullanıcıların şifresi yoktur.
enum ReauthYontemi { sifre, google, apple }

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
        'updatedAt': klasor.updatedAt,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Klasör kaydetme hatası: $e');
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
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        int? updatedAt;
        if (data['updatedAt'] != null) {
          if (data['updatedAt'] is Timestamp) {
            updatedAt = (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
          } else if (data['updatedAt'] is int) {
            updatedAt = data['updatedAt'];
          }
        }
        return KlasorData(
          klasor_id: data['klasor_id'],
          klasor_adi: data['klasor_adi'],
          iconCode: data['iconCode'],
          updatedAt: updatedAt,
        );
      }).toList();
    } catch (e) {
      debugPrint('Klasör yükleme hatası: $e');
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
      debugPrint('Klasör silme hatası: $e');
    }
  }

  // Tarifi Firebase'e kaydet — cloud URL listesini döndürür
  Future<List<String>> saveTarifToFirebase(TarifData tarif) async {
    if (!isUserLoggedIn) return tarif.tarif_resimler;

    try {
      // Yerel fotoğrafları buluta yükle ve URL'leri güncelle
      List<String> guncelResimler = await _checkAndUploadLocalImages(tarif.tarif_resimler);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tarifler')
          .doc('${tarif.klasor_id}_${tarif.tarif_id}')
          .set({
        'tarif_id': tarif.tarif_id,
        'tarif_adi': tarif.tarif_adi,
        'tarif_aciklama': tarif.tarif_aciklama,
        'tarif_aciklama_json': tarif.tarif_aciklama_json,
        'tarif_resimler': guncelResimler,
        'klasor_id': tarif.klasor_id,
        'isFavorite': tarif.isFavorite,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': tarif.updatedAt,
      }, SetOptions(merge: true));

      return guncelResimler; // Upload sonrası URL'leri döndür
    } catch (e) {
      debugPrint('Tarif kaydetme hatası: $e');
      return tarif.tarif_resimler;
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
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return TarifData.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Tarif yükleme hatası: $e');
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
      debugPrint('Tarif silme hatası: $e');
    }
  }

  // Bir tarife ait tüm görselleri (hem yerel dosya hem Firebase Storage) kalıcı olarak sil.
  // Tarif tamamen silindiğinde yetim dosya/görsel kalmaması için çağrılmalı.
  Future<void> deleteImagesForTarif(TarifData tarif) async {
    for (final path in tarif.tarif_resimler) {
      if (path.isEmpty) continue;
      try {
        if (path.startsWith('http')) {
          await _storage.refFromURL(path).delete();
        } else {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      } catch (e) {
        debugPrint('Görsel silinirken hata (yok sayılabilir): $e');
      }
    }
  }

  // Tarifi güncelle — fotoğrafların son yollarını (yüklenenler için bulut
  // adresi) döndürür
  Future<List<String>> updateTarifInFirebase(TarifData tarif) async {
    if (!isUserLoggedIn) return tarif.tarif_resimler;

    try {
      // Yerel fotağrafları buluta yükle ve yolları güncelle
      List<String> guncelResimler = await _checkAndUploadLocalImages(tarif.tarif_resimler);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tarifler')
          .doc('${tarif.klasor_id}_${tarif.tarif_id}')
          .update({
        'tarif_adi': tarif.tarif_adi,
        'tarif_aciklama': tarif.tarif_aciklama,
        'tarif_aciklama_json': tarif.tarif_aciklama_json,
        'tarif_resimler': guncelResimler,
        'isFavorite': tarif.isFavorite,
        'updatedAt': tarif.updatedAt,
      });
      return guncelResimler;
    } catch (e) {
      debugPrint('Tarif güncelleme hatası: $e');
      return tarif.tarif_resimler;
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
      debugPrint('Local verileri Firebase\'e yedekleme hatası: $e');
    }
  }

  // Yerel verileri Firebase'deki verilerle akıllıca birleştir
  Future<void> mergeLocalAndCloudData() async {
    if (!isUserLoggedIn) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Firebase'den güncel verileri çek
      final cloudKlasorler = await loadKlasorlerFromFirebase();
      final localKlasorJsonList = prefs.getStringList('klasorler') ?? [];
      
      // 2. Yerel klasörleri oku
      final List<KlasorData> localKlasorler = [];
      for (int i = 0; i < localKlasorJsonList.length; i++) {
        final map = json.decode(localKlasorJsonList[i]);
        final int klasorId = map['klasor_id'] ?? i + 1;
        localKlasorler.add(KlasorData(
          klasor_id: klasorId,
          klasor_adi: map['klasor_adi'],
          iconCode: map['iconCode'] ?? 0xe2c7,
          updatedAt: map['updatedAt'],
        ));
      }
      
      // 3. Klasör ID'lerini birleştir ve en güncelini seç
      final Map<int, KlasorData> mergedKlasorlerMap = {};
      
      for (var k in cloudKlasorler) {
        mergedKlasorlerMap[k.klasor_id] = k;
      }
      
      for (var k in localKlasorler) {
        if (!mergedKlasorlerMap.containsKey(k.klasor_id)) {
          mergedKlasorlerMap[k.klasor_id] = k;
          await saveKlasorToFirebase(k);
        } else {
          // İkisi de varsa updatedAt'e bak
          final cloudK = mergedKlasorlerMap[k.klasor_id]!;
          if (k.updatedAt > cloudK.updatedAt) {
            mergedKlasorlerMap[k.klasor_id] = k; // Yerel daha yeni
            await saveKlasorToFirebase(k);
          }
        }
      }
      
      // 4. Her klasör için tarifleri birleştir
      Map<int, List<TarifData>> mergedTarifler = {};
      
      for (final klasorId in mergedKlasorlerMap.keys) {
        final localKey = 'tarifler_$klasorId';
        final localTariflerJson = prefs.getStringList(localKey) ?? [];
        final List<TarifData> localTarifler = localTariflerJson.map((e) {
          return TarifData.fromMap(json.decode(e));
        }).toList();
        
        final cloudTarifler = await loadTariflerFromFirebase(klasorId);
        
        final Map<int, TarifData> tarifMap = {};
        
        // Cloud tariflerini haritaya ekle
        for (var tarif in cloudTarifler) {
          tarifMap[tarif.tarif_id] = tarif;
        }
        
        // Yerel tarifleri kontrol et
        for (var tarif in localTarifler) {
          if (!tarifMap.containsKey(tarif.tarif_id)) {
            // Sadece yerelde var
            tarif.tarif_resimler = await saveTarifToFirebase(tarif);
            tarifMap[tarif.tarif_id] = tarif;
          } else {
            // Her ikisinde de var
            final cloudT = tarifMap[tarif.tarif_id]!;
            if (tarif.updatedAt > cloudT.updatedAt) {
              // Yerel tarif daha yeni, cloud'u güncelle
              await updateTarifInFirebase(tarif);
              tarifMap[tarif.tarif_id] = tarif;
            }
          }
        }
        
        // Resimleri kontrol et
        for (var tarif in tarifMap.values) {
          List<String> originalPaths = List.from(tarif.tarif_resimler);
          List<String> cloudPaths = await _checkAndUploadLocalImages(originalPaths);
          if (!_listEquals(originalPaths, cloudPaths)) {
            tarif.tarif_resimler = cloudPaths;
            await updateTarifInFirebase(tarif);
          }
        }

        mergedTarifler[klasorId] = tarifMap.values.toList();
      }

      // 5. Birleştirilmiş verileri yerel depolamaya kaydet
      final mergedKlasorList = mergedKlasorlerMap.values.toList();
      final List<String> klasorJsonList = mergedKlasorList.map((klasor) {
        return json.encode(klasor.toMap());
      }).toList();
      
      await prefs.setStringList('klasorler', klasorJsonList);
      
      for (final entry in mergedTarifler.entries) {
        final key = 'tarifler_${entry.key}';
        final List<String> tariflerJson = entry.value.map((tarif) {
          return json.encode(tarif.toMap());
        }).toList();
        await prefs.setStringList(key, tariflerJson);
      }
      
      debugPrint('Yerel ve cloud verileri başarıyla birleştirildi!');
    } catch (e) {
      debugPrint('Veri birleştirme hatası: $e');
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
      debugPrint('Yedekleme hatası: $e');
    }
  }

  /// Google hesap seçicisini açıp Firebase kimlik bilgisi üretir; giriş ve
  /// yeniden doğrulama aynı akışı kullanır.
  Future<AuthCredential> _googleCredential() async {
    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw KullaniciHatasi('auth_error_google_token'.tr());
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw SignInCancelledException();
      }
      // SDK'nın ham metni (ör. "providerConfigurationError ...") kullanıcıya değil konsola.
      debugPrint('Google sign-in hatası: $e');
      throw KullaniciHatasi('auth_error_google_token'.tr());
    }
  }

  /// Apple ile oturum açma penceresini açıp Firebase kimlik bilgisini ve
  /// (yalnızca ilk girişte dolu gelen) ad/soyad bilgisini döndürür.
  Future<(OAuthCredential, AuthorizationCredentialAppleID)>
      _appleCredential() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      return (oauthCredential, appleCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw SignInCancelledException();
      }
      debugPrint('Apple sign-in hatası: $e');
      throw KullaniciHatasi('auth_error_apple_failed'.tr());
    } on SignInWithAppleException catch (e) {
      debugPrint('Apple sign-in hatası: $e');
      throw KullaniciHatasi('auth_error_apple_failed'.tr());
    }
  }

  // Google hesabıyla giriş yap
  Future<UserCredential> signInWithGoogle() async {
    return _auth.signInWithCredential(await _googleCredential());
  }

  // Apple ID ile giriş yap
  Future<UserCredential> signInWithApple() async {
    final (oauthCredential, appleCredential) = await _appleCredential();
    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple yalnızca ilk girişte ad/soyad döner; Firebase profilinde yoksa ekle
    final user = userCredential.user;
    if (user != null &&
        (user.displayName == null || user.displayName!.isEmpty) &&
        (appleCredential.givenName != null ||
            appleCredential.familyName != null)) {
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((e) => e != null && e.isNotEmpty).join(' ');
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
      }
    }

    return userCredential;
  }

  /// Mevcut kullanıcının hangi yöntemle yeniden doğrulanması gerektiği.
  /// Şifresi olan hesapta şifre tercih edilir (en az sürtünmeli yol).
  ReauthYontemi? get reauthYontemi {
    final providers =
        _auth.currentUser?.providerData.map((p) => p.providerId).toSet() ??
            const <String>{};
    if (providers.contains('password')) return ReauthYontemi.sifre;
    if (providers.contains('google.com')) return ReauthYontemi.google;
    if (providers.contains('apple.com')) return ReauthYontemi.apple;
    return null;
  }

  /// Google ile giriş yapmış kullanıcının kimliğini tazeler (hesap silme öncesi).
  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw ReauthRequiredException();
    await user.reauthenticateWithCredential(await _googleCredential());
  }

  /// Apple ile giriş yapmış kullanıcının kimliğini tazeler (hesap silme öncesi).
  Future<void> reauthenticateWithApple() async {
    final user = _auth.currentUser;
    if (user == null) throw ReauthRequiredException();
    final (oauthCredential, _) = await _appleCredential();
    await user.reauthenticateWithCredential(oauthCredential);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Çıkıştan önce çağrılır: cihazdaki tüm klasör ve tarifleri (fotoğraflar
  /// dahil) buluta yazar ve sunucuya gerçekten ulaştıklarını doğrular.
  /// Hepsi buluttaysa true döner. [sure] içinde bitmezse (ör. internet yok)
  /// ya da bir şey eksik kalırsa false döner; çıkış cihazdaki kopyayı
  /// sildiği için kullanıcı o durumda uyarılmalıdır.
  Future<bool> cikisOncesiYedekle({
    Duration sure = const Duration(seconds: 30),
  }) async {
    if (!isUserLoggedIn) return true;
    try {
      return await _yedekleVeDogrula().timeout(sure);
    } catch (e) {
      debugPrint('Çıkış öncesi yedekleme tamamlanamadı: $e');
      return false;
    }
  }

  Future<bool> _yedekleVeDogrula() async {
    final kullanici = _firestore.collection('users').doc(userId);
    final prefs = await SharedPreferences.getInstance();
    final klasorJsonList = prefs.getStringList('klasorler') ?? [];

    final klasorIdleri = <String>{};
    final tarifIdleri = <String>{};
    var batch = _firestore.batch();
    var bekleyen = 0;
    Future<void> yaz(DocumentReference ref, Map<String, dynamic> veri) async {
      batch.set(ref, veri, SetOptions(merge: true));
      if (++bekleyen >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        bekleyen = 0;
      }
    }

    for (int i = 0; i < klasorJsonList.length; i++) {
      final map = json.decode(klasorJsonList[i]);
      final int klasorId = map['klasor_id'] ?? i + 1;
      klasorIdleri.add('$klasorId');
      await yaz(kullanici.collection('klasorler').doc('$klasorId'), {
        'klasor_id': klasorId,
        'klasor_adi': map['klasor_adi'],
        'iconCode': map['iconCode'] ?? 0xe2c7,
        if (map['updatedAt'] != null) 'updatedAt': map['updatedAt'],
      });

      for (final e in prefs.getStringList('tarifler_$klasorId') ?? <String>[]) {
        final tarif = TarifData.fromMap(json.decode(e));
        final resimler = await _checkAndUploadLocalImages(tarif.tarif_resimler);
        // Dosyası cihazda duran ama yüklenemeyen fotoğraf: yedek eksik.
        if (resimler.any((p) => !p.startsWith('http') && File(p).existsSync())) {
          return false;
        }
        final belgeId = '${klasorId}_${tarif.tarif_id}';
        tarifIdleri.add(belgeId);
        await yaz(kullanici.collection('tarifler').doc(belgeId), {
          'tarif_id': tarif.tarif_id,
          'tarif_adi': tarif.tarif_adi,
          'tarif_aciklama': tarif.tarif_aciklama,
          'tarif_aciklama_json': tarif.tarif_aciklama_json,
          'tarif_resimler': resimler,
          'klasor_id': klasorId,
          'isFavorite': tarif.isFavorite,
          'updatedAt': tarif.updatedAt,
        });
      }
    }
    if (bekleyen > 0) await batch.commit();

    // Daha önce sıraya girmiş yazmalar da sunucuya ulaşsın.
    await _firestore.waitForPendingWrites();

    // Önbellekten değil sunucudan oku: her şey gerçekten orada mı?
    const sunucudan = GetOptions(source: Source.server);
    final sunucuKlasorler = await kullanici.collection('klasorler').get(sunucudan);
    final sunucuTarifler = await kullanici.collection('tarifler').get(sunucudan);
    return sunucuKlasorler.docs.map((d) => d.id).toSet().containsAll(klasorIdleri) &&
        sunucuTarifler.docs.map((d) => d.id).toSet().containsAll(tarifIdleri);
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
    await _oturumKalintilariniTemizle();
  }

  /// Çıkışta ve hesap silindikten sonra: Google oturumunu, RevenueCat
  /// kimliğini ve cihazdaki klasör/tarif verilerini temizler (tema gibi
  /// ayarlar korunur).
  Future<void> _oturumKalintilariniTemizle() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google sign-out hatası: $e');
    }
    await RevenueCatService.logoutFromRevenueCat();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key == 'klasorler' || key.startsWith('tarifler_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Yerel kullanıcı verileri temizlenirken hata: $e');
    }
  }

  // Kullanıcıya ait Storage'daki tüm dosyaları (klasör + alt klasörler) sil
  Future<void> _deleteAllUserStorageFiles(String userId) async {
    Future<void> deleteFolderRecursive(Reference ref) async {
      final listResult = await ref.listAll();
      for (var item in listResult.items) {
        try {
          await item.delete();
        } catch (e) {
          debugPrint('Storage dosyası silinemedi (${item.fullPath}): $e');
        }
      }
      for (var prefix in listResult.prefixes) {
        await deleteFolderRecursive(prefix);
      }
    }

    try {
      await deleteFolderRecursive(_storage.ref().child('users').child(userId));
    } catch (e) {
      // Klasör yoksa (hiç görsel yüklenmemişse) listAll hata verebilir, görmezden gel.
      debugPrint('Kullanıcı storage klasörü silinirken hata (yok sayılabilir): $e');
    }
  }

  /// Kullanıcı hesabını ve tüm verilerini kalıcı olarak siler.
  /// UI bunu çağırmadan önce [reauthYontemi]'ne göre kimliği tazelemelidir;
  /// aksi halde veriler silinip son adımda "requires-recent-login" alınabilir.
  /// Adımlar tekrar çalıştırılabilir: yarıda kalırsa tekrar denemek güvenlidir.
  Future<void> deleteUserAccount() async {
    if (!isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    final currentUserId = userId!;

    // 0. Paylaşım linkleriyle herkese açılmış tarif kopyalarını sil
    await TarifPaylasimService(firestore: _firestore, auth: _auth)
        .kullanicininPaylasimlariniSil(currentUserId);

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

    // 4. Storage'a yüklenmiş tüm görselleri sil (yetim dosya kalmasın)
    await _deleteAllUserStorageFiles(currentUserId);

    // 5. Firebase Authentication'dan hesabı sil.
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw ReauthRequiredException();
      }
      rethrow;
    }

    // Hesap silindi: Google oturumunu, RevenueCat kimliğini (aynı cihazda
    // açılacak yeni hesap eski aboneliği miras almasın) ve cihazdaki
    // tarif/klasör kopyalarını temizle — kullanıcıya "tüm tarifleriniz
    // silinecek" dendi, yerel kopyalar kalırsa yeni hesapta geri yüklenirdi.
    await _oturumKalintilariniTemizle();

    // Alışveriş listesi yalnızca cihazda durur; çıkışta korunur ama hesap
    // silinince "tüm verileriniz silinir" sözü gereği o da temizlenir.
    // (Anahtarlar: lib/sayfalar/alisveris_listesi.dart)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('shopping_list_todo');
      await prefs.remove('shopping_list_done');
    } catch (e) {
      debugPrint('Alışveriş listesi temizlenirken hata: $e');
    }
  }

  /// Şifreyle giriş yapmış kullanıcının kimliğini tazeler (hesap silme öncesi).
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw ReauthRequiredException();
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  // Görseli Firebase Storage'a yükle
  Future<String?> uploadImage(File file) async {
    if (!isUserLoggedIn) return null;

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('users')
          .child(userId!)
          .child('recipes')
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Görsel yükleme hatası: $e');
      return null;
    }
  }

  // Yerel görselleri kontrol et ve buluta yükle
  Future<List<String>> _checkAndUploadLocalImages(List<String> paths) async {
    List<String> results = [];
    for (String path in paths) {
      if (path.startsWith('http')) {
        results.add(path);
      } else {
        File file = File(path);
        if (file.existsSync()) {
          String? url = await uploadImage(file);
          if (url != null) {
            results.add(url);
          } else {
            results.add(path);
          }
        } else {
          results.add(path);
        }
      }
    }
    return results;
  }

  // Yardımcı fonksiyon: Listeleri karşılaştır
  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
