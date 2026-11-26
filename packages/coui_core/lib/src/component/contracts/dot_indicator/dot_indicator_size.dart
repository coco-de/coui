/// DotIndicator-specific size variants.
///
/// Confirmed against the designer's `DotIndicator` set (`Size=sm|md|lg`).
/// Not `CoreComponentSize` — the ladder is three rungs, and a dedicated
/// enum keeps the `defaultsBySize` map literal exhaustive over exactly the
/// members the canvas offers (Progress / Fab / Status use dedicated enums
/// for the same reason).
library;

/// Size options for a `DotIndicator`.
///
/// Each rung sets both the dot diameter and the gap between dots — the
/// two dimensions the designer's set binds per size (`size/N` and
/// `space/N` with the same `N`). Padding around the group does not vary.
enum CoreDotIndicatorSize {
  /// `sm` — 6px dots, 6px apart.
  sm,

  /// `md` — 8px dots, 8px apart. The default.
  md,

  /// `lg` — 12px dots, 12px apart.
  lg;

  /// Widget default size. Flutter / Web `DotIndicator` constructors
  /// reference this so neither platform diverges silently.
  static const CoreDotIndicatorSize defaultSize = md;
}
