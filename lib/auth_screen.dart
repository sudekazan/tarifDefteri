import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Geçici olarak kaldırıldı

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // final _auth = FirebaseAuth.instance; // Geçici olarak kaldırıldı
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLogin = true;
  String? _errorMessage;

  void _submitAuthForm() async {
    final isValid = _formKey.currentState?.validate();
    FocusScope.of(context).unfocus();

    if (isValid == null || !isValid) {
      return;
    }
    _formKey.currentState?.save();

    setState(() {
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Giriş yap - geçici olarak devre dışı
        print('Giriş yapılıyor: $_email');
        // TODO: Firebase entegrasyonu eklenecek
      } else {
        // Kayıt ol - geçici olarak devre dışı
        print('Kayıt yapılıyor: $_email');
        // TODO: Firebase entegrasyonu eklenecek
      }
    } catch (e) {
      // Genel hataları yakala
      setState(() {
        _errorMessage = 'Bilinmeyen bir hata oluştu.';
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('email'),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-posta Adresi'),
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Lütfen geçerli bir e-posta adresi girin.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value!;
                    },
                  ),
                  TextFormField(
                    key: const ValueKey('password'),
                    obscureText: true, // Şifreyi gizler
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Şifre en az 6 karakter olmalıdır.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null) // Hata mesajını göster
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _submitAuthForm,
                    child: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin; // Giriş ve kayıt ekranını değiştir
                        _errorMessage = null; // Ekran değişince hata mesajını temizle
                      });
                    },
                    child: Text(_isLogin ? 'Yeni Hesap Oluştur' : 'Zaten hesabım var'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}