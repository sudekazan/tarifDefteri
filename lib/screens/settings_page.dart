import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../theme/app_theme.dart';
import '../auth_screen.dart';
import '../services/firebase_service.dart';
import '../widgets/banner_ad_widget.dart';

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
  final FirebaseService _firebaseService = FirebaseService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getAppInfo();
    _getCurrentUser();
    // Auth durumu değişikliklerini dinle
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  void _getCurrentUser() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
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

  // Dil bayrakları ve isimleri
  final Map<String, String> _languageFlags = {
    'tr': '🇹🇷',
    'en': '🇬🇧',
    'de': '🇩🇪',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'pt': '🇧🇷',
  };

  String _getCurrentLanguageName(BuildContext context) {
    final langCode = context.locale.languageCode;
    final names = {
      'tr': 'settings_language_turkish'.tr(),
      'en': 'settings_language_english'.tr(),
      'de': 'settings_language_german'.tr(),
      'es': 'settings_language_spanish'.tr(),
      'fr': 'settings_language_french'.tr(),
      'pt': 'settings_language_portuguese'.tr(),
    };
    return '${_languageFlags[langCode] ?? ''} ${names[langCode] ?? langCode}';
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final languages = [
      {'code': 'tr', 'key': 'settings_language_turkish'},
      {'code': 'en', 'key': 'settings_language_english'},
      {'code': 'de', 'key': 'settings_language_german'},
      {'code': 'es', 'key': 'settings_language_spanish'},
      {'code': 'fr', 'key': 'settings_language_french'},
      {'code': 'pt', 'key': 'settings_language_portuguese'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'settings_language_title'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...languages.map((lang) {
                  final code = lang['code']!;
                  final isSelected = context.locale.languageCode == code;
                  return ListTile(
                    leading: Text(
                      _languageFlags[code] ?? '',
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      lang['key']!.tr(),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      context.setLocale(Locale(code));
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rateApp() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      
      // Önce uygulama içi (native pop-up) değerlendirme göster
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // Native pop-up desteklenmiyorsa mağaza sayfasına yönlendir
        // iOS'ta openStoreListing bundle ID'yi otomatik algılar
        // Android'te packageName zorunlu
        const String androidPackageName = "com.sudekazan.tarif_defteri_yeni";
        const String appleId = "6759447259"; // App Store Connect → App Information → Apple ID
        
        try {
          await inAppReview.openStoreListing(
            appStoreId: appleId,         // iOS için
            microsoftStoreId: null,
          );
        } catch (_) {
          // openStoreListing başarısız olursa tarayıcıda aç
          final Uri url = Platform.isAndroid
              ? Uri.parse("https://play.google.com/store/apps/details?id=$androidPackageName")
              : Uri.parse("https://apps.apple.com/app/id$appleId");
          
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr())),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          children: [
          ListTile(
            title: Text(
              'settings_theme_title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
            title: Text('settings_dark_mode'.tr()),
            value: widget.isDarkMode,
            onChanged: widget.onDarkModeChanged,
          ),
          const Divider(),
          // Dil Seçimi
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('settings_language_title'.tr()),
            subtitle: Text(_getCurrentLanguageName(context)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageBottomSheet(context),
          ),
          const Divider(),
          // Firebase / Hesap Yönetimi
          ListTile(
            title: Text(
              'settings_account_title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (_currentUser != null) ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.green),
              ),
              title: Text('settings_logged_in'.tr()),
              subtitle: Text(
                _currentUser?.email ?? 'settings_user_fallback'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'settings_logout'.tr(),
                onPressed: () async {
                  // Onay dialogu göster
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('settings_logout_confirm_title'.tr()),
                      content: Text('settings_logout_confirm_content'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('settings_logout_cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'settings_logout'.tr(),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldLogout == true) {
                    await _firebaseService.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              Text('settings_logout_success'.tr()),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: Text('settings_backup'.tr()),
              subtitle: Text('settings_backup_subtitle'.tr()),
              onTap: () async {
                // TODO: Yedekleme işlemi eklenecek
                try {
                  await _firebaseService.backupLocalDataToFirebase();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('settings_backup_success'.tr())),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('settings_backup_error'.tr())),
                    );
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              title: Text(
                'settings_delete_account'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              subtitle: Text('settings_delete_account_subtitle'.tr()),
              onTap: () async {
                // Hesap silme onayı
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning, color: Colors.red, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'settings_delete_account_dialog_title'.tr(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'settings_delete_account_warning_title'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Text('settings_delete_account_when_delete'.tr()),
                        const SizedBox(height: 8),
                        Text('settings_delete_account_item_recipes'.tr()),
                        Text('settings_delete_account_item_folders'.tr()),
                        Text('settings_delete_account_item_data'.tr()),
                        Text('settings_delete_account_item_cannot_undo'.tr()),
                        const SizedBox(height: 12),
                        Text(
                          'settings_delete_account_confirm_question'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('settings_logout_cancel'.tr()),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(
                          'settings_delete_account_button'.tr(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  try {
                    // Loading göster
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    // Hesabı sil
                    await _firebaseService.deleteUserAccount();

                    // Loading kapat
                    if (mounted) Navigator.pop(context);

                    // Başarı mesajı
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              Text('settings_delete_account_success'.tr()),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    // Loading kapat
                    if (mounted) Navigator.pop(context);

                    // Hata mesajı
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('${'settings_delete_account_error_prefix'.tr()}${e.toString()}'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: Text('settings_login_register'.tr()),
              subtitle: Text('settings_login_subtitle'.tr()),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
                _getCurrentUser();
              },
            ),
          ],
          const Divider(),
          // Uygulama Bilgileri
          ListTile(
            title: Text(
              'settings_app_info_title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('settings_version'.tr()),
            subtitle: Text(appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('settings_developer'.tr()),
            subtitle: const Text('Sude Kazan'),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text('settings_contact'.tr()),
            subtitle: const Text('sudekazan1907@gmail.com'),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline, color: Colors.amber),
            title: Text('settings_rate_app'.tr()),
            subtitle: Text('settings_rate_app_subtitle'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _rateApp,
          ),
          const SizedBox(height: 20),
          // Alt kısımda uygulama adı ve versiyon
          Center(
            child: Column(
              children: [
                Text(
                  'settings_footer_app_name'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'settings_footer_version_prefix'.tr()} $appVersion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'settings_footer_copyright'.tr(),
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
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
