import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/model/capture_body.dart';

void main() {
  test(
    'a body column preserves every source pixel and the complete height',
    () {
      final stage = img.Image(width: 8, height: 5, numChannels: 4);
      for (final pixel in stage) {
        pixel
          ..r = pixel.x * 23
          ..g = pixel.y * 41
          ..b = pixel.x + pixel.y
          ..a = 100 + pixel.y;
      }
      final bytes = Uint8List.fromList(img.encodePng(stage));
      final body = img.decodePng(
        captureBodyColumn(bytes, left: 2.25, width: 3.5),
      )!;
      expect((body.width, body.height), (4, 5));
      for (final pixel in body) {
        final original = stage.getPixel(pixel.x + 2, pixel.y);
        expect(pixel.toList(), original.toList());
      }
    },
  );

  test('invalid or out-of-canvas geometry is an error, never padded', () {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 8, height: 5)),
    );
    for (final (left, width) in [
      (-1.0, 2.0),
      (7.0, 2.0),
      (0.0, 0.0),
      (double.nan, 1.0),
    ]) {
      expect(
        () => captureBodyColumn(bytes, left: left, width: width),
        throwsArgumentError,
      );
    }
    expect(
      () => captureBodyColumn(Uint8List(0), left: 0, width: 1),
      throwsFormatException,
    );
  });
}
