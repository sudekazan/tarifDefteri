import json
import glob

new_keys = {
    "recipe_detail_cooking_mode": "Yemek Yapma Modu",
    "cooking_mode_ingredients": "Malzemeler",
    "cooking_mode_step": "Adım",
    "cooking_mode_steps": "Yapılışı"
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
