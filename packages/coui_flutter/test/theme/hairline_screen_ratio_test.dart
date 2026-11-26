// The hairline step (`CoreStrokeWidth.stroke0_5`) is drawn at the width the
// screen gives it. Below a 2x screen half a logical pixel is a sub-pixel
// line, fainter than the colour it is drawn in, so the design draws one
// pixel there — the Web reads the screen in a media query on
// `--coui-stroke-width-0_5`. `CoUIApp` folds the screen's ratio into the
// theme geometry every stroke reads, so the test reads what a Kbd cap — the
// component that draws the hairline by default — actually lays out and
// paints on each screen.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

/// A one-key Kbd inside a real [CoUIApp] on a screen of [ratio].
Future<void> _pumpOn(WidgetTester tester, double ratio) async {
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Center(child: Kbd.single(keyText: 'K')),
    ),
  );
  await tester.pumpAndSettle();
}

/// The width of the border the cap paints.
double _paintedBorder(WidgetTester tester) {
  final cap = tester.widget<widgets.Container>(
    find
        .descendant(
          of: find.byType(Kbd),
          matching: find.byType(widgets.Container),
        )
        .first,
  );

  return ((cap.decoration! as BoxDecoration).border! as Border).top.width;
}

/// The cap's laid-out box.
Size _cap(WidgetTester tester) =>
    tester.getSize(find.byType(InjectedCast).first);

void main() {
  group('the hairline a Kbd cap draws', () {
    testWidgets('is one pixel on a 1x screen', (tester) async {
      await _pumpOn(tester, 1);
      expect(_paintedBorder(tester), CoreStrokeWidth.stroke1);
    });

    testWidgets('is its own half pixel from a 2x screen up', (tester) async {
      for (final ratio in [2.0, 3.0]) {
        await _pumpOn(tester, ratio);
        expect(
          _paintedBorder(tester),
          CoreStrokeWidth.stroke0_5,
          reason: 'on a ${ratio}x screen',
        );
      }
    });

    // The border grows the cap around its interior, so the wider line on
    // a 1x screen is a cap one pixel wider and taller — the size the Web
    // cap lays out at on the same screen.
    testWidgets('grows the cap by the wider line on a 1x screen', (
      tester,
    ) async {
      await _pumpOn(tester, 3);
      final dense = _cap(tester);
      await _pumpOn(tester, 1);
      final oneX = _cap(tester);
      expect(oneX.width - dense.width, 1);
      expect(oneX.height - dense.height, 1);
    });
  });

  group('applySurfaceStyle with a screen ratio', () {
    final base = ThemeData.fromCore(CoreThemePresets.light);

    test('folds the 1x hairline into the geometry', () {
      final theme = applySurfaceStyle(
        base,
        surfaceStyle: .defaultStyle,
        highContrast: false,
        devicePixelRatio: 1,
      );
      expect(
        theme.geometry.stroke(CoreStrokeWidth.stroke0_5),
        CoreStrokeWidth.stroke1,
      );
    });

    // A harness that calls the fold directly and states no screen keeps
    // the step's own width, as before the screen was folded in.
    test('without a ratio leaves the hairline at its own width', () {
      final theme = applySurfaceStyle(
        base,
        surfaceStyle: .defaultStyle,
        highContrast: false,
      );
      expect(
        theme.geometry.stroke(CoreStrokeWidth.stroke0_5),
        CoreStrokeWidth.stroke0_5,
      );
    });

    test('a style floor still lifts the 1x hairline', () {
      final theme = applySurfaceStyle(
        base,
        surfaceStyle: .neoBrutalism,
        highContrast: false,
        devicePixelRatio: 1,
      );
      final floor = CoreSurfaceRecipe.of(.neoBrutalism).geometry.strokeFloor;
      expect(floor, isNotNull);
      expect(theme.geometry.stroke(CoreStrokeWidth.stroke0_5), floor);
    });
  });
}
