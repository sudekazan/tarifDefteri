import json
import glob

new_keys = {
    "auth_register_success_verify": "Hesabınız oluşturuldu. Lütfen e-postanıza gönderilen doğrulama bağlantısına tıklayın.",
    "folders_rename": "Yeniden Adlandır",
    "folders_new_name": "Yeni İsim",
    "folders_move": "Klasöre Taşı",
    "folders_select_move": "Taşınacak Klasörü Seçin",
    "folders_move_success": "Tarif başarıyla taşındı.",
    "auth_reset_password_email_required": "Şifre sıfırlamak için geçerli bir e-posta adresi girin.",
    "auth_reset_password_success": "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.",
    "auth_forgot_password": "Şifremi Unuttum",
    "recipe_edit_edit_item": "Maddeyi Düzenle",
    "recipe_search_prompt": "Aramak istediğiniz tarifi yazın."
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
