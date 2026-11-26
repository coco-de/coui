/// Project-level theme for `Breakpoint`.
library;

import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_style.dart';
import 'package:meta/meta.dart';

/// Platform-independent theme for `Breakpoint`.
///
/// Carries only the chrome [style] slot — `Breakpoint` has no variant
/// enum, so there is no `variantStyles` slot. Tier boundaries are not a
/// theme override — they are a BEHAVIOUR default that lives as
/// `static const` on `CoreBreakpointContract.defaultBoundaries` and are
/// overridden via the `resolveBreakpoint(context, {boundaries:})`
/// call-site parameter instead.
@immutable
class CoreBreakpointTheme {
  /// Creates a [CoreBreakpointTheme].
  const CoreBreakpointTheme({this.style});

  /// Project-level chrome style merged on top of the design-system
  /// default. `null` → no project override. Currently has no fields to
  /// carry (`CoreBreakpointStyle` is an empty holder).
  final CoreBreakpointStyle? style;

  /// Returns a copy with the given fields replaced.
  CoreBreakpointTheme copyWith({CoreBreakpointStyle? style}) {
    return CoreBreakpointTheme(style: style ?? this.style);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreBreakpointTheme && other.style == style);

  @override
  int get hashCode => style.hashCode;
}
