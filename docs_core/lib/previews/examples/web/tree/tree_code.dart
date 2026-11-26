/// Returns a Web code snippet string for the Tree component.
String treeCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class TreeChainExample extends StatelessComponent {
  const TreeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Tree(
          nodes: [
            CoreTreeNode(
              label: '문서',
              expanded: true,
              children: [
                CoreTreeNode(label: '이력서.pdf'),
                CoreTreeNode(label: '자기소개서.pdf'),
              ],
            ),
            CoreTreeNode(
              label: '이미지',
              children: [
                CoreTreeNode(label: '사진.png'),
                CoreTreeNode(label: '배너.jpg'),
              ],
            ),
            CoreTreeNode(label: 'README.md'),
          ],
        )
        .withStyle(
          const CoreTreeStyle(
            nodeBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            nodePadding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space12,
              vertical: CoreSpace.space8,
            ),
            indent: CoreSpace.space24,
          ),
        )
        .radius16;
  }
}
''',
    'trailing' =>
      '''
class TreeTrailingExample extends StatelessComponent {
  const TreeTrailingExample({super.key});

  @override
  Component build(BuildContext context) {
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
        _ => const Component.fragment([]),
      },
    );
  }
}''',
    'selected' =>
      '''
class TreeSelectedExample extends StatelessComponent {
  const TreeSelectedExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Tree(
      nodes: [
        CoreTreeNode(
          label: '문서',
          expanded: true,
          children: [
            CoreTreeNode(label: '이력서.pdf', selected: true),
            CoreTreeNode(label: '자기소개서.pdf'),
          ],
        ),
        CoreTreeNode(
          label: '이미지',
          children: [
            CoreTreeNode(label: '사진.png'),
          ],
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class TreeDefaultExample extends StatelessComponent {
  const TreeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Tree(
      nodes: [
        CoreTreeNode(
          label: '문서',
          expanded: true,
          children: [
            CoreTreeNode(label: '이력서.pdf'),
            CoreTreeNode(label: '자기소개서.pdf'),
          ],
        ),
        CoreTreeNode(
          label: '이미지',
          children: [
            CoreTreeNode(label: '사진.png'),
            CoreTreeNode(label: '배너.jpg'),
          ],
        ),
        CoreTreeNode(label: 'README.md'),
      ],
    );
  }
}''',
  };
}
