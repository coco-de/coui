import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreTreeStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter
/// than a second `.withStyle(const CoreTreeStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
class TreeChainExample extends StatelessWidget {
  const TreeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
