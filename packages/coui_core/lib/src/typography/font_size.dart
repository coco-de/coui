/// Font size primitive tokens.
///
/// Flutter: `CoreFontSize.s16` → 16.0 (const double).
/// Web: `CoreFontSize.scale.s16` → 's16' (Tailwind 키).
abstract final class CoreFontSize {
  const CoreFontSize._();

  // === Values (double) ===

  /// 10px.
  static const s10 = 10.0;

  /// 11px.
  static const s11 = 11.0;

  /// 12px.
  static const s12 = 12.0;

  /// 13px.
  static const s13 = 13.0;

  /// 14px.
  static const s14 = 14.0;

  /// 15px.
  static const s15 = 15.0;

  /// 16px.
  static const s16 = 16.0;

  /// 18px.
  static const s18 = 18.0;

  /// 20px.
  static const s20 = 20.0;

  /// 24px.
  static const s24 = 24.0;

  /// 28px.
  static const s28 = 28.0;

  /// 32px.
  static const s32 = 32.0;

  /// 36px.
  static const s36 = 36.0;

  /// 40px.
  static const s40 = 40.0;

  /// 44px.
  static const s44 = 44.0;

  /// 48px.
  static const s48 = 48.0;

  /// 52px.
  static const s52 = 52.0;

  /// 60px.
  static const s60 = 60.0;

  /// 72px.
  static const s72 = 72.0;

  /// 96px.
  static const s96 = 96.0;

  /// 128px.
  static const s128 = 128.0;

  // === Scale Names (String — Tailwind 키) ===

  /// Tailwind class name record for compile-safe interpolation.
  static const ({
    String s10,
    String s11,
    String s12,
    String s128,
    String s13,
    String s14,
    String s15,
    String s16,
    String s18,
    String s20,
    String s24,
    String s28,
    String s32,
    String s36,
    String s40,
    String s44,
    String s48,
    String s52,
    String s60,
    String s72,
    String s96,
  })
  scale = (
    s10: 's10',
    s11: 's11',
    s12: 's12',
    s13: 's13',
    s14: 's14',
    s15: 's15',
    s16: 's16',
    s18: 's18',
    s20: 's20',
    s24: 's24',
    s28: 's28',
    s32: 's32',
    s36: 's36',
    s40: 's40',
    s44: 's44',
    s48: 's48',
    s52: 's52',
    s60: 's60',
    s72: 's72',
    s96: 's96',
    s128: 's128',
  );
}
