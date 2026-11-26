/// Platform-independent contract for a global-viewport breakpoint/tier
/// accessor.
library;

import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_tier.dart';
import 'package:coui_core/src/component/contracts/media_query_visibility/core_breakpoint.dart';

/// Public contract answering "what is the current global viewport's
/// breakpoint/tier". No generics — value-branching utilities are out of
/// Phase 1 scope, so neither a composition slot nor a value-type generic
/// is needed.
abstract interface class CoreBreakpointContract {
  /// Tier boundary default — a BEHAVIOUR value (not chrome), so it lives
  /// here (Contract) rather than on a Style slot.
  ///
  /// Confirmed value (2026-07-08): mobile = `CoreBreakpoint.xs`(0) /
  /// tablet = `CoreBreakpoint.md`(768) / desktop = `CoreBreakpoint.lg`
  /// (1024).
  static const Map<CoreBreakpointTier, CoreBreakpoint> defaultBoundaries = {
    CoreBreakpointTier.mobile: CoreBreakpoint.xs,
    CoreBreakpointTier.tablet: CoreBreakpoint.md,
    CoreBreakpointTier.desktop: CoreBreakpoint.lg,
  };

  /// Global viewport width (logical px) at the time of observation.
  double get width;

  /// The [CoreBreakpoint] active for [width]. Named `coreBreakpoint`
  /// rather than `breakpoint` to avoid an ambiguous-extension-member
  /// collision with `responsive_framework`'s `BuildContext.breakpoint`
  /// getter when both packages are imported in the same file.
  CoreBreakpoint get coreBreakpoint;

  /// The semantic tier derived from [coreBreakpoint].
  CoreBreakpointTier get tier;
}
