// The Skeleton's default geometry and pulse start, read off the resolver and
// off a laid-out tree.
//
// Three numbers are the designer's table: a rectangular box takes corner 8,
// a text line is 12 high with 12 between lines (a 24px pitch, 60 for three
// lines), and the pulse rests at 70%. Every one is a Core default the widget
// only reads, so the test says where the default stops mattering — at the
// density axis (the same 12 is 15 on a 1.25x phone) and at the laid-out box.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// A scaling that is not 1. `AdaptiveScaling.mobile` is 1, and a test of the
// density axis at 1 compares the unscaled value with itself.
const _kPhone = AdaptiveScaling(1.25);

const double _kTextWidth = 200;

ThemeData _themeAt(AdaptiveScaling scaling) =>
    scaling.scale(ThemeData.fromCore(CoreThemePresets.light));

Future<ResolvedSkeleton> _resolve(
  WidgetTester tester,
  AdaptiveScaling scaling,
  CoreSkeletonVariant variant,
) async {
  ResolvedSkeleton? resolved;
  // Unmount first. `buildTestApp` puts the child in an
  // `Overlay(initialEntries:)`, which is honoured on the FIRST mount only — a
  // second `pumpWidget` in the same test would never run the new builder.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) {
          resolved = resolveSkeleton(context, variant: variant);
          return const SizedBox.shrink();
        },
      ),
      theme: _themeAt(scaling),
    ),
  );
  expect(resolved, isNotNull, reason: 'the builder never ran');

  return resolved!;
}

Future<Size> _textSize(WidgetTester tester, AdaptiveScaling scaling) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      const SizedBox(width: _kTextWidth, child: Skeleton.text()),
      theme: _themeAt(scaling),
    ),
  );

  return tester.getSize(find.byType(Skeleton));
}

void main() {
  group('text variant geometry', () {
    testWidgets('a line is 12 high with 12 between lines', (tester) async {
      final resolved = await _resolve(
        tester,
        AdaptiveScaling.desktop,
        CoreSkeletonVariant.text,
      );

      expect(resolved.lines, 3);
      expect(resolved.lineHeight, 12);
      expect(resolved.lineSpacing, 12);
      expect(resolved.lastLineWidth, 0.6);
    });

    testWidgets('three lines lay out 60 high, last line 60% wide', (
      tester,
    ) async {
      final size = await _textSize(tester, AdaptiveScaling.desktop);

      expect(size.width, _kTextWidth);
      expect(size.height, 3 * 12 + 2 * 12);

      // The last line is the one narrower than the box.
      final bars = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(Skeleton),
              matching: find.byType(Container),
            ),
          )
          .toList();
      expect(bars, hasLength(3));
      final lastBar = tester.getSize(
        find
            .descendant(
              of: find.byType(Skeleton),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(lastBar.width, closeTo(_kTextWidth * 0.6, 0.01));
      expect(lastBar.height, 12);
    });

    testWidgets('at 1.25x the line and the gap grow together — 15 / 15', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        _kPhone,
        CoreSkeletonVariant.text,
      );

      expect(resolved.lineHeight, 12 * _kPhone.sizeScaling);
      expect(resolved.lineSpacing, 12 * _kPhone.sizeScaling);
      expect(resolved.lineHeight, 15);
      expect(resolved.lineSpacing, 15);
    });

    testWidgets('at 1.25x three lines lay out 75 high', (tester) async {
      final size = await _textSize(tester, _kPhone);

      expect(size.height, 3 * 15 + 2 * 15);
    });
  });

  group('rectangular variant', () {
    testWidgets('the default corner is 8', (tester) async {
      final resolved = await _resolve(
        tester,
        AdaptiveScaling.desktop,
        CoreSkeletonVariant.rectangular,
      );

      for (final corner in [
        resolved.borderRadius.topLeft,
        resolved.borderRadius.topRight,
        resolved.borderRadius.bottomLeft,
        resolved.borderRadius.bottomRight,
      ]) {
        expect(corner.x, 8);
      }
    });

    testWidgets('the corner scales with the density axis — 10 at 1.25x', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        _kPhone,
        CoreSkeletonVariant.rectangular,
      );

      expect(resolved.borderRadius.topLeft.x, closeTo(8 * 1.25, 0.01));
    });
  });

  // `AdaptiveScaling(1.25)` moves all three axes together, so the cases above
  // cannot say WHICH axis the box follows. The resolver multiplies by the size
  // axis (`theme.scaling`) and by nothing else: the radius and text axes are
  // not read by a component, and typography is pre-scaled at the theme.
  group('only the size axis moves the box', () {
    const sizeOnly = AdaptiveScaling.only(sizeScaling: 1.25);
    const radiusAndTextOnly = AdaptiveScaling.only(
      radiusScaling: 1.25,
      textScaling: 1.25,
    );

    testWidgets('size axis alone: line 15, gap 15, corner 10', (tester) async {
      final text = await _resolve(tester, sizeOnly, CoreSkeletonVariant.text);
      expect(text.lineHeight, 15);
      expect(text.lineSpacing, 15);

      final box = await _resolve(
        tester,
        sizeOnly,
        CoreSkeletonVariant.rectangular,
      );
      expect(box.borderRadius.topLeft.x, closeTo(8 * 1.25, 0.01));
    });

    testWidgets('radius and text axes alone leave it at 12 / 12 / 8', (
      tester,
    ) async {
      final text = await _resolve(
        tester,
        radiusAndTextOnly,
        CoreSkeletonVariant.text,
      );
      expect(text.lineHeight, 12);
      expect(text.lineSpacing, 12);

      final box = await _resolve(
        tester,
        radiusAndTextOnly,
        CoreSkeletonVariant.rectangular,
      );
      expect(box.borderRadius.topLeft.x, 8);
    });
  });

  group('pulse start', () {
    for (final variant in CoreSkeletonVariant.values) {
      testWidgets('${variant.name} rests at 70% of the fill', (tester) async {
        final resolved = await _resolve(
          tester,
          AdaptiveScaling.desktop,
          variant,
        );

        expect(resolved.fromOpacity, 0.7);
        expect(resolved.toOpacity, 1);
        // The fill is an opaque scheme colour, so its alpha IS the pulse end.
        expect(resolved.pulseFromColor.a, closeTo(0.7, 1e-6));
        expect(resolved.pulseToColor.a, closeTo(1, 1e-6));
      });
    }
  });
}
