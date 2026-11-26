import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Fieldset`.
///
/// Widget tree (`co_fieldset` decides which optional branches render):
///
/// ```text
/// Opacity (enabled → 1.0 | disabled → CoreOpacity.opacity50)
///   └─ SizedBox (width: double.infinity)
///        └─ InjectedCast (boxShadow, castBorderRadius)
///             └─ OutlinedContainer (containerStyle, role: .content)
///                  └─ Column (crossAxisAlignment.stretch)
///                       ├─ Column                                    // legend != null || description != null
///                       │    ├─ Padding (legendPadding)              // legend != null
///                       │    │    └─ DefaultTextStyle (legendTextStyle)
///                       │    │         └─ legend                      // caller Widget
///                       │    ├─ Gap (legendDescriptionGapStyle)      // both != null
///                       │    └─ DefaultTextStyle (descriptionTextStyle)
///                       │         └─ description                     // caller Widget
///                       ├─ Gap (headerFieldsGapStyle)                // header && children
///                       └─ Column (spacing: fieldSpacing)            // children
///                            └─ ...children                          // caller Widgets
/// ```
///
/// Which box the panel draws — fill, edge, corner, padding — is the
/// variant's row (`CoreFieldsetStyle.defaultsByVariant`); `plain` draws none
/// and `OutlinedContainer` is composed with zero chrome, no blur and no cast.
///
/// The panel is composed (Epic #4349) — [containerStyle] carries a
/// pre-EMIT `CoreOutlinedContainerStyle` bundle, and `OutlinedContainer`
/// runs the scheme-resolve / geometry / scaling bend itself. The cast
/// is painted a layer above it via `InjectedCast` rather than inside
/// the composed decoration — see [boxShadow]'s doc for why.
///
/// Dimensional values are raw logical px (pre-scaling); scaling is
/// applied at the widget use site (Epic #1603 C11 — the widget is
/// render-only and applies `theme.scaling` once per surface).
class ResolvedFieldset {
  /// Creates a [ResolvedFieldset].
  const ResolvedFieldset({
    required this.containerStyle,
    required this.boxShadow,
    required this.castBorderRadius,
    required this.fieldSpacing,
    required this.legendPadding,
    required this.legendTextStyle,
    required this.descriptionTextStyle,
    required this.legendDescriptionGapStyle,
    required this.headerFieldsGapStyle,
  });

  /// Composed-`OutlinedContainer` chrome for the fieldset panel box
  /// (pre-EMIT `CoreOutlinedContainerStyle`). `surfaceBlur: 0` is
  /// forced whenever the effective background resolves to the
  /// token-less transparent sentinel (`CoreFieldsetStyle
  /// .defaultBackgroundColor`, the `outlined` / `plain` fill) —
  /// `OutlinedContainer` does not gate material on fill opacity itself,
  /// so an unguarded blur here would frost a box with no tint to
  /// explain it (`core/theme-axis-composition.md`'s "표면 처리는
  /// 표면이 자기를 표면으로 말할 때만 닿는다"). Left unset whenever a
  /// caller supplies a real token background.
  ///
  /// `boxShadow` is explicitly forced to an empty list (not left null)
  /// whenever there is no fill — an explicit empty stack tells
  /// `OutlinedContainer`'s own resolver not to fall back to the active
  /// style's `controlShadow` (see [boxShadow]'s doc for why painting
  /// that cast here would be unsafe). Left null (the style's normal
  /// fallback) whenever a caller supplies a real token background,
  /// since an opaque fill cannot show a shadow through itself.
  final CoreOutlinedContainerStyle containerStyle;

  /// The style's injected cast, painted outside [containerStyle]
  /// entirely via `InjectedCast` — empty whenever there is a fill
  /// (`OutlinedContainer`'s own `BoxDecoration.boxShadow` already
  /// paints that case safely, an opaque fill cannot show a shadow
  /// through itself).
  ///
  /// The `outlined` / `plain` background is the token-less transparent
  /// sentinel, so its fill can be non-opaque in the way
  /// `core/theme-axis-composition.md`'s "그림자는 두 플랫폼이 다른
  /// 곳에 칠한다" describes — a `BoxDecoration.boxShadow` on that
  /// state would paint a filled rounded rect behind the box that
  /// shows straight through it (CSS clips an outer shadow to outside
  /// the border box; Flutter does not). `OutlinedContainer` composes
  /// that unconditionally-unsafe path for every caller regardless of
  /// fill opacity, so the unfilled state routes its cast through this
  /// field instead, painted by an `InjectedCast` wrapped around the
  /// composed `OutlinedContainer` rather than inside its decoration.
  final List<BoxShadow> boxShadow;

  /// The panel's own corner radius, materialised the same way
  /// `OutlinedContainer`'s internal resolver does (unscaled — the
  /// primitive does not scale its own radius) so the external
  /// `InjectedCast` knocks out exactly the shape the composed box
  /// paints, with no visible sliver at the corners.
  final BorderRadius castBorderRadius;

  /// Effective spacing between children (logical px, pre-scaling).
  final double fieldSpacing;

  /// Effective padding around the legend (logical px, pre-scaling).
  final EdgeInsets legendPadding;

  /// Paint-ready legend [TextStyle] — the size-keyed design-system
  /// default legend typography (`titleSmall`/`titleMedium` + `onSurface`,
  /// or [CoreFieldsetStyle.defaultDisabledLegendColor] when disabled)
  /// merged with the per-instance override, materialised through
  /// `style.toValue(theme:)` (token role + colour resolved in one
  /// primitive). The widget passes it straight to `DefaultTextStyle` so
  /// the legend slot inherits it.
  final TextStyle legendTextStyle;

  /// Paint-ready description [TextStyle] — the design-system default
  /// (`bodySmall` + `onSurfaceVariant`) merged with the per-instance
  /// override, materialised through `style.toValue(theme:)`. The disabled
  /// state does not recolour it: the panel's own opacity dims it with the
  /// rest of the group.
  final TextStyle descriptionTextStyle;

  /// Gap between the legend and the description beneath it — nested
  /// [CoreGapStyle] forwarded raw to `Gap` (the primitive scales itself).
  final CoreGapStyle legendDescriptionGapStyle;

  /// Gap between the header (legend, then description) and the first
  /// field — nested [CoreGapStyle] forwarded raw to `Gap`.
  final CoreGapStyle headerFieldsGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFieldset] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreFieldsetStyle.default*,
///                        defaultsByVariant[variant], defaultsBySize[size])
///   → theme.coreComponentTheme.fieldset.style
///   → theme.coreComponentTheme.fieldset.variantStyles[variant]
///   → widget.fieldsetStyle
/// ```
ResolvedFieldset resolveFieldset(
  BuildContext context, {
  required CoreComponentSize size,
  CoreFieldsetVariant variant = CoreFieldsetVariant.defaultVariant,
  bool enabled = true,
  CoreFieldsetStyle? fieldsetStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final csTheme = theme.coreComponentTheme?.fieldset;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFieldsetStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    fieldsetStyle,
  ]);
  final variantStyle = CoreFieldsetStyle.defaultsByVariant[variant]!;

  // ─── Resolved chrome ──────────────────────────────────
  final fieldSpacing =
      theme.geometry.space(
        merged.fieldSpacing ?? CoreFieldsetStyle.defaultFieldSpacing,
      ) *
      scaling;
  final legendPadding =
      ((merged.legendPadding ?? CoreFieldsetStyle.defaultLegendPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT ──────────
  // The panel is the box `Card` / `Checkbox` compose, not a hand-rolled
  // decoration — passing Core values (not resolved ones) is what keeps
  // the scheme-resolve / geometry / scaling bend applied exactly once,
  // by `OutlinedContainer` itself.
  //
  // Fill, edge, corner and padding resolve through the variant's row
  // (`CoreFieldsetStyle.defaultsByVariant`), the same single source-of-truth
  // table Web reads. A raw colour whose token is null and whose ARGB is `0`
  // (the transparent sentinel, `outlined` / `plain`) means "no fill" — see
  // [containerStyle]'s doc for why that forces `surfaceBlur: 0` rather than
  // leaving it for the active material preset to fill in.
  final backgroundToken =
      merged.backgroundColor ?? variantStyle.backgroundColor!;
  final borderColor = merged.borderColor ?? variantStyle.borderColor!;
  final borderRadius = merged.borderRadius ?? variantStyle.borderRadius!;
  final borderWidth = merged.borderWidth ?? variantStyle.borderWidth!;
  final hasFill = backgroundToken.token != null || backgroundToken.argb != 0;
  // A box exists when it paints a fill or an edge. `plain` states neither,
  // so no material, no blur and no cast reach it — a cast around nothing
  // would float as a stray shadow.
  final hasEdge =
      borderWidth > 0 && (borderColor.token != null || borderColor.argb != 0);
  final hasBox = hasFill || hasEdge;
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundToken,
    borderColor: borderColor,
    borderRadius: borderRadius,
    borderWidth: borderWidth,
    padding: merged.padding ?? variantStyle.padding!,
    surfaceBlur: hasFill ? null : 0,
    // `OutlinedContainer` paints its own cast fallback straight into
    // `BoxDecoration.boxShadow`, which is only safe when the fill is
    // opaque in every state (see [boxShadow]'s doc). A fill-less box is
    // not, so it states an explicit empty stack here (not left null) — an
    // explicit empty list tells the composed resolver not to reach for the
    // active style's `controlShadow` fallback, unlike a null which would.
    boxShadow: hasFill ? null : const [],
  );

  // The cast painted safely, outside the composed box's own decoration
  // — empty whenever there is a fill (an opaque `OutlinedContainer`
  // fill cannot show a shadow through itself, so its own suppressed-
  // fallback-then-normal cast is fine as is) and whenever there is no box
  // at all.
  final boxShadow = (hasFill || !hasBox)
      ? const <BoxShadow>[]
      : resolveInjectedCast(theme);
  final castBorderRadius = borderRadius.toValue(geometry: theme.geometry);

  // ─── Legend typography (paint-ready TextStyle) ────────
  // Stage 1 RESOLVE — the size-keyed default (role + colour) is the merge
  // base, not `defaultLegendTextStyle` directly — `xs`/`sm`/`md` settle
  // on the 16px `titleSmall` rung, `lg`/`xl`/`xl2` on the 18px
  // `titleMedium` rung (`CoreFieldsetStyle.defaultsBySize`).
  final sizeLegendTextStyle =
      CoreFieldsetStyle.defaultsBySize[size]!.legendTextStyle!;
  final disabledLegendColor =
      merged.disabledLegendColor ??
      CoreFieldsetStyle.defaultDisabledLegendColor;

  // `enabled` forces the colour half of the legend's composite style —
  // the size-derived role (fontSize/weight) still applies underneath,
  // and any per-instance colour override is overridden right back to
  // `disabledLegendColor` rather than silently winning over the disabled
  // state (the same "select between resolved values" shape
  // `resolveFormLabel` uses, not a runtime DETECTION branch — `enabled`
  // is a build-time semantic prop here, same as `Fieldset.enabled`).
  final legendStyleBase = enabled
      ? sizeLegendTextStyle
      : sizeLegendTextStyle.copyWith(color: disabledLegendColor);
  final legendStyleOverride = enabled
      ? merged.legendTextStyle
      : merged.legendTextStyle?.copyWith(color: disabledLegendColor);
  final legendCore = legendStyleBase.merge(legendStyleOverride);

  // EMIT Stage 2 (Flutter) — `style.toValue(theme:)` materialises the
  // token role and resolves its colour through the active scheme in one
  // primitive. No hand-rolled `theme.typography.resolve` / `scheme
  // .resolve` assembly (badge reference uses the same
  // `.toValue(theme:)` path).
  final legendTextStyle = legendCore.toValue(theme: theme);

  // ─── Description + header gaps ────────────────────────
  // The description is secondary text under the legend: its colour does not
  // switch with `enabled` (the panel's own opacity dims it with the rest).
  // The two gaps are nested `CoreGapStyle` slots — composite, so
  // `default.merge(merged)`, then forwarded raw to `Gap`.
  final descriptionTextStyle = CoreFieldsetStyle.defaultDescriptionTextStyle
      .merge(merged.descriptionTextStyle)
      .toValue(theme: theme);
  final legendDescriptionGapStyle = CoreFieldsetStyle
      .defaultLegendDescriptionGapStyle
      .merge(merged.legendDescriptionGapStyle);
  final headerFieldsGapStyle = CoreFieldsetStyle.defaultHeaderFieldsGapStyle
      .merge(merged.headerFieldsGapStyle);

  return ResolvedFieldset(
    containerStyle: containerStyle,
    boxShadow: boxShadow,
    castBorderRadius: castBorderRadius,
    fieldSpacing: fieldSpacing,
    legendPadding: legendPadding,
    legendTextStyle: legendTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    legendDescriptionGapStyle: legendDescriptionGapStyle,
    headerFieldsGapStyle: headerFieldsGapStyle,
  );
}
