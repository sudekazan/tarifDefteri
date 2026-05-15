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
      return "İnternet bağlantısı yok veya sunucuya ulaşılamıyor. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.";
    }
    
    // Zaman Aşımı
    if (message.contains("TimeoutException") || message.contains("timed out") || message.contains("deadline_exceeded")) {
      return "İşlem zaman aşımına uğradı. Sunucu yanıt vermiyor, lütfen daha sonra tekrar deneyin.";
    }

    // Firestore / Firebase Hataları
    if (message.contains("ExecutionException")) {
       if (message.contains("1 out of 2 underlying tasks failed") || message.contains("UNAVAILABLE")) {
         return "Sunucuya bağlanırken bir hata oluştu. Lütfen internet bağlantınızı kontrol edin.";
       }
       return "Beklenmedik bir sunucu hatası oluştu. Lütfen tekrar deneyin.";
    }
    
    // Temizleme işlemi
    if (message.contains("Exception:")) {
      message = message.replaceAll("Exception:", "").trim();
    }
    
    // Eğer mesaj çok teknikse (paket adı içeriyorsa) genel bir mesaj göster
    if (message.contains("java.") || message.contains("com.google.") || message.contains("io.grpc.")) {
      return "Teknik bir hata oluştu. Lütfen geliştirici ile iletişime geçin.";
    }
    
    return message;
  }
}
