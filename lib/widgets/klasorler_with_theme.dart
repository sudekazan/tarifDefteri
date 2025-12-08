import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../sayfalar/klasorler.dart';
import '../screens/theme_settings_page.dart';
import '../theme/app_theme.dart';

class KlasorlerWithTheme extends StatelessWidget {
  final Function(AppTheme) onThemeChanged;
  final AppTheme currentTheme;
  final bool isDarkMode; // Koyu mod durumu ekle
  final Function(bool) onDarkModeChanged; // Koyu mod değiştirme fonksiyonu ekle
  
  const KlasorlerWithTheme({
    super.key, 
    required this.onThemeChanged, 
    required this.currentTheme,
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
            ListTile(
              title: Text('settings_theme_title'.tr()),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => ThemeSettingsPage(
                      onThemeChanged: onThemeChanged, 
                      currentTheme: currentTheme
                    )
                  )
                );
              },
            ),
            const Divider(),
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
