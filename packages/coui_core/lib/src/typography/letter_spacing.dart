/// Letter spacing primitive tokens (em units).
///
/// Flutter: `CoreLetterSpacing.tight` → -0.025 (const double).
/// Web: `CoreLetterSpacing.scale.tight` → 'tight' (Tailwind 키).
abstract final class CoreLetterSpacing {
  const CoreLetterSpacing._();

  // === Values (double — em) ===

  /// -0.05em.
  static const tighter = -0.05;

  /// -0.025em.
  static const tight = -0.025;

  // ── Role tracking ──
  // The typography roles track in two steps: a glyph of 20px or more
  // takes [tight20] (−2%), anything smaller takes [tight10] (−1%), and a
  // monospace role takes [normal] — its advance is the grid, so tracking
  // it would break the columns it exists to keep.
  //
  // Two steps rather than a curve because the size ladder is now 1px apart
  // at the label end (11 … 16): a curve that changes rung between 14 and
  // 16 puts two neighbouring roles on visibly different tracking for a
  // one-pixel size step. [tight5] and [tight15] are the rungs the earlier
  // five-step curve stood on; no role of `CoreTypography.coui` names them
  // now (only the retained `CoreTypography.couiV1` does).

  /// -0.005em.
  static const tight5 = -0.005;

  /// -0.01em — role tracking below 20px.
  static const tight10 = -0.01;

  /// -0.015em.
  static const tight15 = -0.015;

  /// -0.02em — role tracking at 20px and above.
  static const tight20 = -0.02;

  /// 0em.
  static const normal = 0.0;

  /// 0.025em.
  static const wide = 0.025;

  /// 0.05em.
  static const wider = 0.05;

  /// 0.1em.
  static const widest = 0.1;

  // === Scale Names (String — Tailwind 키) ===

  /// Tailwind class name record for compile-safe interpolation.
  static const ({
    String normal,
    String tight,
    String tight10,
    String tight15,
    String tight20,
    String tight5,
    String tighter,
    String wide,
    String wider,
    String widest,
  })
  scale = (
    tighter: 'tighter',
    tight: 'tight',
    tight20: 'tight20',
    tight15: 'tight15',
    tight10: 'tight10',
    tight5: 'tight5',
    normal: 'normal',
    wide: 'wide',
    wider: 'wider',
    widest: 'widest',
  );
}
