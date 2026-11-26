import 'package:coui_flutter/coui_flutter.dart';
import 'package:file_drop/file_drop.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _nodes = [
  CoreTreeNode(
    id: 'root',
    label: 'Workspace',
    expanded: true,
    children: [
      CoreTreeNode(id: 'first', label: 'first.dart'),
      CoreTreeNode(
        id: 'folder',
        label: 'lib',
        expanded: true,
        children: [CoreTreeNode(id: 'nested', label: 'nested.dart')],
      ),
      CoreTreeNode(id: 'last', label: 'last.dart'),
    ],
  ),
];

Widget _host(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: SizedBox(
      width: 400,
      height: 200,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

void main() {
  for (final virtual in [false, true]) {
    testWidgets('hidden roots retain parent drops and row faces ($virtual)', (
      tester,
    ) async {
      CoreTreeDropTarget? placed;
      await tester.pumpWidget(
        _host(
          Tree(
            nodes: _nodes,
            showRoots: false,
            nodeKeyPrefix: 'row',
            selectedId: 'first',
            virtualRowHeight: virtual ? 28 : null,
            virtualViewportHeight: virtual ? 200 : null,
            treeStyle: const CoreTreeStyle(rowSpacing: 8),
            onFilesPlaced: (_, target) => placed = target,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Workspace'), findsNothing);
      final first = find.byKey(const Key('row.first'));
      final folder = find.byKey(const Key('row.folder'));
      final nested = find.byKey(const Key('row.nested'));
      expect(tester.getSize(first).height, 28);
      expect(tester.getTopLeft(folder).dy - tester.getTopLeft(first).dy, 36);
      expect(tester.getTopLeft(nested).dy - tester.getTopLeft(folder).dy, 36);
      expect(tester.getTopLeft(find.text('first.dart')).dx, 44);
      expect(tester.getTopLeft(find.text('nested.dart')).dx, 62);
      final drop = tester.widget<DropTarget>(
        find.ancestor(
          of: first,
          matching: find.byType(DropTarget),
        ),
      );
      drop.onDragDone!(
        DropDoneDetails(
          files: [DropItemFile('/tmp/new.dart')],
          localPosition: const Offset(10, 2),
          globalPosition: const Offset(10, 2),
        ),
      );
      await tester.pumpAndSettle();
      expect(placed?.anchor.id, 'first');
      expect(placed?.directory.id, 'root');
      expect(placed?.position, CoreTreeDropPosition.before);
      expect(placed?.depth, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing root visibility invalidates the virtual row cache', (
    tester,
  ) async {
    Widget build({required bool showRoots}) => _host(
      Tree(
        nodes: _nodes,
        showRoots: showRoots,
        virtualRowHeight: 28,
        virtualViewportHeight: 200,
      ),
    );
    await tester.pumpWidget(build(showRoots: true));
    await tester.pumpAndSettle();
    expect(find.text('Workspace'), findsOneWidget);
    final original = tester.element(find.byType(Tree));
    await tester.pumpWidget(build(showRoots: false));
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(Tree)), same(original));
    expect(find.text('Workspace'), findsNothing);
    expect(find.text('nested.dart'), findsOneWidget);
    await tester.pumpWidget(build(showRoots: true));
    await tester.pumpAndSettle();
    expect(find.text('Workspace'), findsOneWidget);
  });
}
