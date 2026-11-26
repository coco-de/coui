// Three questions about how the engine runs the shipped refraction shader,
// answered on a real Impeller device and nowhere else.
//
//   P1  In which unit does `ImageFilter.shader` hand the program its
//       coordinates — logical or physical pixels? The shipped shader gets
//       its corner radius in logical pixels; if the texture is physical the
//       corner it bends around is the true one divided by the device pixel
//       ratio.
//   P2  Is the backdrop bound with a nearest or a linear sampler? A
//       half-texel shift over a hard edge yields an intermediate colour only
//       under linear sampling. The same shift interpolated by hand from four
//       nearest fetches is the workaround, and it either restores that
//       colour or it does not.
//   P3  On the shipped surface, how much of the bending band is made of
//       intermediate colours? Nearest sampling snaps every displaced sample
//       to a texel, so a striped backdrop stays two-valued inside the band;
//       linear sampling fills it with the in-betweens a real lens would.
//       The blur is tuned to a hair above zero, not zero: a surface with no
//       blur mounts no backdrop pass at all, and the bend rides that pass.
//       A first version tuned it to zero and measured a surface that did
//       not bend — identical before and after any shader change.
//
// Whether the *first* frame bends is a separate question with its own file,
// `refraction_first_frame_probe_test.dart`, because it depends on the
// process being cold: a P4 here once reported 0.0000 after P3 had loaded the
// program into the engine's registry, which said nothing about first frames.
//
// ## Why this cannot be a widget test
//
// `flutter_tester` renders with Skia, where `isShaderFilterSupported` is
// `false` and `ImageFilter.shader` throws. Every value here would be missing
// rather than measured. Run it as:
//
//   flutter test integration_test/refraction_sampling_probe_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos
//
// ## Why captures are taken at the device pixel ratio
//
// `toImage()` rasterises offscreen at the ratio it is given, and the
// backdrop the filter samples is that raster. A capture at 1.0 on a 2×
// display would hand the shader a texture half the size the screen does,
// and P1 would report the wrong unit for the frame people actually see.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Supplied by the runner alongside `-d`, so every reported value carries the
/// device it came from. Empty means the probe refuses to report.
const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

/// Where PNGs of the captures go, when the sandbox lets them be written.
/// A number is the deliverable; the picture is for the person reading it.
const kProbeOutputDir = String.fromEnvironment('PROBE_OUTPUT_DIR');

const kSizeShaderAsset = 'shaders/probe_size.frag';
const kHalfTexelShaderAsset = 'shaders/probe_half_texel.frag';
const kHalfTexelBilinearShaderAsset = 'shaders/probe_half_texel_bilinear.frag';

/// Mirrors `kSizeScale` in `probe_size.frag`.
const kSizeScale = 2048.0;

/// Logical size of the surface under test. 100 on the short side puts the
/// shipped 27% band at 27 logical pixels — wide enough to read.
const kSurfaceWidth = 200.0;
const kSurfaceHeight = 100.0;

/// Margin around the surface inside the capture, so the band never touches
/// the capture edge and the backdrop is visible on every side.
const kMargin = 20.0;

const kCaptureWidth = kSurfaceWidth + kMargin * 2;
const kCaptureHeight = kSurfaceHeight + kMargin * 2;

/// Width of one backdrop stripe in logical pixels.
const kStripeWidth = 4.0;

/// A blur too small to make an in-between colour, but not zero: zero mounts
/// no backdrop pass, and the bend rides that pass.
const kHairlineBlur = 0.1;

/// The blur the shipped preset states, for the picture.
const kShippedBlur = 4.0;

/// Bytes per pixel in [ui.ImageByteFormat.rawRgba].
const kBytesPerPixel = 4;

/// How close a channel must be to a dominant level to count as that level.
const kLevelTolerance = 6;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(
      kProbeDeviceId,
      isNotEmpty,
      reason:
          'Pass --dart-define=PROBE_DEVICE_ID=<deviceId> matching the -d '
          'flag. An unattributed value is not a measurement.',
    );
  });

  group('P1 — the unit ImageFilter.shader hands the program', () {
    testWidgets(
      'uSize against the logical size, at 1× and at the device ratio',
      (tester) async {
        if (!ui.ImageFilter.isShaderFilterSupported) {
          debugPrint('P1  device=$kProbeDeviceId  not run: no shader filters');
          return;
        }
        final program = await tester.runAsync(
          () => ui.FragmentProgram.fromAsset(kSizeShaderAsset),
        );
        final filter = ui.ImageFilter.shader(program!.fragmentShader());
        final dpr = tester.view.devicePixelRatio;

        for (final ratio in [1.0, dpr]) {
          final capture = await _captureHalves(
            tester,
            filter: filter,
            pixelRatio: ratio,
          );
          final px = capture.pixelAt(10, 10);
          final reportedWidth = px[0] / 255 * kSizeScale;
          final reportedHeight = px[1] / 255 * kSizeScale;
          debugPrint(
            'P1  device=$kProbeDeviceId  dpr=$dpr  captureRatio=$ratio'
            '  logical=${kSurfaceWidth}x$kSurfaceHeight'
            '  uSize≈${reportedWidth.toStringAsFixed(0)}x'
            '${reportedHeight.toStringAsFixed(0)}',
          );
          // The step of the 8-bit encoding, plus one for rounding.
          final step = kSizeScale / 255 + 1;
          expect(reportedWidth, closeTo(kSurfaceWidth * ratio, step));
          expect(reportedHeight, closeTo(kSurfaceHeight * ratio, step));
        }
      },
    );
  });

  group('P2 — the sampler the engine bound to the backdrop', () {
    testWidgets('a half-texel shift, plain and hand-interpolated', (
      tester,
    ) async {
      if (!ui.ImageFilter.isShaderFilterSupported) {
        debugPrint('P2  device=$kProbeDeviceId  not run: no shader filters');
        return;
      }
      final plain = await tester.runAsync(
        () => ui.FragmentProgram.fromAsset(kHalfTexelShaderAsset),
      );
      final manual = await tester.runAsync(
        () => ui.FragmentProgram.fromAsset(kHalfTexelBilinearShaderAsset),
      );

      // 1× so one texel is one logical pixel and "half a texel" is exact.
      final control = await _captureHalves(tester, filter: null, pixelRatio: 1);
      final viaPlain = await _captureHalves(
        tester,
        filter: ui.ImageFilter.shader(plain!.fragmentShader()),
        pixelRatio: 1,
      );
      final viaManual = await _captureHalves(
        tester,
        filter: ui.ImageFilter.shader(manual!.fragmentShader()),
        pixelRatio: 1,
      );

      final row = kSurfaceHeight ~/ 2;
      final edge = kSurfaceWidth ~/ 2;
      final controlAt = control.pixelAt(edge - 1, row);
      final plainAt = viaPlain.pixelAt(edge - 1, row);
      final manualAt = viaManual.pixelAt(edge - 1, row);
      final plainMixed = _intermediateColumns(viaPlain, row);
      final manualMixed = _intermediateColumns(viaManual, row);

      debugPrint(
        'P2  device=$kProbeDeviceId  column ${edge - 1}:'
        '  control=${_hex(controlAt)}  plain=${_hex(plainAt)}'
        '  manual=${_hex(manualAt)}'
        '  intermediateColumns plain=$plainMixed manual=$manualMixed',
      );

      expect(
        _intermediateColumns(control, row),
        0,
        reason: 'the control drew something other than two solid halves',
      );
      // The finding is the pair of counts. Neither is asserted to a value,
      // because "nearest" is the engine's answer, not a failure of this
      // harness — and an engine that binds linear is a result too.
    });
  });

  group('P3 — intermediate colour inside the shipped band', () {
    testWidgets('over a striped backdrop, blur zero, at the device ratio', (
      tester,
    ) async {
      if (!ui.ImageFilter.isShaderFilterSupported) {
        debugPrint('P3  device=$kProbeDeviceId  not run: no shader filters');
        return;
      }
      final dpr = tester.view.devicePixelRatio;
      final capture = await _captureSurface(
        tester,
        pixelRatio: dpr,
        blur: kHairlineBlur,
        label: 'p3-bend-only',
      );
      // The shipped blur too, for the picture — the numbers above are read
      // off the bend-only capture, where the blur cannot supply in-betweens.
      await _captureSurface(
        tester,
        pixelRatio: dpr,
        blur: kShippedBlur,
        label: 'p3-shipped-blur',
      );

      // The straight part of the left band: past the 1px edge run, short
      // of the corner arcs. Inset 2..24 logical px, rows 30..70.
      final band = capture.region(
        left: kMargin + 2,
        top: kMargin + 30,
        width: 22,
        height: 40,
        ratio: dpr,
      );
      // The flat interior, as the control this metric is read against:
      // no displacement, so the stripes stay exactly two-valued whatever
      // the sampler.
      final interior = capture.region(
        left: kMargin + 60,
        top: kMargin + 30,
        width: 60,
        height: 40,
        ratio: dpr,
      );

      final bandMetric = _levels(band);
      final interiorMetric = _levels(interior);
      debugPrint(
        'P3  device=$kProbeDeviceId  dpr=$dpr'
        '  band: distinct=${bandMetric.distinct}'
        ' intermediate=${bandMetric.intermediateFraction.toStringAsFixed(4)}'
        ' dominant=${bandMetric.dominant}'
        '  interior: distinct=${interiorMetric.distinct}'
        ' intermediate=${interiorMetric.intermediateFraction.toStringAsFixed(4)}'
        ' dominant=${interiorMetric.dominant}',
      );

      expect(
        interiorMetric.intermediateFraction,
        lessThan(0.05),
        reason:
            'the interior is not two-valued — the backdrop or the '
            'fill is not what this metric assumes',
      );
    });
  });
}

/// A capture with the geometry needed to read it back.
class _Capture {
  const _Capture(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;

  List<int> pixelAt(int x, int y) {
    final at = ((y * width) + x) * kBytesPerPixel;

    return bytes.sublist(at, at + kBytesPerPixel);
  }

  /// The pixels of a logical rectangle, scaled by [ratio].
  List<List<int>> region({
    required double left,
    required double top,
    required double width,
    required double height,
    required double ratio,
  }) {
    final x0 = (left * ratio).round();
    final y0 = (top * ratio).round();
    final x1 = ((left + width) * ratio).round();
    final y1 = ((top + height) * ratio).round();
    final out = <List<int>>[];
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        out.add(pixelAt(x, y));
      }
    }

    return out;
  }
}

class _Levels {
  const _Levels(this.distinct, this.intermediateFraction, this.dominant);

  final int distinct;
  final double intermediateFraction;
  final List<int> dominant;
}

/// Grey-level histogram of [pixels]: how many distinct levels, the two most
/// common, and what fraction of pixels sit near neither of those two.
_Levels _levels(List<List<int>> pixels) {
  final counts = <int, int>{};
  for (final px in pixels) {
    final grey = (px[0] + px[1] + px[2]) ~/ 3;
    counts[grey] = (counts[grey] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final dominant = sorted.take(2).map((e) => e.key).toList();
  var near = 0;
  for (final px in pixels) {
    final grey = (px[0] + px[1] + px[2]) ~/ 3;
    if (dominant.any((d) => (grey - d).abs() <= kLevelTolerance)) near++;
  }

  return _Levels(
    counts.length,
    pixels.isEmpty ? 0 : 1 - near / pixels.length,
    dominant,
  );
}

/// Columns in [row] whose colour is neither of the two solid halves.
int _intermediateColumns(_Capture capture, int row) {
  var mixed = 0;
  for (var x = 0; x < capture.width; x++) {
    final px = capture.pixelAt(x, row);
    final isRed = px[0] > 250 && px[2] < 5;
    final isBlue = px[2] > 250 && px[0] < 5;
    if (!isRed && !isBlue) mixed++;
  }

  return mixed;
}

String _hex(List<int> px) =>
    px.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Two solid halves — red then blue — of the surface size, optionally
/// behind [filter]. The harness from the capability probe, kept the same
/// so its control reads the same way.
Future<_Capture> _captureHalves(
  WidgetTester tester, {
  required ui.ImageFilter? filter,
  required double pixelRatio,
}) async {
  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: kSurfaceWidth,
            height: kSurfaceHeight,
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  width: kSurfaceWidth / 2,
                  height: kSurfaceHeight,
                  child: ColoredBox(color: Color(0xFFFF0000)),
                ),
                const Positioned(
                  left: kSurfaceWidth / 2,
                  top: 0,
                  width: kSurfaceWidth / 2,
                  height: kSurfaceHeight,
                  child: ColoredBox(color: Color(0xFF0000FF)),
                ),
                if (filter != null)
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: filter,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _readBoundary(tester, boundaryKey, pixelRatio: pixelRatio);
}

/// The shipped liquid-glass functional surface over a field of narrow
/// vertical stripes, blur tuned to [blur].
Future<_Capture> _captureSurface(
  WidgetTester tester, {
  required double pixelRatio,
  required double blur,
  required String label,
}) async {
  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      surfaceTuning: CoreSurfaceTuning(surfaceBlur: blur),
      // At the root's origin: `toImage` makes the boundary the render target,
      // and the surface reports its rectangle relative to the root, so the two
      // agree only when the boundary starts where the root does.
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: kCaptureWidth,
            height: kCaptureHeight,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _StripesPainter()),
                ),
                Positioned(
                  left: kMargin,
                  top: kMargin,
                  width: kSurfaceWidth,
                  height: kSurfaceHeight,
                  child: const OutlinedContainer(
                    role: CoreSurfaceRole.functional,
                    child: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final capture = await _readBoundary(
    tester,
    boundaryKey,
    pixelRatio: pixelRatio,
  );
  await _writePng(tester, boundaryKey, pixelRatio: pixelRatio, label: label);

  return capture;
}

Future<_Capture> _readBoundary(
  WidgetTester tester,
  GlobalKey boundaryKey, {
  required double pixelRatio,
}) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final result = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final capture = _Capture(
      data!.buffer.asUint8List(),
      image.width,
      image.height,
    );
    image.dispose();

    return capture;
  });

  return result!;
}

Future<void> _writePng(
  WidgetTester tester,
  GlobalKey boundaryKey, {
  required double pixelRatio,
  required String label,
}) async {
  // The macOS runner is sandboxed, so an arbitrary path is refused; the
  // app's own temp directory is always writable and is where to look.
  final dir = kProbeOutputDir.isEmpty
      ? Directory.systemTemp.path
      : kProbeOutputDir;
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('$dir/$label.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      debugPrint('wrote ${file.path}');
    } on Object catch (error) {
      debugPrint('png not written ($label): $error');
    }
  });
}

class _StripesPainter extends CustomPainter {
  const _StripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = const Color(0xFF000000);
    final white = Paint()..color = const Color(0xFFFFFFFF);
    var x = 0.0;
    var dark = true;
    while (x < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, kStripeWidth, size.height),
        dark ? black : white,
      );
      x += kStripeWidth;
      dark = !dark;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
