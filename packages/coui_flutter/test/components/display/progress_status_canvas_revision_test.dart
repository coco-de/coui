// The values the designer changed after checking the canvas, read back from
// what the widgets draw: the `xl` ring's figure, the `dots` wave and gap, and
// the round ends of the bar across a `busy` Status dot.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

/// Every scaling axis at 1, so a measured value is the design's and nothing
/// else.
final ThemeData _theme = ThemeData.fromCore(
  CoreThemePresets.previewLight.copyWith(
    textScaling: 1,
    sizeScaling: 1,
    radiusScaling: 1,
  ),
);

Future<void> _pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    CoUIApp(
      theme: _theme,
      home: Center(child: child),
    ),
  );
  await tester.pump();
}

/// The three dots' opacities, left to right.
List<double> _dotOpacities(WidgetTester tester) {
  final opacities = tester
      .widgetList<Opacity>(
        find.descendant(
          of: find.byType(Loading),
          matching: find.byType(Opacity),
        ),
      )
      .map((o) => o.opacity)
      .toList();
  expect(opacities, hasLength(CoreLoadingStyle.dotCount));
  return opacities;
}

/// The three dots' boxes, left to right.
List<Rect> _dotRects(WidgetTester tester) => tester
    .widgetList<Opacity>(
      find.descendant(of: find.byType(Loading), matching: find.byType(Opacity)),
    )
    .map((o) => tester.getRect(find.byWidget(o)))
    .toList();

void main() {
  group('RadialProgress xl figure', () {
    const desktop = 1280.0;
    const mobile = 400.0;

    double drawnSize(WidgetTester tester) => tester
        .renderObject<RenderParagraph>(
          find.descendant(
            of: find.text('50%'),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!
        .fontSize!;

    test('the xl row states the headlineLarge role and no size', () {
      final style = CoreRadialProgressStyle
          .defaultsBySize[CoreProgressSize.xl]!
          .valueTextStyle!;
      expect(style.token, CoreTextStyles.headlineLarge);
      expect(style.fontSize, isNull);
    });

    testWidgets('draws headlineLarge on a desktop view', (tester) async {
      await _pumpAt(
        tester,
        desktop,
        const RadialProgress(
          value: 50,
          showValueText: true,
          size: CoreProgressSize.xl,
        ),
      );
      expect(
        drawnSize(tester),
        CoreTypography.coui.headlineLarge.fontSize,
      );
    });

    testWidgets("draws headlineLarge's mobile size on a phone", (tester) async {
      await _pumpAt(
        tester,
        mobile,
        const RadialProgress(
          value: 50,
          showValueText: true,
          size: CoreProgressSize.xl,
        ),
      );
      expect(
        drawnSize(tester),
        CoreHeadingSizes.couiByTier[CoreBreakpointTier.mobile]!.headlineLarge,
      );
    });
  });

  group('Loading dots wave', () {
    testWidgets('the dots read 1 · 0.6 · 0.3 at the start of a cycle', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        1280,
        const Loading(variant: .dots, componentSize: .md),
      );
      final opacities = _dotOpacities(tester);
      for (var i = 0; i < opacities.length; i++) {
        expect(
          opacities[i],
          moreOrLessEquals(CoreLoadingStyle.dotWaveOpacities[i]),
          reason: 'dot $i',
        );
      }
      expect(opacities, [
        moreOrLessEquals(1),
        moreOrLessEquals(0.6),
        moreOrLessEquals(0.3),
      ]);
    });

    testWidgets('a third of a cycle on, the bright dot has moved right', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        1280,
        const Loading(variant: .dots, componentSize: .md),
      );
      final cycle =
          CoreLoadingStyle.defaultsByVariant[CoreLoadingVariant.dots]!.duration;
      await tester.pump(cycle ~/ CoreLoadingStyle.dotCount);
      expect(_dotOpacities(tester), [
        moreOrLessEquals(0.3, epsilon: 1e-2),
        moreOrLessEquals(1, epsilon: 1e-2),
        moreOrLessEquals(0.6, epsilon: 1e-2),
      ]);
    });

    for (final size in CoreComponentSize.values) {
      final row = CoreLoadingStyle.defaultsBySize[size];
      if (row == null) continue;
      testWidgets('${size.name}: dots sit half a dot apart, centred', (
        tester,
      ) async {
        await _pumpAt(
          tester,
          1280,
          Loading(variant: .dots, componentSize: size),
        );
        final rects = _dotRects(tester);
        final dot = row.dotSize!;
        for (var i = 1; i < rects.length; i++) {
          expect(
            rects[i].left - rects[i - 1].right,
            moreOrLessEquals(dot * CoreLoadingStyle.dotGapRatio),
            reason: 'gap $i',
          );
        }
        final box = tester.getRect(find.byType(Loading));
        expect(
          rects.first.left - box.left,
          moreOrLessEquals(box.right - rects.last.right),
          reason: 'the row is centred in the indicator',
        );
      });
    }
  });

  group('Status busy bar', () {
    testWidgets('the bar has round ends — half its thickness', (tester) async {
      await _pumpAt(
        tester,
        1280,
        const Status(variant: CoreStatusVariant.busy),
      );
      // The bar is the thinnest decorated box in the dot.
      final boxes = find.descendant(
        of: find.byType(Status),
        matching: find.byType(DecoratedBox),
      );
      final bar = boxes
          .evaluate()
          .map((e) => e.widget as DecoratedBox)
          .reduce(
            (a, b) =>
                tester.getRect(find.byWidget(a)).height <=
                    tester.getRect(find.byWidget(b)).height
                ? a
                : b,
          );
      final rect = tester.getRect(find.byWidget(bar));
      expect(rect.height, CoreStatusStyle.defaultBarWidth);
      final decoration = bar.decoration as BoxDecoration;
      final radius = (decoration.borderRadius! as BorderRadius).topLeft.x;
      // Fully round: the painted corner is clamped to half the thickness.
      expect(radius, greaterThanOrEqualTo(rect.height / 2));
    });
  });
}
