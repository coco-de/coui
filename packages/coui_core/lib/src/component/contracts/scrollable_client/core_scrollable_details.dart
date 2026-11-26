import 'package:coui_core/src/component/contracts/scrollable_client/core_axis_direction.dart';
import 'package:meta/meta.dart';

/// Platform-independent subset of Flutter's `ScrollableDetails` that makes
/// sense on both Flutter and Web.
///
/// Per-axis settings that cannot be mirrored on Web (controller, physics,
/// decorationClipBehavior, …) remain on the Flutter-specific
/// `ScrollableDetails` object and are not exposed through this contract type.
@immutable
class CoreScrollableDetails {
  /// Creates a [CoreScrollableDetails].
  const CoreScrollableDetails({
    required this.direction,
    this.initialOffset = 0,
  });

  /// Forward-pointing [CoreScrollableDetails] for the vertical axis (origin
  /// at the top, content grows downward).
  const CoreScrollableDetails.vertical({this.initialOffset = 0})
    : direction = CoreAxisDirection.down;

  /// Reverse-pointing [CoreScrollableDetails] for the vertical axis (origin
  /// at the bottom, content grows upward).
  const CoreScrollableDetails.verticalReverse({this.initialOffset = 0})
    : direction = CoreAxisDirection.up;

  /// Forward-pointing [CoreScrollableDetails] for the horizontal axis
  /// (origin at the left, content grows rightward).
  const CoreScrollableDetails.horizontal({this.initialOffset = 0})
    : direction = CoreAxisDirection.right;

  /// Reverse-pointing [CoreScrollableDetails] for the horizontal axis
  /// (origin at the right, content grows leftward).
  const CoreScrollableDetails.horizontalReverse({this.initialOffset = 0})
    : direction = CoreAxisDirection.left;

  /// Direction this axis grows in (`up`/`down` → vertical, `left`/`right` →
  /// horizontal).
  final CoreAxisDirection direction;

  /// Initial scroll offset along this axis in pixels. Applied once the
  /// viewport first attaches.
  final double initialOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreScrollableDetails &&
          other.direction == direction &&
          other.initialOffset == initialOffset);

  @override
  int get hashCode => Object.hash(direction, initialOffset);
}
