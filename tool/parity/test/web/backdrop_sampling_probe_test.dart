// How Chromium samples the backdrop when a displacement filter moves it by a
// fraction of a pixel — the Web half of a question the Flutter renderer
// answered on Impeller.
//
// On Impeller the shipped refraction shader read its input through a
// nearest-neighbour sampler: a half-texel shift over a hard edge returned
// the neighbouring texel unmixed, so every displaced read snapped to a
// whole pixel and the bend stepped instead of sliding
// (`app/coui_widgetbook/integration_test/refraction_sampling_probe_test.dart`,
// P2 and P3). The Flutter shader now interpolates by hand. Whether that
// *restored* parity or *created* an asymmetry depends on what the Web
// renderer does with the same fraction — `feDisplacementMap` inside
// `backdrop-filter`, which is how the Web surface bends. If Chromium
// interpolates, the two platforms now agree; if it snaps too, the Flutter
// change made Flutter the smoother of the two and this file is the record
// of that.
//
// Measured, not inferred from the SVG specification: the specification
// leaves the sampling of the displaced read to the implementation.
//
// A run with no Chrome on the machine is skipped, not zeroed.
library;

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import '../../../browser_launch.dart';

/// Mirrors `computed_style_probe_test.dart`'s system-Chrome lookup.
String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

const kViewportWidth = 300;
const kViewportHeight = 200;

/// Panel geometry, shared by the page and the capture clip. Two solid halves
/// — red then blue — meet at the panel's middle column.
const kPanelLeft = 50;
const kPanelTop = 50;
const kPanelWidth = 200;
const kPanelHeight = 100;

/// A displacement map that is the same everywhere: full red, half green. With
/// `xChannelSelector="R"` and `yChannelSelector="G"` that is "move every
/// sample along x by `scale × (1 − 0.5)`, and not at all along y".
///
/// Built from a canvas the size of the panel rather than a 1×1 image, so no
/// `preserveAspectRatio` interpretation can stretch or letterbox the map.
const String _kPageHtml =
    '''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>
  html, body { margin: 0; background: #ffffff; }
  #panel {
    position: absolute;
    left: ${kPanelLeft}px; top: ${kPanelTop}px;
    width: ${kPanelWidth}px; height: ${kPanelHeight}px;
    overflow: hidden;
  }
  .half { position: absolute; top: 0; height: 100%; width: 50%; }
  #red  { left: 0;   background: #ff0000; }
  #blue { left: 50%; background: #0000ff; }
  #glass { position: absolute; inset: 0; }
</style>
</head>
<body>
<div id="panel">
  <div id="red" class="half"></div>
  <div id="blue" class="half"></div>
  <div id="glass"></div>
</div>
<svg width="0" height="0" style="position:absolute" aria-hidden="true">
  <defs>
    <filter id="shift" x="0" y="0" width="100%" height="100%"
            filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB">
      <feImage id="map" result="map" />
      <feDisplacementMap id="disp" in="SourceGraphic" in2="map" scale="0"
                         xChannelSelector="R" yChannelSelector="G" />
    </filter>
  </defs>
</svg>
<script>
  (function () {
    const canvas = document.createElement('canvas');
    canvas.width = $kPanelWidth;
    canvas.height = $kPanelHeight;
    const ctx = canvas.getContext('2d');
    const image = ctx.createImageData($kPanelWidth, $kPanelHeight);
    for (let i = 0; i < image.data.length; i += 4) {
      image.data[i] = 255;     // R: full → +0.5 × scale along x
      image.data[i + 1] = 128; // G: half → no travel along y
      image.data[i + 2] = 0;
      image.data[i + 3] = 255;
    }
    ctx.putImageData(image, 0, 0);
    document.getElementById('map')
        .setAttributeNS('http://www.w3.org/1999/xlink', 'href', canvas.toDataURL());
    document.getElementById('map').setAttribute('href', canvas.toDataURL());
    window.__setShift = function (scale) {
      document.getElementById('disp').setAttribute('scale', String(scale));
      const glass = document.getElementById('glass');
      glass.style.backdropFilter = scale === 0 ? 'none' : 'url(#shift)';
      glass.style.webkitBackdropFilter = glass.style.backdropFilter;
    };
  })();
</script>
</body>
</html>
''';

Future<void> _settle(Page page) async {
  await page.evaluate<void>(
    '() => new Promise(function (done) { requestAnimationFrame(function () '
    '{ requestAnimationFrame(done); }); })',
  );
}

Future<img.Image> _shootPanel(Page page) async {
  final bytes = await page.screenshot(
    clip: const Rectangle(kPanelLeft, kPanelTop, kPanelWidth, kPanelHeight),
  );

  return img.decodePng(bytes)!;
}

/// Columns in the middle row whose colour is neither of the two solid halves.
int _intermediateColumns(img.Image image) {
  final row = image.height ~/ 2;
  var mixed = 0;
  for (var x = 0; x < image.width; x++) {
    final px = image.getPixel(x, row);
    final isRed = px.r > 250 && px.b < 5;
    final isBlue = px.b > 250 && px.r < 5;
    if (!isRed && !isBlue) mixed++;
  }

  return mixed;
}

String _hex(img.Image image, int x) {
  final px = image.getPixel(x, image.height ~/ 2);

  return [
    px.r,
    px.g,
    px.b,
  ].map((c) => c.toInt().toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  final chromePath = _systemChromePath();
  final skipReason = chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null;

  group('W2 — how Chromium samples a displaced backdrop', () {
    late Browser browser;
    late Page page;
    late Directory tempDir;

    setUpAll(() async {
      if (chromePath == null) return;
      browser = await launchCaptureBrowser(
        width: kViewportWidth,
        height: kViewportHeight,
        executablePath: chromePath,
      );
    });

    tearDownAll(() async {
      if (chromePath == null) return;
      await browser.close();
    });

    setUp(() async {
      if (chromePath == null) return;
      page = await browser.newPage();
      tempDir = Directory.systemTemp.createTempSync('backdrop-sampling-');
      final file = File(p.join(tempDir.path, 'sampling.html'))
        ..writeAsStringSync(_kPageHtml);
      await page.goto(Uri.file(file.path).toString(), wait: Until.load);
      await _settle(page);
    });

    tearDown(() async {
      if (chromePath == null) return;
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    test('a half-pixel shift, read at the edge between the halves', () async {
      await page.evaluate<void>('() => window.__setShift(0)');
      await _settle(page);
      final control = await _shootPanel(page);

      // scale 1 × (255/255 − 0.5) = half a pixel along x.
      await page.evaluate<void>('() => window.__setShift(1)');
      await _settle(page);
      final half = await _shootPanel(page);

      // scale 2 → a whole pixel: the edge moves, nothing is mixed, under
      // either sampler. Tells a mixed column from a moved one.
      await page.evaluate<void>('() => window.__setShift(2)');
      await _settle(page);
      final whole = await _shootPanel(page);

      final edge = kPanelWidth ~/ 2;
      final report = StringBuffer()
        ..write('W2  column ${edge - 1}: control=${_hex(control, edge - 1)}')
        ..write(
          '  half=${_hex(half, edge - 1)}  whole=${_hex(whole, edge - 1)}',
        )
        ..write(
          '  intermediateColumns control=${_intermediateColumns(control)}',
        )
        ..write(' half=${_intermediateColumns(half)}')
        ..write(' whole=${_intermediateColumns(whole)}');
      // ignore: avoid_print — the number is the deliverable.
      print(report);

      expect(
        _intermediateColumns(control),
        0,
        reason: 'the control drew something other than two solid halves',
      );
      // The half-pixel count is the finding and is not asserted to a value:
      // "snaps" is the browser's answer, not a failure of this harness.
    }, skip: skipReason);
  });
}
