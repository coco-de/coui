import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedProgress (linear)
// ═══════════════════════════════════════════════════

/// Resolver output for [Progress].
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus static const default fallback and
/// `scaling` applied.
///
/// Widget tree (`progress.dart` draws the column only when the bar has a
/// label cell — without one the track is the whole widget):
///
/// ```text
/// MergeSemantics                          // only with a cell
///   └─ Semantics (value)
///        └─ Column                        // only with a cell
///             ├─ Row                      // only with label / valueLabel
///             │    ├─ DefaultTextStyle(labelTextStyle) → label (Expanded)
///             │    └─ DefaultTextStyle(valueLabelTextStyle) → valueLabel
///             ├─ Gap ← labelGapStyle
///             ├─ Container (track: backgroundColor / borderRadius /
///             │    │        minHeight)
///             │    └─ indicator (color)
///             │  — or, with `segments` and a value —
///             ├─ Row (spacing: segmentSpacing)
///             │    └─ cell × segments (color for the steps passed,
///             │         backgroundColor for the rest; borderRadius /
///             │         minHeight)
///             ├─ Gap ← captionGapStyle
///             └─ DefaultTextStyle(captionTextStyle) → caption
/// ```
class ResolvedProgress {
  /// Creates a [ResolvedProgress].
  const ResolvedProgress({
    required this.color,
    required this.backgroundColor,
    required this.borderRadius,
    required this.minHeight,
    required this.duration,
    required this.indeterminateDuration,
    required this.indeterminateFillRatio,
    required this.labelTextStyle,
    required this.valueLabelTextStyle,
    required this.captionTextStyle,
    required this.labelGapStyle,
    required this.captionGapStyle,
    required this.segmentSpacing,
  });

  /// Effective progress fill colour — the stated colour, else the tone's
  /// fill from [CoreProgressStyle.defaultsByTone].
  final Color color;

  /// Effective track background colour — the explicit override, else
  /// [color] faded by a stated `backgroundAlpha`, else
  /// [CoreProgressStyle.defaultBackgroundColor].
  final Color backgroundColor;

  /// Effective track corner radius (logical px).
  final BorderRadius borderRadius;

  /// Effective track height / thickness (logical px, post-scaling).
  final double minHeight;

  /// Effective determinate width transition duration.
  final Duration duration;

  /// Effective indeterminate slide cycle duration.
  final Duration indeterminateDuration;

  /// Effective indeterminate fill width as a share of the track (`0..1`).
  final double indeterminateFillRatio;

  /// Paint-ready ambient text style of the `label` cell — the
  /// [CoreProgressStyle.defaultLabelStyle] role with any override layered
  /// on top and its colour resolved through the active scheme.
  final TextStyle labelTextStyle;

  /// Paint-ready ambient text style of the `valueLabel` cell.
  final TextStyle valueLabelTextStyle;

  /// Paint-ready ambient text style of the `caption` cell.
  final TextStyle captionTextStyle;

  /// Nested [CoreGapStyle] for the label row → bar spacer — forwarded raw
  /// to `Gap`, which applies `scaling` itself.
  final CoreGapStyle labelGapStyle;

  /// Nested [CoreGapStyle] for the bar → caption spacer — forwarded raw to
  /// `Gap`.
  final CoreGapStyle captionGapStyle;

  /// Gap between the cells of a segmented bar (logical px, the theme
  /// density and `scaling` applied) — the cell row's `Row.spacing`.
  final double segmentSpacing;
}

// ═══════════════════════════════════════════════════
// resolveProgress — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedProgress] for the given [context].
///
/// Applies the full merge chain:
///
/// ```text
/// CoreProgressStyle.defaultX / defaultsBySize[size] / defaultsByTone[tone]
///   → CoreProgressTheme.style
///   → CoreProgressTheme.toneStyles[tone]
///   → widget.progressStyle
/// ```
///
/// Final fallback values come from `coui_core` — [CoreProgressStyle]
/// `defaultX` static const fields. The widget never spells out
/// fallback logic inline.
///
/// [size] and [tone] are semantic identifiers (widget-only props — the
/// theme cannot override them, mirroring `resolveFab`'s `size`). [size]
/// selects the per-size track thickness from
/// [CoreProgressStyle.defaultsBySize]; [tone] selects the fill from
/// [CoreProgressStyle.defaultsByTone] and the project's
/// [CoreProgressTheme.toneStyles] row.
ResolvedProgress resolveProgress(
  BuildContext context, {
  required CoreProgressSize size,
  CoreProgressTone tone = CoreProgressTone.defaultTone,
  CoreProgressStyle? progressStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final pTheme = theme.coreComponentTheme?.progress;

  // ── Merge chain: project → project tone row → instance ──
  final merged = resolveStyleChain(const CoreProgressStyle(), [
    pTheme?.style,
    pTheme?.toneStyles?[tone],
    progressStyle,
  ]);

  // ── Colour resolution (token → Color) ──
  // A stated colour wins; otherwise the tone's fill. Every tone row
  // states its fill, so the lookup is total.
  final toneStyle = CoreProgressStyle.defaultsByTone[tone]!;
  final fillColor = scheme.resolve(merged.color ?? toneStyle.color!).toValue();

  final mergedBg = merged.backgroundColor;
  final trackAlpha = merged.backgroundAlpha;
  final trackColor = mergedBg != null
      ? scheme.resolve(mergedBg).toValue()
      : trackAlpha != null
      ? fillColor.scaleAlpha(trackAlpha)
      : scheme.resolve(CoreProgressStyle.defaultBackgroundColor).toValue();

  // ── Dimensional resolution ──
  final radius = (merged.borderRadius ?? CoreProgressStyle.defaultBorderRadius)
      .toValue(geometry: theme.geometry);

  // Semantic `size` is a widget-only prop (the theme cannot override it).
  // Resolve straight to the per-size default style (minHeight).
  final sizeStyle = CoreProgressStyle.defaultsBySize[size]!;
  final minHeight = (merged.minHeight ?? sizeStyle.minHeight!) * scaling;

  // ── Animation resolution ──
  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreProgressStyle.defaultDuration,
  );
  final indeterminateDuration = resolveMotionDuration(
    context,
    merged.indeterminateDuration ??
        CoreProgressStyle.defaultIndeterminateDuration,
  );

  final indeterminateFillRatio =
      merged.indeterminateFillRatio ??
      CoreProgressStyle.defaultIndeterminateFillRatio;

  // ── Label cells (paint-ready TextStyle) ──
  // EMIT Stage 2 (Flutter) — `default.merge(override).toValue(theme:)`
  // materialises each cell's role with any override layered on top and
  // resolves its colour through the active scheme.
  final labelTextStyle = CoreProgressStyle.defaultLabelStyle
      .merge(merged.labelStyle)
      .toValue(theme: theme);
  final valueLabelTextStyle = CoreProgressStyle.defaultValueLabelStyle
      .merge(merged.valueLabelStyle)
      .toValue(theme: theme);
  final captionTextStyle = CoreProgressStyle.defaultCaptionStyle
      .merge(merged.captionStyle)
      .toValue(theme: theme);

  // Nested CoreGapStyle slots — forwarded raw to `Gap`, which scales itself.
  final labelGapStyle = CoreProgressStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  final captionGapStyle = CoreProgressStyle.defaultCaptionGapStyle.merge(
    merged.captionGapStyle,
  );

  // Cell gap of a segmented bar — spacing, so the theme density moves it
  // before the size factor.
  final segmentSpacing =
      theme.geometry.space(
        merged.segmentSpacing ?? CoreProgressStyle.defaultSegmentSpacing,
      ) *
      scaling;

  return ResolvedProgress(
    color: fillColor,
    backgroundColor: trackColor,
    borderRadius: radius,
    minHeight: minHeight,
    duration: duration,
    indeterminateDuration: indeterminateDuration,
    indeterminateFillRatio: indeterminateFillRatio,
    labelTextStyle: labelTextStyle,
    valueLabelTextStyle: valueLabelTextStyle,
    captionTextStyle: captionTextStyle,
    labelGapStyle: labelGapStyle,
    captionGapStyle: captionGapStyle,
    segmentSpacing: segmentSpacing,
  );
}

// ═══════════════════════════════════════════════════
// ResolvedRadialProgress
// ═══════════════════════════════════════════════════

/// Resolver output for [RadialProgress].
class ResolvedRadialProgress {
  /// Creates a [ResolvedRadialProgress].
  const ResolvedRadialProgress({
    required this.color,
    required this.backgroundColor,
    required this.size,
    required this.strokeWidth,
    required this.valueTextStyle,
  });

  /// Effective arc colour.
  final Color color;

  /// Effective track ring colour — the explicit override, else [color]
  /// faded by a stated `backgroundAlpha`, else
  /// [CoreRadialProgressStyle.defaultBackgroundColor].
  final Color backgroundColor;

  /// Effective ring diameter (logical px, post-scaling).
  final double size;

  /// Effective stroke width (logical px, post-scaling).
  final double strokeWidth;

  /// Paint-ready centre value-text style — the size row's typography role +
  /// per-instance `valueTextStyle` overlay + foreground colour already baked
  /// in. `null` for a size that draws no value text (`sm`) unless one is
  /// stated.
  final TextStyle? valueTextStyle;
}

// ═══════════════════════════════════════════════════
// resolveRadialProgress — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedRadialProgress] for the given [context].
ResolvedRadialProgress resolveRadialProgress(
  BuildContext context, {
  CoreProgressSize size = CoreRadialProgressContract.defaultSize,
  CoreProgressTone tone = CoreRadialProgressContract.defaultTone,
  CoreRadialProgressStyle? radialProgressStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final radialTheme = theme.coreComponentTheme?.radialProgress;

  // ── Merge chain: project → instance ──
  final merged = resolveStyleChain(const CoreRadialProgressStyle(), [
    radialTheme?.style,
    radialProgressStyle,
  ]);

  final ringSize = CoreRadialProgressStyle
      .defaultsBySize[CoreRadialProgressStyle.sizeOf(size)]!;

  // ── Colour resolution ──
  final arcColor = scheme
      .resolve(
        merged.color ?? CoreRadialProgressStyle.defaultsByTone[tone]!.color!,
      )
      .toValue();

  final mergedBg = merged.backgroundColor;
  final trackAlpha = merged.backgroundAlpha;
  final trackColor = mergedBg != null
      ? scheme.resolve(mergedBg).toValue()
      : trackAlpha != null
      ? arcColor.scaleAlpha(trackAlpha)
      : scheme
            .resolve(CoreRadialProgressStyle.defaultBackgroundColor)
            .toValue();

  // ── Centre value-text typography (paint-ready TextStyle) ──
  // EMIT Stage 2 (Flutter) — `default.merge(override).toValue(theme:)`
  // materialises the single-source role default (`bodyLarge` + semi-bold
  // + `onSurface`) with any per-instance `valueTextStyle` overlay layered
  // on top, resolving the merged colour through the active scheme. Single
  // primitive — no hand-rolled `applyCoreTextStyle` / `resolveTypographyRole`
  // assembly.
  final valueTextStyleCore = ringSize.valueTextStyle == null
      ? merged.valueTextStyle
      : ringSize.valueTextStyle!.merge(merged.valueTextStyle);
  final valueTextStyle = valueTextStyleCore?.toValue(theme: theme);

  // ── Dimensional resolution ──
  final diameter = (merged.size ?? ringSize.size!) * scaling;
  final strokeWidth = theme.geometry.stroke(
    merged.strokeWidth ?? ringSize.strokeWidth!,
    scaling: scaling,
  );

  return ResolvedRadialProgress(
    color: arcColor,
    backgroundColor: trackColor,
    size: diameter,
    strokeWidth: strokeWidth,
    valueTextStyle: valueTextStyle,
  );
}
