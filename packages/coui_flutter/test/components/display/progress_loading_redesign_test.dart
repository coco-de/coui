import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_test/flutter_test.dart';

mat.Widget _app(mat.Widget child) => mat.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: mat.Center(child: child),
  ),
);

Future<ResolvedLoading> _resolve(
  WidgetTester tester, {
  CoreLoadingTone tone = CoreLoadingTone.defaultTone,
  CoreLoadingVariant variant = CoreLoadingVariant.spinner,
  CoreComponentSize? size,
  CoreLoadingStyle? style,
}) async {
  late ResolvedLoading resolved;
  await tester.pumpWidget(
    _app(
      mat.Builder(
        builder: (context) {
          resolved = resolveLoading(
            context,
            variant: variant,
            tone: tone,
            componentSize: size,
            loadingStyle: style,
          );
          return const mat.SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

Future<mat.Color> _ink(WidgetTester tester, CoreColor token) async {
  late mat.Color color;
  await tester.pumpWidget(
    _app(
      mat.Builder(
        builder: (context) {
          color = Theme.of(context).colorScheme.resolve(token).toValue();
          return const mat.SizedBox.shrink();
        },
      ),
    ),
  );
  return color;
}

void main() {
  group('RadialProgress size × tone', () {
    for (final entry in const {
      CoreProgressSize.sm: 32.0,
      CoreProgressSize.md: 48.0,
      CoreProgressSize.lg: 80.0,
      CoreProgressSize.xl: 128.0,
    }.entries) {
      testWidgets('${entry.key.name} is ${entry.value} wide', (tester) async {
        await tester.pumpWidget(
          _app(RadialProgress(value: 50, size: entry.key)),
        );
        expect(
          tester.getSize(find.byType(RadialProgress)),
          mat.Size.square(entry.value),
        );
      });
    }

    testWidgets('the resting ring is lg', (tester) async {
      await tester.pumpWidget(_app(const RadialProgress(value: 50)));
      expect(
        tester.getSize(find.byType(RadialProgress)),
        const mat.Size.square(80),
      );
    });

    testWidgets('sm draws no figure, md and up do', (tester) async {
      await tester.pumpWidget(
        _app(
          const RadialProgress(
            value: 50,
            showValueText: true,
            size: CoreProgressSize.sm,
          ),
        ),
      );
      expect(find.text('50%'), findsNothing);
      for (final size in [
        CoreProgressSize.md,
        CoreProgressSize.lg,
        CoreProgressSize.xl,
      ]) {
        await tester.pumpWidget(
          _app(RadialProgress(value: 50, showValueText: true, size: size)),
        );
        expect(find.text('50%'), findsOneWidget, reason: size.name);
      }
    });

    testWidgets('the figure grows with the ring', (tester) async {
      final heights = <double>[];
      for (final size in [
        CoreProgressSize.md,
        CoreProgressSize.lg,
        CoreProgressSize.xl,
      ]) {
        await tester.pumpWidget(
          _app(RadialProgress(value: 50, showValueText: true, size: size)),
        );
        heights.add(tester.getSize(find.text('50%')).height);
      }
      expect(heights[0], lessThan(heights[1]));
      expect(heights[1], lessThan(heights[2]));
    });

    testWidgets('a tone resolves its own arc colour', (tester) async {
      final primary = await _ink(
        tester,
        const CoreColor.token(CoreColors.primary),
      );
      final success = await _ink(
        tester,
        const CoreColor.token(CoreColors.success),
      );
      expect(primary, isNot(success));
    });
  });

  group('Progress value label', () {
    testWidgets('the figure sits at the end of a cell sized for 100%', (
      tester,
    ) async {
      Future<double> right(String text) async {
        await tester.pumpWidget(
          _app(
            mat.SizedBox(
              width: 240,
              child: Progress(value: 0.5, valueLabel: Text(text)),
            ),
          ),
        );
        // The invisible reserve is built first, the shown figure last.
        return tester.getRect(find.text(text).last).right;
      }

      final nine = await right('9%');
      final full = await right('100%');
      expect(nine, full);
    });

    testWidgets('the reserved cell is as wide as 100%', (tester) async {
      await tester.pumpWidget(
        _app(
          const mat.SizedBox(
            width: 240,
            child: Progress(value: 0.5, valueLabel: Text('9%')),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(Progress));
      final nine = tester.getRect(find.text('9%'));
      // '9%' hugs the end, so its left edge is well inside a '100%'-wide cell.
      expect(bar.right - nine.left, lessThan(60));
      expect(nine.right, bar.right);
    });
  });

  group('Loading tone and ring', () {
    testWidgets('primary is the default tone and reads the accent', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      expect(
        resolved.color,
        await _ink(tester, CoreLoadingStyle.defaultColor),
      );
    });

    testWidgets('neutral and inverse read their own ink', (tester) async {
      final neutral = await _resolve(tester, tone: CoreLoadingTone.neutral);
      expect(
        neutral.color,
        await _ink(tester, const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
      final inverse = await _resolve(tester, tone: CoreLoadingTone.inverse);
      expect(
        inverse.color,
        await _ink(tester, const CoreColor.token(CoreColors.onPrimary)),
      );
    });

    testWidgets('the track is a neutral surface, or the ink faded on inverse', (
      tester,
    ) async {
      final primary = await _resolve(tester);
      expect(
        primary.trackColor,
        await _ink(
          tester,
          const CoreColor.token(CoreColors.surfaceContainerHigh),
        ),
      );
      final inverse = await _resolve(tester, tone: CoreLoadingTone.inverse);
      expect(inverse.trackColor.a, closeTo(0.25 * inverse.color.a, 0.01));
    });

    testWidgets('the arc is a quarter turn', (tester) async {
      final resolved = await _resolve(tester);
      expect(resolved.arcSweep, closeTo(3.14159265 / 2, 1e-6));
    });

    testWidgets('the ring thickens with the size', (tester) async {
      final widths = <double>[];
      for (final size in CoreComponentSize.values) {
        widths.add((await _resolve(tester, size: size)).strokeWidth);
      }
      expect(widths, [2, 2, 2, 3, 3, 4]);
    });

    testWidgets('a stated stroke still wins over the size', (tester) async {
      final resolved = await _resolve(
        tester,
        size: CoreComponentSize.xl2,
        style: const CoreLoadingStyle(strokeWidth: 1),
      );
      expect(resolved.strokeWidth, 1);
    });
  });

  group('Loading shapes', () {
    testWidgets('dots grow with the size: 4 · 4 · 6 · 8 · 10 · 12', (
      tester,
    ) async {
      final dots = <double>[];
      for (final size in CoreComponentSize.values) {
        dots.add(
          (await _resolve(
            tester,
            variant: CoreLoadingVariant.dots,
            size: size,
          )).dotSize,
        );
      }
      expect(dots, [4, 4, 6, 8, 10, 12]);
    });

    testWidgets('the bar is twice the size long, its thickness a stroke step', (
      tester,
    ) async {
      final md = await _resolve(
        tester,
        variant: CoreLoadingVariant.bar,
        size: CoreComponentSize.md,
      );
      final side = (await _resolve(tester, size: CoreComponentSize.md)).size;
      expect(md.barLength, side * 2);
      expect(md.barHeight, CoreStrokeWidth.stroke4);
      expect(md.barFillRatio, 0.35);
    });

    testWidgets('the pulse is a faint halo around a dot 0.4 of the size', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        variant: CoreLoadingVariant.pulse,
        size: CoreComponentSize.lg,
      );
      final side = (await _resolve(tester, size: CoreComponentSize.lg)).size;
      expect(resolved.pulseDotSize, closeTo(side * 0.4, 1e-9));
      expect(resolved.pulseHaloAlpha, 0.2);
    });

    testWidgets('a stated dot size wins over the size row', (tester) async {
      final resolved = await _resolve(
        tester,
        variant: CoreLoadingVariant.dots,
        size: CoreComponentSize.xl2,
        style: const CoreLoadingStyle(dotSize: 5),
      );
      expect(resolved.dotSize, 5);
    });
  });
}
