import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling for [StageContainer] after folding widget / theme /
/// default values.
class ResolvedStageContainer {
  /// Creates a [ResolvedStageContainer].
  const ResolvedStageContainer({
    required this.breakpoint,
    required this.padding,
  });

  /// Effective breakpoint strategy.
  final CoreStageBreakpoint breakpoint;

  /// Effective base padding (paint-ready, scaling pre-applied). Left /
  /// right are the minimum horizontal insets — the breakpoint
  /// redistribution adds to them.
  final EdgeInsets padding;
}

/// Resolves [ResolvedStageContainer] for [StageContainer].
///
/// Priority (per-field): widget value > `widget.stageContainerStyle` >
/// `CoreStageContainerTheme.style` > design-system default.
ResolvedStageContainer resolveStageContainer(
  BuildContext context, {
  CoreStageBreakpoint? breakpoint,
  CoreEdgeInsets? padding,
  CoreStageContainerStyle? stageContainerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final themeStyle = theme.coreComponentTheme?.stageContainer?.style;

  final merged = resolveStyleChain(const CoreStageContainerStyle(), [
    themeStyle,
    stageContainerStyle,
  ]);

  final effectiveBreakpoint =
      breakpoint ??
      merged.breakpoint ??
      CoreStageContainerStyle.defaultBreakpoint;
  final effectivePadding =
      padding ?? merged.padding ?? CoreStageContainerStyle.defaultPadding;
  final paddingValue =
      effectivePadding.toValue(geometry: theme.geometry) * scaling;

  return ResolvedStageContainer(
    breakpoint: effectiveBreakpoint,
    padding: paddingValue,
  );
}
