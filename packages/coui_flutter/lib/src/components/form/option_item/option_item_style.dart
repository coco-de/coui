import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedOptionItem
// ═══════════════════════════════════════════════════

/// Resolver output for `OptionItem`.
///
/// ```text
/// Semantics (button · selected · enabled)
///   └─ Clickable
///        └─ ConstrainedBox (minHeight)
///             └─ DecoratedBox (fill by state · border by state · radius)
///                  └─ Stacks (clip: none)
///                       ├─ Position (pressed face, from inside the border) // pressed
///                       └─ Padding (padding, from the outer edge)
///                  └─ Row (spacing)
///                       ├─ IconTheme → leading                      // optional
///                       ├─ Expanded
///                       │    └─ Column: label · Gap · description
///                       └─ Icon check | Checkbox                    // by selection
/// ```
///
/// Every value has had the merge chain, the default fallback, token
/// resolution, density and `scaling` applied — the widget reads them as
/// they are.
class ResolvedOptionItem {
  /// Creates a [ResolvedOptionItem].
  const ResolvedOptionItem({
    required this.padding,
    required this.spacing,
    required this.minHeight,
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.selectedBackgroundColor,
    required this.selectedBorderColor,
    required this.selectedBorderWidth,
    required this.disabledSelectedBackgroundColor,
    required this.labelTextStyle,
    required this.selectedLabelTextStyle,
    required this.disabledLabelTextStyle,
    required this.disabledSelectedLabelTextStyle,
    required this.descriptionTextStyle,
    required this.disabledDescriptionTextStyle,
    required this.descriptionGapStyle,
    required this.leadingIconTheme,
    required this.disabledLeadingIconTheme,
    required this.checkIconStyle,
    required this.disabledCheckIconStyle,
    required this.pressedBackgroundColor,
    required this.pressedBackgroundBorderRadius,
    required this.selectedPressedBackgroundBorderRadius,
    required this.pressedBackgroundInsets,
    required this.selectedPressedBackgroundInsets,
    required this.clickableStyle,
  });

  /// Inset of the row's content. Kept directional-capable.
  final EdgeInsetsGeometry padding;

  /// Space between the seats of the row (post-density, post-scaling).
  final double spacing;

  /// The card's least height (post-scaling).
  final double minHeight;

  /// Corner of the card.
  final BorderRadius borderRadius;

  /// The resting border's colour — also a chosen, disabled row's.
  final Color borderColor;

  /// The resting border's width (post-geometry, post-scaling).
  final double borderWidth;

  /// Fill of a chosen row.
  final Color selectedBackgroundColor;

  /// Border colour of a chosen row.
  final Color selectedBorderColor;

  /// Border width of a chosen row (post-geometry, post-scaling).
  final double selectedBorderWidth;

  /// Fill of a chosen row that is disabled.
  final Color disabledSelectedBackgroundColor;

  /// The label at rest.
  final TextStyle labelTextStyle;

  /// The label of a chosen row.
  final TextStyle selectedLabelTextStyle;

  /// The label of a disabled row.
  final TextStyle disabledLabelTextStyle;

  /// The label of a chosen row that is disabled — the chosen weight in the
  /// disabled ink.
  final TextStyle disabledSelectedLabelTextStyle;

  /// The description at rest.
  final TextStyle descriptionTextStyle;

  /// The description of a disabled row.
  final TextStyle disabledDescriptionTextStyle;

  /// Gap between the label and the description — raw-forwarded to `Gap`.
  final CoreGapStyle descriptionGapStyle;

  /// Ambient icon theme of the leading glyph at rest.
  final IconThemeData leadingIconTheme;

  /// Ambient icon theme of the leading glyph of a disabled row.
  final IconThemeData disabledLeadingIconTheme;

  /// The check mark of a chosen single-selection row — raw-forwarded to
  /// `Icon`, which resolves and scales it.
  final CoreIconStyle checkIconStyle;

  /// [checkIconStyle] of a disabled row.
  final CoreIconStyle disabledCheckIconStyle;

  /// The pressed face's colour — the state layer is already folded into its
  /// alpha.
  final Color pressedBackgroundColor;

  /// Corner of the pressed face under the resting border — concentric with
  /// the border's inner curve (the stated corner less the border width).
  final BorderRadius pressedBackgroundBorderRadius;

  /// [pressedBackgroundBorderRadius] under a chosen row's border.
  final BorderRadius selectedPressedBackgroundBorderRadius;

  /// Where the pressed face sits inside the card's box under the resting
  /// border — the border's width plus the face's inset, less its outset.
  final EdgeInsets pressedBackgroundInsets;

  /// [pressedBackgroundInsets] under a chosen row's border.
  final EdgeInsets selectedPressedBackgroundInsets;

  /// Nested chrome of the composed `Clickable` — raw-forwarded.
  final CoreClickableStyle clickableStyle;
}

/// Resolves the chrome of an `OptionItem`.
///
/// ```text
/// CoreOptionItemStyle.default*  (+ defaultsBySelection[selection])
///   → CoreOptionItemTheme.style
///   → widget.optionItemStyle
/// ```
ResolvedOptionItem resolveOptionItem(
  BuildContext context, {
  required CoreOptionItemSelection selection,
  CoreOptionItemStyle? optionItemStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CoreOptionItemStyle(), [
    theme.coreComponentTheme?.optionItem?.style,
    optionItemStyle,
  ]);
  final selectionStyle = CoreOptionItemStyle.defaultsBySelection[selection]!;

  // ── Stage1 RESOLVE — Core values ──
  final disabledForeground =
      merged.disabledForegroundColor ??
      CoreOptionItemStyle.defaultDisabledForegroundColor;
  final disabledInk = CoreTextStyle(color: disabledForeground);
  final borderRadiusCore =
      merged.borderRadius ?? CoreOptionItemStyle.defaultBorderRadius;
  final labelSlot = CoreOptionItemStyle.defaultLabelTextStyle.merge(
    merged.labelTextStyle,
  );
  final selectedLabelSlot = labelSlot
      .merge(selectionStyle.selectedLabelTextStyle)
      .merge(merged.selectedLabelTextStyle);
  final descriptionSlot = CoreOptionItemStyle.defaultDescriptionTextStyle.merge(
    merged.descriptionTextStyle,
  );
  final leadingIconSlot = CoreOptionItemStyle.defaultLeadingIconStyle.merge(
    merged.leadingIconStyle,
  );
  final checkIconSlot = CoreOptionItemStyle.defaultCheckIconStyle.merge(
    merged.checkIconStyle,
  );
  final stateLayer = merged.stateLayer ?? CoreOptionItemStyle.defaultStateLayer;
  final pressedToken =
      merged.pressedBackgroundColor ??
      CoreOptionItemStyle.defaultPressedBackgroundColor;
  final pressedBackgroundBorderRadius =
      merged.pressedBackgroundBorderRadius ??
      CoreOptionItemStyle.defaultPressedBackgroundBorderRadius;

  // ── Stage2 EMIT ──
  final padding =
      (merged.padding ?? CoreOptionItemStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final spacing =
      theme.geometry.space(
        merged.spacing ?? CoreOptionItemStyle.defaultSpacing,
      ) *
      scaling;
  final minHeight =
      (merged.minHeight ?? CoreOptionItemStyle.defaultMinHeight) * scaling;
  final borderRadius =
      borderRadiusCore.toValue(geometry: theme.geometry) * scaling;
  final borderColor = scheme
      .resolve(merged.borderColor ?? CoreOptionItemStyle.defaultBorderColor)
      .toValue();
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreOptionItemStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final selectedBackgroundColor = scheme
      .resolve(
        merged.selectedBackgroundColor ??
            CoreOptionItemStyle.defaultSelectedBackgroundColor,
      )
      .toValue();
  final selectedBorderColor = scheme
      .resolve(
        merged.selectedBorderColor ??
            CoreOptionItemStyle.defaultSelectedBorderColor,
      )
      .toValue();
  final selectedBorderWidth = theme.geometry.stroke(
    merged.selectedBorderWidth ??
        CoreOptionItemStyle.defaultSelectedBorderWidth,
    scaling: scaling,
  );
  final disabledSelectedBackgroundColor = scheme
      .resolve(
        merged.disabledSelectedBackgroundColor ??
            CoreOptionItemStyle.defaultDisabledSelectedBackgroundColor,
      )
      .toValue();
  final labelTextStyle = labelSlot.toValue(theme: theme);
  final selectedLabelTextStyle = selectedLabelSlot.toValue(theme: theme);
  final disabledLabelTextStyle = labelSlot
      .merge(disabledInk)
      .toValue(theme: theme);
  // A chosen row that is disabled keeps the chosen weight; only the ink
  // drops to the disabled foreground.
  final disabledSelectedLabelTextStyle = selectedLabelSlot
      .merge(disabledInk)
      .toValue(theme: theme);
  final descriptionTextStyle = descriptionSlot.toValue(theme: theme);
  final disabledDescriptionTextStyle = descriptionSlot
      .merge(disabledInk)
      .toValue(theme: theme);
  final disabledForegroundValue = scheme.resolve(disabledForeground).toValue();
  // The glyph rests in the label's ink unless its slot states a colour.
  final leadingIconTheme = IconThemeData(
    size: leadingIconSlot.size,
    color: scheme.resolve(leadingIconSlot.color ?? labelSlot.color!).toValue(),
  );
  final disabledLeadingIconTheme = IconThemeData(
    size: leadingIconSlot.size,
    color: disabledForegroundValue,
  );
  final disabledCheckIconStyle = checkIconSlot.merge(
    CoreIconStyle(color: disabledForeground),
  );
  final pressedBackgroundColor = scheme
      .resolve(pressedToken.scaleAlpha(stateLayer.pressed))
      .toValue();
  final pressedBackgroundOuterRadius =
      pressedBackgroundBorderRadius.toValue(geometry: theme.geometry) * scaling;
  // The face sits inside the border, so its corner is concentric with the
  // border's inner curve: the stated corner less the border in effect.
  // Computed here rather than stated as a Core default because the width
  // it subtracts is the resolved one — the theme geometry folds the stroke
  // (hairline screens, a style's stroke floor) and the state picks rest or
  // chosen — so no constant could hold it.
  BorderRadius pressedFaceRadius(double border) {
    Radius inner(Radius r) =>
        (r - Radius.circular(border)).clamp(minimum: Radius.zero);
    return BorderRadius.only(
      topLeft: inner(pressedBackgroundOuterRadius.topLeft),
      topRight: inner(pressedBackgroundOuterRadius.topRight),
      bottomLeft: inner(pressedBackgroundOuterRadius.bottomLeft),
      bottomRight: inner(pressedBackgroundOuterRadius.bottomRight),
    );
  }

  final pressedBackgroundOutset =
      theme.geometry.space(
        merged.pressedBackgroundOutset ??
            CoreOptionItemStyle.defaultPressedBackgroundOutset,
      ) *
      scaling;
  final pressedBackgroundInset =
      theme.geometry.space(
        merged.pressedBackgroundInset ??
            CoreOptionItemStyle.defaultPressedBackgroundInset,
      ) *
      scaling;

  // The face is measured from the inside of the border, so where it sits
  // in the card's box depends on the border the row draws.
  EdgeInsets pressedFaceInsets(double border) => EdgeInsets.symmetric(
    horizontal: border - pressedBackgroundOutset,
    vertical: border + pressedBackgroundInset,
  );
  final pressedBackgroundInsets = pressedFaceInsets(borderWidth);
  final pressedBackgroundRadius = pressedFaceRadius(borderWidth);
  final selectedPressedBackgroundRadius = pressedFaceRadius(
    selectedBorderWidth,
  );
  final selectedPressedBackgroundInsets = pressedFaceInsets(
    selectedBorderWidth,
  );

  // The focus ring follows the corner of the card.
  final clickableStyle = CoreOptionItemStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadiusCore))
      .merge(merged.clickableStyle);

  return ResolvedOptionItem(
    padding: padding,
    spacing: spacing,
    minHeight: minHeight,
    borderRadius: borderRadius,
    borderColor: borderColor,
    borderWidth: borderWidth,
    selectedBackgroundColor: selectedBackgroundColor,
    selectedBorderColor: selectedBorderColor,
    selectedBorderWidth: selectedBorderWidth,
    disabledSelectedBackgroundColor: disabledSelectedBackgroundColor,
    labelTextStyle: labelTextStyle,
    selectedLabelTextStyle: selectedLabelTextStyle,
    disabledLabelTextStyle: disabledLabelTextStyle,
    disabledSelectedLabelTextStyle: disabledSelectedLabelTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    disabledDescriptionTextStyle: disabledDescriptionTextStyle,
    descriptionGapStyle: CoreOptionItemStyle.defaultDescriptionGapStyle.merge(
      merged.descriptionGapStyle,
    ),
    leadingIconTheme: leadingIconTheme,
    disabledLeadingIconTheme: disabledLeadingIconTheme,
    checkIconStyle: checkIconSlot,
    disabledCheckIconStyle: disabledCheckIconStyle,
    pressedBackgroundColor: pressedBackgroundColor,
    pressedBackgroundBorderRadius: pressedBackgroundRadius,
    selectedPressedBackgroundBorderRadius: selectedPressedBackgroundRadius,
    pressedBackgroundInsets: pressedBackgroundInsets,
    selectedPressedBackgroundInsets: selectedPressedBackgroundInsets,
    clickableStyle: clickableStyle,
  );
}
