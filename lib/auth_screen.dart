import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';
import 'services/revenuecat_service.dart';
import 'utils/error_helper.dart';
import 'widgets/giris_parcalari.dart';
import 'widgets/kil/kil.dart';

/// Yalnızca testler için: Apple düğmesinin görünüp görünmeyeceği. `null` ise
/// eskisi gibi iOS ve macOS'ta görünür.
@visibleForTesting
bool? girisAppleGosterilsinMi;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Ekran çizilirken Firebase'e dokunulmasın diye geç kurulur (testte ekran
  // Firebase olmadan açılabilsin).
  late final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final FirebaseService _firebaseService = FirebaseService();
  String _email = '';
  String _password = '';
  bool _isLogin = true;
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitAuthForm() async {
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus();

    if (isValid == null || !isValid) {
      return;
    }
    _formKey.currentState?.save();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Giriş yap
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        // RevenueCat kimliğini Firebase UID'ye bağla (backend Pro kontrolü için gerekli)
        if (userCredential.user != null) {
          await RevenueCatService.loginWithFirebaseUid(userCredential.user!.uid);
        }
        // Yerel verileri Firebase verileriyle akıllıca birleştir
        // Bu sayede giriş yapmadan eklenen tarifler kaybolmaz
        await _firebaseService.mergeLocalAndCloudData();
        if (mounted) {
          // Başarı mesajı göster
          KilBildirim.goster(
            context,
            'auth_login_success'.tr(),
            tur: KilBildirimTuru.basari,
            sure: const Duration(seconds: 2),
          );
          // Kısa bir gecikme ile sayfayı kapat
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } else {
        // Kayıt ol
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        
        // E-posta doğrulama gönder
        if (userCredential.user != null && !userCredential.user!.emailVerified) {
          await userCredential.user!.sendEmailVerification();
        }

        // RevenueCat kimliğini Firebase UID'ye bağla (backend Pro kontrolü için gerekli)
        if (userCredential.user != null) {
          await RevenueCatService.loginWithFirebaseUid(userCredential.user!.uid);
        }

        // Yeni hesap oluşturulduğunda yerel verileri Firebase'e yedekle
        await _firebaseService.backupLocalDataToFirebase();
        if (mounted) {
          // Başarı mesajı göster
          KilBildirim.goster(
            context,
            'auth_register_success_verify'.tr(),
            tur: KilBildirimTuru.basari,
            sure: const Duration(seconds: 2),
          );
          // Kısa bir gecikme ile sayfayı kapat
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = ErrorHelper.authHatasiMesaji(e.code);
        _isLoading = false;
      });
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = ErrorHelper.getFriendlyErrorMessage(e);
        _isLoading = false;
      });
      debugPrint('General Exception: $e');
    }
  }

  Future<void> _handleSocialSignIn(
    Future<UserCredential> Function() signInFn,
  ) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final userCredential = await signInFn();
      if (userCredential.user != null) {
        await RevenueCatService.loginWithFirebaseUid(
          userCredential.user!.uid,
        );
      }
      // Giriş yapmadan eklenen yerel tarifler kaybolmasın diye akıllıca birleştir
      await _firebaseService.mergeLocalAndCloudData();
      if (!mounted) return;
      KilBildirim.goster(
        context,
        'auth_login_success'.tr(),
        tur: KilBildirimTuru.basari,
        sure: const Duration(seconds: 2),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on SignInCancelledException {
      // Kullanıcı kendi iptal etti, hata gösterme
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = ErrorHelper.authHatasiMesaji(e.code));
      debugPrint('FirebaseAuthException (social): ${e.code} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = ErrorHelper.getFriendlyErrorMessage(e));
      debugPrint('Social sign-in error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() =>
      _handleSocialSignIn(_firebaseService.signInWithGoogle);

  Future<void> _signInWithApple() =>
      _handleSocialSignIn(_firebaseService.signInWithApple);

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'auth_reset_password_email_required'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      KilBildirim.goster(
        context,
        'auth_reset_password_success'.tr(),
        tur: KilBildirimTuru.basari,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorHelper.authHatasiMesaji(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorHelper.getFriendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sekmeDegisti(bool giris) {
    if (giris == _isLogin) return;
    setState(() {
      _isLogin = giris;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final apple = girisAppleGosterilsinMi ??
        (!kIsWeb && (Platform.isIOS || Platform.isMacOS));

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: KilYuvarlakDugme(
                        ikon: Theme.of(context).platform == TargetPlatform.iOS
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.arrow_back_rounded,
                        etiket:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                    GirisTanitim(
                      baslik: 'app_title'.tr(),
                      altYazi: _isLogin
                          ? 'auth_subtitle_login'.tr()
                          : 'auth_subtitle_register'.tr(),
                    ),
                    const SizedBox(height: 24),
                    KilKart(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GirisSekmeSecici(
                              girisSecili: _isLogin,
                              girisEtiketi: 'auth_button_login'.tr(),
                              kayitEtiketi: 'auth_button_register'.tr(),
                              onDegisti: _sekmeDegisti,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              key: const ValueKey('email'),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                labelText: 'auth_email_label'.tr(),
                                hintText: 'auth_email_hint'.tr(),
                                prefixIcon:
                                    const Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.contains('@')) {
                                  return 'auth_email_validation'.tr();
                                }
                                return null;
                              },
                              onSaved: (value) => _email = value!.trim(),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              key: const ValueKey('password'),
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'auth_password_label'.tr(),
                                hintText: 'auth_password_hint'.tr(),
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.length < 6) {
                                  return 'auth_password_validation'.tr();
                                }
                                return null;
                              },
                              onSaved: (value) => _password = value!,
                            ),
                            if (_isLogin)
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed:
                                      _isLoading ? null : _resetPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: r.baslik,
                                    minimumSize: const Size(48, 48),
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontSize: 15),
                                  ),
                                  child: Text('auth_forgot_password'.tr()),
                                ),
                              )
                            else
                              const SizedBox(height: 20),
                            if (_errorMessage != null) ...[
                              GirisHataKutusu(mesaj: _errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            if (_isLoading)
                              const GirisBekleme()
                            else
                              KilDugme.birincil(
                                etiket: _isLogin
                                    ? 'auth_button_login'.tr()
                                    : 'auth_button_register'.tr(),
                                buyuk: true,
                                tamGenislik: true,
                                onPressed: _submitAuthForm,
                              ),
                            const SizedBox(height: 16),
                            GirisAyirici(metin: 'auth_divider_or'.tr()),
                            const SizedBox(height: 16),
                            KilDugme.ikincil(
                              etiket: 'auth_continue_with_google'.tr(),
                              ikon: Icons.g_mobiledata_rounded,
                              tamGenislik: true,
                              onPressed: _isLoading ? null : _signInWithGoogle,
                            ),
                            if (apple) ...[
                              const SizedBox(height: 8),
                              KilDugme.ikincil(
                                etiket: 'auth_continue_with_apple'.tr(),
                                ikon: Icons.apple,
                                tamGenislik: true,
                                onPressed:
                                    _isLoading ? null : _signInWithApple,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
