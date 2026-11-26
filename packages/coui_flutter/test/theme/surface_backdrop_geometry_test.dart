// Pins the one piece of the surface-aware backdrop a widget test can reach:
// how the surface's rectangle is expressed in the backdrop texture's
// pixels. The layer that writes it into the program only runs where a
// scene is built, and the program only runs on Impeller — the picture is
// the device probe's (`refraction_geometry_probe_test.dart`).
library;

import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the surface rectangle in backdrop pixels', () {
    test('is the root-space rectangle scaled by the device pixel ratio', () {
      // A surface 200×100 at (30, 40) in the root, on a 2× device: the
      // backdrop texture is the root at 2×, so the rectangle doubles.
      final rect = surfaceRectInBackdropPixels(
        transform: Matrix4.translationValues(30, 40, 0),
        size: const Size(200, 100),
        devicePixelRatio: 2,
      );

      expect(rect, const Rect.fromLTWH(60, 80, 400, 200));
    });

    test('follows a scaled ancestor rather than the layout size', () {
      // The shader bends around what is on screen. A surface laid out at
      // 200×100 under a 0.5 scale occupies 100×50 of the root, and that is
      // the rectangle the band has to be measured against.
      final transform = Matrix4.translationValues(10, 10, 0)
        ..scaleByDouble(0.5, 0.5, 1, 1);
      final rect = surfaceRectInBackdropPixels(
        transform: transform,
        size: const Size(200, 100),
        devicePixelRatio: 1,
      );

      expect(rect, const Rect.fromLTWH(10, 10, 100, 50));
    });

    test('and the uniform indices leave the engine its two leading floats', () {
      // The engine owns 0 and 1 (`uSize`); a vec2 counts as two floats, so
      // the rectangle's two uniforms sit at 7–8 and 9–10 after the five
      // scalars. The shader's declaration order is pinned separately in
      // `surface_refraction_parity_test.dart`.
      expect(kSurfaceRefractionBezelIndex, 2);
      expect(kSurfaceRefractionDispersionIndex, 6);
      expect(kSurfaceRefractionOriginIndex, 7);
      expect(kSurfaceRefractionExtentIndex, 9);
    });
  });

  group('the widget', () {
    testWidgets('mounts its render object with what the program needs', (
      tester,
    ) async {
      // The scene-time resolve runs here too, but `flutter_tester` cannot
      // run the program, so it answers with the material alone. What can be
      // held is that the widget carries every input the resolve reads,
      // unchanged, into the render object, and that the tree survives a
      // frame without a shader filter.
      final program = await FragmentProgram.fromAsset(
        'shaders/surface_refraction.frag',
      );
      await tester.pumpWidget(
        Center(
          child: SurfaceBackdrop(
            material: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            program: program,
            refraction: const CoreSurfaceRefraction(
              bezel: 0.2,
              dispersion: 0.5,
            ),
            cornerRadius: 12,
            devicePixelRatio: 3,
            child: const SizedBox(width: 80, height: 40),
          ),
        ),
      );

      final render = tester.renderObject<RenderSurfaceBackdrop>(
        find.byType(SurfaceBackdrop),
      );
      final description = render.toStringDeep();

      expect(description, contains('cornerRadius: 12'));
      expect(description, contains('devicePixelRatio: 3'));
      expect(description, contains('bezel: 0.2'));
      expect(render.size, const Size(80, 40));
    });
  });
}
