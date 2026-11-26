/// Platform-agnostic image-editing state for `ImageProperties`.
library;

import 'package:meta/meta.dart';

/// Immutable crop / rotation / flip state for image editing.
///
/// `ImageProperties` is the unified replacement for the legacy
/// Flutter and Web `ImageProperties` data classes — same semantics,
/// full parity. It is a pure platform-neutral data model (no
/// rendering), so it lives in `coui_core` and is shared verbatim by
/// both platforms.
///
/// The crop rectangle is expressed as four logical-pixel scalars
/// ([cropX], [cropY], [cropWidth], [cropHeight]) rather than a Flutter
/// `Rect`, because `coui_core` is platform-neutral and cannot depend
/// on `dart:ui`. Flutter call sites convert with `Rect.fromLTWH`.
///
/// ```dart
/// const props = ImageProperties(
///   rotation: 90,
///   flipHorizontal: true,
/// );
/// ```
@immutable
class ImageProperties {
  /// Creates a [ImageProperties].
  const ImageProperties({
    this.cropX = 0,
    this.cropY = 0,
    this.cropWidth = 0,
    this.cropHeight = 0,
    this.rotation = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  /// Crop rectangle X offset (logical px).
  final double cropX;

  /// Crop rectangle Y offset (logical px).
  final double cropY;

  /// Crop rectangle width (logical px).
  final double cropWidth;

  /// Crop rectangle height (logical px).
  final double cropHeight;

  /// Rotation angle in degrees.
  final double rotation;

  /// Whether the image is flipped horizontally.
  final bool flipHorizontal;

  /// Whether the image is flipped vertically.
  final bool flipVertical;

  /// Returns a copy of this state with the given fields replaced.
  ImageProperties copyWith({
    double? cropX,
    double? cropY,
    double? cropWidth,
    double? cropHeight,
    double? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
  }) {
    return ImageProperties(
      cropX: cropX ?? this.cropX,
      cropY: cropY ?? this.cropY,
      cropWidth: cropWidth ?? this.cropWidth,
      cropHeight: cropHeight ?? this.cropHeight,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageProperties &&
          runtimeType == other.runtimeType &&
          cropX == other.cropX &&
          cropY == other.cropY &&
          cropWidth == other.cropWidth &&
          cropHeight == other.cropHeight &&
          rotation == other.rotation &&
          flipHorizontal == other.flipHorizontal &&
          flipVertical == other.flipVertical;

  @override
  int get hashCode => Object.hash(
    cropX,
    cropY,
    cropWidth,
    cropHeight,
    rotation,
    flipHorizontal,
    flipVertical,
  );

  @override
  String toString() =>
      'ImageProperties(cropX: $cropX, cropY: $cropY, '
      'cropWidth: $cropWidth, cropHeight: $cropHeight, '
      'rotation: $rotation, flipHorizontal: $flipHorizontal, '
      'flipVertical: $flipVertical)';
}
