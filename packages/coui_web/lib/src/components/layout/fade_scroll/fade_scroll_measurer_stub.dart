/// SSR stub for `FadeScrollMeasurer`.
///
/// On non-web Dart targets there is no DOM to listen to, so `attach` and
/// `dispose` are no-ops. The static mask in `fade_scroll_style.dart`
/// falls back to `--co-fade-start-alpha: 0` / `--co-fade-end-alpha: 1`
/// via CSS `var()` fallbacks — no leading fade, a trailing fade — which is
/// how Flutter's settled `FadeScroll` draws a viewport at rest whose
/// content runs past its end.
library;

import 'package:coui_core/coui_core.dart';

/// Stub implementation of [FadeScrollMeasurer] used during SSR.
class FadeScrollMeasurer {
  /// Creates a [FadeScrollMeasurer].
  ///
  /// Holds the same fields as the web implementation so both sides of the
  /// conditional import are the same shape; the stub never reads them —
  /// it never touches the DOM.
  const FadeScrollMeasurer({required this.viewportId, required this.direction});

  /// The `id` of the scroll viewport the web implementation measures.
  final String viewportId;

  /// The scroll axis the web implementation measures along.
  final CoreFadeScrollDirection direction;

  /// No-op on non-web platforms.
  void attach() {}

  /// No-op on non-web platforms.
  void dispose() {}
}
