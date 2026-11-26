/// Which palette derivation a theme is built with.
///
/// This decides one thing: how a colour scheme fills in the tokens an
/// authored palette leaves open. It is not a switch between whole visual
/// languages — typography, motion, corner shape and surface treatment do
/// not follow from it.
///
/// The look of a surface is stated by a surface style recipe instead, which
/// reaches both platforms and declares what it costs in accessibility
/// terms. A system named here is a *starting palette*, not a promise about
/// the rest of the screen.
enum DesignSystem {
  /// CoUI: OKLch palette, tokens passed through as authored.
  coui,

  /// M3 Expressive: Material Design 3 tonal derivation — an unset container
  /// tone is interpolated from the base steps rather than left open.
  ///
  /// Names the palette only. Expressive typography and motion are not
  /// carried by this choice.
  m3Expressive,

  /// Liquid Glass: translucent-material palette derivation.
  ///
  /// Names the palette only. The translucent surface itself, and the
  /// accessibility contract that goes with it, live on the surface style of
  /// the same name.
  liquidGlass,
}
