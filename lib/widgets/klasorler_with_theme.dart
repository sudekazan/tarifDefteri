import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../sayfalar/klasorler.dart';

class KlasorlerWithTheme extends StatelessWidget {
  final bool isDarkMode; // Koyu mod durumu ekle
  final Function(bool) onDarkModeChanged; // Koyu mod değiştirme fonksiyonu ekle

  const KlasorlerWithTheme({
    super.key,
    required this.isDarkMode, // Gerekli parametre
    required this.onDarkModeChanged, // Gerekli parametre
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('settings_title'.tr())),
            SwitchListTile(
              title: Text('settings_dark_mode'.tr()),
              value: isDarkMode,
              onChanged: onDarkModeChanged,
            ),
          ],
        ),
      ),
      body: Klasorler(),
    );
  }
}
