import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Mesajı doğrudan kullanıcıya gösterilmek üzere yazılmış (çevrilmiş) hata.
/// [ErrorHelper] yalnızca bu türün mesajını olduğu gibi gösterir.
class KullaniciHatasi implements Exception {
  final String mesaj;

  const KullaniciHatasi(this.mesaj);

  @override
  String toString() => mesaj;
}

class ErrorHelper {
  /// Herhangi bir hatayı kullanıcıya gösterilebilir, çevrilmiş bir metne
  /// çevirir. Ham hata metni (İngilizce SDK mesajları, hata kodları, sınıf
  /// adları) kullanıcıya hiçbir zaman gösterilmez; geliştirici için konsola
  /// yazılır. Eskiden tanınmayan hatalar olduğu gibi gösteriliyordu
  /// (ör. "GoogleSignInException(code ...providerConfigurationError...)").
  static String getFriendlyErrorMessage(Object? error) {
    if (error is KullaniciHatasi) return error.mesaj;
    if (error is FirebaseAuthException) return authHatasiMesaji(error.code);

    final message = error.toString();
    debugPrint('Kullanıcıya genel mesaj gösterilen hata: $message');

    if (message.contains("UnknownHostException") ||
        message.contains("SocketException") ||
        message.contains("ClientException") ||
        message.contains("Network is unreachable") ||
        message.contains("No address associated with hostname") ||
        message.contains("HandshakeException") ||
        message.contains("Connection refused") ||
        message.contains("network-request-failed")) {
      return 'error_no_internet'.tr();
    }

    if (message.contains("TimeoutException") || message.contains("timed out") || message.contains("deadline-exceeded") || message.contains("deadline_exceeded")) {
      return 'error_timeout'.tr();
    }

    if (message.contains("UNAVAILABLE") || message.contains("unavailable") || message.contains("1 out of 2 underlying tasks failed")) {
      return 'error_server_connection'.tr();
    }

    return 'error_technical'.tr();
  }

  /// Firebase Auth hata kodunu kullanıcı dostu metne çevirir. Bilinmeyen
  /// kodlarda kodu göstermek yerine genel bir mesaj verir.
  static String authHatasiMesaji(String code) {
    debugPrint('FirebaseAuth hata kodu: $code');
    return switch (code) {
      'weak-password' => 'auth_error_weak_password'.tr(),
      'email-already-in-use' => 'auth_error_email_in_use'.tr(),
      'user-not-found' => 'auth_error_user_not_found'.tr(),
      'wrong-password' => 'auth_error_wrong_password'.tr(),
      'invalid-credential' || 'invalid-login-credentials' => 'auth_error_invalid_credential'.tr(),
      'invalid-email' => 'auth_error_invalid_email'.tr(),
      'user-disabled' => 'auth_error_user_disabled'.tr(),
      'network-request-failed' => 'auth_error_network'.tr(),
      'too-many-requests' => 'auth_error_too_many_requests'.tr(),
      'operation-not-allowed' => 'auth_error_operation_not_allowed'.tr(),
      'account-exists-with-different-credential' => 'auth_error_account_exists_different_credential'.tr(),
      'user-mismatch' => 'settings_reauth_user_mismatch'.tr(),
      'user-token-expired' || 'invalid-user-token' || 'requires-recent-login' => 'ai_error_session'.tr(),
      _ => 'auth_error_generic'.tr(),
    };
  }
}
