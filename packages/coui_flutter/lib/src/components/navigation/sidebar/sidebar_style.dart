import 'package:coui_flutter/coui_flutter.dart';

/// Paint-ready resolver output for Flutter `Sidebar`.
///
/// Widget tree (`sidebar.dart` builds):
///
/// ```text
/// CoUISemantics (navigation)
///   └─ Row (stretch)
///        ├─ rail                  // * twoPane / collapsed
///        │    └─ Container (railWidth, railBackgroundColor,
///        │         │         end line when collapsed)
///        │         └─ Column (railPadding, spacing: railSpacing)
///        │              ├─ railHeader · Gap (railHeaderGapStyle)
///        │              ├─ railItems (scrolls)
///        │              └─ railFooter
///        └─ panel                 // * standard / twoPane
///             └─ Container (panelWidth, backgroundColor, end line)
///                  └─ Column
///                       ├─ top    (topPadding, topSpacing)
///                       │    ├─ header
///                       │    ├─ panel title row
///                       │    └─ search
///                       ├─ body   scrolls (bodyPadding, bodySpacing)
///                       └─ bottom (bottomPadding, bottomSpacing)
/// ```
class ResolvedSidebar {
  /// Creates a [ResolvedSidebar].
  const ResolvedSidebar({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.panelWidth,
    required this.railWidth,
    required this.railBackgroundColor,
    required this.railPadding,
    required this.railSpacing,
    required this.railHeaderGapStyle,
    required this.topPadding,
    required this.topSpacing,
    required this.bodyPadding,
    required this.bodySpacing,
    required this.bottomPadding,
    required this.bottomSpacing,
    required this.panelTitleTextStyle,
    required this.panelTitlePadding,
    required this.panelTitleSpacing,
    required this.panelActionIconTheme,
  });

  /// The panel's face.
  final Color backgroundColor;

  /// The line on the edge that meets the page.
  final Color borderColor;

  /// Width of that line (scaled).
  final double borderWidth;

  /// Width of the panel (scaled).
  final double panelWidth;

  /// Width of the icon rail (scaled).
  final double railWidth;

  /// The rail's face.
  final Color railBackgroundColor;

  /// The rail's insets (scaled).
  final EdgeInsetsGeometry railPadding;

  /// Spacing between the rail's items (scaled).
  final double railSpacing;

  /// Extra room after the rail's header, raw-forwarded to the composed
  /// `Gap`.
  final CoreGapStyle railHeaderGapStyle;

  /// The top region's insets (scaled).
  final EdgeInsetsGeometry topPadding;

  /// Spacing between the top region's parts (scaled).
  final double topSpacing;

  /// The body's insets (scaled).
  final EdgeInsetsGeometry bodyPadding;

  /// Spacing between the body's rows (scaled).
  final double bodySpacing;

  /// The bottom region's insets (scaled).
  final EdgeInsetsGeometry bottomPadding;

  /// Spacing between the bottom region's parts (scaled).
  final double bottomSpacing;

  /// The panel title's text.
  final TextStyle panelTitleTextStyle;

  /// Insets around the panel title row (scaled, directional).
  final EdgeInsetsGeometry panelTitlePadding;

  /// Spacing between the panel title and its action (scaled).
  final double panelTitleSpacing;

  /// The panel title action's ambient icon theme.
  final IconThemeData panelActionIconTheme;
}

/// Resolves [ResolvedSidebar] for the given [context].
///
/// ```text
/// CoreSidebarStyle.defaultX → defaultsByType[type]
///   → CoreSidebarTheme.style
///   → CoreSidebarTheme.variantStyles[type]
///   → sidebarStyle
/// ```
ResolvedSidebar resolveSidebar(
  BuildContext context, {
  required CoreSidebarType type,
  CoreSidebarStyle? sidebarStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final sidebarTheme = theme.coreComponentTheme?.sidebar;
  final merged = resolveStyleChain(const CoreSidebarStyle(), [
    sidebarTheme?.style,
    sidebarTheme?.variantStyles?[type],
    sidebarStyle,
  ]);
  final typeStyle = CoreSidebarStyle.defaultsByType[type]!;

  // ─── Stage 1 — RESOLVE ────────────────────────────────
  final railHeaderGapStyle = CoreSidebarStyle.defaultRailHeaderGapStyle.merge(
    merged.railHeaderGapStyle,
  );
  final panelTitleStyle = CoreSidebarStyle.defaultPanelTitleStyle.merge(
    merged.panelTitleStyle,
  );
  final panelActionIconStyle = CoreSidebarStyle.defaultPanelActionIconStyle
      .merge(merged.panelActionIconStyle);

  // ─── Stage 2 — EMIT: dimensions ───────────────────────
  EdgeInsetsGeometry insets(CoreEdgeInsets value) =>
      value.toGeometry(geometry: theme.geometry) * scaling;
  double spacing(double value) => theme.geometry.space(value) * scaling;
  final panelWidth = (merged.panelWidth ?? typeStyle.panelWidth!) * scaling;
  final railWidth =
      (merged.railWidth ?? CoreSidebarStyle.defaultRailWidth) * scaling;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreSidebarStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final railPadding = insets(
    merged.railPadding ?? CoreSidebarStyle.defaultRailPadding,
  );
  final railSpacing = spacing(
    merged.railSpacing ?? CoreSidebarStyle.defaultRailSpacing,
  );
  final topPadding = insets(merged.topPadding ?? typeStyle.topPadding!);
  final topSpacing = spacing(
    merged.topSpacing ?? CoreSidebarStyle.defaultTopSpacing,
  );
  final bodyPadding = insets(merged.bodyPadding ?? typeStyle.bodyPadding!);
  final bodySpacing = spacing(
    merged.bodySpacing ?? CoreSidebarStyle.defaultBodySpacing,
  );
  final bottomPadding = insets(
    merged.bottomPadding ?? CoreSidebarStyle.defaultBottomPadding,
  );
  final bottomSpacing = spacing(
    merged.bottomSpacing ?? CoreSidebarStyle.defaultBottomSpacing,
  );
  final panelTitlePadding = insets(
    merged.panelTitlePadding ?? CoreSidebarStyle.defaultPanelTitlePadding,
  );
  final panelTitleSpacing = spacing(
    merged.panelTitleSpacing ?? CoreSidebarStyle.defaultPanelTitleSpacing,
  );

  // ─── Stage 2 — EMIT: colours / text ───────────────────
  final backgroundColor = scheme
      .resolve(
        merged.backgroundColor ?? CoreSidebarStyle.defaultBackgroundColor,
      )
      .toValue();
  final borderColor = scheme
      .resolve(merged.borderColor ?? CoreSidebarStyle.defaultBorderColor)
      .toValue();
  final railBackgroundColor = scheme
      .resolve(merged.railBackgroundColor ?? typeStyle.railBackgroundColor!)
      .toValue();
  final panelTitleTextStyle = panelTitleStyle.toValue(theme: theme);
  final panelActionIconTheme = IconThemeData(
    size: panelActionIconStyle.size,
    color: scheme.resolve(panelActionIconStyle.color!).toValue(),
  );

  return ResolvedSidebar(
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth,
    panelWidth: panelWidth,
    railWidth: railWidth,
    railBackgroundColor: railBackgroundColor,
    railPadding: railPadding,
    railSpacing: railSpacing,
    railHeaderGapStyle: railHeaderGapStyle,
    topPadding: topPadding,
    topSpacing: topSpacing,
    bodyPadding: bodyPadding,
    bodySpacing: bodySpacing,
    bottomPadding: bottomPadding,
    bottomSpacing: bottomSpacing,
    panelTitleTextStyle: panelTitleTextStyle,
    panelTitlePadding: panelTitlePadding,
    panelTitleSpacing: panelTitleSpacing,
    panelActionIconTheme: panelActionIconTheme,
  );
}
