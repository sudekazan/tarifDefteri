import 'package:flutter/material.dart';

class KlasorData {
  late int klasor_id;
  late String klasor_adi;
  late int iconCode;
  late int updatedAt; // Last modification timestamp

  KlasorData({
    required this.klasor_id,
    required this.klasor_adi,
    this.iconCode = 0xe2c7, // Varsayılan: Icons.folder
    int? updatedAt,
  }) {
    this.updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;
  }

  IconData get icon {
    return IconData(iconCode, fontFamily: 'MaterialIcons');
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