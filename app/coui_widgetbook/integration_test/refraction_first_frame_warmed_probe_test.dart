// The warmed half of `refraction_first_frame_probe_test.dart`: the same
// mid-frame mount, after the process has been asked to hold the program.
//
//   C2  `SurfaceRefractionProgram.warmUp()` was awaited first — what an app
//       does in `main()` ahead of `runApp`, and what `CoUIApp` does on its
//       own for every surface that mounts after its first frame. The
//       surface should bend on the frame it mounts.
//
// Separate file because this one names the holder, and the cold file is
// kept free of it so it builds against the tree from before the holder
// existed — that is how the flash it measures was recorded.
//
// Run as:
//
//   flutter test integration_test/refraction_first_frame_warmed_probe_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

const kSurfaceWidth = 200.0;
const kSurfaceHeight = 100.0;
const kMargin = 20.0;
const kCaptureWidth = kSurfaceWidth + kMargin * 2;
const kCaptureHeight = kSurfaceHeight + kMargin * 2;
const kStripeWidth = 4.0;
const kBytesPerPixel = 4;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(
      kProbeDeviceId,
      isNotEmpty,
      reason: 'Pass --dart-define=PROBE_DEVICE_ID',
    );
  });

  testWidgets(
    'C2 — warmed: a surface mounting mid-frame, first frame vs settled',
    (
      tester,
    ) async {
      if (!ui.ImageFilter.isShaderFilterSupported) {
        debugPrint('C2  device=$kProbeDeviceId  not run: no shader filters');
        return;
      }
      final program = await tester.runAsync(SurfaceRefractionProgram.warmUp);
      expect(
        program,
        isNotNull,
        reason: 'the warm-up did not deliver a program',
      );

      final dpr = tester.view.devicePixelRatio;
      final first = await _captureSurface(
        tester,
        pixelRatio: dpr,
        settle: false,
      );
      final settled = await _captureSurface(
        tester,
        pixelRatio: dpr,
        settle: true,
      );
      final moved = _differingFraction(first, settled);

      debugPrint(
        'C2  device=$kProbeDeviceId  dpr=$dpr'
        '  warmedMidFrameMountFirstVsSettled=${moved.toStringAsFixed(4)}'
        '  (0 = the surface bent on the frame it mounted)',
      );
      expect(
        moved,
        0,
        reason: 'a warmed surface still painted a flat first frame',
      );
    },
  );
}

Future<Uint8List> _captureSurface(
  WidgetTester tester, {
  required double pixelRatio,
  required bool settle,
}) async {
  final boundaryKey = GlobalKey();
  Widget app({required bool withSurface}) => CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    surfaceStyle: CoreSurfaceStyleId.liquidGlass,
    surfaceTuning: const CoreSurfaceTuning(surfaceBlur: 0.1),
    // At the root's origin — see `refraction_geometry_probe_test.dart`.
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
              if (withSurface)
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
  );

  await tester.pumpWidget(app(withSurface: false));
  await tester.pumpAndSettle();
  await tester.pumpWidget(app(withSurface: true));
  if (settle) await tester.pumpAndSettle();

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    return data!.buffer.asUint8List();
  });

  return bytes!;
}

double _differingFraction(Uint8List a, Uint8List b) {
  if (a.length != b.length) return 1;
  final total = a.length ~/ kBytesPerPixel;
  var differing = 0;
  for (var at = 0; at < a.length; at += kBytesPerPixel) {
    for (var channel = 0; channel < kBytesPerPixel; channel++) {
      if (a[at + channel] != b[at + channel]) {
        differing++;
        break;
      }
    }
  }

  return differing / total;
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
