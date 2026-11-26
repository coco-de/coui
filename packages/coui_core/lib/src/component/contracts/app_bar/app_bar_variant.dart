/// Visual variants supported by `AppBar`.
///
/// Defined locally instead of reusing the 17-value `CoreComponentVariant`
/// so map / switch exhaustiveness checks are meaningful (AppBar only ever
/// uses its own five bar shapes).
library;

/// Variant of an `AppBar`.
///
/// Selects the per-variant entry in `CoreAppBarStyle.defaultsByVariant`,
/// which fills `height` / `titleStyle` / `titlePadding` with the
/// designer-measured chrome for that bar shape — plus the bar `padding`
/// for compact, dense and prominent, and the cluster gaps and bar face for
/// dense.
enum CoreAppBarVariant {
  /// 64px single-row bar — the designer set's default member.
  standard,

  /// 56px single-row bar for dense layouts.
  compact,

  /// 112px two-row bar — a 48px top row (leading / actions) above a
  /// bottom-aligned large title.
  medium,

  /// 48px single-row desktop window / tool bar — one row of 32px
  /// controls with 8 above and below. The step ladder above (56 · 64 ·
  /// 112) is sized for touch; a desktop title bar needs this shorter row.
  dense,

  /// 56px single-row bar with one large, start-aligned title — the first
  /// screen of a tab, where the title names the place and the bar carries
  /// no back button. The title takes the `headlineSmall` role and starts 20
  /// in from the bar edge. It is the same row height as [compact]; what
  /// differs is the title, which is the screen's heading here rather than a
  /// label in the bar.
  prominent;

  /// Widget default variant.
  ///
  /// Flutter and Web `AppBar` constructors both reference
  /// `CoreAppBarVariant.defaultVariant` so the two stay in lock-step.
  static const CoreAppBarVariant defaultVariant = standard;
}
