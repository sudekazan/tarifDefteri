import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
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
    return ShowCaseWidget(
      builder: (context) => Scaffold(
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(child: Text('Ayarlar')), 
              ListTile(
                title: const Text('Tema Seç'),
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
                title: const Text('Koyu Mod'),
                value: isDarkMode,
                onChanged: onDarkModeChanged,
              ),
            ],
          ),
        ),
        body: Klasorler(),
      ),
    );
  }
}
