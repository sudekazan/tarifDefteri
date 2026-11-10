import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../auth_screen.dart';
import '../services/ad_service.dart';
import '../services/firebase_service.dart';
import '../services/revenuecat_service.dart';
import '../services/review_service.dart';
import '../utils/error_helper.dart';
import 'premium_sayfasi.dart';
import '../widgets/giris_parcalari.dart' show GirisBekleme;
import '../widgets/kil/kil.dart';
import '../widgets/profil_parcalari.dart';

class ProfilSayfasi extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onDarkModeChanged;

  /// Kabukta Profil sekmesi yeniden seçilince haber verir; Pro durumu başka
  /// bir ekranda değişmiş olabileceği için sayfa yeniden çizilir.
  final Listenable? gorunduSinyali;

  const ProfilSayfasi({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    this.gorunduSinyali,
  });

  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  static const String _androidPackageName = "com.sudekazan.tarif_defteri_yeni";

  String appVersion = '1.0.0';
  String buildNumber = '1';
  late final FirebaseService _firebaseService = FirebaseService();
  User? _currentUser;

  /// AB'deki kullanıcılar için reklam onayını değiştirme satırı gösterilsin mi?
  bool _gizlilikSecenekleriGerekli = false;

  @override
  void initState() {
    super.initState();
    widget.gorunduSinyali?.addListener(_sekmeGorundu);
    _getAppInfo();
    _getCurrentUser();
    AdService.gizlilikSecenekleriGerekli().then((gerekli) {
      if (mounted && gerekli) setState(() => _gizlilikSecenekleriGerekli = true);
    });
    // Auth durumu değişikliklerini dinle
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.gorunduSinyali?.removeListener(_sekmeGorundu);
    super.dispose();
  }

  void _sekmeGorundu() {
    if (mounted) setState(() {});
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

    KilAltSayfa.goster<void>(
      context,
      baslik: 'settings_language_title'.tr(),
      builder: (sayfaContext) => KilSecimListesi(
        secenekler: [
          for (final lang in languages)
            KilSecenek(
              ikon: Icons.language_rounded,
              emoji: _languageFlags[lang['code']],
              etiket: lang['key']!.tr(),
              secili: context.locale.languageCode == lang['code'],
              onTap: () {
                context.setLocale(Locale(lang['code']!));
                Navigator.pop(sayfaContext);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    try {
      // Kullanıcı manuel olarak değerlendirmek istediği için otomatik sormayı tamamen kapatıyoruz.
      await ReviewService.markAsRated();

      final InAppReview inAppReview = InAppReview.instance;
      
      // Önce uygulama içi (native pop-up) değerlendirme göster
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // Native pop-up desteklenmiyorsa mağaza sayfasına yönlendir
        // iOS'ta openStoreListing bundle ID'yi otomatik algılar
        // Android'te packageName zorunlu
        const String appleId = "6759447259"; // App Store Connect → App Information → Apple ID

        try {
          await inAppReview.openStoreListing(
            appStoreId: appleId,         // iOS için
            microsoftStoreId: null,
          );
        } catch (_) {
          // openStoreListing başarısız olursa tarayıcıda aç
          final Uri url = Platform.isAndroid
              ? Uri.parse("https://play.google.com/store/apps/details?id=$_androidPackageName")
              : Uri.parse("https://apps.apple.com/app/id$appleId");
          
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        KilBildirim.goster(
          context,
          ErrorHelper.getFriendlyErrorMessage(e),
          tur: KilBildirimTuru.hata,
        );
      }
    }
  }

  /// Hesap silme işlemini başlatır. Veriler silinmeden ÖNCE kimlik, kullanıcının
  /// giriş yöntemine göre (şifre / Google / Apple) tazelenir. Eskiden önce
  /// veriler siliniyor, sonra şifre isteniyordu: Google/Apple kullanıcılarının
  /// şifresi olmadığı için verileri gitmiş ama hesabı duran bir durumda
  /// takılıp kalıyorlardı.
  Future<void> _performAccountDeletion() async {
    final dogrulandi = await _kimligiTazele();
    if (!dogrulandi || !mounted) return;

    KilDiyalog.beklemeGoster(context);

    try {
      await _firebaseService.deleteUserAccount();
      if (mounted) Navigator.pop(context); // Loading kapat
      _showAccountDeletedSnackBar();
    } on ReauthRequiredException {
      if (mounted) Navigator.pop(context); // Loading kapat
      _showAccountDeletionErrorText('settings_delete_account_retry'.tr());
    } catch (e) {
      if (mounted) Navigator.pop(context); // Loading kapat
      _showAccountDeletionErrorSnackBar(e);
    }
  }

  /// Kimliği giriş yöntemine göre tazeler. Kullanıcı vazgeçerse ya da
  /// doğrulama başarısız olursa false döner ve hiçbir veri silinmez.
  Future<bool> _kimligiTazele() async {
    try {
      switch (_firebaseService.reauthYontemi) {
        case ReauthYontemi.sifre:
          final sonuc = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _SifreDogrulamaDialog(firebaseService: _firebaseService),
          );
          return sonuc == true;
        case ReauthYontemi.google:
          await _firebaseService.reauthenticateWithGoogle();
          return true;
        case ReauthYontemi.apple:
          await _firebaseService.reauthenticateWithApple();
          return true;
        case null:
          // Bilinmeyen yöntem: silme denenir; gerekirse ReauthRequired yakalanır.
          return true;
      }
    } on SignInCancelledException {
      return false;
    } on ReauthRequiredException {
      _showAccountDeletionErrorText('settings_delete_account_retry'.tr());
      return false;
    } on FirebaseAuthException catch (e) {
      _showAccountDeletionErrorText(ErrorHelper.authHatasiMesaji(e.code));
      return false;
    } catch (e) {
      _showAccountDeletionErrorSnackBar(e);
      return false;
    }
  }

  void _showAccountDeletedSnackBar() {
    if (!mounted) return;
    KilBildirim.goster(
      context,
      'settings_delete_account_success'.tr(),
      tur: KilBildirimTuru.basari,
      sure: const Duration(seconds: 3),
    );
  }

  void _showAccountDeletionErrorSnackBar(Object e) {
    _showAccountDeletionErrorText(
      '${'settings_delete_account_error_prefix'.tr()}${ErrorHelper.getFriendlyErrorMessage(e)}',
    );
  }

  void _showAccountDeletionErrorText(String mesaj) {
    if (!mounted) return;
    KilBildirim.goster(
      context,
      mesaj,
      tur: KilBildirimTuru.hata,
      sure: const Duration(seconds: 5),
    );
  }

  Future<void> _manageSubscription() async {
    final String url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions?package=$_androidPackageName';
    await _launchUrl(url);
  }

  Future<void> _restorePurchases() async {
    KilDiyalog.beklemeGoster(context);

    final success = await RevenueCatService.restorePurchases();

    if (!mounted) return;
    Navigator.pop(context); // Loading kapat
    setState(() {});

    KilBildirim.goster(
      context,
      success ? 'premium_restored'.tr() : 'premium_restore_failed'.tr(),
      tur: success ? KilBildirimTuru.basari : KilBildirimTuru.bilgi,
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        KilBildirim.goster(
          context,
          ErrorHelper.getFriendlyErrorMessage(e),
          tur: KilBildirimTuru.hata,
        );
      }
    }
  }

  Future<void> _cikisYap() async {
    final shouldLogout = await KilDiyalog.onayIste(
      context,
      ikon: Icons.logout_rounded,
      tehlikeli: true,
      baslik: 'settings_logout_confirm_title'.tr(),
      mesaj: 'settings_logout_confirm_content'.tr(),
      onayEtiketi: 'settings_logout'.tr(),
      vazgecEtiketi: 'settings_logout_cancel'.tr(),
    );

    if (shouldLogout == true) {
      if (!mounted) return;
      // Çıkış cihazdaki tarifleri siler; önce hepsinin bulutta olduğundan
      // emin ol. Yedeklenemiyorsa (ör. internet yok) kullanıcı karar verir.
      var beklemeAcik = true;
      KilDiyalog.beklemeGoster(context).then((_) => beklemeAcik = false);
      final yedeklendi = await _firebaseService.cikisOncesiYedekle();
      if (!mounted) return;
      // Android geri tuşuyla kapatılmış olabilir; yalnızca açıksa kapat.
      if (beklemeAcik) Navigator.of(context, rootNavigator: true).pop();
      if (!yedeklendi) {
        final yineDeCik = await KilDiyalog.onayIste(
          context,
          ikon: Icons.warning_amber_rounded,
          tehlikeli: true,
          baslik: 'settings_logout_unsynced_title'.tr(),
          mesaj: 'settings_logout_unsynced_content'.tr(),
          onayEtiketi: 'settings_logout_anyway'.tr(),
          vazgecEtiketi: 'settings_logout_cancel'.tr(),
        );
        if (yineDeCik != true) return;
      }
      await _firebaseService.signOut();
      if (mounted) {
        KilBildirim.goster(
          context,
          'settings_logout_success'.tr(),
          tur: KilBildirimTuru.basari,
        );
      }
    }
  }

  Future<void> _yedekle() async {
    // Çıkıştaki doğrulamalı yedek kullanılır: veriler sunucuya gerçekten
    // ulaşmadıysa (ör. internet yok) "yedeklendi" denmez.
    var beklemeAcik = true;
    KilDiyalog.beklemeGoster(context).then((_) => beklemeAcik = false);
    final yedeklendi = await _firebaseService.cikisOncesiYedekle();
    if (!mounted) return;
    // Android geri tuşuyla kapatılmış olabilir; yalnızca açıksa kapat.
    if (beklemeAcik) Navigator.of(context, rootNavigator: true).pop();
    KilBildirim.goster(
      context,
      (yedeklendi ? 'settings_backup_success' : 'settings_backup_error').tr(),
      tur: yedeklendi ? KilBildirimTuru.basari : KilBildirimTuru.hata,
    );
  }

  Future<void> _hesapSilmeyiSor() async {
    final shouldDelete = await KilDiyalog.onayIste(
      context,
      ikon: Icons.warning_amber_rounded,
      tehlikeli: true,
      baslik: 'settings_delete_account_dialog_title'.tr(),
      icerik: const HesapSilmeUyarisi(),
      onayEtiketi: 'settings_delete_account_button'.tr(),
      vazgecEtiketi: 'settings_logout_cancel'.tr(),
    );

    if (shouldDelete == true) {
      await _performAccountDeletion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kullanici = _currentUser;
    return ProfilGorunumu(
      hesap: kullanici == null
          ? null
          : ProfilHesap(
              ad: kullanici.displayName,
              eposta: kullanici.email,
              yontem: _firebaseService.reauthYontemi,
            ),
      proKullanici: RevenueCatService.isProUser,
      koyuMod: widget.isDarkMode,
      dilAdi: _getCurrentLanguageName(context),
      surum: appVersion,
      onKoyuMod: widget.onDarkModeChanged,
      onDil: () => _showLanguageBottomSheet(context),
      onPremium: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumSayfasi(source: 'settings')),
        );
        setState(() {});
      },
      onAbonelikYonet: _manageSubscription,
      onGeriYukle: _restorePurchases,
      onGiris: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        _getCurrentUser();
      },
      onYedekle: _yedekle,
      onCikis: _cikisYap,
      onHesapSil: _hesapSilmeyiSor,
      onDegerlendir: _rateApp,
      onGizlilik: () => _launchUrl('https://sudekazan.github.io/tarifDefteri/privacy.html'),
      onKosullar: () => _launchUrl('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
      onGizlilikSecenekleri:
          _gizlilikSecenekleriGerekli ? AdService.gizlilikSecenekleriniGoster : null,
    );
  }
}

/// Hesap silme onayının içeriği: uyarı başlığı ve silinecekler listesi.
class HesapSilmeUyarisi extends StatelessWidget {
  const HesapSilmeUyarisi({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;
    final govde = yazi.bodyLarge?.copyWith(color: r.anaYazi, height: 1.4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: r.hataZemin,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'settings_delete_account_warning_title'.tr(),
            style: yazi.titleMedium?.copyWith(color: r.hataZeminYazi),
          ),
        ),
        const SizedBox(height: 12),
        Text('settings_delete_account_when_delete'.tr(), style: govde),
        const SizedBox(height: 8),
        Text('settings_delete_account_item_recipes'.tr(), style: govde),
        Text('settings_delete_account_item_folders'.tr(), style: govde),
        Text('settings_delete_account_item_data'.tr(), style: govde),
        Text('settings_delete_account_item_cannot_undo'.tr(), style: govde),
        const SizedBox(height: 12),
        Text(
          'settings_delete_account_confirm_question'.tr(),
          style: yazi.titleMedium?.copyWith(color: r.anaYazi),
        ),
      ],
    );
  }
}

/// Hesap silmeden önce şifreyle kimlik doğrulaması isteyen dialog. Doğrulama
/// başarılıysa `true` ile kapanır. Controller'ı kendi yaşam döngüsünde yönetir
/// (dialog kapanış animasyonu sürerken dispose edilmiş controller kullanılmasın).
class _SifreDogrulamaDialog extends StatefulWidget {
  final FirebaseService firebaseService;

  const _SifreDogrulamaDialog({required this.firebaseService});

  @override
  State<_SifreDogrulamaDialog> createState() => _SifreDogrulamaDialogState();
}

class _SifreDogrulamaDialogState extends State<_SifreDogrulamaDialog> {
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _dogrula() async {
    if (_passwordController.text.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await widget.firebaseService.reauthenticateWithPassword(_passwordController.text);
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        // Burada e-posta zaten belli; "e-posta veya şifre hatalı" yerine
        // doğrudan "şifre hatalı" de.
        _errorText = e.code == 'invalid-credential'
            ? 'auth_error_wrong_password'.tr()
            : ErrorHelper.authHatasiMesaji(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = ErrorHelper.getFriendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KilDiyalog(
      ikon: Icons.lock_outline_rounded,
      tur: KilDiyalogTuru.tehlike,
      baslik: 'settings_reauth_dialog_title'.tr(),
      mesaj: 'settings_reauth_dialog_message'.tr(),
      icerik: TextField(
        controller: _passwordController,
        obscureText: true,
        autofocus: true,
        onSubmitted: (_) => _isSubmitting ? null : _dogrula(),
        decoration: InputDecoration(
          labelText: 'auth_password_label'.tr(),
          errorText: _errorText,
          errorMaxLines: 3,
        ),
      ),
      eylemler: [
        if (_isSubmitting)
          const GirisBekleme()
        else
          KilDugme.hata(
            etiket: 'settings_reauth_confirm_button'.tr(),
            tamGenislik: true,
            onPressed: _dogrula,
          ),
        KilDiyalogMetinDugmesi(
          etiket: 'settings_logout_cancel'.tr(),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}
