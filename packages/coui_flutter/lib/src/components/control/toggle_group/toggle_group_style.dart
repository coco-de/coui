import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedToggleGroup
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `ToggleGroup`.
///
/// Widget tree (`toggle_group.dart` decides which optional branches
/// render):
///
/// ```text
/// OutlinedContainer (trackContainerStyle)
///   └─ Row (spacing = itemSpacing)
///        ├─ items[] (_ToggleGroupItem)
///             └─ Clickable (clickableStyle)      // tap / cursor / press
///                  └─ AnimatedContainer (itemHeight, itemMinWidth,
///                                        itemPadding,
///                                        itemBorderRadius, selectedColor +
///                                        selectedShadow when chosen,
///                                        hoverLayerColor over the face
///                                        while hovered)
///                       └─ Semantics(checked, label)
///                            └─ Row (vertically centred)
///                                 ├─ IconTheme.merge                 // * item.icon != null
///                                 │    (selectedIconTheme | iconTheme)
///                                 │    └─ item.icon
///                                 └─ Padding (labelPadding)          // * item.showLabel
///                                      └─ Text (selectedLabelTextStyle |
///                                               unselectedLabelTextStyle)
///        └─ trailing                                    // * trailing != null
/// ```
///
/// Every field is paint-ready and the disabled state is already folded
/// in: a disabled group resolves the same fields to its flat values
/// (disabled track, sunk chosen face, no shadow, disabled ink), so the
/// widget only picks chosen vs unchosen per segment.
class ResolvedToggleGroup {
  /// Creates a [ResolvedToggleGroup].
  const ResolvedToggleGroup({
    required this.trackContainerStyle,
    required this.selectedColor,
    required this.unselectedColor,
    required this.selectedShadow,
    required this.hoverLayerColor,
    required this.restLayerColor,
    required this.itemBorderRadius,
    required this.itemPadding,
    required this.labelPadding,
    required this.itemHeight,
    required this.itemMinWidth,
    required this.itemSpacing,
    required this.clickableStyle,
    required this.transitionDuration,
    required this.curve,
    required this.selectedLabelTextStyle,
    required this.unselectedLabelTextStyle,
    required this.iconTheme,
    required this.selectedIconTheme,
  });

  /// Composed-`OutlinedContainer` chrome for the track — fill / radius /
  /// padding, `borderWidth: 0` (the track draws no stroke). The track is
  /// the surface; the moving chosen face is not (a material preset must
  /// not animate its translucency on every change).
  final CoreOutlinedContainerStyle trackContainerStyle;

  /// Fill of the chosen segment.
  final Color selectedColor;

  /// Unchosen segment fill — [selectedColor] at alpha 0 (hue held), so
  /// the `AnimatedContainer` lerp is alpha-only instead of passing
  /// through transparent black.
  final Color unselectedColor;

  /// Shadow under the chosen segment — empty for a disabled group.
  /// Scaling pre-applied, tinted with the palette's `shadow` colour.
  final List<BoxShadow> selectedShadow;

  /// The state layer laid over a hovered segment — the layer colour at the
  /// ramp's hover weight, over whichever face the segment wears. `null` for
  /// a disabled group, which paints none.
  final Color? hoverLayerColor;

  /// [hoverLayerColor] at alpha 0 (hue held), the layer's resting value so
  /// the `AnimatedContainer` lerp is alpha-only. `null` when disabled.
  final Color? restLayerColor;

  /// Per-segment corner radius.
  final BorderRadius itemBorderRadius;

  /// Per-segment padding (scaling pre-applied) — the uniform inset around
  /// `[icon][label box]`.
  final EdgeInsets itemPadding;

  /// Inset of the label box inside a segment (scaling pre-applied).
  final EdgeInsets labelPadding;

  /// Fixed segment height (logical px, scaling pre-applied).
  final double itemHeight;

  /// Minimum segment width (logical px, scaling pre-applied) — the
  /// segment height, so an icon-only segment is a square while a label
  /// segment wider than its height keeps its own width.
  final double itemMinWidth;

  /// Spacing between segments (logical px, scaling pre-applied).
  final double itemSpacing;

  /// Nested [CoreClickableStyle] for the composed per-segment `Clickable`.
  final CoreClickableStyle clickableStyle;

  /// Effective chosen-state transition duration.
  final Duration transitionDuration;

  /// The shape the chrome change takes over time — the same `CoreEasing`
  /// alias the Web twin's CSS transition names.
  final Curve curve;

  /// Paint-ready label style of the chosen segment.
  final TextStyle selectedLabelTextStyle;

  /// Paint-ready label style of unchosen segments.
  final TextStyle unselectedLabelTextStyle;

  /// Ambient icon theme of an unchosen segment's icon.
  final IconThemeData iconTheme;

  /// Ambient icon theme of the chosen segment's icon.
  final IconThemeData selectedIconTheme;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedToggleGroup] for the given Flutter [context].
///
/// ```text
/// design system default → CoreToggleGroupTheme.style
///   → widget.toggleGroupStyle
/// ```
///
/// [size] picks the size row (`md` 32 segment in a 40 track, `sm` 26 in a
/// 32 track) from `CoreToggleGroupStyle.defaultsBySize`; a field the row
/// does not state reads the flat default.
///
/// [enabled] is a semantic state (a build-time prop both platforms
/// share), so it is a resolver input; hover / press / focus are not —
/// the composed `Clickable` detects those.
ResolvedToggleGroup resolveToggleGroup(
  BuildContext context, {
  required bool enabled,
  CoreComponentSize size = CoreToggleGroupContract.defaultSize,
  CoreToggleGroupStyle? toggleGroupStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final toggleGroupTheme = theme.coreComponentTheme?.toggleGroup;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreToggleGroupStyle(), [
    toggleGroupTheme?.style,
    toggleGroupStyle,
  ]);

  // The size row — sits between the merged override and the flat default.
  final sizeRow = CoreToggleGroupStyle.sizeDefaults(size);

  // ─── Fills (disabled picks its own pair) ──────────────
  final trackColor = enabled
      ? merged.backgroundColor ?? CoreToggleGroupStyle.defaultBackgroundColor
      : merged.disabledBackgroundColor ??
            CoreToggleGroupStyle.defaultDisabledBackgroundColor;
  final selectedColor = scheme
      .resolve(
        enabled
            ? merged.selectedColor ?? CoreToggleGroupStyle.defaultSelectedColor
            : merged.disabledSelectedColor ??
                  CoreToggleGroupStyle.defaultDisabledSelectedColor,
      )
      .toValue();

  // A disabled group paints no shadow under the chosen face.
  final selectedShadow = enabled
      ? (merged.selectedShadow ?? CoreToggleGroupStyle.defaultSelectedShadow)
            .toValue(
              base: scheme
                  .resolve(const CoreColor.token(CoreColors.shadow))
                  .toValue(),
              geometry: theme.geometry,
              scale: scaling,
            )
      : const <BoxShadow>[];

  // ─── Hover layer ──────────────────────────────────────
  // The layer colour at the ramp's hover weight, laid over the segment's own
  // face. A disabled group paints none.
  final stateLayer =
      merged.stateLayer ?? CoreToggleGroupStyle.defaultStateLayer;
  final hoverLayerColor = enabled
      ? scheme
            .resolve(
              (merged.stateLayerColor ??
                      CoreToggleGroupStyle.defaultStateLayerColor)
                  .scaleAlpha(stateLayer.hover),
            )
            .toValue()
      : null;

  // ─── Chrome (scaling pre-applied where it is a layout dimension) ─
  final itemBorderRadius =
      (merged.itemBorderRadius ??
              sizeRow.itemBorderRadius ??
              CoreToggleGroupStyle.defaultItemBorderRadius)
          .toValue(geometry: theme.geometry);
  final itemPadding =
      (merged.itemPadding ??
              sizeRow.itemPadding ??
              CoreToggleGroupStyle.defaultItemPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final labelPadding =
      (merged.labelPadding ?? CoreToggleGroupStyle.defaultLabelPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final itemHeight =
      (merged.itemHeight ??
          sizeRow.itemHeight ??
          CoreToggleGroupStyle.defaultItemHeight) *
      scaling;
  // A segment is never narrower than it is tall (an icon-only square).
  final itemMinWidth = itemHeight;
  final itemSpacing =
      theme.geometry.space(
        merged.itemSpacing ?? CoreToggleGroupStyle.defaultItemSpacing,
      ) *
      scaling;

  // ─── Per-state icon slots → ambient IconThemeData ─────
  // `defaultX.merge(merged.x)` keeps a colour-only override from dropping
  // the default size. The size stays raw: the child `Icon` scales the
  // ambient size itself.
  final iconStyle = enabled
      ? CoreToggleGroupStyle.defaultIconStyle.merge(merged.iconStyle)
      : CoreToggleGroupStyle.defaultDisabledIconStyle.merge(
          merged.disabledIconStyle,
        );
  final selectedIconStyle = enabled
      ? CoreToggleGroupStyle.defaultSelectedIconStyle.merge(
          merged.selectedIconStyle,
        )
      : iconStyle;
  final iconTheme = IconThemeData(
    size: iconStyle.size,
    color: scheme.resolve(iconStyle.color!).toValue(),
  );
  final selectedIconTheme = IconThemeData(
    size: selectedIconStyle.size,
    color: scheme.resolve(selectedIconStyle.color!).toValue(),
  );

  // ─── Label typography ─────────────────────────────────
  final selectedFontWeight =
      merged.selectedFontWeight ??
      CoreToggleGroupStyle.defaultSelectedFontWeight;
  final TextStyle unselectedLabelTextStyle;
  final TextStyle selectedLabelTextStyle;
  if (enabled) {
    // The size row states a role only; the state colour stays the default's.
    final unselectedLabel = CoreToggleGroupStyle.defaultLabelTextStyle
        .merge(sizeRow.labelTextStyle)
        .merge(merged.labelTextStyle);
    final selectedLabel = CoreToggleGroupStyle.defaultSelectedLabelTextStyle
        .merge(sizeRow.selectedLabelTextStyle)
        .copyWith(fontWeight: selectedFontWeight)
        .merge(merged.selectedLabelTextStyle);
    unselectedLabelTextStyle = unselectedLabel.toValue(
      color: scheme.resolve(unselectedLabel.color!).toValue(),
      theme: theme,
    );
    selectedLabelTextStyle = selectedLabel.toValue(
      color: scheme.resolve(selectedLabel.color!).toValue(),
      theme: theme,
    );
  } else {
    // One disabled ink for both states; the chosen label keeps its weight.
    final disabledLabel = CoreToggleGroupStyle.defaultDisabledLabelTextStyle
        .merge(sizeRow.disabledLabelTextStyle)
        .merge(merged.disabledLabelTextStyle);
    final disabledColor = scheme.resolve(disabledLabel.color!).toValue();
    unselectedLabelTextStyle = disabledLabel.toValue(
      color: disabledColor,
      theme: theme,
    );
    selectedLabelTextStyle = disabledLabel
        .copyWith(fontWeight: selectedFontWeight)
        .toValue(color: disabledColor, theme: theme);
  }

  // Nested Clickable slot — default merged with the override, raw-forward.
  final clickableStyle = CoreToggleGroupStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreToggleGroupStyle.defaultTransitionDuration,
  );

  // Hue-held transparent counterpart for the selection lerp.
  final unselectedColor = selectedColor.withAlpha(0);

  // ─── Composed `OutlinedContainer` chrome for the track ─
  // Core values (not resolved ones) go in: `OutlinedContainer` runs the
  // scheme-resolve / geometry steps itself. It does not scale `padding`,
  // so that is scaled here and handed over as final numbers.
  CoreEdgeInsets toCorePadding(EdgeInsets e) =>
      .fromLTRB(e.left, e.top, e.right, e.bottom);
  final trackPaddingScaled =
      (merged.padding ?? sizeRow.padding ?? CoreToggleGroupStyle.defaultPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final trackContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: trackColor,
    borderRadius:
        merged.borderRadius ??
        sizeRow.borderRadius ??
        CoreToggleGroupStyle.defaultBorderRadius,
    borderWidth: 0,
    padding: toCorePadding(trackPaddingScaled),
  );

  return ResolvedToggleGroup(
    curve: CoreEasing.move.toValue(),
    trackContainerStyle: trackContainerStyle,
    selectedColor: selectedColor,
    unselectedColor: unselectedColor,
    selectedShadow: selectedShadow,
    hoverLayerColor: hoverLayerColor,
    restLayerColor: hoverLayerColor?.withAlpha(0),
    itemBorderRadius: itemBorderRadius,
    itemPadding: itemPadding,
    labelPadding: labelPadding,
    itemHeight: itemHeight,
    itemMinWidth: itemMinWidth,
    itemSpacing: itemSpacing,
    clickableStyle: clickableStyle,
    transitionDuration: transitionDuration,
    selectedLabelTextStyle: selectedLabelTextStyle,
    unselectedLabelTextStyle: unselectedLabelTextStyle,
    iconTheme: iconTheme,
    selectedIconTheme: selectedIconTheme,
  );
}
