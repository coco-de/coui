import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kGapSize = 16.0;

/// The nearest `menu` / `menuBar` role above [finder]'s semantics node — how
/// a screen reader finds the menu a row belongs to.
SemanticsRole? _roleAbove(WidgetTester tester, Finder finder) {
  for (
    var node = tester.getSemantics(finder).parent;
    node != null;
    node = node.parent
  ) {
    final role = node.getSemanticsData().role;
    if (role == SemanticsRole.menu || role == SemanticsRole.menuBar) {
      return role;
    }
  }

  return null;
}

void main() {
  group('CoreMenuItem', () {
    test('action factory has the action kind', () {
      const item = CoreMenuItem<Widget>.action('Action');

      expect(item.kind, CoreMenuItemKind.action);
      expect(item.label, 'Action');
    });

    test('label factory has the label kind', () {
      const item = CoreMenuItem<Widget>.label('Heading');

      expect(item.kind, CoreMenuItemKind.label);
    });

    test('divider factory has the divider kind', () {
      const item = CoreMenuItem<Widget>.divider();

      expect(item.kind, CoreMenuItemKind.divider);
    });

    test('gap factory has the gap kind', () {
      const item = CoreMenuItem<Widget>.gap(_kGapSize);

      expect(item.kind, CoreMenuItemKind.gap);
    });
  });

  group('Menu', () {
    testWidgets('renders action item label', (tester) async {
      await pumpTestApp(
        tester,
        const Menu(
          items: [CoreMenuItem<Widget>.action('Open')],
        ),
      );

      expect(find.byType(Menu), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('renders an action item keyboard-shortcut hint', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Menu(
          items: [CoreMenuItem<Widget>.action('Save', shortcut: 'Ctrl+S')],
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Ctrl+S'), findsOneWidget);
    });

    testWidgets('renders mixed items (label/action/divider/gap)', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Menu(
          items: [
            CoreMenuItem<Widget>.label('Section'),
            CoreMenuItem<Widget>.action('First'),
            CoreMenuItem<Widget>.divider(),
            CoreMenuItem<Widget>.gap(_kGapSize),
            CoreMenuItem<Widget>.action('Second'),
          ],
        ),
      );

      expect(find.byType(Menu), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('action onPressed fires on tap', (tester) async {
      var pressed = false;

      await pumpTestApp(
        tester,
        Menu(
          items: [
            CoreMenuItem<Widget>.action(
              'Tap me',
              onPressed: () => pressed = true,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Tap me'));
      final _ = await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('onActivate fires close-first on action, not on toggle', (
      tester,
    ) async {
      // L2-pre: the shared `Menu` exposes `onActivate` so an overlay host
      // (DropdownMenu / ContextMenu / Menubar) can dismiss on select
      // without re-rolling its own row renderer. Actions fire it
      // close-first (before their own `onPressed`); toggles keep the menu
      // open and never fire it.
      final calls = <String>[];

      await pumpTestApp(
        tester,
        Menu(
          items: [
            CoreMenuItem<Widget>.action(
              'Run',
              onPressed: () => calls.add('pressed'),
            ),
            CoreMenuItem<Widget>.checkbox(
              'Toggle',
              onChanged: (_) => calls.add('changed'),
            ),
          ],
          onActivate: () => calls.add('activate'),
        ),
      );

      // The row handlers fire synchronously on tap (no animation), so the
      // recorded order is asserted straight after the tap.
      await tester.tap(find.text('Run'));
      expect(calls, ['activate', 'pressed']);

      calls.clear();
      await tester.tap(find.text('Toggle'));
      expect(calls, ['changed']);
    });

    testWidgets('renders horizontally when vertical is false', (tester) async {
      await pumpTestApp(
        tester,
        const Menu(
          items: [CoreMenuItem<Widget>.action('Horizontal')],
          vertical: false,
        ),
      );

      expect(find.byType(Menu), findsOneWidget);
    });
  });

  group('Menu group title', () {
    testWidgets('reads onSurfaceSubtle at 12 Medium', (tester) async {
      late Color subtle;
      late Color variant;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            subtle = scheme
                .resolve(const CoreColor.token(CoreColors.onSurfaceSubtle))
                .toValue();
            variant = scheme
                .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
                .toValue();
            return const Menu(
              items: [
                CoreMenuItem<Widget>.label('Navigation'),
                CoreMenuItem<Widget>.action('Home'),
              ],
            );
          },
        ),
      );

      final style = tester.widget<Text>(find.text('Navigation')).style!;
      expect(style.color, subtle);
      expect(style.color, isNot(variant));
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w500);
    });

    testWidgets('keeps 8 above the row inset and only 4 below', (
      tester,
    ) async {
      late ResolvedMenu resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveMenu(context);

            return const SizedBox.shrink();
          },
        ),
      );

      // Top and sides are the default (sm) row's (6 · 8); the bottom is the
      // heading's own.
      expect(resolved.labelPadding, const EdgeInsets.fromLTRB(8, 6, 8, 4));
    });

    testWidgets('follows the row ladder of the size the menu is given', (
      tester,
    ) async {
      late ResolvedMenu resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveMenu(context, size: CoreMenuItemSize.md);

            return const SizedBox.shrink();
          },
        ),
      );

      // The md row's insets (10 · 8); the bottom is still the heading's own.
      expect(resolved.labelPadding, const EdgeInsets.fromLTRB(10, 8, 10, 4));
    });
  });

  group('Menu divider entry', () {
    testWidgets('keeps 4 above and below the rule in a column', (tester) async {
      late ResolvedMenu resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveMenu(context);

            return const SizedBox.shrink();
          },
        ),
      );

      expect(resolved.dividerPadding, const EdgeInsets.symmetric(vertical: 4));
    });

    testWidgets('a bar keeps its dividers flush', (tester) async {
      late ResolvedMenu resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveMenu(context, vertical: false);

            return const SizedBox.shrink();
          },
        ),
      );

      expect(resolved.dividerPadding, EdgeInsets.zero);
    });

    testWidgets('the rows either side of a divider sit 13 apart', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Menu(
          items: [
            CoreMenuItem<Widget>.action('Above'),
            CoreMenuItem<Widget>.divider(),
            CoreMenuItem<Widget>.action('Below'),
          ],
        ),
      );

      final rows = find.byType(MenuItem);
      final above = tester.getRect(rows.at(0));
      final below = tester.getRect(rows.at(1));
      // The panel's 2 gap, the 4 inset, the 1px rule, the 4 inset, the 2 gap.
      expect(below.top - above.bottom, moreOrLessEquals(13, epsilon: 0.01));
    });
  });

  group('Menu (interactions)', () {
    List<CoreMenuItem<Widget>> buildItems() => [
      const CoreMenuItem.label('Navigation'),
      CoreMenuItem.action('Home', onPressed: () {}, active: true),
      CoreMenuItem.action('About', onPressed: () {}),
      const CoreMenuItem.action('Contact', disabled: true),
    ];

    testWidgets('renders every item label', (tester) async {
      await pumpTestApp(tester, Menu(items: buildItems()));

      expect(find.text('Navigation'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
    });

    testWidgets('fires onPressed for an interactive action item', (
      tester,
    ) async {
      var tapped = false;
      await pumpTestApp(
        tester,
        Menu(
          items: [
            const CoreMenuItem.label('Navigation'),
            CoreMenuItem.action('Home', onPressed: () => tapped = true),
          ],
        ),
      );

      await tester.tap(find.text('Home'));
      final _ = await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('does not fire onPressed for a disabled action item', (
      tester,
    ) async {
      var tapped = false;
      await pumpTestApp(
        tester,
        Menu(
          items: [
            CoreMenuItem.action(
              'Contact',
              onPressed: () => tapped = true,
              disabled: true,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Contact'), warnIfMissed: false);
      final _ = await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets('toggles a checkbox item with the next value', (
      tester,
    ) async {
      bool? next;
      await pumpTestApp(
        tester,
        Menu(
          items: [
            CoreMenuItem.checkbox(
              'Show grid',
              onChanged: (value) => next = value,
              checked: true,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Show grid'));
      final _ = await tester.pumpAndSettle();

      expect(next, isFalse);
    });

    testWidgets('renders an inline submenu for action items', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Menu(
          items: [
            CoreMenuItem.action(
              'More',
              submenu: [
                CoreMenuItem.action('Settings', onPressed: () {}),
              ],
            ),
          ],
        ),
      );

      expect(find.text('More'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('lays out horizontally when vertical is false', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Menu(items: buildItems(), vertical: false),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('exposes ariaLabel through Semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTestApp(
        tester,
        Menu(items: buildItems(), ariaLabel: 'Main navigation'),
      );

      // The name sits on the node that is the menu — the rendered tree, not
      // what the widget declares.
      final named = tester.getSemantics(
        find.bySemanticsLabel('Main navigation'),
      );
      expect(named.getSemanticsData().role, SemanticsRole.menu);
      handle.dispose();
    });

    testWidgets('is a menu to a screen reader with no name too', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTestApp(tester, Menu(items: buildItems()));

      // A row is a menu item only inside a menu: an unnamed menu that said
      // nothing would leave every row announcing as a loose command.
      expect(_roleAbove(tester, find.text('Home')), SemanticsRole.menu);
      handle.dispose();
    });

    testWidgets('is a menubar when it runs horizontally', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTestApp(tester, Menu(items: buildItems(), vertical: false));

      expect(_roleAbove(tester, find.text('Home')), SemanticsRole.menuBar);
      handle.dispose();
    });
  });
}
