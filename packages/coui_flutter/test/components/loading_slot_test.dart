import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' hide Icon, Table;
import 'package:flutter_test/flutter_test.dart';

/// Whether the tree renders a skeleton and no real content.
///
/// Both halves matter. A loading state that renders the skeleton *and*
/// the value is not a loading state — it is the content with something
/// flickering behind it, which is the shape the deleted Web wrapper had.
Future<void> _expectSkeletonOnly(
  WidgetTester tester,
  Widget child, {
  required String absent,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 360, child: child)),
    ),
  );
  // `pump`, not `pumpAndSettle`: the pulse loops rather than finishing,
  // which is deliberate — a stopped skeleton is indistinguishable from a
  // loaded one, so it is display tier and never settles.
  await tester.pump(const Duration(milliseconds: 16));

  expect(find.byType(Skeleton), findsWidgets);
  expect(find.text(absent), findsNothing);
}

void main() {
  group('the components this was raised about already take a skeleton', () {
    // The issue asked for a `loading` slot on the components that hold
    // asynchronous content. Measured against the standard, none of them
    // needs one: each takes its content through a widget slot, so the
    // caller substitutes a skeleton in the place the value would go.
    //
    // A slot would be a second path doing the same thing, named and
    // behaved differently per component — the divergence the standard
    // exists to prevent. This is the check that the first path actually
    // works, on the exact components that were in doubt.
    testWidgets('a table row', (tester) async {
      // The hardest of the five: the caller has to produce the row
      // structure, not just one value. It can, because the row and cell
      // types take widgets.
      await _expectSkeletonOnly(
        tester,
        Table(
          rows: const [
            CoreTableRowData<Widget>(
              cells: [
                CoreTableCellData<Widget>(child: Skeleton(width: 80)),
                CoreTableCellData<Widget>(child: Skeleton(width: 40)),
              ],
            ),
          ],
        ),
        absent: '1,240',
      );
    });

    testWidgets('a listing item', (tester) async {
      await _expectSkeletonOnly(
        tester,
        const Listing(children: [Skeleton(width: 200)]),
        absent: 'Order #1',
      );
    });

    testWidgets('a card body', (tester) async {
      await _expectSkeletonOnly(
        tester,
        const Card(body: Skeleton(width: 200)),
        absent: 'Revenue',
      );
    });

    testWidgets('an avatar', (tester) async {
      // Avatar takes `imageUrl` / `initials` as data, which cannot hold a
      // skeleton — but it also takes a `child`, and that is the slot.
      await _expectSkeletonOnly(
        tester,
        const Avatar(child: Skeleton(width: 40, height: 40)),
        absent: 'AB',
      );
    });

    testWidgets('a chat bubble', (tester) async {
      await _expectSkeletonOnly(
        tester,
        const Chat(bubble: Skeleton(width: 180)),
        absent: 'Hello',
      );
    });
  });

  group('the skeleton keeps the shape the caller stated', () {
    testWidgets('the stated size is what is honoured', (tester) async {
      // Why the caller supplies the tree rather than the component
      // guessing: only the caller knows what the arriving content will
      // occupy. A skeleton that guesses wrong makes the layout jump when
      // the value lands.
      //
      // Asserted as a ratio, not an absolute. The rendered size is the
      // stated size times the theme's uniform scale — a mobile theme
      // scales everything by 1.25 — so pinning pixels would be pinning
      // the platform default rather than the contract.
      Future<Size> render(double width, double height) async {
        await tester.pumpWidget(
          CoUIApp(
            theme: ThemeData.fromCore(CoreThemePresets.light),
            home: Align(
              child: SizedBox(
                width: 360,
                child: Card(
                  body: Skeleton(width: width, height: height),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));

        return tester.getSize(find.byType(Skeleton));
      }

      final small = await render(100, 12);
      final large = await render(200, 24);

      expect(large.width / small.width, 2.0);
      expect(large.height / small.height, 2.0);
    });
  });
}
