/// Yemek modundaki tek zamanlayıcının durumu. Ekrandan bağımsız, saf Dart;
/// kalan süre bitiş anından hesaplanır, böylece uygulama arka plandan
/// dönünce de doğru gösterilir.
enum ZamanlayiciDurumu { bos, calisiyor, duraklatildi, bitti }

class YemekZamanlayici {
  YemekZamanlayici({DateTime Function()? saat}) : _saat = saat ?? DateTime.now;

  final DateTime Function() _saat;

  ZamanlayiciDurumu _durum = ZamanlayiciDurumu.bos;
  DateTime? _bitis;
  Duration _duraklatilanKalan = Duration.zero;

  ZamanlayiciDurumu get durum => _durum;
  DateTime? get bitis => _durum == ZamanlayiciDurumu.calisiyor ? _bitis : null;

  Duration get kalan => switch (_durum) {
    ZamanlayiciDurumu.bos || ZamanlayiciDurumu.bitti => Duration.zero,
    ZamanlayiciDurumu.duraklatildi => _duraklatilanKalan,
    ZamanlayiciDurumu.calisiyor => _kalanSimdi(),
  };

  Duration _kalanSimdi() {
    final k = _bitis!.difference(_saat());
    return k.isNegative ? Duration.zero : k;
  }

  void baslat(Duration sure) {
    if (sure <= Duration.zero) return;
    _bitis = _saat().add(sure);
    _durum = ZamanlayiciDurumu.calisiyor;
  }

  void duraklat() {
    if (_durum != ZamanlayiciDurumu.calisiyor) return;
    _duraklatilanKalan = _kalanSimdi();
    _durum = ZamanlayiciDurumu.duraklatildi;
  }

  void devamEt() {
    if (_durum != ZamanlayiciDurumu.duraklatildi) return;
    baslat(_duraklatilanKalan);
  }

  void sifirla() {
    _durum = ZamanlayiciDurumu.bos;
    _bitis = null;
    _duraklatilanKalan = Duration.zero;
  }

  /// Çalışırken süre dolduysa "bitti"ye geçer ve true döner (yalnızca bir kez).
  bool bittiMiKontrolEt() {
    if (_durum == ZamanlayiciDurumu.calisiyor &&
        _kalanSimdi() == Duration.zero) {
      _durum = ZamanlayiciDurumu.bitti;
      return true;
    }
    return false;
  }
}

/// "05:00", "1:05:00" biçimi; birim metni gerekmez.
String zamanlayiciMetni(Duration d) {
  // Kalan saniyeyi yukarı yuvarla: 4,2 sn kala "00:05" görünür.
  final sn = (d.inMilliseconds / 1000).ceil();
  final s = sn ~/ 3600, dk = (sn % 3600) ~/ 60, san = sn % 60;
  String iki(int x) => x.toString().padLeft(2, '0');
  return s > 0 ? '$s:${iki(dk)}:${iki(san)}' : '${iki(dk)}:${iki(san)}';
}
