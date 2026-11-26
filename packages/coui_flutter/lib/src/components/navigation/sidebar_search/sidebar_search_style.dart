import 'package:coui_flutter/coui_flutter.dart';

/// Paint-ready resolver output for Flutter `SidebarSearch`.
///
/// Widget tree (`sidebar_search.dart` builds):
///
/// ```text
/// Clickable (clickableStyle)
///   └─ Container (minHeight, fill, border, borderRadius)
///        └─ Stacks (centerStart)
///             ├─ wash                     // * only while hovered / focused / pressed
///             └─ Padding (padding)
///                  └─ Row (spacing: contentSpacing)
///                       ├─ Icon (iconStyle)
///                       ├─ placeholder    // placeholderTextStyle
///                       └─ Kbd (kbdStyle) // * when a shortcut is given
/// ```
class ResolvedSidebarSearch {
  /// Creates a [ResolvedSidebarSearch].
  const ResolvedSidebarSearch({
    required this.minHeight,
    required this.padding,
    required this.contentSpacing,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.iconStyle,
    required this.placeholderTextStyle,
    required this.kbdStyle,
    required this.hoverWashColor,
    required this.focusWashColor,
    required this.pressedWashColor,
    required this.clickableStyle,
  });

  /// The trigger's height (scaled).
  final double minHeight;

  /// Insets (scaled, directional).
  final EdgeInsetsGeometry padding;

  /// Spacing between the seats (scaled).
  final double contentSpacing;

  /// The corner (scaled).
  final BorderRadius borderRadius;

  /// The face.
  final Color backgroundColor;

  /// The line.
  final Color borderColor;

  /// Width of the line (scaled).
  final double borderWidth;

  /// The search glyph, raw-forwarded to the composed `Icon`.
  final CoreIconStyle iconStyle;

  /// The placeholder's text.
  final TextStyle placeholderTextStyle;

  /// The composed `Kbd`'s chrome, raw-forwarded.
  final CoreKbdStyle? kbdStyle;

  /// The state layer while hovered.
  final Color hoverWashColor;

  /// The state layer while focused.
  final Color focusWashColor;

  /// The state layer while pressed.
  final Color pressedWashColor;

  /// Nested chrome of the composed `Clickable`, raw-forwarded.
  final CoreClickableStyle clickableStyle;
}

/// Resolves [ResolvedSidebarSearch] for the given [context].
///
/// ```text
/// CoreSidebarSearchStyle.defaultX
///   → CoreSidebarSearchTheme.style
///   → sidebarSearchStyle
/// ```
ResolvedSidebarSearch resolveSidebarSearch(
  BuildContext context, {
  CoreSidebarSearchStyle? sidebarSearchStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CoreSidebarSearchStyle(), [
    theme.coreComponentTheme?.sidebarSearch?.style,
    sidebarSearchStyle,
  ]);

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final borderRadius =
      merged.borderRadius ?? CoreSidebarSearchStyle.defaultBorderRadius;
  final iconStyle = CoreSidebarSearchStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  final placeholderStyle = CoreSidebarSearchStyle.defaultPlaceholderStyle.merge(
    merged.placeholderStyle,
  );
  final stateLayer =
      merged.stateLayer ?? CoreSidebarSearchStyle.defaultStateLayer;
  final stateLayerColor =
      merged.stateLayerColor ?? CoreSidebarSearchStyle.defaultStateLayerColor;
  final clickableStyle = CoreSidebarSearchStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 — EMIT ───────────────────────────────────
  final minHeight =
      (merged.minHeight ?? CoreSidebarSearchStyle.defaultMinHeight) * scaling;
  final padding =
      (merged.padding ?? CoreSidebarSearchStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final contentSpacing =
      theme.geometry.space(
        merged.contentSpacing ?? CoreSidebarSearchStyle.defaultContentSpacing,
      ) *
      scaling;
  final borderRadiusValue =
      borderRadius.toValue(geometry: theme.geometry) * scaling;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreSidebarSearchStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final backgroundColor = scheme
      .resolve(
        merged.backgroundColor ?? CoreSidebarSearchStyle.defaultBackgroundColor,
      )
      .toValue();
  final borderColor = scheme
      .resolve(merged.borderColor ?? CoreSidebarSearchStyle.defaultBorderColor)
      .toValue();
  final placeholderTextStyle = placeholderStyle.toValue(theme: theme);
  final ink = scheme.resolve(stateLayerColor).toValue();
  final hoverWashColor = ink.withValues(alpha: stateLayer.hover);
  final focusWashColor = ink.withValues(alpha: stateLayer.focus);
  final pressedWashColor = ink.withValues(alpha: stateLayer.pressed);

  return ResolvedSidebarSearch(
    minHeight: minHeight,
    padding: padding,
    contentSpacing: contentSpacing,
    borderRadius: borderRadiusValue,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth,
    iconStyle: iconStyle,
    placeholderTextStyle: placeholderTextStyle,
    kbdStyle: merged.kbdStyle,
    hoverWashColor: hoverWashColor,
    focusWashColor: focusWashColor,
    pressedWashColor: pressedWashColor,
    clickableStyle: clickableStyle,
  );
}
