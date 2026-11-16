import 'dart:io';

/// Paylaşım metinlerine eklenen indirme linki; platforma göre doğru mağazaya gider.
/// Düz metin paylaşımda kullanılır (bkz. tarif_paylas.dart).
String get magazaLinki => Platform.isIOS
    ? 'https://apps.apple.com/tr/app/dijital-tarif-defteri/id6759447259'
    : 'https://play.google.com/store/apps/details?id=com.sudekazan.tarif_defteri_yeni';
