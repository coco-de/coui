/// Alert-specific visual variants.
///
/// Each variant maps to a distinct visual style in both Flutter and Web.
/// Flutter maps to theme-based decoration, Web maps to Tailwind CSS classes.
///
/// Unlike `CoreBannerVariant` there is no second "how loudly" axis here:
/// an inline alert has no solid treatment in the design, and adding one
/// would double the table for combinations nothing renders.
enum CoreAlertVariant {
  /// Neutral variant — no tone, standard surface styling.
  ///
  /// This member used to be spelled `defaultVariant`, which collided head
  /// on with the `static const defaultVariant` sentinel every other
  /// variant enum in the kit declares — which is why this enum was the
  /// one missing that sentinel. Renaming the member to `neutral` frees
  /// the name, and because the sentinel below points here, existing
  /// `CoreAlertVariant.defaultVariant` call sites keep resolving to this
  /// same value.
  neutral,

  /// Informational -- blue tones.
  info,

  /// Success/positive -- green tones.
  success,

  /// Warning/cautionary -- yellow/amber tones.
  warning,

  /// Error/destructive -- red tones.
  destructive;

  /// Widget default variant — the Flutter / Web `Alert` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreAlertVariant defaultVariant = neutral;
}
