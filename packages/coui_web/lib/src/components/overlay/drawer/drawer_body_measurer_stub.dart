/// SSR stub for [DrawerBodyMeasurer].
///
/// There is no layout to measure off the web, so the body is never
/// reported as fitting and keeps the browser's own touch behaviour.
library;

/// Stub implementation of [DrawerBodyMeasurer] used during SSR.
class DrawerBodyMeasurer {
  /// Creates a [DrawerBodyMeasurer]. The values mirror the web
  /// implementation's and are never read — the stub never touches the DOM.
  const DrawerBodyMeasurer({
    required this.bodyId,
    required this.horizontal,
    required this.onFitsChanged,
  });

  /// `id` of the body `<div>` the web implementation measures.
  final String bodyId;

  /// Whether the drawer slides horizontally.
  final bool horizontal;

  /// Never called off the web.
  final void Function({required bool fits}) onFitsChanged;

  /// No-op on non-web platforms.
  void attach() {}

  /// No-op on non-web platforms.
  void dispose() {}
}
