/// Arama için metni sadeleştirir. Dart'ın toLowerCase'i Türkçe I/İ'yi doğru
/// çevirmez ("Islak" -> "islak", oysa aranan "ıslak"); bu yüzden "ıslak"
/// araması "Islak Kek"i bulamıyordu. Noktalı/noktasız i farkı yok sayılır.
String aramaIcinNormallestir(String metin) => metin
    .toLowerCase()
    .replaceAll('̇', '') // "İ".toLowerCase() -> "i" + birleşik nokta
    .replaceAll('ı', 'i');

/// [metin] içinde [sorgu] geçiyor mu (büyük/küçük harf ve Türkçe i/ı farkı yok sayılır).
bool aramaEslesir(String metin, String sorgu) =>
    aramaIcinNormallestir(metin).contains(aramaIcinNormallestir(sorgu));
