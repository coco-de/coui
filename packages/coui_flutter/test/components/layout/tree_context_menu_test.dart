// Per-node context menu (#5272) — a row's right-click shows that node's
// entries at the pointer with the unified `ContextMenu`.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kTreeWidth = 400.0;
const _kTreeHeight = 400.0;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kTreeWidth,
      height: _kTreeHeight,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

const _nodes = [
  CoreTreeNode(id: 'main', label: 'main.dart'),
  CoreTreeNode(
    id: 'lib',
    label: 'lib',
    children: [CoreTreeNode(id: 'lib/a', label: 'a.dart')],
  ),
];

// An open panel follows its trigger on a perpetual ticker (`follow: true`),
// so `pumpAndSettle` never settles — pump the open/close transition instead,
// as the ContextMenu tests do.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _rightClick(WidgetTester tester, Finder target) async {
  final gesture = await tester.startGesture(
    tester.getCenter(target),
    buttons: kSecondaryButton,
  );
  await gesture.up();
  await _settle(tester);
}

void main() {
  group('Tree nodeContextMenu', () {
    testWidgets(
      "a right-click shows that node's entries and runs the chosen one",
      (tester) async {
        final chosen = <String?>[];
        final selected = <String?>[];

        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: _nodes,
              onNodeSelect: (node) => selected.add(node.id),
              nodeContextMenu: (node) => [
                CoreMenuItem.action(
                  'Rename ${node.label}',
                  onPressed: () => chosen.add(node.id),
                ),
              ],
            ),
          ),
        );

        await _rightClick(tester, find.text('main.dart'));
        expect(find.text('Rename main.dart'), findsOneWidget);
        expect(selected, isEmpty, reason: 'a right-click does not select');

        await tester.tap(find.text('Rename main.dart'));
        await _settle(tester);

        expect(chosen, ['main']);
        expect(find.text('Rename main.dart'), findsNothing);
      },
    );

    testWidgets('a right-click on a folder neither selects nor opens it', (
      tester,
    ) async {
      final toggled = <String?>[];

      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: _nodes,
            selectFolders: true,
            toggleFoldersOnSelect: true,
            onNodeSelect: (_) {},
            onNodeToggle: (node) => toggled.add(node.id),
            nodeContextMenu: (node) => [
              CoreMenuItem.action('Rename', onPressed: () {}),
            ],
          ),
        ),
      );

      await _rightClick(tester, find.text('lib'));

      expect(find.text('Rename'), findsOneWidget);
      expect(toggled, isEmpty);
      expect(find.text('a.dart'), findsNothing);
    });

    testWidgets('a node with no entries has no menu', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: _nodes,
            nodeContextMenu: (node) => node.id == 'main'
                ? const []
                : [CoreMenuItem.action('Rename', onPressed: () {})],
          ),
        ),
      );

      await _rightClick(tester, find.text('main.dart'));
      expect(find.text('Rename'), findsNothing);

      await _rightClick(tester, find.text('lib'));
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets(
      'a double-tap still renames a row that has a menu, and the field has '
      'no menu',
      (tester) async {
        final built = <String?>[];

        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: _nodes,
              onNodeRename: (_, _) {},
              nodeContextMenu: (node) {
                built.add(node.id);
                return [CoreMenuItem.action('Rename', onPressed: () {})];
              },
            ),
          ),
        );

        await tester.tap(find.text('main.dart'));
        await tester.pump();
        await tester.tap(find.text('main.dart'));
        await tester.pump();
        await tester.pump();

        expect(find.byType(EditableText), findsOneWidget);
        built.clear();
        await _rightClick(tester, find.byType(EditableText));

        expect(find.text('Rename'), findsNothing);
        expect(
          built,
          isNot(contains('main')),
          reason: 'the renamed row does not ask for entries',
        );
      },
    );
  });
}
