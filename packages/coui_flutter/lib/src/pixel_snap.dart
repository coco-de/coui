import 'package:flutter/widgets.dart';

/// Rounds a logical-pixel [logical] value to the nearest physical-pixel
/// boundary for the given [devicePixelRatio].
///
/// Aligning sizes / offsets to whole physical pixels avoids the blurry
/// sub-pixel anti-aliasing that fractional device-pixel-ratios (e.g. a
/// 150 % display scale → `dpr = 1.5`) introduce on otherwise crisp edges.
/// Ported from shadcn_flutter's pixel-snap mechanism.
///
/// A no-op when `logical * devicePixelRatio` already lands on a whole
/// physical pixel (the common case at `dpr` 1.0 / 2.0 with integral
/// sizes), so it never shifts layout on integer-ratio displays.
double pixelSnap(double logical, double devicePixelRatio) {
  if (devicePixelRatio <= 0) return logical;
  return (logical * devicePixelRatio).roundToDouble() / devicePixelRatio;
}

/// Provides physical-pixel snapping to descendants.
///
/// Mounted by `CoUIApp` when `pixelSnap` is enabled (the default), so any
/// descendant can align a dimension to the device's physical-pixel grid
/// via [PixelSnap.snapOf]. When no `PixelSnap` ancestor exists (snapping
/// disabled), [snapOf] returns the value unchanged.
class PixelSnap extends InheritedWidget {
  /// Creates a [PixelSnap] scope for the given [devicePixelRatio].
  const PixelSnap({
    required this.devicePixelRatio,
    required super.child,
    super.key,
  });

  /// The nearest [PixelSnap] ancestor, or `null` when snapping is off.
  static PixelSnap? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType();

  /// Snaps [logical] to the physical-pixel grid of the nearest [PixelSnap]
  /// ancestor; returns [logical] unchanged when there is none.
  static double snapOf(BuildContext context, double logical) =>
      maybeOf(context)?.snap(logical) ?? logical;

  /// The active device pixel ratio snapping aligns to.
  final double devicePixelRatio;

  /// Snaps [logical] to the nearest physical pixel for this scope's
  /// [devicePixelRatio].
  double snap(double logical) => pixelSnap(logical, devicePixelRatio);

  @override
  bool updateShouldNotify(PixelSnap oldWidget) =>
      devicePixelRatio != oldWidget.devicePixelRatio;
}
