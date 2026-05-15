import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AiRecipeService {
  
  // Platforma göre doğru localhost adresini bulur
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  /// Kullanıcının girdiği yemek ismine göre yapay zekadan tarif oluşturur.
  Future<Map<String, dynamic>> generateRecipe(String dishName) async {
    try {
      // Firebase giriş yapmış olan kullanıcının kimlik token'ını alıyoruz
      User? user = FirebaseAuth.instance.currentUser;
      String idToken = "test-test-test"; // Test token'ı (Eğer kullanıcı giriş yapmadıysa test ortamı kabulü için)
      
      if (user != null) {
        idToken = await user.getIdToken() ?? "test-test-test";
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
