/// The document attribute a Web page carries while a surface style is
/// active.
///
/// Lives here rather than beside the Web scope because the stylesheet that
/// writes rules for it, the switch that sets it, and any consumer that
/// reads it must all agree on one string — and a second spelling anywhere
/// is a silent no-op rather than an error.
const String kSurfaceStyleAttribute = 'data-coui-style';

/// Identifies a surface style preset.
///
/// A surface style is a theme axis: one choice that moves every component at
/// once. It is orthogonal to brightness — light and dark are both available
/// under any style — so the two combine as a matrix rather than a list.
enum CoreSurfaceStyleId {
  /// The baseline CoUI surface: opaque, stroke-bounded, flat.
  defaultStyle,

  /// Translucent surfaces with blur over arbitrary content.
  liquidGlass,

  /// Thick borders, hard offset shadows, vivid accents.
  neoBrutalism,

  /// Puffy rounded surfaces with a soft inset highlight rim. No colour
  /// shift — pastel is deliberately withheld (see `CoreSurfaceRecipe`
  /// for the contrast measurement behind that call).
  claymorphism,

  /// Surfaces the colour of the page, bounded only by dual shadow.
  neumorphism;

  /// The style used when a theme states none.
  static const CoreSurfaceStyleId defaultId = defaultStyle;
}
