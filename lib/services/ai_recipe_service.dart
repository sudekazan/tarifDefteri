import 'package:cloud_functions/cloud_functions.dart';

class AiRecipeService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Kullanıcının girdiği yemek ismine göre yapay zekadan tarif oluşturur.
  Future<Map<String, dynamic>> generateRecipe(String dishName) async {
    try {
      // Cloud Function'ı çağır
      // 'generateRecipe' ismi, functions/index.js içindeki exports.generateRecipe ile AYNI olmalı
      final callable = _functions.httpsCallable('generateRecipe');
      
      final result = await callable.call(<String, dynamic>{
        'prompt': dishName,
      }).timeout(const Duration(seconds: 30));

      // Gelen veriyi kontrol et ve döndür
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Tarif oluşturulurken bir hata oluştu');
      }
      
    } catch (e) {
      // Hataları yakala ve yukarı fırlat (UI'da göstermek için)
      print('AI Recipe Error: $e');
      if (e is FirebaseFunctionsException) {
        throw Exception('Sunucu Hatası: ${e.message}');
      }
      rethrow;
    }
  }
}
