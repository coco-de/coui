import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Countdown`.
///
/// Widget tree (`co_countdown.dart` renders the value with a fade):
///
/// ```text
/// Semantics (liveRegion, label = clampedValue)
///   └─ AnimatedSwitcher (animationDuration, FadeTransition)
///        └─ Text (clampedValue, textStyle)
/// ```
///
/// Field grouping:
///
/// 1. **Chrome (paint-ready Flutter types)** — [textStyle] is a fully
///    resolved [TextStyle]: the design-system `headlineLarge`
///    typography role merged with the per-instance `labelStyle` slot and
///    flat `fontSize` / `color` overlay, then baked through the single
///    `.toValue(theme:)` path (role materialised against the active
///    theme typography, token colour resolved through the scheme). The
///    widget reads it with no further typography / colour resolution.
/// 2. **Animation** — [animationDuration] is the resolved fade /
///    digit-transition duration (NOT the total countdown length, which
///    is a semantic widget parameter).
class ResolvedCountdown {
  /// Creates a [ResolvedCountdown].
  const ResolvedCountdown({
    required this.textStyle,
    required this.animationDuration,
  });

  /// Paint-ready display [TextStyle] — typography slot materialised,
  /// overrides merged, foreground colour resolved. The widget layers
  /// `tabularFigures` on at render time (a Flutter rendering detail
  /// with no `CoreTextStyle` equivalent).
  final TextStyle textStyle;

  /// Effective fade / digit-transition animation duration.
  final Duration animationDuration;
}

// ═══════════════════════════════════════════════════
// resolveCountdown — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCountdown] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreCountdownStyle.defaultX (single source)
///   → theme.coreComponentTheme.countdown.style
///   → widget.countdownStyle
/// ```
///
/// Stage 1 RESOLVE is Flutter/Web identical; Stage 2 EMIT bakes the
/// typography through the single `.toValue(theme:)` path so the
/// `headlineLarge` role is materialised against the active theme and any
/// token colour resolves through the scheme (dark-mode reactive). The
/// widget reads `resolved.textStyle` with no further resolution.
ResolvedCountdown resolveCountdown(
  BuildContext context, {
  CoreCountdownStyle? countdownStyle,
}) {
  final theme = Theme.of(context);
  final countdownTheme = theme.coreComponentTheme?.countdown;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCountdownStyle(), [
    countdownTheme?.style,
    countdownStyle,
  ]);

  // ─── Stage 1 RESOLVE — typography (CoreTextStyle, composite) ───
  // Token-backed `headlineLarge` default merged with the nested
  // `labelStyle` slot, then the flat `fontSize` / `color` overlay wins
  // over the slot (mirrors the Web resolver's
  // `merged.fontSize ?? merged.labelStyle?.fontSize` precedence). A
  // null-only overlay is a no-op (merge overlays non-null fields only).
  final labelOverlay = CoreTextStyle(
    fontSize: merged.fontSize,
    color: merged.color,
  );
  final labelCore = CoreCountdownStyle.defaultLabelStyle
      .merge(merged.labelStyle)
      .merge(labelOverlay);

  // ─── Stage 1 RESOLVE — animation ──────────────────────
  final animationDuration = resolveMotionDuration(
    context,
    merged.animationDuration ?? CoreCountdownStyle.defaultAnimationDuration,
  );

  // ─── Stage 2 EMIT (Flutter) — typography = .toValue(theme:) ───
  // `toValue(theme:)` materialises the token role against the active
  // theme typography (already text-scaled at the typography axis) and
  // resolves the foreground token colour through the scheme. No separate
  // `scheme.resolve` / `materialiseCoreText` step.
  final textStyle = labelCore.toValue(theme: theme);

  return ResolvedCountdown(
    textStyle: textStyle,
    animationDuration: animationDuration,
  );
}
