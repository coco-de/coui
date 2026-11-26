/// Platform-independent layout for `Alert`.
library;

/// How an `Alert` arranges its content.
///
/// The choice changes the structure as well as the measurements, so it is a
/// widget parameter rather than a Style field: [inline] draws no description
/// at all. Fill, radius and the tone glyph colour come from the variant in
/// both layouts — the layout decides how much of the message is shown and
/// how much room it takes, the variant decides what it says about severity.
enum CoreAlertLayout {
  /// A panel: the tone glyph (or the `leading` slot), a title line and an
  /// optional description below it, held open to a minimum height so a list
  /// of alerts stays on one rhythm whether or not each carries a
  /// description.
  stacked,

  /// A one-line status strip: the `leading` slot (or the tone glyph at a
  /// smaller size), the title as one line of body text that ellipsizes when
  /// it runs out of room, and the `action` slot after it. No minimum height
  /// — the strip is as tall as its content. The description is not drawn;
  /// the title stays the accessible name, so it is announced in full even
  /// when the line is cut short on screen.
  inline;

  /// Widget default layout — the Flutter / Web `Alert` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreAlertLayout defaultLayout = stacked;

  /// How many lines the title may take before it ends in an ellipsis, or
  /// `null` to let it wrap freely.
  ///
  /// A behaviour of the layout rather than a design value, so it is not a
  /// Style field: both platforms read it from here (Flutter as `maxLines`,
  /// Web as the one-line `truncate`) and neither restates the number. Only
  /// `null` and `1` are stated, because `truncate` can express no other cap.
  int? get titleMaxLines => switch (this) {
    stacked => null,
    inline => 1,
  };
}
