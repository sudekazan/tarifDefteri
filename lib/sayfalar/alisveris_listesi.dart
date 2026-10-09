import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class AlisverisListesi extends StatefulWidget {
  const AlisverisListesi({Key? key}) : super(key: key);

  @override
  State<AlisverisListesi> createState() => _AlisverisListesiState();
}

class _AlisverisListesiState extends State<AlisverisListesi> {
  List<String> _alinacaklar = [];
  List<String> _alinanlar = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _alinacaklar = prefs.getStringList('shopping_list_todo') ?? [];
      _alinanlar = prefs.getStringList('shopping_list_done') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _kaydet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shopping_list_todo', _alinacaklar);
    await prefs.setStringList('shopping_list_done', _alinanlar);
  }

  void _ekle(String madde) {
    if (madde.trim().isNotEmpty) {
      setState(() {
        _alinacaklar.insert(0, madde.trim());
      });
      _controller.clear();
      _kaydet();
    }
  }

  void _sil(String madde, bool isDone) {
    setState(() {
      if (isDone) {
        _alinanlar.remove(madde);
      } else {
        _alinacaklar.remove(madde);
      }
    });
    _kaydet();
  }

  void _toggleDurum(String madde, bool isDone) {
    setState(() {
      if (isDone) {
        _alinanlar.remove(madde);
        _alinacaklar.insert(0, madde);
      } else {
        _alinacaklar.remove(madde);
        _alinanlar.insert(0, madde);
      }
    });
    _kaydet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('shopping_list_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              setState(() {
                _alinanlar.clear();
              });
              _kaydet();
            },
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'shopping_list_add_hint'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: _ekle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 40),
                        color: Theme.of(context).primaryColor,
                        onPressed: () => _ekle(_controller.text),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (_alinacaklar.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'shopping_list_todo'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ..._alinacaklar.map((madde) => ListTile(
                        leading: Checkbox(
                          value: false,
                          onChanged: (val) => _toggleDurum(madde, false),
                        ),
                        title: Text(madde, style: const TextStyle(fontSize: 16)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => _sil(madde, false),
                        ),
                      )).toList(),
                      
                      if (_alinanlar.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'shopping_list_done'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ..._alinanlar.map((madde) => ListTile(
                        leading: Checkbox(
                          value: true,
                          onChanged: (val) => _toggleDurum(madde, true),
                        ),
                        title: Text(
                          madde,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => _sil(madde, true),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
