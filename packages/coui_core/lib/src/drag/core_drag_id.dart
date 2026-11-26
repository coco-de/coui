import 'package:meta/meta.dart';

/// Stable identity of a draggable item or drop zone inside one drag scope.
///
/// Ids are caller-owned values, not engine-generated handles: the same id
/// must refer to the same logical item across rebuilds so a drag session
/// survives the re-render that its own movement triggers.
@immutable
class CoreDragId {
  /// Creates a drag id from a caller-owned [value].
  const CoreDragId(this.value);

  /// The caller-owned identity string.
  final String value;

  @override
  bool operator ==(Object other) => other is CoreDragId && other.value == value;

  @override
  int get hashCode => Object.hash(CoreDragId, value);

  @override
  String toString() => 'CoreDragId($value)';
}
