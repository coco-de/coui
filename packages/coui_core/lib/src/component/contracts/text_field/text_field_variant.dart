/// TextField-specific visual variants.
///
/// Identifies the field semantically (normal vs validation error). The
/// error axis is driven by `errorText != null` at the widget, but a field
/// wears [error] only while it is also enabled — `disabled > error`, see
/// [showsErrorChrome]. This enum keys the Core token tables / Theme
/// `variantStyles`.
enum CoreTextFieldVariant {
  /// Default input styling.
  defaultVariant,

  /// Error/validation error styling.
  error,

  /// A bare field — no box, no border, no fill — for an input that sits
  /// inside another surface's chrome (the search row of a `Command`
  /// palette, a menu's filter). The host draws the boundary; the field
  /// draws only its text and caret.
  plain,

  /// A tinted fill instead of a drawn edge (#5747) — for a field sitting on
  /// a surface that already frames it (a card, a sheet).
  filled;

  /// Widget default variant. Flutter / Web `TextField` reference this
  /// single source so neither platform silently diverges.
  static const CoreTextFieldVariant defaultTextFieldVariant = defaultVariant;

  /// Whether a field's error state reaches its box chrome — `disabled >
  /// error`.
  ///
  /// A disabled field is disabled first: a stale error must not paint its
  /// border, fill or Theme `variantStyles[error]` / `errorBorderColor`
  /// override over the disabled tokens. The two variant rows' disabled
  /// tokens happen to agree, but an override paints past them, so the row
  /// agreement alone never enforced the order. Same shape as Carbon's
  /// `!disabled && invalid`.
  ///
  /// This gates chrome only. The error message is content: the widget
  /// still shows it while disabled, and its style keeps reading the Theme
  /// error row.
  ///
  /// The single source for both text inputs — [CoreTextFieldVariant.of]
  /// and `CoreTextAreaVariant.of` ask it rather than each platform's
  /// resolver spelling the order itself.
  static bool showsErrorChrome({
    required bool hasError,
    required bool enabled,
  }) => hasError && enabled;

  /// The variant whose chrome a field paints, given whether it holds an
  /// error, whether it is enabled, and the caller's own [variant].
  ///
  /// [error] when [showsErrorChrome] says so; otherwise the caller's
  /// variant, or [defaultVariant].
  static CoreTextFieldVariant of({
    required bool hasError,
    bool enabled = true,
    CoreTextFieldVariant? variant,
  }) => showsErrorChrome(hasError: hasError, enabled: enabled)
      ? error
      : (variant ?? defaultVariant);
}
