"""Ham mağaza ekranlarını yayına hazır görsele çevirir.

Her görselde üstte uygulama ikonu ve adı, iki satırlık başlık ve kısa bir
açıklama; altta cihaz çerçevesi içinde ekran olur. Renkler ve fontlar
uygulamanın kil paletinden (lib/theme/kil_renkleri.dart, assets/fonts).

Önce ham ekranlar üretilir:
    flutter test test_driver/magaza_goruntuleri/magaza_goruntuleri_test.dart
Sonra:
    python3 test_driver/magaza_goruntuleri/cercevele.py

Çıktı: build/magaza_yayin/<cihaz>/<dil>/<sıra>_<ad>.png
(asc.py upload --dir build/magaza_yayin/iphone ... ile uyumlu)
"""

import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

KOK = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
HAM = os.path.join(KOK, 'build', 'magaza_goruntuleri')
CIKTI = os.path.join(KOK, 'build', 'magaza_yayin')
FONT = os.path.join(KOK, 'assets', 'fonts')
IKON = os.path.join(KOK, 'ios', 'Runner', 'Assets.xcassets',
                    'AppIcon.appiconset', 'Icon-App-1024x1024@1x.png')

# Kil paleti (açık mod).
ZEMIN_UST = (255, 251, 235)   # #FFFBEB krem
ZEMIN_ALT = (255, 237, 213)   # #FFEDD5 şeftali
ANA_YAZI = (15, 23, 42)       # #0F172A
SOLUK_YAZI = (71, 85, 105)    # #475569
RENKLER = {
    'terrakota': (154, 52, 18),  # #9A3412
    'adacayi': (4, 120, 87),     # #047857 (krem zeminde büyük yazı için koyu adaçayı)
}
CERCEVE = (28, 27, 26)        # telefon kasası

# Cihazlar: ham klasör, tuval boyutu, ekran köşe yuvarlaklığı (ekran
# genişliğine oran), kasa kalınlığı (ekran genişliğine oran), kamera tipi.
CIHAZLAR = {
    'iphone': dict(ham='iphone_6.9', tuval=(1320, 2868), kose=0.125,
                   kasa=0.035, kamera='ada'),
    'ipad': dict(ham='ipad_13', tuval=(2064, 2752), kose=0.018,
                 kasa=0.022, kamera=None),
    # Google Play öne çıkarma için 9:16 ister.
    'android': dict(ham='android', tuval=(1080, 1920), kose=0.075,
                    kasa=0.03, kamera='delik'),
}

SS = 3  # kenar yumuşatma için maskeler bu kat büyük çizilir


def font(ad, boyut):
    return ImageFont.truetype(os.path.join(FONT, ad), int(boyut))


def yuvarlak_maske(boyut, yaricap):
    w, h = boyut
    m = Image.new('L', (w * SS, h * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        (0, 0, w * SS - 1, h * SS - 1), radius=yaricap * SS, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def zemin(boyut):
    w, h = boyut
    serit = Image.new('RGB', (1, h))
    for y in range(h):
        t = y / (h - 1)
        serit.putpixel((0, y), tuple(
            round(a + (b - a) * t) for a, b in zip(ZEMIN_UST, ZEMIN_ALT)))
    return serit.resize((w, h))


def sigdir(metin, ad, boyut, genislik):
    """Metin genişliğe sığana kadar fontu küçültür."""
    f = font(ad, boyut)
    while f.getlength(metin) > genislik and boyut > 10:
        boyut -= 2
        f = font(ad, boyut)
    return f


def sar(metin, f, genislik):
    satirlar, satir = [], ''
    for kelime in metin.split():
        deneme = (satir + ' ' + kelime).strip()
        if f.getlength(deneme) <= genislik:
            satir = deneme
        else:
            satirlar.append(satir)
            satir = kelime
    satirlar.append(satir)
    return satirlar


def cihaz_ciz(ekran, cihaz, hedef_yukseklik):
    """Ekranı kasa içine koyar; gölgesiyle birlikte RGBA döner."""
    ew, eh = ekran.size
    olcek = None
    kasa = cihaz['kasa']
    # Kasa dahil yükseklik hedefe eşit olsun.
    olcek = hedef_yukseklik / (eh + 2 * kasa * ew)
    sw, sh = round(ew * olcek), round(eh * olcek)
    k = round(kasa * sw)
    gw, gh = sw + 2 * k, sh + 2 * k
    ekran = ekran.resize((sw, sh), Image.LANCZOS)

    ic_r = round(cihaz['kose'] * sw)
    dis_r = ic_r + k

    govde = Image.new('RGBA', (gw, gh), (0, 0, 0, 0))
    govde.paste(Image.new('RGBA', (gw, gh), CERCEVE + (255,)),
                (0, 0), yuvarlak_maske((gw, gh), dis_r))
    # Kasanın kenarında ince açık çizgi (metal parlaklığı).
    ic = Image.new('RGBA', (gw - 4, gh - 4), (60, 58, 56, 255))
    govde.paste(ic, (2, 2), yuvarlak_maske((gw - 4, gh - 4), dis_r - 2))
    ic2 = Image.new('RGBA', (gw - 8, gh - 8), CERCEVE + (255,))
    govde.paste(ic2, (4, 4), yuvarlak_maske((gw - 8, gh - 8), dis_r - 4))
    govde.paste(ekran.convert('RGBA'), (k, k), yuvarlak_maske((sw, sh), ic_r))

    d = ImageDraw.Draw(govde)
    if cihaz['kamera'] == 'ada':
        aw, ah = round(sw * 0.286), round(sw * 0.084)
        x0, y0 = k + (sw - aw) // 2, k + round(sw * 0.025)
        ada = Image.new('RGBA', (aw, ah), (0, 0, 0, 255))
        govde.paste(ada, (x0, y0), yuvarlak_maske((aw, ah), ah // 2))
    elif cihaz['kamera'] == 'delik':
        r = round(sw * 0.022)
        cx, cy = k + sw // 2, k + round(sh * 0.0195)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(0, 0, 0, 255))

    # Yumuşak kil gölgesi: aşağı kaymış, bulanık.
    pay = round(gw * 0.12)
    golge = Image.new('RGBA', (gw + 2 * pay, gh + 2 * pay), (0, 0, 0, 0))
    gm = yuvarlak_maske((gw, gh), dis_r).point(lambda v: v * 0.30)
    golge.paste(Image.new('RGBA', (gw, gh), (124, 45, 18, 255)),
                (pay, pay + round(gw * 0.035)), gm)
    golge = golge.filter(ImageFilter.GaussianBlur(gw * 0.04))
    golge.alpha_composite(govde, (pay, pay))
    return golge, pay


def gorsel(cihaz_ad, dil, sira, metin, ekran_yolu):
    cihaz = CIHAZLAR[cihaz_ad]
    W, H = cihaz['tuval']
    tuval = zemin((W, H)).convert('RGBA')
    d = ImageDraw.Draw(tuval)
    kenar = round(W * 0.075)
    genislik = W - 2 * kenar
    # Tablet geniş; yazılar telefon boyutuna yakın kalsın.
    birim = min(W, H * 0.46)

    # Marka: ikon kutusu + "Tarifly" (Caveat, terrakota).
    y = round(H * 0.035)
    iks = round(birim * 0.075)
    ikon = Image.open(IKON).convert('RGBA').resize((iks, iks), Image.LANCZOS)
    kutu = Image.new('RGBA', (iks, iks), (0, 0, 0, 0))
    kutu.paste(ikon, (0, 0), yuvarlak_maske((iks, iks), round(iks * 0.24)))
    tuval.alpha_composite(kutu, (kenar, y))
    mf = font('Caveat-Bold.ttf', iks * 0.78)
    d.text((kenar + iks + round(iks * 0.25), y + iks / 2), 'Tarifly',
           font=mf, fill=RENKLER['terrakota'], anchor='lm')
    y += iks + round(birim * 0.055)

    ust, alt, aciklama = metin[0], metin[1], metin[2]
    f1 = sigdir(ust, 'Quicksand-Bold.ttf', birim * 0.088, genislik)
    f2 = sigdir(alt, 'Caveat-Bold.ttf', birim * 0.118, genislik)
    asc1 = f1.getmetrics()[0]
    d.text((kenar, y + asc1), ust, font=f1, fill=ANA_YAZI, anchor='ls')
    y += round(f1.size * 1.18)
    asc2 = f2.getmetrics()[0]
    d.text((kenar, y + asc2), alt, font=f2,
           fill=RENKLER[sira['renk']], anchor='ls')
    y += round(f2.size * 1.12 + birim * 0.025)

    # Açıklamaya hep iki satırlık yer ayrılır; böylece bir setteki bütün
    # görsellerde cihaz aynı boyda ve aynı yerde durur.
    f3 = font('Quicksand-Medium.ttf', birim * 0.036)
    for i, satir in enumerate(sar(aciklama, f3, genislik)[:2]):
        d.text((kenar, y + i * round(f3.size * 1.35) + f3.getmetrics()[0]),
               satir, font=f3, fill=SOLUK_YAZI, anchor='ls')
    y += 2 * round(f3.size * 1.35)

    # Cihaz: kalan alana sığar, altta biraz pay bırakır.
    ust_bosluk = y + round(H * 0.03)
    yukseklik = H - ust_bosluk - round(H * 0.035)
    ekran = Image.open(ekran_yolu).convert('RGB')
    cizim, pay = cihaz_ciz(ekran, cihaz, yukseklik)
    x = (W - cizim.width) // 2
    tuval.alpha_composite(cizim, (x, ust_bosluk - pay))

    hedef = os.path.join(CIKTI, cihaz_ad, dil, sira['ad'] + '.png')
    os.makedirs(os.path.dirname(hedef), exist_ok=True)
    tuval.convert('RGB').save(hedef, optimize=True)
    return hedef


def main():
    with open(os.path.join(os.path.dirname(__file__), 'basliklar.json'),
              encoding='utf-8') as f:
        veri = json.load(f)
    diller = sys.argv[1:] or list(veri['metinler'])
    eksik = []
    for dil in diller:
        for cihaz_ad, cihaz in CIHAZLAR.items():
            for i, sira in enumerate(veri['ekranlar']):
                yol = os.path.join(HAM, dil, cihaz['ham'], sira['ekran'] + '.png')
                if not os.path.exists(yol):
                    eksik.append(yol)
                    continue
                gorsel(cihaz_ad, dil, sira, veri['metinler'][dil][i], yol)
    print('Bitti:', CIKTI)
    if eksik:
        print('Ham ekranı olmayanlar:', *eksik, sep='\n  ')
        sys.exit(1)


if __name__ == '__main__':
    main()
