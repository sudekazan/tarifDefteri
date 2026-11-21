# Premium rozeti — kısa tasarım

Tarih: 2026-11-21 · Durum: onaylandı (Sude)

## Neden
Premium olmayan kullanıcılar, ana sayfada "Tarifly" başlığının hemen yanında duran "Premium" etiketini bir durum bilgisi sanıp kendilerini Premium zannediyor. Etiket aslında satın alma ekranını açan bir düğme.

## Kararlar (Sude)
1. Konum: başlık solda, etiket ekranın sağ kenarında.
2. Yazı: "Premium" yerine "Premium'a geç".

## Kararlar (Claude, itiraz edilmedi)
- Görünüm aynı kalır (dolu kapsül, taç simgesi).
- "Bugün ne pişirsem" ekranındaki aynı etiket de aynı şekilde değişir.
- Diğer diller: en "Go Premium", de "Premium holen", es "Hazte Premium", fr "Passer à Premium", pt "Seja Premium".
- Büyük yazıda yan yana sığmazsa etiket başlığın altına iner; başlık kısalmaz.
- Etiket yalnızca Premium olmayanlara görünür, dokununca satın alma ekranı açılır (değişmiyor).

## Yaklaşımlar
| | Yaklaşım | Sonuç |
|---|---|---|
| A | Yazıyı eyleme çevir, kenarlıklı düğme görünümü | Kısmen alındı: yalnızca yazı |
| B | Başlıktan ayır, listenin üstünde açıklamalı kart | Seçilmedi: fazla yer kaplar |
| C | Ana sayfadan kaldır | Seçilmedi: satın almalar düşebilir |
| **Seçilen** | Başlık solda, "Premium'a geç" sağ kenarda | Sude'nin önerisi |

## Kapsam dışı
Satın alma ekranı, fiyatlar, diğer Premium yönlendirmeleri, rozetin renk/stil değişikliği.
