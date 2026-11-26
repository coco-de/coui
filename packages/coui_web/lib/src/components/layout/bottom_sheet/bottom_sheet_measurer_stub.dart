/// SSR stub for `BottomSheetMeasurer`.
///
/// There is no DOM to measure during server rendering, so `attach` and
/// `dispose` are no-ops. The footer hairline's opacity falls back to `0`
/// through its CSS `var()` fallback — no line — which matches Flutter's
/// first frame before the scroll metrics arrive.
library;

/// Stub implementation of [BottomSheetMeasurer] used during SSR.
class BottomSheetMeasurer {
  /// Creates a [BottomSheetMeasurer].
  ///
  /// Parameters mirror the web implementation's signature for API parity;
  /// the stub never touches the DOM.
  const BottomSheetMeasurer({required this.viewportId, required this.footerId});

  /// `id` of the scrolling content viewport `<div>`.
  final String viewportId;

  /// `id` of the footer's area `<div>`, which carries the variable.
  final String footerId;

  /// No-op on non-web platforms.
  void attach() {}

  /// No-op on non-web platforms.
  void dispose() {}
}
