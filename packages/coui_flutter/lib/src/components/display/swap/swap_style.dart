/// Per-instance resolver for [Swap] on Flutter.
///
/// `co_swap.dart` reads only `Resolved*` fields — every theme /
/// `CoreSwapStyle` lookup + token → ARGB / TextStyle conversion is
/// concentrated here so the widget `build` is free of direct
/// `Theme.of(context).coreComponentTheme` access (verify.md 7-6 (n)).
library;

import 'package:coui_flutter/coui_flutter.dart';

/// Resolver output for [Swap].
///
/// Single struct that the widget reads — every field has had the
/// nested merge chain applied plus `CoreSwapStyle.defaultX` fallback
/// and type conversion.
class ResolvedSwap {
  /// Creates a [ResolvedSwap].
  const ResolvedSwap({
    required this.duration,
    required this.textStyle,
    required this.clickableStyle,
  });

  /// Effective animation cycle duration.
  final Duration duration;

  /// Effective `DefaultTextStyle` applied to the swap slots' children
  /// (already materialised via the single-primitive
  /// `CoreTextStyle.toValue(theme:)` path — token role + scheme colour
  /// resolution in one step).
  final TextStyle textStyle;

  /// Nested [CoreClickableStyle] slot for the composed root `Clickable`
  /// (interactive swaps only) — `CoreSwapStyle.defaultClickableStyle`
  /// merged with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

/// Resolves [ResolvedSwap] for the given [context].
///
/// Single entry point — `co_swap.dart` must not call
/// `theme.coreComponentTheme.swap` directly nor invoke
/// `CoreSwapStyle.merge(...)` outside this function. All fallback
/// chains terminate at `coui_core`'s [CoreSwapStyle] static const
/// defaults.
ResolvedSwap resolveSwap(
  BuildContext context, {
  CoreSwapStyle? swapStyle,
}) {
  final theme = Theme.of(context);
  final compTheme = theme.coreComponentTheme?.swap;

  // Two-stage merge chain (theme.style → widget.swapStyle).
  final merged = resolveStyleChain(const CoreSwapStyle(), [
    compTheme?.style,
    swapStyle,
  ]);

  // ── duration ──
  final effectiveDuration = resolveMotionDuration(
    context,
    merged.duration ?? CoreSwapStyle.defaultDuration,
  );

  // ── textStyle ──
  // EMIT Stage 2 (Flutter) — `style.toValue(theme:)` materialises the
  // token role and resolves its colour through the active scheme in a
  // single primitive (no hand-rolled `typography.resolve` + raw
  // `scheme.resolve` + `.copyWith(color:)` assembly). Both Flutter and
  // Web share the same `CoreSwapStyle.defaultTextStyle` so the role
  // mapping cannot silently diverge (verify.md 7-27). Colour is folded
  // into the nested `CoreTextStyle` slot (sb8).
  final effectiveTextStyle = CoreSwapStyle.defaultTextStyle
      .merge(merged.textStyle)
      .toValue(theme: theme);

  // ── clickableStyle ──
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreSwapStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  return ResolvedSwap(
    duration: effectiveDuration,
    textStyle: effectiveTextStyle,
    clickableStyle: clickableStyle,
  );
}
