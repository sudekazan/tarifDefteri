# Premium Rozeti Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Amaç:** Premium olmayan kullanıcıya gösterilen rozetin yazısını "Premium'a geç" yapmak ve rozeti başlığın sağ kenarına taşımak. Bu değişiklik iki ekranı kapsıyor: ana sayfa ve "Bugün ne pişirsem".

**Mimari:** Ana sayfa başlığı şu an `klasorler.dart` içindeki özel `_baslik()` metodunda tanımlı. Test edilebilmesi için `ana_sayfa_parcalari.dart` dosyasına `AnaSayfaBasligi` adlı bir bileşen olarak taşınacak. `NePisirsemBasligi` bileşeninde yalnızca yan yana yerleşim dalı değişecek. Rozetin metni `home_pro_badge` anahtarından geliyor; bu anahtarın 6 dildeki değeri güncellenecek.

**Teknolojiler:** Flutter, flutter_test, easy_localization.

**Tasarım:** `docs/superpowers/specs/2026-11-21-premium-rozeti-design.md`

**Dal:** `kil-gece`. Başlamadan önce GitHub'daki en güncel hali alınacak (Sude'nin yerel 6 commit'i gönderilmiş olmalı).

## Genel Kısıtlar

- Metinler aynen şöyle olacak: tr `Premium'a geç`, en `Go Premium`, de `Premium holen`, es `Hazte Premium`, fr `Passer à Premium`, pt `Seja Premium`.
- Rozetin görünümü (renkler, kapsül şekli, taç simgesi) ve dokunma davranışı değişmeyecek.
- Dokunma alanı en az 48x48 olmaya devam edecek.
- Büyük yazıda başlık kısalmayacak. Rozet sığmazsa başlığın altına inecek.
- Commit mesajları Türkçe, kısa ve ön eksiz olacak (CLAUDE.md).
- Dosya ve bileşen adlarında projenin Türkçe adlandırma geleneği sürdürülecek.

## İnceleme Odağı

1. **Uzun metin rozetin içinde taşabilir:** "Premium'a geç" ve "Passer à Premium", "Premium"dan uzun. 320 genişlikte ve 3.2 kat yazı boyutunda (rozetin üst sınırı 2.0) rozet taşma hatası vermemeli ve metin kesilmemeli. Bu durumun testi Görev 1'de.
2. **Rozet her durumda sağ kenara yaslanmalı:** Başlık kısa olsa da rozet başlığa yapışık değil, sağ kenarda durmalı. Testi Görev 1 ve Görev 2'de.
3. **Premium kullanıcıda rozet görünmemeli:** Bu durumda başlık tek başına durmalı ve sağda boş bir alan kalmamalı. Testi Görev 1'de (`proRozeti: null` durumu).
4. **Ekran okuyucu:** Rozetin anlam etiketi `premium_title` olarak kalmalı. Mevcut testler bunu zaten kapsıyor, değişmeyecek.
5. **Koyu mod:** Taşma testleri her iki temada da çalışmalı. Mevcut `KilRenkleri.acik` / koyu döngüsü bu testleri de kapsamalı.

---

### Görev 0: Ortam

- [ ] **Adım 1:** `git fetch origin && git checkout kil-gece && git pull`. Beklenen: `origin/kil-gece`, Sude'nin `55a2058` commit'ini içeriyor olmalı (`git log --oneline | grep 55a2058`). İçermiyorsa dur ve Sude'ye sor.
- [ ] **Adım 2:** Flutter SDK'nın varlığını kontrol et: `flutter --version`. Yoksa `git clone --depth 1 -b stable https://github.com/flutter/flutter.git ~/flutter` ile kur ve `flutter pub get` çalıştır. Kurulum ağ yüzünden başarısız olursa testleri Sude'nin Mac'inde `flutter test test/ana_sayfa_parcalari_test.dart test/ne_pisirsem_parcalari_test.dart` komutuyla çalıştırması gerekir. Bu durum kayda geçirilir.
- [ ] **Adım 3:** Temel durum kontrolü: `flutter test test/ana_sayfa_parcalari_test.dart test/ne_pisirsem_parcalari_test.dart`. Beklenen: hepsi PASS.

### Görev 1: Ana sayfa başlığı (`AnaSayfaBasligi`) ve rozetteki uzun metin

**Dosyalar:**
- Değiştirilecek: `lib/widgets/ana_sayfa_parcalari.dart`. Yeni `AnaSayfaBasligi` bileşeni eklenecek; `ProRozeti` içindeki `Text` uzun metinde kaymadan alt satıra inebilecek.
- Değiştirilecek: `lib/sayfalar/klasorler.dart`. `_baslik()` metodu `AnaSayfaBasligi` bileşenini kullanacak.
- Test: `test/ana_sayfa_parcalari_test.dart`

**Arayüz:**
- Sağladığı:
  ```dart
  class AnaSayfaBasligi extends StatelessWidget {
    const AnaSayfaBasligi({super.key, required this.baslik, this.proRozeti});
    final Widget baslik;      // klasorler.dart'taki Semantics+Text bloğu aynen buraya verilir
    final Widget? proRozeti;  // Pro kullanıcıda null
  }
  ```

Adımlar:

- [ ] **Adım 1: Başarısız testleri yaz** (`test/ana_sayfa_parcalari_test.dart` dosyasına, mevcut `_sar` yardımcısıyla):
  - `'ana sayfa başlığı: rozet sağ kenarda'`: 390 genişlik, 1x yazı. `baslik: Text('Tarifly')`, `proRozeti: ProRozeti(etiket: "Premium'a geç", ...)`. Rozetin sağ kenarı (`tester.getRect(find.byType(ProRozeti)).right`) ile başlık alanının sağ kenarı (`tester.getRect(find.byType(AnaSayfaBasligi)).right`) arasındaki fark 1 pikselden az olmalı. Rozetin üst kenarı ile başlığın üst kenarı aynı satırda olmalı: rozetin dikey merkezi, başlığın üst ve alt kenarı arasında kalmalı.
  - `'ana sayfa başlığı: büyük yazıda rozet başlığın altına iner'`: 320 genişlik, 3.2x yazı. Rozetin üst kenarı, `find.text('Tarifly')` alt kenarından büyük ya da ona eşit olmalı. `tester.takeException()` null olmalı.
  - `'ana sayfa başlığı: rozet yoksa yalnızca başlık'`: `proRozeti: null`. `find.byType(ProRozeti)` hiçbir şey bulmamalı ve `find.text('Tarifly')` bir tane bulmalı.
  - `'Pro rozeti uzun metinde taşmaz'`: Her tema (açık/koyu) için, 320 genişlik ve 3.2x yazı. Rozetler `"Premium'a geç"` ve `'Passer à Premium'` etiketleriyle denenir. `tester.takeException()` null olmalı ve metin kesilmeden tamamı görünmeli: `find.text(...)` bir tane bulmalı ve `Text` bileşeninin `overflow` değeri `TextOverflow.ellipsis` olmamalı.
- [ ] **Adım 2: Testlerin başarısız olduğunu gör:** `flutter test test/ana_sayfa_parcalari_test.dart`. Beklenen: `AnaSayfaBasligi` tanımlı olmadığı için derleme hatası.
- [ ] **Adım 3: `AnaSayfaBasligi` bileşenini yaz:**
  - Başlık ve rozet tek satıra sığıyorsa: başlık solda, rozet sağ kenarda (`Row` + `Expanded`/`Spacer` ya da `Wrap` + `alignment: WrapAlignment.spaceBetween`).
  - Sığmıyorsa: rozet başlığın altında, sola yaslı.
  - Sığma kararı, mevcut `Wrap` davranışıyla ya da `LayoutBuilder` ile ölçerek verilebilir. Hangisi testleri geçiriyorsa o seçilir.
  - `ProRozeti` içindeki `Text`, `Flexible` ile sarılır ve alt satıra inebilir (`softWrap: true`, `maxLines` yok, kısaltma yok).
- [ ] **Adım 4: `klasorler.dart` içindeki `_baslik()` metodunu güncelle:** Mevcut `Wrap` yerine `AnaSayfaBasligi(baslik: <mevcut Semantics bloğu>, proRozeti: RevenueCatService.isProUser ? null : ProRozeti(...))` kullan. Rozetin parametreleri değişmeyecek.
- [ ] **Adım 5: Testleri çalıştır:** `flutter test test/ana_sayfa_parcalari_test.dart`. Beklenen: hepsi PASS, mevcutlar dahil.
- [ ] **Adım 6: Commit:** `git commit -m "Premium rozetini ana sayfada sağ kenara taşı"`

### Görev 2: "Bugün ne pişirsem" başlığı

**Dosyalar:**
- Değiştirilecek: `lib/widgets/ne_pisirsem_parcalari.dart`. `NePisirsemBasligi` sınıfının yan yana yerleşim dalı değişecek (`ustUste == false` ve `geriVar == false`).
- Test: `test/ne_pisirsem_parcalari_test.dart`

Adımlar:

- [ ] **Adım 1: Başarısız testi yaz:** `'ne pişirsem başlığı: rozet sağ kenarda'`. 390 genişlik, 1x yazı, `geriVar: false`, `baslik: 'Ne pişirsem?'`, `proRozeti: ProRozeti(etiket: "Premium'a geç", ...)`. Rozetin sağ kenarı ile `NePisirsemBasligi` bileşeninin sağ kenarı arasındaki fark 1 pikselden az olmalı.
- [ ] **Adım 2: Testin başarısız olduğunu gör:** `flutter test test/ne_pisirsem_parcalari_test.dart`. Beklenen: rozet başlığa yapışık olduğu için sağ kenar karşılaştırması FAIL.
- [ ] **Adım 3: Yerleşimi değiştir:** `Row` içinde başlık `Expanded` ile sarılır ve sola yaslanır, ardından `SizedBox(width: 8)` ve rozet gelir. `ustUste` (üst üste) dalına ve `geriVar` dalına dokunulmaz. `geriVar` dalında rozet zaten `KilSayfaBasligi`'nin `eylemler` alanında duruyor. Bu dalın da sağ kenara yaslandığını mevcut ekranda kontrol et, değilse bu görev kapsamında aynı testi `geriVar: true` için de ekle.
- [ ] **Adım 4: Testleri çalıştır:** `flutter test test/ne_pisirsem_parcalari_test.dart`. Beklenen: hepsi PASS.
- [ ] **Adım 5: Commit:** `git commit -m "Ne pişirsem ekranında Premium rozetini sağa taşı"`

### Görev 3: Metinler

**Dosyalar:**
- Değiştirilecek: `assets/lang/{tr,en,de,es,fr,pt}.json`. Yalnızca `home_pro_badge` anahtarının değeri değişecek.

Adımlar:

- [ ] **Adım 1:** Altı dosyada `home_pro_badge` değerini Genel Kısıtlar'daki metinlerle değiştir.
- [ ] **Adım 2: Doğrula:** `for f in assets/lang/*.json; do python3 -c "import json,sys; print(sys.argv[1], json.load(open(sys.argv[1]))['home_pro_badge'])" $f; done`. Beklenen: altı satır, her birinde doğru metin. JSON ayrıştırma hatası olmamalı.
- [ ] **Adım 3: Tüm testler:** `flutter analyze && flutter test`. Beklenen: analiz temiz, tüm testler PASS.
- [ ] **Adım 4: Commit ve gönderme:** `git commit -m "Premium rozetinin yazısını Premium'a geç yap"`, ardından `git push`.
- [ ] **Adım 5 (Sude):** Simülatörde ana sayfayı ve "Bugün ne pişirsem" ekranını Premium olmayan bir hesapla aç. Rozet sağda ve "Premium'a geç" yazıyor olmalı. Ardından cihazın yazı boyutunu en büyüğe çek ve rozetin başlığın altına indiğini gör.
