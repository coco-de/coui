import 'dart:convert';
import 'dart:math' show Rectangle, max, min;
import 'dart:typed_data';

import 'package:puppeteer/puppeteer.dart' show ElementHandle, Page;

/// Capture under the declared viewport, including content beyond its edges.
/// ElementHandle.screenshot temporarily grows the viewport for a large root,
/// which changes media queries and viewport units while the pixels are taken.
/// A document clip captures those pixels without changing the layout input.
/// Page.screenshot retains the existing clip raster rounding.
Future<Uint8List> captureElementPng(Page page, ElementHandle element) async {
  final box = await element.boundingBox;
  if (box == null || box.width <= 0 || box.height <= 0) {
    throw StateError('A screenshot requires a visible, non-empty element');
  }
  final scroll =
      jsonDecode(
            await page.evaluate<String>(
              '() => JSON.stringify({x: scrollX, y: scrollY})',
            ),
          )
          as Map<String, Object?>;
  return await page.screenshot(
    format: .png,
    clip: Rectangle(
      box.left + (scroll['x']! as num),
      box.top + (scroll['y']! as num),
      box.width,
      box.height,
    ),
    captureBeyondViewport: true,
  );
}

/// The pinned Puppeteer screenshot transport's final CDP rectangle.
///
/// Keep this in Dart: negative half coordinates use Dart's rounding, while
/// JavaScript Math.round would choose a different pixel. The Puppeteer path
/// still performs its existing rounding internally.
Map<String, num> captureCdpClip(Rectangle<num> clip) {
  final x = clip.left.round();
  final y = clip.top.round();
  return {
    'x': x,
    'y': y,
    'width': (clip.width + clip.left - x).round(),
    'height': (clip.height + clip.top - y).round(),
    'scale': 1,
  };
}

/// The pinned ElementHandle bounding box from all four DOM border corners.
Rectangle<num> captureBorderQuadBounds(List<num> quad) {
  if (quad.length != 8) throw ArgumentError('Expected four border corners');
  final x = [0, 2, 4, 6].map((i) => quad[i]).reduce(min);
  final y = [1, 3, 5, 7].map((i) => quad[i]).reduce(min);
  final width = [0, 2, 4, 6].map((i) => quad[i]).reduce(max) - x;
  final height = [1, 3, 5, 7].map((i) => quad[i]).reduce(max) - y;
  return Rectangle<num>(x, y, width, height);
}
