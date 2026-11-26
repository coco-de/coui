import 'package:coui_flutter/coui_flutter.dart';

/// Paint-ready resolver output for Flutter `SidebarSection`.
///
/// Widget tree (`sidebar_section.dart` builds):
///
/// ```text
/// Semantics (header)
///   └─ Padding (padding)
///        └─ Row (spacing: contentSpacing)
///             ├─ label            // DefaultTextStyle (labelTextStyle)
///             └─ action           // IconTheme (actionIconTheme)
/// ```
class ResolvedSidebarSection {
  /// Creates a [ResolvedSidebarSection].
  const ResolvedSidebarSection({
    required this.padding,
    required this.contentSpacing,
    required this.labelTextStyle,
    required this.actionIconTheme,
  });

  /// Insets (scaled, directional).
  final EdgeInsetsGeometry padding;

  /// Spacing between the label and the action (scaled).
  final double contentSpacing;

  /// The heading's text.
  final TextStyle labelTextStyle;

  /// The action glyph's ambient theme.
  final IconThemeData actionIconTheme;
}

/// Resolves [ResolvedSidebarSection] for the given [context].
///
/// ```text
/// CoreSidebarSectionStyle.defaultX
///   → CoreSidebarSectionTheme.style
///   → sidebarSectionStyle
/// ```
ResolvedSidebarSection resolveSidebarSection(
  BuildContext context, {
  CoreSidebarSectionStyle? sidebarSectionStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CoreSidebarSectionStyle(), [
    theme.coreComponentTheme?.sidebarSection?.style,
    sidebarSectionStyle,
  ]);

  final labelStyle = CoreSidebarSectionStyle.defaultLabelStyle.merge(
    merged.labelStyle,
  );
  final actionIconStyle = CoreSidebarSectionStyle.defaultActionIconStyle.merge(
    merged.actionIconStyle,
  );

  final padding =
      (merged.padding ?? CoreSidebarSectionStyle.defaultPadding).toGeometry(
        geometry: theme.geometry,
      ) *
      scaling;
  final contentSpacing =
      theme.geometry.space(
        merged.contentSpacing ?? CoreSidebarSectionStyle.defaultContentSpacing,
      ) *
      scaling;
  final labelTextStyle = labelStyle.toValue(theme: theme);
  final actionIconTheme = IconThemeData(
    size: actionIconStyle.size,
    color: theme.colorScheme.resolve(actionIconStyle.color!).toValue(),
  );

  return ResolvedSidebarSection(
    padding: padding,
    contentSpacing: contentSpacing,
    labelTextStyle: labelTextStyle,
    actionIconTheme: actionIconTheme,
  );
}
