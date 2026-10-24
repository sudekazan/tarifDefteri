import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bir metnin link/URL gibi görünüp görünmediğini kontrol eder.
/// tarif_olusturma.dart ve tarif_detay.dart'ta aynı mantık tekrarlanmasın diye ortak hale getirildi.
bool isValidRecipeUrl(String text) {
  final urlPattern = RegExp(
    r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$',
    caseSensitive: false,
  );
  final hasValidFormat = text.contains('.') && !text.contains(' ') && text.length > 3;
  return urlPattern.hasMatch(text) ||
      (hasValidFormat &&
          (text.startsWith('http') ||
              text.startsWith('www') ||
              text.contains('.com') ||
              text.contains('.net') ||
              text.contains('.org') ||
              text.contains('.tr')));
}

/// Tarif içindeki bir linki dış tarayıcıda açar; açılamazsa kullanıcıya bilgi verir.
Future<void> launchRecipeUrl(BuildContext context, String url) async {
  try {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'link_cannot_open_prefix'.tr()}$url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'link_invalid_prefix'.tr()}$url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
