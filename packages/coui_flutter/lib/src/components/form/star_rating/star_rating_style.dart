library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `StarRating`.
///
/// Widget tree (`co_star_rating.dart` decides which optional branches
/// render):
///
/// ```text
/// AnimatedBuilder (slide animation)
///   └─ FocusableActionDetector (keyboard / focus state)
///        └─ MouseRegion
///             └─ GestureDetector (pan + tap)
///                  └─ Flex (direction, gap via SizedBox)
///                       └─ Stack × maxInt
///                            ├─ CustomPaint (StarPainter, starSize)
///                            │    - fill: activeColor / backgroundColor
///                            └─ Star × max (filled / half / empty)
/// ```
///
/// Field grouping:
///
/// 1. **Per-star paint values** — [starSize], [activeColor],
///    [backgroundColor] read by the `CustomPaint` / `StarPainter` per
///    star (scaling pre-applied to [starSize] /
///    [starSpacing]).
/// 2. **Layout values** — [starSpacing] consumed by the [Flex]'s
///    inter-star [SizedBox] gap.
/// 3. **Group chrome** — value / count text styles, their gap, and the
///    focus ring drawn once around the whole group.
class ResolvedStarRating {
  /// Creates a [ResolvedStarRating].
  const ResolvedStarRating({
    required this.animationDuration,
    required this.starSize,
    required this.starSpacing,
    required this.activeColor,
    required this.backgroundColor,
    required this.valueTextStyle,
    required this.countTextStyle,
    required this.valueGapStyle,
    required this.focusOutlineStyle,
  });

  /// Effective star icon size (logical px, scaling pre-applied).
  final double starSize;

  /// Fill-transition duration — drives the `AnimatedValueBuilder` value
  /// lerp (same `CoreDuration` token as the Web CSS width transition).
  final Duration animationDuration;

  /// Effective horizontal spacing between stars (logical px, scaling
  /// pre-applied).
  final double starSpacing;

  /// Resolved active (filled) star colour — already converted from
  /// [CoreColor] to Flutter [Color] via
  /// `scheme.resolve(...).toValue()`. When disabled, this carries the
  /// disabled-active colour so the widget does not branch on `enabled`.
  final Color activeColor;

  /// Resolved inactive (empty) star background colour — already
  /// converted from [CoreColor] to Flutter [Color] via
  /// `scheme.resolve(...).toValue()`.
  final Color backgroundColor;

  /// Paint-ready value text ("4.5") style — size row's role, disabled
  /// colour swapped in when disabled.
  final TextStyle valueTextStyle;

  /// Paint-ready count text ("(128)") style.
  final TextStyle countTextStyle;

  /// Gap between the stars and the value / count text, raw-forwarded to
  /// `Gap` (which resolves its own scaling).
  final CoreGapStyle valueGapStyle;

  /// Keyboard focus ring around the whole group, forwarded to the
  /// composed `FocusOutline` (which resolves its own tokens).
  final CoreFocusOutlineStyle focusOutlineStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStarRating] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.starRating.style
///   → widget.starRatingStyle
/// ```
ResolvedStarRating resolveStarRating(
  BuildContext context, {
  CoreStarRatingStyle? starRatingStyle,
  CoreComponentSize size = CoreStarRatingStyle.defaultSize,
  bool enabled = true,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final srTheme = theme.coreComponentTheme?.starRating;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreStarRatingStyle(), [
    srTheme?.style,
    starRatingStyle,
  ]);

  final animationDuration = resolveMotionDuration(
    context,
    merged.animationDuration ?? CoreStarRatingStyle.defaultAnimationDuration,
  );

  // ─── Resolved chrome (scaling pre-applied) ────────────
  // Active / background colours read [CoreStarRatingStyle.defaultActiveColor]
  // / [defaultBackgroundColor] — same tokens the Web side reads. Colour
  // resolution flows through `scheme.resolve(...).toValue()`, matching
  // the PoC.
  final sizeRow = resolveSizeRow(CoreStarRatingStyle.defaultsBySize, size);
  final starSize = (merged.starSize ?? sizeRow.starSize!) * scaling;
  final starSpacing =
      theme.geometry.space(merged.starSpacing ?? sizeRow.starSpacing!) *
      scaling;

  // Active colour — instance override > disabled token > active token.
  // Caller-provided overrides win whether the widget is enabled or
  // disabled (so a disabled colour override applies to the disabled
  // state through the dedicated `disabledActiveColor` field).
  final activeColor = scheme
      .resolve(
        enabled
            ? (merged.activeColor ?? CoreStarRatingStyle.defaultActiveColor)
            : (merged.disabledActiveColor ??
                  CoreStarRatingStyle.defaultDisabledActiveColor),
      )
      .toValue();
  final backgroundColor = scheme
      .resolve(
        enabled
            ? (merged.backgroundColor ??
                  CoreStarRatingStyle.defaultBackgroundColor)
            : (merged.disabledBackgroundColor ??
                  CoreStarRatingStyle.defaultDisabledBackgroundColor),
      )
      .toValue();

  // Value / count text — the size row's role, then the per-instance
  // override; disabled swaps the ink for the disabled token.
  final valueText = sizeRow.valueStyle!.merge(merged.valueStyle);
  final countText = sizeRow.countStyle!.merge(merged.countStyle);
  final valueTextStyle =
      (enabled
              ? valueText
              : valueText.copyWith(
                  color: CoreStarRatingStyle.defaultDisabledTextColor,
                ))
          .toValue(theme: theme);
  final countTextStyle =
      (enabled
              ? countText
              : countText.copyWith(
                  color: CoreStarRatingStyle.defaultDisabledTextColor,
                ))
          .toValue(theme: theme);
  final valueGapStyle = CoreStarRatingStyle.defaultValueGapStyle.merge(
    merged.valueGapStyle,
  );
  final focusOutlineStyle = merged.focusRingStyle;

  // ─── Compose paint-ready resolved object ──────────────
  return ResolvedStarRating(
    animationDuration: animationDuration,
    starSize: starSize,
    starSpacing: starSpacing,
    activeColor: activeColor,
    backgroundColor: backgroundColor,
    valueTextStyle: valueTextStyle,
    countTextStyle: countTextStyle,
    valueGapStyle: valueGapStyle,
    focusOutlineStyle: focusOutlineStyle,
  );
}
