/// SSR stub for [OverflowMarqueeMeasurer].
///
/// On non-web Dart targets there is no DOM to measure, no `requestAnimationFrame`
/// loop to start, and no hover listeners to attach, so [attach] and
/// [dispose] are no-ops. The static mask in
/// `overflow_marquee_resolver.dart` falls back to `--co-om-fade-start-alpha: 1`
/// / `--co-om-fade-end-alpha: 0` via CSS `var()` fallbacks, which is the
/// same state Flutter draws at `progress == 0` — so an SSR snapshot
/// remains visually coherent even without the client measurer running.
library;

import 'package:coui_core/coui_core.dart';

/// Stub implementation of [OverflowMarqueeMeasurer] used during SSR.
class OverflowMarqueeMeasurer {
  /// Creates an [OverflowMarqueeMeasurer].
  ///
  /// Parameters mirror the web implementation's signature for API
  /// parity but are ignored on non-web targets — the stub never
  /// touches the DOM.
  const OverflowMarqueeMeasurer({
    required String containerId,
    required String trackSelector,
    required CoreAxis axis,
    required Duration duration,
    required Duration delayDuration,
    required double step,
    required double fadePortion,
    required CoreMarqueeCurve curve,
    required bool pauseOnHover,
  });

  /// No-op on non-web platforms.
  void attach() {}

  /// No-op on non-web platforms.
  void dispose() {}
}
