import 'package:coui_flutter/coui_flutter.dart';

/// Flutter interop helpers for the unified [ImageProperties].
///
/// `ImageProperties` itself is a platform-neutral data model defined
/// in `coui_core` (shared verbatim by Flutter and Web). This extension
/// adds Flutter-only `Rect` conveniences so call sites can keep working
/// with `dart:ui` rectangles while the canonical state stays neutral.
extension ImagePropertiesRect on ImageProperties {
  /// The crop region expressed as a Flutter [Rect].
  ///
  /// Built from the platform-neutral [ImageProperties.cropX] /
  /// [ImageProperties.cropY] / [ImageProperties.cropWidth] /
  /// [ImageProperties.cropHeight] scalars.
  Rect get cropRect => .fromLTWH(cropX, cropY, cropWidth, cropHeight);

  /// Returns a copy with the crop region taken from [rect].
  ImageProperties withCropRect(Rect rect) => copyWith(
    cropX: rect.left,
    cropY: rect.top,
    cropWidth: rect.width,
    cropHeight: rect.height,
  );
}

/// Builds a [ImageProperties] from a Flutter [Rect] crop region.
///
/// Convenience for Flutter call sites that already hold a `Rect`.
ImageProperties coImagePropertiesFromRect({
  Rect cropRect = .zero,
  double rotation = 0,
  bool flipHorizontal = false,
  bool flipVertical = false,
}) {
  return ImageProperties(
    cropX: cropRect.left,
    cropY: cropRect.top,
    cropWidth: cropRect.width,
    cropHeight: cropRect.height,
    rotation: rotation,
    flipHorizontal: flipHorizontal,
    flipVertical: flipVertical,
  );
}
