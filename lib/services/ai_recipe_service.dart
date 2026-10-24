import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

/// generateRecipe() başarılı olduğunda döndürülen sonuç.
/// [remaining], backend'in o gün için hesapladığı gerçek kalan ücretsiz
/// hak sayısıdır (Pro kullanıcılarda null = sınırsız).
class AiRecipeResult {
  final Map<String, dynamic> recipeData;
  final int? remaining;

  AiRecipeResult({required this.recipeData, this.remaining});
}

/// Backend günlük ücretsiz AI Şef limitini (429) döndürdüğünde fırlatılır.
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
    return 'https://tarif-defteri-api.onrender.com/api';
  }

  Future<String> _getIdToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('auth_required_for_ai'.tr());
    }
    try {
      final idToken = await user.getIdToken() ?? '';
      if (idToken.isEmpty) {
        throw Exception('Token boş döndü.');
      }
      return idToken;
    } catch (e) {
      debugPrint('Token error: $e');
      throw Exception('Oturum doğrulanamadı. Lütfen tekrar giriş yapın.');
    }
  }

  /// Kullanıcının girdiği yemek ismine göre yapay zekadan tarif oluşturur.
  Future<AiRecipeResult> generateRecipe(String dishName, {String languageCode = 'en'}) async {
    try {
      final idToken = await _getIdToken();
      final url = Uri.parse('$_baseUrl/generate-recipe');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken', // İsteğe "giriş yapılmış" ibaresi eklenir
        },
        body: jsonEncode({
          'prompt': dishName,
          'language': languageCode,
        }),
      ).timeout(const Duration(seconds: 45));

      // Terminalde loglamak için
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode >= 500) {
        throw Exception('Sunucu Hatası: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remaining = data['remaining'] is int ? data['remaining'] as int : null;

      if (response.statusCode == 429) {
        throw AiLimitExceededException(data['message'] ?? 'ai_limit_reached'.tr());
      }

      if (data['success'] == true) {
        return AiRecipeResult(recipeData: Map<String, dynamic>.from(data['data']), remaining: remaining);
      } else {
        throw Exception(data['message'] ?? 'Tarif oluşturulurken bir hata oluştu');
      }

    } catch (e) {
      debugPrint('AI Recipe Error: $e');
      rethrow;
    }
  }

  /// Kullanıcı ödüllü reklamı tam izlediğinde çağrılır; o güne +1 ekstra
  /// ücretsiz AI Şef hakkı tanır ve yeni "kalan hak" sayısını döndürür.
  /// Günlük bonus hakkı da dolmuşsa (nadir), null döner.
  Future<int?> grantBonusUse() async {
    try {
      final idToken = await _getIdToken();
      final url = Uri.parse('$_baseUrl/grant-bonus-ai-use');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('grantBonusUse failed: ${response.statusCode} ${response.body}');
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
