/// Single-entry resolver for `Banner` (Flutter).
///
/// Encapsulates Epic #1302 merge chain (`theme.banner.style` →
/// `theme.banner.variantStyles` for the variant → `widget.bannerStyle`)
/// and converts the resolved [CoreBannerStyle] + variant chrome to a typed
/// [ResolvedBanner] paint-ready bundle. The widget reads from
/// [ResolvedBanner] only — no direct `theme.coreComponentTheme` or
/// `.merge()` calls inside the build method.
library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Banner`.
///
/// Widget tree (`co_banner.dart` builds):
///
/// ```text
/// InjectedCast (boxShadow, radius)                    // the style's cast, outside the box
///   └─ SurfaceBlur (surfaceBlur / surfaceSaturation / surfaceBackdropBrightness / surfaceSheen)
///        └─ Container (padding, decoration: bg + bottom rule + radius)
///             └─ Row
///                  └─ Expanded
///                       └─ BannerBody (iconContentGap / contentTrailingGap /
///                          │           contentMinWidth / trailingRunSpacing)
///                            ├─ Icon (variant icon)     // when showIcon
///                            ├─ Column                  // message column
///                            │    ├─ DefaultTextStyle (titleTextStyle)
///                            │    │    └─ message
///                            │    ├─ Gap (titleDescriptionGapStyle)
///                            │    └─ DefaultTextStyle (descriptionTextStyle)
///                            │         └─ description
///                            └─ Row                     // trailing group
///                                 ├─ action             // when action
///                                 ├─ Gap (contentDismissGapStyle) // both
///                                 └─ Button.plain (closeButtonStyle)
///                                      └─ Icon (x)      // when onDismiss
/// ```
///
/// `BannerBody` keeps the trailing group beside the message column while
/// the column can keep [contentMinWidth]; otherwise the trailing group
/// moves to its own line, [trailingRunSpacing] below, starting where the
/// message text starts. The icon is centred on the message column in both
/// poses.
///
/// The accent border is a single bottom-edge rule — a shape
/// `CoreOutlinedContainerStyle.borderWidth` cannot express (it applies
/// uniformly via `Border.all`), so this surface cannot compose
/// `OutlinedContainer` as its outer box without either drawing a border
/// on all four sides or dropping the accent. Instead it reuses the same
/// shared material-resolution primitives that primitive's own resolver
/// calls (`theme.surfaceFor` / `resolveSurfaceStroke` /
/// `resolveSurfaceSheen` / `resolveInjectedCast`) so the active theme's
/// material and the cast it hands a resting box still reach this one —
/// the pattern `Dock` already uses for its own asymmetric (top-only)
/// border. Carries paint-ready values; the widget never has to spell out
/// the fallback chain inline.
class ResolvedBanner {
  /// Creates a [ResolvedBanner].
  const ResolvedBanner({
    required this.variant,
    required this.backgroundColor,
    required this.borderColor,
    required this.minHeight,
    required this.iconStyle,
    required this.borderRadius,
    required this.borderWidth,
    required this.padding,
    required this.iconContentGapStyle,
    required this.contentDismissGapStyle,
    required this.titleDescriptionGapStyle,
    required this.iconContentGap,
    required this.contentTrailingGap,
    required this.contentMinWidth,
    required this.trailingRunSpacing,
    required this.closeButtonStyle,
    required this.titleTextStyle,
    required this.descriptionTextStyle,
    required this.actionButtonStyle,
    required this.plainActionButtonStyle,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.boxShadow,
  });

  /// Semantic variant.
  final CoreBannerVariant variant;

  /// Resolved background fill colour (alpha already includes the active
  /// theme's surface-material opacity, if any).
  final Color backgroundColor;

  /// Bottom-rule colour, or `null` when this emphasis draws no rule at
  /// all. Null means the widget omits the border outright rather than
  /// painting a transparent one, which would still take up its width.
  final Color? borderColor;

  /// Minimum band height (logical px, scaling applied).
  final double minHeight;

  /// Nested `CoreIconStyle` slot — forwarded straight to
  /// `Icon(iconStyle: …)` for the leading variant glyph. Carries the
  /// resolved variant icon size (raw / pre-scaling — `Icon`'s own
  /// resolver applies `theme.scaling`) and the resolved variant icon
  /// colour overlaid as a raw-ARGB `CoreColor`.
  final CoreIconStyle iconStyle;

  /// Border radius (pre-scaling).
  final BorderRadius borderRadius;

  /// Border width in logical px (pre-scaling).
  final double borderWidth;

  /// Padding in logical px (pre-scaling).
  final EdgeInsets padding;

  /// Nested gap style between leading icon / text column / trailing
  /// slots — forwarded straight to `Gap(gapStyle: …)`. `Gap`
  /// applies `theme.scaling` itself, so the resolver leaves this in
  /// pre-scaling units.
  final CoreGapStyle iconContentGapStyle;

  /// Nested gap style before the dismiss button — forwarded straight to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle contentDismissGapStyle;

  /// Nested vertical gap style between the title and description —
  /// forwarded straight to `Gap(gapStyle: …)`.
  final CoreGapStyle titleDescriptionGapStyle;

  /// Gap after the leading icon (logical px, density and scaling applied) —
  /// `iconContentGapStyle`, measured the way `Gap` measures it.
  final double iconContentGap;

  /// Horizontal gap between the message column and the trailing group
  /// while both share a line (logical px, density and scaling applied) —
  /// `iconContentGapStyle` when an action leads the trailing group,
  /// `contentDismissGapStyle` when the dismiss button does. Not drawn once
  /// the trailing group has wrapped.
  final double contentTrailingGap;

  /// Narrowest the message column may get beside the trailing group
  /// (logical px, scaling applied). A layout bound, so density does not
  /// move it.
  final double contentMinWidth;

  /// Vertical gap above a wrapped trailing group (logical px, density and
  /// scaling applied).
  final double trailingRunSpacing;

  /// Nested `CoreButtonStyle` slot — raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)` for the dismiss
  /// affordance. Chained
  /// `CoreBannerStyle.defaultCloseButtonStyle` → variant-foreground
  /// injection → caller `closeButtonStyle`; `Button`'s own resolver
  /// resolves the colours / padding / hover-fade and self-applies
  /// `theme.scaling`. The close glyph is a `Icon` child reading
  /// `closeButtonStyle.leadingIconStyle`.
  final CoreButtonStyle closeButtonStyle;

  /// Paint-ready title text style (typography role + overlay color).
  final TextStyle titleTextStyle;

  /// Paint-ready description text style (typography role + overlay
  /// color).
  final TextStyle descriptionTextStyle;

  /// Nested [CoreButtonStyle] slot — forwarded to a `Button` action
  /// (asChild pattern), carrying the variant's foreground under the
  /// caller's own fields. Never null: the injection always states a
  /// colour, so an action that is a `Button` always has chrome to
  /// receive.
  final CoreButtonStyle actionButtonStyle;

  /// [actionButtonStyle] plus the inline inset a `plain` action needs —
  /// the bundle the widget forwards when the action is a `plain` `Button`.
  final CoreButtonStyle plainActionButtonStyle;

  /// Backdrop blur sigma from the active theme's surface-material
  /// treatment, or `null` when the surface is an opaque fill. Mirrors
  /// `OutlinedContainer`'s own `surfaceBlur` — `co_banner` wraps its
  /// `Container` in `SurfaceBlur` to apply it since this surface does
  /// not compose that primitive.
  final double? surfaceBlur;

  /// Chroma lift riding the same material treatment as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material. Rides the same backdrop pass as
  /// [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// The cast the active surface style contributes to this band — empty
  /// under every style that contributes none.
  ///
  /// A banner authors no shadow of its own, so it is exactly the surface
  /// `CoreSurfaceGeometryConstraint.controlShadow` is for: one that paints
  /// its own fill and has nothing for the style's shadow transform to bend.
  /// `OutlinedContainer` hands a composed surface the same cast at rest, and
  /// this band cannot compose that primitive (see the class doc), so it
  /// restates the contribution. The Web twin reaches the same cast through
  /// `kControlShadowRestMarker`.
  ///
  /// Painted outside the box (`InjectedCast`) rather than behind it: a
  /// material preset makes this fill translucent, and a cast drawn behind
  /// a translucent fill shows through it on Flutter only
  /// (`cross-platform/api.md`, "그림자는 두 플랫폼이 다른 곳에 칠한다").
  final List<BoxShadow> boxShadow;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves the banner Style chain to a typed [ResolvedBanner].
///
/// Merge chain:
///
/// ```text
/// design system default
///   → CoreBannerTheme.style
///   → CoreBannerTheme.variantStyles[variant]
///   → widget.bannerStyle
/// ```
///
/// Then variant token table fills the remaining gaps before returning
/// paint-ready Flutter types.
///
/// [hasAction] says which slot leads the trailing group — the action, or
/// the dismiss button alone — and so which gap the message column keeps
/// from it on one line ([ResolvedBanner.contentTrailingGap]).
ResolvedBanner resolveBanner(
  BuildContext context, {
  required CoreBannerVariant variant,
  required CoreBannerEmphasis emphasis,
  bool hasAction = false,
  CoreBannerStyle? bannerStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final bannerTheme = theme.coreComponentTheme?.banner;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreBannerStyle(), [
    bannerTheme?.style,
    bannerTheme?.variantStyles?[variant],
    bannerStyle,
  ]);

  // Semantic identifier (`variant`) comes straight from the widget — the
  // theme cannot override it (render-only.md (c)). Web resolves it
  // identically, so the two platforms stay 1:1.

  // ─── Variant chrome (single source — defaultsByVariant) ───
  // Two axes: the tone says what kind of message this is, the emphasis says
  // how hard it presses. Both are semantic identifiers off the widget, so
  // neither is theme-overridable and Web resolves the same pair.
  final vs = CoreBannerStyle.defaultsByVariant[variant]![emphasis]!;

  // ─── Stage1 RESOLVE — dimensional (all local var) ─────────
  final padding = merged.padding ?? CoreBannerStyle.defaultPadding;
  final iconContentGapStyle = CoreBannerStyle.defaultIconContentGapStyle.merge(
    merged.iconContentGapStyle,
  );
  final iconSize =
      merged.iconStyle?.size ?? CoreBannerStyle.defaultIconStyle.size;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreBannerStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final borderRadius =
      merged.borderRadius ?? CoreBannerStyle.defaultBorderRadius;
  final contentDismissGapStyle = CoreBannerStyle.defaultContentDismissGapStyle
      .merge(merged.contentDismissGapStyle);
  final titleDescriptionGapStyle = CoreBannerStyle
      .defaultTitleDescriptionGapStyle
      .merge(merged.titleDescriptionGapStyle);

  // ─── Stage1 RESOLVE — colour (all local var) ──────────────
  final backgroundColorCore = merged.backgroundColor ?? vs.backgroundColor;
  // Nullable by design: `solid` states no rule at all. A null here means
  // "draw no stroke", NOT "draw a transparent one" — a transparent stroke
  // would still occupy its width and make `solid` a hair taller than `weak`.
  final borderColorCore = merged.borderColor ?? vs.borderColor;
  final foregroundColorCore = merged.foregroundColor ?? vs.textColor;
  // Separate from the title colour: on every `weak` pair the description
  // drops to `onSurfaceVariant` while the message keeps the tone's
  // foreground. Reusing `textColor` here would only be right on `solid`.
  final descriptionColorCore = merged.foregroundColor ?? vs.descriptionColor;
  // Effective leading-icon colour — the caller `iconStyle.color` else the
  // variant colour. Stays unresolved so it bakes into the icon slot below
  // (and feeds the dismiss fallback) with no resolve→re-wrap round-trip.
  final iconColor = merged.iconStyle?.color ?? vs.iconColor;
  // Paint-ready leading-icon slot — caller `iconStyle` overlaid with the
  // resolved variant size + colour. The widget forwards this straight to
  // `Icon(iconStyle: …)`, whose own resolver resolves the colour +
  // applies `theme.scaling` to the raw size.
  final iconStyle = (merged.iconStyle ?? const CoreIconStyle()).merge(
    CoreIconStyle(size: iconSize, color: iconColor),
  );
  // Dismiss-button chrome — the chained `defaultCloseButtonStyle` plus
  // the variant-tinted foreground; the per-instance override merges on
  // top. Raw-forwarded to a plain-variant
  // `Button` whose own resolver handles the padding / colours /
  // hover-fade and `theme.scaling`, so the resolver does NOT scale here
  // (Anti-Pattern A, mirroring the toast close button).
  // The glyph paints the variant's own foreground token at full strength,
  // resting and hovered alike. It used to rest at 70 % of that token and
  // fade up on hover, which produced a composited colour no contrast guard
  // could evaluate — that is why the two opacity constants are deprecated
  // rather than retuned. A caller who wants a dimmer dismiss sets
  // `closeButtonStyle.foregroundColor` to a token that is actually dimmer.
  //
  // The variant row's focus-ring slot rides along: a solid row fills the
  // banner with a saturated colour, so its buttons state an opaque gap
  // band; a weak row states none and keeps the transparent default. The
  // caller's own slot still merges on top.
  final closeButtonStyle = CoreBannerStyle.defaultCloseButtonStyle
      .merge(
        CoreButtonStyle(
          foregroundColor: iconColor,
          hoverForegroundColor: iconColor,
          focusOutlineStyle: vs.focusOutlineStyle,
        ),
      )
      .merge(merged.closeButtonStyle);

  // Action-button chrome — the variant's own foreground, then the
  // per-instance override on top (so a caller still wins). Same shape as
  // the dismiss injection above, and as `Toast`'s action.
  //
  // Without the injection a `Button` action keeps `plain`'s own label
  // colour, which is picked for a light neutral surface. On a solid
  // banner that is a dark grey label on a saturated fill: the message,
  // description, leading icon and dismiss glyph all track the variant
  // and the action alone did not. `foregroundColorCore` is the same
  // value the title paints, so the action reads as part of the banner
  // rather than as a control that landed on it.
  // The banner/toast foreground every action wears — shared by the two
  // bundles below so the plain one cannot drift from the other.
  final actionForegroundStyle = CoreButtonStyle(
    foregroundColor: foregroundColorCore,
    hoverForegroundColor: foregroundColorCore,
    focusOutlineStyle: vs.focusOutlineStyle,
  );
  final actionButtonStyle = CoreBannerStyle.defaultActionButtonStyle
      .merge(actionForegroundStyle)
      .merge(merged.actionButtonStyle);
  // A `plain` action gets the inline inset its variant lacks — and only
  // it; every other variant keeps its own size row's inset. The caller's
  // `actionButtonStyle` still wins over that default, the plain slot over
  // both. The widget picks between the two by the action's variant.
  final plainActionButtonStyle = CoreBannerStyle.defaultActionButtonStyle
      .merge(CoreBannerStyle.defaultPlainActionButtonStyle)
      .merge(actionForegroundStyle)
      .merge(merged.actionButtonStyle)
      .merge(merged.plainActionButtonStyle);

  // ─── Stage1 RESOLVE — typography composite (all local var) ─
  final titleCore = CoreBannerStyle.defaultTitleStyle.merge(merged.titleStyle);
  final descriptionCore = CoreBannerStyle.defaultDescriptionStyle.merge(
    merged.descriptionStyle,
  );

  // ─── Surface material (theme.surfaceFor — mirrors OutlinedContainer's
  //     own resolver, reused directly since the asymmetric accent border
  //     blocks composing that widget as this surface's outer box) ─────
  // A theme-wide surface treatment reaches the banner the same way it
  // reaches a card — otherwise the banner stays opaque while every panel
  // around it turns translucent.
  final material = theme.surfaceFor(
    .content,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(theme);

  // ─── Stage2 EMIT (Flutter, theme-aware — all local var) ───
  final backgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundColorCore
            : backgroundColorCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border.
  final borderColor = borderColorCore == null
      ? null
      : resolveSurfaceStroke(theme, scheme.resolve(borderColorCore).toValue());
  final foregroundColor = scheme.resolve(foregroundColorCore).toValue();
  final descriptionColor = scheme.resolve(descriptionColorCore).toValue();
  final minHeight =
      (merged.minHeight ?? CoreBannerStyle.defaultMinHeight) * scaling;
  // The gap the message column keeps from the trailing group on one line —
  // the gap the widget used to place before whichever leads that group (the
  // action, else the dismiss). Spacing, so density moves it the way `Gap`
  // moves it; both gap styles carry a size through their defaults.
  final iconContentGap =
      theme.geometry.space(iconContentGapStyle.size!) * scaling;
  final contentTrailingGap =
      theme.geometry.space(
        (hasAction ? iconContentGapStyle : contentDismissGapStyle).size!,
      ) *
      scaling;
  // A layout bound — scaled, not moved by density.
  final contentMinWidth =
      (merged.contentMinWidth ?? CoreBannerStyle.defaultContentMinWidth) *
      scaling;
  final trailingRunSpacing =
      theme.geometry.space(
        merged.trailingRunSpacing ?? CoreBannerStyle.defaultTrailingRunSpacing,
      ) *
      scaling;
  final paddingValue = (padding.toValue(geometry: theme.geometry)) * scaling;
  final borderRadiusValue =
      (borderRadius.toValue(geometry: theme.geometry)) * scaling;
  // The style's contributed cast — this band authors no shadow, so there is
  // nothing for the style to bend and the contribution is the whole of it.
  final boxShadow = resolveInjectedCast(theme);
  // Title / description — `style.toValue(theme:)` materialises the
  // size-aware token role and resolves its colour. When the per-instance
  // style carries no explicit colour the `color:` override forces the
  // variant foreground so the label tracks the variant tone.
  final titleTextStyle = titleCore.toValue(
    color: titleCore.color == null ? foregroundColor : null,
    theme: theme,
  );
  final descriptionTextStyle = descriptionCore.toValue(
    color: descriptionCore.color == null ? descriptionColor : null,
    theme: theme,
  );

  // ─── RETURN = bare 매핑 (+ dimensional * scaling) ─────────
  return ResolvedBanner(
    variant: variant,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    minHeight: minHeight,
    // Raw forward — `Icon`'s own resolver applies `theme.scaling` to the
    // slot size; the variant colour is already baked in as a raw-ARGB
    // `CoreColor`.
    iconStyle: iconStyle,
    borderRadius: borderRadiusValue,
    borderWidth: borderWidth,
    padding: paddingValue,
    iconContentGapStyle: iconContentGapStyle,
    contentDismissGapStyle: contentDismissGapStyle,
    titleDescriptionGapStyle: titleDescriptionGapStyle,
    iconContentGap: iconContentGap,
    contentTrailingGap: contentTrailingGap,
    contentMinWidth: contentMinWidth,
    trailingRunSpacing: trailingRunSpacing,
    // Raw forward — flows straight into
    // `Button(variant: .plain, buttonStyle: …)`; the button's own
    // resolver resolves colours / padding and applies `theme.scaling`.
    closeButtonStyle: closeButtonStyle,
    titleTextStyle: titleTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    actionButtonStyle: actionButtonStyle,
    plainActionButtonStyle: plainActionButtonStyle,
    surfaceBlur: material?.blurRadius,
    surfaceSaturation: material?.saturation,
    surfaceBackdropBrightness: material?.backdropBrightnessIn(theme),
    surfaceSheen: resolveSurfaceSheen(theme),
    boxShadow: boxShadow,
  );
}
