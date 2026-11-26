import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Stacks].
///
/// Folds the per-field 3-tier priority (widget > `CoreComponentTheme`
/// > design-system default) into a single immutable bundle the build
/// method can consume.
class ResolvedStacks {
  /// Creates a [ResolvedStacks].
  const ResolvedStacks({
    required this.alignment,
    required this.fit,
    required this.clipBehavior,
    this.textDirection,
  });

  /// Effective alignment for non-positioned children.
  final CoreAlignment alignment;

  /// Effective constraint propagation mode.
  final CoreStackFit fit;

  /// Effective overflow clipping behaviour.
  final CoreClipBehavior clipBehavior;

  /// Optional explicit reading direction (`null` = inherit ambient).
  final CoreTextDirection? textDirection;
}

/// Resolves [ResolvedStacks] for [Stacks].
///
/// Priority (per-field): widget value > `CoreComponentTheme.stacks.style`
/// > design-system default ([CoreStacksStyle.defaultAlignment] /
/// [CoreStacksStyle.defaultFit] / [CoreStacksStyle.defaultClipBehavior]).
ResolvedStacks resolveStacks(
  BuildContext context, {
  CoreAlignment? alignment,
  CoreStackFit? fit,
  CoreClipBehavior? clipBehavior,
  CoreTextDirection? textDirection,
}) {
  // Theme-optional: [Stacks] uses no dimensional theme values, only an
  // optional per-component override, so it must also render outside a
  // [Theme] scope (e.g. a low-level `ModalBackdrop` barrier).
  final coreTheme = Theme.maybeOf(context)?.coreComponentTheme?.stacks;
  final merged = resolveStyleChain(const CoreStacksStyle(), [
    coreTheme?.style,
    CoreStacksStyle(
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
    ),
  ]);
  return ResolvedStacks(
    alignment: merged.alignment ?? CoreStacksStyle.defaultAlignment,
    fit: merged.fit ?? CoreStacksStyle.defaultFit,
    clipBehavior: merged.clipBehavior ?? CoreStacksStyle.defaultClipBehavior,
    textDirection: textDirection,
  );
}

/// Converts [CoreAlignment] to Flutter's [AlignmentDirectional].
AlignmentDirectional coreAlignmentToFlutter(CoreAlignment a) => .new(a.x, a.y);

/// Converts [CoreStackFit] to Flutter's [StackFit].
StackFit coreStackFitToFlutter(CoreStackFit fit) => switch (fit) {
  .loose => .loose,
  .expand => .expand,
  .passthrough => .passthrough,
};

/// Converts [CoreClipBehavior] to Flutter's [Clip].
Clip coreClipBehaviorToFlutter(CoreClipBehavior c) => switch (c) {
  .none => .none,
  .hardEdge => .hardEdge,
  .antiAlias => .antiAlias,
  .antiAliasWithSaveLayer => .antiAliasWithSaveLayer,
};

/// Converts [CoreTextDirection] to Flutter's [TextDirection].
TextDirection? coreTextDirectionToFlutter(CoreTextDirection? d) => switch (d) {
  null => null,
  .ltr => .ltr,
  .rtl => .rtl,
};
