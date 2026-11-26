/// Semantic variants of a `Select` trigger.
library;

import 'package:coui_core/src/component/contracts/text_field/text_field_variant.dart';

/// Whether the trigger reads as an ordinary field or one carrying a
/// validation error.
///
/// Inherited from `TextField`'s model minus `plain` (Select 코드 인계
/// 통합본 2026-09-08 §2): a borderless select exists in none of the seven
/// systems surveyed, and a trigger with no box has no edge for its chevron
/// to sit against.
///
/// The error axis is driven by `errorText != null` at the widget, the way
/// `TextField` drives its own; this enum keys the Figma set and the theme's
/// `variantStyles`.
enum CoreSelectVariant {
  /// An ordinary field.
  defaultVariant,

  /// A field carrying a validation error — the `error` border, kept
  /// through focus (the kit's `TextField` keeps it there too).
  error,

  /// A tinted fill instead of a drawn edge (#5747) — the trigger takes
  /// [CoreTextFieldVariant.filled].
  filled;

  /// Widget default. Both platform constructors reference this value.
  static const CoreSelectVariant defaultSelectVariant = defaultVariant;

  /// The `TextField` variant the composed trigger takes.
  CoreTextFieldVariant toTextFieldVariant() => switch (this) {
    defaultVariant => CoreTextFieldVariant.defaultVariant,
    error => CoreTextFieldVariant.error,
    filled => CoreTextFieldVariant.filled,
  };
}
