/// Semantic text element type rendered by a unified text-block
/// component.
///
/// Web binds each value to the matching semantic HTML element (`<p>`,
/// `<h1>` … `<h6>`, `<blockquote>`, etc.) so screen readers and the
/// document outline stay correct. Flutter reads the same value twice —
/// once for typography, and once for [headingLevel], which is what puts
/// the heading into the accessibility tree.
enum CoreTextBlockElement {
  /// Paragraph element (`<p>`).
  p,

  /// Inline span element (`<span>`).
  span,

  /// Heading level 1 (`<h1>`).
  h1,

  /// Heading level 2 (`<h2>`).
  h2,

  /// Heading level 3 (`<h3>`).
  h3,

  /// Heading level 4 (`<h4>`).
  h4,

  /// Heading level 5 (`<h5>`).
  h5,

  /// Heading level 6 (`<h6>`).
  h6,

  /// Blockquote element (`<blockquote>`).
  blockquote,

  /// Preformatted text element (`<pre>`).
  pre,

  /// Label element (`<label>`).
  label,

  /// Strong importance element (`<strong>`).
  strong,

  /// Emphasis element (`<em>`).
  em,

  /// Small print element (`<small>`).
  small;

  /// Widget default element. Flutter / Web text-block components
  /// reference this so the default never silently diverges.
  static const CoreTextBlockElement defaultElement = p;

  /// The outline depth this element states, or null when it states none.
  ///
  /// 1–6 is the shared vocabulary of `<h1>`…`<h6>`, `aria-level` and
  /// Flutter's `Semantics.headingLevel` alike, so the mapping lives on
  /// the enum rather than in either platform's adapter.
  ///
  /// Null, never zero. Flutter asserts a heading level is either absent
  /// or within 1–6, so a non-heading returning `0` throws at the point
  /// the semantics are applied rather than reading as "not a heading".
  int? get headingLevel => switch (this) {
    h1 => 1,
    h2 => 2,
    h3 => 3,
    h4 => 4,
    h5 => 5,
    h6 => 6,
    p || span || blockquote || pre || label || strong || em || small => null,
  };

  /// The heading element of outline depth [level] — the inverse of
  /// [headingLevel], for components that take the depth as a number
  /// (`PageHeader.headingLevel`) and render it through this element
  /// vocabulary, so `<h1>`…`<h6>` stays mapped in one place.
  ///
  /// A depth outside 1–6 lands on the nearest heading rather than
  /// throwing: the widgets assert the range at construction, and a release
  /// build that slips past the assert still renders a heading.
  static CoreTextBlockElement heading(int level) => switch (level) {
    <= 1 => h1,
    2 => h2,
    3 => h3,
    4 => h4,
    5 => h5,
    _ => h6,
  };
}
