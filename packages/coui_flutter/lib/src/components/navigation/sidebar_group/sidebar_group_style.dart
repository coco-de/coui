import 'package:coui_flutter/coui_flutter.dart';

/// Paint-ready resolver output for Flutter `SidebarGroup`.
///
/// Widget tree (`sidebar_group.dart` builds):
///
/// ```text
/// Column (spacing: childrenSpacing)
///   ├─ SidebarItem (itemStyle)            // the group's own row, chevron at its end
///   └─ AnimatedSize (duration)            // * children only while open
///        └─ Stacks
///             ├─ tree line                // treeLineColor × treeLineWidth at treeLineInset
///             └─ Padding (childrenPadding)
///                  └─ Column (spacing: childrenSpacing) — children
/// ```
class ResolvedSidebarGroup {
  /// Creates a [ResolvedSidebarGroup].
  const ResolvedSidebarGroup({
    required this.childrenPadding,
    required this.childrenSpacing,
    required this.treeLineColor,
    required this.treeLineWidth,
    required this.treeLineInset,
    required this.chevronIconStyle,
    required this.duration,
    required this.itemStyle,
  });

  /// Insets around the nested rows (scaled, directional).
  final EdgeInsetsGeometry childrenPadding;

  /// Spacing between the rows (scaled).
  final double childrenSpacing;

  /// The line beside the nested rows.
  final Color treeLineColor;

  /// Width of that line (scaled).
  final double treeLineWidth;

  /// How far in from the start the line sits (scaled).
  final double treeLineInset;

  /// The chevron, raw-forwarded to the composed `Icon`.
  final CoreIconStyle chevronIconStyle;

  /// How long the nested rows take to open and close, already routed
  /// through reduced motion.
  final Duration duration;

  /// The group row's chrome, raw-forwarded to its `SidebarItem`.
  final CoreSidebarItemStyle? itemStyle;
}

/// Resolves [ResolvedSidebarGroup] for the given [context].
///
/// ```text
/// CoreSidebarGroupStyle.defaultX
///   → CoreSidebarGroupTheme.style
///   → sidebarGroupStyle
/// ```
ResolvedSidebarGroup resolveSidebarGroup(
  BuildContext context, {
  CoreSidebarGroupStyle? sidebarGroupStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CoreSidebarGroupStyle(), [
    theme.coreComponentTheme?.sidebarGroup?.style,
    sidebarGroupStyle,
  ]);

  final chevronIconStyle = CoreSidebarGroupStyle.defaultChevronIconStyle.merge(
    merged.chevronIconStyle,
  );
  final childrenPadding =
      (merged.childrenPadding ?? CoreSidebarGroupStyle.defaultChildrenPadding)
          .toGeometry(geometry: theme.geometry) *
      scaling;
  final childrenSpacing =
      theme.geometry.space(
        merged.childrenSpacing ?? CoreSidebarGroupStyle.defaultChildrenSpacing,
      ) *
      scaling;
  final treeLineWidth = theme.geometry.stroke(
    merged.treeLineWidth ?? CoreSidebarGroupStyle.defaultTreeLineWidth,
    scaling: scaling,
  );
  // A position, not a gap: it marks where the group row's glyph sits, so
  // density does not move it (the glyph does not move either).
  final treeLineInset =
      (merged.treeLineInset ?? CoreSidebarGroupStyle.defaultTreeLineInset) *
      scaling;
  final treeLineColor = theme.colorScheme
      .resolve(
        merged.treeLineColor ?? CoreSidebarGroupStyle.defaultTreeLineColor,
      )
      .toValue();
  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreSidebarGroupStyle.defaultDuration,
  );

  return ResolvedSidebarGroup(
    childrenPadding: childrenPadding,
    childrenSpacing: childrenSpacing,
    treeLineColor: treeLineColor,
    treeLineWidth: treeLineWidth,
    treeLineInset: treeLineInset,
    chevronIconStyle: chevronIconStyle,
    duration: duration,
    itemStyle: merged.itemStyle,
  );
}
