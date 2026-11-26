/// Non-widget value-accessor for the current global-viewport breakpoint.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:jaspr/jaspr.dart';

/// Non-widget value-accessor — [CoreBreakpointContract] implementation.
///
/// Renders nothing (this is not a `Component`/widget) — every getter is
/// a thin forward to a single [resolveBreakpoint] call.
class Breakpoint implements CoreBreakpointContract {
  /// Creates a [Breakpoint] bound to [context].
  const Breakpoint(this.context);

  /// The context this accessor observes the global viewport through.
  final BuildContext context;

  @override
  double get width => resolveBreakpoint(context).width;

  @override
  CoreBreakpoint get coreBreakpoint => resolveBreakpoint(context).breakpoint;

  @override
  CoreBreakpointTier get tier => resolveBreakpoint(context).tier;
}

/// Entry point for consuming code — `context.breakpointTier` /
/// `context.isDesktop` etc., instead of constructing [Breakpoint]
/// directly (mirrors the Flutter counterpart member-for-member,
/// `cross-platform/api.md`).
extension BreakpointContextX on BuildContext {
  /// Whether this is mobile/tablet/desktop right now — the primary
  /// lookup API.
  CoreBreakpointTier get breakpointTier => resolveBreakpoint(this).tier;

  /// The active [CoreBreakpoint] (Tailwind's 6-step scale) — exposed for
  /// interop with existing [CoreBreakpoint] consumers such as
  /// `CoreResponsiveContainerMaxWidth`.
  ///
  /// Named `coreBreakpoint`, not `breakpoint`: `responsive_framework`
  /// already exposes a same-named `BuildContext.breakpoint` extension
  /// getter, and if both extensions were imported in the same file, Dart
  /// would throw an ambiguous-extension-member compile error. Renaming
  /// this one avoids the collision without touching the
  /// already-finalized `breakpointTier`/`isMobile`/`isTablet`/
  /// `isDesktop` names.
  CoreBreakpoint get coreBreakpoint => resolveBreakpoint(this).breakpoint;

  /// Shorthand for `context.breakpointTier == CoreBreakpointTier.mobile`.
  ///
  /// ⚠️ This is a *different axis* from `AdaptiveScaling.mobile` (the
  /// text/size/radius scaling axis, `theme.scaling`)
  /// — this getter only looks at viewport width. Do not mix the two
  /// axes (e.g. `if (context.isMobile) scale = 1.25`).
  bool get isMobile => breakpointTier == .mobile;

  /// Shorthand for `context.breakpointTier == CoreBreakpointTier.tablet`.
  bool get isTablet => breakpointTier == .tablet;

  /// Shorthand for `context.breakpointTier == CoreBreakpointTier.desktop`.
  ///
  /// ⚠️ Different axis from `AdaptiveScaling.desktop` — see [isMobile].
  bool get isDesktop => breakpointTier == .desktop;
}
