import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

const _nodes = [
  CoreTreeNode(
    id: 'root',
    label: 'Workspace',
    expanded: true,
    children: [
      CoreTreeNode(id: 'first', label: 'first.dart'),
      CoreTreeNode(id: 'last', label: 'last.dart'),
    ],
  ),
];

void main() {
  testServer('promoted children from multiple roots have one sibling set', (
    tester,
  ) async {
    tester.pumpComponent(
      CoUIWeb(
        theme: .coui,
        child: const Tree(
          showRoots: false,
          nodes: [
            ..._nodes,
            CoreTreeNode(
              id: 'other',
              label: 'Other',
              expanded: true,
              children: [CoreTreeNode(id: 'third', label: 'third.dart')],
            ),
          ],
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    final rows = document.querySelectorAll('[role="treeitem"]');
    expect(rows.map((row) => row.attributes['aria-posinset']), ['1', '2', '3']);
    expect(rows.map((row) => row.attributes['aria-setsize']), ['3', '3', '3']);
    expect(rows.map((row) => row.attributes['aria-level']), ['1', '1', '1']);
  });

  testServer('hidden roots keep root-level drop targets and accessible depth', (
    tester,
  ) async {
    tester.pumpComponent(
      CoUIWeb(
        theme: .coui,
        child: Tree(
          nodes: _nodes,
          showRoots: false,
          treeStyle: const CoreTreeStyle(rowSpacing: 8),
          onNodeDrop: (_, _) {},
          onFilesDroppedOnNode: (_, _) {},
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    final rows = document.querySelectorAll('[role="treeitem"]');
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.attributes['aria-level']), ['1', '1']);
    expect(document.querySelector(r'#tree-node\.root'), isNull);
    expect(document.querySelectorAll('[aria-dropeffect]'), hasLength(2));
    expect(
      document.querySelectorAll('[data-tree-file-drop-over]'),
      hasLength(2),
    );
    final gaps = document.querySelectorAll('[data-tree-spacing]');
    expect(gaps, hasLength(1));
    expect(
      gaps.single.attributes['style']!.replaceAll(' ', ''),
      contains('padding-bottom:var(--coui-space-8)'),
    );
  });

  testServer('defaults retain the root and introduce no spacing wrappers', (
    tester,
  ) async {
    tester.pumpComponent(
      CoUIWeb(
        theme: .coui,
        child: const Tree(nodes: _nodes),
      ),
    );
    final document = (await tester.request('/')).document!;
    expect(document.querySelectorAll('[role="treeitem"]'), hasLength(3));
    expect(document.querySelector(r'#tree-node\.root'), isNotNull);
    expect(document.querySelectorAll('[data-tree-spacing]'), isEmpty);
  });
}
