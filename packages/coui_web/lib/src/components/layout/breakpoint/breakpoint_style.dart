/// Resolver for the global-viewport breakpoint/tier — the Web side of
/// `CoreBreakpointContract`.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:jaspr/jaspr.dart';

/// Judgement-ready value bundle returned by [resolveBreakpoint].
///
/// This is not a paint-ready chrome bundle — `Breakpoint` renders
/// nothing, so its field composition is not a cross-platform symmetry
/// target (`core/layer-mapping.md`, Resolved-layer asymmetry is
/// legitimate).
class ResolvedBreakpoint {
  /// Creates a [ResolvedBreakpoint].
  const ResolvedBreakpoint({
    required this.width,
    required this.breakpoint,
    required this.tier,
  });

  /// Global viewport width (logical px) observed at resolve time.
  final double width;

  /// The active [CoreBreakpoint] for [width].
  final CoreBreakpoint breakpoint;

  /// The semantic tier derived from [breakpoint].
  final CoreBreakpointTier tier;
}

/// Single entry point — observes the global viewport width the Web way
/// and forwards [boundaries] to [CoreBreakpointToTier.toTier] unchanged.
///
/// The resolver body carries no tier-boundary judgement logic of its
/// own — judgement is delegated entirely to the shared Core
/// self-conversion, so Flutter and Web can never silently diverge on it
/// (`resolver/resolver-pattern.md`, "Enum self-conversion").
///
/// [context] is accepted for cross-platform signature parity with the
/// Flutter counterpart (`cross-platform/api.md`) even though the Web
/// observation itself does not walk the component tree — viewport width
/// is a global browser value, not one scoped to a particular element.
///
/// Observation mechanism (see the PR description for the full decision
/// record): [viewportSize] reads `window.innerWidth` through the
/// existing SSR-safe conditional-import helper in `web_dom_utils.dart`
/// (already reused by `DraggablePanel`). On the server (no `dart:js`)
/// the stub returns a width of `0`, which resolves to
/// `CoreBreakpoint.xs` → `CoreBreakpointTier.mobile` — a deterministic
/// fallback, not a crash. This is a one-shot observation: no global
/// `ResizeObserver`/rebuild wiring is installed at this layer. Real-time
/// resize reactivity, if a given consumer needs it, is left to that
/// consumer's own `StatefulComponent` (the same division of concerns
/// `StageContainer`/`Window` already use for their own local
/// measurements) rather than bolted onto this non-widget accessor.
ResolvedBreakpoint resolveBreakpoint(
  BuildContext context, {
  Map<CoreBreakpointTier, CoreBreakpoint> boundaries =
      CoreBreakpointContract.defaultBoundaries,
}) {
  final width = viewportSize().width;
  final breakpoint = CoreBreakpoint.forWidth(width);
  final tier = breakpoint.toTier(boundaries: boundaries);
  return ResolvedBreakpoint(width: width, breakpoint: breakpoint, tier: tier);
}
