import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// The count the docs and the canvas show.
const _badge = Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text('3'),
);

const _labels = ['Inbox', 'Search', 'Settings'];

// The bar's own side padding (12 + 12) and an item's padding and label
// spacing.
const _barPaddingHorizontal = 24.0;
const _itemPaddingEnd = 4.0;
const _labelSpacing = 4.0;

/// Three icon-less labelled destinations, the first carrying a count. An
/// icon-less destination has no corner to hang the badge on, so the badge
/// follows the label at the row's end.
Widget _bar({required double width, Key? key}) {
  return SizedBox(
    width: width,
    child: NavigationBar(
      key: key,
      labelMode: CoreNavigationLabelMode.all,
      selectedIndex: 0,
      onSelected: (_) {},
      items: [
        const CoreNavigationBarItem.destination(
          label: 'Inbox',
          badge: KeyedSubtree(key: ValueKey('badge'), child: _badge),
        ),
        for (final label in _labels.skip(1))
          CoreNavigationBarItem.destination(label: label),
      ],
    ),
  );
}

/// Pumps [child] into a tree of its own. The test app's overlay keeps the
/// entries it was first built with, so a second `pumpTestApp` over the same
/// tree would not show the new child.
Future<void> _pumpFresh(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(tester, child);
}

Rect _destinationRect(WidgetTester tester, String label) {
  return tester.getRect(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
}

void main() {
  group('an icon-less destination with a badge in a bar', () {
    testWidgets('lays out without a flex exception once the bar scrolls', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(width: 160));
      await tester.pump();

      // The row of destinations is unbounded in the scroll branch, so a
      // row-end badge cannot ask the label for the leftover width.
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byKey(const ValueKey('badge')), findsOneWidget);
    });

    testWidgets('follows the label inside its own destination when scrolling', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(width: 160));
      await tester.pump();

      final destination = _destinationRect(tester, 'Inbox');
      final badge = tester.getRect(find.byKey(const ValueKey('badge')));
      final label = tester.getRect(find.text('Inbox'));

      expect(tester.takeException(), isNull);
      // One label spacing after the label, and the destination's own end
      // inset after the badge — the destination is exactly as wide as that.
      expect(badge.left, closeTo(label.right + _labelSpacing, 0.01));
      expect(badge.right, closeTo(destination.right - _itemPaddingEnd, 0.01));
    });

    testWidgets('keeps the badge at the destination end when the bar fills', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(width: 1200));
      await tester.pump();

      final destination = _destinationRect(tester, 'Inbox');
      final badge = tester.getRect(find.byKey(const ValueKey('badge')));
      final label = tester.getRect(find.text('Inbox'));

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      // An equal share is wider than the content: the group keeps the start
      // edge and the badge takes the far end.
      expect(badge.right, closeTo(destination.right - _itemPaddingEnd, 0.01));
      expect(badge.left, greaterThan(label.right + _labelSpacing));
    });

    group('the fill-or-scroll decision counts the badge', () {
      late double withBadge;
      late double withoutBadge;

      setUp(() {
        withBadge = 0;
        withoutBadge = 0;
      });

      Future<void> measureNaturalWidths(WidgetTester tester) async {
        // A bar this narrow scrolls, so every destination lays out at its
        // natural width — the badge and the label spacing before it included.
        await _pumpFresh(tester, _bar(width: 100));
        await tester.pump();
        withBadge = [
          for (final label in _labels) _destinationRect(tester, label).width,
        ].reduce((a, b) => a + b);
        final badge = tester.getRect(find.byKey(const ValueKey('badge')));
        withoutBadge = withBadge - _labelSpacing - badge.width;
      }

      testWidgets('scrolls when only the badge pushes the row past the width', (
        tester,
      ) async {
        await measureNaturalWidths(tester);
        expect(withoutBadge, lessThan(withBadge));

        // Room for the labels alone, not for the badge beside the first one.
        final available = (withoutBadge + withBadge) / 2;
        await _pumpFresh(
          tester,
          _bar(width: available + _barPaddingHorizontal, key: UniqueKey()),
        );
        // The first layout of a badge decides without its width: the row
        // fills, and the width the badge reports settles the decision on the
        // frame that follows.
        expect(find.byType(SingleChildScrollView), findsNothing);
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('fills when the row fits with the badge', (tester) async {
        await measureNaturalWidths(tester);

        // One logical pixel to spare: the decision compares sums of
        // fractional widths, and the exact boundary is not under test.
        await _pumpFresh(
          tester,
          _bar(width: withBadge + _barPaddingHorizontal + 1, key: UniqueKey()),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsNothing);
      });
    });
  });
}
