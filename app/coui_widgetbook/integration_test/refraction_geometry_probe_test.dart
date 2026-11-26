// Whether the bend follows the surface or the backdrop.
//
// An `ImageFilter.shader` program is handed the whole backdrop snapshot —
// `uSize` and `FlutterFragCoord()` describe the render target, not the
// surface — so a shader that measures its band against `uSize` bends the
// *window's* rim. A glass panel hugging the screen's edge then shows the
// window's band through its own edge and looks right; one anywhere else
// does not bend at all. Measured on Impeller before the fix: zero dispersed
// pixels inside a centred panel's band, 2720 inside an edge-hugging one.
//
//   G1  The shipped functional glass surface, once centred in a large
//       backdrop and once at its left edge. A bend that follows the surface
//       colours both bands; one that follows the backdrop colours only the
//       edge. The two counts are asserted to agree within a tolerance.
//
// The capture boundary sits at the root's origin on purpose: `toImage`
// makes the boundary the render target, and the surface reports its
// rectangle relative to the root, so the two coordinate spaces agree only
// when the boundary starts where the root does.
//
// Run as:
//
//   flutter test integration_test/refraction_geometry_probe_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos
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

const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    expect(
      kProbeDeviceId,
      isNotEmpty,
      reason: 'Pass --dart-define=PROBE_DEVICE_ID',
    );
  });

  testWidgets('G1 — the bend follows the surface, centred or at the edge', (
    tester,
  ) async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      debugPrint('G1  device=$kProbeDeviceId  not run: no shader filters');
      return;
    }
    final dpr = tester.view.devicePixelRatio;
    Future<Uint8List> capture(String label, double left, double top) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          surfaceTuning: const CoreSurfaceTuning(surfaceBlur: 0.1),
          home: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 600,
                height: 400,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _Stripes()),
                    ),
                    Positioned(
                      left: left,
                      top: top,
                      width: 200,
                      height: 100,
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
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: dpr);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${Directory.systemTemp.path}/center-$label.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        return data!.buffer.asUint8List();
      });
      return bytes!;
    }

    // Colourful (dispersed) pixels inside the panel's left band: any pixel whose channels disagree.
    int coloured(Uint8List b, double left, double top) {
      final w = (600 * dpr).round();
      var n = 0;
      for (
        var y = ((top + 30) * dpr).round();
        y < ((top + 70) * dpr).round();
        y++
      ) {
        for (
          var x = ((left + 2) * dpr).round();
          x < ((left + 24) * dpr).round();
          x++
        ) {
          final at = (y * w + x) * 4;
          final r = b[at], g = b[at + 1], bl = b[at + 2];
          if ((r - g).abs() > 24 || (g - bl).abs() > 24) n++;
        }
      }
      return n;
    }

    final centre = await capture('centre', 200, 150);
    final edge = await capture('edge', 20, 150);
    final atCentre = coloured(centre, 200, 150);
    final atEdge = coloured(edge, 20, 150);
    debugPrint(
      'G1  device=$kProbeDeviceId  colouredPixelsInLeftBand: centre=$atCentre  edge=$atEdge'
      '  (a bend that follows the surface gives both; one that follows the backdrop gives only edge)',
    );
    expect(
      atEdge,
      greaterThan(0),
      reason: 'no bend at all — the harness is not showing refraction',
    );
    expect(
      atCentre,
      greaterThan(atEdge ~/ 2),
      reason:
          'the centred surface barely bends: the shader is measuring the backdrop, not the surface',
    );
  });
}

class _Stripes extends CustomPainter {
  const _Stripes();
  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = const Color(0xFF000000);
    final white = Paint()..color = const Color(0xFFFFFFFF);
    var x = 0.0;
    var dark = true;
    while (x < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 4, size.height),
        dark ? black : white,
      );
      x += 4;
      dark = !dark;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
