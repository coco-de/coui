import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  const child = CoreTreeNode(id: 'child', label: 'child');
  const parent = CoreTreeNode(
    id: 'parent',
    label: 'parent',
    children: [child],
  );
  const emptyFolder = CoreTreeNode(
    id: 'empty',
    label: 'empty',
    canHaveChildren: true,
  );

  List<CoreTreeNode> childrenOf(CoreTreeNode node) => node.children;

  test('file can be dropped into an unloaded or empty directory', () {
    expect(
      CoreTreeDropRules.accepts(child, emptyFolder, childrenOf: childrenOf),
      isTrue,
    );
  });

  test('self, descendant and leaf destinations are refused', () {
    expect(
      CoreTreeDropRules.accepts(parent, parent, childrenOf: childrenOf),
      isFalse,
    );
    expect(
      CoreTreeDropRules.accepts(parent, child, childrenOf: childrenOf),
      isFalse,
    );
    expect(
      CoreTreeDropRules.accepts(emptyFolder, child, childrenOf: childrenOf),
      isFalse,
    );
    const grandchildFolder = CoreTreeNode(
      id: 'grandchild',
      label: 'grandchild',
      canHaveChildren: true,
    );
    expect(
      CoreTreeDropRules.accepts(
        parent,
        grandchildFolder,
        childrenOf: (node) =>
            node.id == 'child' ? const [grandchildFolder] : node.children,
      ),
      isFalse,
    );
  });

  test('nodes without stable ids are not draggable or valid targets', () {
    expect(
      CoreTreeDropRules.accepts(
        const CoreTreeNode(label: 'unnamed'),
        emptyFolder,
        childrenOf: childrenOf,
      ),
      isFalse,
    );
  });

  test('edge and centre hit testing preserves the target tree depth', () {
    expect(
      CoreTreeDropRules.positionAt(
        pointerY: 3,
        rowTop: 0,
        rowHeight: 32,
        isBranch: true,
        hasParent: true,
      ),
      CoreTreeDropPosition.before,
    );
    expect(
      CoreTreeDropRules.positionAt(
        pointerY: 16,
        rowTop: 0,
        rowHeight: 32,
        isBranch: true,
        hasParent: true,
      ),
      CoreTreeDropPosition.inside,
    );
    expect(
      CoreTreeDropRules.positionAt(
        pointerY: 27,
        rowTop: 0,
        rowHeight: 32,
        isBranch: false,
        hasParent: true,
      ),
      CoreTreeDropPosition.after,
    );
  });

  test(
    'reordering siblings is valid; a folder may not enter its descendant',
    () {
      const sibling = CoreTreeNode(id: 'sibling', label: 'sibling');
      const nested = CoreTreeNode(id: 'nested', label: 'nested');
      const branch = CoreTreeNode(
        id: 'branch',
        label: 'branch',
        children: [nested],
      );
      const root = CoreTreeNode(
        id: 'root',
        label: 'root',
        children: [branch, sibling],
      );
      const before = CoreTreeDropTarget(
        anchor: sibling,
        directory: root,
        position: .before,
        depth: 1,
      );
      expect(
        CoreTreeDropRules.acceptsPlacement(
          branch,
          before,
          childrenOf: childrenOf,
        ),
        isTrue,
      );
      expect(
        CoreTreeDropRules.acceptsPlacement(
          sibling,
          before,
          childrenOf: childrenOf,
        ),
        isFalse,
      );
      const nestedFolder = CoreTreeNode(
        id: 'nested',
        label: 'nested',
        canHaveChildren: true,
      );
      const insideDescendant = CoreTreeDropTarget(
        anchor: nestedFolder,
        directory: nestedFolder,
        position: .inside,
        depth: 2,
      );
      expect(
        CoreTreeDropRules.acceptsPlacement(
          branch,
          insideDescendant,
          childrenOf: (node) =>
              node.id == 'branch' ? const [nestedFolder] : node.children,
        ),
        isFalse,
      );
    },
  );
}
