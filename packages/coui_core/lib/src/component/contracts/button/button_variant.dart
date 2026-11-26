import 'package:coui_core/src/component/behaviour_only.dart';

/// Button-specific visual variants.
///
/// Each variant maps to a distinct visual style in both Flutter and Web.
/// Flutter maps to theme-based decoration, Web maps to Tailwind CSS classes.
enum CoreButtonVariant {
  /// Primary brand action — filled background, high emphasis.
  primary,

  /// Secondary action — a pale (tonal) fill, medium emphasis. Reads as the
  /// quieter sibling of [primary] rather than a second dark button.
  secondary,

  /// Tonal brand action — a pale brand fill (`primaryContainer`) with a
  /// brand label (`onPrimaryContainer`). One step quieter than [primary]
  /// and one step more branded than [secondary]: the supporting action
  /// inside a card. Same structure and state rules as [secondary], with
  /// the brand container pair in place of the neutral one.
  tonal,

  /// Outlined border with transparent background.
  outline,

  /// Minimal visual weight — transparent background, subtle hover.
  ghost,

  /// Muted low-emphasis button: transparent fill, content (label / icon)
  /// rendered at reduced opacity that fades to full on hover — no fill or
  /// colour change. Used for dismiss (✕) / copy / quiet toolbar icons.
  plain,

  /// Destructive/dangerous action — error-colored.
  destructive,

  /// Menu item button.
  menu,

  /// Menu bar item button.
  menubar,

  /// The button that paints nothing.
  ///
  /// `CardImage` wraps a pressable card in one to get press, focus and the
  /// accessibility role while the card's own chrome shows through. Not a
  /// design choice — a designer picking it would get an invisible button —
  /// so it is off the Figma canvas, where it sat beside `primary` for months
  /// as if it were one.
  @behaviourOnly
  fixed,
}
