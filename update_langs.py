import json
import glob

new_keys = {
    "shopping_list_title": "Alışveriş Listesi",
    "shopping_list_add_hint": "Yeni malzeme ekle...",
    "shopping_list_todo": "Alınacaklar",
    "shopping_list_done": "Alınanlar",
    "recipe_detail_add_to_cart": "Alışveriş Listesine Ekle"
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
