/// How the scrollable viewport responds to hit-testing events.
///
/// Mirrors Flutter's `HitTestBehavior` enum. On Web, [opaque] / [translucent]
/// both allow the viewport to receive pointer events (CSS default), while
/// [deferToChild] is approximated by disabling pointer events on the bare
/// root when the content area is empty.
enum CoreHitTestBehavior {
  /// Only receive pointer events where a child is hit.
  deferToChild,

  /// Always receive pointer events inside the bounds (opaque — children
  /// below the viewport cannot receive events).
  opaque,

  /// Always receive pointer events inside the bounds, but also let events
  /// fall through to siblings underneath.
  translucent,
}
