// /t/KOD sayfası: paylaşılan tarifi Firestore'dan (REST, giriş yok) okur.
// Kural: paylasilanTarifler belgeleri herkese açık okunur.
(function () {
  var PROJE = 'tarifdefteriuygulamasi';
  var RESIM_BASI = 'https://firebasestorage.googleapis.com/';

  var durum = document.getElementById('durum');
  var kutu = document.getElementById('tarif');

  var parca = location.pathname.split('/').filter(Boolean);
  var kod = parca[0] === 't' ? parca[1] : null;
  if (!kod || !/^[A-Za-z0-9]{8}$/.test(kod)) {
    durum.textContent = T.bulunamadi;
    return;
  }

  durum.textContent = T.yukleniyor;

  // Firestore REST değerini düz JS değerine çevirir.
  function coz(deger) {
    if (!deger) return null;
    if ('stringValue' in deger) return deger.stringValue;
    if ('integerValue' in deger) return Number(deger.integerValue);
    if ('doubleValue' in deger) return deger.doubleValue;
    if ('booleanValue' in deger) return deger.booleanValue;
    if ('arrayValue' in deger) return (deger.arrayValue.values || []).map(coz);
    if ('mapValue' in deger) return alanlar(deger.mapValue.fields || {});
    return null;
  }
  function alanlar(f) {
    var sonuc = {};
    Object.keys(f).forEach(function (k) { sonuc[k] = coz(f[k]); });
    return sonuc;
  }

  function el(etiket, sinif, metin) {
    var e = document.createElement(etiket);
    if (sinif) e.className = sinif;
    if (metin != null) e.textContent = metin;
    return e;
  }

  function goster(t) {
    var ad = String(t.ad || '');
    document.title = ad ? ad + ' · Tarifly' : 'Tarifly';
    document.getElementById('ad').textContent = ad;

    var resimKutu = document.getElementById('resimler');
    (Array.isArray(t.resimler) ? t.resimler : [])
      .filter(function (r) { return typeof r === 'string' && r.indexOf(RESIM_BASI) === 0; })
      .slice(0, 5)
      .forEach(function (r) {
        var img = el('img');
        img.src = r;
        img.alt = ad;
        img.loading = 'lazy';
        resimKutu.appendChild(img);
      });

    var bolumKutu = document.getElementById('bolumler');
    var bolumler = Array.isArray(t.bolumler) ? t.bolumler : [];
    bolumler.forEach(function (b) {
      if (!b) return;
      var kart = el('section', 'kart bolum');
      kart.appendChild(el('h2', null, String(b.title || '')));
      var liste = el(b.type === 'yapilis' ? 'ol' : 'ul');
      (Array.isArray(b.items) ? b.items : []).forEach(function (m) {
        var li = el('li');
        var metin = String(m == null ? '' : m);
        if (b.type === 'linkler' && /^https:\/\/\S+$/.test(metin)) {
          var a = el('a', null, metin);
          a.href = metin;
          a.rel = 'noopener noreferrer nofollow';
          a.target = '_blank';
          li.appendChild(a);
        } else {
          li.textContent = metin;
        }
        liste.appendChild(li);
      });
      kart.appendChild(liste);
      bolumKutu.appendChild(kart);
    });

    if (!bolumler.length && t.aciklama) {
      var kart = el('section', 'kart bolum');
      kart.appendChild(el('h2', null, T.aciklama));
      kart.appendChild(el('p', null, String(t.aciklama)));
      bolumKutu.appendChild(kart);
    }

    durum.textContent = '';
    kutu.hidden = false;
  }

  var adres = 'https://firestore.googleapis.com/v1/projects/' + PROJE +
    '/databases/(default)/documents/paylasilanTarifler/' + encodeURIComponent(kod);

  fetch(adres)
    .then(function (yanit) {
      if (yanit.status === 404 || yanit.status === 403) return null;
      if (!yanit.ok) throw new Error('HTTP ' + yanit.status);
      return yanit.json();
    })
    .then(function (belge) {
      if (!belge || !belge.fields) {
        durum.textContent = T.bulunamadi;
        return;
      }
      goster(alanlar(belge.fields));
    })
    .catch(function () {
      durum.textContent = T.hata;
    });
})();
