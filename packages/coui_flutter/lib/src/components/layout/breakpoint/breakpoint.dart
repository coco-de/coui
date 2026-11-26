/// Non-widget value-accessor for the global viewport breakpoint/tier.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:flutter/widgets.dart';

/// Non-widget value-accessor — [CoreBreakpointContract] implementation. No
/// render output (this is not a widget). Consists only of getters that
/// forward to a single `resolveBreakpoint(context)` call's
/// [ResolvedBreakpoint].
class Breakpoint implements CoreBreakpointContract {
  /// Creates a [Breakpoint] bound to [context].
  const Breakpoint(this.context);

  /// The [BuildContext] this accessor observes.
  final BuildContext context;

  @override
  double get width => resolveBreakpoint(context).width;

  @override
  CoreBreakpoint get coreBreakpoint => resolveBreakpoint(context).breakpoint;

  @override
  CoreBreakpointTier get tier => resolveBreakpoint(context).tier;
}

/// Real usage entry point — consumer code does not construct [Breakpoint]
/// directly; it queries through this extension instead.
extension BreakpointContextX on BuildContext {
  /// Whether this screen is currently mobile/tablet/desktop — the primary
  /// query API.
  CoreBreakpointTier get breakpointTier => resolveBreakpoint(this).tier;

  /// The active [CoreBreakpoint] (Tailwind's 6-tier scale) — exposed for
  /// interop with existing [CoreBreakpoint] consumers such as
  /// `CoreResponsiveContainerMaxWidth`.
  ///
  /// The member is named `coreBreakpoint` rather than `breakpoint`
  /// (Solutioning Gate D1, Critical): `responsive_framework` already
  /// exposes a `BuildContext` extension getter of the same name
  /// (`breakpoint`). If both extensions are imported in the same file —
  /// which happens on almost every screen during a file-by-file migration —
  /// Dart throws an "ambiguous extension member" compile error. Renaming to
  /// `coreBreakpoint` lets both extensions coexist without colliding.
  CoreBreakpoint get coreBreakpoint => resolveBreakpoint(this).breakpoint;

  /// Shorthand for `context.breakpointTier == CoreBreakpointTier.mobile`.
  ///
  /// This is a **different axis** from `AdaptiveScaling.mobile` (the
  /// text/size/radius scaling axis, `theme.scaling`) —
  /// this getter only looks at viewport width. Do not mix the two axes by
  /// hand-coding something like `if (context.isMobile) scale = 1.25`.
  bool get isMobile => breakpointTier == .mobile;

  /// Shorthand for `context.breakpointTier == CoreBreakpointTier.tablet`.
  bool get isTablet => breakpointTier == .tablet;

  /// Shorthand for `context.breakpointTier == CoreBreakpointTier.desktop`.
  ///
  /// This is a **different axis** from `AdaptiveScaling.desktop` (the
  /// scaling axis) — see [isMobile].
  bool get isDesktop => breakpointTier == .desktop;
}
