/// SSR stub for [PaginationFitMeasurer].
///
/// There is no layout to measure off the client, so the server renders
/// the row's first (full) step and the client measurer narrows it after
/// hydration.
library;

/// Stub implementation of [PaginationFitMeasurer] used during SSR.
class PaginationFitMeasurer {
  /// Creates a [PaginationFitMeasurer].
  ///
  /// Parameters mirror the web implementation's signature for API parity
  /// but are ignored on non-web targets.
  PaginationFitMeasurer({required this.probeId, required this.onStep});

  /// `id` of the probe `<div>` — unused off the client.
  final String probeId;

  /// Receives the step to show — never called off the client.
  final void Function(int step) onStep;

  /// No-op on non-web platforms.
  void sync() {}

  /// No-op on non-web platforms.
  void dispose() {}
}
