// The floating glass bar grows a little while its lens is up — the capsule,
// the lens and the destinations together, about a point mirrored from the lens
// (`CoreGlassNavigationMotion.barSwell`, `barSwellOrigin`). What this reads is
// the transform the capsule is drawn through; the motion's numbers are Core's
// and its own tests hold them.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

const _glass = CoreNavigationBarStyle(surfaceStyle: .liquidGlass);
const double _size = CoreGlassNavigationMotion.barSwell;

const _items = [
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.house),
    label: 'Home',
  ),
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.search),
    label: 'Search',
  ),
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.bell),
    label: 'Alerts',
  ),
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.user),
    label: 'Profile',
  ),
];

Finder _destination(int index) => find.byKey(ValueKey<int>(index));

/// The transform the bar's capsule is drawn through: the one nearest the
/// material pass, around it and every destination. The bar's compact form is
/// a transform of its own outside this one (`AnimatedScale`).
Transform _swell(WidgetTester tester) {
  final finder = find
      .ancestor(
        of: find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(BackdropFilter),
        ),
        matching: find.byType(Transform),
      )
      .first;
  for (final inside in [find.byType(BackdropFilter), _destination(0)]) {
    expect(
      find.descendant(of: finder, matching: inside),
      findsWidgets,
      reason: 'the swell draws the capsule and the destinations together',
    );
  }

  return tester.widget<Transform>(finder);
}

double _scale(WidgetTester tester) =>
    _swell(tester).transform.getMaxScaleOnAxis();

Future<void> _pumpFrames(WidgetTester tester, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _pumpBar(
  WidgetTester tester, {
  CoreNavigationBarMode mode = .bar,
  TextDirection textDirection = .ltr,
  bool disableAnimations = false,
  double width = 360,
}) => pumpTestApp(
  tester,
  SizedBox(
    width: mode == .bar ? width : null,
    child: NavigationBar(
      mode: mode,
      items: _items,
      selectedIndex: 0,
      onSelected: (_) {},
      navigationBarStyle: _glass,
    ),
  ),
  textDirection: textDirection,
  disableAnimations: disableAnimations,
);

void main() {
  group('the glass bar swell', () {
    testWidgets('is at rest until the bar is held', (tester) async {
      await _pumpBar(tester);
      expect(_scale(tester), 1);
    });

    testWidgets('grows the whole bar while its lens is held, and lets it go', (
      tester,
    ) async {
      await _pumpBar(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(_destination(0)),
      );
      await tester.pump();
      await _pumpFrames(tester, 12);
      expect(_scale(tester), greaterThan(1 + _size / 2));

      // Held, it settles at its size and its clock stops.
      await tester.pumpAndSettle();
      expect(_scale(tester), closeTo(1 + _size, 1e-9));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scale(tester), 1);
    });

    for (final direction in TextDirection.values) {
      testWidgets('grows from the side away from the lens: $direction', (
        tester,
      ) async {
        // A lens at one end puts the point toward the other, so the lens's
        // end moves out the most. The first destination is on the left in a
        // left-to-right row and on the right in a right-to-left one.
        final first = direction == .ltr ? 1.0 : -1.0;
        for (final (index, side) in [(0, first), (_items.length - 1, -first)]) {
          await _pumpBar(tester, textDirection: direction);
          final gesture = await tester.startGesture(
            tester.getCenter(_destination(index)),
          );
          await tester.pump();
          await _pumpFrames(tester, 4);

          final alignment = _swell(tester).alignment! as Alignment;
          expect(alignment.x.sign, side, reason: 'destination $index');
          expect(alignment.y, 0);

          await gesture.up();
          await tester.pumpAndSettle();
        }
      });

      testWidgets('puts its point where the lens is drawn: $direction', (
        tester,
      ) async {
        // Padding on one side only, so a point measured past the wrong
        // padding lands somewhere else. The point is read back against the
        // drawn capsule and the drawn lens: a uniform scale keeps every
        // fraction across the capsule, so the swell itself does not move the
        // answer.
        await pumpTestApp(
          tester,
          SizedBox(
            width: 520,
            child: NavigationBar(
              items: _items,
              selectedIndex: 0,
              onSelected: (_) {},
              navigationBarStyle: const CoreNavigationBarStyle(
                surfaceStyle: .liquidGlass,
                padding: CoreEdgeInsets.only(left: 40, top: 4, bottom: 4),
              ),
            ),
          ),
          textDirection: direction,
        );
        final gesture = await tester.startGesture(
          tester.getCenter(_destination(1)),
        );
        await tester.pump();
        await _pumpFrames(tester, 12);

        final capsule = tester.getRect(find.byType(BackdropFilter));
        final lens = tester.getCenter(
          find.byKey(const ValueKey('coui-navigation-selection')),
        );
        final expected = CoreGlassNavigationMotion.barSwellOrigin(
          (lens.dx - capsule.left) / capsule.width,
        );

        final alignment = _swell(tester).alignment! as Alignment;
        expect(alignment.x, closeTo(expected * 2 - 1, 1e-3));

        await gesture.up();
        await tester.pumpAndSettle();
      });
    }

    testWidgets("runs down the rail's column", (tester) async {
      await _pumpBar(tester, mode: .rail);
      final gesture = await tester.startGesture(
        tester.getCenter(_destination(0)),
      );
      await tester.pump();
      await _pumpFrames(tester, 12);

      expect(_scale(tester), greaterThan(1 + _size / 2));
      final alignment = _swell(tester).alignment! as Alignment;
      expect(alignment.x, 0);
      expect(alignment.y, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scale(tester), 1);
    });

    testWidgets('reads the finger on the bar as it is laid out', (
      tester,
    ) async {
      // The swell is drawn only: a finger that goes to where a destination
      // is laid out puts the lens on it. A press that starts while the bar is
      // still grown is where reading the finger through the drawn bar would
      // differ — the point it grows from moves with the lens.
      await _pumpBar(tester);
      final first = tester.getCenter(_destination(0));
      final second = tester.getCenter(_destination(1));
      var gesture = await tester.startGesture(first);
      await tester.pump();
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(_scale(tester), greaterThan(1 + _size / 2));

      gesture = await tester.startGesture(first);
      await tester.pump();
      await gesture.moveTo(Offset.lerp(first, second, .5)!);
      await tester.pump();
      await gesture.moveTo(second);
      await tester.pump();
      await _pumpFrames(tester, 30);
      expect(_scale(tester), greaterThan(1));

      final lens = tester.getCenter(
        find.byKey(const ValueKey('coui-navigation-selection')),
      );
      expect(lens.dx, closeTo(tester.getCenter(_destination(1)).dx, .5));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('never grows the bar under reduced motion', (tester) async {
      await _pumpBar(tester, disableAnimations: true);
      final gesture = await tester.startGesture(
        tester.getCenter(_destination(0)),
      );
      await tester.pump();
      await _pumpFrames(tester, 12);
      expect(_scale(tester), 1);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('lets the bar go when motion is reduced while it is held', (
      tester,
    ) async {
      // Reduced motion snaps the lens without its clock ticking, so the bar
      // hears of it after the frame rather than from the clock.
      await _pumpBar(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(_destination(0)),
      );
      await tester.pump();
      await _pumpFrames(tester, 12);
      expect(_scale(tester), greaterThan(1));

      await _pumpBar(tester, disableAnimations: true);
      await tester.pump();
      expect(_scale(tester), 1);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('lets the bar go when its lens goes while it is held', (
      tester,
    ) async {
      // Too narrow for its destinations, the row scrolls and has no lens.
      final width = ValueNotifier<double>(360);
      addTearDown(width.dispose);
      await pumpTestApp(
        tester,
        ValueListenableBuilder<double>(
          valueListenable: width,
          builder: (context, value, _) => SizedBox(
            width: value,
            child: NavigationBar(
              items: _items,
              selectedIndex: 0,
              onSelected: (_) {},
              navigationBarStyle: _glass,
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(_destination(0)),
      );
      await tester.pump();
      await _pumpFrames(tester, 12);
      expect(_scale(tester), greaterThan(1));

      width.value = 120;
      await tester.pump();
      await tester.pump();
      expect(_scale(tester), 1);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
