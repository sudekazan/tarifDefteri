import 'package:flutter_test/flutter_test.dart';
import 'package:tarif_defteri/services/analytics_service.dart';

void main() {
  late List<(String, Map<String, Object>?)> olaylar;
  late List<(String, String?)> ozellikler;

  setUp(() {
    olaylar = [];
    ozellikler = [];
    AnalyticsService.testLogger = (name, params) async => olaylar.add((name, params));
    AnalyticsService.testUserPropertyLogger = (name, value) async => ozellikler.add((name, value));
  });

  tearDown(() {
    AnalyticsService.testLogger = null;
    AnalyticsService.testUserPropertyLogger = null;
  });

  test('satinAlma paywall kaynağını gönderir', () async {
    await AnalyticsService.satinAlma(packageId: r'$rc_annual', priceString: '₺100', source: 'ai_limit');

    expect(olaylar.single.$1, 'satin_alma');
    expect(olaylar.single.$2, {'package_id': r'$rc_annual', 'price': '₺100', 'source': 'ai_limit'});
  });

  test('satinAlmaBasarisiz iptali metin olarak gönderir', () async {
    await AnalyticsService.satinAlmaBasarisiz(source: 'settings', packageId: r'$rc_monthly', iptalEdildi: true);

    expect(olaylar.single.$1, 'satin_alma_basarisiz');
    expect(olaylar.single.$2, {'source': 'settings', 'package_id': r'$rc_monthly', 'iptal_edildi': 'true'});
  });

  test('aiLimitDoldu kaynağı gönderir', () async {
    await AnalyticsService.aiLimitDoldu(kaynak: 'link');

    expect(olaylar.single.$1, 'ai_limit_doldu');
    expect(olaylar.single.$2, {'kaynak': 'link'});
  });

  test('aiKullanildi bool değeri metin olarak gönderir', () async {
    await AnalyticsService.aiKullanildi(isPro: false, kaynak: 'ne_pisirsem');

    expect(olaylar.single.$2, {'is_pro': 'false', 'kaynak': 'ne_pisirsem'});
  });

  test('tarifKaydedildi bool değeri metin olarak gönderir', () async {
    await AnalyticsService.tarifKaydedildi(isAiGenerated: true);

    expect(olaylar.single.$2, {'is_ai_generated': 'true'});
  });

  test('odulluReklam sonucu ve yeri gönderir', () async {
    await AnalyticsService.odulluReklam(sonuc: 'yuklenemedi', yer: 'ne_pisirsem');

    expect(olaylar.single.$1, 'odullu_reklam');
    expect(olaylar.single.$2, {'sonuc': 'yuklenemedi', 'yer': 'ne_pisirsem'});
  });

  test('aramaYapildi ve klasorOlusturuldu parametreleri doğru', () async {
    await AnalyticsService.aramaYapildi(sonucVar: false);
    await AnalyticsService.klasorOlusturuldu(klasorSayisi: 3);

    expect(olaylar[0].$1, 'arama_yapildi');
    expect(olaylar[0].$2, {'sonuc_var': 'false'});
    expect(olaylar[1].$1, 'klasor_olusturuldu');
    expect(olaylar[1].$2, {'klasor_sayisi': 3});
  });

  test('parametresiz olayların adları doğru', () async {
    await AnalyticsService.paywallKapatildi('ana_ekran');
    await AnalyticsService.yemekModuAcildi();
    await AnalyticsService.yemekModuTamamlandi();
    await AnalyticsService.alisverisListesiAcildi();
    await AnalyticsService.alisverisListesineEklendi();
    await AnalyticsService.tarifPaylasildi(kaynak: 'klasorler');

    expect(olaylar.map((o) => o.$1), [
      'paywall_kapatildi',
      'yemek_modu_acildi',
      'yemek_modu_tamamlandi',
      'alisveris_listesi_acildi',
      'alisveris_listesine_eklendi',
      'tarif_paylasildi',
    ]);
    expect(olaylar.first.$2, {'source': 'ana_ekran'});
    expect(olaylar.last.$2, {'kaynak': 'klasorler'});
  });

  test('setIsPro kullanıcı özelliğini metin olarak ayarlar', () async {
    await AnalyticsService.setIsPro(true);

    expect(ozellikler.single, ('is_pro', 'true'));
  });

  test('analitik hata verse de çağrı sorunsuz tamamlanır', () async {
    AnalyticsService.testLogger = (name, params) async => throw Exception('Firebase yok');
    AnalyticsService.testUserPropertyLogger = (name, value) async => throw Exception('Firebase yok');

    await expectLater(AnalyticsService.aiLimitDoldu(kaynak: 'klasor_ai'), completes);
    await expectLater(AnalyticsService.setIsPro(false), completes);
  });
}
