import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kItemCount = 50;
const _kItemHeight = 40.0;

/// Side of the square viewport every test pumps the bar into — short enough
/// that [_kItemCount] items overflow it, so there is a thumb to look at.
const _kViewportSide = 300.0;

/// Inset from the bar's trailing edge that the probe presses at. The default
/// thumb spans 2–8 from that edge (6 thick, 2 clear of it), so 4 lands on it.
const _kThumbProbeInset = 4.0;

/// Vertical step the probe walks the trailing edge with.
const _kThumbProbeStep = 2.0;

/// A point well clear of the bar, on the leading side of the viewport.
const _kFarFromBar = Offset(20, 20);

/// How long the tests let the hover transition run — a little over the
/// contract's, so the controller has certainly finished.
const _kHoverSettle = Duration(
  milliseconds: CoreScrollbarContract.hoverTransitionMs + 50,
);

Widget _list() => ListView.builder(
  itemBuilder: (_, index) =>
      SizedBox(height: _kItemHeight, child: Text('Item $index')),
  itemCount: _kItemCount,
);

Widget _boxed(Widget child) =>
    SizedBox(width: _kViewportSide, height: _kViewportSide, child: child);

Finder get _painterHost => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint && widget.foregroundPainter is ScrollbarPainter,
);

/// The live painter the bar's thumb is drawn with — the same object the
/// framework's own hit testing consults, so what it reports is what is on
/// screen.
ScrollbarPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_painterHost).foregroundPainter!
        as ScrollbarPainter;

/// What `CoreScrollbarStyle` colour [core] paints as under the test theme.
Color _resolved(WidgetTester tester, CoreColor core) {
  final theme = Theme.of(tester.element(find.byType(Scrollbar)));
  return theme.colorScheme.resolve(core).toValue();
}

Offset? _findThumbPoint(WidgetTester tester) {
  final painter = _painter(tester);
  final rect = tester.getRect(_painterHost);
  for (var dy = 0.0; dy < rect.height; dy += _kThumbProbeStep) {
    final local = Offset(rect.width - _kThumbProbeInset, dy);
    if (painter.hitTestOnlyThumbInteractive(local, PointerDeviceKind.mouse)) {
      return rect.topLeft + local;
    }
  }
  return null;
}

/// Scrolls far enough to bring the thumb in, then leaves it up. A touch
/// drag, because the desktop scroll behaviour ignores a mouse one.
Future<void> _revealThumb(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -200));
  await tester.pump();
  await tester.pump(
    const Duration(milliseconds: CoreScrollbarContract.fadeDurationMs),
  );
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: _kFarFromBar);
  addTearDown(gesture.removePointer);
  return gesture;
}

/// What the bar occupies across its thickness: the thumb plus the gap it
/// keeps from the edge on both sides.
double _footprint(ScrollbarPainter painter) =>
    painter.thickness + 2 * painter.crossAxisMargin;

Future<void> _pumpBar(
  WidgetTester tester, {
  CoreScrollbarVisibility visibility = CoreScrollbarVisibility.auto,
  CoreScrollbarStyle? style,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await pumpTestApp(
    tester,
    _boxed(
      Scrollbar(
        visibility: visibility,
        scrollbarStyle: style,
        child: _list(),
      ),
    ),
    disableAnimations: disableAnimations,
    textDirection: textDirection,
  );
  await tester.pumpAndSettle();
  await _revealThumb(tester);
}

void main() {
  group('Scrollbar resting look', () {
    testWidgets(
      'is a 6px capsule 2px clear of the edge, in the surface ink at half '
      'strength',
      (tester) async {
        await _pumpBar(tester);
        final painter = _painter(tester);

        expect(painter.thickness, CoreScrollbarStyle.defaultThickness);
        expect(painter.crossAxisMargin, CoreScrollbarStyle.defaultThumbInset);
        expect(painter.mainAxisMargin, CoreScrollbarStyle.defaultThumbInset);
        expect(painter.minLength, CoreScrollbarStyle.defaultMinThumbLength);
        expect(
          painter.color,
          _resolved(tester, CoreScrollbarStyle.defaultThumbColor),
        );
        // The whole bar, thumb plus its gap on both sides.
        expect(_footprint(painter), 10);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'a style override reaches every part of the look',
      (tester) async {
        const ink = CoreColor.token(CoreColors.primary);
        await _pumpBar(
          tester,
          style: const CoreScrollbarStyle(
            thumbColor: ink,
            thickness: 4,
            thumbInset: 3,
            minThumbLength: 64,
          ),
        );
        final painter = _painter(tester);

        expect(painter.color, _resolved(tester, ink));
        expect(painter.thickness, 4);
        expect(painter.crossAxisMargin, 3);
        expect(painter.mainAxisMargin, 3);
        expect(painter.minLength, 64);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'thin halves the thumb and keeps its gap',
      (tester) async {
        await _pumpBar(tester, visibility: CoreScrollbarVisibility.thin);
        final painter = _painter(tester);

        expect(painter.thickness, 3);
        expect(painter.crossAxisMargin, CoreScrollbarStyle.defaultThumbInset);
        expect(_footprint(painter), 7);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'hidden draws no thumb at all',
      (tester) async {
        await pumpTestApp(
          tester,
          _boxed(
            Scrollbar(
              visibility: CoreScrollbarVisibility.hidden,
              child: _list(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_painterHost, findsNothing);
      },
      variant: TargetPlatformVariant.desktop(),
    );
  });

  group('Scrollbar hover and drag look', () {
    testWidgets(
      'the thumb darkens and thickens while the pointer is on it, and the '
      'space the bar occupies does not change',
      (tester) async {
        await _pumpBar(tester);
        final thumbPoint = _findThumbPoint(tester);
        expect(thumbPoint, isNotNull);
        final painter = _painter(tester);
        final restFootprint = _footprint(painter);

        final gesture = await _mouse(tester);
        await gesture.moveTo(thumbPoint!);
        await tester.pump();
        await tester.pump(_kHoverSettle);

        expect(painter.thickness, CoreScrollbarStyle.defaultHoverThickness);
        expect(
          painter.color,
          _resolved(tester, CoreScrollbarStyle.defaultHoverThumbColor),
        );
        // The growth came out of the gap, not out of the content's space.
        expect(painter.crossAxisMargin, 1);
        expect(_footprint(painter), restFootprint);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'the thumb goes back to rest when the pointer leaves',
      (tester) async {
        await _pumpBar(tester);
        final thumbPoint = _findThumbPoint(tester)!;
        final painter = _painter(tester);
        final restColor = painter.color;

        final gesture = await _mouse(tester);
        await gesture.moveTo(thumbPoint);
        await tester.pump();
        await tester.pump(_kHoverSettle);
        expect(painter.thickness, CoreScrollbarStyle.defaultHoverThickness);

        await gesture.moveTo(_kFarFromBar);
        await tester.pump();
        await tester.pump(_kHoverSettle);

        expect(painter.thickness, CoreScrollbarStyle.defaultThickness);
        expect(painter.crossAxisMargin, CoreScrollbarStyle.defaultThumbInset);
        expect(painter.color, restColor);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'a held thumb keeps the hovered look even when the pointer is dragged '
      'off the bar, and lets go of it on release',
      (tester) async {
        await _pumpBar(tester);
        final thumbPoint = _findThumbPoint(tester)!;
        final painter = _painter(tester);
        final bar = tester.getRect(_painterHost);

        final gesture = await _mouse(tester);
        await gesture.down(thumbPoint);
        await tester.pump();
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();
        await tester.pump(_kHoverSettle);
        expect(painter.thickness, CoreScrollbarStyle.defaultHoverThickness);

        // Off the bar, still holding the thumb.
        await gesture.moveTo(Offset(bar.left + 20, thumbPoint.dy + 40));
        await tester.pump();
        await tester.pump(_kHoverSettle);
        expect(
          painter.thickness,
          CoreScrollbarStyle.defaultHoverThickness,
          reason: 'the thumb is still held — it must not shrink under the hand',
        );

        await gesture.up();
        await tester.pump();
        await gesture.moveTo(_kFarFromBar);
        await tester.pump();
        await tester.pump(_kHoverSettle);
        expect(painter.thickness, CoreScrollbarStyle.defaultThickness);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'a hovered thumb is never wider than the space reserved for it',
      (tester) async {
        await _pumpBar(
          tester,
          style: const CoreScrollbarStyle(hoverThickness: 40),
        );
        final thumbPoint = _findThumbPoint(tester)!;
        final painter = _painter(tester);
        final restFootprint = _footprint(painter);

        final gesture = await _mouse(tester);
        await gesture.moveTo(thumbPoint);
        await tester.pump();
        await tester.pump(_kHoverSettle);

        expect(painter.thickness, restFootprint);
        expect(painter.crossAxisMargin, 0);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'thin grows to half the hovered thickness inside the same footprint',
      (tester) async {
        await _pumpBar(tester, visibility: CoreScrollbarVisibility.thin);
        final thumbPoint = _findThumbPoint(tester)!;
        final painter = _painter(tester);

        final gesture = await _mouse(tester);
        await gesture.moveTo(thumbPoint);
        await tester.pump();
        await tester.pump(_kHoverSettle);

        expect(painter.thickness, 4);
        expect(painter.crossAxisMargin, 1.5);
        expect(_footprint(painter), 7);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'under reduced motion the hovered look is reached at once',
      (tester) async {
        await _pumpBar(tester, disableAnimations: true);
        final thumbPoint = _findThumbPoint(tester)!;
        final painter = _painter(tester);

        final gesture = await _mouse(tester);
        await gesture.moveTo(thumbPoint);
        // One frame, no time elapsed: an animated change would still be at
        // the start.
        await tester.pump();

        expect(painter.thickness, CoreScrollbarStyle.defaultHoverThickness);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'without reduced motion the change is in flight, not instant',
      (tester) async {
        await _pumpBar(tester);
        final thumbPoint = _findThumbPoint(tester)!;
        final painter = _painter(tester);

        final gesture = await _mouse(tester);
        await gesture.moveTo(thumbPoint);
        await tester.pump();
        await tester.pump(
          const Duration(
            milliseconds: CoreScrollbarContract.hoverTransitionMs ~/ 4,
          ),
        );

        // Part-way between the two looks — the control for the test above:
        // without it, "reached at once" would pass for a bar that never
        // animates.
        expect(
          painter.thickness,
          greaterThan(CoreScrollbarStyle.defaultThickness),
        );
        expect(
          painter.thickness,
          lessThan(CoreScrollbarStyle.defaultHoverThickness),
        );
      },
      variant: TargetPlatformVariant.desktop(),
    );
  });

  group('Scrollbar in a right-to-left tree', () {
    testWidgets(
      'keeps the same gap from the leading edge it moves to',
      (tester) async {
        await _pumpBar(tester, textDirection: TextDirection.rtl);
        final painter = _painter(tester);

        expect(painter.textDirection, TextDirection.rtl);
        expect(painter.crossAxisMargin, CoreScrollbarStyle.defaultThumbInset);
        expect(_footprint(painter), 10);
      },
      variant: TargetPlatformVariant.desktop(),
    );
  });
}
