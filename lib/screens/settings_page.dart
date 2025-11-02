import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  final Function(AppTheme) onThemeChanged;
  final AppTheme currentTheme;
  final bool isDarkMode;
  final Function(bool) onDarkModeChanged;
  
  const SettingsPage({
    super.key, 
    required this.onThemeChanged, 
    required this.currentTheme, 
    required this.isDarkMode, 
    required this.onDarkModeChanged
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String appVersion = '1.0.0';
  String buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // Hata durumunda varsayılan değerleri kullan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Tema Seçimi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.values.map((theme) {
                final color = appThemeColors[theme]!;
                final isSelected = theme == widget.currentTheme;
                return GestureDetector(
                  onTap: () => widget.onThemeChanged(theme),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check, color: Colors.white, size: 22),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Koyu Mod'),
            value: widget.isDarkMode,
            onChanged: widget.onDarkModeChanged,
          ),
          const Divider(),
          // Uygulama Bilgileri
          const ListTile(
            title: Text('Uygulama Bilgileri', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versiyon'),
            subtitle: Text('$appVersion ($buildNumber)'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Geliştirici'),
            subtitle: const Text('Sude Kazan'),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('İletişim'),
            subtitle: const Text('sudekazan1907@gmail.com'),
          ),
          const SizedBox(height: 20),
          // Alt kısımda uygulama adı ve versiyon
          Center(
            child: Column(
              children: [
                Text(
                  'Tarif Defteri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versiyon $appVersion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2024 Sude Kazan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
