// The active boundary step (`CoreStrokeWidth.stroke1_5`) is drawn at the
// width the screen gives it. A 1x screen has no half pixel: Chrome draws a
// 1.5 CSS px border there as one whole pixel, so the Web states 1px below a
// 2x screen (`--coui-stroke-width-1_5`) and `CoUIApp` folds the same screen
// into the theme geometry every stroke reads. The test reads the frame an
// unchecked checkbox — the component that draws this step by default —
// actually paints on each screen, through a real app, so a component that
// stopped routing its frame through the geometry would fail here.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

/// An unchecked checkbox inside a real [CoUIApp] on a screen of [ratio].
Future<void> _pumpOn(WidgetTester tester, double ratio) async {
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Center(
        child: Checkbox(checked: false, onChanged: (_) {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The border the checkbox's square paints — its `OutlinedContainer`. The
/// focus ring around it is a separate, wider stroke and is not the frame.
double _paintedFrame(WidgetTester tester) {
  final widths = <double>[];
  for (final element
      in find
          .descendant(
            of: find.descendant(
              of: find.byType(Checkbox),
              matching: find.byType(OutlinedContainer),
            ),
            matching: find.byWidgetPredicate(
              (w) => w is widgets.Container || w is widgets.DecoratedBox,
            ),
          )
          .evaluate()) {
    final decoration = switch (element.widget) {
      widgets.Container(:final decoration) => decoration,
      widgets.DecoratedBox(:final decoration) => decoration,
      _ => null,
    };
    if (decoration is BoxDecoration && decoration.border is Border) {
      widths.add((decoration.border! as Border).top.width);
    }
  }
  // A Container paints through the DecoratedBox it builds, so the one
  // frame can be found twice — it is one width.
  expect(widths.toSet(), hasLength(1), reason: 'the square has one frame');

  return widths.first;
}

void main() {
  group('the frame an unchecked checkbox draws', () {
    testWidgets('is one pixel on a 1x screen', (tester) async {
      await _pumpOn(tester, 1);
      expect(_paintedFrame(tester), CoreStrokeWidth.stroke1);
    });

    testWidgets('is its own 1.5 from a 2x screen up', (tester) async {
      for (final ratio in [2.0, 3.0]) {
        await _pumpOn(tester, ratio);
        expect(
          _paintedFrame(tester),
          CoreStrokeWidth.stroke1_5,
          reason: 'on a ${ratio}x screen',
        );
      }
    });
  });

  group('applySurfaceStyle with a screen ratio', () {
    final base = ThemeData.fromCore(CoreThemePresets.light);

    test('folds the 1x active boundary into the geometry', () {
      final theme = applySurfaceStyle(
        base,
        surfaceStyle: .defaultStyle,
        highContrast: false,
        devicePixelRatio: 1,
      );
      expect(
        theme.geometry.stroke(CoreStrokeWidth.stroke1_5),
        CoreStrokeWidth.stroke1,
      );
    });

    test('without a ratio leaves the active boundary at its own width', () {
      final theme = applySurfaceStyle(
        base,
        surfaceStyle: .defaultStyle,
        highContrast: false,
      );
      expect(
        theme.geometry.stroke(CoreStrokeWidth.stroke1_5),
        CoreStrokeWidth.stroke1_5,
      );
    });

    test('a style floor still lifts the 1x active boundary', () {
      final theme = applySurfaceStyle(
        base,
        surfaceStyle: .neoBrutalism,
        highContrast: false,
        devicePixelRatio: 1,
      );
      final floor = CoreSurfaceRecipe.of(.neoBrutalism).geometry.strokeFloor;
      expect(floor, isNotNull);
      expect(theme.geometry.stroke(CoreStrokeWidth.stroke1_5), floor);
    });
  });
}
