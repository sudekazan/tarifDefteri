import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/utils/error_helper.dart';

// Testte çeviri dosyası yüklü olmadığı için `.tr()` anahtarın kendisini
// döndürür; bu sayede hangi metnin seçildiğini anahtar üzerinden doğrularız.
void main() {
  test('kullanıcı için yazılmış hata mesajı olduğu gibi gösterilir', () {
    expect(ErrorHelper.getFriendlyErrorMessage(const KullaniciHatasi('Hazır mesaj')), 'Hazır mesaj');
  });

  test('tanınmayan SDK hatası ham metin yerine genel mesaja çevrilir', () {
    final mesaj = ErrorHelper.getFriendlyErrorMessage(
      PlatformException(code: 'sign_in_failed', message: 'com.google.GIDSignIn error -4'),
    );
    expect(mesaj, 'error_technical');
  });

  test('bozuk JSON hatası kullanıcıya gösterilmez', () {
    expect(ErrorHelper.getFriendlyErrorMessage(const FormatException('Unexpected character')), 'error_technical');
  });

  test('ağ hatası internet mesajına çevrilir', () {
    expect(ErrorHelper.getFriendlyErrorMessage(Exception('SocketException: Failed host lookup')), 'error_no_internet');
  });

  test('bilinen Firebase Auth kodu kendi mesajına çevrilir', () {
    expect(ErrorHelper.getFriendlyErrorMessage(FirebaseAuthException(code: 'user-disabled')), 'auth_error_user_disabled');
  });

  test('bilinmeyen Firebase Auth kodu kullanıcıya gösterilmez', () {
    expect(ErrorHelper.authHatasiMesaji('internal-error'), 'auth_error_generic');
  });
}
