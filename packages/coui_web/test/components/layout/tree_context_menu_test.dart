// Per-node context menu (#5272) on the Web twin. Opening the panel needs a
// browser `contextmenu` event (`universal_web` cannot build one on the VM),
// so this pins the wiring: which rows carry a `ContextMenu`, with whose
// entries, and when it is inert. The open/choose path is pinned on Flutter
// and by the ContextMenu's own tests.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _nodes = [
  CoreTreeNode(
    id: 'lib',
    label: 'lib',
    children: [CoreTreeNode(id: 'lib/a', label: 'a.dart')],
  ),
  CoreTreeNode(id: 'main', label: 'main.dart'),
];

List<ContextMenu> _menus() => [
  for (final element in find.byType(ContextMenu).evaluate())
    element.component as ContextMenu,
];

void main() {
  group('Tree nodeContextMenu', () {
    testComponents("every row carries a ContextMenu with its node's entries", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Tree(
          nodes: _nodes,
          nodeContextMenu: (node) => [
            CoreMenuItem.action('Rename ${node.label}', onPressed: () {}),
          ],
        ),
      );
      await tester.pump();

      final menus = _menus();
      expect(menus, hasLength(2));
      expect(menus.map((menu) => menu.items.single.label), [
        'Rename lib',
        'Rename main.dart',
      ]);
      expect(menus.every((menu) => menu.enabled), isTrue);
    });

    testComponents('a node with no entries keeps an inert wrapper', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Tree(
          nodes: _nodes,
          nodeContextMenu: (node) => node.id == 'main'
              ? const []
              : [CoreMenuItem.action('Rename', onPressed: () {})],
        ),
      );
      await tester.pump();

      final menus = _menus();
      expect(menus, hasLength(2));
      expect(menus.map((menu) => menu.enabled), [true, false]);
    });

    testComponents('without nodeContextMenu no row is wrapped', (tester) async {
      pumpWithTheme(tester, Tree(nodes: _nodes, onNodeSelect: (_) {}));
      await tester.pump();

      expect(find.byType(ContextMenu), findsNothing);
    });

    testComponents('the row being renamed has an inert wrapper', (
      tester,
    ) async {
      final controller = CoreTreeController();
      pumpWithTheme(
        tester,
        Tree(
          nodes: _nodes,
          controller: controller,
          onNodeRename: (_, _) {},
          nodeContextMenu: (node) => [
            CoreMenuItem.action('Rename', onPressed: () {}),
          ],
        ),
      );
      await tester.pump();

      controller.startRename('main');
      await tester.pump();

      expect(find.byType(TextField), findsOneComponent);
      expect(_menus().map((menu) => menu.enabled), [true, false]);
    });
  });
}
