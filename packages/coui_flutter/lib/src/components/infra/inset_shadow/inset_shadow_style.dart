import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/theme.dart' show Theme;
import 'package:coui_flutter/src/util/core_to_flutter.dart';
import 'package:flutter/widgets.dart';

/// The inset rim the active surface style adds to a raised surface,
/// paint-ready.
///
/// Paired with `InsetShadow`, which draws the result. A surface needs
/// both: resolving without drawing produces a value nothing shows, and
/// this axis has shipped that twice.
///
/// ## Why this is not part of the shadow conversion
///
/// It would be the obvious place — the conversion already receives the
/// geometry constraint the rim travels on. It is the wrong place for
/// three measured reasons:
///
/// - The conversion is a per-layer derivation of what the component
///   authored (scale a blur, scale an offset). A rim is an addition to
///   the stack as a whole, and callers split their stack into outer and
///   inset halves and convert each — so a rim inside the conversion is
///   emitted once per half.
/// - The caller that already applies a style transform passes an
///   identity constraint into the conversion, so "the conversion is the
///   only point a style can reach a shadow" is not true where a rim
///   lands.
/// - It would hand an inset layer to callers that put the result
///   straight into `BoxDecoration.boxShadow`, where Flutter paints it
///   behind the background and it never appears.
///
/// [stack] is the shadow the surface states itself, and it gates the rim:
/// a rim decorates a surface that casts, it does not turn a flat one into a
/// raised one. The cast a style contributes to a surface that states none
/// is not that stack, so it brings no rim. Web holds the same line by
/// writing `--coui-surface-rim` only beside a stack the surface authored
/// (`check_surface_fill_contract.sh` keeps it from riding alone or beside
/// the contributed cast).
List<BoxShadow> resolveSurfaceRim(
  BuildContext context, {
  required List<CoreShadowLayer> stack,
}) {
  final theme = Theme.of(context);
  final rim = theme.geometry.highlightRim;
  if (rim.isEmpty || stack.isEmpty) return const [];

  // The rim is the style's own statement, not a derivation of the
  // component's stack, so the style's transform must not run over it —
  // hence the identity constraint rather than `theme.geometry`.
  return rim.toValue(
    base: theme.colorScheme
        .resolve(const CoreColor.token(CoreColors.surfaceHighlight))
        .toValue(),
    geometry: const CoreSurfaceGeometryConstraint(),
  );
}
