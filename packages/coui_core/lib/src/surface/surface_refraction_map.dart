import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coui_core/src/surface/surface_refraction.dart';

/// RGBA displacement pixels shared by DOM Web and Flutter Web.
///
/// R/G encode signed horizontal/vertical travel around the channel midpoint.
/// SVG multiplies that ratio by twice the corresponding peak displacement.
/// No browser types live here: adapters only upload these bytes to a canvas.
Uint8List surfaceRefractionDisplacementMap({
  required int width,
  required int height,
  required double radius,
  required CoreSurfaceRefraction refraction,
  bool lens = false,
}) {
  assert(width > 0 && height > 0, 'A displacement map needs a measured box.');
  final pixels = Uint8List(width * height * 4);
  final halfWidth = width / 2;
  final halfHeight = height / 2;
  final corner = radius.clamp(0.0, math.min(halfWidth, halfHeight));
  final band = math.min(width, height) * refraction.bezel;
  final peak = lens
      ? refraction.lensPeak(
          cornerPx: math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight),
        )
      : refraction.peakDisplacement(bandPx: band);

  double distance(double x, double y) {
    final qx = (x - halfWidth).abs() - (halfWidth - corner);
    final qy = (y - halfHeight).abs() - (halfHeight - corner);
    final mx = math.max(qx, 0.0);
    final my = math.max(qy, 0.0);
    return math.sqrt(mx * mx + my * my) +
        math.min(math.max(qx, qy), 0) -
        corner;
  }

  int channel(double ratio) => ((ratio * .5 + .5) * 255).round().clamp(0, 255);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final px = x + .5;
      final py = y + .5;
      double dx;
      double dy;
      if (lens) {
        dx = peak == 0 ? 0 : refraction.lensDisplacement(px - halfWidth) / peak;
        dy = peak == 0
            ? 0
            : refraction.lensDisplacement(py - halfHeight) / peak;
      } else {
        final gx = distance(px + 1, py) - distance(px - 1, py);
        final gy = distance(px, py + 1) - distance(px, py - 1);
        final length = math.sqrt(gx * gx + gy * gy);
        final unit = length == 0 ? 1.0 : length;
        final travel = refraction.displacementAt(
          insetPx: math.max(0, -distance(px, py)),
          bandPx: band,
        );
        final ratio = peak == 0 ? 0.0 : travel / peak;
        dx = (gx / unit) * ratio;
        dy = (gy / unit) * ratio;
      }
      final at = (y * width + x) * 4;
      pixels[at] = channel(dx);
      pixels[at + 1] = channel(dy);
      pixels[at + 3] = 255;
    }
  }
  return pixels;
}
