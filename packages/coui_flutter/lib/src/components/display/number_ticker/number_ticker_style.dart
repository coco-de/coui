import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Single-entry-point resolver
// ═══════════════════════════════════════════════════

// ═══════════════════════════════════════════════════
// ResolvedNumberTicker
// ═══════════════════════════════════════════════════

/// Resolver output for `NumberTicker`.
///
/// Single struct that the widget reads — every chrome / dimensional /
/// text-style override has been merged through:
///
/// ```text
/// design system default (CoreNumberTickerStyle.defaultDuration)
///   → theme.coreComponentTheme.numberTicker.style
///   → widget.numberTickerStyle
/// ```
class ResolvedNumberTicker {
  /// Creates a [ResolvedNumberTicker].
  const ResolvedNumberTicker({
    required this.duration,
    required this.textStyle,
  });

  /// Value-interpolation animation duration.
  final Duration duration;

  /// Resolved text style for the formatted numeric display.
  final TextStyle textStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedNumberTicker] for the given [context].
///
/// Priority (per-field):
/// `widget.numberTickerStyle` > `CoreNumberTickerTheme.style` >
/// `CoreNumberTickerStyle.defaultDuration`.
ResolvedNumberTicker resolveNumberTicker(
  BuildContext context, {
  CoreNumberTickerStyle? numberTickerStyle,
}) {
  final theme = Theme.of(context);
  final ntTheme = theme.coreComponentTheme?.numberTicker;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreNumberTickerStyle(), [
    ntTheme?.style,
    numberTickerStyle,
  ]);

  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreNumberTickerStyle.defaultDuration,
  );

  // ─── Typography (paint-ready TextStyle) ───────────────
  // EMIT Stage 2 (Flutter) — single primitive. The design-system default
  // (`titleLarge` role) is merged with any per-instance `textStyle`
  // overlay, then materialised through `.toValue(theme:)` which resolves
  // the role token + its colour against the active scheme (dark-mode
  // tracks). The display child uses tabular figures so digits keep a
  // fixed advance while the value animates — applied as a final overlay
  // (`.toValue` does not carry font features).
  final labelCore = CoreNumberTickerStyle.defaultTextStyle.merge(
    merged.textStyle,
  );
  final textStyle = labelCore
      .toValue(theme: theme)
      .copyWith(
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  return ResolvedNumberTicker(
    duration: duration,
    textStyle: textStyle,
  );
}
