/// Visual variants supported by `Card`.
///
/// Defined locally instead of reusing the 17-value `CoreComponentVariant`
/// so map / switch exhaustiveness checks are meaningful (Card only ever
/// uses two of those values).
library;

/// Variant of a `Card`.
///
/// Selects the per-variant row in `CoreCardStyle.defaultsByVariant`, which
/// fills `backgroundColor` / `borderColor` / `borderWidth` with the
/// appropriate scheme tokens.
enum CoreCardVariant {
  /// Surface background + `outlineVariant` hairline border + thin stroke.
  outlined,

  /// Filled chrome with `surfaceContainer` background and no visible border.
  ///
  /// The widget's default variant.
  filled;

  /// Widget default variant.
  ///
  /// Flutter and Web `Card` constructors both reference
  /// `CoreCardVariant.defaultVariant` so the two stay in lock-step.
  static const CoreCardVariant defaultVariant = filled;
}
