/// SSR stub for `InputOtpScaleMeasurer`.
///
/// On non-web Dart targets there is no DOM to measure, so `attach` and
/// `dispose` are no-ops. The visual row renders at its intrinsic width —
/// matching Flutter's `FittedBox(fit: scaleDown)` before its first layout
/// pass; the web implementation applies the down-scale on hydration.
library;

/// Stub implementation of [InputOtpScaleMeasurer] used during SSR.
class InputOtpScaleMeasurer {
  /// Creates an [InputOtpScaleMeasurer].
  ///
  /// Parameters mirror the web implementation's signature for API parity
  /// but are ignored on non-web targets — the stub never touches the DOM.
  const InputOtpScaleMeasurer({required this.rowId});

  /// Id of the visual row, retained for API parity with the web implementation.
  final String rowId;

  /// No-op on non-web platforms.
  void attach() {}

  /// No-op on non-web platforms.
  void dispose() {}
}
