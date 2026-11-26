// `role="tree"` promises the WAI-ARIA tree keys (#3968 · #4154): one tab
// stop for the whole tree, arrows inside it. What that needs from the
// markup is pinned here — every visible row a `treeitem` in the roving
// rotation, the hierarchy stated on each row because the DOM is flat, and
// `aria-selected` only where selection means something.
//
// The key → index arithmetic is pinned in `base/roving_focus_test.dart`;
// the live keydown dispatch is not — `universal_web`'s `KeyboardEvent.key`
// throws on the VM this suite runs on.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

const _nodes = [
  CoreTreeNode(
    label: 'Documents',
    expanded: true,
    children: [
      CoreTreeNode(label: 'Resume.pdf'),
      CoreTreeNode(label: 'Letter.pdf'),
    ],
  ),
  CoreTreeNode(
    label: 'Pictures',
    children: [CoreTreeNode(label: 'a.png')],
  ),
];

void main() {
  testServer(
    'selectedId marks a node selected without changing the input tree',
    (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          Tree(
            nodes: const [CoreTreeNode(id: 'file', label: 'file')],
            selectedId: 'file',
          ),
        ),
      );
      final row = (await tester.request(
        '/',
      )).document!.querySelector('[role="treeitem"]');
      expect(row?.attributes['aria-selected'], 'true');
    },
  );
  testServer('opt-in drag rows expose labelled keyboard grips and targets', (
    tester,
  ) async {
    tester.pumpComponent(
      _host(
        Tree(
          nodes: const [
            CoreTreeNode(id: 'file', label: 'file'),
            CoreTreeNode(id: 'folder', label: 'folder', canHaveChildren: true),
          ],
          onNodeDrop: (_, _) {},
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    expect(document.querySelectorAll('[aria-grabbed]'), hasLength(2));
    expect(document.querySelectorAll('[aria-dropeffect]'), hasLength(1));
    expect(document.querySelector('[aria-label="file"]'), isNotNull);
    expect(document.querySelector('#tree-node\\.folder'), isNotNull);
  });
  testServer('leaf insertion and external drops use the visible parent row', (
    tester,
  ) async {
    tester.pumpComponent(
      _host(
        Tree(
          nodes: const [
            CoreTreeNode(
              id: 'root',
              label: 'root',
              expanded: true,
              children: [
                CoreTreeNode(id: 'file', label: 'file'),
              ],
            ),
            CoreTreeNode(id: 'orphan', label: 'orphan'),
          ],
          onNodeDrop: (_, _) {},
          onFilesDroppedOnNode: (_, _) {},
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    expect(document.querySelectorAll('[aria-dropeffect]'), hasLength(2));
    expect(
      document.querySelectorAll('[data-tree-file-drop-over]'),
      hasLength(2),
    );
    expect(document.querySelector('#tree-node\\.orphan'), isNotNull);
  });
  testServer('placement mode keeps folder targets but locks the root drag', (
    tester,
  ) async {
    tester.pumpComponent(
      _host(
        Tree(
          nodes: const [
            CoreTreeNode(
              id: 'root',
              label: 'root',
              expanded: true,
              children: [
                CoreTreeNode(id: 'root/file', label: 'file'),
              ],
            ),
          ],
          onNodePlace: (_, _) {},
          canDragNode: (node) => node.id != 'root',
          onFilesPlaced: (_, _) {},
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    expect(document.querySelectorAll('[aria-dropeffect]'), hasLength(2));
    expect(document.querySelectorAll('[aria-grabbed]'), hasLength(1));
    expect(
      document.querySelectorAll('[data-tree-file-drop-over]'),
      hasLength(2),
    );
  });
  group('Tree lazy and windowed', () {
    testServer('unloaded branch is expandable and uses caller slots and id', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          Tree(
            nodes: const [
              CoreTreeNode(id: 'src', label: 'src', canHaveChildren: true),
            ],
            leadingBuilder: (context, node, {required expanded}) =>
                const Text('folder-icon'),
            trailingBuilder: (context, node, {required expanded}) =>
                const Text('M'),
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final row = document.querySelector('#tree-node\\.src');
      expect(row, isNotNull);
      expect(row!.attributes['aria-expanded'], 'false');
      expect(row.text, contains('folder-icon'));
      expect(row.text, contains('M'));
    });

    testServer('virtualized tree renders only first viewport, not all nodes', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          Tree(
            nodes: [
              for (var i = 0; i < 1000; i++)
                CoreTreeNode(id: '$i', label: 'file-$i'),
            ],
            virtualRowHeight: 32,
            virtualViewportHeight: 160,
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final rows = document.querySelectorAll('[role="treeitem"]');
      expect(rows.length, lessThan(20));
      expect(rows.first.text, contains('file-0'));
      expect(document.body!.text, isNot(contains('file-999')));
    });
  });
  group('Tree roving focus', () {
    testServer('every visible row is a treeitem, and only the first is a '
        'tab stop', (tester) async {
      tester.pumpComponent(_host(const Tree(id: 't', nodes: _nodes)));
      final items = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="treeitem"]');

      // Display-only leaves included — a row a keyboard cannot land on is a
      // row a screen reader cannot read. The collapsed folder's child is
      // not visible, so it is not a stop.
      expect(items.map((e) => e.text.trim()), [
        'Documents',
        'Resume.pdf',
        'Letter.pdf',
        'Pictures',
      ]);
      expect(items.map((e) => e.attributes['tabindex']), [
        '0',
        '-1',
        '-1',
        '-1',
      ]);
      expect(items.map((e) => e.attributes['data-roving-item']), [
        't:0',
        't:1',
        't:2',
        't:3',
      ]);
    });

    testServer('the hierarchy is stated on each row because the DOM is '
        'flat', (tester) async {
      tester.pumpComponent(_host(const Tree(id: 't', nodes: _nodes)));
      final items = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="treeitem"]');

      expect(items.map((e) => e.attributes['aria-level']), [
        '1',
        '2',
        '2',
        '1',
      ]);
      expect(items.map((e) => e.attributes['aria-posinset']), [
        '1',
        '1',
        '2',
        '2',
      ]);
      expect(items.map((e) => e.attributes['aria-setsize']), [
        '2',
        '2',
        '2',
        '2',
      ]);
      expect(items.map((e) => e.attributes['aria-expanded']), [
        'true',
        null,
        null,
        'false',
      ]);
    });

    testServer('a folder chevron is a pointer target, not a second tab stop', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          Tree(
            id: 't',
            nodes: _nodes,
            selectFolders: true,
            onNodeSelect: (_) {},
          ),
        ),
      );
      // Nothing inside a row may be a stop of its own — the chevrons are
      // the only focusable descendants, and they sit at -1 with no role.
      final nested = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="treeitem"] [tabindex]');

      expect(nested, hasLength(2));
      for (final chevron in nested) {
        expect(chevron.attributes['tabindex'], '-1');
        expect(chevron.attributes['role'], isNull);
        expect(chevron.attributes['aria-hidden'], 'true');
      }
    });
  });

  group('Tree aria-selected', () {
    testServer('a tree nobody selects in states no selection at all', (
      tester,
    ) async {
      tester.pumpComponent(_host(const Tree(nodes: _nodes)));
      final items = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="treeitem"]');

      expect(items, isNotEmpty);
      expect(
        items.map((e) => e.attributes['aria-selected']),
        everyElement(isNull),
      );
    });

    testServer('selectable rows state their selection, selected or not', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          Tree(
            nodes: const [
              CoreTreeNode(label: 'One', selected: true),
              CoreTreeNode(label: 'Two'),
            ],
            onNodeSelect: (_) {},
          ),
        ),
      );
      final items = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="treeitem"]');

      expect(items.map((e) => e.attributes['aria-selected']), [
        'true',
        'false',
      ]);
    });
  });
}
