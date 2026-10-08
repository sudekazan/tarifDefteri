import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
class AiRecipeService {
  
  // Platforma göre doğru localhost adresini bulur
  String get _baseUrl {
    // Uygulama yayına alındığı için artık tüm platformlarda canlı sunucuyu kullanıyoruz
    return 'https://tarif-defteri-api.onrender.com/api';
  }

  /// Kullanıcının girdiği yemek ismine göre yapay zekadan tarif oluşturur.
  Future<Map<String, dynamic>> generateRecipe(String dishName, {String languageCode = 'en'}) async {
    try {
      // Firebase giriş yapmış olan kullanıcının kimlik token'ını alıyoruz
      User? user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception('auth_required_for_ai'.tr(defaultValue: 'Yapay zeka asistanını kullanmak için lütfen giriş yapın.'));
      }
      
      String idToken = '';
      try {
        idToken = await user.getIdToken() ?? '';
        if (idToken.isEmpty) {
          throw Exception('Token boş döndü.');
        }
      } catch (e) {
        print('Token error: $e');
        throw Exception('Oturum doğrulanamadı. Lütfen tekrar giriş yapın.');
      }

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
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode >= 500) {
        throw Exception('Sunucu Hatası: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Tarif oluşturulurken bir hata oluştu');
      }
      
    } catch (e) {
      print('AI Recipe Error: $e');
      rethrow;
    }
  }
}
