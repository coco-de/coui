/// How an unselected chip is drawn.
library;

/// Visual variants supported by `Chip`.
///
/// Defined locally instead of reusing the 17-value `CoreComponentVariant`
/// so map / switch exhaustiveness checks are meaningful (Chip only ever
/// uses two of those values).
///
/// Three axes, three jobs, one each:
///
/// - **variant** — how an *unselected* chip is drawn: [outlined] or [filled].
/// - **emphasis** — how a *selected* chip is drawn: a quiet tint (`low`) or a
///   solid fill (`high`).
/// - **chipColor** — which colour a *selected* chip takes: `neutral` or
///   `primary`.
///
/// The variant never touches a selected chip, and never touches a disabled
/// one: disabled follows its own tokens whatever the variant says.
///
/// **[filled] is only for `CoreChipEmphasis.high`.** A filled unselected chip
/// and a `low`-selected chip differ by a few percent of lightness — the
/// selected tint is, for `neutral`, slightly *lighter* than the resting
/// fill — so the two states would be told apart by hue alone, which a
/// colour-blind reader or a forced-colours mode does not see (WCAG 1.4.1).
/// `Chip` reports the pair in debug builds when the chip can be selected
/// (`selected`, or an `onTap` that could select it) — a chip that never
/// takes the selected state (a `ChipInput` badge) has no second state to be
/// confused with, so the pair is fine there.
enum CoreChipVariant {
  /// A transparent fill on a hairline border.
  ///
  /// The widget's default variant, and the one every chip drew before this
  /// axis existed.
  outlined,

  /// A grey fill and no visible border — a chip that recommends or runs
  /// something, or a light filter row laid on the page.
  ///
  /// On a grey surface (`surfaceContainer` and up) a filled chip sinks into
  /// the ground; use [outlined] there.
  filled;

  /// Widget default variant.
  ///
  /// Flutter and Web `Chip` constructors both reference
  /// `CoreChipVariant.defaultVariant` so the two stay in lock-step.
  static const CoreChipVariant defaultVariant = outlined;
}
