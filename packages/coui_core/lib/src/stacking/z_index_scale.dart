/// Z-Index primitive tokens.
///
/// Spec defines 12 tokens (`z0`–`z100`, `zAuto`). These are **web-only**
/// tokens; Flutter determines stacking by widget tree order, so there is no
/// Flutter-side counterpart.
///
/// Design rationale: start at 1000 to avoid colliding with custom z-index
/// values (1–999); use a step of 10 to allow intermediate insertions.
abstract final class CoreZIndex {
  const CoreZIndex._();

  // === Primitive Tokens (12개) ===

  /// 1000 — base content layer.
  static const int z0 = 1000;

  /// 1010 — dropdown menus.
  static const int z10 = 1010;

  /// 1020 — sticky/fixed headers.
  static const int z20 = 1020;

  /// 1030 — sidebars.
  static const int z30 = 1030;

  /// 1040 — overlay backdrops.
  static const int z40 = 1040;

  /// 1050 — modals/dialogs.
  static const int z50 = 1050;

  /// 1060 — popovers.
  static const int z60 = 1060;

  /// 1070 — tooltips.
  static const int z70 = 1070;

  /// 1080 — toasts/snackbars.
  static const int z80 = 1080;

  /// 1090 — urgent alerts.
  static const int z90 = 1090;

  /// 1100 — top-most layer (debug, devtools).
  static const int z100 = 1100;

  /// `auto` — default stacking order. Use as a CSS `z-index` value string.
  static const String zAuto = 'auto';

  // === Scale Names (String for Web) ===

  /// CSS variable key record for compile-safe interpolation.
  ///
  /// Usage: `var(--z-${CoreZIndex.scale.z50})` → `var(--z-50)`.
  static const ({
    String z0,
    String z10,
    String z100,
    String z20,
    String z30,
    String z40,
    String z50,
    String z60,
    String z70,
    String z80,
    String z90,
    String zAuto,
  })
  scale = (
    z0: '0',
    z10: '10',
    z20: '20',
    z30: '30',
    z40: '40',
    z50: '50',
    z60: '60',
    z70: '70',
    z80: '80',
    z90: '90',
    z100: '100',
    zAuto: 'auto',
  );
}
