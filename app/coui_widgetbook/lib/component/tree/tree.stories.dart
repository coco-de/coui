import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'tree.stories.g.dart';

/// Default preview width for the tree.
const _kTreeWidth = 300.0;

/// Interactive demo host for [Tree] stories.
///
/// Tracks the last selected node so selection feedback can be
/// exercised alongside expand/collapse behaviour.
class TreeDemo extends StatefulWidget {
  /// Creates a [TreeDemo].
  const TreeDemo({this.showRoots = true, this.rowSpacing = 0, super.key});

  /// Whether the workspace preview includes its root row.
  final bool showRoots;

  /// Space outside each row in the workspace preview.
  final double rowSpacing;

  @override
  State<TreeDemo> createState() => _TreeDemoState();
}

class _TreeDemoState extends State<TreeDemo> {
  String? _selectedLabel;
  String? _lastDrop;
  var _orderedFiles = const [
    CoreTreeNode(id: 'preview/alpha', label: 'alpha.dart'),
    CoreTreeNode(id: 'preview/beta', label: 'beta.dart'),
    CoreTreeNode(id: 'preview/gamma', label: 'gamma.dart'),
  ];
  var _dropNodes = const [
    CoreTreeNode(
      id: 'src',
      label: 'src',
      expanded: true,
      canHaveChildren: true,
      children: [CoreTreeNode(id: 'src/main.dart', label: 'main.dart')],
    ),
    CoreTreeNode(id: 'test', label: 'test', canHaveChildren: true),
  ];
  var _controlledNodes = const [
    CoreTreeNode(
      label: 'src',
      expanded: true,
      children: [
        CoreTreeNode(label: 'main.dart'),
        CoreTreeNode(label: 'widget.dart'),
      ],
    ),
    CoreTreeNode(
      label: 'test',
      children: [CoreTreeNode(label: 'widget_test.dart')],
    ),
  ];

  var _explorerNodes = const [
    CoreTreeNode(
      id: 'app',
      label: 'app',
      children: [
        CoreTreeNode(id: 'app/main.dart', label: 'main.dart'),
        CoreTreeNode(id: 'app/router.dart', label: 'router.dart'),
      ],
    ),
    CoreTreeNode(id: 'README.md', label: 'README.md'),
  ];

  /// Starts a rename from outside the rows — the toolbar button below.
  final _explorerController = CoreTreeController();
  String? _explorerSelectedId;

  @override
  void dispose() {
    _explorerController.dispose();
    super.dispose();
  }

  void handleNodeSelect(CoreTreeNode node) {
    setState(() => _selectedLabel = node.label);
  }

  /// A row's right-click menu — 「Rename」 starts the same inline edit.
  List<CoreMenuItem<Widget>> explorerMenuFor(CoreTreeNode node) => [
    CoreMenuItem.action(
      'Rename',
      onPressed: switch (node.id) {
        final id? => () => _explorerController.startRename(id),
        null => null,
      },
    ),
  ];

  void handleExplorerSelect(CoreTreeNode node) {
    setState(() {
      _selectedLabel = node.label;
      _explorerSelectedId = node.id;
    });
  }

  /// The consumer owns a rename: here the label changes and the id stays,
  /// so the folder keeps its expansion across the edit.
  void handleRename(CoreTreeNode node, String label) {
    setState(() {
      _explorerNodes = _relabel(_explorerNodes, node.id, label);
      _selectedLabel = label;
    });
  }

  void handleControlledToggle(CoreTreeNode node) {
    setState(() {
      _controlledNodes = _flipExpanded(_controlledNodes, node.label);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _selectedLabel;

    return SizedBox(
      width: _kTreeWidth,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Tree(
              nodes: const [
                CoreTreeNode(
                  label: 'Documents',
                  expanded: true,
                  children: [
                    CoreTreeNode(label: 'Resume.pdf'),
                    CoreTreeNode(label: 'Cover Letter.docx'),
                  ],
                ),
                CoreTreeNode(
                  label: 'Images',
                  children: [
                    CoreTreeNode(label: 'vacation.jpg'),
                    CoreTreeNode(label: 'profile.png'),
                  ],
                ),
                CoreTreeNode(label: 'Music'),
              ],
              onNodeSelect: handleNodeSelect,
            ),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            const Text('Workspace presentation').labelSmall().onSurface(),
            SizedBox(
              height: 180,
              child: Tree(
                showRoots: widget.showRoots,
                treeStyle: CoreTreeStyle(rowSpacing: widget.rowSpacing),
                nodes: const [
                  CoreTreeNode(
                    id: 'workspace',
                    label: 'Workspace',
                    expanded: true,
                    children: [
                      CoreTreeNode(id: 'workspace/main', label: 'main.dart'),
                      CoreTreeNode(
                        id: 'workspace/pubspec',
                        label: 'pubspec.yaml',
                      ),
                    ],
                  ),
                ],
                virtualRowHeight: 28,
                virtualViewportHeight: 180,
                onNodeSelect: handleNodeSelect,
              ),
            ),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            const Text(
              'Folder select · controlled expansion',
            ).labelSmall().onSurface(),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
            Tree(
              selectFolders: true,
              expansionControlled: true,
              nodes: _controlledNodes,
              onNodeSelect: handleNodeSelect,
              onNodeToggle: handleControlledToggle,
            ),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            const Text(
              'Explorer · the whole row toggles · double-click, F2, '
              'right-click or the button renames',
            ).labelSmall().onSurface(),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
            Tree(
              selectFolders: true,
              toggleFoldersOnSelect: true,
              nodes: _explorerNodes,
              controller: _explorerController,
              nodeContextMenu: explorerMenuFor,
              onNodeSelect: handleExplorerSelect,
              onNodeRename: handleRename,
            ),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
            Button(
              onPressed: switch (_explorerSelectedId) {
                final id? => () => _explorerController.startRename(id),
                null => null,
              },
              variant: .outline,
              size: CoreComponentSize.sm,
              child: const Text('Rename selected · controller'),
            ),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            const Text('Lazy · windowed · badges').labelSmall().onSurface(),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
            Tree(
              nodes: const [
                CoreTreeNode(id: 'lib', label: 'lib', canHaveChildren: true),
                CoreTreeNode(id: 'README.md', label: 'README.md'),
              ],
              loadChildren: (node) async => const [
                CoreTreeNode(id: 'lib/main.dart', label: 'main.dart'),
                CoreTreeNode(id: 'lib/app.dart', label: 'app.dart'),
              ],
              leadingBuilder: (context, node, {required expanded}) => Icon(
                node.canHaveChildren
                    ? (expanded
                          ? LucideIcons.folderOpen
                          : LucideIcons.folderClosed)
                    : LucideIcons.file,
              ),
              trailingBuilder: (context, node, {required expanded}) =>
                  node.id == 'lib/main.dart'
                  ? const Text('M').labelSmall()
                  : const SizedBox.shrink(),
              virtualRowHeight: 36,
              virtualViewportHeight: 108,
            ),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            const Text(
              'Drag a row or OS file onto a folder or between rows',
            ).labelSmall().onSurface(),
            Tree(
              nodes: _dropNodes,
              onFilesDroppedOnNode: (files, directory) => setState(() {
                _lastDrop =
                    '${files.length} OS file(s) → ${directory.label} (preview)';
              }),
              onNodeDrop: (source, destination) => setState(() {
                _lastDrop = '${source.label} → ${destination.label}';
                if (source.id == 'src/main.dart' && destination.id == 'test') {
                  _dropNodes = const [
                    CoreTreeNode(
                      id: 'src',
                      label: 'src',
                      expanded: true,
                      canHaveChildren: true,
                    ),
                    CoreTreeNode(
                      id: 'test',
                      label: 'test',
                      expanded: true,
                      canHaveChildren: true,
                      children: [
                        CoreTreeNode(id: 'test/main.dart', label: 'main.dart'),
                      ],
                    ),
                  ];
                }
              }),
            ),
            const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
            const Text(
              'Placement preview · reorder files or drop OS files',
            ).labelSmall().onSurface(),
            Tree(
              expansionControlled: true,
              nodes: [
                CoreTreeNode(
                  id: 'preview',
                  label: 'preview',
                  expanded: true,
                  canHaveChildren: true,
                  children: _orderedFiles,
                ),
              ],
              canDragNode: (node) => node.id != 'preview',
              onNodePlace: (source, target) {
                final next = [..._orderedFiles]
                  ..removeWhere((node) => node.id == source.id);
                final anchor = next.indexWhere(
                  (node) => node.id == target.anchor.id,
                );
                final index = target.position == .inside
                    ? 0
                    : anchor + (target.position == .after ? 1 : 0);
                if (target.directory.id != 'preview' ||
                    (target.position != .inside && anchor < 0)) {
                  return;
                }
                setState(() {
                  _orderedFiles = next..insert(index, source);
                  _lastDrop =
                      '${source.label} → ${target.position.name} '
                      '${target.anchor.label}';
                });
              },
              onFilesPlaced: (files, target) => setState(() {
                _lastDrop =
                    '${files.length} OS file(s) → '
                    '${target.position.name} ${target.anchor.label} (preview)';
              }),
            ),
            if (_lastDrop case final message?) Text(message).labelSmall(),
            if (selectedLabel != null) ...[
              const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
              Text('Selected: $selectedLabel').bodySmall().onSurface(),
            ],
          ],
        ),
      ),
    );
  }
}

List<CoreTreeNode> _relabel(
  List<CoreTreeNode> nodes,
  String? id,
  String label,
) {
  return [
    for (final node in nodes)
      CoreTreeNode(
        label: node.id == id ? label : node.label,
        id: node.id,
        selected: node.selected,
        canHaveChildren: node.canHaveChildren,
        expanded: node.expanded,
        children: _relabel(node.children, id, label),
      ),
  ];
}

List<CoreTreeNode> _flipExpanded(List<CoreTreeNode> nodes, String label) {
  return [
    for (final node in nodes)
      CoreTreeNode(
        label: node.label,
        id: node.id,
        selected: node.selected,
        canHaveChildren: node.canHaveChildren,
        expanded: node.label == label && node.children.isNotEmpty
            ? !node.expanded
            : node.expanded,
        children: _flipExpanded(node.children, label),
      ),
  ];
}

/// Navigation metadata for the Tree component.
const kComponentMeta = ComponentMeta(name: 'Tree', path: 'layout');

/// Story metadata for [TreeDemo].
const kMeta = Meta(TreeDemo.new);

/// File tree with expandable folders and node selection.
final $Default = _Story();
