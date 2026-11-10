/// Malzeme listesindeki ara başlıkları ("Kek İçin", "Üzeri için:") bulur.
///
/// Tarifte ara başlıklar ayrı bir alan değil, malzeme satırlarının arasına
/// yazılmış düz satırlar. Yemek modunda bunlar işaretlenecek malzeme gibi
/// görünmesin diye ayıklanır; kayıtlı veri değişmez.
library;

final RegExp _maddeIsareti = RegExp(r'^\s*[*\-•–—]\s+');
final RegExp _rakam = RegExp(r'[0-9½¼¾]');

/// [satirlar] içindeki ara başlıkların sıra numaraları.
///
/// Bir satır başlık sayılır, eğer içinde rakam yoksa ve
/// - ":" ile bitiyorsa, ya da
/// - listedeki başka satırlar "* ", "- ", "• " ile başlarken bu satır
///   işaretsizse.
Set<int> malzemeBaslikIndeksleri(List<String> satirlar) {
  final isaretliVar = satirlar.any(_maddeIsareti.hasMatch);
  final basliklar = <int>{};
  for (var i = 0; i < satirlar.length; i++) {
    final satir = satirlar[i].trim();
    if (satir.isEmpty || _rakam.hasMatch(satir)) continue;
    final isaretsiz = isaretliVar && !_maddeIsareti.hasMatch(satir);
    if (satir.endsWith(':') || isaretsiz) basliklar.add(i);
  }
  return basliklar;
}

/// Satırın başındaki madde işaretini ("* ", "- ", "• ") atar; yemek modunda
/// onay kutusu zaten madde işareti görevi görür.
String malzemeIsaretsiz(String satir) => satir.replaceFirst(_maddeIsareti, '');
