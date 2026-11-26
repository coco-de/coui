import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Mask].
class ResolvedMask {
  /// Creates a [ResolvedMask].
  const ResolvedMask({
    required this.shape,
    required this.half,
  });

  /// Effective mask shape.
  final CoreMaskShape shape;

  /// Effective half-crop.
  final CoreMaskHalf half;
}

/// Resolves [ResolvedMask] for [Mask].
///
/// Priority: widget value > `CoreComponentTheme.mask` > design-system default.
ResolvedMask resolveMask(
  BuildContext context, {
  CoreMaskShape? shape,
  CoreMaskHalf? half,
}) {
  final coreTheme = Theme.of(context).coreComponentTheme?.mask;
  // Standard chain (`resolver/resolver-pattern.md`): empty base, then each
  // user-intent layer, then the leaf default fills what stayed null. The widget
  // params are the top layer — `shape`/`half` are semantic enums, which
  // `core/style-contract.md` keeps on the widget rather than behind the Style
  // slot, so they enter the chain here rather than as a caller-supplied Style.
  final merged = resolveStyleChain(const CoreMaskStyle(), [
    coreTheme?.style,
    CoreMaskStyle(shape: shape, half: half),
  ]);
  return ResolvedMask(
    shape: merged.shape ?? CoreMaskStyle.defaultShape,
    half: merged.half ?? CoreMaskStyle.defaultHalf,
  );
}
