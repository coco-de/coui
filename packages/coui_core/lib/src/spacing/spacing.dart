// `CoreSpace` is a flat numeric scale (`space0`…`space256`); each member is
// self-documenting by name, so per-member dartdoc would be redundant.

/// Space primitive tokens.
///
/// Flutter: `CoreSpace.space16` → 16.0 (const double).
/// Web: `CoreSpace.scale.space16` → 'space16' (String for Tailwind).
abstract final class CoreSpace {
  const CoreSpace._();

  // === Values (double) ===

  // ── Small (0–18px, 2px interval) ──

  /// 0px.
  static const space0 = 0.0;

  /// 2px.
  static const space2 = 2.0;

  /// 4px.
  static const space4 = 4.0;

  /// 6px.
  static const space6 = 6.0;

  /// 8px.
  static const space8 = 8.0;

  /// 10px.
  static const space10 = 10.0;

  /// 12px.
  static const space12 = 12.0;

  /// 14px.
  static const space14 = 14.0;

  /// 16px.
  static const space16 = 16.0;

  /// 18px.
  static const space18 = 18.0;

  // ── Medium (20–32px, 4px interval) ──

  /// 20px.
  static const space20 = 20.0;

  /// 24px.
  static const space24 = 24.0;

  /// 28px.
  static const space28 = 28.0;

  /// 32px.
  static const space32 = 32.0;

  // ── Large (34–64px, 4px interval) ──

  /// 36px.
  static const space36 = 36.0;

  /// 40px.
  static const space40 = 40.0;

  /// 44px.
  static const space44 = 44.0;

  /// 48px.
  static const space48 = 48.0;

  /// 52px.
  static const space52 = 52.0;

  /// 56px.
  static const space56 = 56.0;

  /// 60px.
  static const space60 = 60.0;

  /// 64px.
  static const space64 = 64.0;

  // ── Extra Large (72–256px, 8px interval) ──

  /// 72px.
  static const space72 = 72.0;

  /// 80px.
  static const space80 = 80.0;

  /// 88px.
  static const space88 = 88.0;

  /// 96px.
  static const space96 = 96.0;

  /// 104px.
  static const space104 = 104.0;

  /// 112px.
  static const space112 = 112.0;

  /// 120px.
  static const space120 = 120.0;

  /// 128px.
  static const space128 = 128.0;

  /// 136px.
  static const space136 = 136.0;

  /// 144px.
  static const space144 = 144.0;

  /// 152px.
  static const space152 = 152.0;

  /// 160px.
  static const space160 = 160.0;

  /// 168px.
  static const space168 = 168.0;

  /// 176px.
  static const space176 = 176.0;

  /// 184px.
  static const space184 = 184.0;

  /// 192px.
  static const space192 = 192.0;

  /// 200px.
  static const space200 = 200.0;

  /// 208px.
  static const space208 = 208.0;

  /// 216px.
  static const space216 = 216.0;

  /// 224px.
  static const space224 = 224.0;

  /// 232px.
  static const space232 = 232.0;

  /// 240px.
  static const space240 = 240.0;

  /// 248px.
  static const space248 = 248.0;

  /// 256px.
  static const space256 = 256.0;

  /// Every step of the scale, in ascending order.
  ///
  /// The scale is a list of named constants, and a consumer that needs to
  /// walk it — a CSS variable per step, a density re-map onto the nearest
  /// step — would otherwise re-type the numbers and drift from them.
  static const List<double> steps = [
    space0,
    space2,
    space4,
    space6,
    space8,
    space10,
    space12,
    space14,
    space16,
    space18,
    space20,
    space24,
    space28,
    space32,
    space36,
    space40,
    space44,
    space48,
    space52,
    space56,
    space60,
    space64,
    space72,
    space80,
    space88,
    space96,
    space104,
    space112,
    space120,
    space128,
    space136,
    space144,
    space152,
    space160,
    space168,
    space176,
    space184,
    space192,
    space200,
    space208,
    space216,
    space224,
    space232,
    space240,
    space248,
    space256,
  ];

  // === Scale Names (String for Web) ===

  /// Tailwind class name record for compile-safe interpolation.
  static const ({
    String space0,
    String space10,
    String space104,
    String space112,
    String space12,
    String space120,
    String space128,
    String space136,
    String space14,
    String space144,
    String space152,
    String space16,
    String space160,
    String space168,
    String space176,
    String space18,
    String space184,
    String space192,
    String space2,
    String space20,
    String space200,
    String space208,
    String space216,
    String space224,
    String space232,
    String space24,
    String space240,
    String space248,
    String space256,
    String space28,
    String space32,
    String space36,
    String space4,
    String space40,
    String space44,
    String space48,
    String space52,
    String space56,
    String space6,
    String space60,
    String space64,
    String space72,
    String space8,
    String space80,
    String space88,
    String space96,
  })
  scale = (
    space0: 'space0',
    space2: 'space2',
    space4: 'space4',
    space6: 'space6',
    space8: 'space8',
    space10: 'space10',
    space12: 'space12',
    space14: 'space14',
    space16: 'space16',
    space18: 'space18',
    space20: 'space20',
    space24: 'space24',
    space28: 'space28',
    space32: 'space32',
    space36: 'space36',
    space40: 'space40',
    space44: 'space44',
    space48: 'space48',
    space52: 'space52',
    space56: 'space56',
    space60: 'space60',
    space64: 'space64',
    space72: 'space72',
    space80: 'space80',
    space88: 'space88',
    space96: 'space96',
    space104: 'space104',
    space112: 'space112',
    space120: 'space120',
    space128: 'space128',
    space136: 'space136',
    space144: 'space144',
    space152: 'space152',
    space160: 'space160',
    space168: 'space168',
    space176: 'space176',
    space184: 'space184',
    space192: 'space192',
    space200: 'space200',
    space208: 'space208',
    space216: 'space216',
    space224: 'space224',
    space232: 'space232',
    space240: 'space240',
    space248: 'space248',
    space256: 'space256',
  );
}
