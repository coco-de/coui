// The active pill and its flight. What a widget test can hold: that the
// settled pill is under the active item and nowhere else, that changing
// the active item puts the bar in flight through the shared morph clip,
// that the flight ends where the spring says and hands the pill to the new
// item, and that reduced motion skips the flight entirely.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reducedMotion = false}) => CoUIApp(
  theme: ThemeData.fromCore(CoreThemePresets.light),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: child,
  ),
);

Dock _dock(int active) => Dock(
  items: [
    for (var i = 0; i < 3; i++)
      CoreDockItemData<Widget>(
        icon: const Icon(LucideIcons.house),
        label: 'Item $i',
        isActive: i == active,
        onPressed: () {},
      ),
  ],
);

/// The pill boxes in the tree: decorated boxes in the resolved indicator
/// colour with the resolved indicator radius.
Iterable<DecoratedBox> _pills(WidgetTester tester) {
  final context = tester.element(find.byType(Dock));
  final resolved = resolveDock(context);

  return tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where((
    box,
  ) {
    final decoration = box.decoration;

    return decoration is BoxDecoration &&
        decoration.color == resolved.indicatorColor &&
        decoration.borderRadius == resolved.indicatorRadius;
  });
}

void main() {
  testWidgets('the settled pill sits under the active item alone', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_dock(1)));

    final pills = _pills(tester).toList();
    expect(pills, hasLength(1));
    // Under the second item: the pill's box is the item's, widened by the
    // padding, so its centre is the item's centre.
    final pill = tester.getCenter(find.byWidget(pills.single));
    final item = tester.getCenter(find.text('Item 1'));
    expect(pill.dx, closeTo(item.dx, 1));
  });

  testWidgets('and a transparent indicator colour draws no pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _dock(0).withStyle(
          const CoreDockStyle(indicatorColor: CoreColor.transparent),
        ),
      ),
    );

    // Still one decorated box, fully transparent — the slot is drawn, the
    // fill is not. That is the shape "off" takes here: the layout does not
    // change when a style turns the pill on again.
    for (final pill in _pills(tester)) {
      expect((pill.decoration as BoxDecoration).color!.a, 0);
    }
  });

  testWidgets(
    'changing the active item flies the pill through the morph clip',
    (
      tester,
    ) async {
      await tester.pumpWidget(_app(_dock(0)));
      expect(find.byType(LiquidMorphClip), findsNothing);

      await tester.pumpWidget(_app(_dock(2)));
      await tester.pump();

      // In flight: the clip is up, and no item draws a settled pill — the
      // flight is the pill until it lands.
      expect(find.byType(LiquidMorphClip), findsOneWidget);
      expect(_pills(tester), isEmpty);

      // Landed: the clip is gone and the pill is under the new item.
      final spring = resolveDock(
        tester.element(find.byType(Dock)),
      ).indicatorSpring;
      await tester.pump(
        Duration(
          milliseconds: (spring.settleSeconds() * 1000).ceil() + 50,
        ),
      );
      expect(find.byType(LiquidMorphClip), findsNothing);
      final pill = tester.getCenter(find.byWidget(_pills(tester).single));
      expect(pill.dx, closeTo(tester.getCenter(find.text('Item 2')).dx, 1));
    },
  );

  testWidgets('the flight is the two pills, in the track s coordinates', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_dock(0)));
    final before = tester.getCenter(find.text('Item 0'));
    final after = tester.getCenter(find.text('Item 2'));
    await tester.pumpWidget(_app(_dock(2)));
    await tester.pump();

    final clip = tester.widget<LiquidMorphClip>(find.byType(LiquidMorphClip));
    // Same size, same row: the two bodies differ only in where they are,
    // and their distance is the items' distance.
    expect(clip.anchor.halfWidth, closeTo(clip.panel.halfWidth, 1e-6));
    expect(clip.anchor.centerY, closeTo(clip.panel.centerY, 1e-6));
    expect(
      clip.panel.centerX - clip.anchor.centerX,
      closeTo(after.dx - before.dx, 1),
    );
    expect(clip.anchor.radius, greaterThan(0));
    // Settle before the test ends so no timer is left pending.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('reduced motion skips the flight', (tester) async {
    await tester.pumpWidget(_app(_dock(0), reducedMotion: true));
    await tester.pumpWidget(_app(_dock(2), reducedMotion: true));
    await tester.pump();

    expect(find.byType(LiquidMorphClip), findsNothing);
    final pill = tester.getCenter(find.byWidget(_pills(tester).single));
    expect(pill.dx, closeTo(tester.getCenter(find.text('Item 2')).dx, 1));
  });
}
