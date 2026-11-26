import 'package:coui_flutter/coui_flutter.dart';

/// Resolver output for `OptionList`.
///
/// ```text
/// Semantics (group)
///   └─ Column (spacing, stretch) → the rows
/// ```
class ResolvedOptionList {
  /// Creates a [ResolvedOptionList].
  const ResolvedOptionList({required this.spacing});

  /// Space between two rows (post-density, post-scaling).
  final double spacing;
}

/// Resolves the chrome of an `OptionList`.
///
/// ```text
/// CoreOptionListStyle.default*
///   → CoreOptionListTheme.style
///   → widget.optionListStyle
/// ```
ResolvedOptionList resolveOptionList(
  BuildContext context, {
  CoreOptionListStyle? optionListStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final merged = resolveStyleChain(const CoreOptionListStyle(), [
    theme.coreComponentTheme?.optionList?.style,
    optionListStyle,
  ]);
  final spacing =
      theme.geometry.space(
        merged.spacing ?? CoreOptionListStyle.defaultSpacing,
      ) *
      scaling;
  return ResolvedOptionList(spacing: spacing);
}
