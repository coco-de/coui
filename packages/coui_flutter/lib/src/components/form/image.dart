import 'package:coui_flutter/coui_flutter.dart';

enum ImageType { bmp, gif, ico, jpg, png, pvr, tga, tiff }

class ImageProperties {
  const ImageProperties({
    this.cropRect = Rect.zero,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.rotation = 0,
  });

  final Rect cropRect;
  final double rotation;
  final bool flipHorizontal;

  final bool flipVertical;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImageProperties &&
        other.cropRect == cropRect &&
        other.rotation == rotation &&
        other.flipHorizontal == flipHorizontal &&
        other.flipVertical == flipVertical;
  }

  @override
  String toString() =>
      'ImageProperties(cropRect: $cropRect, rotation: $rotation, flipHorizontal: $flipHorizontal, flipVertical: $flipVertical)';

  @override
  int get hashCode =>
      Object.hash(cropRect, rotation, flipHorizontal, flipVertical);
}
