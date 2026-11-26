/// InputOtp-specific size variants.
///
/// Not `CoreComponentSize` — the ladder is two rungs, the everyday field and
/// the large one a verification screen draws, and a dedicated enum keeps the
/// `defaultsBySize` map literal exhaustive over exactly those members (Select
/// / MenuItem / DotIndicator use dedicated enums for the same reason).
library;

/// Size options for an `InputOtp`.
///
/// Each rung sets the cell box, its corner, the digit and separator text
/// role, and the obscured dot — the parts that have to grow together for a
/// larger field to read as the same component. The gap between cells and the
/// error message do not vary.
enum CoreInputOtpSize {
  /// `md` — 40 × 40 cells, 8 corner, `labelLarge` digits. The default, and
  /// the field as it was drawn before it had a size axis.
  md,

  /// `lg` — 56 × 56 cells, 14 corner, `titleLarge` digits (semi-bold
  /// overlay). For a screen whose one job is entering the code.
  lg;

  /// Widget default size. Flutter / Web `InputOtp` constructors reference
  /// this so neither platform diverges silently.
  static const CoreInputOtpSize defaultSize = md;
}
