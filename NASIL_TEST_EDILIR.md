# 🧪 Tarif Kaybı Sorunu - Test Rehberi

## 📱 Test Senaryoları

### ✅ Test 1: Giriş Yapmadan Tarif Ekleme ve Sonra Giriş Yapma

**Amaç:** Giriş yapmadan eklenen tariflerin, giriş yapıldıktan sonra kaybolmadığını doğrulama

**Adımlar:**
1. Uygulamayı aç (giriş yapma)
2. Ana sayfada "+" butonuna bas ve yeni bir klasör oluştur (ör: "Tatlılar")
3. Klasörü aç ve 2-3 tarif ekle (ör: "Sütlaç", "Kazandibi")
4. Ana sayfaya dön ve tariflerin görüldğünü kontrol et
5. Ayarlar > Giriş Yap / Kayıt Ol
6. Yeni bir hesap oluştur (veya mevcut hesapla giriş yap)
7. **Beklenen:** Giriş başarılı mesajı göründükten sonra ana sayfada eklediğin tarifler hala görünmeli
8. **Beklenen:** "Tarifleriniz birleştirildi 🎉" mesajını görmelisin

**Sonuç:** ✅ BAŞARILI - Tarifler kaybolmadı

---

### ✅ Test 2: Farklı Cihazlarda Senkronizasyon

**Amaç:** Farklı cihazlardaki tariflerin birleştiğini doğrulama

**Adımlar:**

**Cihaz 1:**
1. Uygulamayı aç
2. 2 klasör oluştur: "Çorbalar", "Ana Yemekler"
3. Her klasöre 2 tarif ekle
4. Ayarlar > Giriş Yap
5. `test@example.com` hesabıyla giriş yap

**Cihaz 2:**
1. Uygulamayı aç
2. 2 klasör oluştur: "Salatalar", "İçecekler"
3. Her klasöre 2 tarif ekle
4. Ayarlar > Giriş Yap
5. `test@example.com` hesabıyla giriş yap (aynı hesap!)

**Beklenen Sonuç:**
- ✅ Cihaz 2'de tüm 4 klasör görünmeli (Çorbalar, Ana Yemekler, Salatalar, İçecekler)
- ✅ Her klasördeki tarifler korunmalı
- ✅ Hiçbir tarif kaybolmamalı

---

### ✅ Test 3: Çıkış Yap ve Tekrar Giriş Yap

**Amaç:** Çıkış yapıp tekrar giriş yapıldığında verilerin korunduğunu doğrulama

**Adımlar:**
1. Uygulamayı aç ve hesabınla giriş yap
2. 3 klasör ve 6 tarif ekle
3. Ayarlar > Çıkış Yap
4. Tekrar Ayarlar > Giriş Yap
5. Aynı hesapla giriş yap

**Beklenen:**
- ✅ Tüm klasörlerin ve tariflerin korunduğunu gör
- ✅ Hiçbir veri kaybı olmamalı

---

### ✅ Test 4: Klasör Oluşturma ve Tarif Birleştirme

**Amaç:** Yeni klasör oluştururken eski tariflerin yanlış klasöre gitmediğini doğrulama

**Adımlar:**
1. Giriş yapmadan 2 klasör oluştur: "Klasör A", "Klasör B"
2. Klasör A'ya 2 tarif ekle
3. Klasör B'ye 3 tarif ekle
4. Giriş yap
5. Yeni bir klasör oluştur: "Klasör C"

**Beklenen:**
- ✅ Klasör A'daki tarifler Klasör A'da kalmalı
- ✅ Klasör B'deki tarifler Klasör B'de kalmalı
- ✅ Klasör C boş olmalı
- ✅ Tarifler klasörler arasında karışmamalı

---

### ✅ Test 5: Offline/Online Senkronizasyon

**Amaç:** İnternet olmadan eklenen tariflerin online olunca senkronize edildiğini doğrulama

**Adımlar:**
1. Hesabınla giriş yap
2. İnterneti kapat (Airplane mode)
3. 2 tarif ekle
4. İnterneti aç
5. Uygulamayı kapat ve tekrar aç

**Beklenen:**
- ✅ Offline eklenen tarifler görünmeli
- ✅ Online olunca Firebase'e yüklenmiş olmalı

---

## 🔍 Debug İpuçları

### Console Logları

Giriş yaparken console'da şu mesajları görmelisin:

```
✅ Yerel ve cloud verileri başarıyla birleştirildi!
```

### Firebase Console Kontrol

1. Firebase Console'a git (https://console.firebase.google.com)
2. Projen > Firestore Database
3. `users/{userId}/tarifler` collection'ına bak
4. Tariflerin orada olduğunu kontrol et

### Hata Durumunda

Eğer tarifler hala kayboluyor gibi görünüyorsa:

1. **Uygulamayı tamamen kapat ve yeniden başlat**
2. **Cache temizle:**
   - Settings > Apps > Tarif Defteri > Clear Data (dikkat: tüm veriler silinir!)
3. **Console loglarını kontrol et:**
   - Android Studio'da Logcat'e bak
   - "firebase" veya "merge" kelimelerini ara

---

## 🎯 Başarı Kriterleri

Test başarılı sayılır eğer:

✅ Giriş yapmadan eklenen tarifler giriş yaptıktan sonra kaybolmuyorsa
✅ Farklı cihazlardaki tarifler birleşiyorsa
✅ Çıkış yapıp tekrar giriş yapıldığında veriler korunuyorsa
✅ Yeni klasör oluştururken tarifler karışmıyorsa
✅ Firebase Console'da veriler görünüyorsa

---

## 📞 Destek

Sorun yaşarsan:
1. `COZUM_DOKUMANI.md` dosyasını oku
2. Console loglarını kontrol et
3. Firebase Console'dan verileri kontrol et

---

**Güncelleme:** 20 Kasım 2024
**Durum:** ✅ ÇÖZÜLDÜ
