// Widget tests for the Flutter `Carousel` prev / next buttons and indicator
// tones — the chrome the redesign moved.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kViewport = 400.0;

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Material(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: _kViewport, height: 160, child: child),
      ),
    ),
  ),
);

Carousel _carousel({
  required CoreCarouselVariant variant,
  CoreCarouselStyle? carouselStyle,
}) => Carousel(
  variant: variant,
  showNavigation: true,
  transition: const CarouselTransition.sliding(),
  itemCount: 3,
  itemBuilder: (context, index) => ColoredBox(
    color: const Color(0xFFCCCCCC),
    child: Center(child: Text('Item $index')),
  ),
  carouselStyle: carouselStyle,
);

/// The two nav buttons' rects, prev first.
({Rect prev, Rect next}) _navRects(WidgetTester tester) {
  final buttons = find.byType(Button);
  expect(buttons, findsNWidgets(2));
  return (
    prev: tester.getRect(buttons.at(0)),
    next: tester.getRect(buttons.at(1)),
  );
}

void main() {
  group('Carousel prev / next buttons', () {
    testWidgets('slide puts one button at each end of the viewport', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_carousel(variant: .slide)));
      await tester.pump();

      final rects = _navRects(tester);
      const inset = 16.0;

      expect(rects.prev.left, inset);
      expect(rects.next.right, _kViewport - inset);
    });

    testWidgets('banner gathers the pair at the trailing end, four apart', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_carousel(variant: .banner)));
      await tester.pump();

      final rects = _navRects(tester);
      const inset = 16.0;

      // Next keeps the trailing inset; prev sits to its left with the gap
      // between the two discs.
      expect(rects.next.right, _kViewport - inset);
      expect(rects.next.left - rects.prev.right, 4);
      expect(rects.prev.left, greaterThan(_kViewport / 2));
    });

    testWidgets('the banner gap is the style slot, not a literal', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _carousel(
            variant: .banner,
            carouselStyle: const CoreCarouselStyle(
              navGapStyle: CoreGapStyle(size: 12),
            ),
          ),
        ),
      );
      await tester.pump();

      final rects = _navRects(tester);
      expect(rects.next.left - rects.prev.right, 12);
    });

    testWidgets('banner and slide differ only in where the pair sits', (
      tester,
    ) async {
      // The disc is 32 in both: only the arrangement moves.
      for (final variant in CoreCarouselVariant.values) {
        await tester.pumpWidget(_app(_carousel(variant: variant)));
        await tester.pump();

        final rects = _navRects(tester);
        expect(rects.prev.size, const Size.square(32), reason: '$variant');
        expect(rects.next.size, const Size.square(32), reason: '$variant');
      }
    });
  });

  group('Carousel resolver', () {
    late BuildContext captured;

    Future<void> capture(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    testWidgets('the nav button states a raised face', (tester) async {
      await capture(tester);
      final resolved = resolveCarousel(captured);
      final style = resolved.navButtonStyle;

      expect(
        style.backgroundColor,
        const CoreColor.token(CoreColors.surfaceRaised),
      );
      expect(
        style.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(style.borderWidth, CoreStrokeWidth.stroke1);
      expect(style.boxShadow, CoreShadow.sm);
    });

    testWidgets('a stated controlOverlayColor still wins the fill', (
      tester,
    ) async {
      await capture(tester);
      const stated = CoreColor.token(CoreColors.primary);
      final resolved = resolveCarousel(
        captured,
        carouselStyle: const CoreCarouselStyle(controlOverlayColor: stated),
      );

      expect(resolved.navButtonStyle.backgroundColor, stated);
      // …and the rest of the face stays.
      expect(resolved.navButtonStyle.boxShadow, CoreShadow.sm);
    });

    testWidgets('the dots take the accent when active, outline when not', (
      tester,
    ) async {
      await capture(tester);
      final resolved = resolveCarousel(captured);

      expect(
        resolved.dotIndicatorStyle.activeColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        resolved.dotIndicatorStyle.inactiveColor,
        const CoreColor.token(CoreColors.outline),
      );
    });

    testWidgets('a stated indicator colour wins over the carousel tone', (
      tester,
    ) async {
      await capture(tester);
      const stated = CoreColor.token(CoreColors.tertiary);
      final resolved = resolveCarousel(
        captured,
        carouselStyle: const CoreCarouselStyle(
          indicatorActiveColor: stated,
          indicatorInactiveColor: stated,
        ),
      );

      expect(resolved.dotIndicatorStyle.activeColor, stated);
      expect(resolved.dotIndicatorStyle.inactiveColor, stated);
    });

    testWidgets('the prev ↔ next gap is the default four unless stated', (
      tester,
    ) async {
      await capture(tester);

      expect(
        resolveCarousel(captured).navGapStyle,
        CoreCarouselStyle.defaultNavGapStyle,
      );
      expect(
        resolveCarousel(
          captured,
          carouselStyle: const CoreCarouselStyle(
            navGapStyle: CoreGapStyle(size: 8),
          ),
        ).navGapStyle.size,
        8,
      );
    });
  });
}
