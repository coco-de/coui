// The coordinate space an `ImageFilter.shader` program runs in, and which
// float index reaches which declared uniform — the two facts the shipped
// refraction shader stands on.
//
//   S1  `uSize` and `FlutterFragCoord()` read back as colour at a known pixel
//       of a 200×100 panel placed at (20,20) inside a 240×140 capture. If
//       they were the panel's, the size would read ≈ 400 at 2× and the
//       fragment ≈ its panel-local position; they read the capture's — the
//       whole render target — composed with a blur or bare, clipped or not,
//       under an `Opacity` or not. That is why the shipped shader is handed
//       the surface's rectangle as uniforms instead of deriving it.
//   S2  With the shipped shader's declaration shape (a vec2, five floats, a
//       sampler), `setFloat(3..5)` land in the third, fourth and fifth
//       floats — declaration order, a vec2 counting as two. Measured because
//       a wrong mapping would have explained the same symptom.
//
// Encoded through 8-bit channels at /2048, so every value carries ±8 px.
//
// Run as:
//
//   flutter test integration_test/refraction_coordinate_space_probe_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos
library;

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('S1 — where the program thinks it is', (tester) async {
    final program = await tester.runAsync(
      () => ui.FragmentProgram.fromAsset('shaders/probe_coords.frag'),
    );
    final dpr = tester.view.devicePixelRatio;
    for (final composed in [false, true]) {
      for (final clip in [false, true]) {
        if (composed != clip) continue; // two cases are enough here
        final shader = program!.fragmentShader();
        final filter = composed
            ? ui.ImageFilter.compose(
                outer: ui.ImageFilter.shader(shader),
                inner: ui.ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
              )
            : ui.ImageFilter.shader(shader);
        final key = GlobalKey();
        Widget backdrop = BackdropFilter(
          filter: filter,
          child: const SizedBox.expand(),
        );
        backdrop = clip
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: backdrop,
              )
            : ClipRect(child: backdrop);
        for (final wrap in ['none', 'opacity-on-panel', 'opacity-on-stack']) {
          final panel = wrap == 'opacity-on-panel'
              ? Opacity(opacity: 0.99, child: backdrop)
              : backdrop;
          Widget stack = Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFF808080)),
              ),
              Positioned(
                left: 20,
                top: 20,
                width: 200,
                height: 100,
                child: panel,
              ),
            ],
          );
          if (wrap == 'opacity-on-stack')
            stack = Opacity(opacity: 0.99, child: stack);
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(width: 240, height: 140, child: stack),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final bytes = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: dpr);
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            return data!.buffer.asUint8List();
          });
          final w = (240 * dpr).round();
          // Panel-local (30, 30) logical → capture (50, 50) logical.
          final x = (50 * dpr).round(), y = (50 * dpr).round();
          final at = (y * w + x) * 4;
          final px = bytes!.sublist(at, at + 4);
          debugPrint(
            'S1  device=$kProbeDeviceId composed=$composed clip=$clip wrap=$wrap  at capture($x,$y)=panel(${x - (20 * dpr).round()},${y - (20 * dpr).round()})'
            '  uSize.x≈${(px[0] / 255 * 2048).round()}  frag≈(${(px[1] / 255 * 2048).round()},${(px[2] / 255 * 2048).round()})  (±8, 8-bit encoding)',
          );
        }
      }
    }
  });

  testWidgets('S2 — which float index reaches which uniform', (tester) async {
    final program = await tester.runAsync(
      () => ui.FragmentProgram.fromAsset('shaders/probe_uniforms5.frag'),
    );
    final shader = program!.fragmentShader()
      ..setFloat(2, 0.1)
      ..setFloat(3, 0.2)
      ..setFloat(4, 0.3)
      ..setFloat(5, 0.4)
      ..setFloat(6, 0.5);
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFF00FF00)),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.shader(shader),
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
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return data!.buffer.asUint8List();
    });
    final at = ((25 * 50) + 25) * 4;
    debugPrint(
      'S2  device=$kProbeDeviceId pixel(25,25) rgba=${bytes!.sublist(at, at + 4)}  expected ~[51,77,102,255] if index 3→uB 4→uC 5→uD',
    );
  });
}
