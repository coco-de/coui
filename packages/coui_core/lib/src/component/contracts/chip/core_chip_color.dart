/// Colour of the selected state for chip components.
library;

/// The colour a chip takes on when it is selected.
///
/// An unselected chip is colourless whatever its colour (a quiet hairline
/// and a neutral label), so this names the colour the chip *becomes*, not
/// the colour it rests in. Two shipped values are enough for that: the
/// achromatic one ([neutral]) and the brand colour ([primary]). Status
/// colours belong to `Badge`, not to a control the user toggles.
///
/// This is the enum behind `Chip.chipColor`. It is unrelated to the
/// `.secondary` / `.tertiary` getters on the `Chip` chain, which pick a
/// background colour token for one instance and name no value of this enum.
enum CoreChipColor {
  /// Custom color using a seed color.
  custom,

  /// Neutral chip — the selected fill is the inverse surface.
  neutral,

  /// Primary theme color chip.
  primary;

  /// Widget default chip color — the Flutter / Web `Chip`
  /// constructors reference this so the default cannot silently
  /// diverge between platforms.
  static const CoreChipColor defaultColor = neutral;
}
