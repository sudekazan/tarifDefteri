import json
import glob

new_keys = {
    "premium_success": "Premium özellikler aktifleştirildi!",
    "premium_restored": "Satın alımlar geri yüklendi!",
    "premium_restore_failed": "Geri yüklenecek abonelik bulunamadı.",
    "premium_title": "Premium'a Geç",
    "premium_restore": "Geri Yükle",
    "premium_headline": "Tarif Defteri Pro ile Sınırları Kaldırın!",
    "premium_feature_ads": "Tüm reklamları kalıcı olarak kaldırın.",
    "premium_feature_ai": "Sınırsız yapay zeka ile tarif oluşturma.",
    "premium_feature_link": "İnternet linklerinden sınırsız tarif çekme.",
    "premium_no_packages": "Şu an paket bulunmamaktadır. Lütfen daha sonra tekrar deneyin.",
    "ai_limit_reached": "Günlük ücretsiz AI kullanım hakkınız doldu. Lütfen Premium'a geçin."
}

for filepath in glob.glob('assets/lang/*.json'):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    for k, v in new_keys.items():
        if k not in data:
            data[k] = v
            
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Updated {filepath}")
