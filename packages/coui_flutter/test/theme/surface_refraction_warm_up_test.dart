// Pins what this harness can see of the warm-up: that the program is
// asked for once, kept, and asked for at the right moment.
//
// It cannot see the frame that benefits. `ImageFilter.shader` is a hard
// throw under `flutter_tester`, so the surface never reaches the branch
// that reads the held program here — the frame-one measurement is the
// device probe (`refraction_first_frame_probe_test.dart` and its warmed
// twin), where the mid-frame mount is captured before and after the holder.
library;

import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The key the package's own test bundle files the shader under.
///
/// A consuming app reaches it as `packages/coui_flutter/shaders/…`, which is
/// what the holder asks for; `flutter_tester` running inside the package
/// has no `packages/` prefix for the package's own assets and answers "not
/// found" to that key. The injected loader reads the local key and checks
/// the holder asked for the shipped one.
const _kLocalShaderAsset = 'shaders/surface_refraction.frag';

void main() {
  var loads = 0;

  setUp(() {
    SurfaceRefractionProgram.debugReset();
    loads = 0;
    SurfaceRefractionProgram.debugIsShaderFilterSupported = () => true;
    SurfaceRefractionProgram.debugLoad = (asset) {
      loads++;
      expect(asset, kSurfaceRefractionShaderAsset);

      return FragmentProgram.fromAsset(_kLocalShaderAsset);
    };
  });

  tearDown(() {
    SurfaceRefractionProgram.debugReset();
    SurfaceRefractionProgram.debugLoad = FragmentProgram.fromAsset;
    SurfaceRefractionProgram.debugIsShaderFilterSupported = () =>
        ImageFilter.isShaderFilterSupported;
  });

  group('the program is held once for the process', () {
    test('an engine without shader filters is never asked', () async {
      // The asset would load fine; it is the filter that cannot run. Asking
      // anyway would spend the I/O on every platform that can do nothing
      // with the answer — Flutter Web among them.
      SurfaceRefractionProgram.debugIsShaderFilterSupported = () => false;

      expect(await SurfaceRefractionProgram.warmUp(), isNull);
      expect(loads, 0);
      expect(SurfaceRefractionProgram.loaded, isNull);
    });

    test(
      'the first ask loads it and every later ask shares the result',
      () async {
        // Two asks in flight and a third after — the shape of an app root
        // warming up while its first surfaces mount. One load serves all.
        final first = SurfaceRefractionProgram.warmUp();
        final second = SurfaceRefractionProgram.warmUp();
        final programs = await Future.wait([first, second]);
        final third = await SurfaceRefractionProgram.warmUp();

        expect(loads, 1);
        expect(programs[0], isNotNull);
        expect(programs[1], same(programs[0]));
        expect(third, same(programs[0]));
        expect(SurfaceRefractionProgram.loaded, same(programs[0]));
      },
    );

    test('a load that fails is remembered rather than retried', () async {
      // A missing asset would otherwise be requested on every rebuild of
      // every surface — a loop that never succeeds and never stops.
      SurfaceRefractionProgram.debugLoad = (asset) {
        loads++;

        throw StateError('no such asset');
      };

      expect(await SurfaceRefractionProgram.warmUp(), isNull);
      expect(await SurfaceRefractionProgram.warmUp(), isNull);
      expect(loads, 1);
      expect(SurfaceRefractionProgram.loaded, isNull);
    });
  });

  group('the app root asks the moment the style bends', () {
    testWidgets('component material warms before a navigation surface mounts', (
      tester,
    ) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(
            CoreThemePresets.light,
            coreComponentTheme: const CoreComponentTheme(
              appBar: CoreAppBarTheme(
                style: CoreAppBarStyle(surfaceStyle: .liquidGlass),
              ),
            ),
          ),
          home: const SizedBox(),
        ),
      );
      await tester.pump();
      expect(loads, 1);
      expect(SurfaceRefractionProgram.loaded, isNotNull);
    });

    Widget app(CoreSurfaceStyleId style) => CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      // No surface in the tree on purpose: the point is that the *root*
      // asks, before any surface exists to ask for itself.
      home: const SizedBox(),
    );

    testWidgets('a style that states a bend is warmed at mount', (
      tester,
    ) async {
      await tester.pumpWidget(app(CoreSurfaceStyleId.liquidGlass));
      await tester.pump();

      expect(loads, 1);
      expect(SurfaceRefractionProgram.loaded, isNotNull);
    });

    testWidgets('a style that bends nothing asks for nothing', (tester) async {
      await tester.pumpWidget(app(CoreSurfaceStyleId.defaultId));
      await tester.pump();

      expect(loads, 0);
    });

    testWidgets('and switching to a bending style asks then', (tester) async {
      // The style can change at runtime; the warm-up follows it rather than
      // living only in the first mount.
      await tester.pumpWidget(app(CoreSurfaceStyleId.defaultId));
      await tester.pump();
      expect(loads, 0);

      await tester.pumpWidget(app(CoreSurfaceStyleId.liquidGlass));
      await tester.pump();

      expect(loads, 1);
    });
  });
}
