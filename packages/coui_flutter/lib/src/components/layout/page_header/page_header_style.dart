import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedPageHeader
// ═══════════════════════════════════════════════════

/// Resolver output for `PageHeader`.
///
/// ```text
/// HeaderWrapLayout (minTextWidth · textActionsSpacing, bottoms aligned)
///   ├─ Column (textSpacing)
///   │    ├─ DefaultTextStyle(eyebrowTextStyle) → eyebrow       // optional
///   │    ├─ Semantics(headingLevel) → DefaultTextStyle(titleTextStyle) → title
///   │    └─ DefaultTextStyle(descriptionTextStyle) → description // optional
///   └─ Wrap (actionSpacing) → actions                           // optional
/// ```
///
/// Every value has had the merge chain, the default fallback, token
/// resolution, density and `scaling` applied — the widget reads them as
/// they are.
class ResolvedPageHeader {
  /// Creates a [ResolvedPageHeader].
  const ResolvedPageHeader({
    required this.eyebrowTextStyle,
    required this.titleTextStyle,
    required this.descriptionTextStyle,
    required this.textSpacing,
    required this.textActionsSpacing,
    required this.actionSpacing,
    required this.minTextWidth,
  });

  /// Ambient text style of the eyebrow slot.
  final TextStyle eyebrowTextStyle;

  /// Ambient text style of the title slot.
  final TextStyle titleTextStyle;

  /// Ambient text style of the description slot.
  final TextStyle descriptionTextStyle;

  /// Space between the lines of the text block (post-scaling).
  final double textSpacing;

  /// Space between the text block and the actions (post-scaling).
  final double textActionsSpacing;

  /// Space between two actions (post-scaling).
  final double actionSpacing;

  /// The narrowest text block beside the actions (post-scaling).
  final double minTextWidth;
}

/// Resolves the chrome of a `PageHeader`.
///
/// ```text
/// CorePageHeaderStyle.default*
///   → CorePageHeaderTheme.style
///   → widget.pageHeaderStyle
/// ```
ResolvedPageHeader resolvePageHeader(
  BuildContext context, {
  CorePageHeaderStyle? pageHeaderStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CorePageHeaderStyle(), [
    theme.coreComponentTheme?.pageHeader?.style,
    pageHeaderStyle,
  ]);

  final eyebrowTextStyle = CorePageHeaderStyle.defaultEyebrowTextStyle
      .merge(merged.eyebrowTextStyle)
      .toValue(theme: theme);
  final titleTextStyle = CorePageHeaderStyle.defaultTitleTextStyle
      .merge(merged.titleTextStyle)
      .toValue(theme: theme);
  final descriptionTextStyle = CorePageHeaderStyle.defaultDescriptionTextStyle
      .merge(merged.descriptionTextStyle)
      .toValue(theme: theme);
  final textSpacing =
      theme.geometry.space(
        merged.textSpacing ?? CorePageHeaderStyle.defaultTextSpacing,
      ) *
      scaling;
  final textActionsSpacing =
      theme.geometry.space(
        merged.textActionsSpacing ??
            CorePageHeaderStyle.defaultTextActionsSpacing,
      ) *
      scaling;
  final actionSpacing =
      theme.geometry.space(
        merged.actionSpacing ?? CorePageHeaderStyle.defaultActionSpacing,
      ) *
      scaling;
  final minTextWidth =
      (merged.minTextWidth ?? CorePageHeaderStyle.defaultMinTextWidth) *
      scaling;

  return ResolvedPageHeader(
    eyebrowTextStyle: eyebrowTextStyle,
    titleTextStyle: titleTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    textSpacing: textSpacing,
    textActionsSpacing: textActionsSpacing,
    actionSpacing: actionSpacing,
    minTextWidth: minTextWidth,
  );
}
