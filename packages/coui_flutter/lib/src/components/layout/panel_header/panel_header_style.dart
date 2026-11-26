import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedPanelHeader
// ═══════════════════════════════════════════════════

/// Resolver output for `PanelHeader`.
///
/// ```text
/// Padding (padding)
///   └─ HeaderWrapLayout (minTitleWidth · titleActionSpacing, centred)
///        ├─ Semantics(headingLevel) → DefaultTextStyle(titleTextStyle) → title
///        └─ action                                              // optional
/// ```
///
/// Every value has had the merge chain, the default fallback, token
/// resolution, density and `scaling` applied — the widget reads them as
/// they are.
class ResolvedPanelHeader {
  /// Creates a [ResolvedPanelHeader].
  const ResolvedPanelHeader({
    required this.titleTextStyle,
    required this.padding,
    required this.titleActionSpacing,
    required this.minTitleWidth,
  });

  /// Ambient text style of the title slot.
  final TextStyle titleTextStyle;

  /// Inset around the row (post-scaling).
  final EdgeInsets padding;

  /// Space between the title and the action (post-scaling).
  final double titleActionSpacing;

  /// The narrowest title beside the action (post-scaling).
  final double minTitleWidth;
}

/// Resolves the chrome of a `PanelHeader`.
///
/// ```text
/// CorePanelHeaderStyle.default*
///   → CorePanelHeaderTheme.style
///   → widget.panelHeaderStyle
/// ```
ResolvedPanelHeader resolvePanelHeader(
  BuildContext context, {
  CorePanelHeaderStyle? panelHeaderStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CorePanelHeaderStyle(), [
    theme.coreComponentTheme?.panelHeader?.style,
    panelHeaderStyle,
  ]);

  final titleTextStyle = CorePanelHeaderStyle.defaultTitleTextStyle
      .merge(merged.titleTextStyle)
      .toValue(theme: theme);
  final padding =
      (merged.padding ?? CorePanelHeaderStyle.defaultPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final titleActionSpacing =
      theme.geometry.space(
        merged.titleActionSpacing ??
            CorePanelHeaderStyle.defaultTitleActionSpacing,
      ) *
      scaling;
  final minTitleWidth =
      (merged.minTitleWidth ?? CorePanelHeaderStyle.defaultMinTitleWidth) *
      scaling;

  return ResolvedPanelHeader(
    titleTextStyle: titleTextStyle,
    padding: padding,
    titleActionSpacing: titleActionSpacing,
    minTitleWidth: minTitleWidth,
  );
}
