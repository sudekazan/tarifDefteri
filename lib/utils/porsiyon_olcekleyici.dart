/// Malzeme satırındaki ilk miktarı porsiyon çarpanıyla ölçekler.
///
/// "2 su bardağı" -> "4 su bardağı", "1 1/2 kaşık" -> "3 kaşık",
/// "200g un" -> "400g un". "2-3 kaşık" gibi aralıklara dokunmaz.
/// Ondalık virgülle yazılmış girdide ("1,5") sonucu da virgülle yazar.
/// Bozuk girdide ("1,5/2", "1/0") çökmez, satırı olduğu gibi döndürür.
String olcekleMalzeme(String malzeme, double carpan) {
  if (carpan == 1.0) return malzeme;

  final match = _miktar.firstMatch(malzeme);
  if (match == null) return malzeme;

  final tamKisim = match.group(1)!;
  final tam = double.tryParse(tamKisim.replaceAll(',', '.'));
  if (tam == null) return malzeme;

  double deger;
  if (match.group(2) != null) {
    // Karışık kesir: "1 1/2"
    final payda = int.parse(match.group(3)!);
    if (payda == 0) return malzeme;
    deger = tam + int.parse(match.group(2)!) / payda;
  } else if (match.group(4) != null) {
    // Basit kesir: "1/2"
    final payda = int.parse(match.group(4)!);
    if (payda == 0) return malzeme;
    deger = tam / payda;
  } else {
    deger = tam;
  }

  var sonuc = (deger * carpan)
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
  if (tamKisim.contains(',')) sonuc = sonuc.replaceAll('.', ',');
  return malzeme.replaceRange(match.start, match.end, sonuc);
}

// Önünde/arkasında rakam, ayraç ya da tire olmayan ilk sayı; ardından
// isteğe bağlı " 1/2" (karışık kesir) ya da "/2" (kesir).
final _miktar = RegExp(
  r'(?<![\d.,/\-])(\d+(?:[.,]\d+)?)(?:\s+(\d+)/(\d+)|/(\d+))?(?![\d.,/\-])',
);
