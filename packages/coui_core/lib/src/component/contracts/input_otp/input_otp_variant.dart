/// `InputOtp`-specific visual variants.
///
/// Identifies the field semantically (normal vs validation error). The
/// error axis is driven by `errorText != null` at the widget; this enum
/// keys `CoreInputOtpStyle.defaultsByVariant` / `CoreInputOtpTheme
/// .variantStyles` — the same idiom as `CoreTextFieldVariant`.
enum CoreInputOtpVariant {
  /// Default cell styling.
  defaultVariant,

  /// Error/validation error styling — cell border (and focus ring)
  /// switch to the `error` token.
  error;

  /// Widget default variant. Flutter / Web `InputOtp` reference this
  /// single source so neither platform silently diverges.
  static const CoreInputOtpVariant defaultInputOtpVariant = defaultVariant;
}
