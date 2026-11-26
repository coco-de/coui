import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the path this harness can actually see.
///
/// `ImageFilter.isShaderFilterSupported` answers `false` under
/// `flutter_tester` no matter what the platform can do — it reports whether
/// Impeller is on, and the test binding renders with Skia. So a widget test
/// that asserted the *supported* path would be asserting nothing: it would
/// pass by never reaching the branch.
///
/// What it can hold, and what these tests hold, is the fallback — which is
/// the path most surfaces are on and the one whose failure is silent.
Future<Widget> _surface(
  WidgetTester tester, {
  CoreSurfaceRefraction? refraction,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      // functional: the role liquidGlass actually treats. The default
      // role (content) draws flat under this preset and mounts no
      // `SurfaceBlur` at all (#4424).
      home: OutlinedContainer(
        role: CoreSurfaceRole.functional,
        refraction: refraction,
        child: const SizedBox(width: 80, height: 40),
      ),
    ),
  );

  return tester.widget(find.byType(OutlinedContainer));
}

/// The sigma the surface actually draws with, read off the live filter.
double _drawnSigma(WidgetTester tester) {
  final backdrop = tester.widget<BackdropFilter>(
    find.descendant(
      of: find.byType(SurfaceBlur),
      matching: find.byType(BackdropFilter),
    ),
  );
  final described = backdrop.filter.toString();
  final match = RegExp(r'([0-9]+\.?[0-9]*)').firstMatch(described);

  return double.parse(match!.group(1)!);
}

void main() {
  group('a surface that asked for bending and could not have it', () {
    testWidgets('still draws the rest of its material', (tester) async {
      // The failure this catches is losing the whole material because one
      // layer was unavailable, which is worse than the layer's absence.
      await _surface(
        tester,
        refraction: const CoreSurfaceRefraction(bezel: 0.2),
      );

      expect(find.byType(SurfaceBlur), findsOneWidget);
      final blur = tester.widget<SurfaceBlur>(find.byType(SurfaceBlur));

      expect(blur.surfaceBlur, isNotNull);
      expect(blur.surfaceBlur, greaterThan(0));
      expect(blur.surfaceSheen, isNotNull);
      expect(blur.surfaceSaturation, isNotNull);
    });

    testWidgets('and never reaches the shader constructor', (tester) async {
      // On Flutter Web that constructor is an unconditional throw, so a
      // path that reached it would not render differently — it would crash.
      // Here the same gate keeps this harness off it, which is why this
      // renders at all.
      await _surface(
        tester,
        refraction: const CoreSurfaceRefraction(bezel: 0.2),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the correction reaches the blur it corrects', (tester) async {
      // The field most likely to die: it defaults to zero, so every other
      // scenario here passes whether or not anything reads it. This one
      // fails if nothing does.
      await _surface(
        tester,
        refraction: const CoreSurfaceRefraction(bezel: 0.2),
      );
      final withoutCorrection = _drawnSigma(tester);

      await _surface(
        tester,
        refraction: const CoreSurfaceRefraction(bezel: 0.2, fallbackBlurAdd: 8),
      );
      final withCorrection = _drawnSigma(tester);

      expect(withCorrection, withoutCorrection + 8);
    });

    testWidgets('and a request with no correction moves nothing', (
      tester,
    ) async {
      // The correction is what moves the sigma, not the request. Two
      // requests that differ only in their correction are the sharpest
      // way to say that — and they are also how the test below tells an
      // inherited request from a stated one.
      await _surface(
        tester,
        refraction: const CoreSurfaceRefraction(bezel: 0.2),
      );
      final noCorrection = _drawnSigma(tester);

      await _surface(
        tester,
        refraction: const CoreSurfaceRefraction(bezel: 0.4),
      );
      final widerBezel = _drawnSigma(tester);

      expect(noCorrection, widerBezel);
    });
  });

  group('the request is stated once and consumed by the surface', () {
    testWidgets('a caller may state it, and the style slot stays clear', (
      tester,
    ) async {
      // Chrome and material are still different things: the request never
      // travels through `containerStyle`, so a caller reading that slot
      // learns nothing about bending and cannot set it there.
      final widget =
          await _surface(
                tester,
                refraction: const CoreSurfaceRefraction(bezel: 0.2),
              )
              as OutlinedContainer;

      expect(widget.refraction, isNotNull);
      expect(widget.containerStyle, isNull);
    });

    testWidgets('and the material supplies one to a surface that does not', (
      tester,
    ) async {
      // **The assertion that fails if the axis wiring is declared but
      // inert** — which is the state this file was rewritten out of.
      // Nothing in the kit passed a refraction to anything, so the glass
      // preset had every term of its material except the one it is named
      // for, on both platforms, with the implementation present.
      //
      // Told apart by the correction, not by a style switch: the shipped
      // request states a fallback blur and the stated one here does not,
      // so on an engine without shader filters the inherited request is
      // the one that shows up as extra sigma. Reading the difference keeps
      // this about *whether the request arrived*.
      await _surface(
        tester,
        refraction: const CoreSurfaceRefraction(bezel: 0.2),
      );
      final stated = _drawnSigma(tester);

      await _surface(tester);
      final inherited = _drawnSigma(tester);

      expect(
        inherited,
        greaterThan(stated),
        reason: 'the material never reached a surface that asked for none',
      );
      expect(
        inherited - stated,
        CoreSurfaceRecipe.of(
          CoreSurfaceStyleId.liquidGlass,
        ).refraction!.fallbackBlurAdd,
        reason: 'the arriving request was not the one the preset states',
      );
    });
  });
}
