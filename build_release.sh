#!/bin/bash

# Tarif Defteri - Release Build Script
# Bu script icon tree shaking sorununu çözer

echo "🚀 Tarif Defteri Build Başlatılıyor..."
echo ""

# Temiz derleme yalnızca istenirse: ./build_release.sh --clean
# (Her seferinde clean yapmak önbelleği siler, derlemeyi uzatır.)
if [ "$1" == "--clean" ]; then
    echo "🧹 Build temizleniyor..."
    flutter clean
    echo ""
fi

# Pub get
echo "📦 Paketler indiriliyor..."
flutter pub get
echo ""

# Build appbundle
echo "📱 App Bundle oluşturuluyor..."
flutter build appbundle --no-tree-shake-icons

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build başarılı!"
    echo "📦 Dosya: build/app/outputs/bundle/release/app-release.aab"
else
    echo ""
    echo "❌ Build başarısız!"
    exit 1
fi
