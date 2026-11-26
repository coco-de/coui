/// Semantic 3-tier grouping derived from [CoreBreakpoint].
library;

import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_contract.dart';
import 'package:coui_core/src/component/contracts/media_query_visibility/core_breakpoint.dart';

/// Semantic 3-tier grouping of [CoreBreakpoint]. A pure derived enum that
/// stores no pixel value of its own — it only groups [CoreBreakpoint]
/// values via [CoreBreakpointToTier.toTier].
enum CoreBreakpointTier {
  /// Narrowest tier — phones and other small viewports.
  mobile,

  /// Mid-width tier — tablets and similar viewports.
  tablet,

  /// Widest tier — desktop and large viewports.
  desktop,
}

/// Core→Core self-conversion (`resolver/resolver-pattern.md` "source enum
/// instance method"). [CoreBreakpoint] is an existing entity that this
/// phase leaves untouched, so this method cannot live on the enum body
/// itself — the `extension` keeps the call-site signature
/// (`breakpoint.toTier(...)`) identical to a source-enum instance method
/// without touching `core_breakpoint.dart`.
extension CoreBreakpointToTier on CoreBreakpoint {
  /// Returns the [CoreBreakpointTier] this breakpoint falls into.
  ///
  /// [boundaries] may be a partial map (only some tiers overridden) —
  /// any missing tier individually falls back to the matching key in
  /// [CoreBreakpointContract.defaultBoundaries].
  CoreBreakpointTier toTier({
    Map<CoreBreakpointTier, CoreBreakpoint> boundaries =
        CoreBreakpointContract.defaultBoundaries,
  }) {
    CoreBreakpoint boundaryFor(CoreBreakpointTier tier) =>
        boundaries[tier] ?? CoreBreakpointContract.defaultBoundaries[tier]!;
    // defaultBoundaries is a compile-time 3-entry literal, so this `!`
    // can never be null at runtime.

    if (minWidth >= boundaryFor(.desktop).minWidth) {
      return .desktop;
    }
    if (minWidth >= boundaryFor(.tablet).minWidth) {
      return .tablet;
    }
    return .mobile;
  }
}

/// Ordinal comparison for [CoreBreakpointTier] — `mobile < tablet <
/// desktop`, matching declaration order.
///
/// Consumers that need a "has the viewport reached this tier or wider"
/// judgement (e.g. `ResponsiveRowColumn`'s `switchAt` threshold) share
/// this single comparison instead of each re-deriving `.index >=`
/// locally per platform resolver (`resolver/resolver-pattern.md`,
/// dedup — one function per (Core type × operation)).
extension CoreBreakpointTierOrder on CoreBreakpointTier {
  /// Whether this tier is at or above [other] in the `mobile < tablet <
  /// desktop` ordering.
  bool isAtLeast(CoreBreakpointTier other) => index >= other.index;
}
