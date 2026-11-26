import 'package:coui_core/src/drag/core_drag_geometry.dart';
import 'package:meta/meta.dart';

/// How eagerly a drag scrolls its container near the edges.
///
/// The numbers live here rather than in each adapter because "how close to
/// the edge, and how fast" is a design decision — Flutter and Web must
/// answer it identically or the same drag feels different per platform.
@immutable
class CoreDragAutoScrollConfig {
  /// Creates an auto-scroll config.
  const CoreDragAutoScrollConfig({
    this.threshold = defaultThreshold,
    this.maxVelocity = defaultMaxVelocity,
  });

  /// How far from an edge the drag starts pulling, in logical pixels.
  static const double defaultThreshold = 48;

  /// Pixels per second at the very edge.
  static const double defaultMaxVelocity = 900;

  /// The default configuration.
  static const CoreDragAutoScrollConfig standard = CoreDragAutoScrollConfig();

  /// How far from an edge the drag starts pulling.
  final double threshold;

  /// Pixels per second at the very edge.
  final double maxVelocity;

  @override
  bool operator ==(Object other) =>
      other is CoreDragAutoScrollConfig &&
      other.threshold == threshold &&
      other.maxVelocity == maxVelocity;

  @override
  int get hashCode =>
      Object.hash(CoreDragAutoScrollConfig, threshold, maxVelocity);

  @override
  String toString() =>
      'CoreDragAutoScrollConfig(threshold: $threshold, '
      'maxVelocity: $maxVelocity)';
}

/// How fast a container should scroll, in pixels per second.
@immutable
class CoreDragScrollIntent {
  /// Creates a scroll intent.
  const CoreDragScrollIntent({this.x = 0, this.y = 0});

  /// Nothing should scroll.
  static const CoreDragScrollIntent none = CoreDragScrollIntent();

  /// Horizontal velocity — negative scrolls toward the start.
  final double x;

  /// Vertical velocity — negative scrolls toward the top.
  final double y;

  /// Whether this intent asks for any movement at all.
  bool get isActive => x != 0 || y != 0;

  /// The distance this intent covers over [elapsed].
  ///
  /// Adapters tick at whatever rate their frame loop runs, so the engine
  /// reports a velocity and lets the caller integrate it — a per-frame
  /// step would scroll at different speeds on different refresh rates.
  CoreDragOffset distanceOver(Duration elapsed) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

    return CoreDragOffset(x: x * seconds, y: y * seconds);
  }

  @override
  bool operator ==(Object other) =>
      other is CoreDragScrollIntent && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(CoreDragScrollIntent, x, y);

  @override
  String toString() => 'CoreDragScrollIntent($x, $y)';
}

/// Edge-proximity scrolling for a drag inside a scrollable container.
abstract final class CoreDragAutoScroll {
  /// How fast [containerRect] should scroll with the drag at [pointer].
  ///
  /// Velocity ramps linearly with how deep the pointer is inside the edge
  /// band, so the pull is gentle on entry and fastest at the boundary —
  /// a constant speed makes precise drops near the edge almost impossible.
  ///
  /// A pointer beyond the edge keeps the maximum rather than accelerating
  /// without bound: once the user has left the container, more distance
  /// carries no additional intent.
  static CoreDragScrollIntent resolve({
    required CoreDragPoint pointer,
    required CoreDragRect containerRect,
    CoreDragAutoScrollConfig config = .standard,
  }) {
    if (config.threshold <= 0 || config.maxVelocity <= 0) {
      return .none;
    }

    return CoreDragScrollIntent(
      x: _axisVelocity(
        position: pointer.x,
        start: containerRect.left,
        end: containerRect.right,
        config: config,
      ),
      y: _axisVelocity(
        position: pointer.y,
        start: containerRect.top,
        end: containerRect.bottom,
        config: config,
      ),
    );
  }

  /// Velocity along one axis, negative toward [start].
  ///
  /// A container thinner than two thresholds would otherwise have its
  /// bands overlap and fight; the near edge wins, which keeps the sign
  /// stable instead of flickering at the midpoint.
  static double _axisVelocity({
    required double position,
    required double start,
    required double end,
    required CoreDragAutoScrollConfig config,
  }) {
    final fromStart = position - start;
    final fromEnd = end - position;

    if (fromStart < fromEnd) {
      if (fromStart >= config.threshold) return 0;

      return -config.maxVelocity * _ramp(fromStart, config.threshold);
    }

    if (fromEnd >= config.threshold) return 0;

    return config.maxVelocity * _ramp(fromEnd, config.threshold);
  }

  /// How much of the maximum applies at [distance] into a [threshold] band.
  static double _ramp(double distance, double threshold) {
    if (distance <= 0) return 1;

    return (threshold - distance) / threshold;
  }
}
