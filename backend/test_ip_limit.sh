#!/usr/bin/env bash
# IP sınırının kullanıcıları birbirinden ayırdığını doğrular.
# Kullanım: ./test_ip_limit.sh [BASE_URL]   (varsayılan: http://localhost:3000)
# Beklenen: 1.1.1.1 adresiyle 201. istek 429 döner; hemen ardından 2.2.2.2 ile istek 429 DÖNMEZ.
# Not: canlı sunucuda çalıştırma; o IP için bir saat boyunca gerçek sınırı tüketir.
set -euo pipefail
BASE="${1:-http://localhost:3000}"
URL="$BASE/api/generate-recipe"
req() { curl -s -o /dev/null -w '%{http_code}' -X POST "$URL" \
  -H "X-Forwarded-For: $1" -H 'Authorization: Bearer gecersiz' -H 'Content-Type: application/json' -d '{}'; }

for i in $(seq 1 200); do
  code=$(req 1.1.1.1)
  [ "$code" = 429 ] && { echo "HATA: $i. istekte erken 429"; exit 1; }
done
last=$(req 1.1.1.1)
other=$(req 2.2.2.2)
echo "1.1.1.1 için 201. istek: $last (beklenen 429)"
echo "2.2.2.2 için ilk istek: $other (beklenen 429 dışında, örn. 401)"
if [ "$last" = 429 ] && [ "$other" != 429 ]; then
  echo "TAMAM: IP sınırı kullanıcıları ayırıyor"
else
  echo "BAŞARISIZ"; exit 1
fi
