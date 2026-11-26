import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Keep the stage image as well: this column intentionally excludes its
/// horizontal context, not the separate stage comparison's painted pixels.
/// The complete vertical raster is retained, including each engine's own
/// fractional-height rasterization. No pixels are scaled, padded or masked.
Uint8List captureBodyColumn(
  Uint8List stagePng, {
  required double left,
  required double width,
}) {
  if (stagePng.isEmpty) throw const FormatException('Invalid stage PNG');
  final stage = img.decodePng(stagePng);
  if (stage == null) throw const FormatException('Invalid stage PNG');
  if (!left.isFinite || !width.isFinite || width <= 0) {
    throw ArgumentError('Invalid body column: left=$left width=$width');
  }
  final start = left.floor();
  final end = (left + width).ceil();
  if (start < 0 || end > stage.width) {
    throw ArgumentError(
      'Body column $start..$end exceeds stage width ${stage.width}',
    );
  }
  return Uint8List.fromList(
    img.encodePng(
      img.copyCrop(
        stage,
        x: start,
        y: 0,
        width: end - start,
        height: stage.height,
      ),
    ),
  );
}

/// Root keeps its established name. A declared stage is an additional
/// required artifact, never a substitute for the root body comparison.
String pixelArtifactKey(String key, String probeRole) =>
    probeRole == 'stage' ? '$key.stage' : key;
