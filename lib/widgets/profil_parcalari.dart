import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart' show ReauthYontemi;
import 'kil/kil.dart';
import 'premium_parcalari.dart';

/// Yazı bu kattan büyükse hesap kartında ikon metnin üstüne çıkar ve
/// satırlarda ikon kutusu gizlenir (Premium'daki 1.6 sınırı gibi).
const double profilUstUsteOlcegi = 1.6;

bool profilUstUsteMi(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) / 10 > profilUstUsteOlcegi;

/// Caveat başlık en fazla bu kadar büyür (diğer sekmelerdeki gibi).
const double profilBaslikSiniri = 2.0;

/// Profilin üstünde gösterilen hesap bilgisi.
@immutable
class ProfilHesap {
  const ProfilHesap({this.ad, this.eposta, this.yontem});

  final String? ad;
  final String? eposta;

  /// Giriş yöntemi; bilinmiyorsa `null` (satır gösterilmez).
  final ReauthYontemi? yontem;
}

/// Giriş yönteminin metni ve ikonu.
(String, IconData) profilYontemMetni(ReauthYontemi yontem) => switch (yontem) {
      ReauthYontemi.sifre => (
          'profile_signed_in_with_email'.tr(),
          Icons.mail_outline_rounded,
        ),
      ReauthYontemi.google => (
          'profile_signed_in_with_google'.tr(),
          Icons.g_mobiledata_rounded,
        ),
      ReauthYontemi.apple => (
          'profile_signed_in_with_apple'.tr(),
          Icons.apple,
        ),
    };

/// Hesap bilgisi kartı: kişi dairesi, ad (yoksa e-posta), e-posta ve giriş
/// yöntemi hapı.
class ProfilHesapKarti extends StatelessWidget {
  const ProfilHesapKarti({
    super.key,
    required this.hesap,
    required this.yedekAd,
  });

  final ProfilHesap hesap;

  /// Ad ve e-posta yoksa gösterilen ad ("Kullanıcı").
  final String yedekAd;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;
    final ustUste = profilUstUsteMi(context);

    final adVar = hesap.ad != null && hesap.ad!.trim().isNotEmpty;
    final epostaVar = hesap.eposta != null && hesap.eposta!.isNotEmpty;
    final gorunenAd =
        adVar ? hesap.ad!.trim() : (epostaVar ? hesap.eposta! : yedekAd);
    final altSatir = adVar && epostaVar ? hesap.eposta : null;

    final daire = ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: r.seciliCipZemin,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person_rounded, size: 32, color: r.seciliCipYazi),
      ),
    );

    final yontem = hesap.yontem;
    final metinler = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(gorunenAd, style: yazi.titleLarge?.copyWith(color: r.anaYazi)),
        if (altSatir != null) ...[
          const SizedBox(height: 2),
          Text(altSatir, style: yazi.bodyMedium?.copyWith(color: r.solukYazi)),
        ],
        if (yontem != null) ...[
          const SizedBox(height: 8),
          _YontemHapi(yontem: yontem),
        ],
      ],
    );

    return KilKart(
      padding: const EdgeInsets.all(16),
      child: MergeSemantics(
        child: ustUste
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [daire, const SizedBox(height: 12), metinler],
              )
            : Row(
                children: [
                  daire,
                  const SizedBox(width: 14),
                  Expanded(child: metinler),
                ],
              ),
      ),
    );
  }
}

class _YontemHapi extends StatelessWidget {
  const _YontemHapi({required this.yontem});

  final ReauthYontemi yontem;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final (metin, ikon) = profilYontemMetni(yontem);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: r.solukYuzey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(ikon, size: 18, color: r.solukYazi)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              metin,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: r.solukYazi),
            ),
          ),
        ],
      ),
    );
  }
}

/// Giriş yapılmamışken hesap kartının yeri: açıklama ve giriş düğmesi.
class ProfilGirisKarti extends StatelessWidget {
  const ProfilGirisKarti({
    super.key,
    required this.baslik,
    required this.aciklama,
    required this.dugmeEtiketi,
    required this.onGiris,
  });

  final String baslik;
  final String aciklama;
  final String dugmeEtiketi;
  final VoidCallback onGiris;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;
    final ustUste = profilUstUsteMi(context);

    final daire = ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: r.solukYuzey,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: 32,
          color: r.solukYazi,
        ),
      ),
    );
    final metinler = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(baslik, style: yazi.titleLarge?.copyWith(color: r.anaYazi)),
        const SizedBox(height: 2),
        Text(aciklama, style: yazi.bodyMedium?.copyWith(color: r.solukYazi)),
      ],
    );

    return KilKart(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: ustUste
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [daire, const SizedBox(height: 12), metinler],
                  )
                : Row(
                    children: [
                      daire,
                      const SizedBox(width: 14),
                      Expanded(child: metinler),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          KilDugme.birincil(
            etiket: dugmeEtiketi,
            ikon: Icons.login_rounded,
            tamGenislik: true,
            onPressed: onGiris,
          ),
        ],
      ),
    );
  }
}

/// Bir ayar bölümü: küçük başlık ve altında satırları taşıyan kil kartı.
class ProfilBolumu extends StatelessWidget {
  const ProfilBolumu({super.key, this.baslik, required this.satirlar});

  final String? baslik;
  final List<Widget> satirlar;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (baslik != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Semantics(
              header: true,
              child: Text(
                baslik!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: r.solukYazi),
              ),
            ),
          ),
        KilKart(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < satirlar.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                satirlar[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Bir ayar satırı: renkli ikon kutusu, başlık, isteğe bağlı açıklama ve
/// sağda ok ya da [sag]. En az 56 yükseklik; dokunulabiliyorsa ekran okuyucu
/// düğme olarak okur. [tehlike] ise ikon ve başlık hata renginde (hesap sil,
/// çıkış yap).
class ProfilSatiri extends StatelessWidget {
  const ProfilSatiri({
    super.key,
    required this.ikon,
    required this.baslik,
    this.altBaslik,
    this.onTap,
    this.sag,
    this.ok = true,
    this.tehlike = false,
  });

  final IconData ikon;
  final String baslik;
  final String? altBaslik;
  final VoidCallback? onTap;

  /// Sağdaki öğe (ör. anahtar). Verilirse ok çizilmez.
  final Widget? sag;

  /// Dokunulabilir satırda sağda ok gösterilsin mi.
  final bool ok;
  final bool tehlike;

  static const double enKucukYukseklik = 56;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;
    final ustUste = profilUstUsteMi(context);

    final kutu = ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tehlike ? r.hataZemin : r.seciliCipZemin,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          ikon,
          size: 22,
          color: tehlike ? r.hataZeminYazi : r.seciliCipYazi,
        ),
      ),
    );

    final sagOge = sag ??
        (onTap != null && ok
            ? ExcludeSemantics(
                child: Icon(Icons.chevron_right_rounded, color: r.solukYazi),
              )
            : null);

    final satir = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: enKucukYukseklik),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (!ustUste) ...[kutu, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    baslik,
                    style: yazi.titleMedium?.copyWith(
                      color: tehlike ? r.hata : r.anaYazi,
                    ),
                  ),
                  if (altBaslik != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      altBaslik!,
                      style: yazi.bodyMedium?.copyWith(color: r.solukYazi),
                    ),
                  ],
                ],
              ),
            ),
            if (sagOge != null) ...[const SizedBox(width: 8), sagOge],
          ],
        ),
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: onTap != null && sag == null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, child: satir),
        ),
      ),
    );
  }
}

/// Anahtarlı ayar satırı (koyu mod). Satırın tamamına dokunmak da değiştirir.
class ProfilAnahtarSatiri extends StatelessWidget {
  const ProfilAnahtarSatiri({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.deger,
    required this.onDegisti,
  });

  final IconData ikon;
  final String baslik;
  final bool deger;
  final ValueChanged<bool> onDegisti;

  @override
  Widget build(BuildContext context) {
    return ProfilSatiri(
      ikon: ikon,
      baslik: baslik,
      onTap: () => onDegisti(!deger),
      sag: Switch(value: deger, onChanged: onDegisti),
    );
  }
}

/// Sayfanın altındaki uygulama adı, sürüm ve telif satırı.
class ProfilAltBilgi extends StatelessWidget {
  const ProfilAltBilgi({
    super.key,
    required this.uygulamaAdi,
    required this.surum,
    required this.telif,
  });

  final String uygulamaAdi;
  final String surum;
  final String telif;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final yazi = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          uygulamaAdi,
          textAlign: TextAlign.center,
          style: yazi.titleMedium?.copyWith(color: r.anaYazi),
        ),
        const SizedBox(height: 4),
        Text(
          surum,
          textAlign: TextAlign.center,
          style: yazi.bodyMedium?.copyWith(color: r.solukYazi),
        ),
        const SizedBox(height: 4),
        Text(
          telif,
          textAlign: TextAlign.center,
          style: yazi.bodySmall?.copyWith(color: r.solukYazi),
        ),
      ],
    );
  }
}

/// Profil sekmesinin tamamı. Veri ve işlemler [ProfilSayfasi]'den gelir;
/// böylece ekran Firebase olmadan test edilebilir.
///
/// Sıra: başlık, hesap kartı (ya da giriş kartı), ardından ayarlar listesi:
/// Premium, Ayarlar (koyu mod, dil), Hesap Yönetimi (yalnızca girişliyken),
/// Uygulama Bilgileri, Yasal & Gizlilik ve alt bilgi. Özet ya da sayı yok
/// (Sude kararı, 2026-11-10).
class ProfilGorunumu extends StatelessWidget {
  const ProfilGorunumu({
    super.key,
    required this.hesap,
    required this.proKullanici,
    required this.koyuMod,
    required this.dilAdi,
    required this.surum,
    required this.onKoyuMod,
    required this.onDil,
    required this.onPremium,
    required this.onAbonelikYonet,
    required this.onGeriYukle,
    required this.onGiris,
    required this.onYedekle,
    required this.onCikis,
    required this.onHesapSil,
    required this.onDegerlendir,
    required this.onGizlilik,
    required this.onKosullar,
    this.onGizlilikSecenekleri,
  });

  /// Giriş yoksa `null`.
  final ProfilHesap? hesap;
  final bool proKullanici;
  final bool koyuMod;
  final String dilAdi;
  final String surum;

  final ValueChanged<bool> onKoyuMod;
  final VoidCallback onDil;
  final VoidCallback onPremium;
  final VoidCallback onAbonelikYonet;
  final VoidCallback onGeriYukle;
  final VoidCallback onGiris;
  final VoidCallback onYedekle;
  final VoidCallback onCikis;
  final VoidCallback onHesapSil;
  final VoidCallback onDegerlendir;
  final VoidCallback onGizlilik;
  final VoidCallback onKosullar;

  /// Yalnızca AB'de reklam onayı gerekiyorsa verilir; yoksa satır çıkmaz.
  final VoidCallback? onGizlilikSecenekleri;

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    const bosluk = SizedBox(height: 24);
    final hesap = this.hesap;

    return AnnotatedRegion(
      value: kilDurumCubuguStili(context),
      child: Scaffold(
        backgroundColor: r.zemin,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: profilBaslikSiniri,
                child: Semantics(
                  header: true,
                  child: Text(
                    'tab_profile'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: r.baslik),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (hesap != null)
                ProfilHesapKarti(
                  hesap: hesap,
                  yedekAd: 'settings_user_fallback'.tr(),
                )
              else
                ProfilGirisKarti(
                  baslik: 'settings_login_register'.tr(),
                  aciklama: 'settings_login_subtitle'.tr(),
                  dugmeEtiketi: 'auth_button_login'.tr(),
                  onGiris: onGiris,
                ),
              bosluk,
              // Premium
              ProyaGecKarti(
                baslik: proKullanici
                    ? 'settings_premium_active_title'.tr()
                    : 'settings_premium_get_title'.tr(),
                aciklama: proKullanici
                    ? 'settings_premium_active_subtitle'.tr()
                    : 'settings_premium_get_subtitle'.tr(),
                aktif: proKullanici,
                onTap: proKullanici ? null : onPremium,
              ),
              const SizedBox(height: 12),
              ProfilBolumu(
                satirlar: [
                  if (proKullanici)
                    ProfilSatiri(
                      ikon: Icons.settings_suggest_outlined,
                      baslik: 'settings_premium_manage'.tr(),
                      onTap: onAbonelikYonet,
                    )
                  else
                    ProfilSatiri(
                      ikon: Icons.restore_rounded,
                      baslik: 'settings_premium_restore'.tr(),
                      onTap: onGeriYukle,
                      ok: false,
                    ),
                ],
              ),
              bosluk,
              ProfilBolumu(
                baslik: 'settings_title'.tr(),
                satirlar: [
                  ProfilAnahtarSatiri(
                    ikon: Icons.dark_mode_outlined,
                    baslik: 'settings_dark_mode'.tr(),
                    deger: koyuMod,
                    onDegisti: onKoyuMod,
                  ),
                  ProfilSatiri(
                    ikon: Icons.language_rounded,
                    baslik: 'settings_language_title'.tr(),
                    altBaslik: dilAdi,
                    onTap: onDil,
                  ),
                ],
              ),
              if (hesap != null) ...[
                bosluk,
                ProfilBolumu(
                  baslik: 'settings_account_title'.tr(),
                  satirlar: [
                    ProfilSatiri(
                      ikon: Icons.cloud_upload_outlined,
                      baslik: 'settings_backup'.tr(),
                      altBaslik: 'settings_backup_subtitle'.tr(),
                      onTap: onYedekle,
                      ok: false,
                    ),
                    ProfilSatiri(
                      ikon: Icons.logout_rounded,
                      baslik: 'settings_logout'.tr(),
                      onTap: onCikis,
                      ok: false,
                      tehlike: true,
                    ),
                    ProfilSatiri(
                      ikon: Icons.delete_forever_outlined,
                      baslik: 'settings_delete_account'.tr(),
                      altBaslik: 'settings_delete_account_subtitle'.tr(),
                      onTap: onHesapSil,
                      ok: false,
                      tehlike: true,
                    ),
                  ],
                ),
              ],
              bosluk,
              ProfilBolumu(
                baslik: 'settings_app_info_title'.tr(),
                satirlar: [
                  ProfilSatiri(
                    ikon: Icons.info_outline_rounded,
                    baslik: 'settings_version'.tr(),
                    altBaslik: surum,
                  ),
                  ProfilSatiri(
                    ikon: Icons.person_outline_rounded,
                    baslik: 'settings_developer'.tr(),
                    altBaslik: 'Sude Kazan',
                  ),
                  ProfilSatiri(
                    ikon: Icons.mail_outline_rounded,
                    baslik: 'settings_contact'.tr(),
                    altBaslik: 'sudekazan1907@gmail.com',
                  ),
                  ProfilSatiri(
                    ikon: Icons.star_outline_rounded,
                    baslik: 'settings_rate_app'.tr(),
                    altBaslik: 'settings_rate_app_subtitle'.tr(),
                    onTap: onDegerlendir,
                  ),
                ],
              ),
              bosluk,
              ProfilBolumu(
                baslik: 'settings_legal_title'.tr(),
                satirlar: [
                  ProfilSatiri(
                    ikon: Icons.privacy_tip_outlined,
                    baslik: 'settings_privacy_policy'.tr(),
                    altBaslik: 'settings_privacy_policy_subtitle'.tr(),
                    onTap: onGizlilik,
                  ),
                  ProfilSatiri(
                    ikon: Icons.description_outlined,
                    baslik: 'settings_terms_of_use'.tr(),
                    altBaslik: 'settings_terms_of_use_subtitle'.tr(),
                    onTap: onKosullar,
                  ),
                  if (onGizlilikSecenekleri != null)
                    ProfilSatiri(
                      ikon: Icons.shield_outlined,
                      baslik: 'settings_privacy_options'.tr(),
                      onTap: onGizlilikSecenekleri,
                    ),
                ],
              ),
              const SizedBox(height: 28),
              ProfilAltBilgi(
                uygulamaAdi: 'settings_footer_app_name'.tr(),
                surum: '${'settings_footer_version_prefix'.tr()} $surum',
                telif: 'settings_footer_copyright'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
