/// Radius primitive tokens.
///
/// Spec defines 19 primitive tokens (`radius0`–`radius64`, `radius9999`).
///
/// Flutter: `CoreRadius.radius8` → 8.0 (const double).
/// Web: `CoreRadius.scale.radius8` → `'radius8'` (Tailwind class key).
abstract final class CoreRadius {
  const CoreRadius._();

  // ── Small (0–16px, 2px interval) ──

  /// 0px.
  static const double radius0 = 0;

  /// 2px.
  static const double radius2 = 2;

  /// 4px.
  static const double radius4 = 4;

  /// 6px.
  static const double radius6 = 6;

  /// 8px.
  static const double radius8 = 8;

  /// 10px.
  static const double radius10 = 10;

  /// 12px.
  static const double radius12 = 12;

  /// 14px.
  static const double radius14 = 14;

  /// 16px.
  static const double radius16 = 16;

  // ── Medium (20–36px, 4px interval) ──

  /// 20px.
  static const double radius20 = 20;

  /// 24px.
  static const double radius24 = 24;

  /// 28px.
  static const double radius28 = 28;

  /// 32px.
  static const double radius32 = 32;

  /// 36px.
  static const double radius36 = 36;

  // ── Large (40–64px, 8px interval) ──

  /// 40px.
  static const double radius40 = 40;

  /// 48px.
  static const double radius48 = 48;

  /// 56px.
  static const double radius56 = 56;

  /// 64px.
  static const double radius64 = 64;

  // ── Full ──

  /// Fully rounded (9999px). Use for pills, circles, avatars.
  static const double radius9999 = 9999;

  /// The ladder, in ascending order, without the two sentinels.
  ///
  /// `radius0` (deliberately square) and `radius9999` (fully rounded)
  /// are excluded: both are statements rather than magnitudes, and a
  /// transform that moves values along this ladder has to leave them
  /// where they are.
  ///
  /// Exists so a surface style can redistribute radii *on the scale*
  /// rather than to arbitrary numbers. That is not a preference — on
  /// Web only values on this ladder resolve through the
  /// `--coui-radius-*` variables, and anything else is emitted as a
  /// literal, which silently opts that component out of every preset.
  static const List<double> steps = [
    radius2,
    radius4,
    radius6,
    radius8,
    radius10,
    radius12,
    radius14,
    radius16,
    radius20,
    radius24,
    radius28,
    radius32,
    radius36,
    radius40,
    radius48,
    radius56,
    radius64,
  ];

  /// Tailwind class name record for compile-safe interpolation.
  static const ({
    String radius0,
    String radius10,
    String radius12,
    String radius14,
    String radius16,
    String radius2,
    String radius20,
    String radius24,
    String radius28,
    String radius32,
    String radius36,
    String radius4,
    String radius40,
    String radius48,
    String radius56,
    String radius6,
    String radius64,
    String radius8,
    String radius9999,
  })
  scale = (
    radius0: 'radius0',
    radius2: 'radius2',
    radius4: 'radius4',
    radius6: 'radius6',
    radius8: 'radius8',
    radius10: 'radius10',
    radius12: 'radius12',
    radius14: 'radius14',
    radius16: 'radius16',
    radius20: 'radius20',
    radius24: 'radius24',
    radius28: 'radius28',
    radius32: 'radius32',
    radius36: 'radius36',
    radius40: 'radius40',
    radius48: 'radius48',
    radius56: 'radius56',
    radius64: 'radius64',
    radius9999: 'radius9999',
  );
}
