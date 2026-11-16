// Mağaza görselleri için örnek klasörler, tarifler ve alışveriş listesi.
// Her dil için ayrı; yemek adları o dilin okuruna uygun seçildi.
// Fotoğraflar uygulamanın web sitesindeki yemek fotoğraflarıdır.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';
import 'package:tarif_defteri/tarifler_data/tarif_data.dart';

String _foto(String ad) =>
    File('tarif_defteri_web_sitesi/images/$ad').absolute.path;

final _corba = _foto('corba.jpeg');
final _pide = _foto('kıymalı_pide.jpeg');
final _kunefe = _foto('künefe.jpeg');

class OrnekTarif {
  const OrnekTarif(
    this.ad, {
    this.foto,
    this.favori = false,
    this.malzemeler = const [],
    this.yapilis = const [],
  });
  final String ad;
  final String? foto;
  final bool favori;
  final List<String> malzemeler;
  final List<String> yapilis;
}

class OrnekKlasor {
  const OrnekKlasor(this.id, this.ad, this.ikon, this.tarifler);
  final int id;
  final String ad;
  final IconData ikon;
  final List<OrnekTarif> tarifler;
}

class OrnekVeriler {
  OrnekVeriler._(this.klasorler, this.alinacaklar, this.alinanlar,
      this.malzemeBaslik, this.yapilisBaslik);

  final List<OrnekKlasor> klasorler;
  final List<String> alinacaklar;
  final List<String> alinanlar;
  final String malzemeBaslik;
  final String yapilisBaslik;

  static const diller = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

  static OrnekVeriler dil(String dil) => {
        'tr': _tr,
        'en': _en,
        'de': _de,
        'es': _es,
        'fr': _fr,
        'pt': _pt,
      }[dil]!;

  /// Görseli çekilecek ayrıntılı tarif (fotoğraflı çorba).
  TarifData get oneCikanTarif => tarifVerisi(klasorler.first, 0);
  KlasorData get ilkKlasor => klasorVerisi(klasorler.first);

  KlasorData klasorVerisi(OrnekKlasor k) => KlasorData(
        klasor_id: k.id,
        klasor_adi: k.ad,
        iconCode: k.ikon.codePoint,
        updatedAt: 1,
      );

  TarifData tarifVerisi(OrnekKlasor k, int sira) {
    final t = k.tarifler[sira];
    final bolumler = [
      {
        'title': malzemeBaslik,
        'type': 'malzemeler',
        'items': t.malzemeler,
        'isExpanded': true,
      },
      {
        'title': yapilisBaslik,
        'type': 'yapilis',
        'items': t.yapilis,
        'isExpanded': true,
      },
    ];
    final metin = StringBuffer()
      ..writeln(malzemeBaslik)
      ..writeAll(t.malzemeler.map((m) => '* $m\n'))
      ..writeln()
      ..writeln(yapilisBaslik);
    for (var i = 0; i < t.yapilis.length; i++) {
      metin.writeln('${i + 1}. ${t.yapilis[i]}');
    }
    return TarifData(
      tarif_id: k.id * 100 + sira,
      tarif_adi: t.ad,
      tarif_aciklama: metin.toString().trim(),
      tarif_aciklama_json: json.encode(bolumler),
      tarif_resimler: [if (t.foto != null) t.foto!],
      klasor_id: k.id,
      isFavorite: t.favori,
      updatedAt: 1000 - sira,
    );
  }

  /// SharedPreferences'a yazılacak başlangıç değerleri.
  Map<String, Object> tercihler() => {
        'defaultFoldersAdded': true,
        'app_launch_count': 0,
        'klasorler': [
          for (final k in klasorler) json.encode(klasorVerisi(k).toMap()),
        ],
        for (final k in klasorler)
          'tarifler_${k.id}': [
            for (var i = 0; i < k.tarifler.length; i++)
              json.encode(tarifVerisi(k, i).toMap()),
          ],
        'shopping_list_todo': alinacaklar,
        'shopping_list_done': alinanlar,
      };
}

final _tr = OrnekVeriler._(
  [
    OrnekKlasor(1, 'Çorbalar', Icons.soup_kitchen, [
      OrnekTarif(
        'Mercimek Çorbası',
        foto: _corba,
        favori: true,
        malzemeler: [
          '1 su bardağı kırmızı mercimek',
          '1 adet kuru soğan',
          '1 adet havuç',
          '1 yemek kaşığı tereyağı',
          '1 tatlı kaşığı pul biber',
          '6 su bardağı sıcak su',
          'Tuz, kimyon',
        ],
        yapilis: [
          'Soğanı ve havucu küçük doğrayıp tereyağında kavurun.',
          'Yıkanmış mercimeği ve sıcak suyu ekleyin.',
          'Mercimekler dağılana kadar 25 dakika pişirin.',
          'Blenderdan geçirip tuz ve kimyonla tatlandırın.',
          'Pul biberli tereyağı gezdirerek servis edin.',
        ],
      ),
      OrnekTarif('Ezogelin Çorbası'),
      OrnekTarif('Yayla Çorbası'),
      OrnekTarif('Domates Çorbası'),
    ]),
    OrnekKlasor(2, 'Ana Yemekler', Icons.dinner_dining, [
      OrnekTarif('Karnıyarık', favori: true),
      OrnekTarif('İzmir Köfte'),
      OrnekTarif('Tavuk Sote'),
    ]),
    OrnekKlasor(3, 'Hamur İşleri', Icons.bakery_dining, [
      OrnekTarif('Kıymalı Pide', foto: _pide),
      OrnekTarif('Su Böreği'),
      OrnekTarif('Peynirli Poğaça'),
    ]),
    OrnekKlasor(4, 'Tatlılar', Icons.cake, [
      OrnekTarif('Künefe', foto: _kunefe, favori: true),
      OrnekTarif('Fırın Sütlaç'),
      OrnekTarif('Revani'),
    ]),
    OrnekKlasor(5, 'Kahvaltılık', Icons.brunch_dining, [
      OrnekTarif('Menemen'),
      OrnekTarif('Çılbır'),
    ]),
  ],
  [
    '1 su bardağı kırmızı mercimek',
    '1 adet havuç',
    'Tereyağı',
    'Kadayıf',
    'Tuzsuz peynir',
    'Domates',
  ],
  ['Kuru soğan', 'Pul biber'],
  'Malzemeler',
  'Yapılışı',
);

final _en = OrnekVeriler._(
  [
    OrnekKlasor(1, 'Soups', Icons.soup_kitchen, [
      OrnekTarif(
        'Red Lentil Soup',
        foto: _corba,
        favori: true,
        malzemeler: [
          '1 cup red lentils',
          '1 onion',
          '1 carrot',
          '1 tbsp butter',
          '1 tsp red pepper flakes',
          '6 cups hot water',
          'Salt, cumin',
        ],
        yapilis: [
          'Dice the onion and carrot, then sauté them in butter.',
          'Add the rinsed lentils and the hot water.',
          'Simmer for 25 minutes until the lentils break down.',
          'Blend until smooth and season with salt and cumin.',
          'Drizzle with red pepper butter and serve.',
        ],
      ),
      OrnekTarif('Tomato Basil Soup'),
      OrnekTarif('Chicken Noodle Soup'),
      OrnekTarif('Butternut Squash Soup'),
    ]),
    OrnekKlasor(2, 'Main Dishes', Icons.dinner_dining, [
      OrnekTarif('Spaghetti Bolognese', favori: true),
      OrnekTarif('Lemon Herb Roast Chicken'),
      OrnekTarif('Beef Tacos'),
    ]),
    OrnekKlasor(3, 'Baking', Icons.bakery_dining, [
      OrnekTarif('Turkish Meat Pide', foto: _pide),
      OrnekTarif('Banana Bread'),
      OrnekTarif('Blueberry Muffins'),
    ]),
    OrnekKlasor(4, 'Desserts', Icons.cake, [
      OrnekTarif('Kunefe', foto: _kunefe, favori: true),
      OrnekTarif('Chocolate Chip Cookies'),
      OrnekTarif('Classic Cheesecake'),
    ]),
    OrnekKlasor(5, 'Breakfast', Icons.brunch_dining, [
      OrnekTarif('Fluffy Pancakes'),
      OrnekTarif('Shakshuka'),
    ]),
  ],
  [
    '1 cup red lentils',
    '1 carrot',
    'Butter',
    'Spaghetti',
    'Fresh basil',
    'Tomatoes',
  ],
  ['Onion', 'Red pepper flakes'],
  'Ingredients',
  'Instructions',
);

final _de = OrnekVeriler._(
  [
    OrnekKlasor(1, 'Suppen', Icons.soup_kitchen, [
      OrnekTarif(
        'Rote Linsensuppe',
        foto: _corba,
        favori: true,
        malzemeler: [
          '200 g rote Linsen',
          '1 Zwiebel',
          '1 Karotte',
          '1 EL Butter',
          '1 TL Chiliflocken',
          '1,5 l heißes Wasser',
          'Salz, Kreuzkümmel',
        ],
        yapilis: [
          'Zwiebel und Karotte würfeln und in Butter andünsten.',
          'Gewaschene Linsen und heißes Wasser dazugeben.',
          '25 Minuten köcheln, bis die Linsen zerfallen.',
          'Fein pürieren, mit Salz und Kreuzkümmel abschmecken.',
          'Mit Chilibutter beträufelt servieren.',
        ],
      ),
      OrnekTarif('Kartoffelsuppe'),
      OrnekTarif('Tomatensuppe'),
      OrnekTarif('Kürbissuppe'),
    ]),
    OrnekKlasor(2, 'Hauptgerichte', Icons.dinner_dining, [
      OrnekTarif('Wiener Schnitzel', favori: true),
      OrnekTarif('Käsespätzle'),
      OrnekTarif('Rinderrouladen'),
    ]),
    OrnekKlasor(3, 'Backen', Icons.bakery_dining, [
      OrnekTarif('Türkische Hackfleisch-Pide', foto: _pide),
      OrnekTarif('Laugenbrezeln'),
      OrnekTarif('Zwiebelkuchen'),
    ]),
    OrnekKlasor(4, 'Desserts', Icons.cake, [
      OrnekTarif('Künefe', foto: _kunefe, favori: true),
      OrnekTarif('Apfelstrudel'),
      OrnekTarif('Käsekuchen'),
    ]),
    OrnekKlasor(5, 'Frühstück', Icons.brunch_dining, [
      OrnekTarif('Bircher Müsli'),
      OrnekTarif('Rührei mit Schnittlauch'),
    ]),
  ],
  [
    '200 g rote Linsen',
    '1 Karotte',
    'Butter',
    'Kartoffeln',
    'Schnittlauch',
    'Tomaten',
  ],
  ['Zwiebeln', 'Chiliflocken'],
  'Zutaten',
  'Zubereitung',
);

final _es = OrnekVeriler._(
  [
    OrnekKlasor(1, 'Sopas', Icons.soup_kitchen, [
      OrnekTarif(
        'Sopa de lentejas rojas',
        foto: _corba,
        favori: true,
        malzemeler: [
          '1 taza de lentejas rojas',
          '1 cebolla',
          '1 zanahoria',
          '1 cucharada de mantequilla',
          '1 cucharadita de chile en copos',
          '6 tazas de agua caliente',
          'Sal y comino',
        ],
        yapilis: [
          'Pica la cebolla y la zanahoria y sofríelas en mantequilla.',
          'Añade las lentejas lavadas y el agua caliente.',
          'Cocina 25 minutos hasta que las lentejas se deshagan.',
          'Tritura y sazona con sal y comino.',
          'Sirve con un chorrito de mantequilla con chile.',
        ],
      ),
      OrnekTarif('Gazpacho andaluz'),
      OrnekTarif('Caldo de pollo'),
      OrnekTarif('Crema de calabaza'),
    ]),
    OrnekKlasor(2, 'Platos principales', Icons.dinner_dining, [
      OrnekTarif('Paella de marisco', favori: true),
      OrnekTarif('Albóndigas en salsa'),
      OrnekTarif('Pollo al ajillo'),
    ]),
    OrnekKlasor(3, 'Masas y panes', Icons.bakery_dining, [
      OrnekTarif('Pide turca de carne', foto: _pide),
      OrnekTarif('Empanadas de carne'),
      OrnekTarif('Pan de pueblo'),
    ]),
    OrnekKlasor(4, 'Postres', Icons.cake, [
      OrnekTarif('Künefe', foto: _kunefe, favori: true),
      OrnekTarif('Flan casero'),
      OrnekTarif('Arroz con leche'),
    ]),
    OrnekKlasor(5, 'Desayunos', Icons.brunch_dining, [
      OrnekTarif('Tortilla de patatas'),
      OrnekTarif('Churros con chocolate'),
    ]),
  ],
  [
    '1 taza de lentejas rojas',
    '1 zanahoria',
    'Mantequilla',
    'Patatas',
    'Pimiento rojo',
    'Tomates',
  ],
  ['Cebolla', 'Chile en copos'],
  'Ingredientes',
  'Preparación',
);

final _fr = OrnekVeriler._(
  [
    OrnekKlasor(1, 'Soupes', Icons.soup_kitchen, [
      OrnekTarif(
        'Soupe de lentilles corail',
        foto: _corba,
        favori: true,
        malzemeler: [
          '200 g de lentilles corail',
          '1 oignon',
          '1 carotte',
          '1 c. à soupe de beurre',
          '1 c. à café de piment en flocons',
          '1,5 l d’eau chaude',
          'Sel, cumin',
        ],
        yapilis: [
          'Émincez l’oignon et la carotte, faites-les revenir au beurre.',
          'Ajoutez les lentilles rincées et l’eau chaude.',
          'Laissez mijoter 25 minutes jusqu’à ce qu’elles fondent.',
          'Mixez, puis assaisonnez de sel et de cumin.',
          'Servez avec un filet de beurre pimenté.',
        ],
      ),
      OrnekTarif('Soupe à l’oignon'),
      OrnekTarif('Velouté de potiron'),
      OrnekTarif('Soupe au pistou'),
    ]),
    OrnekKlasor(2, 'Plats principaux', Icons.dinner_dining, [
      OrnekTarif('Bœuf bourguignon', favori: true),
      OrnekTarif('Poulet rôti aux herbes'),
      OrnekTarif('Ratatouille'),
    ]),
    OrnekKlasor(3, 'Boulangerie', Icons.bakery_dining, [
      OrnekTarif('Pide turque à la viande', foto: _pide),
      OrnekTarif('Quiche lorraine'),
      OrnekTarif('Croissants maison'),
    ]),
    OrnekKlasor(4, 'Desserts', Icons.cake, [
      OrnekTarif('Künefe', foto: _kunefe, favori: true),
      OrnekTarif('Crème brûlée'),
      OrnekTarif('Tarte Tatin'),
    ]),
    OrnekKlasor(5, 'Petit-déjeuner', Icons.brunch_dining, [
      OrnekTarif('Crêpes'),
      OrnekTarif('Pain perdu'),
    ]),
  ],
  [
    '200 g de lentilles corail',
    '1 carotte',
    'Beurre',
    'Crème fraîche',
    'Basilic frais',
    'Tomates',
  ],
  ['Oignons', 'Piment en flocons'],
  'Ingrédients',
  'Préparation',
);

final _pt = OrnekVeriler._(
  [
    OrnekKlasor(1, 'Sopas', Icons.soup_kitchen, [
      OrnekTarif(
        'Sopa de lentilha vermelha',
        foto: _corba,
        favori: true,
        malzemeler: [
          '1 xícara de lentilha vermelha',
          '1 cebola',
          '1 cenoura',
          '1 colher de sopa de manteiga',
          '1 colher de chá de pimenta calabresa',
          '6 xícaras de água quente',
          'Sal e cominho',
        ],
        yapilis: [
          'Pique a cebola e a cenoura e refogue na manteiga.',
          'Junte a lentilha lavada e a água quente.',
          'Cozinhe por 25 minutos até a lentilha desmanchar.',
          'Bata no liquidificador e tempere com sal e cominho.',
          'Sirva com um fio de manteiga com pimenta.',
        ],
      ),
      OrnekTarif('Caldo verde'),
      OrnekTarif('Canja de galinha'),
      OrnekTarif('Sopa de abóbora'),
    ]),
    OrnekKlasor(2, 'Pratos principais', Icons.dinner_dining, [
      OrnekTarif('Feijoada', favori: true),
      OrnekTarif('Bacalhau à Brás'),
      OrnekTarif('Frango assado com ervas'),
    ]),
    OrnekKlasor(3, 'Massas e pães', Icons.bakery_dining, [
      OrnekTarif('Pide turca de carne', foto: _pide),
      OrnekTarif('Pão de queijo'),
      OrnekTarif('Empadão de frango'),
    ]),
    OrnekKlasor(4, 'Sobremesas', Icons.cake, [
      OrnekTarif('Künefe', foto: _kunefe, favori: true),
      OrnekTarif('Pastel de nata'),
      OrnekTarif('Brigadeiro'),
    ]),
    OrnekKlasor(5, 'Café da manhã', Icons.brunch_dining, [
      OrnekTarif('Tapioca recheada'),
      OrnekTarif('Panquecas'),
    ]),
  ],
  [
    '1 xícara de lentilha vermelha',
    '1 cenoura',
    'Manteiga',
    'Queijo minas',
    'Coentro',
    'Tomates',
  ],
  ['Cebola', 'Pimenta calabresa'],
  'Ingredientes',
  'Modo de preparo',
);
