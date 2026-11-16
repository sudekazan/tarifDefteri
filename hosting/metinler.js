// tarifly.web.app sayfalarının metinleri (uygulamanın altı dili).
// Tarayıcı dili bunlardan biri değilse İngilizce.
var TARIFLY_METINLER = {
  tr: {
    yukleniyor: 'Tarif yükleniyor…',
    bulunamadi: 'Bu tarif bulunamadı. Paylaşan kişi kaldırmış olabilir.',
    hata: 'Tarif açılamadı. İnternet bağlantını kontrol edip sayfayı yenile.',
    ctaBaslik: 'Bu tarifi defterine ekle',
    ctaMetin: "Tarifly'i indir, sonra bu linke tekrar dokun. Tarif uygulamada açılır, tek dokunuşla defterine eklersin.",
    appStore: "App Store'dan indir",
    googlePlay: "Google Play'den indir",
    tanitim: 'Tariflerin, tek bir defterde.',
    aciklama: 'Tarif'
  },
  en: {
    yukleniyor: 'Loading recipe…',
    bulunamadi: 'This recipe could not be found. The person who shared it may have removed it.',
    hata: "The recipe couldn't be opened. Check your internet connection and refresh the page.",
    ctaBaslik: 'Add this recipe to your cookbook',
    ctaMetin: 'Download Tarifly, then tap this link again. The recipe opens in the app and you can add it with one tap.',
    appStore: 'Download on the App Store',
    googlePlay: 'Get it on Google Play',
    tanitim: 'All your recipes in one cookbook.',
    aciklama: 'Recipe'
  },
  de: {
    yukleniyor: 'Rezept wird geladen…',
    bulunamadi: 'Dieses Rezept wurde nicht gefunden. Die Person, die es geteilt hat, hat es vielleicht entfernt.',
    hata: 'Das Rezept konnte nicht geöffnet werden. Prüfe deine Internetverbindung und lade die Seite neu.',
    ctaBaslik: 'Füge dieses Rezept deinem Kochbuch hinzu',
    ctaMetin: 'Lade Tarifly herunter und tippe dann erneut auf diesen Link. Das Rezept öffnet sich in der App und du fügst es mit einem Tipp hinzu.',
    appStore: 'Im App Store laden',
    googlePlay: 'Bei Google Play herunterladen',
    tanitim: 'Alle deine Rezepte in einem Kochbuch.',
    aciklama: 'Rezept'
  },
  es: {
    yukleniyor: 'Cargando receta…',
    bulunamadi: 'No se encontró esta receta. Es posible que la persona que la compartió la haya eliminado.',
    hata: 'No se pudo abrir la receta. Comprueba tu conexión a internet y recarga la página.',
    ctaBaslik: 'Añade esta receta a tu recetario',
    ctaMetin: 'Descarga Tarifly y vuelve a tocar este enlace. La receta se abre en la app y la añades con un toque.',
    appStore: 'Descargar en el App Store',
    googlePlay: 'Disponible en Google Play',
    tanitim: 'Todas tus recetas en un solo recetario.',
    aciklama: 'Receta'
  },
  fr: {
    yukleniyor: 'Chargement de la recette…',
    bulunamadi: "Cette recette est introuvable. La personne qui l'a partagée l'a peut-être supprimée.",
    hata: "Impossible d'ouvrir la recette. Vérifie ta connexion internet et actualise la page.",
    ctaBaslik: 'Ajoute cette recette à ton carnet',
    ctaMetin: "Télécharge Tarifly, puis touche à nouveau ce lien. La recette s'ouvre dans l'app et tu l'ajoutes en un geste.",
    appStore: "Télécharger dans l'App Store",
    googlePlay: 'Disponible sur Google Play',
    tanitim: 'Toutes tes recettes dans un seul carnet.',
    aciklama: 'Recette'
  },
  pt: {
    yukleniyor: 'Carregando receita…',
    bulunamadi: 'Esta receita não foi encontrada. A pessoa que a compartilhou pode tê-la removido.',
    hata: 'Não foi possível abrir a receita. Verifique sua conexão com a internet e atualize a página.',
    ctaBaslik: 'Adicione esta receita ao seu caderno',
    ctaMetin: 'Baixe o Tarifly e toque neste link de novo. A receita abre no app e você a adiciona com um toque.',
    appStore: 'Baixar na App Store',
    googlePlay: 'Disponível no Google Play',
    tanitim: 'Todas as suas receitas em um só caderno.',
    aciklama: 'Receita'
  }
};

function tariflyDil() {
  var diller = navigator.languages || [navigator.language || 'en'];
  for (var i = 0; i < diller.length; i++) {
    var kod = String(diller[i]).slice(0, 2).toLowerCase();
    if (TARIFLY_METINLER[kod]) return kod;
  }
  return 'en';
}

var TARIFLY_DIL = tariflyDil();
var T = TARIFLY_METINLER[TARIFLY_DIL];

document.documentElement.lang = TARIFLY_DIL;
document.querySelectorAll('[data-metin]').forEach(function (el) {
  el.textContent = T[el.getAttribute('data-metin')] || '';
});

// Telefona uygun mağaza düğmesi öne çıkar, diğeri ikincil görünür.
(function () {
  var ua = navigator.userAgent || '';
  var ios = /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && 'ontouchend' in document);
  var android = /Android/.test(ua);
  var iosDugme = document.getElementById('ios');
  var androidDugme = document.getElementById('android');
  if (!iosDugme || !androidDugme) return;
  if (ios) androidDugme.classList.add('ikincil');
  else if (android) {
    iosDugme.classList.add('ikincil');
    iosDugme.parentNode.insertBefore(androidDugme, iosDugme);
  } else androidDugme.classList.add('ikincil');
})();
