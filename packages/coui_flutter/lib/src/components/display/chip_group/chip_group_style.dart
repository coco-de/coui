import 'package:coui_flutter/coui_flutter.dart';

/// Resolved `ChipGroup` style values after applying the 3-tier priority
/// (`widget.chipGroupStyle` > `CoreChipGroupTheme.style` >
/// `CoreChipGroupStyle.defaultX`).
class ResolvedChipGroup {
  /// Creates a [ResolvedChipGroup].
  const ResolvedChipGroup({
    required this.layout,
    required this.selectionMode,
    required this.itemSpacing,
    required this.rowSpacing,
    required this.titleHintGapStyle,
    required this.titleGapStyle,
    required this.fadeWidth,
    required this.fadeGradient,
    required this.titleTextStyle,
    required this.hintTextStyle,
  });

  /// Effective layout mode.
  final CoreChipGroupLayout layout;

  /// Effective selection mode.
  final CoreChipGroupSelectionMode selectionMode;

  /// Effective horizontal gap between sibling chips (logical px,
  /// post-scaling) — forwarded to `Wrap.spacing` / `Row.spacing` as a
  /// native paint-API scalar (no `Gap` indirection).
  final double itemSpacing;

  /// Effective vertical gap between wrap rows (logical px, post-scaling),
  /// forwarded to `Wrap.runSpacing`.
  final double rowSpacing;

  /// Effective nested gap style for the title → hint spacer inside the
  /// header — forwarded to `Gap(gapStyle: …)`, which self-scales, so this
  /// slot carries raw (pre-scaling) values.
  final CoreGapStyle titleHintGapStyle;

  /// Effective nested gap style for the header → chips spacer —
  /// forwarded to `Gap(gapStyle: …)`. `Gap` self-scales, so this
  /// slot carries raw (pre-scaling) values.
  final CoreGapStyle titleGapStyle;

  /// Effective edge fade width (logical px, post-scaling).
  final double fadeWidth;

  /// Edge fade gradient (opaque fade colour → transparent) — raw-forwarded
  /// to `FadeScroll`, which resolves the tokens. No widget-side
  /// `CoreColor` round-trip.
  final List<CoreColor> fadeGradient;

  /// Paint-ready title text style (typography role + resolved colour +
  /// `titleTextStyle` override).
  final TextStyle titleTextStyle;

  /// Paint-ready selection-hint text style (typography role + resolved
  /// colour + `selectionHintTextStyle` override).
  final TextStyle hintTextStyle;
}

/// Resolves [ResolvedChipGroup] for [ChipGroup].
///
/// Merge chain: `widget.chipGroupStyle` > `CoreChipGroupTheme.style` >
/// design-system default (`CoreChipGroupStyle.defaultX`). Semantic enum
/// defaults (`layout` / `selectionMode`) flow from the widget directly
/// or fall back to the theme enum default.
ResolvedChipGroup resolveChipGroup(
  BuildContext context, {
  CoreChipGroupLayout? layout,
  CoreChipGroupSelectionMode? selectionMode,
  CoreChipGroupStyle? chipGroupStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.chipGroup;

  final merged = resolveStyleChain(const CoreChipGroupStyle(), [
    coreTheme?.style,
    chipGroupStyle,
  ]);

  // ── Semantic enums (widget prop, fall back to design default) ──
  // Not theme-overridable on the unified path (parity with chip/badge —
  // a Theme override would stamp on the caller's `layout:` /
  // `selectionMode:`).
  final resolvedLayout = layout ?? .wrap;
  final resolvedSelectionMode = selectionMode ?? .multi;

  final titleHintGapStyle = CoreChipGroupStyle.defaultTitleHintGapStyle.merge(
    merged.titleHintGapStyle,
  );
  final titleGapStyle = CoreChipGroupStyle.defaultTitleGapStyle.merge(
    merged.titleGapStyle,
  );

  // ─── Paint-ready header text styles ────────────────────────────
  // EMIT Stage 2 (Flutter) — `default.merge(override).toValue(theme:)`
  // materialises the token role and resolves its colour (the slot's own
  // `onSurface` / `onSurfaceVariant`, or any per-instance override) through
  // the active scheme in one step. Single primitive — no hand-rolled
  // role + colour assembly.
  final titleTextStyle = CoreChipGroupStyle.defaultTitleTextStyle
      .merge(merged.titleTextStyle)
      .toValue(theme: theme);
  final hintTextStyle = CoreChipGroupStyle.defaultSelectionHintTextStyle
      .merge(merged.selectionHintTextStyle)
      .toValue(theme: theme);

  // Edge fade gradient (opaque fade colour token → transparent) — the
  // `FadeScroll` resolver resolves the tokens itself.
  final fadeGradient = [
    merged.fadeColor ?? CoreChipGroupStyle.defaultFadeColor,
    CoreColor.transparent,
  ];

  // ── Paint-ready dimensional scalars — fallback plus scaling resolved
  //    in these locals so the return literal stays a bare mapping. ──
  final itemSpacing =
      theme.geometry.space(
        merged.itemSpacing ?? CoreChipGroupStyle.defaultItemSpacing,
      ) *
      scaling;
  final rowSpacing =
      theme.geometry.space(
        merged.rowSpacing ?? CoreChipGroupStyle.defaultRowSpacing,
      ) *
      scaling;
  final fadeWidth =
      (merged.fadeWidth ?? CoreChipGroupStyle.defaultFadeWidth) * scaling;

  return ResolvedChipGroup(
    layout: resolvedLayout,
    selectionMode: resolvedSelectionMode,
    itemSpacing: itemSpacing,
    rowSpacing: rowSpacing,
    titleHintGapStyle: titleHintGapStyle,
    titleGapStyle: titleGapStyle,
    fadeWidth: fadeWidth,
    fadeGradient: fadeGradient,
    titleTextStyle: titleTextStyle,
    hintTextStyle: hintTextStyle,
  );
}
