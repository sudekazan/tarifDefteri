# Not: AndroidX, Firebase, Google Play Services ve Flutter eklentileri kendi
# consumer ProGuard kurallarını AAR içinde getirir. Bu paketler için toplu
# "-keep ... { *; }" kuralı eklemeyin; aksi halde kod karartma (obfuscation)
# oranı düşer ve Play Console "DEX kodu optimizasyonu" uyarısı verir.

# Crash raporlarında okunabilir stack trace için
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Uygulama paketi (yalnızca MainActivity içeriyor, küçük)
-keep class com.sudekazan.** { *; }

-dontwarn androidx.**
-dontwarn com.google.**

# Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# RevenueCat (ödeme akışı; güvenli tarafta kalmak için korunuyor)
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**
