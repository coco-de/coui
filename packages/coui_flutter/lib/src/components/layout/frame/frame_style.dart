library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Frame`.
///
/// Widget tree (`co_frame.dart` decides which optional branches render):
///
/// ```text
/// {flex wrapper: Flexible | none}
///   └─ {a11y wrapper: Semantics | none}
///        └─ {focus wrapper: Focus | none}
///             └─ {interaction wrapper: MouseRegion > GestureDetector | none}
///                  └─ {transform wrapper: Transform | none}
///                       └─ {layer-blur wrapper: ImageFiltered | none}
///                            └─ {opacity wrapper: Opacity | none}
///                                 └─ {margin wrapper: Padding | none}
///                                      └─ {align wrapper: Align | none}
///                                           └─ {sizing wrapper: SizedBox > ConstrainedBox | none}
///                                                └─ {chrome wrapper: AnimatedContainer (+CustomPaint dashed/inner, +BackdropFilter) | none}
///                                                     └─ {padding wrapper: Padding | none}
///                                                          └─ _buildContent (Row | Column | Wrap | child)
/// ```
///
/// Field grouping:
///
/// 1. **Paint-ready chrome** — every colour is a Flutter [Color]
///    (resolved through `scheme.resolve(x).toValue()`), every radius a
///    [BorderRadiusGeometry], every shadow stack a `List<BoxShadow>`,
///    and [borderWidth] carries `theme.scaling` pre-applied. The widget
///    reads these straight into `BoxDecoration` / `Border` / painters
///    without re-running merge / colour / scaling logic (Epic #1603
///    C9 / C11).
/// 2. **Behaviour** — [clipBehavior] (Flutter [Clip]) and [duration]
///    feed `AnimatedContainer` directly.
///
/// 3. **Spacing** — [padding], [margin] and [gap] carry the theme
///    density (`theme.geometry`): each moves one rung on the spacing
///    scale under a density other than standard, which makes them theme
///    values rather than caller values passed through.
///
/// Sizing / per-instance layout values (width, height, transform,
/// opacity, gradient, image, etc.) pass straight through to the widget
/// — they carry no theme / merge dependency, so they are not folded
/// into this struct.
class ResolvedFrame {
  /// Creates a [ResolvedFrame].
  const ResolvedFrame({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.dashLength,
    required this.dashSpacing,
    required this.borderStyle,
    required this.borderRadius,
    required this.padding,
    required this.margin,
    required this.gap,
    required this.elevation,
    required this.boxShadow,
    required this.innerShadow,
    required this.gradient,
    required this.backgroundImage,
    required this.clipBehavior,
    required this.duration,
    required this.curve,
  });

  /// Effective background colour (resolved). `null` → no fill.
  final Color? backgroundColor;

  /// Effective border colour (resolved). `null` → no border.
  final Color? borderColor;

  /// Effective border width (logical px, `theme.scaling` pre-applied).
  /// `null` → 0.
  final double? borderWidth;

  /// Dash segment length when the border style is dashed (raw logical
  /// px — the painter consumes it directly).
  final double dashLength;

  /// Gap between dash segments (raw logical px).
  final double dashSpacing;

  /// Effective border style.
  final CoreFrameBorderStyle borderStyle;

  /// Effective border radius (BorderRadiusGeometry-wrapped). `null` → no rounding.
  final BorderRadiusGeometry? borderRadius;

  /// Effective padding (EdgeInsetsGeometry-wrapped). `null` → no padding.
  final EdgeInsetsGeometry? padding;

  /// Effective margin (EdgeInsetsGeometry-wrapped). `null` → no margin.
  final EdgeInsetsGeometry? margin;

  /// Main-axis gap between children (logical px). `0` when the caller
  /// states none.
  final double gap;

  /// Effective elevation preset (drives the resting [boxShadow] when the
  /// caller does not pass an explicit `boxShadow` override).
  final CoreFrameElevation elevation;

  /// Paint-ready drop-shadow stack. The caller-supplied `boxShadow`
  /// override (resolved to Flutter [BoxShadow]s) when present, otherwise
  /// the [elevation] preset's shadow stack (empty for `none`). The
  /// shadow base colour resolved through `scheme.resolve(...)` (C7).
  final List<BoxShadow> boxShadow;

  /// Paint-ready inner-shadow stack — the caller-supplied `innerShadow`
  /// override resolved to Flutter [BoxShadow]s. Empty when the caller
  /// supplied none.
  final List<BoxShadow> innerShadow;

  /// Paint-ready background [Gradient]. `null` when the caller supplied
  /// none. Stop colours resolved through `scheme.resolve(...)` (C7).
  final Gradient? gradient;

  /// Paint-ready background [DecorationImage]. `null` when the caller
  /// supplied none.
  final DecorationImage? backgroundImage;

  /// Effective clip behaviour.
  final Clip clipBehavior;

  /// Effective animation duration.
  final Duration duration;

  /// The shape the chrome change takes over time.
  ///
  /// Paired with the duration beside it rather than left to the framework.
  /// Flutter's implicit animations default to `Curves.linear` and the Web
  /// twin's CSS transition does not — same length, different shape, so
  /// side by side one pane slides at a constant rate while the other eases
  /// in and out. Both platforms name the same `CoreEasing` alias instead.
  final Curve curve;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFrame] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreFrameStyle.defaultX / shadow* geometry)
///   → theme.coreComponentTheme.frame.style
///   → widget.frameStyle
///   → widget chrome props (backgroundColor, borderColor, …)
/// ```
ResolvedFrame resolveFrame(
  BuildContext context, {
  required CoreClipBehavior clipBehavior,
  CoreColor? backgroundColor,
  CoreColor? borderColor,
  double? borderWidth,
  CoreFrameBorderStyle? borderStyle,
  CoreBorderRadius? borderRadius,
  CoreEdgeInsets? padding,
  CoreEdgeInsets? margin,
  double? gap,
  CoreFrameElevation? elevation,
  List<CoreShadowLayer>? boxShadow,
  List<CoreShadowLayer>? innerShadow,
  CoreGradient? gradient,
  CoreImageSource? backgroundImage,
  Duration? duration,
  CoreFrameStyle? frameStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.frame;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFrameStyle(), [
    coreTheme?.style,
    frameStyle,
  ]);

  // ─── Resolved chrome (paint-ready Flutter values) ─────
  // Widget-level flat props win over the merged style chain so the
  // Figma "Inspect" surface stays 1:1. Colours convert through
  // `scheme.resolve(x).toValue()` only (Epic #1603 C7) so token
  // references survive the active light / dark scheme.
  final resolvedBackground = _resolveColor(
    scheme,
    backgroundColor ?? merged.backgroundColor,
  );
  final resolvedBorderColor = _resolveColor(
    scheme,
    borderColor ?? merged.borderColor,
  );
  // Border width carries `theme.scaling` pre-applied so the widget
  // paints it straight into `Border.all(width: …)` (Epic #1603 C11 —
  // no `* scaling` left in build()).
  final effectiveBorderWidth = borderWidth ?? merged.borderWidth;
  final dashLength = merged.dashLength ?? CoreFrameStyle.defaultDashLength;
  final dashSpacing = merged.dashSpacing ?? CoreFrameStyle.defaultDashSpacing;
  final resolvedBorderWidth = effectiveBorderWidth != null
      ? theme.geometry.stroke(effectiveBorderWidth, scaling: scaling)
      : null;
  final resolvedBorderStyle =
      borderStyle ?? merged.borderStyle ?? CoreFrameStyle.defaultBorderStyle;
  final resolvedBorderRadius = (borderRadius ?? merged.borderRadius)?.toValue(
    geometry: theme.geometry,
  );
  // Padding, margin and gap are spacing: the density moves each one rung
  // on the spacing scale. The frame applies no size factor to them — it
  // draws a caller's values as stated — so density is the only step here.
  final resolvedPadding = (padding ?? merged.padding)?.toValue(
    geometry: theme.geometry,
  );
  final resolvedMargin = margin?.toValue(geometry: theme.geometry);
  final resolvedGap = gap == null ? 0.0 : theme.geometry.space(gap);
  final resolvedElevation =
      elevation ?? merged.elevation ?? CoreFrameStyle.defaultElevation;

  // Shadow stacks — resolved here so the resolver output is paint-ready
  // and the widget build keeps no shadow-base lookup or layer conversion
  // (Epic #1603 C9 / C11). The shadow base colour routes through
  // `merged.shadowBaseColor ?? CoreFrameStyle.defaultShadowBaseColor` (the
  // `shadow` token) via the scheme resolver (C7) — never a direct
  // `scheme.shadow` reference. `.toValue()` falls back to opaque black
  // when the scheme leaves the token unset. A caller-supplied box-shadow
  // override wins over the elevation preset; the inner-shadow stack is
  // always the caller override.
  final shadowBase = scheme
      .resolve(merged.shadowBaseColor ?? CoreFrameStyle.defaultShadowBaseColor)
      .toValue();
  // Elevation → shadow reuses the canonical
  // `CoreOutlinedContainerElevation.toValue` adapter (both enums
  // share the same four levels via `toOutlinedContainerElevation()`) so
  // the frame's resting shadow geometry stays single-sourced with
  // `OutlinedContainer` instead of duplicating offset / blur / spread
  // constants (Epic #1603 C4 — single source, no resolver-local
  // `_kSoft*` geometry).
  final resolvedBoxShadow = boxShadow != null
      ? boxShadow.toValue(base: shadowBase, geometry: theme.geometry)
      : resolvedElevation.toOutlinedContainerElevation().toValue(
          base: shadowBase,
          geometry: theme.geometry,
        );
  final resolvedInnerShadow = innerShadow != null
      ? innerShadow.toValue(base: shadowBase, geometry: theme.geometry)
      : const <BoxShadow>[];

  // Background gradient / image — resolved to paint-ready Flutter types
  // here (Epic #1603 C9 / C11) so the widget reads them straight into
  // `BoxDecoration`. Gradient stop colours resolve through
  // `scheme.resolve(...)` (C7).
  final resolvedGradient = gradient?.toValue(scheme: scheme);
  final resolvedBackgroundImage = backgroundImage != null
      ? _imageToDecorationImage(backgroundImage)
      : null;

  // Clip behaviour — widget passes the contract default (`hardEdge`)
  // when nothing was set; in that case the merged-style override (if
  // present) wins.
  final effectiveClip = clipBehavior == CoreFrameStyle.defaultClipBehavior
      ? (merged.clipBehavior ?? clipBehavior)
      : clipBehavior;
  final resolvedClip = _clipToFlutter(effectiveClip);
  final resolvedDuration = resolveMotionDuration(
    context,
    duration ?? merged.duration ?? CoreFrameStyle.defaultDuration,
  );

  return ResolvedFrame(
    // The same alias the Web twin names for this element's CSS
    // transition. Chrome moving between states is `move`; a curve
    // stated on one platform and defaulted on the other is the
    // divergence nothing renders differently enough to notice until
    // the two are put side by side.
    curve: CoreEasing.move.toValue(),
    backgroundColor: resolvedBackground,
    borderColor: resolvedBorderColor,
    borderWidth: resolvedBorderWidth,
    dashLength: dashLength,
    dashSpacing: dashSpacing,
    borderStyle: resolvedBorderStyle,
    borderRadius: resolvedBorderRadius,
    padding: resolvedPadding,
    margin: resolvedMargin,
    gap: resolvedGap,
    elevation: resolvedElevation,
    boxShadow: resolvedBoxShadow,
    innerShadow: resolvedInnerShadow,
    gradient: resolvedGradient,
    backgroundImage: resolvedBackgroundImage,
    clipBehavior: resolvedClip,
    duration: resolvedDuration,
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (per-slot conversions — Epic #1603 C1:
// only `resolveFrame` is a public resolver)
// ═══════════════════════════════════════════════════

/// Converts a [CoreColor] to a Flutter [Color] through the active
/// [scheme]. Returns `null` for `null` input. Token references resolve
/// against the live light / dark scheme (Epic #1603 C7) — never
/// `Color(core.value)` which bypasses resolution and the opacity
/// modifier.
Color? _resolveColor(CoreColorScheme scheme, CoreColor? color) =>
    color != null ? scheme.resolve(color).toValue() : null;

/// Maps the contract [CoreClipBehavior] to the Flutter [Clip] enum.
Clip _clipToFlutter(CoreClipBehavior clip) => switch (clip) {
  .none => .none,
  .hardEdge => .hardEdge,
  .antiAlias => .antiAlias,
  .antiAliasWithSaveLayer => .antiAliasWithSaveLayer,
};

/// Converts a [CoreImageSource] to a paint-ready [DecorationImage].
DecorationImage _imageToDecorationImage(CoreImageSource src) {
  final ImageProvider<Object> provider = src.url != null
      ? NetworkImage(src.url!)
      : AssetImage(src.asset!);
  return DecorationImage(
    image: provider,
    fit: switch (src.fit) {
      .cover => .cover,
      .contain => .contain,
      .fill => .fill,
      .none => .none,
      .scaleDown => .scaleDown,
    },
    alignment: coreAlignmentToFlutter(src.alignment),
  );
}

// ═══════════════════════════════════════════════════
// Render-time enum mappers (pure CoreXxx → Flutter type maps used by
// `co_frame.dart` at build time — no theme / merge / scaling, so they
// stay public render helpers, not resolvers)
// ═══════════════════════════════════════════════════

/// Maps [CoreFrameDirection] to the corresponding flex axis. Returns
/// `null` for `wrap` since wrap is rendered via the [Wrap] widget.
Axis? coreFrameDirectionToAxis(CoreFrameDirection d) => switch (d) {
  .row || .rowReverse => .horizontal,
  .column || .columnReverse => .vertical,
  .wrap => null,
};

/// Maps [CoreFrameDirection] to the corresponding [VerticalDirection]
/// for [Column].
VerticalDirection coreFrameDirectionToVerticalDirection(
  CoreFrameDirection d,
) => switch (d) {
  .columnReverse => .up,
  .row || .rowReverse || .column || .wrap => .down,
};

/// Whether the direction reverses the main axis (used for [Row]
/// `textDirection`).
bool coreFrameDirectionIsReversed(CoreFrameDirection d) =>
    d == .rowReverse || d == .columnReverse;

/// Maps [CoreMainAxisAlignment] to Flutter [MainAxisAlignment].
MainAxisAlignment coreMainAxisAlignmentToFlutter(CoreMainAxisAlignment a) =>
    switch (a) {
      .start => .start,
      .end => .end,
      .center => .center,
      .spaceBetween => .spaceBetween,
      .spaceAround => .spaceAround,
      .spaceEvenly => .spaceEvenly,
    };

/// Maps [CoreCrossAxisAlignment] to Flutter [CrossAxisAlignment].
CrossAxisAlignment coreCrossAxisAlignmentToFlutter(
  CoreCrossAxisAlignment a,
) => switch (a) {
  .start => .start,
  .end => .end,
  .center => .center,
  .stretch => .stretch,
  .baseline => .baseline,
};

/// Maps [CoreFlexFit] to Flutter [FlexFit].
FlexFit coreFlexFitToFlutter(CoreFlexFit f) => switch (f) {
  .tight => .tight,
  .loose => .loose,
};

/// Maps [CoreFrameBorderStyle] to Flutter's native [BorderStyle].
/// `dashed` and `dotted` return [BorderStyle.none]; the caller paints
/// them via [CustomPaint].
BorderStyle coreFrameBorderStyleToFlutter(CoreFrameBorderStyle s) =>
    switch (s) {
      .solid => .solid,
      .none || .dashed || .dotted => .none,
    };

/// Maps [CoreCursor] to Flutter [SystemMouseCursors] / [MouseCursor].
MouseCursor coreCursorToFlutter(CoreCursor c) => switch (c) {
  .basic => SystemMouseCursors.basic,
  .pointer => SystemMouseCursors.click,
  .text => SystemMouseCursors.text,
  .grab => SystemMouseCursors.grab,
  .grabbing => SystemMouseCursors.grabbing,
  .forbidden => SystemMouseCursors.forbidden,
  .resizeColumn => SystemMouseCursors.resizeColumn,
  .resizeRow => SystemMouseCursors.resizeRow,
};
