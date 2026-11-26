import 'package:coui_core/src/component/contracts/text_field/text_field_variant.dart';

/// TextArea-specific visual variants.
///
/// Identifies the field semantically (normal vs validation error). The
/// error axis is driven by `errorText != null` at the widget, but an area
/// wears [error] only while it is also enabled — `disabled > error`, see
/// [CoreTextFieldVariant.showsErrorChrome]. This enum keys the Core token
/// tables / Theme `variantStyles`.
///
/// `CoreTextAreaStyle.defaultsByVariant` is keyed by this enum. It used to
/// be keyed by a bare `bool`; code that indexed that table directly goes
/// through [of] now (`defaultsByVariant[CoreTextAreaVariant.of(hasError:
/// …)]`). Widget call sites are unaffected — `TextArea` still takes only
/// `errorText`.
///
/// Mirrors [CoreTextFieldVariant] deliberately: the two components state
/// the same two poses through the same public surface (`errorText`), and
/// a table keyed by a bare `bool` on one of them and by an enum on the
/// other is the same concept spelled two ways. It also cost something
/// concrete — the Figma exporter promotes a `Core{Name}Variant` enum to
/// a canvas axis and nothing else, so the twelve error members the
/// designer drew for TextArea had nowhere in code to land while the
/// identical members for TextField did.
enum CoreTextAreaVariant {
  /// Default input styling.
  defaultVariant,

  /// Error/validation error styling.
  error,

  /// A tinted fill instead of a drawn edge (#5747) — mirrors
  /// [CoreTextFieldVariant.filled].
  filled;

  /// Widget default variant. Flutter / Web `TextArea` reference this
  /// single source so neither platform silently diverges.
  static const CoreTextAreaVariant defaultTextAreaVariant = defaultVariant;

  /// The variant whose chrome an area paints, given whether it currently
  /// holds an error and whether it is enabled.
  ///
  /// [error] only when [CoreTextFieldVariant.showsErrorChrome] says so —
  /// `errorText != null` and enabled. The order lives there, shared with
  /// `TextField`, so both resolvers ask it rather than each spelling the
  /// mapping itself.
  ///
  /// Otherwise the caller's [variant] (#5747 — `TextArea` takes one now, so
  /// a filled area exists), or [defaultVariant].
  static CoreTextAreaVariant of({
    required bool hasError,
    bool enabled = true,
    CoreTextAreaVariant? variant,
  }) =>
      CoreTextFieldVariant.showsErrorChrome(
        hasError: hasError,
        enabled: enabled,
      )
      ? error
      : (variant ?? defaultVariant);
}
