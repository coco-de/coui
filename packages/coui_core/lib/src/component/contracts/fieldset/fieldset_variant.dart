/// Fieldset visual variants.
library;

/// How a `Fieldset` draws the boundary of its group.
///
/// The variant decides the box — fill, edge, corner and inner padding. The
/// legend, the description and the fields are the same in all three; only
/// whether a box surrounds them changes.
enum CoreFieldsetVariant {
  /// A panel: a faint fill (`surface-container-low`) inside a hairline edge
  /// (`outline-subtle`). The default.
  filled,

  /// The hairline edge only — no fill.
  outlined,

  /// No box. The legend, the description and the fields sit directly on
  /// the page, set apart by whitespace.
  plain;

  /// Widget default variant — the Flutter / Web `Fieldset` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreFieldsetVariant defaultVariant = filled;
}
