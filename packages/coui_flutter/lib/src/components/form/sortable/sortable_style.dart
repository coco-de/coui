import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedSortable
// ═══════════════════════════════════════════════════

/// Resolver output for `Sortable`.
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus token / colour fallback. Dimensional
/// values are post-scaling (`theme.scaling` already applied).
class ResolvedSortable {
  /// Creates a [ResolvedSortable].
  const ResolvedSortable({
    required this.itemBackgroundColor,
    required this.itemHoverColor,
    required this.disabledItemBackgroundColor,
    required this.itemBorderColor,
    required this.disabledItemBorderColor,
    required this.itemBorderWidth,
    required this.itemMinHeight,
    required this.surfaceOpacity,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.handleIconStyle,
    required this.handleDisabledIconStyle,
    required this.handleFocusOutlineStyle,
    required this.removeButtonStyle,
    required this.itemTextStyle,
    required this.disabledItemTextStyle,
    required this.disabledRemoveButtonStyle,
    required this.itemBorderRadius,
    required this.itemSpacing,
    required this.itemPadding,
    required this.handlePadding,
    required this.animationDuration,
    required this.proxyScale,
    required this.proxyElevation,
    required this.proxyInsetShadow,
    required this.curve,
  });

  /// Resolved item background colour (default token fallback applied).
  final Color itemBackgroundColor;

  /// Resolved item hover background colour (default token fallback applied).
  final Color itemHoverColor;

  /// Resolved item background colour while the list is disabled — the
  /// dedicated disabled container token.
  final Color disabledItemBackgroundColor;

  /// Resolved item border colour.
  final Color itemBorderColor;

  /// Resolved item border colour while the list is disabled.
  final Color disabledItemBorderColor;

  /// Resolved item border width (logical px, post-geometry).
  final double itemBorderWidth;

  /// Resolved minimum item height (logical px, post-scaling).
  final double itemMinHeight;

  /// The active style's content-role material opacity, or `null` when the
  /// style states no material — regardless of whether an item's fill is
  /// actually painted.
  ///
  /// The widget reads this on its own (unlike [surfaceBlur] and its
  /// siblings, which additionally gate on the fill being painted): it
  /// decides whether an item's fill *can* turn translucent at all, which
  /// decides whether the drag-proxy's lift shadow has to move off
  /// `BoxDecoration.boxShadow` and onto `InjectedCast`
  /// (`core/theme-axis-composition.md` — "그림자는 두 플랫폼이 다른 곳에
  /// 칠한다"). Every non-glass preset leaves this `null`.
  final double? surfaceOpacity;

  /// Backdrop blur sigma for each item's own box, `null` when the active
  /// theme states no material or the item paints no fill of its own to
  /// blur behind (an explicit transparent `itemBackgroundColor` override)
  /// — see [itemBackgroundColor].
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through each item, or
  /// null for no material.
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Per-state drag-handle icon style (size + colour token) for the
  /// interactive list — `onSurfaceSubtle`. The resolver owns the icon
  /// chrome so the widget forwards a `CoreIconStyle` to `Icon` rather
  /// than a raw `Color`. The per-state colour wins over a caller's
  /// `iconStyle.color` — override the colour via `handleColor` /
  /// `removeButtonColor` instead.
  final CoreIconStyle handleIconStyle;

  /// Per-state drag-handle icon style for the non-interactive list —
  /// the dedicated `disabledContent` colour.
  final CoreIconStyle handleDisabledIconStyle;

  /// Focus ring around the drag handle — the keyboard's way into a
  /// reorder. Raw-forwarded from the nested `handleStyle.focusOutlineStyle`
  /// slot; `FocusOutline` resolves its own defaults for whatever is null.
  final CoreFocusOutlineStyle? handleFocusOutlineStyle;

  /// Remove-button style — `defaultRemoveButtonStyle` chained with the
  /// flat remove fields and the per-instance `removeButtonStyle`
  /// override, raw-forwarded to
  /// `Button(variant: .plain, size: .sm, shape: .square, buttonStyle: …)`.
  /// The child `Button` resolves its own colours / hover / focus ring;
  /// only the square `width` / `height` are pre-scaled here because
  /// `Button` paints its dimensional axis raw (it does not self-scale).
  final CoreButtonStyle removeButtonStyle;

  /// Resolved paint-ready label typography for each sortable item — the
  /// `bodyLarge` role overlaid with the merged `itemTextStyle` slot and
  /// the `onSurface` foreground colour (sb-text-style-repackage). The
  /// widget forwards this straight into `DefaultTextStyle.merge` without
  /// re-reading `theme.typography`.
  final TextStyle itemTextStyle;

  /// [itemTextStyle] with the disabled foreground — the widget picks it
  /// while the list is disabled.
  final TextStyle disabledItemTextStyle;

  /// [removeButtonStyle] with the disabled foreground — the widget picks it
  /// while the list is disabled.
  final CoreButtonStyle disabledRemoveButtonStyle;

  /// Resolved item border radius (paint-ready, post-scaling).
  final BorderRadius itemBorderRadius;

  /// Drag-proxy peak scale factor (unitless — no scaling). Read by the
  /// reorder proxy decorator so the widget never re-references
  /// `CoreSortableStyle.defaultProxyScale`.
  final double proxyScale;

  /// Drag-proxy peak Material elevation (unitless). Read by the reorder
  /// proxy decorator instead of `CoreSortableStyle.defaultProxyElevation`.
  final double proxyElevation;

  /// The active style's inset rim on the lifted row — empty under every
  /// style that states none, and for a proxy that does not lift.
  ///
  /// A rim decorates a surface that casts, and the proxy casts the moment
  /// it lifts: the Web twin appends `kSurfaceRimVar` to the drag source's
  /// lift shadow (`composeSortableItem`). A resting row casts nothing on
  /// either platform, so it takes no rim on either.
  final List<BoxShadow> proxyInsetShadow;

  /// Resolved spacing between items (logical px, post-scaling).
  final double itemSpacing;

  /// Resolved inner padding of each item (paint-ready Flutter
  /// `EdgeInsetsGeometry` — directional, so it follows the reading
  /// direction — scaling pre-applied).
  final EdgeInsetsGeometry itemPadding;

  /// Resolved padding around the drag handle (logical px, post-scaling).
  final EdgeInsetsGeometry handlePadding;

  /// Resolved reorder shift / colour transition duration.
  final Duration animationDuration;

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
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSortable] for the given [context].
///
/// Walks the nested-merge chain plus token / colour fallback in a
/// single pass:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.sortable.style
///   → widget.sortableStyle
/// ```
ResolvedSortable resolveSortable(
  BuildContext context, {
  CoreSortableStyle? sortableStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final sortableTheme = theme.coreComponentTheme?.sortable;

  final merged = resolveStyleChain(const CoreSortableStyle(), [
    sortableTheme?.style,
    sortableStyle,
  ]);

  // Each row draws its own box directly (the per-item `AnimatedContainer`
  // in `sortable.dart`) rather than composing `OutlinedContainer`. A
  // glass style's material reaches it the same way it reaches a card —
  // through the content-layer seat, folded into the fill below.
  final material = theme.surfaceFor(.content, depth: SurfaceDepth.of(context));
  final surfaceOpacity = material?.opacityIn(theme);

  final itemBorderRadius =
      merged.itemBorderRadius ?? CoreSortableStyle.defaultItemBorderRadius;
  // Nested icon slot — absorb the design-system default so the resolver
  // forwards a non-null `CoreIconStyle` to both icon use sites.
  final iconStyle = CoreSortableStyle.defaultIconStyle.merge(merged.iconStyle);
  // Handle padding — nested `handleStyle.padding` slot wins, else flat
  // `handlePadding`, else design-system default.
  // The handle's focus ring rides the same nested button-style slot as
  // its padding and colour — raw-forwarded, `FocusOutline` fills the rest.
  final handleFocusOutlineStyle = merged.handleStyle?.focusOutlineStyle;
  final handlePadding =
      merged.handleStyle?.padding ??
      merged.handlePadding ??
      CoreSortableStyle.defaultHandlePadding;
  // Handle colour — nested `handleStyle.foregroundColor` slot wins, else
  // flat `handleColor`, else design-system default; the disabled list takes
  // the dedicated disabled-content token.
  final handleColor =
      merged.handleStyle?.foregroundColor ??
      merged.handleColor ??
      CoreSortableStyle.defaultHandleColor;
  final disabledHandleColor =
      merged.disabledHandleColor ??
      CoreSortableStyle.defaultDisabledHandleColor;
  // Per-state handle icon styles — the shared `iconStyle` slot merged with
  // the per-state colour token, so the widget forwards a `CoreIconStyle` to
  // `Icon` rather than computing a raw `Color`. `Icon` resolves the colour
  // token + applies its own scaling.
  //
  // The per-state colour wins over everything the slot carries for
  // `color`, including a caller-supplied `iconStyle.color`. That is
  // intentional: colour has its own dedicated entry points
  // (`handleColor`, or the nested `handleStyle.foregroundColor` slot), so
  // `iconStyle.color` is not the override path for it. Every other
  // `iconStyle` sub-field (size included) survives.
  // guard-nested-override: color — handle colour wins over
  // `iconStyle.color`; override via `handleColor` instead.
  final handleIconStyle = iconStyle.merge(CoreIconStyle(color: handleColor));
  // guard-nested-override: color — the disabled handle colour; override
  // via `disabledHandleColor` instead.
  final handleDisabledIconStyle = iconStyle.merge(
    CoreIconStyle(color: disabledHandleColor),
  );

  // Remove-button chrome — chained `defaultRemoveButtonStyle` (32-px square
  // + zero padding + `sm` corner + 16-px glyph + onSurfaceVariant
  // foreground), then a linkage layer carrying the flat remove fields and
  // the shared icon slot / transition duration so the button keeps tracking
  // those overrides, then the per-instance nested override. Raw-forwarded
  // to `Button(variant: .plain, size: .sm, shape: .square, buttonStyle: …)`
  // — the button resolves its own colours / hover / focus ring. Only
  // `width` / `height` are pre-scaled below: `Button` paints its
  // dimensional axis raw (it does not self-scale).
  final removeButtonChain = CoreSortableStyle.defaultRemoveButtonStyle
      .merge(
        CoreButtonStyle(
          foregroundColor: merged.removeButtonColor,
          borderRadius: merged.removeButtonBorderRadius,
          width: merged.removeButtonSize,
          height: merged.removeButtonSize,
          leadingIconStyle: merged.iconStyle,
          animationDuration: merged.animationDuration,
        ),
      )
      .merge(merged.removeButtonStyle);
  final removeButtonStyle = removeButtonChain.copyWith(
    width: removeButtonChain.width! * scaling,
    height: removeButtonChain.height! * scaling,
  );

  // ─── Item label typography (paint-ready TextStyle) ─────
  // The item label's `bodyMedium` role + `onSurface` colour live in the
  // single `CoreSortableStyle.defaultItemTextStyle` slot default; layer the
  // per-instance `itemTextStyle` slot over it. EMIT Stage 2 (Flutter) —
  // `style.toValue(theme:)` materialises the token role and resolves its
  // own colour through the active scheme so dark mode tracks. Single
  // primitive — no `resolveTypographyRole` + `applyCoreTextStyle` assembly
  // (sb-text-style-repackage).
  final itemTextStyle = CoreSortableStyle.defaultItemTextStyle
      .merge(merged.itemTextStyle)
      .toValue(theme: theme);
  // A disabled list says so in its own token — the item text and the remove
  // button's glyph take `disabledForegroundColor`.
  final disabledForegroundColor =
      merged.disabledForegroundColor ??
      CoreSortableStyle.defaultDisabledForegroundColor;
  final disabledItemTextStyle = CoreSortableStyle.defaultItemTextStyle
      .merge(merged.itemTextStyle)
      .merge(CoreTextStyle(color: disabledForegroundColor))
      .toValue(theme: theme);
  final disabledRemoveButtonStyle = removeButtonStyle.copyWith(
    foregroundColor: disabledForegroundColor,
  );

  // ─── Colour resolution (EMIT Stage 2 — local vars) ─────
  final itemBackgroundColorCore =
      merged.itemBackgroundColor ??
      CoreSortableStyle.defaultItemBackgroundColor;
  final itemHoverColorCore =
      merged.itemHoverColor ?? CoreSortableStyle.defaultItemHoverColor;
  final itemBorderColorCore =
      merged.itemBorderColor ?? CoreSortableStyle.defaultItemBorderColor;
  final disabledItemBackgroundColorCore =
      merged.disabledItemBackgroundColor ??
      CoreSortableStyle.defaultDisabledItemBackgroundColor;
  final disabledItemBorderColorCore =
      merged.disabledItemBorderColor ??
      CoreSortableStyle.defaultDisabledItemBorderColor;
  final itemBackgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? itemBackgroundColorCore
            : itemBackgroundColorCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final itemHoverColor = scheme
      .resolve(
        surfaceOpacity == null
            ? itemHoverColorCore
            : itemHoverColorCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final disabledItemBackgroundColor = scheme
      .resolve(disabledItemBackgroundColorCore)
      .toValue();
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the row's border
  // so the row doesn't draw a second boundary on top of it.
  final itemBorderColor = resolveSurfaceStroke(
    theme,
    scheme.resolve(itemBorderColorCore).toValue(),
  );
  final disabledItemBorderColor = resolveSurfaceStroke(
    theme,
    scheme.resolve(disabledItemBorderColorCore).toValue(),
  );
  // Gated on the fill, like every other content-role surface on this
  // axis: both idle and hover state a solid token by default, so
  // fill-vs-no-fill does not vary by state — only an explicit transparent
  // `itemBackgroundColor` override can turn it off.
  final hasFill = itemBackgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill ? resolveSurfaceSheen(theme) : null;

  // ─── Dimensional fallback + scaling (local vars) ───────
  // Materialise paint-ready Flutter values and bake scaling into each so
  // the widget forwards them straight into BoxDecoration without
  // re-reading theme.scaling.
  final itemBorderRadiusValue =
      itemBorderRadius.toValue(geometry: theme.geometry) * scaling;
  final itemSpacing =
      theme.geometry.space(
        merged.itemSpacing ?? CoreSortableStyle.defaultItemSpacing,
      ) *
      scaling;
  final itemPadding =
      (merged.itemPadding ?? CoreSortableStyle.defaultItemPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final handlePaddingValue =
      handlePadding.toGeometry(geometry: theme.geometry) * scaling;
  final itemBorderWidth = theme.geometry.stroke(
    merged.itemBorderWidth ?? CoreSortableStyle.defaultItemBorderWidth,
    scaling: scaling,
  );
  final itemMinHeight =
      (merged.itemMinHeight ?? CoreSortableStyle.defaultItemMinHeight) *
      scaling;

  // Animation duration — nested `removeButtonStyle.animationDuration`
  // / `handleStyle.animationDuration` slot wins, else flat
  // `animationDuration`, else design-system default.
  final animationDuration = resolveMotionDuration(
    context,
    merged.removeButtonStyle?.animationDuration ??
        merged.handleStyle?.animationDuration ??
        merged.animationDuration ??
        CoreSortableStyle.defaultAnimationDuration,
  );

  // Drag-proxy paint values — `merged.X ?? default` so per-instance
  // overrides win, resolved once here (widget reads `resolved.*`, never
  // `CoreSortableStyle.default*`).
  final proxyScale = merged.proxyScale ?? CoreSortableStyle.defaultProxyScale;
  final proxyElevation =
      merged.proxyElevation ?? CoreSortableStyle.defaultProxyElevation;
  // The rim on the lifted row, gated the way every panel's rim is: on the
  // stack the surface casts. The proxy's lift is that stack — one layer
  // thrown straight down by the elevation and blurred twice as far, the
  // geometry both the widget's lift and the Web twin's `box-shadow` paint.
  final proxyInsetShadow = resolveSurfaceRim(
    context,
    stack: [
      if (proxyElevation > 0)
        (
          offsetX: 0,
          offsetY: proxyElevation,
          blurRadius: proxyElevation * 2,
          spreadRadius: 0,
          opacity: CoreOpacity.opacity20,
          inset: false,
        ),
    ],
  );

  return ResolvedSortable(
    // The same alias the Web twin names for this element's CSS
    // transition. Chrome moving between states is `move`; a curve
    // stated on one platform and defaulted on the other is the
    // divergence nothing renders differently enough to notice until
    // the two are put side by side.
    curve: CoreEasing.move.toValue(),
    itemBackgroundColor: itemBackgroundColor,
    itemHoverColor: itemHoverColor,
    disabledItemBackgroundColor: disabledItemBackgroundColor,
    itemBorderColor: itemBorderColor,
    disabledItemBorderColor: disabledItemBorderColor,
    itemBorderWidth: itemBorderWidth,
    itemMinHeight: itemMinHeight,
    surfaceOpacity: surfaceOpacity,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    handleIconStyle: handleIconStyle,
    handleDisabledIconStyle: handleDisabledIconStyle,
    handleFocusOutlineStyle: handleFocusOutlineStyle,
    removeButtonStyle: removeButtonStyle,
    itemTextStyle: itemTextStyle,
    disabledItemTextStyle: disabledItemTextStyle,
    disabledRemoveButtonStyle: disabledRemoveButtonStyle,
    itemBorderRadius: itemBorderRadiusValue,
    itemSpacing: itemSpacing,
    itemPadding: itemPadding,
    handlePadding: handlePaddingValue,
    animationDuration: animationDuration,
    proxyScale: proxyScale,
    proxyElevation: proxyElevation,
    proxyInsetShadow: proxyInsetShadow,
  );
}
