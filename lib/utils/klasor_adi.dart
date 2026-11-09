import 'package:easy_localization/easy_localization.dart';

import '../tarifler_data/klasor_data.dart';

/// Ekranda görünen klasör adı. Favoriler ve eski varsayılan klasörlerin adı
/// dile göre çevrilir; kullanıcının kendi klasörlerinde ad olduğu gibi kalır.
String klasorGorunenAdi(KlasorData klasor) {
  if (klasor.klasor_id == -1) return 'folders_favorites'.tr();
  final ad = klasor.klasor_adi;
  final id = klasor.klasor_id;
  if (id == 1 &&
      (ad == 'Tatlılar' ||
          ad == 'Desserts' ||
          ad == 'default_folder_desserts'.tr())) {
    return 'default_folder_desserts'.tr();
  } else if (id == 2 &&
      (ad == 'Çorbalar' ||
          ad == 'Soups' ||
          ad == 'default_folder_soups'.tr())) {
    return 'default_folder_soups'.tr();
  } else if (id == 3 &&
      (ad == 'Ana Yemekler' ||
          ad == 'Main Dishes' ||
          ad == 'default_folder_main_dishes'.tr())) {
    return 'default_folder_main_dishes'.tr();
  } else if (id == 4 &&
      (ad == 'Kahvaltılıklar' ||
          ad == 'Breakfast' ||
          ad == 'default_folder_breakfast'.tr())) {
    return 'default_folder_breakfast'.tr();
  }
  return ad;
}
