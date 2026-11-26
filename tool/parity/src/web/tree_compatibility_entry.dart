/// Old-public-API-only Tree fixture, also compiled on the unmodified base.
library;

import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiTreeVirtual')
external set _configure(JSFunction value);

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  bool _virtual = false;

  @override
  void initState() {
    super.initState();
    _configure = ((bool value) => setState(() => _virtual = value)).toJS;
  }

  @override
  Component build(BuildContext context) => div(
    [
      Tree(
        id: 'compatibility-tree',
        nodes: const [
          CoreTreeNode(
            id: 'root',
            label: 'Workspace',
            expanded: true,
            children: [
              CoreTreeNode(
                id: 'src',
                label: 'src',
                expanded: true,
                children: [CoreTreeNode(id: 'main', label: 'main.dart')],
              ),
              CoreTreeNode(id: 'readme', label: 'README.md'),
            ],
          ),
        ],
        selectedId: 'main',
        virtualRowHeight: _virtual ? 28 : null,
        virtualViewportHeight: _virtual ? 216 : null,
        onNodeSelect: (_) {},
        onNodeDrop: (_, _) {},
        onFilesDroppedOnNode: (_, _) {},
      ),
    ],
    styles: const Styles(raw: {'width': '320px', 'margin': '16px'}),
  );
}
