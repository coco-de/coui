/// Tone of a `MenuItem` row.
library;

/// Whether a row is an ordinary action or a destructive one.
///
/// The tone moves the **foreground only** — label and glyphs — never the
/// hover / pressed wash (Button · Menu 개편 2026-09-08 §6-3 (c)). Moving
/// the wash too would give the row a second state-layer ramp, and under
/// forced colours the two tones would fold into one anyway. Because colour
/// is the only cue, the placement rule travels with it: a critical item is
/// the last of its group, usually behind a divider.
enum CoreMenuItemTone {
  /// An ordinary action.
  neutral,

  /// A destructive action — the label reads in the error colour.
  critical;

  /// Widget default. Both platform constructors reference this value.
  static const CoreMenuItemTone defaultTone = neutral;
}
