class TarifData{
  late int tarif_id;
  late String tarif_adi;
  late String tarif_aciklama;
  late List<String> tarif_resimler; // Görsel listesi
  late int klasor_id;
  bool isFavorite;

  TarifData({
    required this.tarif_id,
    required this.tarif_adi,
    required this.tarif_aciklama,
    required this.tarif_resimler, // Görsel listesi
    required this.klasor_id,
    this.isFavorite = false,
  });

  // Geriye uyumluluk için eski tarif_resim alanını da destekle
  String get tarif_resim => tarif_resimler.isNotEmpty ? tarif_resimler.first : '';

  factory TarifData.fromMap(Map<String, dynamic> map) => TarifData(
    tarif_id: map['tarif_id'],
    tarif_adi: map['tarif_adi'],
    tarif_aciklama: map['tarif_aciklama'],
    tarif_resimler: map['tarif_resimler'] != null 
        ? List<String>.from(map['tarif_resimler'])
        : map['tarif_resim'] != null && map['tarif_resim'].isNotEmpty
            ? [map['tarif_resim']] // Eski veri formatından dönüştür
            : [],
    klasor_id: map['klasor_id'],
    isFavorite: map['isFavorite'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'tarif_id': tarif_id,
    'tarif_adi': tarif_adi,
    'tarif_aciklama': tarif_aciklama,
    'tarif_resimler': tarif_resimler,
    'klasor_id': klasor_id,
    'isFavorite': isFavorite,
  };
}