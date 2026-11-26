import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for `AspectRatioBox`.
///
/// Folds the per-field 2-tier priority (widget > `CoreComponentTheme`
/// > design-system default) into a single immutable bundle the build
/// method can consume.
class ResolvedAspectRatioBox {
  /// Creates a [ResolvedAspectRatioBox].
  const ResolvedAspectRatioBox({required this.ratio});

  /// Effective width-to-height ratio. Always strictly positive.
  final double ratio;
}

/// Resolves [ResolvedAspectRatioBox] for `AspectRatioBox`.
///
/// Priority (per-field): widget value (when `> 0`) >
/// `CoreComponentTheme.aspectRatioBox.style.defaultRatio` >
/// design-system default
/// ([CoreAspectRatioBoxStyle.defaultDefaultRatio]).
ResolvedAspectRatioBox resolveAspectRatioBox(
  BuildContext context, {
  required double ratio,
}) {
  final coreTheme = Theme.of(context).coreComponentTheme?.aspectRatioBox;
  final widgetRatio = ratio.isFinite && ratio > 0 ? ratio : null;
  final themeRatio = coreTheme?.style?.defaultRatio;
  final resolved =
      widgetRatio ?? themeRatio ?? CoreAspectRatioBoxStyle.defaultDefaultRatio;
  return ResolvedAspectRatioBox(ratio: resolved);
}
