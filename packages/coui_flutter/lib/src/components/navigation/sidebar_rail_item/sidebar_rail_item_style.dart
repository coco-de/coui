import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `SidebarRailItem`.
///
/// Widget tree (`sidebar_rail_item.dart` builds):
///
/// ```text
/// Tooltip (label)
///   └─ Clickable (clickableStyle)
///        └─ AnimatedContainer (size × size, fill, borderRadius)
///             └─ Stacks (center)
///                  ├─ wash                // * only while hovered / focused / pressed
///                  ├─ icon                // IconTheme (iconTheme per state)
///                  └─ dot                 // * when `dot`, top-end corner
/// ```
class ResolvedSidebarRailItem {
  /// Creates a [ResolvedSidebarRailItem].
  const ResolvedSidebarRailItem({
    required this.size,
    required this.borderRadius,
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.hoverWashColor,
    required this.focusWashColor,
    required this.pressedWashColor,
    required this.iconTheme,
    required this.selectedIconTheme,
    required this.disabledIconTheme,
    required this.dotColor,
    required this.dotSize,
    required this.clickableStyle,
    required this.duration,
    required this.curve,
  });

  /// The square's side (scaled).
  final double size;

  /// The corner (scaled).
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

  /// A disabled destination's glyph theme.
  final IconThemeData disabledIconTheme;

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

/// Resolves [ResolvedSidebarRailItem] for the given [context].
///
/// ```text
/// CoreSidebarRailItemStyle.defaultX
///   → CoreSidebarRailItemTheme.style
///   → sidebarRailItemStyle
/// ```
ResolvedSidebarRailItem resolveSidebarRailItem(
  BuildContext context, {
  CoreSidebarRailItemStyle? sidebarRailItemStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CoreSidebarRailItemStyle(), [
    theme.coreComponentTheme?.sidebarRailItem?.style,
    sidebarRailItemStyle,
  ]);

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final borderRadius =
      merged.borderRadius ?? CoreSidebarRailItemStyle.defaultBorderRadius;
  final iconStyle = CoreSidebarRailItemStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );
  final selectedIconStyle = iconStyle
      .merge(CoreSidebarRailItemStyle.defaultSelectedIconStyle)
      .merge(merged.selectedIconStyle);
  final disabledIconStyle = iconStyle
      .merge(CoreSidebarRailItemStyle.defaultDisabledIconStyle)
      .merge(merged.disabledIconStyle);
  final stateLayer =
      merged.stateLayer ?? CoreSidebarRailItemStyle.defaultStateLayer;
  final stateLayerColor =
      merged.stateLayerColor ?? CoreSidebarRailItemStyle.defaultStateLayerColor;
  final clickableStyle = CoreSidebarRailItemStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 — EMIT ───────────────────────────────────
  final size = (merged.size ?? CoreSidebarRailItemStyle.defaultSize) * scaling;
  final borderRadiusValue =
      borderRadius.toValue(geometry: theme.geometry) * scaling;
  final dotSize =
      (merged.dotSize ?? CoreSidebarRailItemStyle.defaultDotSize) * scaling;
  final backgroundColor = scheme
      .resolve(
        merged.backgroundColor ??
            CoreSidebarRailItemStyle.defaultBackgroundColor,
      )
      .toValue();
  final selectedBackgroundColor = scheme
      .resolve(
        merged.selectedBackgroundColor ??
            CoreSidebarRailItemStyle.defaultSelectedBackgroundColor,
      )
      .toValue();
  final ink = scheme.resolve(stateLayerColor).toValue();
  final hoverWashColor = ink.withValues(alpha: stateLayer.hover);
  final focusWashColor = ink.withValues(alpha: stateLayer.focus);
  final pressedWashColor = ink.withValues(alpha: stateLayer.pressed);
  final dotColor = scheme
      .resolve(merged.dotColor ?? CoreSidebarRailItemStyle.defaultDotColor)
      .toValue();
  IconThemeData iconThemeOf(CoreIconStyle style) => IconThemeData(
    size: style.size,
    color: scheme.resolve(style.color!).toValue(),
  );
  final iconTheme = iconThemeOf(iconStyle);
  final selectedIconTheme = iconThemeOf(selectedIconStyle);
  final disabledIconTheme = iconThemeOf(disabledIconStyle);
  final clickable = resolveClickable(context, clickableStyle: clickableStyle);
  final duration = resolveMotionDuration(context, clickable.duration);
  final curve = clickable.curve;

  return ResolvedSidebarRailItem(
    size: size,
    borderRadius: borderRadiusValue,
    backgroundColor: backgroundColor,
    selectedBackgroundColor: selectedBackgroundColor,
    hoverWashColor: hoverWashColor,
    focusWashColor: focusWashColor,
    pressedWashColor: pressedWashColor,
    iconTheme: iconTheme,
    selectedIconTheme: selectedIconTheme,
    disabledIconTheme: disabledIconTheme,
    dotColor: dotColor,
    dotSize: dotSize,
    clickableStyle: clickableStyle,
    duration: duration,
    curve: curve,
  );
}
