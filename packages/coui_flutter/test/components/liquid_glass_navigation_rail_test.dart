import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

const _glass = CoreNavigationBarStyle(surfaceStyle: .liquidGlass);
const ValueKey<String> _selectionKey = ValueKey('coui-navigation-selection');
const ValueKey<String> _lensKey = ValueKey('coui-navigation-lens');

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

/// The destination at [index], by the bar's own key.
Finder _destination(int index) => find.byKey(ValueKey<int>(index));

Future<void> _pumpFrames(WidgetTester tester, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  group('the glass rail is a floating capsule', () {
    testWidgets('it resolves the rail preset, not the bar or the docked rail', (
      tester,
    ) async {
      late ResolvedNavigationBar glassRail;
      late ResolvedNavigationBar dockedRail;
      late ResolvedNavigationBar glassSidebar;
      late CoreSurfaceGeometryConstraint geometry;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            geometry = Theme.of(context).geometry;
            glassRail = resolveNavigationBar(
              context,
              mode: .rail,
              variant: .standard,
              navigationBarStyle: _glass,
            );
            dockedRail = resolveNavigationBar(
              context,
              mode: .rail,
              variant: .standard,
            );
            glassSidebar = resolveNavigationBar(
              context,
              // The announced mode still has to keep its docked chrome
              // under glass until it is removed.
              // ignore: deprecated_member_use
              mode: .sidebar,
              variant: .standard,
              navigationBarStyle: _glass,
            );
            return const SizedBox();
          },
        ),
      );
      const preset = CoreNavigationBarStyle.glassRailStyle;

      expect(glassRail.floatingGlass, isTrue);
      expect(
        glassRail.barRadius,
        preset.barRadius!.toValue(geometry: geometry),
      );
      expect(
        glassRail.barMargin,
        preset.barMargin!.toValue(geometry: geometry),
      );
      expect(glassRail.padding, preset.padding!.toValue(geometry: geometry));
      expect(glassRail.itemSpacing, preset.itemSpacing);
      expect(
        glassRail.itemRadius,
        preset.itemRadius!.toValue(geometry: geometry),
      );
      expect(glassRail.itemMinHeight, preset.itemMinHeight);
      expect(glassRail.iconOnlyItemMinHeight, preset.itemMinHeight);
      expect(glassRail.iconOnlyItemMinWidth, preset.iconOnlyItemMinWidth);
      expect(
        glassRail.iconAnchorPadding,
        preset.iconAnchorPadding!.toValue(geometry: geometry),
      );
      // Detached: no content-facing hairline on either axis.
      expect(glassRail.barBorder, const BorderDirectional());
      expect(glassRail.barHairline, const BorderDirectional());
      // The lens is the face, so the pill behind the icon is not drawn.
      expect(glassRail.indicator, CoreNavigationSelectionIndicator.color);
      expect(glassRail.selectedBackgroundColor.a, greaterThan(0));
      // The quiet pane and the moving lens, as on the bar.
      expect(
        glassRail.refraction,
        CoreNavigationBarStyle.glassRestingRefraction,
      );
      expect(
        glassRail.selectionRefraction,
        CoreNavigationBarStyle.glassSelectionRefraction,
      );

      // The opaque rail is untouched: docked, tiled, hairlined.
      expect(dockedRail.floatingGlass, isFalse);
      expect(dockedRail.barRadius, BorderRadius.zero);
      expect(dockedRail.barMargin, EdgeInsets.zero);
      expect(dockedRail.indicator, CoreNavigationSelectionIndicator.fill);
      expect(dockedRail.barBorder.end.width, greaterThan(0));

      // The sidebar takes the material and keeps its docked chrome.
      expect(glassSidebar.isGlass, isTrue);
      expect(glassSidebar.floatingGlass, isFalse);
      expect(glassSidebar.barRadius, BorderRadius.zero);
      expect(glassSidebar.indicator, CoreNavigationSelectionIndicator.fill);
    });

    testWidgets('four destinations stand 48 across and 212 tall', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        NavigationBar(
          mode: .rail,
          items: _items,
          selectedIndex: 0,
          onSelected: (_) {},
          navigationBarStyle: _glass,
        ),
      );

      // The material pass is clipped to the capsule, so its box is the
      // capsule's — the margin sits outside it.
      final capsule = find.byType(BackdropFilter);
      expect(capsule, findsOneWidget);
      expect(tester.getSize(capsule), const Size(48, 212));
      final bar = find.byType(NavigationBar);
      expect(tester.getSize(bar), const Size(64, 228));
      expect(
        tester.getTopLeft(capsule),
        tester.getTopLeft(bar) + const Offset(8, 8),
      );

      // Each destination is the 40×48 cell, 4 inside the capsule and 4
      // from the next.
      for (var index = 0; index < _items.length; index++) {
        final cell = find.descendant(
          of: _destination(index),
          matching: find.byType(AnimatedContainer),
        );
        expect(tester.getSize(cell.first), const Size(40, 48));
        expect(
          tester.getTopLeft(cell.first),
          tester.getTopLeft(capsule) + Offset(4, 4 + index * 52.0),
        );
      }

      // No `SafeArea` of its own — where the capsule sits is the shell's.
      expect(
        find.descendant(of: bar, matching: find.byType(SafeArea)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('it is icon-only unless a label mode is stated', (
      tester,
    ) async {
      Widget rail({
        CoreNavigationLabelMode? labelMode,
        CoreNavigationBarStyle? style,
      }) => NavigationBar(
        mode: .rail,
        items: _items,
        selectedIndex: 0,
        onSelected: (_) {},
        labelMode: labelMode,
        navigationBarStyle: style,
      );

      await pumpTestApp(tester, rail(style: _glass));
      expect(find.text('Home'), findsNothing);
      expect(find.text('Search'), findsNothing);
      // The hidden label is still the destination's name.
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      expect(find.byKey(_selectionKey), findsOneWidget);

      // A stated mode wins over the capsule's default.
      await tester.pumpWidget(const SizedBox());
      await pumpTestApp(tester, rail(style: _glass, labelMode: .all));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // The opaque rail keeps naming every destination.
      await tester.pumpWidget(const SizedBox());
      await pumpTestApp(tester, rail());
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byKey(_selectionKey), findsNothing);
    });

    testWidgets('a standalone rail item answers the same defaults', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        // A destination placed on its own fills the width it is given, as
        // a hand-built column's rows do; its own width is the intrinsic one.
        IntrinsicWidth(
          child: NavigationBarItem(
            mode: .rail,
            icon: const Icon(LucideIcons.house),
            label: 'Home',
            selected: true,
            onPressed: () {},
            navigationBarStyle: _glass,
          ),
        ),
      );
      expect(find.text('Home'), findsNothing);
      final cell = find.descendant(
        of: find.byType(NavigationBarItem),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(cell.first), const Size(40, 48));
      // Outside a track the destination paints its own selected face.
      final face =
          tester.widget<AnimatedContainer>(cell.first).decoration!
              as BoxDecoration;
      expect(face.color!.a, greaterThan(0));
    });
  });

  group('a hidden label is a tooltip beside the destination', () {
    Widget navigation(CoreNavigationBarMode mode) => NavigationBar(
      mode: mode,
      items: _items,
      selectedIndex: 0,
      onSelected: (_) {},
      labelMode: .none,
      navigationBarStyle: _glass,
    );

    /// Hovers the destination at [index] of a rail held at [alignment] and
    /// returns where the destination and its tooltip bubble landed.
    Future<({Rect destination, Rect bubble})> hover(
      WidgetTester tester, {
      required Alignment alignment,
      required int index,
    }) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: .liquidGlass,
          home: Align(alignment: alignment, child: navigation(.rail)),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_destination(index)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // The label is not drawn in the capsule, so the only text is the
      // bubble's.
      final label = _items[index].label!;
      return (
        destination: tester.getRect(_destination(index)),
        bubble: tester.getRect(find.text(label)),
      );
    }

    testWidgets('a column asks for the side, a row for the top', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        navigation(.rail),
        surfaceStyle: .liquidGlass,
      );
      final rail = tester.widgetList<Tooltip>(find.byType(Tooltip));
      expect(rail, hasLength(_items.length));
      expect(
        rail.map((tooltip) => tooltip.position),
        everyElement(CoreTooltipPosition.right),
      );

      await tester.pumpWidget(const SizedBox());
      await pumpTestApp(tester, navigation(.bar), surfaceStyle: .liquidGlass);
      final bar = tester.widgetList<Tooltip>(find.byType(Tooltip));
      expect(bar, hasLength(_items.length));
      expect(
        bar.map((tooltip) => tooltip.position),
        everyElement(CoreTooltipPosition.top),
      );
    });

    testWidgets('a rail at the left opens it to the right, over the content', (
      tester,
    ) async {
      final at = await hover(tester, alignment: .centerLeft, index: 1);

      expect(at.bubble.left, greaterThanOrEqualTo(at.destination.right));
      // Beside the destination it names — not over the one above or below.
      expect(at.bubble.center.dy, closeTo(at.destination.center.dy, 1));
    });

    testWidgets('a rail at the right opens it to the left instead', (
      tester,
    ) async {
      final at = await hover(tester, alignment: .centerRight, index: 1);

      expect(at.bubble.right, lessThanOrEqualTo(at.destination.left));
      expect(at.bubble.center.dy, closeTo(at.destination.center.dy, 1));
    });
  });

  group('the lens travels down the column', () {
    for (final direction in TextDirection.values) {
      testWidgets('one selection capsule moves and retargets in $direction', (
        tester,
      ) async {
        var selected = 0;
        late StateSetter update;
        await pumpTestApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return NavigationBar(
                mode: .rail,
                items: _items,
                selectedIndex: selected,
                onSelected: (index) => setState(() => selected = index),
                navigationBarStyle: _glass,
              );
            },
          ),
          textDirection: direction,
        );
        final pill = find.byKey(_selectionKey);
        expect(pill, findsOneWidget);
        // At rest the lens is the selected cell.
        expect(tester.getSize(pill), const Size(40, 48));
        expect(tester.getCenter(pill), tester.getCenter(_destination(0)));

        final start = tester.getCenter(pill);
        await tester.tap(_destination(3));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final mid = tester.getCenter(pill);
        // Down the column in either direction, never sideways.
        expect(mid.dy, greaterThan(start.dy));
        expect(mid.dx, closeTo(start.dx, .01));

        update(() => selected = 2);
        await tester.pump();
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(pill).dy,
          closeTo(tester.getCenter(_destination(2)).dy, .1),
        );
        expect(
          tester.getCenter(pill).dx,
          closeTo(tester.getCenter(_destination(2)).dx, .1),
        );
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      });
    }

    for (final reducedMotion in [false, true]) {
      testWidgets(
        'scrubbing tracks down the column and commits once: '
        'reduced=$reducedMotion',
        (tester) async {
          var selected = 0;
          final commits = <int>[];
          await pumpTestApp(
            tester,
            StatefulBuilder(
              builder: (context, setState) => NavigationBar(
                mode: .rail,
                items: _items,
                selectedIndex: selected,
                navigationBarStyle: _glass,
                onSelected: (index) {
                  commits.add(index);
                  setState(() => selected = index);
                },
              ),
            ),
            disableAnimations: reducedMotion,
          );
          final pill = find.byKey(_selectionKey);
          final start = tester.getCenter(_destination(0));
          final end = tester.getCenter(_destination(3));
          final resting = tester.getSize(pill);
          final gesture = await tester.startGesture(start);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 180));
          // Held, the lens swells across the column — past the cell, as it
          // swells above the bar's row.
          expect(
            tester.getSize(pill).width,
            reducedMotion ? resting.width : greaterThan(resting.width),
          );
          await gesture.moveTo(Offset.lerp(start, end, .35)!);
          await tester.pump();
          await _pumpFrames(tester, 5);
          final first = tester.getCenter(pill).dy;
          await gesture.moveTo(Offset.lerp(start, end, .4)!);
          await tester.pump();
          await _pumpFrames(tester, 5);
          expect(tester.getCenter(pill).dy, greaterThan(first));
          expect(commits, isEmpty);
          expect(selected, 0);
          await gesture.moveTo(end);
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();
          expect(commits, [3]);
          expect(tester.getCenter(pill).dy, closeTo(end.dy, .1));
          expect(find.byKey(_lensKey), findsNothing);
          expect(tester.hasRunningAnimations, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('a drag across the column never previews or selects', (
      tester,
    ) async {
      final commits = <int>[];
      await pumpTestApp(
        tester,
        NavigationBar(
          mode: .rail,
          items: _items,
          selectedIndex: 0,
          onSelected: commits.add,
          navigationBarStyle: _glass,
        ),
      );
      final home = tester.getCenter(_destination(0));
      final gesture = await tester.startGesture(home);
      await gesture.moveTo(home + const Offset(120, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(
        tester.getCenter(find.byKey(_selectionKey)).dy,
        closeTo(home.dy, .1),
      );
    });

    testWidgets('edge resistance is smooth and bounded', (tester) async {
      final commits = <int>[];
      await pumpTestApp(
        tester,
        NavigationBar(
          mode: .rail,
          items: _items,
          selectedIndex: 0,
          onSelected: commits.add,
          navigationBarStyle: _glass,
        ),
      );
      final home = tester.getCenter(_destination(0));
      final cell = tester.getCenter(_destination(1)).dy - home.dy;
      double offset() =>
          (tester.getCenter(find.byKey(_selectionKey)).dy - home.dy).abs();
      final gesture = await tester.startGesture(home);
      await gesture.moveTo(home - Offset(0, cell));
      await tester.pumpAndSettle();
      final near = offset();
      await gesture.moveTo(home - Offset(0, cell * 10));
      await tester.pumpAndSettle();
      final far = offset();
      expect(near, greaterThan(0));
      expect(far, greaterThan(near));
      expect(far, lessThan(cell / 2));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(offset(), closeTo(0, .1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a disabled destination is neither grabbed nor committed', (
      tester,
    ) async {
      final commits = <int>[];
      await pumpTestApp(
        tester,
        NavigationBar(
          mode: .rail,
          items: const [
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.house),
              label: 'Home',
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.search),
              label: 'Search',
              enabled: false,
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
          selectedIndex: 0,
          onSelected: commits.add,
          navigationBarStyle: _glass,
        ),
      );
      final home = tester.getCenter(_destination(0));
      final gesture = await tester.startGesture(home);
      await gesture.moveTo(tester.getCenter(_destination(1)));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(
        tester.getCenter(find.byKey(_selectionKey)).dy,
        closeTo(home.dy, .1),
      );
    });

    testWidgets("the capsule's own padding still reaches a destination", (
      tester,
    ) async {
      final commits = <int>[];
      await pumpTestApp(
        tester,
        NavigationBar(
          mode: .rail,
          items: _items,
          selectedIndex: 0,
          onSelected: commits.add,
          navigationBarStyle: _glass,
        ),
      );
      // 2 inside the capsule's leading edge: outside the 40-wide cell,
      // inside the 48 a destination accepts a pointer across.
      final capsule = tester.getRect(find.byType(BackdropFilter));
      final row = tester.getCenter(_destination(2)).dy;
      await tester.tapAt(Offset(capsule.left + 2, row));
      await tester.pumpAndSettle();
      expect(commits, [2]);
    });
  });

  group(
    'where the lens cannot travel the rail keeps its resting selection',
    () {
      Future<void> expectResting(
        WidgetTester tester,
        Widget rail, {
        int selected = 0,
      }) async {
        await pumpTestApp(tester, rail);
        // The scroll view reports whether its column fits after the frame.
        await tester.pump();
        await tester.pump();
        expect(find.byKey(_selectionKey), findsNothing);
        expect(find.byKey(_lensKey), findsNothing);
        // The selected destination paints the selection itself, in the
        // colour the lens rests at.
        final cell = find.descendant(
          of: _destination(selected),
          matching: find.byType(AnimatedContainer),
        );
        final face =
            tester.widget<AnimatedContainer>(cell.first).decoration!
                as BoxDecoration;
        expect(face.color!.a, greaterThan(0));
        // No pill behind the icon: the capsule marks with colour alone.
        final anchors = tester.widgetList<AnimatedContainer>(cell).skip(1);
        for (final anchor in anchors) {
          expect((anchor.decoration! as BoxDecoration).color!.a, 0);
        }
        expect(tester.takeException(), isNull);
      }

      testWidgets('destinations of different heights', (tester) async {
        await expectResting(
          tester,
          NavigationBar(
            mode: .rail,
            items: _items,
            selectedIndex: 0,
            onSelected: (_) {},
            // Only the selected destination grows a caption.
            labelMode: .selected,
            navigationBarStyle: _glass,
          ),
        );
      });

      testWidgets('a header in the column', (tester) async {
        await expectResting(
          tester,
          NavigationBar(
            mode: .rail,
            items: _items,
            selectedIndex: 0,
            onSelected: (_) {},
            header: const SizedBox.square(dimension: 24),
            navigationBarStyle: _glass,
          ),
        );
      });

      testWidgets('a divider among the destinations', (tester) async {
        await expectResting(
          tester,
          NavigationBar(
            mode: .rail,
            items: const [
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.house),
                label: 'Home',
              ),
              CoreNavigationBarItem.divider(),
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.user),
                label: 'Profile',
              ),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
            navigationBarStyle: _glass,
          ),
        );
      });

      testWidgets('a column taller than the rail scrolls instead', (
        tester,
      ) async {
        final commits = <int>[];
        await expectResting(
          tester,
          SizedBox(
            // Room for two of the four destinations.
            height: 132,
            child: NavigationBar(
              mode: .rail,
              items: _items,
              selectedIndex: 0,
              onSelected: commits.add,
              navigationBarStyle: _glass,
            ),
          ),
        );
        // The drag the lens would have taken scrolls the column.
        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scrollable.position.maxScrollExtent, greaterThan(0));
        await tester.drag(_destination(1), const Offset(0, -60));
        await tester.pumpAndSettle();
        expect(scrollable.position.pixels, greaterThan(0));
        expect(commits, isEmpty);
      });
    },
  );

  testWidgets('reduced motion keeps the pane and snaps the selection', (
    tester,
  ) async {
    var selected = 0;
    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => NavigationBar(
          mode: .rail,
          items: _items,
          selectedIndex: selected,
          onSelected: (index) => setState(() => selected = index),
          navigationBarStyle: _glass,
        ),
      ),
      disableAnimations: true,
    );
    await tester.tap(_destination(3));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(
      tester.getCenter(find.byKey(_selectionKey)).dy,
      closeTo(tester.getCenter(_destination(3)).dy, .1),
    );
  });

  testWidgets('reduced transparency keeps the capsule and drops the glass', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      NavigationBar(
        mode: .rail,
        items: _items,
        selectedIndex: 0,
        onSelected: (_) {},
        navigationBarStyle: _glass,
      ),
      theme: const ThemeData(reduceTransparency: true),
      highContrast: true,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    // Still the capsule: the same box, opaque.
    expect(tester.getSize(find.byType(NavigationBar)), const Size(64, 228));
    expect(tester.takeException(), isNull);
  });
}
