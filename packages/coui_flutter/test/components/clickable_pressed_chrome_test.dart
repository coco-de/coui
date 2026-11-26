import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _shift = CoreOffset(4, 4);
const _hard = [
  (
    offsetX: 0.0,
    offsetY: 2.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

Future<ResolvedClickable> _resolve(
  WidgetTester tester,
  CoreClickableStyle? style, {
  ThemeData? theme,
}) async {
  late ResolvedClickable seen;

  await tester.pumpWidget(
    CoUIApp(
      theme: theme ?? ThemeData.fromCore(CoreThemePresets.light),
      home: Builder(
        builder: (context) {
          seen = resolveClickable(context, clickableStyle: style);

          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return seen;
}

void main() {
  group('a style that says nothing about pressing changes nothing', () {
    testWidgets('no shift, no shadow', (tester) async {
      final resolved = await _resolve(tester, null);

      expect(resolved.pressedTranslate, Offset.zero);
      expect(resolved.pressedBoxShadow, isNull);
    });
  });

  group('a stated press reaches the widget', () {
    testWidgets('the shift arrives in logical pixels', (tester) async {
      // Pixels, not a fraction of the control — a press travels a fixed
      // distance whatever the control's size, which is why the widget
      // uses a matrix rather than a slide.
      final resolved = await _resolve(
        tester,
        const CoreClickableStyle(pressedTranslate: _shift),
      );

      expect(resolved.pressedTranslate.dx, greaterThan(0));
      expect(resolved.pressedTranslate.dy, greaterThan(0));
    });

    testWidgets('the shift scales with platform density', (tester) async {
      // Every other dimensional value does; a press distance that stayed
      // fixed while the control around it grew would drift out of
      // proportion on a denser platform. Read against the theme's own
      // factor rather than a forced one — the app derives it from the
      // platform, so a copyWith here would be overwritten and the test
      // would pass on a value nothing produced.
      late double factor;
      late ResolvedClickable seen;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Builder(
            builder: (context) {
              factor = Theme.of(context).scaling;
              seen = resolveClickable(
                context,
                clickableStyle: const CoreClickableStyle(
                  pressedTranslate: _shift,
                ),
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(factor, greaterThan(0));
      expect(seen.pressedTranslate.dx, _shift.dx * factor);
      expect(seen.pressedTranslate.dy, _shift.dy * factor);
    });

    testWidgets('the shadow resolves to a paint-ready stack', (tester) async {
      final resolved = await _resolve(
        tester,
        const CoreClickableStyle(pressedBoxShadow: _hard),
      );

      expect(resolved.pressedBoxShadow, hasLength(_hard.length));
      expect(resolved.pressedBoxShadow!.first.blurRadius, 0);
    });
  });

  group('the active surface style has its say', () {
    testWidgets('a style that flattens shadows flattens this one too', (
      tester,
    ) async {
      // A press under a preset that states hard shadows must not quietly
      // keep a soft one — the pressed stack goes through the same
      // geometry constraint as a resting stack.
      const soft = [
        (
          offsetX: 0.0,
          offsetY: 2.0,
          blurRadius: 8.0,
          spreadRadius: 0.0,
          opacity: 0.4,
          inset: false,
        ),
      ];

      late ResolvedClickable seen;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: Builder(
            builder: (context) {
              seen = resolveClickable(
                context,
                clickableStyle: const CoreClickableStyle(
                  pressedBoxShadow: soft,
                ),
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen.pressedBoxShadow!.first.blurRadius, 0);
    });
  });
}
