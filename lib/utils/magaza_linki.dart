import 'dart:io';

/// Paylaşım metinlerine eklenen indirme linki; platforma göre doğru mağazaya gider.
/// tarif_detay.dart, klasorler.dart ve klasor_ici.dart'taki paylaşımlar ortak kullanır.
String get magazaLinki => Platform.isIOS
    ? 'https://apps.apple.com/tr/app/dijital-tarif-defteri/id6759447259'
    : 'https://play.google.com/store/apps/details?id=com.sudekazan.tarif_defteri_yeni';
