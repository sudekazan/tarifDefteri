import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kil bileşenlerinin ortak dokunma davranışı: basılı hali, klavye/odak ve
/// "hareketi azalt" ayarına göre animasyon süresi.
///
/// Anlam (düğme, seçili, işaretli) bilgisini çağıran bileşen kendi
/// `Semantics` sarmalayıcısıyla verir.
class KilBasilir extends StatefulWidget {
  const KilBasilir({
    super.key,
    required this.onTap,
    required this.builder,
  });

  final VoidCallback? onTap;

  /// [basili]: parmak üzerindeyken true. [odakli]: klavye odağı görünürken true.
  final Widget Function(BuildContext context, bool basili, bool odakli) builder;

  /// Basılma ve seçim geçişlerinin süresi (plan: 150–200 ms).
  static const Duration gecisSuresi = Duration(milliseconds: 160);

  /// Kısa bir dokunuşta basılı halin en az bu kadar görünmesi.
  static const Duration enKisaBasili = Duration(milliseconds: 90);

  /// "Hareketi azalt" açıksa sıfır, değilse [gecisSuresi].
  static Duration sure(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : gecisSuresi;

  @override
  State<KilBasilir> createState() => _KilBasilirState();
}

class _KilBasilirState extends State<KilBasilir> {
  bool _basili = false;
  bool _odakli = false;
  DateTime? _basmaAni;
  Timer? _birakmaZamanlayici;

  bool get _etkin => widget.onTap != null;

  void _bas() {
    _birakmaZamanlayici?.cancel();
    _basmaAni = DateTime.now();
    if (!_basili) setState(() => _basili = true);
  }

  void _birak() {
    final gecen = _basmaAni == null
        ? KilBasilir.enKisaBasili
        : DateTime.now().difference(_basmaAni!);
    final kalan = KilBasilir.enKisaBasili - gecen;
    if (kalan <= Duration.zero || KilBasilir.sure(context) == Duration.zero) {
      if (_basili) setState(() => _basili = false);
      return;
    }
    _birakmaZamanlayici?.cancel();
    _birakmaZamanlayici = Timer(kalan, () {
      if (mounted && _basili) setState(() => _basili = false);
    });
  }

  @override
  void didUpdateWidget(KilBasilir oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_etkin && _basili) _basili = false;
  }

  @override
  void dispose() {
    _birakmaZamanlayici?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: _etkin,
      mouseCursor: _etkin ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (deger) => setState(() => _odakli = deger),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _etkin ? (_) => _bas() : null,
        onTapUp: _etkin ? (_) => _birak() : null,
        onTapCancel: _etkin ? _birak : null,
        onTap: widget.onTap,
        child: widget.builder(context, _basili && _etkin, _odakli && _etkin),
      ),
    );
  }
}
