import 'package:flutter/material.dart';

class KlasorData{
  late int klasor_id;
  late String klasor_adi;
  late int iconCode;

  KlasorData({
    required this.klasor_id,
    required this.klasor_adi,
    this.iconCode = 0xe2c7, // Varsayılan: Icons.folder
  });

  static const IconData _defaultIcon = Icons.folder;
  
  IconData get icon {
    if (iconCode == 0xe2c7) return _defaultIcon;
    return IconData(iconCode, fontFamily: 'MaterialIcons');
  }

  Map<String, dynamic> toMap() => {
    'klasor_id': klasor_id,
    'klasor_adi': klasor_adi,
    'iconCode': iconCode,
  };

  factory KlasorData.fromMap(Map<String, dynamic> map) => KlasorData(
    klasor_id: map['klasor_id'],
    klasor_adi: map['klasor_adi'],
    iconCode: map['iconCode'] ?? 0xe2c7,
  );
}