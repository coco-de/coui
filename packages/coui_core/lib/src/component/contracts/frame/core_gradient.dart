import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/alignment.dart';
import 'package:meta/meta.dart';

/// Gradient kind for `CoreGradient`.
enum CoreGradientType {
  /// Linear gradient — colors interpolated along a line from `begin`
  /// to `end`.
  linear,

  /// Radial gradient — colors interpolated outward from the centre.
  radial,
}

/// Platform-independent gradient used by `CoreFrameContract.gradient`.
///
/// Maps to:
/// - Flutter: `LinearGradient` / `RadialGradient`.
/// - Web: CSS `linear-gradient(...)` / `radial-gradient(...)`.
/// - Figma: Fill type "Linear" / "Radial".
///
/// A radial gradient is centred on the box it paints and reaches the nearest
/// side; only a linear gradient reads [begin] and [end].
@immutable
class CoreGradient {
  /// Creates a [CoreGradient].
  const CoreGradient({
    required this.type,
    required this.colors,
    this.stops,
    this.begin = CoreAlignment.centerStart,
    this.end = CoreAlignment.centerEnd,
  });

  /// Gradient kind.
  final CoreGradientType type;

  /// Colour stops in interpolation order.
  final List<CoreColor> colors;

  /// Optional explicit stop positions (`0.0..1.0`). When `null`, stops
  /// are evenly distributed.
  final List<double>? stops;

  /// Linear gradient start anchor (ignored for radial).
  final CoreAlignment begin;

  /// Linear gradient end anchor (ignored for radial).
  final CoreAlignment end;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreGradient &&
        other.type == type &&
        _listEquals(other.colors, colors) &&
        _listEquals(other.stops, stops) &&
        other.begin == begin &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(
    type,
    Object.hashAll(colors),
    stops == null ? null : Object.hashAll(stops!),
    begin,
    end,
  );

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
