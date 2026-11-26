import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Menubar', () {
    testWidgets('renders without border', (tester) async {
      await pumpTestApp(
        tester,
        const Menubar(
          border: false,
          menus: [],
        ),
      );

      expect(find.byType(Menubar), findsOneWidget);
    });

    testWidgets('renders with border by default', (tester) async {
      await pumpTestApp(
        tester,
        const Menubar(menus: []),
      );

      expect(find.byType(Menubar), findsOneWidget);
    });

    testWidgets('renders menu labels', (tester) async {
      await pumpTestApp(
        tester,
        const Menubar(
          menus: [
            CoreMenubarMenu(
              label: 'File',
              entries: [
                CoreMenubarEntry.action(label: 'New'),
                CoreMenubarEntry.divider(),
                CoreMenubarEntry.action(label: 'Open'),
              ],
            ),
            CoreMenubarMenu(label: 'Edit'),
          ],
        ),
      );

      expect(find.byType(Menubar), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    // The dropdown is mounted in the app's overlay, outside the bar's own
    // subtree, so a bar that rebuilds with new menus has to reach it
    // explicitly. Web hosts re-sync the portalled panel on every build; this
    // is the Flutter half of that statement.
    testWidgets('swapping the menus re-renders the open dropdown', (
      tester,
    ) async {
      final menus = ValueNotifier<List<CoreMenubarMenu>>(const [
        CoreMenubarMenu(
          label: 'File',
          entries: [
            CoreMenubarEntry.action(label: 'New'),
            CoreMenubarEntry.action(label: 'Open'),
          ],
        ),
      ]);
      addTearDown(menus.dispose);

      await pumpTestApp(
        tester,
        ValueListenableBuilder<List<CoreMenubarMenu>>(
          valueListenable: menus,
          builder: (_, value, _) => Menubar(menus: value),
        ),
      );

      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      menus.value = const [
        CoreMenubarMenu(
          label: 'File',
          entries: [
            CoreMenubarEntry.action(label: 'Save'),
            CoreMenubarEntry.action(label: 'Open'),
          ],
        ),
      ];
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('New'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('menus that shrink under an open dropdown close it', (
      tester,
    ) async {
      // The dropdown reads its menu by index, lazily. A bar that loses the
      // menu a panel is showing must not rebuild that panel against an index
      // that is gone.
      final menus = ValueNotifier<List<CoreMenubarMenu>>(const [
        CoreMenubarMenu(
          label: 'File',
          entries: [CoreMenubarEntry.action(label: 'New')],
        ),
        CoreMenubarMenu(
          label: 'Edit',
          entries: [CoreMenubarEntry.action(label: 'Undo')],
        ),
      ]);
      addTearDown(menus.dispose);

      await pumpTestApp(
        tester,
        ValueListenableBuilder<List<CoreMenubarMenu>>(
          valueListenable: menus,
          builder: (_, value, _) => Menubar(menus: value),
        ),
      );

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);

      menus.value = const [
        CoreMenubarMenu(
          label: 'File',
          entries: [CoreMenubarEntry.action(label: 'New')],
        ),
      ];
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('border property defaults to true', (tester) async {
      const menubar = Menubar(menus: []);

      expect(menubar.border, isTrue);
    });
  });
}
