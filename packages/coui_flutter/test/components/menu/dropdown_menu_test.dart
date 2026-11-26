import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: material.Center(child: child)),
  ),
);

/// Settles pending animations, discarding the frame count so call
/// sites stay free of `avoid-ignoring-return-values` noise.
Future<void> _settle(WidgetTester tester) async {
  final frames = await tester.pumpAndSettle();
  expect(frames, greaterThanOrEqualTo(0));
}

void main() {
  group('DropdownMenu widget (Button item rendering)', () {
    // A plain trigger so the dropdown's own
    // `GestureDetector(onTap: _handleToggle)` reliably receives the tap
    // (a `Button` trigger would win the gesture arena itself). The
    // entry rendering under test is independent of the trigger.
    Widget buildMenu({void Function(String)? onSelect}) => DropdownMenu(
      trigger: const Text('Open'),
      items: [
        CoreMenuItem.action(
          'Profile',
          shortcut: 'Ctrl+P',
          onPressed: () => onSelect?.call('Profile'),
        ),
        const CoreMenuItem.divider(),
        CoreMenuItem.action(
          'Disabled',
          disabled: true,
          onPressed: () => onSelect?.call('Disabled'),
        ),
      ],
    );

    testWidgets('opens and renders entries as buttons without layout '
        'exception', (tester) async {
      await tester.pumpWidget(_buildApp(buildMenu()));
      await _settle(tester);

      await tester.tap(find.text('Open'));
      await _settle(tester);

      // The key regression check — an `expanded` Button inside the
      // popup panel must not blow up under the panel's width
      // constraints.
      expect(tester.takeException(), isNull);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Ctrl+P'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('tapping an enabled entry fires onSelect and closes', (
      tester,
    ) async {
      final selections = <String>[];
      await tester.pumpWidget(
        _buildApp(buildMenu(onSelect: selections.add)),
      );
      await _settle(tester);

      await tester.tap(find.text('Open'));
      await _settle(tester);

      await tester.tap(find.text('Profile'));
      await _settle(tester);

      expect(selections, ['Profile']);
      expect(find.text('Profile'), findsNothing);
    });

    testWidgets('tapping a disabled entry does not fire onSelect', (
      tester,
    ) async {
      final selections = <String>[];
      await tester.pumpWidget(
        _buildApp(buildMenu(onSelect: selections.add)),
      );
      await _settle(tester);

      await tester.tap(find.text('Open'));
      await _settle(tester);

      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      await _settle(tester);

      expect(selections, isEmpty);
    });
  });

  group('DropdownMenu interactive trigger (gesture arena)', () {
    // Regression: a `Button` trigger is itself interactive (Clickable).
    // A wrapping `GestureDetector` used to lose the gesture arena to it, so
    // the menu never opened. The trigger is now wrapped in a non-competing
    // `TriggerTapDetector` (Listener), mirroring Web DOM bubbling.
    testWidgets('opens when the trigger is a Button', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          DropdownMenu(
            trigger: Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: const material.Text('Open Menu'),
            ),
            items: [
              CoreMenuItem.action('Profile', onPressed: () {}),
            ],
          ),
        ),
      );
      await _settle(tester);

      expect(find.text('Profile'), findsNothing);

      await tester.tap(find.text('Open Menu'));
      await _settle(tester);

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('does NOT open on a secondary (right) click', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          DropdownMenu(
            trigger: const material.Text('Open Menu'),
            items: [
              CoreMenuItem.action('Profile', onPressed: () {}),
            ],
          ),
        ),
      );
      await _settle(tester);

      // Right-click is the context-menu's gesture — the dropdown's
      // `TriggerTapDetector` must ignore non-primary presses.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Open Menu')),
        buttons: kSecondaryButton,
      );
      await gesture.up();
      await _settle(tester);

      expect(find.text('Profile'), findsNothing);
    });
  });

  group('DropdownMenu follows its host while open', () {
    // The panel is mounted in the app's `Overlay`, outside the host's own
    // subtree, so a host that rebuilds with new items has to reach it
    // explicitly. Web hosts re-sync the portalled panel on every build; this
    // is the Flutter half of that statement.
    testWidgets('swapping the items re-renders the open panel', (tester) async {
      final items = ValueNotifier<List<CoreMenuItem<Widget>>>([
        CoreMenuItem.action('Sort 5s', onPressed: () {}),
        CoreMenuItem.action('Sort 10s', onPressed: () {}),
      ]);
      addTearDown(items.dispose);

      await tester.pumpWidget(
        _buildApp(
          ValueListenableBuilder<List<CoreMenuItem<Widget>>>(
            valueListenable: items,
            builder: (_, value, _) =>
                DropdownMenu(trigger: const Text('Open'), items: value),
          ),
        ),
      );
      await _settle(tester);

      await tester.tap(find.text('Open'));
      await _settle(tester);
      expect(find.text('Sort 5s'), findsOneWidget);
      expect(find.text('Sort 10s'), findsOneWidget);

      items.value = [
        CoreMenuItem.action('Sort 4s', onPressed: () {}),
        CoreMenuItem.action('Sort 10s', onPressed: () {}),
      ];
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Sort 4s'), findsOneWidget);
      expect(find.text('Sort 5s'), findsNothing);
      expect(find.text('Sort 10s'), findsOneWidget);
    });
  });

  group('DropdownMenu controller (imperative open/close)', () {
    testWidgets('controller.show opens, close closes, isOpen tracks', (
      tester,
    ) async {
      final controller = PopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          DropdownMenu(
            controller: controller,
            trigger: const Text('Trigger'),
            items: [
              CoreMenuItem.action('Profile', onPressed: () {}),
            ],
          ),
        ),
      );
      await _settle(tester);

      expect(controller.isOpen, isFalse);
      expect(find.text('Profile'), findsNothing);

      controller.show();
      await _settle(tester);

      expect(controller.isOpen, isTrue);
      expect(find.text('Profile'), findsOneWidget);

      controller.close();
      await _settle(tester);

      expect(controller.isOpen, isFalse);
      expect(find.text('Profile'), findsNothing);
    });
  });
}
