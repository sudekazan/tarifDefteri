import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/ai_modu.dart';
import '../utils/error_helper.dart';

export '../utils/ai_modu.dart';

/// generateRecipe() başarılı olduğunda döndürülen sonuç.
/// [remaining], backend'in o hafta, o tür için hesapladığı gerçek kalan ücretsiz
/// hak sayısıdır (Pro kullanıcılarda null = sınırsız).
class AiRecipeResult {
  final Map<String, dynamic> recipeData;
  final int? remaining;

  AiRecipeResult({required this.recipeData, this.remaining});
}

/// Premium öneri kartlarından biri.
class AiOnerisi {
  final String baslik;
  final String aciklama;

  const AiOnerisi({required this.baslik, required this.aciklama});
}

/// suggestRecipes() sonucu; seçilen kartın tam tarifi [suggestionId] ile istenir.
class AiOneriSonucu {
  final String suggestionId;
  final List<AiOnerisi> oneriler;

  const AiOneriSonucu({required this.suggestionId, required this.oneriler});
}

/// Backend haftalık ücretsiz AI Şef limitini (429) döndürdüğünde fırlatılır.
class AiLimitExceededException implements Exception {
  final String message;
  AiLimitExceededException(this.message);

  @override
  String toString() => message;
}

class AiRecipeService {

  // Platforma göre doğru localhost adresini bulur
  String get _baseUrl {
    // Uygulama yayına alındığı için artık tüm platformlarda canlı sunucuyu kullanıyoruz
    return 'https://api.dijitaltarifdefteri.com.tr/api';
  }

  Future<String> _getIdToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw KullaniciHatasi('auth_required_for_ai'.tr());
    }
    try {
      final idToken = await user.getIdToken() ?? '';
      if (idToken.isEmpty) {
        throw StateError('Firebase idToken boş döndü');
      }
      return idToken;
    } catch (e) {
      debugPrint('Token error: $e');
      throw KullaniciHatasi('ai_error_session'.tr());
    }
  }

  Future<http.Response> _post(
    String yol,
    Map<String, dynamic> govde,
    Duration zamanAsimi,
  ) async {
    final idToken = await _getIdToken();
    return http
        .post(
          Uri.parse('$_baseUrl/$yol'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer $idToken', // İsteğe "giriş yapılmış" ibaresi eklenir
          },
          body: jsonEncode(govde),
        )
        .timeout(zamanAsimi);
  }

  /// Ortak hata kodlarını kullanıcı hatasına çevirir ve başarılı yanıtın
  /// gövdesini döndürür. `success: false` durumu çağırana bırakılır.
  Map<String, dynamic> _yanitiCoz(http.Response response) {
    debugPrint('Status Code: ${response.statusCode}');

    if (response.statusCode == 401) {
      throw KullaniciHatasi('ai_error_session'.tr());
    }
    if (response.statusCode == 400) {
      throw KullaniciHatasi('ai_error_not_food'.tr());
    }
    if (response.statusCode == 410) {
      throw KullaniciHatasi('ai_error_suggestion_expired'.tr());
    }
    if (response.statusCode >= 500) {
      throw KullaniciHatasi('ai_error_server'.tr());
    }

    // Sunucu uyanırken JSON yerine HTML dönebilir; ham FormatException
    // kullanıcıya gitmesin.
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AI yanıtı ayrıştırılamadı: $e');
      throw KullaniciHatasi('ai_error_server'.tr());
    }

    if (response.statusCode == 429) {
      // Saatlik istek sınırı hak bitimiyle karıştırılmamalı; aksi halde
      // hakkı olan kullanıcıya "reklam izle / Premium'a geç" gösterilir.
      if (data['rateLimited'] == true) {
        throw KullaniciHatasi('ai_error_rate_limited'.tr());
      }
      throw AiLimitExceededException(
        data['message'] ?? 'ai_limit_reached'.tr(),
      );
    }
    if (response.statusCode == 403) {
      throw KullaniciHatasi('ai_error_server'.tr());
    }
    return data;
  }

  /// `success: false` yanıtındaki mesajı yapay zekâ kullanıcının dilinde
  /// yazar (ör. "bu bir yemek adı değil"); yoksa çevrilmiş genel mesaj.
  Never _basarisizYanit(Map<String, dynamic> data) {
    final aiMesaji = data['message'];
    throw KullaniciHatasi(
      aiMesaji is String && aiMesaji.trim().isNotEmpty
          ? aiMesaji
          : 'ai_error_not_food'.tr(),
    );
  }

  /// Kullanıcının girdiği yemek ismine (ya da elindeki malzemelere) göre
  /// yapay zekadan tarif oluşturur.
  /// [mode]: [AiModu.yemekAdi] ya da [AiModu.malzeme]; backend buna göre
  /// başlık üretimini, mesajları ve hangi haftalık haktan düşüleceğini ayırır.
  Future<AiRecipeResult> generateRecipe(
    String dishName, {
    String languageCode = 'en',
    String mode = AiModu.yemekAdi,
  }) async {
    final response = await _post('generate-recipe', {
      'prompt': dishName,
      'language': languageCode,
      'mode': mode,
    }, const Duration(seconds: 45));
    final data = _yanitiCoz(response);
    final remaining = data['remaining'] is int
        ? data['remaining'] as int
        : null;
    if (data['success'] != true) _basarisizYanit(data);
    return AiRecipeResult(
      recipeData: Map<String, dynamic>.from(data['data']),
      remaining: remaining,
    );
  }

  /// Premium: malzemelerden 3 kısa tarif önerisi ister (bir hak düşer).
  Future<AiOneriSonucu> suggestRecipes(
    String prompt, {
    String languageCode = 'en',
  }) async {
    final response = await _post('suggest-recipes', {
      'prompt': prompt,
      'language': languageCode,
    }, const Duration(seconds: 45));
    final data = _yanitiCoz(response);
    if (data['success'] != true) _basarisizYanit(data);

    final oneriler = <AiOnerisi>[
      for (final o in (data['oneriler'] as List? ?? const []))
        if (o is Map && o['baslik'] is String)
          AiOnerisi(
            baslik: o['baslik'] as String,
            aciklama: o['aciklama'] is String ? o['aciklama'] as String : '',
          ),
    ];
    final id = data['suggestionId'];
    if (oneriler.isEmpty || id is! String) {
      throw KullaniciHatasi('ai_error_server'.tr());
    }
    return AiOneriSonucu(suggestionId: id, oneriler: oneriler);
  }

  /// Öneri kartlarından seçilen tarifin tamamını üretir; hak düşmez.
  Future<AiRecipeResult> generateFromSuggestion(
    String suggestionId,
    int index,
  ) async {
    final response = await _post('generate-recipe', {
      'suggestionId': suggestionId,
      'suggestionIndex': index,
    }, const Duration(seconds: 45));
    final data = _yanitiCoz(response);
    if (data['success'] != true) _basarisizYanit(data);
    return AiRecipeResult(recipeData: Map<String, dynamic>.from(data['data']));
  }

  /// Kullanıcı ödüllü reklamı tam izlediğinde çağrılır; o haftaya [mod]
  /// için +1 ekstra hak tanır ve yeni "kalan hak" sayısını döndürür.
  /// Haftalık bonus hakkı da dolmuşsa null döner.
  Future<int?> grantBonusUse({required String mod}) async {
    try {
      final response = await _post('grant-bonus-ai-use', {
        'mode': mod,
      }, const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
          'grantBonusUse failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['remaining'] is int ? data['remaining'] as int : null;
    } catch (e) {
      debugPrint('grantBonusUse error: $e');
      return null;
    }
  }
}
