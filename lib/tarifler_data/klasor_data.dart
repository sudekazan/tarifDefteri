import 'package:flutter/material.dart';

class KlasorData {
  late int klasor_id;
  late String klasor_adi;
  late int iconCode;
  late int updatedAt; // Last modification timestamp

  /// Klasör ikonu (`Icons.folder`). Yeni klasörlerin varsayılanı.
  static const int varsayilanIkon = 0xe2a3;

  /// Eskiden "klasör" diye kaydedilen kod. Bugünkü ikon fontunda bu kod
  /// "5 sn ileri" (`Icons.forward_5`) ikonu; ekranda klasör ikonu gösterilir.
  /// Kayıtlı değer değiştirilmez.
  static const int eskiVarsayilanIkon = 0xe2c7;

  KlasorData({
    required this.klasor_id,
    required this.klasor_adi,
    this.iconCode = varsayilanIkon,
    int? updatedAt,
  }) {
    this.updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
  }

  IconData get icon {
    final kod = iconCode == eskiVarsayilanIkon ? varsayilanIkon : iconCode;
    return IconData(kod, fontFamily: 'MaterialIcons');
  }

  Map<String, dynamic> toMap() => {
    'klasor_id': klasor_id,
    'klasor_adi': klasor_adi,
    'iconCode': iconCode,
    'updatedAt': updatedAt,
  };

  factory KlasorData.fromMap(Map<String, dynamic> map) => KlasorData(
    klasor_id: map['klasor_id'],
    klasor_adi: map['klasor_adi'],
    iconCode: map['iconCode'] ?? 0xe2c7,
    updatedAt: map['updatedAt'],
  );
}