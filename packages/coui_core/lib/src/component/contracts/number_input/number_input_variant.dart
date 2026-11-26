/// Variants of the `NumberInput` component.
library;

/// How a `NumberInput`'s field is drawn.
///
/// The field is a composed `TextField`, so each value maps to the
/// `TextField` variant of the same name and the border, fill, hover and
/// focus chrome come from there — a `NumberInput` placed next to a
/// `TextField` reads the same.
enum CoreNumberInputVariant {
  /// Outlined field on the surface fill.
  defaultVariant,

  /// Field filled with the container tone; the border takes the fill's
  /// colour.
  filled,

  /// Field in the error state.
  error;

  /// The variant a `NumberInput` draws when the caller states none.
  /// Flutter and Web constructors both reference this single source.
  static const CoreNumberInputVariant defaultNumberInputVariant =
      defaultVariant;
}
