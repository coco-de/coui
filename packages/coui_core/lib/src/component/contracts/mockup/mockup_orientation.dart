/// Which way a `MockupDevice` is turned.
///
/// Orthogonal to `CoreMockupDevice`: the device says what hardware it is,
/// the orientation says which way it is held. A turned body carries its
/// buttons with it, so this axis decides which edge each button sits on —
/// it is not a restatement of the screen aspect, which states proportions
/// only and is read long-side-first.
enum CoreMockupOrientation {
  /// Held upright — the screen's long side runs vertically.
  portrait,

  /// Turned a quarter turn clockwise — the long side runs horizontally,
  /// and every button moves one edge along with it.
  landscape;

  /// Widget default orientation. Flutter / Web `MockupDevice` reference
  /// this single source so neither platform silently diverges.
  static const CoreMockupOrientation defaultOrientation = portrait;
}
