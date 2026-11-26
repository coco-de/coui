import 'package:coui_flutter/coui_flutter.dart';

class TreeTrailingExample extends StatelessWidget {
  const TreeTrailingExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Tree(
      nodes: const [
        CoreTreeNode(
          label: 'src',
          expanded: true,
          children: [
            CoreTreeNode(label: 'app.dart'),
            CoreTreeNode(label: 'button.dart'),
            CoreTreeNode(label: 'legacy.dart'),
            CoreTreeNode(label: 'theme.dart'),
          ],
        ),
        CoreTreeNode(label: 'README.md'),
      ],
      trailingBuilder: (context, node, {required expanded}) => switch (node.label) {
        'app.dart' => const Text('M').labelXs.bold.onWarningContainer,
        'button.dart' => const Text('A').labelXs.bold.onWarningContainer,
        'legacy.dart' => const Text('D').labelXs.bold.onWarningContainer,
        _ => const SizedBox.shrink(),
      },
    );
  }
}
