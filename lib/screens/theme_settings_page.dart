import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeSettingsPage extends StatelessWidget {
  final Function(AppTheme) onThemeChanged;
  final AppTheme currentTheme;
  
  const ThemeSettingsPage({
    super.key, 
    required this.onThemeChanged, 
    required this.currentTheme
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tema Seçimi')),
      body: ListView(
        children: AppTheme.values.map((theme) {
          return RadioListTile<AppTheme>(
            title: Text(theme.toString().split('.').last),
            value: theme,
            groupValue: currentTheme,
            onChanged: (AppTheme? value) {
              if (value != null) {
                onThemeChanged(value);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
