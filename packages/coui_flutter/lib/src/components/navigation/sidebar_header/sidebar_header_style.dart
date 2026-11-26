import 'package:coui_flutter/coui_flutter.dart';

/// Paint-ready resolver output for Flutter `SidebarHeader`.
///
/// Widget tree (`sidebar_header.dart` builds):
///
/// ```text
/// Clickable (clickableStyle)              // * only when `onPressed`
///   └─ Container (padding, fill, border, borderRadius)
///        └─ Stacks
///             ├─ wash                     // * only while hovered / focused / pressed
///             └─ Row (spacing: contentSpacing)
///                  ├─ leading
///                  ├─ Column
///                  │    ├─ title          // DefaultTextStyle (titleTextStyle)
///                  │    └─ subtitle       // DefaultTextStyle (subtitleTextStyle)
///                  └─ trailing            // IconTheme (trailingIconTheme)
/// ```
class ResolvedSidebarHeader {
  /// Creates a [ResolvedSidebarHeader].
  const ResolvedSidebarHeader({
    required this.padding,
    required this.contentSpacing,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.titleTextStyle,
    required this.subtitleTextStyle,
    required this.trailingIconTheme,
    required this.hoverWashColor,
    required this.focusWashColor,
    required this.pressedWashColor,
    required this.clickableStyle,
  });

  /// Insets (scaled).
  final EdgeInsetsGeometry padding;

  /// Spacing between the seats (scaled).
  final double contentSpacing;

  /// The corner (scaled).
  final BorderRadius borderRadius;

  /// The face.
  final Color backgroundColor;

  /// The line, or `null` when no line is drawn.
  final Color? borderColor;

  /// Width of the line (scaled).
  final double borderWidth;

  /// The name's text.
  final TextStyle titleTextStyle;

  /// The second line's text.
  final TextStyle subtitleTextStyle;

  /// The switch glyph's ambient theme.
  final IconThemeData trailingIconTheme;

  /// The state layer while hovered.
  final Color hoverWashColor;

  /// The state layer while focused.
  final Color focusWashColor;

  /// The state layer while pressed.
  final Color pressedWashColor;

  /// Nested chrome of the composed `Clickable`, raw-forwarded.
  final CoreClickableStyle clickableStyle;
}

/// Resolves [ResolvedSidebarHeader] for the given [context].
///
/// ```text
/// CoreSidebarHeaderStyle.defaultX → defaultsByVariant[variant]
///   → CoreSidebarHeaderTheme.style
///   → CoreSidebarHeaderTheme.variantStyles[variant]
///   → sidebarHeaderStyle
/// ```
ResolvedSidebarHeader resolveSidebarHeader(
  BuildContext context, {
  required CoreSidebarHeaderVariant variant,
  CoreSidebarHeaderStyle? sidebarHeaderStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final headerTheme = theme.coreComponentTheme?.sidebarHeader;
  final merged = resolveStyleChain(const CoreSidebarHeaderStyle(), [
    headerTheme?.style,
    headerTheme?.variantStyles?[variant],
    sidebarHeaderStyle,
  ]);
  final variantStyle = CoreSidebarHeaderStyle.defaultsByVariant[variant]!;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final borderRadius =
      merged.borderRadius ?? CoreSidebarHeaderStyle.defaultBorderRadius;
  final stroke = merged.borderColor ?? variantStyle.borderColor;
  final titleStyle = CoreSidebarHeaderStyle.defaultTitleStyle.merge(
    merged.titleStyle,
  );
  final subtitleStyle = CoreSidebarHeaderStyle.defaultSubtitleStyle.merge(
    merged.subtitleStyle,
  );
  final trailingIconStyle = CoreSidebarHeaderStyle.defaultTrailingIconStyle
      .merge(merged.trailingIconStyle);
  final stateLayer =
      merged.stateLayer ?? CoreSidebarHeaderStyle.defaultStateLayer;
  final stateLayerColor =
      merged.stateLayerColor ?? CoreSidebarHeaderStyle.defaultStateLayerColor;
  final clickableStyle = CoreSidebarHeaderStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 — EMIT ───────────────────────────────────
  final padding =
      (merged.padding ?? CoreSidebarHeaderStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final contentSpacing =
      theme.geometry.space(
        merged.contentSpacing ?? CoreSidebarHeaderStyle.defaultContentSpacing,
      ) *
      scaling;
  final borderRadiusValue =
      borderRadius.toValue(geometry: theme.geometry) * scaling;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreSidebarHeaderStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final backgroundColor = scheme
      .resolve(merged.backgroundColor ?? variantStyle.backgroundColor!)
      .toValue();
  final borderColor = stroke == null ? null : scheme.resolve(stroke).toValue();
  final titleTextStyle = titleStyle.toValue(theme: theme);
  final subtitleTextStyle = subtitleStyle.toValue(theme: theme);
  final trailingIconTheme = IconThemeData(
    size: trailingIconStyle.size,
    color: scheme.resolve(trailingIconStyle.color!).toValue(),
  );
  final ink = scheme.resolve(stateLayerColor).toValue();
  final hoverWashColor = ink.withValues(alpha: stateLayer.hover);
  final focusWashColor = ink.withValues(alpha: stateLayer.focus);
  final pressedWashColor = ink.withValues(alpha: stateLayer.pressed);

  return ResolvedSidebarHeader(
    padding: padding,
    contentSpacing: contentSpacing,
    borderRadius: borderRadiusValue,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth,
    titleTextStyle: titleTextStyle,
    subtitleTextStyle: subtitleTextStyle,
    trailingIconTheme: trailingIconTheme,
    hoverWashColor: hoverWashColor,
    focusWashColor: focusWashColor,
    pressedWashColor: pressedWashColor,
    clickableStyle: clickableStyle,
  );
}
