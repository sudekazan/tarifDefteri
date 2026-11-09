import 'package:flutter/material.dart';

import '../../theme/kil_renkleri.dart';

/// Alttan açılan kil penceresi. Üstte tutamak, isteğe bağlı Caveat başlık.
///
/// Açmak için: `KilAltSayfa.goster(context, baslik: ..., builder: ...)`.
/// Klavye açılınca içerik yukarı kayar.
class KilAltSayfa extends StatelessWidget {
  const KilAltSayfa({
    super.key,
    required this.child,
    this.baslik,
    this.dolgu = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

  final Widget child;
  final String? baslik;
  final EdgeInsetsGeometry dolgu;

  static Future<T?> goster<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? baslik,
    bool kapatilabilir = true,
    EdgeInsetsGeometry dolgu = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: kapatilabilir,
      enableDrag: kapatilabilir,
      showDragHandle: false,
      backgroundColor: context.kil.kart,
      builder: (sayfaContext) => KilAltSayfa(
        baslik: baslik,
        dolgu: dolgu,
        child: builder(sayfaContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.kil;
    final klavye = MediaQuery.viewInsetsOf(context).bottom;
    final baslikStili =
        Theme.of(context).textTheme.headlineSmall?.copyWith(color: r.baslik);

    return Padding(
      padding: EdgeInsets.only(bottom: klavye),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: r.tanitanKenar,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            if (baslik != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Semantics(
                  header: true,
                  child: Text(baslik!, style: baslikStili),
                ),
              ),
            Flexible(child: Padding(padding: dolgu, child: child)),
          ],
        ),
      ),
    );
  }
}
