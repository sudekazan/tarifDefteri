import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
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
        await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        // Yerel verileri Firebase verileriyle akıllıca birleştir
        // Bu sayede giriş yapmadan eklenen tarifler kaybolmaz
        await _firebaseService.mergeLocalAndCloudData();
        if (mounted) {
          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('auth_login_success'.tr()),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
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

        // Yeni hesap oluşturulduğunda yerel verileri Firebase'e yedekle
        await _firebaseService.backupLocalDataToFirebase();
        if (mounted) {
          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('auth_register_success_verify'.tr())),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
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
      
      String message = 'auth_error_generic'.tr();
      if (e.code == 'weak-password') {
        message = 'auth_error_weak_password'.tr();
      } else if (e.code == 'email-already-in-use') {
        message = 'auth_error_email_in_use'.tr();
      } else if (e.code == 'user-not-found') {
        message = 'auth_error_user_not_found'.tr();
      } else if (e.code == 'wrong-password') {
        message = 'auth_error_wrong_password'.tr();
      } else if (e.code == 'invalid-email') {
        message = 'auth_error_invalid_email'.tr();
      } else if (e.code == 'invalid-credential') {
        message = 'auth_error_invalid_credential'.tr();
      } else if (e.code == 'network-request-failed') {
        message = 'auth_error_network'.tr();
      } else if (e.code == 'operation-not-allowed') {
        message = 'auth_error_operation_not_allowed'.tr();
      } else if (e.code == 'too-many-requests') {
        message = 'auth_error_too_many_requests'.tr();
      } else {
        message = '${'auth_error_code_prefix'.tr()}${e.code}';
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
      print('FirebaseAuthException: ${e.code} - ${e.message}');
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = '${'auth_error_unexpected_prefix'.tr()}${e.toString()}';
        _isLoading = false;
      });
      print('General Exception: $e');
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth_reset_password_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'auth_error_user_not_found'.tr();
        } else {
          _errorMessage = e.message ?? 'Bir hata oluştu.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Bilinmeyen bir hata oluştu.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Icon Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // App Title & Tagline
                Text(
                  'app_title'.tr(),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'auth_subtitle_login'.tr()
                      : 'auth_subtitle_register'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 28),

                // Form Container
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1D2B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C3044)
                          : Colors.grey.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Pill Switcher (Giriş Yap / Kayıt Ol)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF121420)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (!_isLogin) {
                                      setState(() {
                                        _isLogin = true;
                                        _errorMessage = null;
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _isLogin
                                          ? (isDark ? primaryColor : primaryColor)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _isLogin
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      'auth_button_login'.tr(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _isLogin
                                            ? Colors.white
                                            : (isDark ? Colors.white60 : Colors.black60),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_isLogin) {
                                      setState(() {
                                        _isLogin = false;
                                        _errorMessage = null;
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_isLogin
                                          ? primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: !_isLogin
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      'auth_button_register'.tr(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: !_isLogin
                                            ? Colors.white
                                            : (isDark ? Colors.white60 : Colors.black60),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        TextFormField(
                          key: const ValueKey('email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'auth_email_label'.tr(),
                            hintText: 'auth_email_hint'.tr(),
                            prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty || !value.contains('@')) {
                              return 'auth_email_validation'.tr();
                            }
                            return null;
                          },
                          onSaved: (value) => _email = value!.trim(),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          key: const ValueKey('password'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'auth_password_label'.tr(),
                            hintText: 'auth_password_hint'.tr(),
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDark ? Colors.white54 : Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty || value.length < 6) {
                              return 'auth_password_validation'.tr();
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value!,
                        ),

                        if (_isLogin) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              child: Text(
                                'auth_forgot_password'.tr(),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 20),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Main Auth Submit Button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitAuthForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _isLogin
                                        ? 'auth_button_login'.tr()
                                        : 'auth_button_register'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}