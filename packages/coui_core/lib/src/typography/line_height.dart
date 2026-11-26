/// Line height primitive tokens.
///
/// Flutter: `CoreLineHeight.h160` → 1.6 (const double).
/// Web: `CoreLineHeight.scale.h160` → 'h160' (Tailwind 키).
abstract final class CoreLineHeight {
  const CoreLineHeight._();

  // === Values (double) ===

  /// 1.0x.
  static const h100 = 1.0;

  /// 1.2x.
  static const h120 = 1.2;

  /// 1.4x.
  static const h140 = 1.4;

  /// 1.5x.
  static const h150 = 1.5;

  /// 1.6x.
  static const h160 = 1.6;

  /// 1.8x.
  static const h180 = 1.8;

  /// 2.0x.
  static const h200 = 2.0;

  // === Scale Names (String — Tailwind 키) ===

  /// Tailwind class name record for compile-safe interpolation.
  static const ({
    String h100,
    String h120,
    String h140,
    String h150,
    String h160,
    String h180,
    String h200,
  })
  scale = (
    h100: 'h100',
    h120: 'h120',
    h140: 'h140',
    h150: 'h150',
    h160: 'h160',
    h180: 'h180',
    h200: 'h200',
  );
}

/// Fixed line-box primitive tokens — logical px, not a multiplier.
///
/// A multiplier ties the line box to the font size, so roles of different
/// sizes cannot share one line grid: 11 · 12 · 13px code at any one
/// multiplier lands on three different line heights, and a gutter of 12px
/// line numbers beside 13px code drifts by a few pixels every screen.
/// A role that must sit on one grid regardless of its size states the box
/// itself through `CoreTextStyle.lineHeightPx`.
///
/// Flutter turns it into `height = px / fontSize`, so the box follows the
/// text scaler the way a multiplier does; Web emits it in rem for the same
/// reason.
abstract final class CoreLineBox {
  const CoreLineBox._();

  /// 21px — the code line grid (`code-xs` · `code-sm` · `code-md`).
  static const px21 = 21.0;
}
