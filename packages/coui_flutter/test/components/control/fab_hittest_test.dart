import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Fab speed-dial hit-testing', () {
    testWidgets('an expanded action fires onPressed when tapped', (
      tester,
    ) async {
      var editTapped = false;
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          onPressed: () {},
          actions: [
            FabAction(
              icon: const Icon(LucideIcons.pencil),
              label: const Text('Edit'),
              onPressed: () => editTapped = true,
            ),
            const FabAction(
              icon: Icon(LucideIcons.share2),
              label: Text('Share'),
            ),
          ],
        ),
      );

      // Open the speed dial (tap the main FAB).
      //
      // Finite pumps instead of `pumpAndSettle`: the expanded actions now
      // render in a composed `Popover` overlay, whose shared overlay engine
      // runs a `follow` re-anchor ticker that keeps a frame perpetually
      // scheduled while open — so `pumpAndSettle` never settles for any open
      // popover (Select behaves identically). One pump mounts the panel; the
      // second advances past the entrance animation so the action settles at
      // its hit-testable resting position.
      await tester.tap(find.byType(Fab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Locate the 'Edit' action's menu row (the label is its child).
      final editLabel = find.text('Edit');
      expect(editLabel, findsOneWidget, reason: 'action label should render');
      final editButton = find
          .ancestor(of: editLabel, matching: find.byType(MenuItem))
          .first;
      expect(editButton, findsOneWidget, reason: 'action row should render');

      // Tap it — this fails (warns "missed") if the action lies outside the
      // hit region. Hosting the actions in the overlay layer keeps them
      // hit-testable regardless of the FAB button's own bounds.
      await tester.tap(editButton);
      await tester.pump();

      expect(
        editTapped,
        isTrue,
        reason: 'expanded speed-dial action must be tappable / hit-testable',
      );
    });

    testWidgets('re-tapping the main FAB closes the open speed dial', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          onPressed: () {},
          actions: const [
            FabAction(
              icon: Icon(LucideIcons.pencil),
              label: Text('Edit'),
            ),
            FabAction(
              icon: Icon(LucideIcons.share2),
              label: Text('Share'),
            ),
          ],
        ),
      );

      // Open the speed dial.
      await tester.tap(find.byType(Fab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Edit'), findsOneWidget, reason: 'speed dial opened');

      // Re-tap the main FAB. The trigger now lives inside the panel's
      // `TapRegion` group, so this does NOT fire an outside-tap dismiss that
      // would race the toggle and re-open it — it just closes.
      await tester.tap(find.byType(Fab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Edit'),
        findsNothing,
        reason:
            're-tapping the trigger must close (not re-open) the speed dial',
      );
    });
  });
}
