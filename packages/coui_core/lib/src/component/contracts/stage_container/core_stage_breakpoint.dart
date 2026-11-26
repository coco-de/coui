import 'package:meta/meta.dart';

/// Platform-independent breakpoint strategy for StageContainer.
///
/// Resolves the "content width" that a stage should clamp to given a
/// parent viewport width. Concrete strategies:
///
/// - [CoreConstantStageBreakpoint]: a single recurring grid size. The nearest
///   multiple below / above the viewport width is taken as the min / max.
/// - [CoreStagedStageBreakpoint]: a fixed ladder (e.g. Bootstrap's
///   `[576, 768, 992, 1200, 1400]`). The next rung above the viewport width
///   is the max, the rung below is the min.
///
/// The contract mirrors the legacy Flutter `StageBreakpoint` so Web/Flutter
/// can share the same breakpoint instance.
@immutable
abstract class CoreStageBreakpoint {
  /// Default staged ladder matching Bootstrap's container breakpoints.
  static const defaultBreakpoints =
      CoreStagedStageBreakpoint.defaultBreakpoints();

  /// Minimum content width (px) below which the strategy switches to a
  /// "narrow" mode (Flutter strips horizontal padding, Web does the same).
  double get minSize;

  /// Maximum content width (px). Anything wider gets the extra space split
  /// into left / right padding so the content stays centered.
  double get maxSize;

  /// Returns the lower rung for the given viewport [width].
  double getMinWidth(double width);

  /// Returns the upper rung for the given viewport [width].
  double getMaxWidth(double width);
}

/// Constant-rung strategy: every multiple of [breakpoint] is a rung.
///
/// Matches the legacy `ConstantBreakpoint`.
@immutable
class CoreConstantStageBreakpoint implements CoreStageBreakpoint {
  /// Creates a [CoreConstantStageBreakpoint].
  const CoreConstantStageBreakpoint(
    this.breakpoint, {
    this.maxSize = double.infinity,
    this.minSize = 0,
  });

  /// Grid step in pixels.
  final double breakpoint;

  @override
  final double minSize;

  @override
  final double maxSize;

  @override
  double getMinWidth(double width) => breakpoint * (width / breakpoint).floor();

  @override
  double getMaxWidth(double width) => breakpoint * (width / breakpoint).ceil();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreConstantStageBreakpoint &&
          other.breakpoint == breakpoint &&
          other.minSize == minSize &&
          other.maxSize == maxSize);

  @override
  int get hashCode => Object.hash(breakpoint, minSize, maxSize);
}

/// Staged-ladder strategy: a fixed ascending list of rungs.
///
/// Matches the legacy `StagedBreakpoint`.
@immutable
class CoreStagedStageBreakpoint implements CoreStageBreakpoint {
  /// Creates a [CoreStagedStageBreakpoint] from the given ladder. Must
  /// contain at least two rungs in strictly ascending order.
  const CoreStagedStageBreakpoint(this.breakpoints)
    : assert(breakpoints.length > 1, 'breakpoints must have at least 2 rungs');

  /// Default ladder: `[576, 768, 992, 1200, 1400]` (Bootstrap).
  const CoreStagedStageBreakpoint.defaultBreakpoints()
    : breakpoints = _defaultBreakpoints;

  /// Ladder rungs.
  final List<double> breakpoints;

  static const _defaultBreakpoints = [576.0, 768.0, 992.0, 1200.0, 1400.0];

  @override
  double get minSize => breakpoints.first;

  @override
  double get maxSize => breakpoints.last;

  @override
  double getMinWidth(double width) {
    for (var i = 1; i < breakpoints.length; i++) {
      if (width < breakpoints[i]) return breakpoints[i - 1];
    }
    return width;
  }

  @override
  double getMaxWidth(double width) {
    for (final b in breakpoints) {
      if (width < b) return b;
    }
    return maxSize;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreStagedStageBreakpoint) return false;
    if (other.breakpoints.length != breakpoints.length) return false;
    for (var i = 0; i < breakpoints.length; i++) {
      if (other.breakpoints[i] != breakpoints[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(breakpoints);
}
