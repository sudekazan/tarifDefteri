# Tarifly linkiyle tarif paylaşma

Paylaşan (giriş yapmış) kişinin tarifi `paylasilanTarifler/{kod}` belgesine kopyalanır. Link: `https://tarifly.web.app/t/{kod}`. Tarifly yüklüyse link uygulamayı açar (`PaylasilanTarifSayfasi`, "Defterime ekle"). Yüklü değilse aynı adresteki web sayfası tarifi gösterir.

- Uygulama: `lib/services/tarif_paylasim_service.dart`, `lib/utils/tarif_paylas.dart`, `lib/sayfalar/paylasilan_tarif_sayfasi.dart`; link dinleme `lib/sayfalar/ana_kabuk.dart`.
- Web sitesi: `hosting/` (Firebase Hosting'deki `tarifly` sitesi, `firebase.json`).
- Hesap silinince kişinin paylaşım belgeleri de silinir (`deleteUserAccount`).

## Firestore kuralı (konsolda eklenecek)

Firebase konsolu → Firestore → Kurallar. Aşağıdaki bloğu `match /databases/{database}/documents { ... }` içine, mevcut kuralların yanına ekle:

```
match /paylasilanTarifler/{kod} {
  function gecerli(d) {
    return d.sahipUid == request.auth.uid
      && d.ad is string && d.ad.size() <= 200
      && d.aciklama is string && d.aciklama.size() <= 50000
      && d.bolumler is list && d.bolumler.size() <= 40
      && d.resimler is list && d.resimler.size() <= 5;
  }

  // Herkes tek belgeyi okuyabilir (link sahibi).
  allow get: if true;
  // Liste yalnızca kendi paylaşımların (aynı tarifin linkini yeniden kullanmak için).
  allow list: if request.auth != null && resource.data.sahipUid == request.auth.uid;
  allow create: if request.auth != null
    && kod.matches('^[A-Za-z0-9]{8}$')
    && gecerli(request.resource.data);
  allow update: if request.auth != null
    && resource.data.sahipUid == request.auth.uid
    && gecerli(request.resource.data);
  allow delete: if request.auth != null && resource.data.sahipUid == request.auth.uid;
}
```

## Yayına almadan önce

1. Firestore kuralını yukarıdaki gibi ekle.
2. Apple Developer → Identifiers → `com.sudekazan.tarifDefteri` → "Associated Domains" açık olsun (Xcode otomatik imzalama da açabilir).
3. Play uygulama imzalama SHA-256 parmak izi `hosting/.well-known/assetlinks.json` içinde (2026-11-16 eklendi).
4. Siteyi yayına al: `firebase deploy --only hosting:tarifly`
5. Kontrol: `https://tarifly.web.app/.well-known/apple-app-site-association` ve `.../assetlinks.json` açılmalı.
6. Gerçek cihazda dene: bir tarifi paylaş, linke başka telefondan dokun.

## Bilinen sınırlar

- WhatsApp önizlemesinde tarifin fotoğrafı değil genel Tarifly kartı görünür (tarife özel önizleme Cloud Functions, yani Blaze plan ister).
- Belge paylaşma anındaki kopyadır; tarif değişirse yeniden paylaşınca aynı link güncellenir.
