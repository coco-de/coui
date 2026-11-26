import 'package:coui_core/coui_core.dart' show CoreSpace;
import 'package:coui_core/src/size/layout.dart' show CoreLayout;
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;

/// Size (dimension) primitive tokens — the full palette of element
/// dimensions the system allows.
///
/// For component heights, widths, icon diameters, avatar diameters.
/// NOT for spacing (padding, gap, margin) — use [CoreSpace] instead.
/// The judgment call: set the value to 0 — if the *element disappears*
/// it is a Size; if *elements touch* it is a Space.
///
/// Flutter: `CoreSize.size16` → 16.0 (const double).
/// Web: `CoreSize.scale.size16` → 'size16' (String for Tailwind).
///
/// ## An independent scale, not a Space subset
///
/// [CoreSpace] and [CoreSize] are separate namespaces that never
/// reference each other. What they share is the 4px-multiple principle
/// in the 24px-and-up band — not values. The two must move
/// independently: density tuning shrinks spacing without shrinking
/// icons, text scaling grows icons without growing gaps, and touch
/// targets (44 · 48) are dimension law, not rhythm.
///
/// ## Banded intervals — optics first, grid second
///
/// | band | interval | tokens |
/// |---|---|---|
/// | optical (4–20) | 2px | 4 6 8 10 12 14 16 18 20 |
/// | control (24–48) | 4px | 24 28 32 36 40 44 48 |
/// | structure (56–96) | 8px | 56 64 72 80 88 96 |
/// | display (112–128) | 16px | 112 128 |
///
/// Below 24px optical size perception dominates: 16 → 20 is +25%, which
/// reads as a *different* size rather than the next step, so the band
/// steps by 2px. From 24px up the 4px grid applies, widening to 8px and
/// 16px as relative change shrinks.
///
/// The ladder ends at 128 on purpose. A 200px "element" does not exist —
/// that is a panel or a container, and the bounds a panel may take (a
/// dialog's maximum width, a list's scroll ceiling) live in [CoreLayout],
/// not in an element-dimension token and not in [CoreSpace]'s upper band.
///
/// `size44` (Apple HIG control / WCAG AAA touch) and `size128` (large
/// avatar) have no [CoreSpace] twin — the most direct payoff of keeping
/// Size as its own primitive. A primitive is a palette, and full
/// consumption is not a membership requirement: a step may sit in the band
/// for regularity and external precedent (Fluent/Spectrum avatar 36, M3
/// medium FAB 80) before a component reads it.
abstract final class CoreSize {
  const CoreSize._();

  // === Values (double) ===

  // ── Optical (4–20px, 2px interval) ──

  /// 4px — minimum status dot.
  static const size4 = 4.0;

  /// 6px — status dot, switch handle.
  static const size6 = 6.0;

  /// 8px — badge dot, smallest spinner.
  static const size8 = 8.0;

  /// 10px — smallest icon step.
  static const size10 = 10.0;

  /// 12px — small icon (Fluent · Atlassian · SLDS).
  static const size12 = 12.0;

  /// 14px — between dense and default.
  static const size14 = 14.0;

  /// 16px — text-adjacent icon anchor.
  static const size16 = 16.0;

  /// 18px — M3 / Flutter chip icon.
  static const size18 = 18.0;

  /// 20px — UI-control icon anchor.
  static const size20 = 20.0;

  // ── Control (24–48px, 4px interval) ──

  /// 24px — WCAG 2.2 AA minimum pointer target · default icon.
  static const size24 = 24.0;

  /// 28px — Apple HIG minimum control.
  static const size28 = 28.0;

  /// 32px — the default control size across surveyed systems.
  static const size32 = 32.0;

  /// 36px — Fluent / Spectrum avatar; fills the 32–40 gap · `md` toggle
  /// track width.
  static const size36 = 36.0;

  /// 40px — Flutter `CircleAvatar` default · M3 S button.
  static const size40 = 40.0;

  /// 44px — Apple HIG default control · WCAG 2.2 AAA touch target · `xl`
  /// toggle track width.
  static const size44 = 44.0;

  /// 48px — M3 minimum touch target · Flutter `kMinInteractiveDimension`.
  static const size48 = 48.0;

  // ── Structure (56–96px, 8px interval) ──

  /// 56px — Flutter `kToolbarHeight` · ListTile one-line.
  static const size56 = 56.0;

  /// 64px — M3 app bar · navigation bar.
  static const size64 = 64.0;

  /// 72px — ListTile two-line · FAB large.
  static const size72 = 72.0;

  /// 80px — M3 tall navigation bar · medium FAB.
  static const size80 = 80.0;

  /// 88px — ListTile three-line.
  static const size88 = 88.0;

  /// 96px — M3 L button · large avatar.
  static const size96 = 96.0;

  // ── Display (112–128px, 16px interval) ──

  /// 112px — M3 medium app bar.
  static const size112 = 112.0;

  /// 128px — display avatar (profile header).
  static const size128 = 128.0;

  // === Scale Names (String for Web) ===

  /// Tailwind class name record for compile-safe interpolation.
  static const ({
    String size10,
    String size112,
    String size12,
    String size128,
    String size14,
    String size16,
    String size18,
    String size20,
    String size24,
    String size28,
    String size32,
    String size36,
    String size4,
    String size40,
    String size44,
    String size48,
    String size56,
    String size6,
    String size64,
    String size72,
    String size8,
    String size80,
    String size88,
    String size96,
  })
  scale = (
    size4: 'size4',
    size6: 'size6',
    size8: 'size8',
    size10: 'size10',
    size12: 'size12',
    size14: 'size14',
    size16: 'size16',
    size18: 'size18',
    size20: 'size20',
    size24: 'size24',
    size28: 'size28',
    size32: 'size32',
    size36: 'size36',
    size40: 'size40',
    size44: 'size44',
    size48: 'size48',
    size56: 'size56',
    size64: 'size64',
    size72: 'size72',
    size80: 'size80',
    size88: 'size88',
    size96: 'size96',
    size112: 'size112',
    size128: 'size128',
  );
}
