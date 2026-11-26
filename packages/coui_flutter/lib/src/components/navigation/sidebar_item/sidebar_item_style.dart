import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `SidebarItem`.
///
/// Widget tree (`sidebar_item.dart` builds):
///
/// ```text
/// Clickable (clickableStyle — focus ring, press)
///   └─ AnimatedContainer (minHeight, fill, borderRadius)
///        └─ Stacks (centerStart)
///             ├─ wash                     // * only while hovered / focused / pressed
///             └─ Padding (padding)
///                  └─ Row (spacing: contentSpacing)
///                       ├─ leading        // IconTheme (iconTheme per state)
///                       ├─ label          // DefaultTextStyle (labelTextStyle per state)
///                       ├─ dot            // * when `dot`
///                       ├─ count
///                       └─ trailing       // IconTheme (trailingIconTheme)
/// ```
class ResolvedSidebarItem {
  /// Creates a [ResolvedSidebarItem].
  const ResolvedSidebarItem({
    required this.minHeight,
    required this.padding,
    required this.contentSpacing,
    required this.borderRadius,
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.hoverWashColor,
    required this.focusWashColor,
    required this.pressedWashColor,
    required this.iconTheme,
    required this.selectedIconTheme,
    required this.disabledIconTheme,
    required this.trailingIconTheme,
    required this.disabledTrailingIconTheme,
    required this.labelTextStyle,
    required this.selectedLabelTextStyle,
    required this.disabledLabelTextStyle,
    required this.dotColor,
    required this.dotSize,
    required this.clickableStyle,
    required this.duration,
    required this.curve,
  });

  /// The row's height (logical px, scaled).
  final double minHeight;

  /// Insets (scaled, directional).
  final EdgeInsetsGeometry padding;

  /// Spacing between the row's seats (scaled).
  final double contentSpacing;

  /// The row's corner (scaled).
  final BorderRadius borderRadius;

  /// The resting face.
  final Color backgroundColor;

  /// The current place's face.
  final Color selectedBackgroundColor;

  /// The state layer while hovered.
  final Color hoverWashColor;

  /// The state layer while focused.
  final Color focusWashColor;

  /// The state layer while pressed.
  final Color pressedWashColor;

  /// The resting glyph's ambient theme.
  final IconThemeData iconTheme;

  /// The current place's glyph theme.
  final IconThemeData selectedIconTheme;

  /// A disabled row's glyph theme.
  final IconThemeData disabledIconTheme;

  /// The trailing glyph's ambient theme.
  final IconThemeData trailingIconTheme;

  /// A disabled row's trailing glyph theme.
  final IconThemeData disabledTrailingIconTheme;

  /// The resting label.
  final TextStyle labelTextStyle;

  /// The current place's label.
  final TextStyle selectedLabelTextStyle;

  /// A disabled row's label.
  final TextStyle disabledLabelTextStyle;

  /// The unread dot's colour.
  final Color dotColor;

  /// The unread dot's diameter (scaled).
  final double dotSize;

  /// Nested chrome of the composed `Clickable`, raw-forwarded.
  final CoreClickableStyle clickableStyle;

  /// The face's transition length, already routed through reduced motion.
  final Duration duration;

  /// The face's transition curve.
  final Curve curve;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSidebarItem] for the given [context].
///
/// ```text
/// CoreSidebarItemStyle.defaultX → defaultsByLevel[level]
///   → CoreSidebarItemTheme.style
///   → CoreSidebarItemTheme.variantStyles[level]
///   → sidebarItemStyle
/// ```
ResolvedSidebarItem resolveSidebarItem(
  BuildContext context, {
  required CoreSidebarItemLevel level,
  CoreSidebarItemStyle? sidebarItemStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final itemTheme = theme.coreComponentTheme?.sidebarItem;
  final merged = resolveStyleChain(const CoreSidebarItemStyle(), [
    itemTheme?.style,
    itemTheme?.variantStyles?[level],
    sidebarItemStyle,
  ]);
  final levelStyle = CoreSidebarItemStyle.defaultsByLevel[level]!;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final borderRadius =
      merged.borderRadius ?? CoreSidebarItemStyle.defaultBorderRadius;
  final iconStyle = CoreSidebarItemStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  final selectedIconStyle = iconStyle
      .merge(CoreSidebarItemStyle.defaultSelectedIconStyle)
      .merge(merged.selectedIconStyle);
  final disabledIconStyle = iconStyle
      .merge(CoreSidebarItemStyle.defaultDisabledIconStyle)
      .merge(merged.disabledIconStyle);
  final trailingIconStyle = CoreSidebarItemStyle.defaultTrailingIconStyle.merge(
    merged.trailingIconStyle,
  );
  final disabledTrailingIconStyle = trailingIconStyle
      .merge(CoreSidebarItemStyle.defaultDisabledTrailingIconStyle)
      .merge(merged.disabledTrailingIconStyle);
  final labelStyle = levelStyle.labelStyle!
      .merge(CoreSidebarItemStyle.defaultLabelStyle)
      .merge(merged.labelStyle);
  final selectedLabelStyle = labelStyle
      .merge(CoreSidebarItemStyle.defaultSelectedLabelStyle)
      .merge(merged.selectedLabelStyle);
  final disabledLabelStyle = labelStyle
      .merge(CoreSidebarItemStyle.defaultDisabledLabelStyle)
      .merge(merged.disabledLabelStyle);
  final stateLayer =
      merged.stateLayer ?? CoreSidebarItemStyle.defaultStateLayer;
  final stateLayerColor =
      merged.stateLayerColor ?? CoreSidebarItemStyle.defaultStateLayerColor;
  // The focus ring follows the row's corner; an explicit `clickableStyle`
  // still wins.
  final clickableStyle = CoreSidebarItemStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 — EMIT: dimensions ───────────────────────
  final minHeight = (merged.minHeight ?? levelStyle.minHeight!) * scaling;
  final padding =
      (merged.padding ?? CoreSidebarItemStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final contentSpacing =
      theme.geometry.space(
        merged.contentSpacing ?? CoreSidebarItemStyle.defaultContentSpacing,
      ) *
      scaling;
  final borderRadiusValue =
      borderRadius.toValue(geometry: theme.geometry) * scaling;
  final dotSize =
      (merged.dotSize ?? CoreSidebarItemStyle.defaultDotSize) * scaling;

  // ─── Stage 2 — EMIT: colours ──────────────────────────
  final backgroundColor = scheme
      .resolve(
        merged.backgroundColor ?? CoreSidebarItemStyle.defaultBackgroundColor,
      )
      .toValue();
  final selectedBackgroundColor = scheme
      .resolve(
        merged.selectedBackgroundColor ??
            CoreSidebarItemStyle.defaultSelectedBackgroundColor,
      )
      .toValue();
  final ink = scheme.resolve(stateLayerColor).toValue();
  final hoverWashColor = ink.withValues(alpha: stateLayer.hover);
  final focusWashColor = ink.withValues(alpha: stateLayer.focus);
  final pressedWashColor = ink.withValues(alpha: stateLayer.pressed);
  final dotColor = scheme
      .resolve(merged.dotColor ?? CoreSidebarItemStyle.defaultDotColor)
      .toValue();

  // Caller glyphs are tinted through the ambient `IconTheme`; its size is
  // the raw ladder value because `Icon` scales the ambient size itself.
  IconThemeData iconThemeOf(CoreIconStyle style) => IconThemeData(
    size: style.size,
    color: scheme.resolve(style.color!).toValue(),
  );
  final iconTheme = iconThemeOf(iconStyle);
  final selectedIconTheme = iconThemeOf(selectedIconStyle);
  final disabledIconTheme = iconThemeOf(disabledIconStyle);
  final trailingIconTheme = iconThemeOf(trailingIconStyle);
  final disabledTrailingIconTheme = iconThemeOf(disabledTrailingIconStyle);

  final labelTextStyle = labelStyle.toValue(theme: theme);
  final selectedLabelTextStyle = selectedLabelStyle.toValue(theme: theme);
  final disabledLabelTextStyle = disabledLabelStyle.toValue(theme: theme);

  final clickable = resolveClickable(context, clickableStyle: clickableStyle);
  final duration = resolveMotionDuration(context, clickable.duration);
  final curve = clickable.curve;

  return ResolvedSidebarItem(
    minHeight: minHeight,
    padding: padding,
    contentSpacing: contentSpacing,
    borderRadius: borderRadiusValue,
    backgroundColor: backgroundColor,
    selectedBackgroundColor: selectedBackgroundColor,
    hoverWashColor: hoverWashColor,
    focusWashColor: focusWashColor,
    pressedWashColor: pressedWashColor,
    iconTheme: iconTheme,
    selectedIconTheme: selectedIconTheme,
    disabledIconTheme: disabledIconTheme,
    trailingIconTheme: trailingIconTheme,
    disabledTrailingIconTheme: disabledTrailingIconTheme,
    labelTextStyle: labelTextStyle,
    selectedLabelTextStyle: selectedLabelTextStyle,
    disabledLabelTextStyle: disabledLabelTextStyle,
    dotColor: dotColor,
    dotSize: dotSize,
    clickableStyle: clickableStyle,
    duration: duration,
    curve: curve,
  );
}
