import 'package:meta/meta.dart';

/// Platform-independent alignment specification.
///
/// Maps to Flutter `Alignment` or CSS alignment properties.
@immutable
class CoreAlignment {
  /// Creates an alignment with x and y values from -1.0 to 1.0.
  const CoreAlignment(this.x, this.y);

  /// Horizontal alignment: -1.0 (start) to 1.0 (end).
  final double x;

  /// Vertical alignment: -1.0 (top) to 1.0 (bottom).
  final double y;

  /// Top-start alignment.
  static const topStart = CoreAlignment(-1, -1);

  /// Top-center alignment.
  static const topCenter = CoreAlignment(0, -1);

  /// Top-end alignment.
  static const topEnd = CoreAlignment(1, -1);

  /// Center-start alignment.
  static const centerStart = CoreAlignment(-1, 0);

  /// Center alignment.
  static const center = CoreAlignment(0, 0);

  /// Center-end alignment.
  static const centerEnd = CoreAlignment(1, 0);

  /// Bottom-start alignment.
  static const bottomStart = CoreAlignment(-1, 1);

  /// Bottom-center alignment.
  static const bottomCenter = CoreAlignment(0, 1);

  /// Bottom-end alignment.
  static const bottomEnd = CoreAlignment(1, 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAlignment && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'CoreAlignment($x, $y)';
}
