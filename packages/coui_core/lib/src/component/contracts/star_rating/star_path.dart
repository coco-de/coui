import 'dart:math' as math;

/// Platform-independent star path point generator.
///
/// Generates a list of (x, y) points for a star shape
/// that can be used in Flutter CustomPainter or Web SVG.
abstract final class CoreStarPath {
  const CoreStarPath._();

  /// Start angle offset — 12 o'clock position.
  static const double _kStartAngleOffset = -math.pi / 2;

  /// Maximum rounding clamp value.
  static const _kMaxRounding = 0.5;

  /// Generates star polygon points as a list of (x, y) pairs.
  ///
  /// Returns points in a coordinate system where (0,0) is center
  /// and the star fits within a circle of [radius].
  static List<({double x, double y})> generatePoints({
    required double points,
    required double radius,
    double innerRadiusRatio = 0.4,
    double rotation = 0.0,
    double squash = 0.0,
  }) {
    final numPoints = points.round();
    final innerRadius = radius * innerRadiusRatio;
    final result = <({double x, double y})>[];
    final startAngle = _kStartAngleOffset + rotation;
    final angleStep = math.pi / numPoints;

    for (var i = 0; i < numPoints * 2; i++) {
      final angle = startAngle + i * angleStep;
      final r = i.isEven ? radius : innerRadius;
      final x = r * math.cos(angle);
      var y = r * math.sin(angle);
      if (squash > 0) {
        y *= 1.0 - squash;
      }
      result.add((x: x, y: y));
    }
    return result;
  }

  /// Generates an SVG path string for a star shape.
  ///
  /// The path is centered at ([size]/2, [size]/2) and fits
  /// within a square of [size] x [size].
  static String toSvgPath({
    required double size,
    double points = 5,
    double innerRadiusRatio = 0.4,
    double rotation = 0.0,
    double squash = 0.0,
    double pointRounding = 0.0,
    double valleyRounding = 0.0,
  }) {
    final halfSize = size / 2;
    final starPoints = generatePoints(
      points: points,
      radius: halfSize,
      innerRadiusRatio: innerRadiusRatio,
      rotation: rotation,
      squash: squash,
    );

    if (starPoints.isEmpty) return '';

    // No rounding — simple polygon.
    if (pointRounding <= 0 && valleyRounding <= 0) {
      final sb = StringBuffer();
      for (var i = 0; i < starPoints.length; i++) {
        final p = starPoints[i];
        if (i == 0) {
          sb.write('M${_f(p.x + halfSize)},${_f(p.y + halfSize)}');
        } else {
          sb.write(' L${_f(p.x + halfSize)},${_f(p.y + halfSize)}');
        }
      }
      sb.write(' Z');
      return sb.toString();
    }

    // With rounding — use quadratic bezier at corners.
    final sb = StringBuffer();
    final n = starPoints.length;

    for (var i = 0; i < n; i++) {
      final prev = starPoints[(i - 1 + n) % n];
      final curr = starPoints[i];
      final next = starPoints[(i + 1) % n];

      final isOuter = i.isEven;
      final rounding = isOuter ? pointRounding : valleyRounding;
      final r = rounding.clamp(0.0, _kMaxRounding);

      final fromX = curr.x + (prev.x - curr.x) * r;
      final fromY = curr.y + (prev.y - curr.y) * r;
      final toX = curr.x + (next.x - curr.x) * r;
      final toY = curr.y + (next.y - curr.y) * r;

      if (i == 0) {
        sb.write('M${_f(fromX + halfSize)},${_f(fromY + halfSize)}');
      } else {
        sb.write(' L${_f(fromX + halfSize)},${_f(fromY + halfSize)}');
      }
      sb.write(
        ' Q${_f(curr.x + halfSize)},${_f(curr.y + halfSize)}'
        ' ${_f(toX + halfSize)},${_f(toY + halfSize)}',
      );
    }
    sb.write(' Z');
    return sb.toString();
  }

  static String _f(double v) => v.toStringAsFixed(2);
}
