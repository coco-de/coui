import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedSwitcher
// ═══════════════════════════════════════════════════

/// Resolver output for [Switcher].
///
/// Single struct that the widget reads — the transition duration and
/// curve have had the nested-merge chain applied plus the
/// `CoreSwitcherStyle.defaultX` static const fallbacks:
///
/// ```text
/// CoreSwitcherStyle.defaultDuration / defaultCurve   // design system default
///   → theme.coreComponentTheme.switcher.style
///   → widget.switcherStyle
/// ```
class ResolvedSwitcher {
  /// Creates a [ResolvedSwitcher].
  const ResolvedSwitcher({required this.duration, required this.curve});

  /// Effective slide / fade transition duration.
  final Duration duration;

  /// Paint-ready slide / fade transition curve, converted from the
  /// resolved `CoreCubicBezier` token — the Web twin emits the same four
  /// control points as its `cubic-bezier(...)` timing function.
  final Curve curve;
}

// ═══════════════════════════════════════════════════
// resolveSwitcher — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSwitcher] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreSwitcherStyle.defaultX` static const fallbacks so the widget
/// reads only fully-resolved Flutter-typed values.
ResolvedSwitcher resolveSwitcher(
  BuildContext context, {
  CoreSwitcherStyle? switcherStyle,
}) {
  final switcherTheme = Theme.of(context).coreComponentTheme?.switcher;

  final merged = resolveStyleChain(const CoreSwitcherStyle(), [
    switcherTheme?.style,
    switcherStyle,
  ]);

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final duration = merged.duration ?? CoreSwitcherStyle.defaultDuration;
  final curve = merged.curve ?? CoreSwitcherStyle.defaultCurve;

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final curveValue = curve.toValue();

  return ResolvedSwitcher(duration: duration, curve: curveValue);
}

/// Converts a [CoreSwitcherDirection] to the Flutter [AxisDirection]
/// the internal transition render object understands.
AxisDirection coSwitcherAxisDirection(CoreSwitcherDirection direction) {
  return switch (direction) {
    .up => .up,
    .down => .down,
    .left => .left,
    .right => .right,
  };
}
