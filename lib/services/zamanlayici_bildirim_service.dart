import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Yemek modu zamanlayıcısı bitince uygulama arka plandayken bildirim gösterir.
/// Tek bildirim kimliği kullanılır; ekranda tek zamanlayıcı var.
class ZamanlayiciBildirimService {
  ZamanlayiciBildirimService._();

  static const int _kimlik = 4101;
  static final _eklenti = FlutterLocalNotificationsPlugin();
  static bool _hazir = false;

  static Future<void> _hazirla() async {
    if (_hazir) return;
    await _eklenti.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // İzin, ilk zamanlayıcı başlatılınca istenir; açılışta değil.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _hazir = true;
  }

  static Future<void> _izinIste() async {
    await _eklenti
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _eklenti
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  }

  /// [bitis] anında bildirim kurar. Hata olursa sessizce geçer; uygulama
  /// içi uyarı yine çalışır.
  static Future<void> kur({
    required DateTime bitis,
    required String baslik,
    required String metin,
    required String kanalAdi,
  }) async {
    try {
      await _hazirla();
      await _izinIste();
      await _eklenti.zonedSchedule(
        id: _kimlik,
        scheduledDate: tz.TZDateTime.from(bitis.toUtc(), tz.UTC),
        title: baslik,
        body: metin,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'yemek_zamanlayici',
            kanalAdi,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(presentSound: true),
        ),
        // Tam zamanlı alarm izni (Play politikası) istememek için: birkaç
        // saniye gecikebilir.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Zamanlayıcı bildirimi kurulamadı: $e');
    }
  }

  static Future<void> iptal() async {
    try {
      if (!_hazir) return;
      await _eklenti.cancel(id: _kimlik);
    } catch (e) {
      debugPrint('Zamanlayıcı bildirimi iptal edilemedi: $e');
    }
  }
}
