/// Variants for `Stat`.
library;

/// Visual variant for `Stat` cards.
///
/// Selects the row in `CoreStatStyle.defaultsByVariant`, which fills the
/// card face and its border. The names match `CoreCardVariant`, so a stat
/// set beside a card of the same variant reads as the same material.
enum CoreStatVariant {
  /// Page-ground face with a 1px `outline-variant` border — the card is
  /// marked by its line. The widget's default variant.
  outlined,

  /// `surfaceContainer` face with no visible border — the card is marked
  /// by its tone.
  filled;

  /// Widget default variant. Flutter and Web `Stat` constructors
  /// reference this so silent divergence between platforms is
  /// impossible.
  static const CoreStatVariant defaultVariant = outlined;
}
