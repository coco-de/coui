import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// Bare-label tabs — the bar the selection mark was added for.
const _items = [
  CoreNavigationBarItem<Widget>.destination(label: 'Home'),
  CoreNavigationBarItem<Widget>.destination(label: 'Search'),
  CoreNavigationBarItem<Widget>.destination(label: 'Profile'),
];

NavigationBar _bar({
  CoreNavigationSelectionMark selectionMark = CoreNavigationSelectionMark.dot,
  CoreNavigationBarMode mode = CoreNavigationBarMode.bar,
  int selectedIndex = 0,
  CoreValueChanged<int>? onSelected,
  CoreNavigationBarStyle? navigationBarStyle,
  List<CoreNavigationBarItem<Widget>> items = _items,
}) {
  return NavigationBar(
    items: items,
    selectedIndex: selectedIndex,
    onSelected: onSelected,
    mode: mode,
    labelMode: CoreNavigationLabelMode.all,
    selectionMark: selectionMark,
    navigationBarStyle: navigationBarStyle,
  );
}

/// The dot of the destination whose label is [label].
Finder _dotOf(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(Clickable),
  ),
  matching: find.byType(Badge),
);

/// The fade around the dot of the destination whose label is [label].
AnimatedOpacity _fadeOf(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: _dotOf(label), matching: find.byType(AnimatedOpacity)),
);

void main() {
  group('NavigationBar selectionMark', () {
    testWidgets('none draws no mark — the bar it was before', (tester) async {
      await pumpTestApp(
        tester,
        _bar(selectionMark: CoreNavigationSelectionMark.none),
      );
      final fadesWithout = find.byType(AnimatedOpacity).evaluate().length;
      final labelTop = tester.getTopLeft(find.text('Home')).dy;

      expect(find.byType(Badge), findsNothing);

      // The dot adds exactly its own fade per destination and nothing else.
      // (The harness overlay keeps its first entry, so the tree is torn
      // down before the second bar goes in.)
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpTestApp(tester, _bar());
      expect(
        find.byType(AnimatedOpacity).evaluate().length,
        fadesWithout + _items.length,
      );
      // …and the room it takes is the only thing that moves the label.
      expect(
        tester.getTopLeft(find.text('Home')).dy,
        isNot(labelTop),
      );
    });

    testWidgets('dot: every destination keeps the room, one shows it', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar());

      for (final label in ['Home', 'Search', 'Profile']) {
        expect(_dotOf(label), findsOneWidget, reason: label);
      }
      expect(_fadeOf(tester, 'Home').opacity, 1);
      expect(_fadeOf(tester, 'Search').opacity, 0);
      expect(_fadeOf(tester, 'Profile').opacity, 0);

      // The labels stay level: the hidden dots still take their room.
      final homeTop = tester.getTopLeft(find.text('Home')).dy;
      expect(tester.getTopLeft(find.text('Search')).dy, homeTop);
      expect(tester.getTopLeft(find.text('Profile')).dy, homeTop);
    });

    testWidgets('the dot is 4 across and 6 above its label', (tester) async {
      await pumpTestApp(tester, _bar());

      expect(tester.getSize(_dotOf('Home')), const Size.square(4));
      final dot = tester.getRect(_dotOf('Home'));
      final label = tester.getRect(find.text('Home'));
      expect(label.top - dot.bottom, CoreSpace.space6);
      // Centred over the label.
      expect(dot.center.dx, moreOrLessEquals(label.center.dx));
    });

    testWidgets('the dot reads in the selected label colour', (tester) async {
      await pumpTestApp(tester, _bar());

      final badge = tester.widget<Badge>(_dotOf('Home'));
      expect(badge.form, CoreBadgeForm.dot);
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: _dotOf('Home'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final label = tester.widget<Text>(find.text('Home'));
      expect((box.decoration! as BoxDecoration).color, label.style!.color);
    });

    testWidgets('the fade runs on the selection clock', (tester) async {
      var selected = 0;
      await pumpTestApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => _bar(
            selectedIndex: selected,
            onSelected: (index) => setState(() => selected = index),
          ),
        ),
      );

      final fade = _fadeOf(tester, 'Home');
      expect(fade.duration, CoreNavigationBarStyle.defaultDuration);
      // The destination's own colour change rides the same curve.
      for (final t in [0.25, 0.5, 0.75]) {
        expect(fade.curve.transform(t), CoreEasing.move.toValue().transform(t));
      }

      await tester.tap(find.text('Search'));
      await tester.pump();
      await tester.pump(CoreNavigationBarStyle.defaultDuration ~/ 2);
      final halfway = tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byWidget(_fadeOf(tester, 'Search')),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value;
      expect(halfway, inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(_fadeOf(tester, 'Search').opacity, 1);
      expect(_fadeOf(tester, 'Home').opacity, 0);
    });

    testWidgets('reduced motion swaps the dot at once', (tester) async {
      await pumpTestApp(tester, _bar(), disableAnimations: true);

      expect(_fadeOf(tester, 'Home').duration, Duration.zero);
    });

    testWidgets('the mark adds nothing to the destination name', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTestApp(tester, _bar());

      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: _dotOf('Home'),
            matching: find.byType(ExcludeSemantics),
          ),
          matching: find.byType(Badge),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a row — the sidebar — draws no mark', (tester) async {
      await pumpTestApp(
        tester,
        SizedBox(
          width: 240,
          height: 400,
          child: _bar(mode: CoreNavigationBarMode.sidebar),
        ),
      );

      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('the rail stacks its labels, so it takes the mark', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        SizedBox(height: 400, child: _bar(mode: CoreNavigationBarMode.rail)),
      );

      expect(_dotOf('Home'), findsOneWidget);
    });

    testWidgets('the nested slots reach the dot and the gap', (tester) async {
      await pumpTestApp(
        tester,
        _bar(
          navigationBarStyle: const CoreNavigationBarStyle(
            selectionMarkStyle: CoreBadgeStyle(
              backgroundColor: CoreColor.token(CoreColors.error),
            ),
            selectionMarkGapStyle: CoreGapStyle(size: CoreSpace.space8),
          ),
        ),
      );

      final badge = tester.widget<Badge>(_dotOf('Home'));
      expect(
        badge.badgeStyle?.backgroundColor,
        const CoreColor.token(CoreColors.error),
      );
      // The default dot size stays under the caller's colour.
      expect(badge.badgeStyle?.dotSize, CoreSize.size4);
      final dot = tester.getRect(_dotOf('Home'));
      final label = tester.getRect(find.text('Home'));
      expect(label.top - dot.bottom, CoreSpace.space8);
    });

    testWidgets('a theme-wide style reaches the dot', (tester) async {
      await pumpTestApp(
        tester,
        _bar(),
        componentTheme: const CoreComponentTheme(
          navigationBar: CoreNavigationBarTheme(
            style: CoreNavigationBarStyle(
              selectionMarkStyle: CoreBadgeStyle(dotSize: CoreSize.size6),
            ),
          ),
        ),
      );

      expect(tester.getSize(_dotOf('Home')), const Size.square(6));
    });

    testWidgets('the glass bar takes its own selection colour', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        _bar(),
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
      );

      expect(
        tester.widget<Badge>(_dotOf('Home')).badgeStyle?.backgroundColor,
        CoreNavigationBarStyle
            .glassBarStyle
            .selectionMarkStyle
            ?.backgroundColor,
      );
    });
  });
}
