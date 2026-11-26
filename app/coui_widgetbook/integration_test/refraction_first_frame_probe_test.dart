// Whether the frame a glass surface mounts in already bends — the case
// the app-root warm-up and the shared program holder exist for.
//
//   C1  The app is up (one frame painted, no glass on it yet) and a glass
//       surface mounts on the next frame — a route push, a card scrolling
//       in. The difference between that frame and the settled frame is the
//       flash. Nothing here asks for the program by name, so the same file
//       builds against the tree from before the holder existed and reads
//       the flash there too; that is how "before" was recorded.
//
// The surface has to mount *inside* a frame for the question to be real.
// A surface in the very first `pumpWidget` is built synchronously before
// any frame is scheduled, the load's continuation runs in the microtask
// after that build, and the first painted frame already has the program —
// which is also what `runApp` does, so an app's first screen was never
// where the flash lived. `refraction_first_frame_warmed_probe_test` asks
// the warmed version of the same question.
//
// Run as:
//
//   flutter test integration_test/refraction_first_frame_probe_test.dart \
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

  testWidgets('C1 — a surface mounting mid-frame, first frame vs settled', (
    tester,
  ) async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      debugPrint('C1  device=$kProbeDeviceId  not run: no shader filters');
      return;
    }
    final dpr = tester.view.devicePixelRatio;
    final first = await _captureSurface(tester, pixelRatio: dpr, settle: false);
    final settled = await _captureSurface(
      tester,
      pixelRatio: dpr,
      settle: true,
    );
    final moved = _differingFraction(first, settled);

    debugPrint(
      'C1  device=$kProbeDeviceId  dpr=$dpr'
      '  midFrameMountFirstVsSettled=${moved.toStringAsFixed(4)}'
      '  (0 = the surface bent on the frame it mounted)',
    );
    // The number is the finding: on the tree before the holder it is the
    // flash, on the tree with it (where `CoUIApp` warms the program up at
    // its own mount) it is zero. Neither is asserted, so the file reads the
    // same on both.
  });
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
