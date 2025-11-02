import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tarif_defteri/tarifler_data/klasor_data.dart';

class KlasorKayit extends StatefulWidget {
  const KlasorKayit({super.key});

  @override
  State<KlasorKayit> createState() => _KlasorKayitState();
}

class _KlasorKayitState extends State<KlasorKayit> {
  var tfklasorAdi = TextEditingController();
  int selectedIconCode = 0xe2c7; // Varsayılan: Icons.folder

  final List<IconData> iconOptions = [
    Icons.favorite, // Favori
    Icons.cake, // Tatlı/muffin
    Icons.fastfood, // Poğaça/atıştırmalık
    Icons.restaurant, // Yemek
    Icons.local_drink, // İçecek
    Icons.soup_kitchen, // Sulu yemek
    Icons.icecream, // Tatlı/dondurma
    Icons.lunch_dining, // Yemek tabağı
    Icons.bakery_dining, // Fırın/tatlı
    Icons.emoji_food_beverage, // Çay/kahve
  ];

  Future<void> klasorKaydet(String klasor_adi) async {
    print("Klasör Kayıt Edildi: ${klasor_adi}");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Klasör Kayıt"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column( mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Klasör İkonu Seç", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: iconOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final icon = iconOptions[index];
                    final isSelected = selectedIconCode == icon.codePoint;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIconCode = icon.codePoint;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[700]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(controller: tfklasorAdi,decoration: const InputDecoration(hintText: "Klasör Adı Giriniz"),),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(onPressed: (){
                  if (tfklasorAdi.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'klasorAdi': tfklasorAdi.text,
                      'iconCode': selectedIconCode,
                    });
                  }
                }, child:const  Text("Kaydet")),
              )
            ],
          ),
        ),
      )
    );
  }
}
