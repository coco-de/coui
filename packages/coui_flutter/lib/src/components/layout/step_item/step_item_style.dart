import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `StepItem`.
///
/// Widget tree:
///
/// ```text
/// ConstrainedBox (minHeight)
///   └─ Padding (padding)
///        └─ Row (cross-axis centre)
///             ├─ Icon (status glyph, iconStyle)
///             ├─ Gap (iconTitleGapStyle)
///             ├─ Expanded
///             │    └─ Text title (titleTextStyle, one line, ellipsis)
///             ├─ Gap (titleTrailingGapStyle)        // when trailing
///             └─ Text trailing (trailingTextStyle)  // when trailing
/// ```
///
/// The geometry carries `theme.scaling` (and the density bend on the
/// padding); the nested [CoreIconStyle] / [CoreGapStyle] slots are
/// forwarded raw, because `Icon` and `Gap` scale themselves.
class ResolvedStepItem {
  /// Creates a [ResolvedStepItem].
  const ResolvedStepItem({
    required this.minHeight,
    required this.padding,
    required this.iconTitleGapStyle,
    required this.titleTrailingGapStyle,
    required this.iconStyle,
    required this.titleTextStyle,
    required this.trailingTextStyle,
  });

  /// Minimum row height (scaling pre-applied).
  final double minHeight;

  /// Content insets (density and scaling pre-applied).
  final EdgeInsetsGeometry padding;

  /// Nested [CoreGapStyle] forwarded to the `Gap` between the glyph and
  /// the title.
  final CoreGapStyle iconTitleGapStyle;

  /// Nested [CoreGapStyle] forwarded to the `Gap` between the title and
  /// the trailing note.
  final CoreGapStyle titleTrailingGapStyle;

  /// Nested [CoreIconStyle] forwarded to the status glyph's `Icon` — the
  /// size and the status colour.
  final CoreIconStyle iconStyle;

  /// Title [TextStyle] — role and status colour.
  final TextStyle titleTextStyle;

  /// Trailing-note [TextStyle] — role and status colour.
  final TextStyle trailingTextStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStepItem] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreStepItemStyle.default* + defaultsByStatus[status]   // defaults
///   → theme.coreComponentTheme.stepItem.style
///   → theme.coreComponentTheme.stepItem.statusStyles[status]
///   → stepItemStyle
/// ```
///
/// A caller-stated field wins over the defaults; the nested slots merge
/// field by field, so a caller who restates only a colour keeps the role
/// and the size.
ResolvedStepItem resolveStepItem(
  BuildContext context, {
  required CoreStepStatus status,
  CoreStepItemStyle? stepItemStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final stepItemTheme = theme.coreComponentTheme?.stepItem;

  // ─── Merge chain ──────────────────────────────────────
  // The status comes straight from the widget — the theme only answers how
  // each status looks (render-only.md (c)).
  final merged = resolveStyleChain(const CoreStepItemStyle(), [
    stepItemTheme?.style,
    stepItemTheme?.statusStyles?[status],
    stepItemStyle,
  ]);

  // The status row — what this status paints (the glyph, the title and
  // the trailing note's colours).
  final chrome = CoreStepItemStyle.defaultsByStatus[status]!;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final iconStyle = CoreStepItemStyle.defaultIconStyle
      .merge(chrome.iconStyle)
      .merge(merged.iconStyle);
  final titleCore = CoreStepItemStyle.defaultTitleStyle
      .merge(chrome.titleStyle)
      .merge(merged.titleStyle);
  final trailingCore = CoreStepItemStyle.defaultTrailingStyle
      .merge(chrome.trailingStyle)
      .merge(merged.trailingStyle);
  // Nested `CoreGapStyle` slots — forwarded raw to `Gap`, which applies
  // density and scaling itself.
  final iconTitleGapStyle = CoreStepItemStyle.defaultIconTitleGapStyle.merge(
    merged.iconTitleGapStyle,
  );
  final titleTrailingGapStyle = CoreStepItemStyle.defaultTitleTrailingGapStyle
      .merge(merged.titleTrailingGapStyle);

  // ─── Stage 2 — EMIT ───────────────────────────────────
  // The row height is the row's own, not a control-ladder rung, so only
  // `scaling` moves it; the padding takes the density bend too.
  final minHeight =
      (merged.minHeight ?? CoreStepItemStyle.defaultMinHeight) * scaling;
  final padding =
      (merged.padding ?? CoreStepItemStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final titleTextStyle = titleCore.toValue(theme: theme);
  final trailingTextStyle = trailingCore.toValue(theme: theme);

  return ResolvedStepItem(
    minHeight: minHeight,
    padding: padding,
    iconTitleGapStyle: iconTitleGapStyle,
    titleTrailingGapStyle: titleTrailingGapStyle,
    iconStyle: iconStyle,
    titleTextStyle: titleTextStyle,
    trailingTextStyle: trailingTextStyle,
  );
}
