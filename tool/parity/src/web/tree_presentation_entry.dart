/// Live-client fixture for Tree root visibility and row spacing.
///
/// `couiTreeConfigure(json)` rebuilds the shipped Tree with `showRoots`,
/// `rowSpacing`, and `virtual` options. The fixture does not implement layout,
/// virtualization, focus, expansion, or drop behavior; those belong to Tree.
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiTreeConfigure')
external set _configure(JSFunction value);
@JS('couiTreeEvents')
external set _events(JSFunction value);

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  bool _showRoots = false;
  bool _virtual = true;
  double _rowSpacing = 8;
  String? _selected;
  final List<Map<String, String?>> _recorded = [];

  static final _nodes = [
    CoreTreeNode(
      id: 'root',
      label: 'Workspace',
      expanded: true,
      children: [
        const CoreTreeNode(
          id: 'folder',
          label: 'src',
          expanded: true,
          children: [CoreTreeNode(id: 'nested', label: 'nested.dart')],
        ),
        for (var i = 0; i < 200; i++)
          CoreTreeNode(id: 'file-$i', label: 'file-$i.dart'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _events = (() => jsonEncode(_recorded)).toJS;
    _configure = ((String json) {
      final config = jsonDecode(json) as Map<String, Object?>;
      setState(() {
        _showRoots = config['showRoots'] as bool? ?? _showRoots;
        _virtual = config['virtual'] as bool? ?? _virtual;
        _rowSpacing = (config['rowSpacing'] as num?)?.toDouble() ?? _rowSpacing;
      });
    }).toJS;
  }

  @override
  Component build(BuildContext context) => div(
    [
      Tree(
        id: 'probe-tree',
        nodes: _nodes,
        showRoots: _showRoots,
        selectedId: _selected,
        virtualRowHeight: _virtual ? 28 : null,
        virtualViewportHeight: _virtual ? 216 : null,
        treeStyle: CoreTreeStyle(rowSpacing: _rowSpacing),
        onNodeSelect: (node) => setState(() => _selected = node.id),
        onNodeRename: (node, newLabel) => _recorded.add({
          'kind': 'rename',
          'node': node.id,
          'label': newLabel,
        }),
        onNodeDrop: (node, destination) => _recorded.add({
          'kind': 'drop',
          'node': node.id,
          'destination': destination.id,
        }),
        onFilesDroppedOnNode: (files, destination) => _recorded.add({
          'kind': 'files',
          'destination': destination.id,
        }),
      ),
    ],
    id: 'probe',
    styles: const Styles(raw: {'width': '320px', 'margin': '16px'}),
  );
}
