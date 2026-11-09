import 'package:easy_localization/easy_localization.dart';

class ErrorHelper {
  static String getFriendlyErrorMessage(dynamic error) {
    String message = error.toString();

    // İnternet / DNS Hataları
    if (message.contains("UnknownHostException") ||
        message.contains("SocketException") ||
        message.contains("Network is unreachable") ||
        message.contains("No address associated with hostname") ||
        message.contains("HandshakeException") ||
        message.contains("Connection refused")) {
      return 'error_no_internet'.tr();
    }

    // Zaman Aşımı
    if (message.contains("TimeoutException") || message.contains("timed out") || message.contains("deadline_exceeded")) {
      return 'error_timeout'.tr();
    }

    // Firestore / Firebase Hataları
    if (message.contains("ExecutionException")) {
       if (message.contains("1 out of 2 underlying tasks failed") || message.contains("UNAVAILABLE")) {
         return 'error_server_connection'.tr();
       }
       return 'error_server_unexpected'.tr();
    }

    // Temizleme işlemi
    if (message.contains("Exception:")) {
      message = message.replaceAll("Exception:", "").trim();
    }

    // Eğer mesaj çok teknikse (paket adı içeriyorsa) genel bir mesaj göster
    if (message.contains("java.") || message.contains("com.google.") || message.contains("io.grpc.")) {
      return 'error_technical'.tr();
    }

    return message;
  }
}
