/// Single entry point for observing the global viewport breakpoint/tier
/// from a Flutter [BuildContext].
library;

import 'package:coui_core/coui_core.dart';
import 'package:flutter/widgets.dart';

/// Judgement-ready value bundle for Flutter `Breakpoint` (not paint-ready —
/// this component renders nothing). Field composition itself is not a
/// cross-platform symmetry target (`core/layer-mapping.md` Resolved-layer
/// asymmetry is legitimate, FR-3/SC-1).
class ResolvedBreakpoint {
  /// Creates a [ResolvedBreakpoint].
  const ResolvedBreakpoint({
    required this.width,
    required this.breakpoint,
    required this.tier,
  });

  /// Global viewport width (logical px) at the time of observation.
  final double width;

  /// The [CoreBreakpoint] active for [width].
  final CoreBreakpoint breakpoint;

  /// The semantic tier derived from [breakpoint].
  final CoreBreakpointTier tier;
}

/// Single entry point — observes the global viewport width the Flutter way
/// (`MediaQuery.sizeOf`, not a local container width) and passes
/// [boundaries] straight through to `CoreBreakpoint.toTier()`. This resolver
/// carries no tier-specific threshold logic of its own — observation only,
/// judgement is delegated to the `CoreBreakpoint` self-conversion.
ResolvedBreakpoint resolveBreakpoint(
  BuildContext context, {
  Map<CoreBreakpointTier, CoreBreakpoint> boundaries =
      CoreBreakpointContract.defaultBoundaries,
}) {
  final width = MediaQuery.widthOf(context);
  final breakpoint = CoreBreakpoint.forWidth(width);
  final tier = breakpoint.toTier(boundaries: boundaries);
  return ResolvedBreakpoint(width: width, breakpoint: breakpoint, tier: tier);
}
